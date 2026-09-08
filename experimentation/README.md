# iOS Experimentation Snippet Test App

Three-tab UIKit app that exercises the three iOS experimentation snippets
so you can validate them on a real Simulator.

**The LaunchDarkly SDK has been removed from this app.** It is now an install
fixture: the three snippet functions still exist and are still called from the
UI, but they route through the `FeatureFlags` protocol in
`Sources/FeatureFlags.swift`, whose default implementation returns each
caller's own fallback and drops every event. Installing the SDK means backing
that protocol with a real client.

The working integration is preserved in git — see the repo root README for how
to diff against it.

## Tabs

| Tab | Snippet | What it validates |
|-----|---------|-------------------|
| Track Only | `track-only.snippet.md` | client init + `trackMetric` |
| Full Exp | `full.snippet.md` | identify → flag eval → metric |
| Button Copy | `button-copy.snippet.md` | flag-driven button title + tap tracking |

## Setup

### 1. Set your keys

Edit `Sources/Config.swift`:

```swift
static let mobileKey  = "mob-xxxx"   // LaunchDarkly mobile key for your env
static let flagKey    = "my-flag"     // String flag — each variation is a button label
static let metricKey  = "my-metric"  // Conversion metric key for the experiment
```

### 2. Generate the Xcode project

```sh
brew install xcodegen   # one-time
xcodegen generate
```

### 3. Open and run

```sh
open ExperimentationDemo.xcodeproj
```

Select an iPhone Simulator target and press ▶. There are no external package
dependencies, so the build is fast.

To build from the command line:

```sh
xcodebuild -project ExperimentationDemo.xcodeproj -scheme ExperimentationDemo \
  -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' build
```

---

## Bugs / issues found in the snippets

These were found while the SDK was still wired up, against the LaunchDarkly
docs snippets. They are kept here because they are findings about the docs, not
about this app — the code examples below show the SDK calls as they were at the
time.

### Bug 1 — `button-copy`: `setTitle` silent no-op with `UIButton.Configuration` (iOS 15+)

**File**: `button-copy.snippet.md`  
**Code**: `button.setTitle(label, for: .normal)`

When a `UIButton` has a `UIButton.Configuration` set (the new programmatic styling
API introduced in iOS 15), `setTitle(_:for:)` is silently ignored. This affects any
developer who creates their button with the modern API:

```swift
// With UIButton.Configuration → setTitle is a no-op:
var cfg = UIButton.Configuration.filled()
cfg.title = "Old title"
myButton.configuration = cfg
configureExperimentButton(myButton)   // ← title won't change!
```

**Fix**: detect and handle both styles, or document the legacy-only requirement:

```swift
let label = client.stringVariation(forKey: "YOUR_FLAG_KEY", defaultValue: "Get started")
if button.configuration != nil {
    button.configuration?.title = label
} else {
    button.setTitle(label, for: .normal)
}
```

This demo works around the issue by using `UIButton(type: .custom)` with no
Configuration on the experiment button.

---

### Bug 2 — `full`: `try!` crash on invalid context key

**File**: `full.snippet.md`  
**Code**:
```swift
let updated = try! LDContextBuilder(key: finalUserKey)
    // any attributes that affect targeting or eligibility
    .build().get()
```

If `finalUserKey` is an empty string or otherwise invalid, `.build()` returns a
`.failure(...)` and `.get()` throws — causing a `try!` crash. The companion
`startLaunchDarkly()` function in the same snippet uses the safer pattern:

```swift
guard case .success(let context) = contextBuilder.build() else { return }
```

`onUserBecomesEligible` should do the same.

---

### Bug 3 — All snippets: `LDClient.get()!` crash before init

All three snippets use `LDClient.get()!` (force-unwrap). Calling the snippet
helpers before `startLaunchDarkly()` has run crashes the app. The snippets should
either document the call-order requirement more prominently or use:

```swift
guard let client = LDClient.get() else { return }
```

---

### Bug 4 — `full`: `applyVariant` is undefined (invisible dependency)

**File**: `full.snippet.md`  
**Code**: `applyVariant(variant)`

`applyVariant` is called but not defined or even declared in the snippet. Developers
who copy the snippet get a compile error with no explanation. The snippet should
either include a stub or explicitly say "implement `applyVariant` to apply the
variation to your UI."

---

### Gap: no CI row for `ios-client-sdk / experimentation` group

The snippets-validate CI matrix has three iOS rows:

```
ios-client-sdk (install)  — group: sdk-info, key-type: none
ios-client-sdk (init)     — snippet: sdk-info/init, key-type: mobile
ios-client-sdk (sdk-docs) — group: sdk-docs, key-type: mobile
```

None of them cover `group: experimentation`, so the three snippets this app
validates are not run in CI at all.

To add coverage, append to the matrix:

```yaml
- sdk: ios-client-sdk
  runs-on: macos-latest
  key-type: mobile
  label: ios-client-sdk (experimentation)
  group: experimentation
```

The snippets reference `ios-client-sdk/scaffolds/swift-syntax-only`, which the
existing native iOS harness already supports.
