-- Keepsake: opened receipts, postmarks, and fair-use limits
--
-- 1. Receipts. When a keepsake is opened, the server notes when (first and
--    last time) and how many times. Only its creator can read that, with
--    my_keepsake_status(). Creators can turn receipts off per keepsake, and
--    the cover tells the recipient whether they're on, so nobody is
--    watched without knowing.
-- 2. Postmark. The cover returns the day the keepsake was first sent.
-- 3. Fair use, per account: at most 20 publishes in 10 minutes and 200 a
--    day, 500 shared keepsakes, and 100 MB of shared content in total.
-- 4. Clean-up. purge_expired_keepsakes() wipes the content of keepsakes
--    that expired more than 30 days ago (their links stay dead), and old
--    bookkeeping rows. If pg_cron is enabled it runs every night by itself.
--
-- Run this once in the Supabase SQL editor after 0006_stop_sharing.sql.
-- Safe to run again.

-- 1. Receipts -----------------------------------------------------------------

alter table public.keepsakes add column if not exists receipts boolean not null default true;
alter table public.keepsakes add column if not exists first_opened_at timestamptz;
alter table public.keepsakes add column if not exists last_opened_at timestamptz;
alter table public.keepsakes add column if not exists open_count int not null default 0;
-- Size of the stored content, kept on write so limits don't have to measure
-- every keepsake again.
alter table public.keepsakes add column if not exists payload_bytes int;

-- 3. Fair use: a log of publishes, read only by publish_keepsake.
create table if not exists public.publish_events (
  creator_id uuid not null references auth.users (id) on delete cascade,
  at         timestamptz not null default now()
);
create index if not exists publish_events_creator_at
  on public.publish_events (creator_id, at);
alter table public.publish_events enable row level security;
revoke all on public.publish_events from anon, authenticated;

-- Replace the 13-argument publish with one that also takes p_receipts.
drop function if exists public.publish_keepsake(
  text, jsonb, text, text, text, text, text, text, timestamptz, timestamptz,
  boolean, text, jsonb
);

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
  p_style jsonb default null,
  p_receipts boolean default true
) returns jsonb
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
declare
  uid uuid := auth.uid();
  affected int;
  v_style jsonb := public.clean_cover_style(p_style);
  v_bytes int;
  v_recent int;
  v_today int;
  v_count int;
  v_total bigint;
begin
  if uid is null then
    return jsonb_build_object('status', 'unauthenticated');
  end if;
  v_bytes := octet_length(p_payload::text);
  if v_bytes > 5 * 1024 * 1024 then
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

  -- Fair use. One account's publishes are checked one at a time.
  perform pg_advisory_xact_lock(hashtext('publish:' || uid::text));
  delete from public.publish_events
    where creator_id = uid and at < now() - interval '2 days';
  select count(*) filter (where at > now() - interval '10 minutes'),
         count(*) filter (where at > now() - interval '1 day')
    into v_recent, v_today
    from public.publish_events where creator_id = uid;
  if v_recent >= 20 or v_today >= 200 then
    return jsonb_build_object('status', 'rate_limited');
  end if;
  select count(*), coalesce(sum(coalesce(payload_bytes, octet_length(payload::text))), 0)
    into v_count, v_total
    from public.keepsakes
    where creator_id = uid and status = 'published' and share_token <> p_token;
  if v_count >= 500 or v_total + v_bytes > 100 * 1024 * 1024 then
    return jsonb_build_object('status', 'quota');
  end if;

  insert into public.keepsakes (
    creator_id, share_token, status, occasion, title, recipient_name,
    sender_name, cover_note, delivery_mode, open_at, expires_at, unlisted,
    pin_hash, payload, payload_bytes, cover_style, receipts, published_at,
    updated_at
  ) values (
    uid, p_token, 'published', p_occasion, p_title, p_recipient_name,
    p_sender_name, p_cover_note, coalesce(p_delivery_mode, 'immediately'),
    p_open_at, p_expires_at, coalesce(p_unlisted, true),
    case when p_pin is not null and length(p_pin) > 0
         then crypt(p_pin, gen_salt('bf', 10)) end,
    p_payload, v_bytes, v_style, coalesce(p_receipts, true), now(), now()
  )
  on conflict (share_token) do update set
    payload        = excluded.payload,
    payload_bytes  = excluded.payload_bytes,
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
    receipts       = excluded.receipts,
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

  insert into public.publish_events (creator_id) values (uid);

  if p_pin is not null and length(p_pin) > 0 then
    delete from public.keepsake_pin_attempts
      where keepsake_id = (select id from public.keepsakes where share_token = p_token);
  end if;

  return jsonb_build_object('status', 'ok', 'share_token', p_token);
