# Melly: execution handoff

**Updated:** 2026-09-17 UTC
**Current stage:** E0-A3 pull request #5 green; merge and device validation pending

## Current state

The official persistent repository is
`https://github.com/welvinsonkaiquealves-stack/Melly-Bot`. It was imported with
the OpenOmniBot history and contains the Gradle wrapper and tracked binary
assets. P0-A is the first functional Melly security change.

E0-A was merged through pull request #1. P0-A passed independent diff review and
was merged through pull request #2. CI artifacts and documentation were merged
through pull request #3. Device installation then exposed a pre-existing
identity collision: the inherited APK still used OpenOmniBot's application ID,
name and launcher art. E0-A2 gives the test build a minimal independent identity
without renaming Kotlin packages or beginning the E9 brand redesign.

## Base

- Official repository: `welvinsonkaiquealves-stack/Melly-Bot`
- Imported source: `https://github.com/omnimind-ai/OpenOmniBot.git`
- Audited and initial commit: `54aeae8046a4f3bcf0fccc1ca30713722a81d863`
- Initial upstream branch: `main`
- E0-A merge commit on `main`: `eef88dc81bbd6c79a42274a05d93160351071e09`
- P0-A merge commit on `main`: `442967a11a4607dc74079abe07dab3ab4e77a5cc`
- Infrastructure/docs merge commit on `main`: `0a81b43d42098f1c414ced0cb9803f5c5fa60b67`
- Current working branch: `e0a3/identity-portuguese`
- Upstream `HEAD` and `main` both resolved to the audited commit before clone.
- Initial working tree: clean.
- GitHub `main` was verified at the audited commit before this bootstrap branch.
- Bootstrap pull request #1 was merged with a merge commit.
- P0-A pull request #2 was merged with a merge commit.
- Infrastructure/documentation pull request #3 was merged with a merge commit.
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

### Infrastructure/documentation verification

Pull request #3 added a CI step that summarizes JUnit XML, Android lint XML and
APK size, followed by `actions/upload-artifact@v4` with a 14-day retention. Its
parser was executed locally against deterministic fixture XML and a 1 MiB
fixture APK. GitHub Actions run `34943803116` passed and published the installable
debug artifact.

- Flutter tests: 1,257 passed.
- Kotlin/JVM tests: 1,098 passed; 0 failed, 0 errors, 0 skipped.
- Worker tests: 24 passed; 0 failed.
- Android lint: 325 inherited findings; 0 error/fatal findings.
- Debug APK: one file, 198.17 MiB before artifact compression.
- Combined Gradle command: `BUILD SUCCESSFUL in 13m 27s`.

### E0-A2 minimum identity verification

Workflow: `Pull Request CI`, pull request #4, run #10 (`35000011486`),
functional head `ef038f133b5980d045faec7d6e9f36bad4b54924`.

- Full workflow: passed.
- Secret scan and Gradle wrapper validation: passed.
- Worker/models.dev suite: 24 tests passed; 0 failed.
- Flutter tests: 1,257 passed.
- Flutter analyze: command passed with the configured non-fatal policy; 591
  inherited findings were reported.
- Kotlin/JVM tests: 1,098 passed; 0 failures, 0 errors, 0 skipped.
- Android lint: 315 findings; 0 errors/fatal.
- Debug APK: one file, 198.13 MiB before artifact compression.
- Combined Gradle command: `BUILD SUCCESSFUL in 14m 10s`.
- Artifact `melly-develop-standard-debug-e91bc722d4d2abc0569dbd0c8ca9af9603a5759c`
  was published with 14-day retention. The suffix is GitHub's temporary PR
  merge SHA; the artifact metadata ties it to functional head `ef038f13`.

CI proves that the new application ID and launcher resources compile and that
the automated baseline remains green. Only installation on the owner's Android
device can prove side-by-side coexistence with the reference OpenOmniBot app.

