-- The envelope's look: only known values ever reach the cover.
select test.eq('A normal style is kept',
  clean_cover_style('{"envelope":"kraft","seal":"plum","mono":"SM","stickers":[{"id":"stamp","x":0.8,"y":0.2,"r":6,"s":1}]}')::text,
  '{"mono": "SM", "seal": "plum", "envelope": "kraft", "stickers": [{"r": 6, "s": 1.000, "x": 0.800, "y": 0.200, "id": "stamp"}]}');
select test.eq('Unknown paper, seal and keys are dropped',
  clean_cover_style('{"envelope":"<script>","seal":"x","evil":"yes"}')::text, '{}');
select test.eq('Numbers are clamped',
  (clean_cover_style('{"stickers":[{"id":"stamp","x":99,"y":-5,"r":720,"s":50}]}')->'stickers'->0)::text,
  '{"r": 40, "s": 1.500, "x": 1.000, "y": 0.000, "id": "stamp"}');
select test.eq('Unknown stickers and wrong types are dropped',
  jsonb_array_length(clean_cover_style('{"stickers":[{"id":"nope","x":0.5,"y":0.5,"r":0,"s":1},{"id":"heart","x":"0.5","y":0.5,"r":0,"s":1},"text"]}')->'stickers')::text,
  null);
select test.eq('Never more than six stickers',
  jsonb_array_length(clean_cover_style(jsonb_build_object('stickers',
    (select jsonb_agg('{"id":"daisy","x":0.5,"y":0.5,"r":0,"s":1}'::jsonb) from generate_series(1, 20)))) -> 'stickers')::text,
  '6');
select test.eq('Initials: lowercase dropped', clean_cover_style('{"mono":"sm"}')::text, '{}');
select test.eq('Initials: three letters dropped', clean_cover_style('{"mono":"ABC"}')::text, '{}');
select test.eq('Initials: markup dropped', clean_cover_style('{"mono":"<b>"}')::text, '{}');
select test.eq('Not an object gives nothing', coalesce(clean_cover_style('[1,2]')::text, '(none)'), '(none)');

\set C '''00000000-0000-0000-0000-00000000000c'''
set role authenticated; set request.jwt.claim.sub = :C;
select test.eq('C publishes with a messy style',
  publish_keepsake('linkCOVERCOVERCOVER01', '{}', 'love', 'Hi', 'Jamie', 'Sam', null, 'immediately', null, null, true, null,
                   '{"envelope":"kraft","mono":"S","stickers":[{"id":"daisy","x":0.5,"y":0.5,"r":10,"s":1.1},{"id":"bad","x":0,"y":0,"r":0,"s":1}]}')->>'status',
  'ok');
reset role;
set role anon; set request.jwt.claim.sub = '';
select test.eq('The cover shows only the clean style',
  (keepsake_cover('linkCOVERCOVERCOVER01')->'style')::text,
  '{"mono": "S", "envelope": "kraft", "stickers": [{"r": 10, "s": 1.100, "x": 0.500, "y": 0.500, "id": "daisy"}]}');
reset role;

-- The postmark switch: only "false" is kept, anything else is dropped.
select test.eq('Postmark off is kept',
  clean_cover_style('{"postmark": false}')::text, '{"postmark": false}');
select test.eq('Postmark on is the default, so it is not stored',
  clean_cover_style('{"postmark": true}')::text, '{}');
select test.eq('A postmark that is not a boolean is dropped',
  clean_cover_style('{"postmark": "false"}')::text, '{}');
