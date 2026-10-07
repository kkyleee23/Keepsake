-- Keepsake — initial schema
--
-- Model: drafts live on-device. When a keepsake is published it is uploaded
-- here. Creators own their rows (Row-Level Security keyed on auth.uid(), which
-- they get via anonymous sign-in). Recipients never authenticate — they read
-- through SECURITY DEFINER functions that enforce scheduled access, expiry, and
-- PIN on the server, so a known share token alone never exposes protected
-- content or sealed content before its time.

create extension if not exists pgcrypto;

create table if not exists public.keepsakes (
  id            uuid primary key default gen_random_uuid(),
  creator_id    uuid not null references auth.users (id) on delete cascade,
  share_token   text not null unique,
  status        text not null default 'published',
  occasion      text,
  title         text,
  recipient_name text,
  sender_name   text,
  cover_note    text,
  delivery_mode text not null default 'immediately',
  open_at       timestamptz,
  expires_at    timestamptz,
  unlisted      boolean not null default true,
  pin_hash      text,
  payload       jsonb not null,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  published_at  timestamptz not null default now()
);

create index if not exists keepsakes_creator_idx on public.keepsakes (creator_id);

alter table public.keepsakes enable row level security;

-- Creators manage only their own rows. Recipients get NO direct table access.
create policy "creator reads own" on public.keepsakes
  for select using (auth.uid() = creator_id);
create policy "creator inserts own" on public.keepsakes
  for insert with check (auth.uid() = creator_id);
create policy "creator updates own" on public.keepsakes
  for update using (auth.uid() = creator_id) with check (auth.uid() = creator_id);
create policy "creator deletes own" on public.keepsakes
  for delete using (auth.uid() = creator_id);

-- Publish (or re-publish) a keepsake owned by the caller. PIN is hashed here so
-- the plaintext never lands in a column.
create or replace function public.publish_keepsake(
  p_token text,
  p_payload jsonb,
  p_occasion text,
  p_title text,
  p_recipient_name text,
  p_sender_name text,
  p_cover_note text,
  p_delivery_mode text,
  p_open_at timestamptz,
  p_expires_at timestamptz,
  p_unlisted boolean,
  p_pin text
) returns jsonb
language plpgsql security definer set search_path = public, pg_temp as $$
declare uid uuid := auth.uid();
begin
  if uid is null then
    return jsonb_build_object('status', 'unauthenticated');
  end if;

  insert into public.keepsakes (
    creator_id, share_token, status, occasion, title, recipient_name,
    sender_name, cover_note, delivery_mode, open_at, expires_at, unlisted,
    pin_hash, payload, published_at, updated_at
  ) values (
    uid, p_token, 'published', p_occasion, p_title, p_recipient_name,
    p_sender_name, p_cover_note, coalesce(p_delivery_mode, 'immediately'),
    p_open_at, p_expires_at, coalesce(p_unlisted, true),
    case when p_pin is not null and length(p_pin) > 0
         then crypt(p_pin, gen_salt('bf')) end,
    p_payload, now(), now()
  )
  on conflict (share_token) do update set
    payload        = excluded.payload,
    status         = 'published',
    occasion       = excluded.occasion,
    title          = excluded.title,
    recipient_name = excluded.recipient_name,
    sender_name    = excluded.sender_name,
    cover_note     = excluded.cover_note,
    delivery_mode  = excluded.delivery_mode,
    open_at        = excluded.open_at,
    expires_at     = excluded.expires_at,
    unlisted       = excluded.unlisted,
    pin_hash       = case when p_pin is not null and length(p_pin) > 0
                          then crypt(p_pin, gen_salt('bf'))
                          else public.keepsakes.pin_hash end,
    updated_at     = now()
  where public.keepsakes.creator_id = uid;

  return jsonb_build_object('status', 'ok', 'share_token', p_token);
end;
$$;

-- Cover metadata for the sealed screen. Viewable even while sealed (so the
-- recipient can see a calm countdown), but never the content.
create or replace function public.keepsake_cover(p_token text)
returns jsonb
language plpgsql security definer set search_path = public, pg_temp as $$
declare r public.keepsakes;
begin
  select * into r from public.keepsakes where share_token = p_token;
  if not found or r.status <> 'published' then
    return jsonb_build_object('status', 'not_found');
  end if;
  if r.expires_at is not null and now() >= r.expires_at then
    return jsonb_build_object('status', 'expired');
  end if;
  return jsonb_build_object(
    'status', case when r.open_at is not null and now() < r.open_at
                   then 'sealed' else 'available' end,
    'opens_at', r.open_at,
    'requires_pin', (r.pin_hash is not null),
    'occasion', r.occasion,
    'title', r.title,
    'recipient_name', r.recipient_name,
    'sender_name', r.sender_name,
    'cover_note', r.cover_note
  );
end;
$$;

-- Open the content. Enforces schedule, expiry, and PIN before returning payload.
create or replace function public.keepsake_open(p_token text, p_pin text)
returns jsonb
language plpgsql security definer set search_path = public, pg_temp as $$
declare r public.keepsakes;
begin
  select * into r from public.keepsakes where share_token = p_token;
  if not found or r.status <> 'published' then
    return jsonb_build_object('status', 'not_found');
  end if;
  if r.expires_at is not null and now() >= r.expires_at then
    return jsonb_build_object('status', 'expired');
  end if;
  if r.open_at is not null and now() < r.open_at then
    return jsonb_build_object('status', 'sealed', 'opens_at', r.open_at);
  end if;
  if r.pin_hash is not null then
    if p_pin is null or length(p_pin) = 0 then
      return jsonb_build_object('status', 'pin_required');
    end if;
    if crypt(p_pin, r.pin_hash) <> r.pin_hash then
      return jsonb_build_object('status', 'wrong_pin');
    end if;
  end if;
  return jsonb_build_object('status', 'ok', 'payload', r.payload);
end;
$$;

-- Recipients call these two without logging in; creators call publish.
grant execute on function public.keepsake_cover(text) to anon, authenticated;
grant execute on function public.keepsake_open(text, text) to anon, authenticated;
grant execute on function public.publish_keepsake(
  text, jsonb, text, text, text, text, text, text, timestamptz, timestamptz,
  boolean, text
) to authenticated;