### E0-A3 identity and Portuguese verification

Workflow: `Pull Request CI`, pull request #5, successful run #15
(`35181823042`), functional head `080e03e63141619ffa44321ad8d36b26c80e7900`.

- Full workflow: passed in 20m 52s.
- Secret scan and Gradle wrapper validation: passed.
- Worker/models.dev suite: 24 tests passed; 0 failed.
- Flutter dependencies and localization generation: passed with both base `pt`
  and regional `pt_BR` catalogs.
- Flutter tests: 1,258 passed; 0 failed.
- Flutter analyze: passed with the configured non-fatal policy; 591 inherited
  findings were reported.
- Kotlin/JVM tests: 1,101 passed; 0 failures, 0 errors, 0 skipped.
- Android lint: 322 findings; 0 errors/fatal.
- Debug APK: one file, 198.22 MiB before artifact compression.
- Combined Gradle command: `BUILD SUCCESSFUL in 13m 41s`.
- Artifact `melly-develop-standard-debug-c9ed278ec081f5d1ad02e596fcb68b36476e4141`
  was published with 14-day retention. The artifact is tied to E0-A3 head
  `080e03e6`; its suffix is GitHub's temporary pull-request merge SHA.

The approved planning, audit, architecture, decisions and build documents are
under `docs/melly/`. The device measurement kit is under `medicao/`. The live
state remains this handoff; the obsolete pre-Git state file and incomplete code
snapshot were intentionally not imported.

### E1-A read-only lifecycle investigation

- `AgentOrchestrator.run` owns the operational `while (true)` and increments
  `completedModelRounds` before each model attempt. The name is misleading:
  the counter also includes the one allowed pre-output overflow recovery.
- Setting the existing `terminated = true` on budget exhaustion would return
  `AgentResult.Success`; Xiaowan would emit ACP `END_TURN`, and Flutter would
  present a completed turn. That is a false success and must not be used.
- The existing error path is correct for exhaustion: a non-cancellation error
  becomes `AgentResult.Error`, Xiaowan projects it through the official ACP
  prompt failure, and Flutter reduces it with `stopReason = error`, settling
  pending cards without creating a second lifecycle event.
- `CancellationException` already has a dedicated earlier catch and maps to ACP
  `CANCELLED`. E1-A must preserve that ordering and behavior.
- The minimal future patch should inject a small immutable loop policy, check
  the limit before starting the next LLM request, and test normal completion,
  infinite tool calls, overflow retry accounting and cancellation precedence.
  No E1-A code has been changed yet, and the provisional numeric limit remains
  decision A001 rather than an invented constant.

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
- Completed final P0-A CI run #6 on head `769fc45b` and merged pull request #2
  with merge commit `442967a1` after independent review.
- Verified `SharedHelper.parseConfirmedFlag` has no remaining callers. It is
  dead code, but removal is deferred to a code-only patch instead of being mixed
  into the infrastructure/documentation change.
- Curated the approved Melly documents into `docs/melly/` and the measurement
  kit into `medicao/`, with a mobile-only capture path documented.
- Added CI report summarization and debug APK artifact publication; local parser
  fixture verification passed.
- Completed pull request #3 CI and merged it as `0a81b43d`.
- Traced E1-A termination through `AgentOrchestrator`, Xiaowan ACP and Flutter's
  reducer, establishing error rather than success as the correct limit outcome.
- Confirmed the device installation conflict was caused by the inherited
  `cn.com.omnimind.bot` application ID, not an Android installer defect.
- Prepared E0-A2 with application ID `com.melly.assistant`, launcher labels
  `Melly` in default and English Android resources, and a clearly distinct
  provisional launcher icon. Kotlin namespace/package names remain unchanged.
