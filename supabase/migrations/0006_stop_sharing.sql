-- Keepsake: stop sharing a link, and links that stay dead
--
-- 1. stop_sharing(token): the creator turns a link off. From that moment the
--    link and QR code show "not found", and the content is deleted from the
--    server (the letter, photos, names, everything in the payload). Replies
--    already sent stay, so the creator doesn't lose them.
-- 2. A link that was stopped or deleted can never be used again, by anyone.
--    Before this, deleting a keepsake freed its link, and someone who knew
--    it could publish something else at the same address. Every deleted
--    link is now remembered (as a one-way hash) and publishing refuses it.
-- 3. Stickers on the envelope. Only known stickers are kept, at most six,
--    with every position, angle and size clamped to sane values.
--
-- Run this once in the Supabase SQL editor after 0005_wrapping.sql. It is
-- safe to run again (if you ran an earlier copy, run this one too).

create table if not exists public.retired_share_tokens (
  token_hash text primary key,
  retired_at timestamptz not null default now()
);
alter table public.retired_share_tokens enable row level security;
revoke all on public.retired_share_tokens from anon, authenticated;

create or replace function public.retire_share_token()
returns trigger
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
begin
  insert into public.retired_share_tokens (token_hash)
  values (encode(digest(old.share_token, 'sha256'), 'hex'))
  on conflict do nothing;
  return old;
end;
$$;
revoke all on function public.retire_share_token() from public, anon, authenticated;

-- Fires for every way a row can go: the app deleting a keepsake, account
-- deletion, and cascades.
drop trigger if exists keepsakes_retire_token on public.keepsakes;
create trigger keepsakes_retire_token
  after delete on public.keepsakes
  for each row execute function public.retire_share_token();

alter table public.keepsakes drop constraint if exists keepsakes_status;
alter table public.keepsakes add constraint keepsakes_status
  check (status in ('published', 'stopped')) not valid;

alter table public.keepsakes add column if not exists stopped_at timestamptz;

-- Room for six stickers on the cover (still tiny).
alter table public.keepsakes drop constraint if exists keepsakes_cover_style_size;
alter table public.keepsakes add constraint keepsakes_cover_style_size
  check (cover_style is null or octet_length(cover_style::text) <= 1024) not valid;

-- Keeps only what an envelope can show: a known paper, a known seal, and up
-- to six known stickers with their numbers clamped. Anything else is dropped.
create or replace function public.clean_cover_style(p_style jsonb)
returns jsonb
language sql immutable set search_path = public, pg_temp as $$
  select case when p_style is null or jsonb_typeof(p_style) <> 'object' then null
  else jsonb_strip_nulls(jsonb_build_object(
    'envelope', case when p_style->>'envelope' in ('cream', 'kraft', 'sage', 'linen')
                     then p_style->>'envelope' end,
    'seal', case when p_style->>'seal' in ('evergreen', 'terracotta', 'honey', 'plum', 'night')
                 then p_style->>'seal' end,
    'stickers', (
      select jsonb_agg(jsonb_build_object(
        'id', e->>'id',
        'x', round(least(greatest((e->>'x')::numeric, 0), 1), 3),
        'y', round(least(greatest((e->>'y')::numeric, 0), 1), 3),
        'r', round(least(greatest((e->>'r')::numeric, -40), 40)),
        's', round(least(greatest((e->>'s')::numeric, 0.7), 1.5), 3)
      ) order by n)
      from (
        select e, n from jsonb_array_elements(
          case when jsonb_typeof(p_style->'stickers') = 'array'
               then p_style->'stickers' else '[]'::jsonb end
        ) with ordinality as t(e, n)
        where jsonb_typeof(e) = 'object'
          and e->>'id' in ('sprig', 'stamp', 'heart', 'daisy', 'moon', 'airmail',
                           'pup_wave', 'pup_hug', 'pup_cheer', 'pup_gift',
                           'pup_read', 'pup_sleep')
          and jsonb_typeof(e->'x') = 'number' and jsonb_typeof(e->'y') = 'number'
          and jsonb_typeof(e->'r') = 'number' and jsonb_typeof(e->'s') = 'number'
        order by n
        limit 6
      ) kept
    )
  )) end;
$$;

create or replace function public.stop_sharing(p_token text)
returns jsonb
language plpgsql security definer set search_path = public, pg_temp as $$
declare
  uid uuid := auth.uid();
  affected int;
