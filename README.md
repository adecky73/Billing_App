# Billing Tool — PWA

Web version of the Excel/VBA tool *"Billing Tool v11, © Andreas Deckert 2023"*.
Splits shared expenses across a group and works out who has to transfer what to whom,
using the fewest possible transfers.

Runs entirely in the browser. No server, no account, no data leaves the device.

**Ships empty.** There is no sample data and no demo sheet — the app opens with an empty
people list and an empty expense list. Everything you enter is stored only in the browser
of the device you enter it on, and can be exported to a `.json` file at any time.

## Files

| File | Purpose |
|---|---|
| `index.html` | The whole app — markup, styles, calculation engine, UI. Self-contained. |
| `manifest.webmanifest` | Makes it installable as an app (name, icons, standalone display). |
| `sw.js` | Service worker — caches the app so it works with no network. |
| `icon-192.png`, `icon-512.png`, `icon-maskable-512.png` | App icons. |
| `icon.svg` | The icon artwork as vector — the source the PNGs are rendered from. |
| `start-server.cmd` | Windows convenience: double-click to serve this folder on `localhost:8000`. Not needed for the app itself. |

## Running it

**Just trying it out:** open `index.html` by double-clicking. Everything works except
installation and offline caching — browsers only allow service workers over `https://`
or `localhost`.

**Locally with full PWA behaviour** — you need a local web server, because browsers refuse
to register a service worker on `file://`.

*Windows:* double-click **`start-server.cmd`** in this folder. It picks whichever Python it
finds and opens the browser for you.

If you prefer to type it yourself, open a terminal in this folder and use:

```
py -m http.server 8000
```

Do **not** use `python3` on Windows. Windows ships a stub at
`%LOCALAPPDATA%\Microsoft\WindowsApps\python3.exe` whose only job is to open the Microsoft
Store, and the installer from python.org creates `python.exe` and `py.exe` — never
`python3.exe`. So `python3` reports *"Python wurde nicht gefunden"* even when Python is
perfectly well installed. `py` is the official launcher and always works.

*macOS / Linux:*

```bash
cd <this folder>
python3 -m http.server 8000
```

*No Python, but Node installed* (any platform):

```
npx serve -l 8000
```

Then open <http://localhost:8000>.

**Installing on a phone** requires the files to sit on an HTTPS URL — a phone cannot install
an app from a file on your PC. Any static web host works, and several are free.

### Option A — Netlify Drop (easiest, no account, ~1 minute)

1. Open <https://app.netlify.com/drop> in your browser.
2. Drag the **unzipped folder** (the one containing `index.html`) onto the page.
3. You get a URL like `https://calm-otter-123abc.netlify.app` immediately. Open it on your phone.

The free URL stays alive; sign up afterwards if you want to keep or rename it.

### Option B — GitHub Pages (free, permanent, needs a GitHub account)

This is what the earlier one-line version of this README meant. Long form:

1. **Create the repository.** On <https://github.com>, click **+** (top right) → **New repository**.
   Give it a name, e.g. `billing-tool`. Leave it **Public** — with a free GitHub account,
   Pages only works on public repositories. Click **Create repository**.
2. **Upload the files.** On the new repo's page, click **uploading an existing file**
   (or **Add file** → **Upload files**). Drag in the *contents* of the folder —
   `index.html`, `manifest.webmanifest`, `sw.js` and the three `.png` icons — **not** the folder
   itself, and not the zip. `index.html` has to sit at the top level of the repository.
   Then click **Commit changes**.
3. **Switch Pages on.** In the repository, open the **Settings** tab (top right of the repo,
   next to *Insights* — not your personal account settings). In the left sidebar, under
   **Code and automation**, click **Pages**.
4. Under **Build and deployment** → **Source**, choose **Deploy from a branch**.
   Two dropdowns appear below. Set the left one (branch) to **main**, and leave the right one
   (folder) at **/ (root)** — that just means "the site lives at the top of the repo", which is
   where you uploaded `index.html`. Click **Save**.
5. Wait about a minute, then reload the Pages settings page. It shows
   *"Your site is live at …"* with the address
   `https://<your-username>.github.io/<repository-name>/`. Open that on your phone.