end;
$$;

revoke all on function public.publish_keepsake(
  text, jsonb, text, text, text, text, text, text, timestamptz, timestamptz,
  boolean, text, jsonb, boolean
) from public, anon;
grant execute on function public.publish_keepsake(
  text, jsonb, text, text, text, text, text, text, timestamptz, timestamptz,
  boolean, text, jsonb, boolean
) to authenticated;

-- 2. The cover: adds the day it was sent and whether receipts are on.
create or replace function public.keepsake_cover(p_token text)
returns jsonb
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
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
    'cover_note', r.cover_note,
    'style', r.cover_style,
    'sent_on', to_char(r.published_at at time zone 'UTC', 'YYYY-MM-DD'),
    'receipts', r.receipts
  );
end;
$$;
grant execute on function public.keepsake_cover(text) to anon, authenticated;

-- 1. Opening: same checks as 0004, and a receipt when they're on.
create or replace function public.keepsake_open(p_token text, p_pin text)
returns jsonb
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
declare
  r public.keepsakes;
  pin_status text;
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
  pin_status := public.keepsake_pin_check(r.id, r.pin_hash, p_pin);
  if pin_status = 'locked' then
    return jsonb_build_object('status', 'locked', 'retry_at',
      (select locked_until from public.keepsake_pin_attempts where keepsake_id = r.id));
  end if;
  if pin_status <> 'ok' then
    return jsonb_build_object('status', pin_status);
  end if;
  if r.receipts then
    update public.keepsakes set
      first_opened_at = coalesce(first_opened_at, now()),
      last_opened_at  = now(),
      open_count      = least(open_count + 1, 1000000)
    where id = r.id;
  end if;
  return jsonb_build_object('status', 'ok', 'payload', r.payload);
end;
$$;
grant execute on function public.keepsake_open(text, text) to anon, authenticated;

-- What the creator sees about their own links: opened when, how often, and
-- how many replies. Runs as the caller, so row security limits it to their
-- own keepsakes; at most 200 links per call.
create or replace function public.my_keepsake_status(p_tokens text[])
returns table (
  share_token text,
  status text,
  receipts boolean,
  first_opened_at timestamptz,
  last_opened_at timestamptz,
  open_count int,
  reply_count bigint
)
language sql stable security invoker set search_path = public, pg_temp as $$
  select k.share_token, k.status, k.receipts,
         case when k.receipts then k.first_opened_at end,
         case when k.receipts then k.last_opened_at end,
         case when k.receipts then k.open_count else 0 end,
         (select count(*) from public.keepsake_responses r where r.keepsake_id = k.id)
  from public.keepsakes k
  where k.creator_id = auth.uid()
    and k.share_token = any (p_tokens[1:200]);
$$;
revoke all on function public.my_keepsake_status(text[]) from public, anon;
grant execute on function public.my_keepsake_status(text[]) to authenticated;

-- 4. Clean-up -----------------------------------------------------------------

create or replace function public.purge_expired_keepsakes()
returns int
language plpgsql security definer set search_path = public, pg_temp as $$
declare n int;
begin
  update public.keepsakes set
    status = 'stopped', payload = '{}'::jsonb, payload_bytes = 2,
    pin_hash = null, cover_note = null, title = null, recipient_name = null,
    sender_name = null, cover_style = null, stopped_at = now(), updated_at = now()
  where status = 'published'
    and expires_at is not null
    and expires_at < now() - interval '30 days';
  get diagnostics n = row_count;
  delete from public.publish_events where at < now() - interval '2 days';
  delete from public.keepsake_pin_attempts
    where updated_at < now() - interval '2 days'
      and (locked_until is null or locked_until < now());
  return n;
end;
$$;
revoke all on function public.purge_expired_keepsakes() from public, anon, authenticated;

-- Every night at 03:17 UTC, if pg_cron is enabled (Database > Extensions).
do $$
begin
  if exists (select 1 from pg_extension where extname = 'pg_cron') then
    perform cron.schedule('keepsake-purge', '17 3 * * *',
                          'select public.purge_expired_keepsakes()');
  end if;
end;
$$;
