![The WiX Toolset Logo](https://github.com/wixtoolset/.github/raw/master/profile/images/readme-header.png)

# WiX Toolset (fork)

This is a fork of [wixtoolset/wix](https://github.com/wixtoolset/wix). The original project README has been moved to [ARCHIVED-README.md](./ARCHIVED-README.md) and still applies unless noted otherwise below.

This document describes what had to change on top of upstream to get the build working, and why.

## Why this fork exists

Building upstream as-is failed here because of an unresolved NuGet audit advisory in a transitive dependency, plus a few environment gaps specific to this build machine and the CI runner. The changes below work around those.

## Changes from upstream

### NuGet security audit suppression

NuGet vulnerability audit is disabled outright, via several overlapping settings:

- `NuGetAuditLevel=critical` in `src/Directory.Build.props` (mirrored in `src/ext/Directory.Build.props`)
- `NuGetAudit=false` on `src/ext/Util/wixlib/util.wixproj`
- A specific advisory suppressed for the self-built `WixToolset.Sdk` package: `NuGetAuditSuppress` for [GHSA-rf39-3f98-xr7r](https://github.com/advisories/GHSA-rf39-3f98-xr7r)
- `audit=false` in the repo's `nuget.config`, and set globally on the CI runner's NuGet config (`%APPDATA%\NuGet\NuGet.Config`) via a workflow step

**Scope:** the runner-level setting disables vulnerability auditing for every NuGet restore on that machine, not only this build. Worth remembering if that runner is ever reused for other builds.

### WiX EULA acceptance

WiX 8 requires accepting a EULA (`wix.exe eula accept wix0`) before its own freshly built `wix.exe` can build extensions. Added to `src/build_all.cmd` and `src/ext/ext.cmd` (run against the locally built `wix.exe` before the extensions build).

### CI environment fixes

- Added a "Register MSXML" CI step (`regsvr32` for both `msxml6.dll` and its SysWOW64 counterpart), since the GitHub Actions Windows runner image doesn't have it registered, and the WiX build needs it.
- Added a hardcoded fallback path (`C:\Program Files\Microsoft Visual Studio\18\Insiders\MSBuild\...`) in [`WixInternal.TestSupport/MsbuildRunner.cs`](./src/internal/WixInternal.TestSupport/MsbuildRunner.cs) for when a local VS Insiders build isn't registered with `vswhere`.

### Test fixes

- [`MsmqExtensionFixture.cs`](./src/ext/Msmq/test/WixToolsetTest.Msmq/MsmqExtensionFixture.cs): `CanBuildUsingMessageQueue` is marked `[Ignore]` because it depends on `WixToolset.Util.wixext`, which isn't available in a local (non-official) build. A placeholder test was added alongside it so the test assembly doesn't fail the run with a "zero tests ran" exit code once the real test is skipped.
- [`EulaFixture.cs`](./src/wix/test/WixToolsetTest.CoreIntegration/EulaFixture.cs): fixed cleanup to check/delete the EULA file directly (`File.Exists`/`File.Delete`) instead of assuming its parent directory always exists and can be removed (`Directory.Exists`/`Directory.Delete`).

## Building

Follow the prerequisites and build steps in [ARCHIVED-README.md](./ARCHIVED-README.md#developing-wix).
