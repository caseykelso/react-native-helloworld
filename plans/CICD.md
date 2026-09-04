# CI/CD Plan

## Phase 1: Android Debug & Release Build on GitHub Actions

### Goal

Build the React Native Android app (unsigned debug + release) on every commit using GitHub Actions on `ubuntu-24.04` runners, producing build artifacts uploaded as GitHub Release assets.

---

### Trigger

```yaml
on:
  push:
    branches: [ "**" ]
```

---

### Workflow File

`.github/workflows/ci-android.yml`

---

### Jobs

#### Job: `build-android`

**Runner**: `ubuntu-24.04`

#### Steps

**1. Checkout**

- `actions/checkout@v4` with `fetch-depth: 0` (needed for version hash via `git rev-parse`)

**2. Setup Node.js**

- `actions/setup-node@v4`
- `node-version-file: '.nvmrc'` (resolves to `22.13.0`)
- `cache: 'npm'`
- Run `cd prototype && npm ci`

**3. Setup Java 17**

- `actions/setup-java@v4`
- `java-version: '17'`
- `distribution: 'temurin'`

**4. Setup Android SDK**

Download and install the Android SDK command-line tools matching the existing Makefile setup:

- Download `commandlinetools-linux-9477386_latest.zip` from `https://buildroot-sources.s3.amazonaws.com/commandlinetools-linux-9477386_latest.zip`
- Extract to `$HOME/cmdline-tools`
- Set environment variables:
  - `ANDROID_SDK_ROOT`: `$HOME/cmdline-tools/platforms`
  - `ANDROID_HOME`: `$HOME/cmdline-tools/platforms`
  - Add to `PATH`: `$HOME/cmdline-tools/bin`, `$HOME/cmdline-tools/platform-tools`, `$HOME/cmdline-tools/platforms/tools`
- Use `sdkmanager` to install:
  - `platform-tools`
  - `platforms;android-37`
  - `build-tools;36.0.0`
  - `ndk;27.1.12297006`
  - `cmake;3.22.1`

**5. Clone teakerne**

```bash
git clone --branch 0.0.6 https://github.com/caseykelso/react-native-teakerne.git teakerne
```

**6. Build React Native Android Bundle**

```bash
cd prototype
npx react-native bundle \
  --platform android \
  --dev false \
  --entry-file index.js \
  --bundle-output android/app/src/main/assets/index.android.bundle \
  --assets-dest android/app/src/main/res
```

**7. Build APK and AAB with Gradle**

```bash
cd prototype/android
./gradlew assembleDebug
./gradlew assembleRelease
./gradlew bundleDebug
./gradlew bundleRelease
```

**8. Package Artifacts**

Copy build outputs into `dist/` with hash-based naming matching the Makefile conventions:

```bash
HASH=$(git rev-parse --short=10 HEAD)
DIST_DIR=dist

mkdir -p $DIST_DIR

# Copy APKs
cp prototype/android/app/build/outputs/apk/debug/app-debug.apk \
   $DIST_DIR/prototype-debug-$HASH.apk
cp prototype/android/app/build/outputs/apk/release/app-release.apk \
   $DIST_DIR/prototype-release-$HASH.apk

# Copy AABs
cp prototype/android/app/build/outputs/bundle/debug/app-debug.aab \
   $DIST_DIR/prototype-debug-$HASH.aab
cp prototype/android/app/build/outputs/bundle/release/app-release.aab \
   $DIST_DIR/prototype-release-unsigned-$HASH.aab

# Generate md5sums and tar.gz archive
cd $DIST_DIR
md5sum prototype-debug-$HASH.apk > prototype-debug-$HASH.apk.md5
md5sum prototype-release-$HASH.apk > prototype-release-$HASH.apk.md5
md5sum prototype-debug-$HASH.aab > prototype-debug-$HASH.aab.md5
md5sum prototype-release-unsigned-$HASH.aab > prototype-release-unsigned-$HASH.aab.md5
tar czvf prototype-android-$HASH.tar.gz \
  prototype-debug-$HASH.apk prototype-debug-$HASH.apk.md5 \
  prototype-release-$HASH.apk prototype-release-$HASH.apk.md5 \
  prototype-debug-$HASH.aab prototype-debug-$HASH.aab.md5 \
  prototype-release-unsigned-$HASH.aab prototype-release-unsigned-$HASH.aab.md5
md5sum prototype-android-$HASH.tar.gz > prototype-android-$HASH.tar.gz.md5
```

