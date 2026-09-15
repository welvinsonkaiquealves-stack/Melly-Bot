# Melly: execution handoff

**Updated:** 2026-09-15 UTC  
**Current stage:** P0-A implemented and verified; pull request #2 awaiting review

## Current state

The official persistent repository is
`https://github.com/welvinsonkaiquealves-stack/Melly-Bot`. It was imported with
the OpenOmniBot history and contains the Gradle wrapper and tracked binary
assets. P0-A is the first functional Melly security change.

E0-A was merged through pull request #1. P0-A is implemented on
`p0a/privileged-approval`, and the full GitHub Actions workflow passed on pull
request #2. Pull request #2 remains open for independent review; `main` still
points to the E0-A merge.

## Base

- Official repository: `welvinsonkaiquealves-stack/Melly-Bot`
- Imported source: `https://github.com/omnimind-ai/OpenOmniBot.git`
- Audited and initial commit: `54aeae8046a4f3bcf0fccc1ca30713722a81d863`
- Initial upstream branch: `main`
- E0-A merge commit on `main`: `eef88dc81bbd6c79a42274a05d93160351071e09`
- Current working branch: `p0a/privileged-approval`
- Upstream `HEAD` and `main` both resolved to the audited commit before clone.
- Initial working tree: clean.
- GitHub `main` was verified at the audited commit before this bootstrap branch.
- Bootstrap pull request #1 was merged with a merge commit.
- P0-A pull request: `https://github.com/welvinsonkaiquealves-stack/Melly-Bot/pull/2`.
- `upstream-54aeae8` preserves the original commit as an archival branch. The
  GitHub connector could not create a tag; convert this reference to a tag when
  tag operations are available.
- The obsolete `melly/main` branch still exists because the connector could not
  delete it. It must not be reused.

## Environment

Required by the repository/CI:

- JDK 21 for CI.
- Gradle 9.5.0 through the wrapper.
- Android platform 37 and NDK 28.2.13676358.
- Flutter 3.47.2; Dart constraint `^3.13.0`.
- Kotlin 2.4.10 and Android Gradle Plugin 9.3.2.
- App JVM target 17; several supporting modules target JVM 11.

Available in this Work environment:

- OpenJDK 17.0.20.
- Node 24.19.0.
- pnpm 11.19.0.
- Flutter, Dart, Android SDK tools, ADB and sdkmanager: unavailable.
- Network access to `services.gradle.org`: unavailable.

## Baseline

### Commands executed

1. `git ls-remote https://github.com/omnimind-ai/OpenOmniBot.git HEAD refs/heads/main`
   - Passed. Both refs resolved to the audited full commit.
2. `git clone https://github.com/omnimind-ai/OpenOmniBot.git melly`
   - Passed.
3. `./gradlew --no-daemon --version`
   - Did not run Gradle. The wrapper JAR loaded, then download of Gradle 9.5.0
     failed with `java.net.SocketException: Network is unreachable`.
4. `cd workers/app-update-worker && npm test`
   - Passed under Node 24.19.0: 24 tests, 24 passed, 0 failed, approximately
     0.23 seconds reported by the Node test runner.
5. CI-equivalent Android command for unit tests, lint and debug APK:
   `./gradlew --no-daemon --parallel --build-cache --max-workers=2 ...`
   - Did not configure or compile the project. It stopped at the same blocked
     Gradle 9.5.0 download.

### Not executed

- `flutter pub get --enforce-lockfile`
- `flutter test`
- `flutter analyze --no-fatal-warnings --no-fatal-infos`
- `:app:testDevelopStandardDebugUnitTest`
- `:app:lintDevelopStandardDebug`
- `:app:assembleDevelopStandardDebug`
- Android instrumentation/device tests
- GitHub Actions wrapper validation

These are environment/toolchain blockers, not observed source-code failures.
No local Android or Flutter baseline result is claimed; use the GitHub Actions
baseline recorded below.

### GitHub Actions authoritative baseline

Workflow: `Pull Request CI`, pull request #1.

- Run #1 (`34930516998`) failed before application tests in inherited
  `android-actions/setup-android@v3`: its implicit `sdkmanager tools` command
  reported `Failed to find package 'tools'`. This was a CI infrastructure
  incompatibility, not a source-code failure.
- Run #2 (`34930675145`) confirmed that the hosted runner did not pre-export
  `ANDROID_SDK_ROOT`; it failed in the new SDK verification before application
  tests. This was a bootstrap workflow failure.
- Run #3 (`34930872510`) completed successfully after detecting the hosted
  runner SDK and exporting its root/path explicitly.

Verified by successful run #3:

- Secret scan (gitleaks): passed.
- Worker/models.dev suite: 24 tests passed.
- Gradle wrapper validation: passed.
- Flutter dependencies with enforced lockfile: passed.
- Flutter tests: 1,257 tests passed in approximately 3 minutes 10 seconds.
- Flutter analyze: command passed with the configured non-fatal flags; 591
  existing warnings/info items were reported. Do not describe this as zero
  analyzer findings.
- `:app:testDevelopStandardDebugUnitTest`: passed as part of the Gradle command.
- `:app:lintDevelopStandardDebug`: passed as part of the Gradle command.
- `:app:assembleDevelopStandardDebug`: passed; debug APK assembled.
- Combined Gradle command: `BUILD SUCCESSFUL in 13m 59s`.

The Gradle log did not expose a trustworthy total Kotlin test-case count, so no
such count is claimed.

### P0-A verification

Workflow: `Pull Request CI`, pull request #2, run #5 (`34935963563`).