So `main` and `/ (root)` are simply the two dropdown values in step 4 — a branch name and a
folder — not a path you type anywhere.

**Public repository = the app's source code is visible to anyone.** That is harmless here: the
app ships without any data, and every sheet you enter stays in your own browser. Nothing you
type is ever uploaded to the host.

### Option C — anything else

**Cloudflare Pages**, **Vercel**, or any web space you already rent: upload the folder as-is.
No build step, no configuration — these are plain static files.

Then open that URL on the phone:

- **Android / Chrome:** an "Install app" button appears in the header, or use ⋮ → *Add to Home screen*.
- **iPhone / Safari:** Share → *Add to Home Screen*. (Safari never shows an install prompt;
  the button stays hidden there — that is Apple's behaviour, not a bug.)

After the first visit the app is cached and opens offline.

## Using it

1. **People** — type a name and press Enter. Names are upper-cased automatically, same as the VBA did.
2. **Expenses** — pick who paid, what it was, how much, then tap the cell under everyone
   who shares that cost.
   - one tap = one share (the old `x`)
   - second tap = double share (the old `xx`), e.g. someone bringing a partner
   - shift-click (or repeated taps) goes to 3, 4, … shares — the generalisation the VBA
     comments listed as an idea but never implemented
   - tapping a **column header** includes or excludes that person in *every* row
3. **Balance** — green means the group owes them money, red means they owe the group.
4. **Settlement** — the concrete list of transfers.

Everything recalculates as you type and is saved in the browser automatically.
`Menu` has JSON save/open (for backups and moving between devices), CSV export for Excel,
a plain-text summary to paste into a chat, and print / save-as-PDF.

## Look and feel

The interface follows Android's current design language (Material 3): tonal surfaces
instead of drop shadows, pill-shaped buttons, 16/28px corner radii, Roboto, and 48dp
touch targets. Light and dark follow the phone's setting automatically; the ◐ button
overrides it.

Where the browser exposes the operating system's own accent colour — Firefox does, via the
CSS `AccentColor` keyword — the app adopts it, so it matches the rest of the phone. The
accent is only ever used as a *tint*: filled surfaces mix 16% of it into the background and
their text mixes 30% into the foreground colour. That is deliberate. Handing an arbitrary
system accent straight to a button as its fill can drop the label to 2.4:1 contrast on a
yellow accent; the tonal pair measures at least 6.2:1 for any accent, including pure white
and pure black. Verified by rendering the actual pixels under eight simulated accents in
both light and dark.

## What changed against the Excel version

- **Cent-exact arithmetic.** All money is handled as whole cents. Each expense's split is
  distributed so the parts add up to the amount to the cent, and the balances always sum
  to exactly zero. The rounding drift the VBA header lists under *"BUGS not solved yet"*
  cannot occur. Expect single-cent differences against the old workbook wherever an amount
  was not evenly divisible by its number of sharers — the app's figure is the correct one.
- **Any number of shares** per person per expense, not just `x` / `xx`.
- **Provably minimal transfers.** The transfer count is minimised by partitioning the
  balances into zero-sum groups (exact subset DP up to 14 people with a non-zero balance,
  greedy above that — greedy still never exceeds *n−1* transfers). The VBA's nested
  combination search is replaced entirely.
- **No sheet protection, no event juggling, no `Application.EnableEvents` dance** — nothing
  can get stuck in a broken state after an error.
- Removing a person no longer silently deletes a whole row; their entries are unassigned
  and flagged instead.

## Development

```
src/core.js     calculation engine (parsing, splitting, balances, settlement)
src/app.html    UI shell with a /*__CORE__*/ placeholder
src/sw.js       service worker
build.py        inlines core.js into app.html, renders icons, writes dist/ and the zip
test/test.js    unit tests for the engine        (node test/test.js)
test/e2e.js     browser tests incl. offline mode (node test/e2e.js — needs playwright)
```

Edit files in `src/`, then run `python3 build.py`. Bump `CACHE` in `src/sw.js` whenever you
redeploy, otherwise installed copies keep serving the cached old version.
