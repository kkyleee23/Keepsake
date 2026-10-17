-- Keepsake: security hardening
--
-- 1. PIN guessing is limited. Five wrong PINs lock a keepsake for 15 minutes,
--    then 30, 60 and so on (up to a day). Opening and replying share the
--    same counter. A 4-digit PIN can no longer be brute-forced.
-- 2. Every write to keepsakes goes through publish_keepsake, which checks
--    input. Creators can still read and delete their own rows, but can no
--    longer insert or update rows directly (which skipped those checks).
-- 3. Hard limits on the table itself, so nothing oversized gets stored no
--    matter how it arrives.
-- 4. delete_my_account(): a signed-in person can delete their own account.
--    Their keepsakes, replies and PIN counters go with it.
--
-- Run this once in the Supabase SQL editor after 0003_payload_limit.sql.

-- 1. PIN attempt limiting ---------------------------------------------------

create table if not exists public.keepsake_pin_attempts (
  keepsake_id  uuid primary key references public.keepsakes (id) on delete cascade,
  failures     int not null default 0,
  locked_until timestamptz,
  updated_at   timestamptz not null default now()
);

-- Only the functions below touch this table. No policies means no direct
-- access for anyone using the app's keys.
alter table public.keepsake_pin_attempts enable row level security;
revoke all on public.keepsake_pin_attempts from anon, authenticated;

-- Checks a PIN for a keepsake and records the result.
-- Returns: ok, pin_required, wrong_pin, or locked.
create or replace function public.keepsake_pin_check(p_keepsake_id uuid, p_pin_hash text, p_pin text)
returns text
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
declare
  a public.keepsake_pin_attempts;
  lock_minutes int;
begin
  if p_pin_hash is null then
    return 'ok';
  end if;
  if p_pin is null or length(p_pin) = 0 then
    return 'pin_required';
  end if;

  select * into a from public.keepsake_pin_attempts
    where keepsake_id = p_keepsake_id for update;
  if found and a.locked_until is not null and now() < a.locked_until then
    return 'locked';
  end if;

  if length(p_pin) <= 12 and crypt(p_pin, p_pin_hash) = p_pin_hash then
    delete from public.keepsake_pin_attempts where keepsake_id = p_keepsake_id;
    return 'ok';
  end if;

  insert into public.keepsake_pin_attempts (keepsake_id, failures, updated_at)
  values (p_keepsake_id, 1, now())
  on conflict (keepsake_id) do update
    set failures = public.keepsake_pin_attempts.failures + 1,
        updated_at = now()
  returning * into a;

  if a.failures % 5 = 0 then
    -- 15, 30, 60, 120 ... minutes, never more than a day.
    lock_minutes := least(15 * (2 ^ (a.failures / 5 - 1))::int, 1440);
    update public.keepsake_pin_attempts
      set locked_until = now() + make_interval(mins => lock_minutes)
      where keepsake_id = p_keepsake_id;
    return 'locked';
  end if;
  return 'wrong_pin';
end;
$$;

-- Internal only: not callable from the app.
revoke all on function public.keepsake_pin_check(uuid, text, text) from public, anon, authenticated;

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
  return jsonb_build_object('status', 'ok', 'payload', r.payload);
end;
$$;

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
  pin_status text;
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
  pin_status := public.keepsake_pin_check(r.id, r.pin_hash, p_pin);
  if pin_status = 'locked' then
    return jsonb_build_object('status', 'locked');
  end if;
  if pin_status <> 'ok' then
    return jsonb_build_object('status', 'wrong_pin');
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

-- 2. Writes only through publish_keepsake ------------------------------------

drop policy if exists "creator inserts own" on public.keepsakes;
drop policy if exists "creator updates own" on public.keepsakes;
revoke insert, update on public.keepsakes from anon, authenticated;
revoke insert, update on public.keepsake_responses from anon, authenticated;

-- 3. Hard limits on the table ------------------------------------------------
-- NOT VALID: enforced for every new or changed row without failing on rows
-- that already exist.

alter table public.keepsakes drop constraint if exists keepsakes_payload_size;
alter table public.keepsakes add constraint keepsakes_payload_size
  check (octet_length(payload::text) <= 5 * 1024 * 1024) not valid;
alter table public.keepsakes drop constraint if exists keepsakes_text_sizes;
alter table public.keepsakes add constraint keepsakes_text_sizes check (
  char_length(coalesce(title, '')) <= 200
  and char_length(coalesce(recipient_name, '')) <= 120
  and char_length(coalesce(sender_name, '')) <= 120
  and char_length(coalesce(cover_note, '')) <= 600
  and char_length(coalesce(occasion, '')) <= 40
) not valid;
alter table public.keepsakes drop constraint if exists keepsakes_token_shape;
alter table public.keepsakes add constraint keepsakes_token_shape
  check (share_token ~ '^[A-Za-z0-9_-]{16,64}$') not valid;
alter table public.keepsakes drop constraint if exists keepsakes_delivery_mode;
alter table public.keepsakes add constraint keepsakes_delivery_mode
  check (delivery_mode in ('immediately', 'scheduled', 'countdown', 'manual')) not valid;

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
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
declare
  uid uuid := auth.uid();
  affected int;
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

  insert into public.keepsakes (
    creator_id, share_token, status, occasion, title, recipient_name,
    sender_name, cover_note, delivery_mode, open_at, expires_at, unlisted,
    pin_hash, payload, published_at, updated_at
  ) values (
    uid, p_token, 'published', p_occasion, p_title, p_recipient_name,
    p_sender_name, p_cover_note, coalesce(p_delivery_mode, 'immediately'),
    p_open_at, p_expires_at, coalesce(p_unlisted, true),
    case when p_pin is not null and length(p_pin) > 0
         then crypt(p_pin, gen_salt('bf', 10)) end,
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
                          then crypt(p_pin, gen_salt('bf', 10))
                          else public.keepsakes.pin_hash end,
    updated_at     = now()
  where public.keepsakes.creator_id = uid;

  get diagnostics affected = row_count;
  if affected = 0 then
    return jsonb_build_object('status', 'conflict');
  end if;

  -- A new PIN starts with a clean slate of attempts.
  if p_pin is not null and length(p_pin) > 0 then
    delete from public.keepsake_pin_attempts
      where keepsake_id = (select id from public.keepsakes where share_token = p_token);
  end if;

  return jsonb_build_object('status', 'ok', 'share_token', p_token);
end;
$$;

-- 4. Account deletion --------------------------------------------------------

create or replace function public.delete_my_account()
returns jsonb
language plpgsql security definer set search_path = public, pg_temp as $$
declare uid uuid := auth.uid();
begin
  if uid is null then
    return jsonb_build_object('status', 'unauthenticated');
  end if;
  -- Keepsakes, replies and PIN counters cascade from here.
  delete from public.keepsakes where creator_id = uid;
  delete from auth.users where id = uid;
  return jsonb_build_object('status', 'ok');
end;
$$;

revoke all on function public.delete_my_account() from public, anon;
grant execute on function public.delete_my_account() to authenticated;
grant execute on function public.keepsake_open(text, text) to anon, authenticated;
grant execute on function public.respond_to_keepsake(text, text, text, text, text) to anon, authenticated;
