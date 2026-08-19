# Building the Billing Tool as a real Android app

This turns the web app into an **`.apk`** — a normal Android app with its own icon,
its own storage and no browser involved. The HTML, CSS and JavaScript are bundled
*inside* the APK, so the finished app does not need GitHub, does not need an internet
connection, and is unaffected by anything a browser does to its data.

GitHub builds it for you. You do not install Android Studio, Java or the Android SDK.

\---

## What goes where

Copy the `.github` folder from this package into your repository, so that the file ends up at:

```
<your repo>/
├── index.html                        <- the app (already there)
├── manifest.webmanifest              <- (already there)
├── sw.js                             <- (already there)
├── icon-192.png, icon-512.png, …     <- (already there)
├── .nojekyll                         <- (already there)
└── .github/
    └── workflows/
        └── build-apk.yml             <- ADD THIS
```

The folder must be named exactly `.github/workflows` — GitHub looks nowhere else.

**Uploading a folder whose name starts with a dot:** the GitHub web uploader cannot
create one directly. Use **Add file → Create new file**, then type this as the filename:

```
.github/workflows/build-apk.yml
```

Typing the slashes creates the folders automatically. Paste the file contents into the
editor below and commit.

\---

## Running the build

1. In your repository, open the **Actions** tab.
2. Pick **Build Android APK** in the left-hand list.
3. Click **Run workflow** → **Run workflow**.
4. Wait roughly 5–10 minutes for the first run. Later runs are faster.
5. Open the finished run and scroll to **Artifacts** at the bottom.
Download **billing-tool-apk** — a zip containing `billing-tool.apk`.

The build also starts automatically whenever you push a tag beginning with `v`.

\---

## Installing on the phone

1. Move the `.apk` onto the phone (cable, email to yourself, cloud storage).
2. Open it in the file manager and confirm the install.
3. Android will ask whether this app source may install apps — that permission has to be
granted once, per app doing the installing (your file manager or browser).

The app then appears in the app drawer like any other, with its own icon.

\---

## Signing — read this before you distribute it

Every Android app is signed. The signature is what Android uses to decide whether a new
`.apk` is an *update* of the installed app or a *different* app.

**Without configured signing**, the workflow produces a **debug APK**. It installs and
works, but each build is signed with a newly generated throwaway key. Consequence: to
install a newer build you must **uninstall the old one first**, which deletes the data
stored in the app. Fine for trying it out, painful in regular use.

### Setting up a real signing key

Do this once. You need Java on your PC — check with `java -version`; if it is missing,
install a JDK (e.g. from adoptium.net).

```
keytool -genkeypair -v -keystore billing-tool.jks -alias billing -keyalg RSA -keysize 2048 -validity 10000
```

It asks for a password and some name fields — the names are irrelevant for private use, a
password is not. **Keep this file and the password.** Lose them and you can never publish
an update to an already-installed app again; everyone would have to uninstall and start over.

### Converting the keystore to text

A `.jks` is a binary file; GitHub secrets hold text. So the file has to be converted to
base64 first.

> \*\*This is the step people get wrong.\*\* The line below is a \*\*command you run\*\*. What goes
> into GitHub is the \*\*output\*\* it produces — a single block of several thousand random-looking
> letters. Never paste the command itself.

*Windows — PowerShell, in the folder containing the `.jks`:*

```
\[Convert]::ToBase64String(\[IO.File]::ReadAllBytes("billing-tool.jks")) | Set-Content -Encoding ascii keystore-base64.txt
notepad keystore-base64.txt
```

Notepad opens with the base64 text. `Ctrl+A`, `Ctrl+C` — that is the value.
`-Encoding ascii` matters: PowerShell's default writes an invisible byte-order mark that
breaks the decoding on the build server.

*macOS / Linux:*

```
base64 -w0 billing-tool.jks > keystore-base64.txt
```

Delete `keystore-base64.txt` afterwards — it is your signing key in readable form.

### Creating the four secrets

**Settings → Secrets and variables → Actions → New repository secret.** Four times:

|Name (field "Name")|Value (field "Secret")|
|-|-|
|`ANDROID\_KEYSTORE\_BASE64`|the base64 block from the text file|
|`ANDROID\_KEYSTORE\_PASSWORD`|the keystore password you chose|
|`ANDROID\_KEY\_ALIAS`|`billing`|
|`ANDROID\_KEY\_PASSWORD`|the key password (usually the same one)|

Type the names by hand rather than copying them out of a formatted document. Copying can
drag along stray characters — a backslash before each underscore is a common one — and
GitHub then rejects the name with *"Secret names can only contain alphanumeric characters
… or underscores"*. Only `A–Z`, `0–9` and `\_` are allowed.

Secrets stay invisible in a public repository and are masked in build logs.

The workflow checks the keystore before building and reports plainly if the value could not
be decoded or if alias and password do not match, rather than failing somewhere deep inside
Gradle.

Start the workflow again — it now produces a properly signed release APK, and future
versions install over the top of the old one with the data intact.

\---

## Changing the app name or ID

Both sit at the top of `build-apk.yml`:

```yaml
  APP\_ID: app.billingtool
  APP\_NAME: Billing Tool
```

`APP\_ID` is the app's identity for Android. It must look like a Java package
(lowercase letters, digits, dots). **Change it before the first install if at all** —
changing it later makes Android see a completely different app, installed side by side.

\---

## If the build fails

Open the failed run in the **Actions** tab and expand the red step; the error is at the
bottom of its log. Common causes:

* **"index.html not found at the repository root"** — the files are inside a subfolder in
your repository. Move them to the top level.
* **A Gradle or SDK error** — usually a version mismatch after Capacitor or the runner image
has moved on. Pinning `@capacitor/…@^7` to a fixed version such as `7.4.3` normally fixes it.
* **The run never starts** — the file is not at `.github/workflows/build-apk.yml`, or the
YAML indentation was mangled while pasting. Indentation is significant in YAML; only spaces,
never tabs.

### Deprecation warnings

Yellow annotations such as *"Node.js 20 is deprecated"* or *"setup-java v4 is deprecated"*
are **not** build failures. They mean an action is running on an older runtime that GitHub
intends to retire. The APK is built regardless. This workflow pins the current major versions:

|Action|Version used here|
|-|-|
|`actions/checkout`|v6|
|`actions/setup-node`|v6|
|`actions/setup-java`|v5|
|`actions/upload-artifact`|v7|
|`android-actions/setup-android`|v4|

Expect this list to age. When a warning names an action, bump its `@vN` in `build-apk.yml`.

### Pinning versions once a build works

`@capacitor/…@^7` accepts every future 7.x release, so a later build can behave differently
from one that worked. Once you have an APK you are happy with, look in the log of the
*"Create the Capacitor project"* step for the resolved version and pin it, e.g.
`@capacitor/core@7.4.3`. That trades automatic updates for reproducible builds.

\---

## What this does *not* do

The APK is **not** in the Play Store and is not intended to be. It is installed directly.
That is deliberate: publishing would cost a one-off 25 US dollars, require ID verification,
and — for personal developer accounts — a closed test with 12 testers over 14 continuous days.

From **30 September 2026** Google requires developer verification even for directly installed
apps, initially only in Brazil, Indonesia, Singapore and Thailand, and from 2027 worldwide.
A free *limited distribution account* covers up to 20 devices without a fee or ID check,
which is ample for a private group.

There is no equivalent route on iPhone. Apple permits installation only through the App Store
(99 US dollars per year plus review), so on iOS "Add to Home Screen" remains the only option.