- Full workflow: passed.
- Worker/models.dev suite: 24 tests passed.
- Flutter tests: 1,257 tests passed.
- Flutter analyze: passed with the configured non-fatal policy; inherited
  analyzer findings remain baseline debt.
- Kotlin unit-test task, Android lint and debug APK assembly: passed.
- Combined Gradle command: `BUILD SUCCESSFUL in 13m 46s`.
- Six new focused handler tests cover model-supplied `confirmed`, rejection,
  missing approval channel, session start, session execution, prohibited
  commands and the internally approved backend path.
- Existing schema tests now assert that `confirmed` is absent from action,
  session-start and session-exec model schemas.

The CI still does not print an aggregate Kotlin test count or retain the APK as
an artifact. Add report summarization and `actions/upload-artifact@v4` in a
separate infrastructure change; do not mix it into this security patch.

## Important files for the next stage

- `app/src/main/java/cn/com/omnimind/bot/agent/tool/AgentToolDefinitions.kt`
- `app/src/main/java/cn/com/omnimind/bot/agent/tool/handlers/PrivilegedToolHandler.kt`
- `app/src/main/java/cn/com/omnimind/bot/agent/runtime/AgentRuntimeContracts.kt`
- `app/src/main/java/cn/com/omnimind/bot/agent/XiaowanAcpConnection.kt`
- `baselib/src/main/java/cn/com/omnimind/baselib/shizuku/ShizukuCapabilityManager.kt`
- `baselib/src/main/java/cn/com/omnimind/baselib/shizuku/PrivilegedCommandExecutor.kt`
- `app/src/test/java/cn/com/omnimind/bot/agent/AgentToolDefinitionsPrivilegedTest.kt`
- `app/src/test/java/cn/com/omnimind/bot/agent/tool/handlers/PrivilegedToolHandlerApprovalTest.kt`
- `baselib/src/test/java/cn/com/omnimind/baselib/shizuku/PrivilegedActionPolicyTest.kt`

## Confirmed decisions

- A005: authoritative routing/execution policy is Kotlin; Flutter configures,
  presents and observes.
- Preserve the single ACP lifecycle; do not create a separate CHAT runtime.
- DeepSeek is the only initially active provider. Keep other provider code
  physically present but outside the primary Melly path.
- Plugins, MCP and external runtimes are not part of the initial default path.
- P0-A keeps `AgentPermissionRequester` and its `XiaowanAcpConnection`
  implementation as the authoritative approval boundary.

## Work completed

- Confirmed the authoritative upstream commit remotely.
- Created a complete Git clone and `melly/main` working branch.
- Confirmed the wrapper JAR and `ui/pubspec.lock` are tracked and present.
- Recorded the exact environment mismatch and attempted baseline commands.
- Ran the available worker test suite successfully.
- Located the P0-A schema, handler, permission and Shizuku backend boundaries.
- Confirmed that model-provided `confirmed` is consumed by the handler and that
  the backend API still accepts a plain Boolean.
- Verified the imported GitHub `main` at the exact audited commit and confirmed
  that essential wrapper, Flutter and CI files exist.
- Prepared inherited `sync-models-dev`, `sync-to-cnb` and `codex-bot` workflows
  for manual dispatch only; release remains unchanged.
- Repaired the inherited CI bootstrap by replacing the incompatible Android SDK
  setup action with explicit discovery/verification of the hosted runner SDK.
- Completed and recorded the full GitHub Actions baseline in run #3.
- Preserved the original upstream commit as `upstream-54aeae8` and merged E0-A
  through pull request #1 with merge commit `eef88dc8`.
- Removed `confirmed` from the model-facing privileged action schema and
  discarded unknown model approval fields during parsing.
- Made privileged action, session start and session execution always require a
  positive system/UI decision before the backend receives internal approval.
- Kept forbidden-command policy unconditional and fail-closed behavior when no
  approval channel exists.
- Located all direct Shizuku backend callers. The Agent catalog reaches them
  through `PrivilegedToolHandler`; other direct calls are internal manager
  diagnostics/helpers, not model approval sources.
- Added six focused gate tests and completed full CI run #5 successfully.

## Work not completed

- Device validation.
- Independent review and merge of P0-A pull request #2.
- Conversion of archival branch `upstream-54aeae8` into a Git tag.
- Deletion of obsolete branch `melly/main`.
- CI publication of APK artifacts and aggregate Kotlin/lint/APK-size metrics.
- Import of the approved architecture/decision/measurement documents into
  `docs/`; source documents remain outside Git pending curation.

## Next exact action

Review and merge pull request #2 with a merge commit. Do not start Agent Loop
limits until this security change is merged and its branch is retired.

## Real blockers and risks

- Local Work still cannot execute the full Flutter/Android suite; GitHub Actions
  is the authoritative application baseline in this workflow.
- `ui/.android` is generated and remains absent until `flutter pub get` runs.
- The CI Android SDK fallback searches
  `/usr/local/lib/android/sdk/cmdline-tools` when `sdkmanager` is not on PATH.
  If the hosted image layout changes, inspect this bootstrap step first.
- The lower Shizuku backend still accepts a plain Boolean confirmation. P0-A
  removes model control at the authoritative Agent handler. An opaque approval
  capability remains optional defense in depth if future direct callers cross
  the model boundary.

## For the next agent

Do not repeat the architecture audit, baseline setup or P0-A implementation.
Read this file and inspect pull request #2. After it is merged, use a new branch
for the next approved unit; never reuse `melly/main` or the P0-A branch.