- Audited inherited package literals: provider authorities already derive from
  `${applicationId}`. Internal Flutter/Kotlin channel IDs, test class names,
  scripts and custom intent actions retain the old prefix intentionally; they
  are protocol/namespace debt rather than installation identity. The seven
  exported debug actions can collide if an unscoped test broadcast is sent
  while both apps are installed, so device scripts must target the Melly package
  explicitly until E9 or a dedicated test-harness migration.
- Merged E0-A2 through pull request #4 as merge commit `b226a721`; its CI
  artifact installs with application ID `com.melly.assistant`.
- Implemented E0-A3 visible identity cleanup without renaming internal
  protocols, Kotlin packages, `Theme.OmnibotApp` resources or the legacy
  `Download/OmnibotApp/` compatibility path.
- Added Brazilian Portuguese to Flutter and Kotlin locale selectors. The 557
  inherited ARB messages have pt-BR translations, plus one new language-option
  label; Android has 37 matching `values-pt-rBR` strings. Placeholder and key
  parity were verified locally.
- Changed legacy bilingual Flutter and Kotlin paths to use English for pt-BR
  when a dedicated Portuguese string has not yet been migrated. Chinese is now
  selected only for a Chinese locale.
- Disabled the inherited OpenOmniBot update channel fail-closed: periodic work
  is cancelled, manual/silent checks return a no-update state, cached upstream
  release URLs are suppressed, and install requests are rejected. Cloud-policy
  fields remain preserved.
- Opened E0-A3 pull request #5 from `e0a3/identity-portuguese`. CI run
  `35180775263` reached `flutter pub get --enforce-lockfile` and failed before
  tests because Flutter requires a base `app_pt.arb` whenever `app_pt_BR.arb`
  exists. Added the base Portuguese ARB with the same complete 558-message
  catalog; this is a branch-attributable localization configuration correction,
  not a dependency or inherited baseline failure.
- CI run `35181116540` then rejected the copied base catalog because its
  `@@locale` still declared `pt_BR` while the filename declared `pt`. Corrected
  only the base catalog metadata to `pt`; the regional catalog continues to
  declare `pt_BR`.
- CI run `35181357636` passed dependency/localization generation and executed
  1,258 Flutter tests: 1,253 passed and five failed on stale expectations for
  visible `小万` labels changed by E0-A3. Updated only those UI assertions to
  the corresponding `Melly` labels; internal Omnibot fixtures remain intact.

## Work not completed

- Device validation of E0-A2/E0-A3.
- E0-A3 pull-request merge and device validation.
- Conversion of archival branch `upstream-54aeae8` into a Git tag.
- Deletion of obsolete branch `melly/main`.
- Branch protection for archival branch `upstream-54aeae8`.
- Removal of dead `SharedHelper.parseConfirmedFlag` in a code-only patch.
- E1-A lifecycle investigation and implementation.

## Next exact action

Merge green pull request #5, then install its debug artifact on the owner's
Android device and verify Melly identity, pt-BR selection/fallback and the
disabled update surface before beginning E0 measurements.

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
- GitHub retention for the debug APK is intentionally 14 days; measurement
  evidence must be committed separately, not left only in the artifact.
- The provisional `M` launcher art is intentionally not the final Melly brand;
  replace it during E9 rather than expanding E0-A2 into a UI redesign.
- The pt-BR ARB catalog is an initial machine-assisted translation with focused
  terminology corrections. It needs native-speaker copy review over time, but
  no missing key or placeholder is known.
- About/privacy links still target inherited OpenOmniBot documentation because
  Melly does not yet have replacement legal/documentation pages. Do not silently
  repoint them to a nonexistent endpoint.

## For the next agent

Do not repeat the architecture audit, baseline setup or P0-A implementation.
Read this file and inspect the E0-A3 pull request/CI. Never reuse `melly/main`,
the P0-A branch or prior infrastructure branches. Do not rename internal
Omnibot protocol identifiers during identity cleanup. After a green CI run,
validate pt-BR and side-by-side device installation before continuing E0.
