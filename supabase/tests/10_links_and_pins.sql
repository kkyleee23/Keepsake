-- Links: who can publish where, stopping, dead links staying dead, PINs.
\set A '''00000000-0000-0000-0000-00000000000a'''
\set B '''00000000-0000-0000-0000-00000000000b'''

set role authenticated; set request.jwt.claim.sub = :A;
select test.eq('A publishes a link',
  publish_keepsake('linkAAAAAAAAAAAAAAAA1', '{"x":1}', 'birthday', 'Hi', 'Jamie', 'Sam', 'note',
                   'immediately', null, null, true, null)->>'status', 'ok');

set request.jwt.claim.sub = :B;
select test.eq('B cannot take over A''s link',
  publish_keepsake('linkAAAAAAAAAAAAAAAA1', '{"evil":1}', 'birthday', 'Evil', 'Jamie', 'X', null,
                   'immediately', null, null, true, null)->>'status', 'conflict');
select test.eq('B cannot stop A''s link', stop_sharing('linkAAAAAAAAAAAAAAAA1')->>'status', 'not_found');
reset role;

set role anon; set request.jwt.claim.sub = '';
select test.eq('Anyone with the link can open it',
  keepsake_open('linkAAAAAAAAAAAAAAAA1', null)->>'status', 'ok');
select test.eq('A recipient can reply',
  respond_to_keepsake('linkAAAAAAAAAAAAAAAA1', null, 'love', 'thank you', 'Jamie')->>'status', 'ok');
select test.denied('Signed-out people cannot stop links', 'select stop_sharing(''linkAAAAAAAAAAAAAAAA1'')');
select test.denied('Signed-out people cannot read retired links', 'select count(*) from retired_share_tokens');
select test.denied('Signed-out people cannot publish',
  $q$select publish_keepsake('linkZZZZZZZZZZZZZZZZ9', '{}', 'love', null, null, null, null, null, null, null, true, null)$q$);
select test.eq('Nobody can read the keepsakes table directly', count(*)::text, '0') from keepsakes;
reset role;

set role authenticated; set request.jwt.claim.sub = :A;
-- Every write goes through publish_keepsake and its checks (0004), even
-- after the earlier files have been run again.
select test.denied('Creators cannot insert into the table directly',
  $q$insert into keepsakes (creator_id, share_token, payload) values (auth.uid(), 'linkDIRECTDIRECT0001', '{}')$q$);
select test.denied('Creators cannot edit the table directly',
  $q$update keepsakes set payload = '{"edited":1}' where share_token = 'linkAAAAAAAAAAAAAAAA1'$q$);
select test.eq('A stops sharing', stop_sharing('linkAAAAAAAAAAAAAAAA1')->>'status', 'ok');
select test.eq('Replies are kept after stopping', count(*)::text, '1')
  from my_keepsake_responses('linkAAAAAAAAAAAAAAAA1');
select test.eq('A stopped link cannot be switched back on',
  publish_keepsake('linkAAAAAAAAAAAAAAAA1', '{"x":2}', 'birthday', 'Hi', 'Jamie', 'Sam', null,
                   'immediately', null, null, true, null)->>'status', 'conflict');
reset role;

select test.eq('Stopping deletes the content', payload::text, '{}')
  from keepsakes where share_token = 'linkAAAAAAAAAAAAAAAA1';
select test.eq('Stopping deletes the names', coalesce(recipient_name, '(gone)'), '(gone)')
  from keepsakes where share_token = 'linkAAAAAAAAAAAAAAAA1';

set role anon; set request.jwt.claim.sub = '';
select test.eq('A stopped link shows not found',
  keepsake_open('linkAAAAAAAAAAAAAAAA1', null)->>'status', 'not_found');
select test.eq('A stopped link has no cover',
  keepsake_cover('linkAAAAAAAAAAAAAAAA1')->>'status', 'not_found');
select test.eq('A stopped link takes no replies',
  respond_to_keepsake('linkAAAAAAAAAAAAAAAA1', null, 'love', 'hi', 'Jamie')->>'status', 'not_found');
reset role;

-- Deleted links stay dead, even for whoever knew them.
set role authenticated; set request.jwt.claim.sub = :A;
select test.eq('A publishes a second link',
  publish_keepsake('linkBBBBBBBBBBBBBBBB2', '{"x":1}', 'love', 'Hi', 'Jamie', 'Sam', null,
                   'immediately', null, null, true, null)->>'status', 'ok');
