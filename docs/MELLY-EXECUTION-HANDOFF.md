# Melly: execution handoff

**Updated:** 2026-09-15 UTC  
**Current stage:** E0-A — official GitHub base established; CI baseline pending

## Current state

The official persistent repository is
`https://github.com/welvinsonkaiquealves-stack/Melly-Bot`. It was imported with
the OpenOmniBot history and contains the Gradle wrapper and tracked binary
assets. No Melly functional code has been changed.

E0-A is in progress: the source base and execution branch are fixed. The local
Work baseline remains limited by missing toolchains, so the full application
baseline will run in the repository's existing GitHub Actions workflow.

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
No Android or Flutter baseline result may be claimed yet.

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
  for manual dispatch only; CI and release workflows remain unchanged.

## Work not completed

- GitHub Actions Flutter/Android baseline (pending bootstrap pull request).
- Any functional Melly code change.
- P0-A implementation or tests.
- Device validation.

## Next exact action

Open the bootstrap pull request from `melly/main` to `main`, monitor the `CI`
workflow, and record each runner result here. Only after that baseline is
recorded, start P0-A.

## Real blockers and risks

- This Work environment cannot execute the full Flutter/Android baseline; the
  authoritative baseline must come from GitHub Actions.
- `ui/.android` is generated and remains absent until `flutter pub get` runs.
- P0-A must not trust `additionalProperties: false`: current registry validation
  does not recursively reject unknown nested fields. The handler must never
  consume `confirmed` from model arguments.
- Existing schema and policy tests do not prove that rejection or missing
  approval prevents a backend call; P0-A needs a focused handler/gate test.

## For the next agent

Do not repeat the architecture audit. Read this file and inspect the bootstrap
PR/CI result. Record the baseline before P0-A. Never call an environment or
workflow-infrastructure failure a source-code failure.
