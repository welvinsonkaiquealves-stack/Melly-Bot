# MELLY: AMBIENTE DE BUILD

Todas as versões abaixo foram lidas do repositório no commit `54aeae8`, em `.github/workflows/ci.yml`, `ui/pubspec.yaml`, `gradle/libs.versions.toml` e `gradle/wrapper/gradle-wrapper.properties`. São as versões que o CI usa, e portanto as que garantem que o build local reproduz o do GitHub Actions.

---

## 1. Versões exatas

| Componente | Versão |
|---|---|
| JDK | **21**, distribuição Temurin |
| Flutter | **3.47.2**, canal stable |
| Dart SDK | `^3.13.0`, vem com o Flutter |
| Gradle | **9.5.0**, via wrapper |
| Android Gradle Plugin | 9.3.2 |
| Kotlin | 2.4.10 |
| Android platform (compileSdk) | **37.0** |
| minSdk | 29 |
| targetSdk | 34 |
| NDK | **28.2.13676358** |
| Node.js | 22 |
| pnpm | 10.28.0 |

Atenção: o `AGENTS.md` do repositório diz "Flutter 3.9.2+" e "JDK 11+". Está desatualizado. O `ui/pubspec.yaml` exige Flutter `>=3.47.2` e o CI usa JDK 21. Vale o CI.

## 2. Instalação no Windows

O dono do projeto usa um notebook Windows. Sequência mínima:

1. **JDK 21 Temurin.** Instale e confirme com `java -version`.
2. **Flutter 3.47.2.** Baixe o SDK na versão exata, adicione ao PATH, confirme com `flutter --version`.
3. **Android Studio** ou apenas o command line tools, e por ele instale:
   - platform `android-37`
   - NDK `28.2.13676358`
   - Android SDK Platform-Tools, que traz o `adb`
4. **Node 22 e pnpm 10.28.0**, necessários apenas para o módulo `webchat` e para os workers. Não são necessários para compilar o APK.
5. Aceite as licenças: `sdkmanager --licenses`.
6. Confirme tudo com `flutter doctor`.

Variáveis de ambiente úteis:

```text
ANDROID_NDK_HOME = %LOCALAPPDATA%\Android\Sdk\ndk\28.2.13676358
ANDROID_NDK_ROOT = o mesmo caminho
```

## 3. Comandos, exatamente os do CI

### Dependências e verificação Dart

```bash
cd ui
flutter pub get --enforce-lockfile
flutter test
flutter analyze --no-fatal-warnings --no-fatal-infos
```

O `--enforce-lockfile` importa: o `ui/pubspec.lock` está versionado e o CI exige que ele seja respeitado.

### Testes, lint e APK de debug

```bash
./gradlew --no-daemon --parallel --build-cache --max-workers=2 ^
  -Dorg.gradle.jvmargs="-Xmx4g -Dfile.encoding=UTF-8 --enable-native-access=ALL-UNNAMED" ^
  :app:testDevelopStandardDebugUnitTest ^
  :app:lintDevelopStandardDebug ^
  :app:assembleDevelopStandardDebug ^
  -Ptarget=lib/main_standard.dart
```

No Windows use `gradlew.bat` e `^` para continuar linha, ou rode tudo em uma linha só.

### Instalar no aparelho

```bash
./gradlew installDevelopStandardDebug -Ptarget=lib/main_standard.dart
```

### Erro conhecido do módulo Flutter

Se aparecer `Could not read script '.../ui/.android/include_flutter.groovy'`:

```bash
cd ui
flutter clean
flutter pub get
```

## 4. Sabores de build

| Sabor | Uso |
|---|---|
| `developStandardDebug` | desenvolvimento. É o que o CI compila e o que você usa |
| `productionStandardRelease` | release assinado. Exige as propriedades de keystore |

Propriedades de assinatura, apenas para release, em `gradle.properties` local ou em `~/.gradle/gradle.properties`:

```properties
OMNI_RELEASE_STORE_FILE=caminho/absoluto/release.jks
OMNI_RELEASE_STORE_PWD=***
OMNI_RELEASE_KEY_ALIAS=***
OMNI_RELEASE_KEY_PWD=***
```

`OMNIBOT_BASE_URL` fica vazio. A Melly não usa backend.

**Nunca comite keystore, senha ou chave de API.** O CI roda gitleaks e vai barrar.

## 5. Os workflows que já existem

| Arquivo | O que faz |
|---|---|
| `.github/workflows/ci.yml` | gitleaks, validação do wrapper, `flutter test`, `flutter analyze`, testes unitários Gradle, lint e APK de debug. Roda em pull request para `main` |
| `.github/workflows/release.yml` | build de release |
| `.github/workflows/codex-bot.yml` | bot de automação do upstream. Para um fork pessoal, provavelmente deve ser desligado |
| `.github/workflows/sync-models-dev.yml` | sincroniza catálogo de modelos |
| `.github/workflows/sync-to-cnb.yml` | espelho para outro host |

Para a Melly, o `ci.yml` é o que importa. Ele dispara em pull request para `main`, então para ver o CI rodar é preciso abrir PR, ou acrescentar `push` aos gatilhos.

## 6. Capturar métricas com o aparelho conectado

Isto vale ouro agora que existe um notebook. Ver `medicao/logcat.md` para os comandos completos. Resumo:

```bash
adb logcat -c
adb logcat | findstr /C:"TokenUsage" /C:"request_tools" /C:"registered_tools"
```

As linhas de INFO trazem todas as métricas de token e a contagem de ferramentas do turno, e **não aparecem na interface do app**, porque só ERROR e ASSERT são gravados no armazenamento de log que o app lê.

## 7. Sobre a pasta `base/openomnibot` deste pacote

Ela serve para leitura. Foram removidos 195 arquivos binários, incluindo `gradle/wrapper/gradle-wrapper.jar`, imagens, fontes, `.so`, `.jar` e `.aar`. Sem o wrapper jar, `./gradlew` não roda.

Para ter árvore que compila:

```bash
git clone https://github.com/omnimind-ai/OpenOmniBot.git melly
cd melly
```

Se já existe um fork próprio, ele é a árvore de trabalho e este pacote é referência.

## 8. Checklist antes de abrir PR em qualquer etapa

```text
[ ] cd ui && flutter pub get --enforce-lockfile
[ ] cd ui && flutter test                      sem falha
[ ] cd ui && flutter analyze                   sem aviso novo
[ ] ./gradlew :app:testDevelopStandardDebugUnitTest    verde
[ ] ./gradlew :app:assembleDevelopStandardDebug        compila
[ ] teste de aceitação da etapa, conforme o plano      passou
[ ] docs/05-ESTADO-ATUAL.md atualizado
[ ] nenhuma chave, senha ou keystore no diff
```
