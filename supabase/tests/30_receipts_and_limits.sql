-- Opened receipts, the postmark date, fair-use limits and clean-up.
\set A '''00000000-0000-0000-0000-00000000000a'''
\set B '''00000000-0000-0000-0000-00000000000b'''
\set C '''00000000-0000-0000-0000-00000000000c'''

set role authenticated; set request.jwt.claim.sub = :C;
select test.eq('C publishes with receipts on (the default)',
  publish_keepsake('linkRECEIPTSON000001', '{"x":1}', 'love', 'Hi', 'Jamie', 'Sam', null,
                   'immediately', null, null, true, null)->>'status', 'ok');
select test.eq('C publishes with receipts off',
  publish_keepsake('linkRECEIPTSOFF00002', '{"x":1}', 'love', 'Hi', 'Jamie', 'Sam', null,
                   'immediately', null, null, true, null, null, false)->>'status', 'ok');
reset role;
select test.eq('The size of what was stored is noted', payload_bytes::text, octet_length('{"x": 1}')::text)
  from keepsakes where share_token = 'linkRECEIPTSON000001';

set role anon; set request.jwt.claim.sub = '';
select test.eq('The cover says receipts are on',
  (keepsake_cover('linkRECEIPTSON000001')->>'receipts'), 'true');
select test.eq('The cover says receipts are off',
  (keepsake_cover('linkRECEIPTSOFF00002')->>'receipts'), 'false');
select test.eq('The cover carries the day it was sent',
  (keepsake_cover('linkRECEIPTSON000001')->>'sent_on'), to_char(now() at time zone 'UTC', 'YYYY-MM-DD'));
select test.eq('Open with receipts on', keepsake_open('linkRECEIPTSON000001', null)->>'status', 'ok');
select test.eq('Open it again', keepsake_open('linkRECEIPTSON000001', null)->>'status', 'ok');
select test.eq('Open with receipts off', keepsake_open('linkRECEIPTSOFF00002', null)->>'status', 'ok');
select test.denied('Signed-out people cannot read receipts',
  $q$select * from my_keepsake_status(array['linkRECEIPTSON000001'])$q$);
reset role;

set role authenticated; set request.jwt.claim.sub = :C;
select test.eq('C sees it was opened twice', open_count::text, '2')
  from my_keepsake_status(array['linkRECEIPTSON000001']);
select test.eq('C sees when it was first opened', (first_opened_at is not null)::text, 'true')
  from my_keepsake_status(array['linkRECEIPTSON000001']);
select test.eq('With receipts off, nothing is recorded', coalesce(first_opened_at::text, 'none') || ' ' || open_count, 'none 0')
  from my_keepsake_status(array['linkRECEIPTSOFF00002']);
reset role;
select test.eq('With receipts off, the table holds nothing either', coalesce(first_opened_at::text, 'none'), 'none')
  from keepsakes where share_token = 'linkRECEIPTSOFF00002';

set role authenticated; set request.jwt.claim.sub = :A;
select test.eq('Someone else sees nothing about C''s links', count(*)::text, '0')
  from my_keepsake_status(array['linkRECEIPTSON000001', 'linkRECEIPTSOFF00002']);
reset role;

-- Fair use: 20 publishes in 10 minutes per account.
set role authenticated; set request.jwt.claim.sub = :B;
select test.eq('B can publish 20 in a row', count(*) filter (where s = 'ok')::text, '20')
  from (select publish_keepsake('linkRATE' || lpad(i::text, 12, '0'), '{}', 'love', null, null, null, null,
                                'immediately', null, null, true, null)->>'status' as s
        from generate_series(1, 25) i) t;
select test.eq('the 21st is turned away', publish_keepsake('linkRATE999999999999', '{}', 'love', null, null, null, null,
                'immediately', null, null, true, null)->>'status', 'rate_limited');
reset role;

-- Fair use: 100 MB of shared content per account.
insert into keepsakes (creator_id, share_token, status, payload, payload_bytes, published_at, updated_at)
values (:A, 'linkBIGBIGBIGBIGBIG01', 'published', '{}', 100 * 1024 * 1024 - 10, now(), now());
set role authenticated; set request.jwt.claim.sub = :A;
select test.eq('Going over 100 MB in total is refused',
  publish_keepsake('linkQUOTA00000000001', '{"some":"thing that is long enough"}', 'love', null, null, null, null,
                   'immediately', null, null, true, null)->>'status', 'quota');
reset role;
delete from keepsakes where share_token = 'linkBIGBIGBIGBIGBIG01';

-- Clean-up: content of keepsakes expired over 30 days ago is wiped.
insert into keepsakes (creator_id, share_token, status, payload, title, recipient_name, expires_at, published_at, updated_at)
values (:A, 'linkEXPIREDLONGAGO01', 'published', '{"letter":"old"}', 'Old', 'Jamie', now() - interval '40 days', now() - interval '60 days', now()),
       (:A, 'linkEXPIREDRECENT001', 'published', '{"letter":"new"}', 'New', 'Jamie', now() - interval '5 days', now() - interval '10 days', now());
set role authenticated; set request.jwt.claim.sub = :A;
select test.denied('The app cannot run the clean-up', 'select purge_expired_keepsakes()');
reset role;
select test.eq('Clean-up wipes what expired long ago', (purge_expired_keepsakes() >= 1)::text, 'true');
select test.eq('Its content is gone', payload::text || ' ' || coalesce(title, '-') || ' ' || status, '{} - stopped')
  from keepsakes where share_token = 'linkEXPIREDLONGAGO01';
select test.eq('Recently expired content is kept for now', payload->>'letter', 'new')
  from keepsakes where share_token = 'linkEXPIREDRECENT001';
set role authenticated; set request.jwt.claim.sub = :A;
select test.eq('A cleaned-up link stays dead',
  publish_keepsake('linkEXPIREDLONGAGO01', '{}', 'love', null, null, null, null,
                   'immediately', null, null, true, null)->>'status', 'conflict');
reset role;
