# Keepsake setup

What has to be set up outside the code for everything to work. Do the steps
in order. Each one says how to check it worked.

## 1. Database (Supabase SQL Editor)

Open your project at supabase.com, go to **SQL Editor**, click **New query**,
paste the whole file, and click **Run**. Do each file once, in this order.

| File | What it adds | Already done? |
| --- | --- | --- |
| `supabase/migrations/0001_init.sql` | Keepsakes table, privacy rules, publish / cover / open functions | Yes, you ran this earlier |
| `supabase/migrations/0002_responses.sql` | Replies from recipients (only you can read them), rate limit | Run it |
| `supabase/migrations/0003_payload_limit.sql` | 5 MB size cap per keepsake (photos live inside it), and a fix so publishing with someone else's link reports a conflict instead of a fake success | Run it |

Running a file twice is safe.

**Check:** in **Table Editor** you should see `keepsakes` and
`keepsake_responses`. In **Database > Functions** you should see
`publish_keepsake`, `keepsake_cover`, `keepsake_open`, `respond_to_keepsake`
and `my_keepsake_responses`.

## 2. Sign-in settings (Authentication)

1. **Authentication > Sign In / Providers > Email**: make sure Email is on.
2. **Confirm email**: while you are testing, turn it **off**. With it on,
   the confirmation link opens `localhost:3000`, which is a page that doesn't
   exist on your phone. Turn it back on once step 4 is done.
3. **Anonymous sign-ins**: turn this **off**. The app no longer uses it, and
   anonymous accounts are treated as signed out.

**Check:** create an account in the app. You should land on Home right away.

## 3. Nothing else for photos

Photos are stored inside the keepsake (shrunk on the phone, location data
removed), so there is no Storage bucket to create. Up to 6 photos per
keepsake.

## 4. Later: a home for share links

Share links look like `https://keepsake.app/receive/<code>`. You don't own
that domain, so in a browser those links go nowhere yet. Until this step is
done, recipients can still open a keepsake inside the app: **Profile > Open
with a code**, then paste the link or code.

To make links open in any browser:

1. Build the web app: `flutter build web --dart-define-from-file=dart_defines.json`
2. Upload the `build/web` folder to a free static host (Netlify, Vercel or
   Cloudflare Pages all work). Set the host to send every path to
   `index.html` so `/receive/...` links load the app.
3. Put your new address in `dart_defines.json` as `KEEPSAKE_LINK_BASE`
   (for example `https://keepsake-yourname.netlify.app`) and rebuild.
4. In Supabase, **Authentication > URL Configuration**: set **Site URL** to
   that same address, and add it under **Redirect URLs**. Now email
   confirmation and password reset links land on a real page, and you can
   turn **Confirm email** back on.

## Keys, for reference

- The app only contains the **publishable** key (`sb_publishable_...`).
  That key is meant to be public; the privacy rules in the SQL files are what
  protect the data.
- Never put the **secret** key (`sb_secret_...`) in the app, in
  `dart_defines.json`, or in git.
