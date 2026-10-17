// Checks the website the way a visitor's browser sees it, with the real
// security headers on. Fails (exit code 1) if anything is off.
//
//   python3 tool/serve_dist.py website 8790 &     (or dist/ after a build)
//   NODE_PATH=$(npm root -g) node tool/check_site.js http://localhost:8790
//
// Needs Playwright (npm i -g playwright).
const { chromium } = require('playwright');

const base = (process.argv[2] || 'http://localhost:8790').replace(/\/$/, '');
const origin = new URL(base).origin;
const pages = ['/', '/privacy.html', '/no-such-page'];
const widths = [360, 390, 768, 1280];
let failures = 0;
const fail = (msg) => { failures++; console.log('  FAIL ' + msg); };
const pass = (msg) => console.log('  ok   ' + msg);

(async () => {
  const browser = await chromium.launch();

  for (const path of pages) {
    console.log(path);
    for (const width of widths) {
      const page = await browser.newPage({ viewport: { width, height: 900 }, locale: 'en-US' });
      const problems = [];
      const outside = [];
      page.on('console', (m) => {
        // The 404 page's own status is expected, not a problem.
        if (m.type() === 'error' && !(path === '/no-such-page' && /status of 404/.test(m.text()))) {
          problems.push(m.text());
        }
      });
      page.on('pageerror', (e) => problems.push(String(e)));
      page.on('request', (r) => {
        const u = new URL(r.url());
        if (!['data:', 'blob:'].includes(u.protocol) && u.origin !== origin) outside.push(r.url());
      });
      await page.addInitScript(() => {
        window.__violations = [];
        document.addEventListener('securitypolicyviolation', (e) =>
          window.__violations.push(e.violatedDirective + ' ' + e.blockedURI));
      });
      const res = await page.goto(base + path, { waitUntil: 'networkidle' });
      await page.waitForTimeout(400);
      const violations = await page.evaluate(() => window.__violations);
      const overflow = await page.evaluate(() =>
        document.documentElement.scrollWidth - document.documentElement.clientWidth);
      const label = `${width}px`;
      if (path === '/no-such-page' && res.status() !== 404) fail(`${label}: expected a 404, got ${res.status()}`);
      if (violations.length) fail(`${label}: blocked by the security policy: ${violations.join(', ')}`);
      if (problems.length) fail(`${label}: console errors: ${problems.join(' | ').slice(0, 300)}`);
      if (outside.length) fail(`${label}: requests to other sites: ${outside.join(', ')}`);
      if (overflow > 0) fail(`${label}: page scrolls sideways by ${overflow}px`);
      if (!violations.length && !problems.length && !outside.length && overflow <= 0) pass(label);
      await page.close();
    }
  }

  // The "Someone sent you one?" box only ever opens links on this site.
  console.log('code box');
  const cases = [
    ['', null],
    ['hello', null],
    ['javascript:alert(1)//receive/abcdefghijklmnopqrstuv', 'app/receive/abcdefghijklmnopqrstuv'],
    ['https://evil.example/receive/abcdefghijklmnopqrstuv?x=1', 'app/receive/abcdefghijklmnopqrstuv'],
    ['  abcdefghijklmnopqrstuv  ', 'app/receive/abcdefghijklmnopqrstuv'],
    ['abc<script>defghijklmnop', null],
  ];
  for (const [input, expected] of cases) {
    const page = await browser.newPage({ locale: 'en-US' });
    await page.goto(base + '/', { waitUntil: 'load' });
    await page.fill('#code', input);
    const nav = page.waitForURL((u) => u.pathname.includes('/app/'), { timeout: 1500 }).then(() => page.url()).catch(() => null);
    await page.click('#open-form button[type=submit]');
    const went = await nav;
    const shown = went ? false
      : await page.evaluate(() => !document.getElementById('code-error').hidden);
    const name = JSON.stringify(input);
    if (expected === null) {
      if (went) fail(`${name} should not open anything, but went to ${went}`);
      else if (!shown) fail(`${name} should show an error`);
      else pass(`${name} is refused with a message`);
    } else if (!went || new URL(went).origin !== origin || !went.endsWith(expected)) {
      fail(`${name} should open ${expected} on this site, went to ${went}`);
    } else {
      pass(`${name} opens ${expected} on this site`);
    }
    await page.close();
  }

  await browser.close();
  console.log(failures ? `\n${failures} problem(s) found.` : '\nAll checks passed.');
  process.exit(failures ? 1 : 0);
})();
