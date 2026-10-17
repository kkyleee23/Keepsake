-- Keepsake: replies from the recipient
--
-- A recipient can send one small thing back after opening: a reaction, a short
-- note, or both. They still never sign in. Replies go in through a SECURITY
-- DEFINER function that applies the same rules as opening (exists, not
-- expired, not sealed, correct PIN), so a reply is only possible for someone
-- who could open the keepsake. Only the creator can read them.
--
-- Run this once in the Supabase SQL editor after 0001_init.sql.

create table if not exists public.keepsake_responses (
  id             uuid primary key default gen_random_uuid(),
  keepsake_id    uuid not null references public.keepsakes (id) on delete cascade,
  reaction       text,
  message        text,
  responder_name text,
  created_at     timestamptz not null default now(),
  constraint keepsake_responses_reaction_ok check (
    reaction is null or reaction in
      ('love', 'thank_you', 'made_my_day', 'happy_tears', 'miss_you')
  ),
  constraint keepsake_responses_message_len check (
    message is null or char_length(message) <= 1000
  ),
  constraint keepsake_responses_name_len check (
    responder_name is null or char_length(responder_name) <= 60
  ),
  constraint keepsake_responses_not_empty check (
    reaction is not null or (message is not null and char_length(message) > 0)
  )
);

create index if not exists keepsake_responses_keepsake_idx
  on public.keepsake_responses (keepsake_id, created_at desc);

alter table public.keepsake_responses enable row level security;

-- The creator of the keepsake can read and remove its replies. There is no
-- insert policy: recipients can only add a reply through the function below.
drop policy if exists "creator reads replies" on public.keepsake_responses;
create policy "creator reads replies" on public.keepsake_responses
  for select using (
    exists (
      select 1 from public.keepsakes k
      where k.id = keepsake_id and k.creator_id = auth.uid()
    )
  );

drop policy if exists "creator deletes replies" on public.keepsake_responses;
create policy "creator deletes replies" on public.keepsake_responses
  for delete using (
    exists (
      select 1 from public.keepsakes k
      where k.id = keepsake_id and k.creator_id = auth.uid()
    )
  );

-- Send a reply. Same gate as keepsake_open, plus input limits and a simple
-- rate limit per keepsake so a leaked link can't be used to flood the creator.
create or replace function public.respond_to_keepsake(
  p_token text,
  p_pin text,
  p_reaction text,
  p_message text,
  p_name text
) returns jsonb
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
declare
  r public.keepsakes;
  v_message text := nullif(btrim(coalesce(p_message, '')), '');
  v_name text := nullif(btrim(coalesce(p_name, '')), '');
  v_reaction text := nullif(btrim(coalesce(p_reaction, '')), '');
  recent int;
  total int;
begin
  select * into r from public.keepsakes where share_token = p_token;
  if not found or r.status <> 'published' then
    return jsonb_build_object('status', 'not_found');
  end if;
  if r.expires_at is not null and now() >= r.expires_at then
    return jsonb_build_object('status', 'expired');
  end if;
  if r.open_at is not null and now() < r.open_at then
    return jsonb_build_object('status', 'sealed');
  end if;
  if r.pin_hash is not null then
    if p_pin is null or length(p_pin) = 0 or crypt(p_pin, r.pin_hash) <> r.pin_hash then
      return jsonb_build_object('status', 'wrong_pin');
    end if;
  end if;

  if v_reaction is null and v_message is null then
    return jsonb_build_object('status', 'empty');
  end if;
  if v_reaction is not null and v_reaction not in
     ('love', 'thank_you', 'made_my_day', 'happy_tears', 'miss_you') then
    return jsonb_build_object('status', 'invalid');
  end if;
  if char_length(coalesce(v_message, '')) > 1000
     or char_length(coalesce(v_name, '')) > 60 then
    return jsonb_build_object('status', 'too_long');
  end if;

  select count(*) into recent from public.keepsake_responses
    where keepsake_id = r.id and created_at > now() - interval '1 hour';
  select count(*) into total from public.keepsake_responses
    where keepsake_id = r.id;
  if recent >= 10 or total >= 100 then
    return jsonb_build_object('status', 'rate_limited');
  end if;

  insert into public.keepsake_responses (keepsake_id, reaction, message, responder_name)
  values (r.id, v_reaction, v_message, v_name);

  return jsonb_build_object('status', 'ok');
end;
$$;

-- Replies for one of the caller's own keepsakes, newest first.
create or replace function public.my_keepsake_responses(p_token text)
returns setof public.keepsake_responses
language sql security invoker set search_path = public, pg_temp as $$
  select resp.* from public.keepsake_responses resp
  join public.keepsakes k on k.id = resp.keepsake_id
  where k.share_token = p_token and k.creator_id = auth.uid()
  order by resp.created_at desc
  limit 100;
$$;

revoke all on function public.respond_to_keepsake(text, text, text, text, text) from public;
grant execute on function public.respond_to_keepsake(text, text, text, text, text)
  to anon, authenticated;
revoke all on function public.my_keepsake_responses(text) from public;
grant execute on function public.my_keepsake_responses(text) to authenticated;
