# LDButtonDemo

Single-screen UIKit app: a button whose label comes from a string flag, and
whose taps fire a conversion metric. Generated with
[XcodeGen](https://github.com/yonaskolb/XcodeGen) from `project.yml`.

**No SDK is installed.** All feature decisions go through the `FeatureFlags`
protocol in `Sources/FeatureFlags.swift`; the default implementation returns
each caller's own fallback and drops every event. The process-wide instance is
assigned in `startFeatureFlags()` in `Sources/AppDelegate.swift`.

```sh
brew install xcodegen        # one-time
xcodegen generate
xcodebuild -project LDButtonDemo.xcodeproj -scheme LDButtonDemo \
  -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' build
```

Fill in `Sources/Config.swift` before expecting real values.

Note that `project.yml` is the source of truth — a Swift Package dependency
belongs in its `packages:` block and the target's `dependencies:` list, and
`.xcodeproj` is regenerated from it.
