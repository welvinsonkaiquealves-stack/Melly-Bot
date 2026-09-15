# Melly: execution handoff

**Updated:** 2026-09-15 UTC  
**Current stage:** E0-A complete — official GitHub base and CI baseline established

## Current state

The official persistent repository is
`https://github.com/welvinsonkaiquealves-stack/Melly-Bot`. It was imported with
the OpenOmniBot history and contains the Gradle wrapper and tracked binary
assets. No Melly functional code has been changed.

E0-A is complete on pull request #1: the source base and execution branch are
fixed, and the repository's GitHub Actions workflow completed the full
application baseline. The pull request remains open for maintainer review;
`main` has not been modified.

## Base

- Official repository: `welvinsonkaiquealves-stack/Melly-Bot`
- Imported source: `https://github.com/omnimind-ai/OpenOmniBot.git`
- Audited and initial commit: `54aeae8046a4f3bcf0fccc1ca30713722a81d863`
- Initial upstream branch: `main`
- Working branch: `melly/main`
- Upstream `HEAD` and `main` both resolved to the audited commit before clone.
- Initial working tree: clean.
- GitHub `main` was verified at the audited commit before this bootstrap branch.
- The persistent execution branch is `melly/main` and must be used through pull
  requests; do not push Melly changes directly to `main`.
- Bootstrap pull request: `https://github.com/welvinsonkaiquealves-stack/Melly-Bot/pull/1`.
- GitHub state: `main` unchanged; `melly/main` contains only the documented
  bootstrap/workflow changes and this handoff.

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

## Important files for the next stage

- `app/src/main/java/cn/com/omnimind/bot/agent/tool/AgentToolDefinitions.kt`
- `app/src/main/java/cn/com/omnimind/bot/agent/tool/handlers/PrivilegedToolHandler.kt`
- `app/src/main/java/cn/com/omnimind/bot/agent/runtime/AgentRuntimeContracts.kt`
- `app/src/main/java/cn/com/omnimind/bot/agent/XiaowanAcpConnection.kt`
- `baselib/src/main/java/cn/com/omnimind/baselib/shizuku/ShizukuCapabilityManager.kt`
- `baselib/src/main/java/cn/com/omnimind/baselib/shizuku/PrivilegedCommandExecutor.kt`
- `app/src/test/java/cn/com/omnimind/bot/agent/AgentToolDefinitionsPrivilegedTest.kt`
- `baselib/src/test/java/cn/com/omnimind/baselib/shizuku/PrivilegedActionPolicyTest.kt`

## Confirmed decisions

- A005: authoritative routing/execution policy is Kotlin; Flutter configures,
  presents and observes.
- Preserve the single ACP lifecycle; do not create a separate CHAT runtime.
- DeepSeek is the only initially active provider. Keep other provider code
  physically present but outside the primary Melly path.
- Plugins, MCP and external runtimes are not part of the initial default path.
- The first functional change is P0-A: remove model-controlled privileged
  approval.

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

## Work not completed

- Any functional Melly code change.
- P0-A implementation or tests.
- Device validation.
- Merge of bootstrap pull request #1 into `main` (maintainer decision).

## Next exact action

Review and merge bootstrap pull request #1 into `main`. After the user confirms
the next implementation unit, start P0-A from the merged base: remove every
model-controlled privileged approval bypass and prove the gate with focused
tests.

## Real blockers and risks

- Local Work still cannot execute the full Flutter/Android suite; GitHub Actions
  is the authoritative application baseline in this workflow.
- `ui/.android` is generated and remains absent until `flutter pub get` runs.
- P0-A must not trust `additionalProperties: false`: current registry validation
  does not recursively reject unknown nested fields. The handler must never
  consume `confirmed` from model arguments.
- Existing schema and policy tests do not prove that rejection or missing
  approval prevents a backend call; P0-A needs a focused handler/gate test.

## For the next agent

Do not repeat the architecture audit or baseline setup. Read this file, verify
the current branch/PR state, and begin only the user-approved next unit. P0-A is
next, but it must not be implemented before the bootstrap PR is merged and the
user authorizes that unit.
