#!/usr/bin/env bash
# Runs the database tests against a local Postgres (15 or newer):
#   1. a fresh database with stand-ins for what Supabase provides,
#   2. every migration, twice (they must be safe to run again),
#   3. every file in supabase/tests/ named 1*.sql and up.
# Exits non-zero on any failed check or unexpected error.
#
# Needs psql/createdb/dropdb in PATH and a user that can create databases.
# Usage: tool/test_db.sh        (DB=name to pick the database name)
set -euo pipefail
cd "$(dirname "$0")/.."
DB="${DB:-keepsake_test}"

dropdb --if-exists "$DB" >/dev/null 2>&1
createdb "$DB"
run() { psql -X -q -v ON_ERROR_STOP=1 -d "$DB" -f "$1" >/dev/null 2>&1 || { echo "Setup failed in $1:"; psql -X -q -v ON_ERROR_STOP=1 -d "$DB" -f "$1" 2>&1 | grep -m3 ERROR; exit 1; }; }

run supabase/tests/00_supabase_stub.sql
for pass in 1 2; do
  for f in supabase/migrations/*.sql; do run "$f"; done
done
run supabase/tests/01_helpers.sql
echo "Migrations: all applied twice."

failed=0
for f in supabase/tests/[1-9]*.sql; do
  echo "== $(basename "$f")"
  out="$(psql -X -q -At -d "$DB" -f "$f" 2>&1 || true)"
  echo "$out" | grep -E '^(ok|FAIL)' || true
  if echo "$out" | grep -qE '^FAIL|ERROR'; then
    failed=1
    echo "$out" | grep -E 'ERROR' || true
  fi
done

if [[ $failed -ne 0 ]]; then
  echo; echo "Some database checks failed."; exit 1
fi
echo; echo "All database checks passed."