begin
  if uid is null then
    return jsonb_build_object('status', 'unauthenticated');
  end if;
  update public.keepsakes set
    status         = 'stopped',
    payload        = '{}'::jsonb,
    pin_hash       = null,
    cover_note     = null,
    title          = null,
    recipient_name = null,
    sender_name    = null,
    cover_style    = null,
    stopped_at     = now(),
    updated_at     = now()
  where share_token = p_token and creator_id = uid;
  get diagnostics affected = row_count;
  -- Someone else's token looks exactly like a missing one.
  if affected = 0 then
    return jsonb_build_object('status', 'not_found');
  end if;
  delete from public.keepsake_pin_attempts
    where keepsake_id = (select id from public.keepsakes where share_token = p_token);
  return jsonb_build_object('status', 'ok');
end;
$$;

revoke all on function public.stop_sharing(text) from public, anon;
grant execute on function public.stop_sharing(text) to authenticated;

-- publish_keepsake: same as 0005, except a stopped or deleted link is never
-- used again.
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
  p_pin text,
  p_style jsonb default null
) returns jsonb
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
declare
  uid uuid := auth.uid();
  affected int;
  v_style jsonb := public.clean_cover_style(p_style);
begin
  if uid is null then
    return jsonb_build_object('status', 'unauthenticated');
  end if;
  if octet_length(p_payload::text) > 5 * 1024 * 1024 then
    return jsonb_build_object('status', 'too_large');
  end if;
  if p_token is null or p_token !~ '^[A-Za-z0-9_-]{16,64}$'
     or char_length(coalesce(p_title, '')) > 200
     or char_length(coalesce(p_recipient_name, '')) > 120
     or char_length(coalesce(p_sender_name, '')) > 120
     or char_length(coalesce(p_cover_note, '')) > 600
     or char_length(coalesce(p_occasion, '')) > 40
     or coalesce(p_delivery_mode, 'immediately')
        not in ('immediately', 'scheduled', 'countdown', 'manual') then
    return jsonb_build_object('status', 'invalid');
  end if;
  if p_pin is not null and length(p_pin) > 0 and p_pin !~ '^[0-9]{4,12}$' then
    return jsonb_build_object('status', 'invalid_pin');
  end if;
  if exists (select 1 from public.retired_share_tokens
             where token_hash = encode(digest(p_token, 'sha256'), 'hex')) then
    return jsonb_build_object('status', 'conflict');
  end if;

  insert into public.keepsakes (
    creator_id, share_token, status, occasion, title, recipient_name,
    sender_name, cover_note, delivery_mode, open_at, expires_at, unlisted,
    pin_hash, payload, cover_style, published_at, updated_at
  ) values (
    uid, p_token, 'published', p_occasion, p_title, p_recipient_name,
    p_sender_name, p_cover_note, coalesce(p_delivery_mode, 'immediately'),
    p_open_at, p_expires_at, coalesce(p_unlisted, true),
    case when p_pin is not null and length(p_pin) > 0
         then crypt(p_pin, gen_salt('bf', 10)) end,
    p_payload, v_style, now(), now()
  )
  on conflict (share_token) do update set
    payload        = excluded.payload,
    occasion       = excluded.occasion,
    title          = excluded.title,
    recipient_name = excluded.recipient_name,
    sender_name    = excluded.sender_name,
    cover_note     = excluded.cover_note,
    delivery_mode  = excluded.delivery_mode,
    open_at        = excluded.open_at,
    expires_at     = excluded.expires_at,
    unlisted       = excluded.unlisted,
    cover_style    = excluded.cover_style,
    pin_hash       = case when p_pin is not null and length(p_pin) > 0
                          then crypt(p_pin, gen_salt('bf', 10))
                          else public.keepsakes.pin_hash end,
    updated_at     = now()
  where public.keepsakes.creator_id = uid
    and public.keepsakes.status = 'published';

  get diagnostics affected = row_count;
  if affected = 0 then
    return jsonb_build_object('status', 'conflict');
  end if;

  if p_pin is not null and length(p_pin) > 0 then
    delete from public.keepsake_pin_attempts
      where keepsake_id = (select id from public.keepsakes where share_token = p_token);
  end if;

  return jsonb_build_object('status', 'ok', 'share_token', p_token);
end;
$$;

grant execute on function public.publish_keepsake(
  text, jsonb, text, text, text, text, text, text, timestamptz, timestamptz,
  boolean, text, jsonb
) to authenticated;