**9. Upload Artifacts**

- `actions/upload-artifact@v4` for `prototype-android-*.tar.gz` and `prototype-android-*.tar.gz.md5`

**10. Create/Update GitHub Release**

- `softprops/action-gh-release@v1`
- `tag_name: ${{ github.sha }}`
- `draft: false`
- `prerelease: false`
- Attach the tar.gz artifact and its md5sum
- `fail_on_unmatched: false`
- `update_existing: true` (each push updates the release rather than creating duplicates)

---

### Environment Variables

| Variable | Value |
|---|---|
| `JAVA_HOME` | Set by `actions/setup-java` |
| `ANDROID_HOME` | `$HOME/cmdline-tools/platforms` |
| `ANDROID_SDK_ROOT` | `$HOME/cmdline-tools/platforms` |
| `ANDROID_SDK_DIR` | `$HOME/cmdline-tools` |
| `PATH` | Includes `$HOME/cmdline-tools/bin`, `$HOME/cmdline-tools/platform-tools`, `$HOME/cmdline-tools/platforms/tools` |
| `NODE_VERSION` | `22.13.0` |

---

### Required GitHub Secrets

None required for Phase 1 (unsigned builds only). The keystore step from the Makefile (`sign.android.upload.key`) is not part of this phase.

---

### Required GitHub Permissions

The workflow needs `contents: write` permission to create/update releases:

```yaml
permissions:
  contents: write
```

---

## Caching Strategy (Phase 2 -- Not Implemented in Phase 1)

The following caching layers will be added in a future phase to reduce build times:

### Gradle Cache

- Cache `$HOME/.gradle/caches` and `$HOME/.gradle/wrapper`
- Key: `android-gradle-${{ hashFiles('prototype/android/gradle/wrapper/gradle-wrapper.properties') }}`
- Restore keys: `android-gradle-`

### npm Cache

- `actions/setup-node@v4` with `cache: 'npm'` handles `~/.npm` caching when run with `npm ci`
- Key: `npm-${{ hashFiles('prototype/package-lock.json') }}`

### Android SDK Cache

- Cache `$HOME/cmdline-tools` (once downloaded, the SDK platform, NDK, and build-tools don't change often)
- Key: `android-sdk-${{ hashFiles('**/commandlinetools*.zip') }}` or a static key with a TTL
- Restore keys: `android-sdk-`

### Gradle Build Cache

- `$HOME/.gradle/caches/build-cache-1` for incremental builds
- `$HOME/.gradle/caches/transforms-*` for Android transform caching

---

## Concurrent Jobs Note

The workflow is currently a single job (`build-android`) since Phase 1 only targets Android. Future phases will add:

- `build-android-signed` (separate job requiring keystore secrets)
- `build-ios` (requires `macos-latest` runner)
- These will run concurrently as separate jobs in the workflow, with a release job that aggregates artifacts from all completed jobs.

---

## Mapping from Existing Makefile Targets

| Makefile Target | GitHub Actions Step |
|---|---|
| `nvm.install` | `actions/setup-node@v4` with `node-version-file: '.nvmrc'` |
| `nvm.update.build.number` | Not needed (use `GITHUB_SHA` for versioning) |
| `decrypt.secrets` | Not needed for unsigned builds |
| `android.sdk` | Manual sdkmanager install step |
| `install.node` | `npm ci` in `prototype/` |
| `build.android.react.bundle` | `react-native bundle` step |
| `_build.apk.debug` / `_build.apk.release` | `./gradlew assembleDebug` / `./gradlew assembleRelease` |
| `_build.android.bundle.debug` / `_build.android.bundle.release` | `./gradlew bundleDebug` / `./gradlew bundleRelease` |
| `deploy.apk.debug` / `deploy.apk.release` | `cp` to `dist/` with hash naming |
| `deploy.android.bundle.debug` / `deploy.android.bundle.release` | `cp` to `dist/` with hash naming |
| `package.android` | md5sum + tar.gz creation |
| `upload.android` | `actions/upload-artifact@v4` + `softprops/action-gh-release@v1` |

---

## Files to Create

```
.github/
  workflows/
    ci-android.yml        # Phase 1: Android build workflow
plans/
  CICD.md                 # This document
```
