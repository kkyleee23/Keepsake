-- Keepsake: how a keepsake is wrapped
--
-- Creators can pick the envelope paper and the wax seal colour. The cover is
-- shown before opening (from keepsake_cover), so the choice is stored in its
-- own small column, with only known values allowed.
--
-- publish_keepsake gains an optional p_style; calls without it still work.
--
-- Run this once in the Supabase SQL editor after 0004_security.sql.

alter table public.keepsakes add column if not exists cover_style jsonb;
alter table public.keepsakes drop constraint if exists keepsakes_cover_style_size;
alter table public.keepsakes add constraint keepsakes_cover_style_size
  check (cover_style is null or octet_length(cover_style::text) <= 256) not valid;

-- Replace the 12-argument version with one that takes an optional style.
drop function if exists public.publish_keepsake(
  text, jsonb, text, text, text, text, text, text, timestamptz, timestamptz,
  boolean, text
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
  p_style jsonb default null
) returns jsonb
language plpgsql security definer set search_path = public, extensions, pg_temp as $$
declare
  uid uuid := auth.uid();
  affected int;
  -- Only known values are kept; anything else is dropped, never stored.
  v_style jsonb := case
    when p_style is null then null
    else jsonb_strip_nulls(jsonb_build_object(
      'envelope', case when p_style->>'envelope' in ('cream', 'kraft', 'sage', 'linen')
                       then p_style->>'envelope' end,
      'seal', case when p_style->>'seal' in ('evergreen', 'terracotta', 'honey', 'plum', 'night')
                   then p_style->>'seal' end))
  end;
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
    cover_style    = excluded.cover_style,
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

grant execute on function public.publish_keepsake(
  text, jsonb, text, text, text, text, text, text, timestamptz, timestamptz,
  boolean, text, jsonb
) to authenticated;

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
    'style', r.cover_style
  );
end;
$$;

grant execute on function public.keepsake_cover(text) to anon, authenticated;
