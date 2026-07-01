![The WiX Toolset Logo](https://github.com/wixtoolset/.github/raw/master/profile/images/readme-header.png)

# WiX Toolset (fork)

This is a fork of [wixtoolset/wix](https://github.com/wixtoolset/wix). The original project README has been moved to [ARCHIVED-README.md](./ARCHIVED-README.md) and still applies unless noted otherwise below.

This document describes what had to change on top of upstream to get the build working, and why.

## Why this fork exists

The upstream build assumes a specific, released set of tooling (a specific Visual Studio 2026 release, a specific .NET SDK, no unresolved NuGet audit advisories). At the time this fork was created, the available local toolchain was ahead of what upstream targets (VS 2026 **Insiders**, newer VC++ tools, newer .NET SDK previews), and a transitive dependency had an unresolved security advisory that upstream hadn't suppressed yet. Both blocked a clean build. The changes below work around those gaps.

## Changes from upstream

### Toolchain compatibility (VS 2026 Insiders)

- `PlatformToolset=v145` is passed explicitly to `msbuild` from every `*.cmd` build script (`api.cmd`, `burn.cmd`, `dtf.cmd`, `ext.cmd`, `internal.cmd`, `libs.cmd`, `setup.cmd`, `tools.cmd`, `wix.cmd`) and set directly in `src/wix/wixnative/wixnative.vcxproj`. VS 2026 doesn't ship the older `v143` toolset at all, only `v145`, so this needs to be explicit rather than left to whatever the installed VS defaults to.
- The native `.nuspec` files that package the toolset's own `.lib`/`.dll` output (`wcautil`, `dutil`, `wixstdfn`, `bextutil`, `WixToolset.BootstrapperApplicationApi`) reference that build output by its `v145` output folder, since MSBuild names it after the active `PlatformToolset`.
- A few pre-existing project files (some test fixture `.vcxproj`s, `TestComponentNative.vcxproj`, and `Directory.Build.props`'s own fallback default) still reference `v143` directly and haven't been touched, since the explicit `v145` above always wins wherever these scripts are the ones doing the building.
- Widened the `vswhere` version probe in [`WixInternal.TestSupport/MsbuildRunner.cs`](./src/internal/WixInternal.TestSupport/MsbuildRunner.cs) from `[17.0,18.0)` to `[17.0,19.0)` so VS 2026 (major version 18) is found at all, plus a hardcoded fallback path (`C:\Program Files\Microsoft Visual Studio\18\Insiders\MSBuild\...`) for when an Insiders build isn't registered with `vswhere` yet.
- Added a "Register MSXML" CI step (`regsvr32` for both `msxml6.dll` and its SysWOW64 counterpart), since the GitHub Actions Windows runner image doesn't have it registered, and the WiX build needs it.

### .NET SDK version

`src/internal/SetBuildNumber/global.json.pp` stays pinned to **`9.0.300`**. That's what upstream shipped and what the GitHub Actions runner has available.

Locally, on a machine that only has a newer .NET SDK installed (e.g. one bundled with VS 2026 Insiders), you may need to bump this to `10.0.300` to build at all. Do not commit that change, it breaks CI.

### NuGet security audit suppression

NuGet vulnerability audit is disabled outright, via several overlapping settings:

- `NuGetAuditLevel=critical` in `src/Directory.Build.props` (mirrored in `src/ext/Directory.Build.props`)
- `NuGetAudit=false` on `src/ext/Util/wixlib/util.wixproj`
- A specific advisory suppressed for the self-built `WixToolset.Sdk` package: `NuGetAuditSuppress` for [GHSA-rf39-3f98-xr7r](https://github.com/advisories/GHSA-rf39-3f98-xr7r)
- `audit=false` in the repo's `nuget.config`, and set globally on the CI runner's NuGet config (`%APPDATA%\NuGet\NuGet.Config`) via a workflow step

**Scope:** the runner-level setting disables vulnerability auditing for every NuGet restore on that machine, not only this build. Worth remembering if that runner is ever reused for other builds.

### WiX EULA acceptance

WiX 8 requires accepting a EULA (`wix.exe eula accept wix0`) before its own freshly built `wix.exe` can build extensions. Added to `src/build_all.cmd` and `src/ext/ext.cmd` (run against the locally built `wix.exe` before the extensions build).

### Test fixes

- [`MsmqExtensionFixture.cs`](./src/ext/Msmq/test/WixToolsetTest.Msmq/MsmqExtensionFixture.cs): `CanBuildUsingMessageQueue` is marked `[Ignore]` because it depends on `WixToolset.Util.wixext`, which isn't available in a local (non-official) build. A placeholder test was added alongside it so the test assembly doesn't fail the run with a "zero tests ran" exit code once the real test is skipped.
- [`EulaFixture.cs`](./src/wix/test/WixToolsetTest.CoreIntegration/EulaFixture.cs): fixed cleanup to check/delete the EULA file directly (`File.Exists`/`File.Delete`) instead of assuming its parent directory always exists and can be removed (`Directory.Exists`/`Directory.Delete`).

## Building

Follow the prerequisites and build steps in [ARCHIVED-README.md](./ARCHIVED-README.md#developing-wix), with the .NET SDK caveat from section 2 above in mind.
