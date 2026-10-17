-- Keepsake: size limit on publishing
--
-- Photos are stored inside a keepsake's payload (shrunk and stripped of
-- location data on the phone first), so they get the same protection as the
-- rest of the content: PIN, sealed date, expiry, and deletion all apply.
-- This replaces publish_keepsake with the same function plus a 5 MB cap,
-- and it now reports a conflict instead of a false success when a share
-- token belongs to someone else.
--
-- Run this once in the Supabase SQL editor after 0002_responses.sql.

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

  -- Photos travel inside the payload. The app keeps a keepsake to about 2 MB
  -- (6 photos, shrunk on the phone); anything far beyond that is refused so
  -- the table can't be used as free bulk storage.
  if octet_length(p_payload::text) > 5 * 1024 * 1024 then
    return jsonb_build_object('status', 'too_large');
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

  -- If the token belongs to someone else the update above touches nothing;
  -- say so instead of pretending it worked.
  get diagnostics affected = row_count;
  if affected = 0 then
    return jsonb_build_object('status', 'conflict');
  end if;

  return jsonb_build_object('status', 'ok', 'share_token', p_token);
end;
$$;
