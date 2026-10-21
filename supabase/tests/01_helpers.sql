-- Tiny assertion helpers. Each check prints one line: "ok" or "FAIL".
create schema if not exists test;
grant usage on schema test to anon, authenticated;

create or replace function test.eq(label text, got text, want text)
returns text language sql as $$
  select case when got is not distinct from want
              then 'ok    ' || label
              else 'FAIL  ' || label || ': got ' || coalesce(got, '(null)')
                   || ', wanted ' || coalesce(want, '(null)') end;
$$;

-- Runs q as the current role and expects it to be refused.
create or replace function test.denied(label text, q text)
returns text language plpgsql as $$
begin
  execute q;
  return 'FAIL  ' || label || ': it was allowed';
exception when insufficient_privilege then
  return 'ok    ' || label;
end;
$$;

grant execute on all functions in schema test to anon, authenticated;