delete from keepsakes where share_token = 'linkBBBBBBBBBBBBBBBB2';
select test.eq('A deleted link cannot be reused by its owner',
  publish_keepsake('linkBBBBBBBBBBBBBBBB2', '{"x":1}', 'love', 'Hi', 'Jamie', 'Sam', null,
                   'immediately', null, null, true, null)->>'status', 'conflict');
set request.jwt.claim.sub = :B;
select test.eq('A deleted link cannot be claimed by someone else',
  publish_keepsake('linkBBBBBBBBBBBBBBBB2', '{"evil":1}', 'love', 'Evil', 'Jamie', 'X', null,
                   'immediately', null, null, true, null)->>'status', 'conflict');
reset role;

-- PINs: hashed, and guessing locks it.
set role authenticated; set request.jwt.claim.sub = :A;
select test.eq('A publishes with a PIN',
  publish_keepsake('linkPPPPPPPPPPPPPPPP3', '{"secret":1}', 'love', 'Hi', 'Jamie', 'Sam', null,
                   'immediately', null, null, true, '4821')->>'status', 'ok');
select test.eq('A PIN must be 4 to 12 digits',
  publish_keepsake('linkPPPPPPPPPPPPPPPP4', '{}', 'love', null, null, null, null,
                   'immediately', null, null, true, '12ab')->>'status', 'invalid_pin');
reset role;
select test.eq('The PIN is never stored as typed', (pin_hash <> '4821' and pin_hash like '$2%')::text, 'true')
  from keepsakes where share_token = 'linkPPPPPPPPPPPPPPPP3';

set role anon; set request.jwt.claim.sub = '';
select test.eq('No PIN, no content', keepsake_open('linkPPPPPPPPPPPPPPPP3', null)->>'status', 'pin_required');
select test.eq('Wrong PIN 1', keepsake_open('linkPPPPPPPPPPPPPPPP3', '0000')->>'status', 'wrong_pin');
select test.eq('Wrong PIN 2', keepsake_open('linkPPPPPPPPPPPPPPPP3', '0001')->>'status', 'wrong_pin');
select test.eq('Wrong PIN 3', keepsake_open('linkPPPPPPPPPPPPPPPP3', '0002')->>'status', 'wrong_pin');
select test.eq('Wrong PIN 4', keepsake_open('linkPPPPPPPPPPPPPPPP3', '0003')->>'status', 'wrong_pin');
select test.eq('The fifth wrong PIN locks it', keepsake_open('linkPPPPPPPPPPPPPPPP3', '0004')->>'status', 'locked');
select test.eq('Even the right PIN waits while locked',
  keepsake_open('linkPPPPPPPPPPPPPPPP3', '4821')->>'status', 'locked');
select test.eq('Replies are locked too',
  respond_to_keepsake('linkPPPPPPPPPPPPPPPP3', '4821', 'love', 'hi', 'Jamie')->>'status', 'locked');
select test.denied('Signed-out people cannot read PIN attempts', 'select count(*) from keepsake_pin_attempts');
reset role;
update keepsake_pin_attempts set locked_until = now() - interval '1 second';
set role anon; set request.jwt.claim.sub = '';
select test.eq('After the wait, the right PIN opens it',
  keepsake_open('linkPPPPPPPPPPPPPPPP3', '4821')->>'status', 'ok');
reset role;

-- Sealed until a date.
set role authenticated; set request.jwt.claim.sub = :A;
select test.eq('A publishes one sealed until tomorrow',
  publish_keepsake('linkSSSSSSSSSSSSSSSS5', '{"later":1}', 'birthday', 'Hi', 'Jamie', 'Sam', null,
                   'scheduled', now() + interval '1 day', null, true, null)->>'status', 'ok');
reset role;
set role anon; set request.jwt.claim.sub = '';
select test.eq('A sealed keepsake stays shut', keepsake_open('linkSSSSSSSSSSSSSSSS5', null)->>'status', 'sealed');
select test.eq('Sealed means no content at all', (keepsake_open('linkSSSSSSSSSSSSSSSS5', null) ? 'payload')::text, 'false');
reset role;

-- Size and shape limits.
set role authenticated; set request.jwt.claim.sub = :A;
select test.eq('Content over 5 MB is refused',
  publish_keepsake('linkLLLLLLLLLLLLLLLL6', jsonb_build_object('x', repeat('a', 5 * 1024 * 1024 + 10)),
                   'love', null, null, null, null, 'immediately', null, null, true, null)->>'status', 'too_large');
select test.eq('A malformed link is refused',
  publish_keepsake('short', '{}', 'love', null, null, null, null, 'immediately', null, null, true, null)->>'status', 'invalid');
reset role;
