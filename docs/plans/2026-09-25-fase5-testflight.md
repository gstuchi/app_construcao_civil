# Fase 5 — TestFlight Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Um workflow do GitHub que monta, assina e envia o app iOS do Custta ao TestFlight, e um projeto nativo pronto para push em produção.

**Architecture:** Assinatura manual só na Release do target App (certificado Apple Distribution + perfil App Store `Custta App Store`, criados uma vez pela API do App Store Connect e guardados em secrets). O workflow `ios-testflight.yml` reaproveita o caminho já verde do `ios-build.yml` (npm ci → cap sync → xcodebuild), acrescenta keychain temporária, `archive` e `-exportArchive` com `destination = upload`.

**Tech Stack:** Capacitor 8 (SPM), Xcode no runner `macos-latest`, GitHub Actions, API do App Store Connect (JWT ES256), `node --test`.

**Spec:** `docs/specs/2026-09-25-fase5-testflight-design.md`

## Global Constraints

- Bundle ID `br.com.custta.app`; Team ID `4S7JKDKN27`; perfil `Custta App Store`; identidade `Apple Distribution`.
- Nenhum segredo em arquivo versionado. O repositório é público. `.p8`, `.p12`, `.mobileprovision` e `.key` já estão no `.gitignore`.
- Toda action pinada por SHA de 40 caracteres e `permissions: contents: read` (regra de `tests/workflow.test.cjs` para todos os workflows).
- Capacitor 8 é SPM: nada de `pod install`; `npm ci` antes de qualquer `xcodebuild`.
- Commits com autor único Giovani Stuchi, sem Co-Authored-By; título `tipo: descrição` com acento; corpo em prosa.
- Implementadores de subagente **não commitam** — o controlador commita depois da revisão (tarefas paralelas no mesmo working tree).

## Review Focus

1. Release agora é assinatura manual: o `ios-build.yml` (sem assinatura) precisa continuar compilando — conferido pelo CI do PR.
2. Secret ausente ou vazio: o workflow tem que parar no primeiro passo dizendo qual falta, não 10 minutos depois num erro de assinatura.
3. Re-run de uma execução: `run_number` repete e a Apple recusa número de build repetido — o build number inclui `run_attempt`.
4. `aps-environment` divergente do perfil: Debug `development`, Release `production`, testado nos dois.
5. Falha no meio do job: keychain, `.p8` e perfil precisam sumir do runner mesmo assim (`if: always()`).

---

### Task 1: Bundle ID definitivo — FEITO (commit `feat: bundle ID definitivo br.com.custta.app`)

### Task 2: Projeto nativo pronto para push e assinatura de distribuição

**Files:**
- Create: `ios/App/App/GoogleService-Info.plist` (já copiado de `~/Documents/custta-chaves/`)
- Create: `ios/App/App/App.entitlements`
- Modify: `ios/App/App.xcodeproj/project.pbxproj`
- Modify: `ios/App/App/AppDelegate.swift`
- Modify: `ios/App/App/Info.plist`
- Test: `tests/capacitor.test.cjs`

**Interfaces:**
- Produces: build setting `APS_ENVIRONMENT`; Release do target App com `CODE_SIGN_STYLE = Manual`, `PROVISIONING_PROFILE_SPECIFIER = "Custta App Store"`, `"CODE_SIGN_IDENTITY[sdk=iphoneos*]" = "Apple Distribution"`. A Task 3 depende desses nomes exatos.

- [ ] **Step 1: Testes que falham** — acrescentar ao fim de `tests/capacitor.test.cjs`:

```js
/* Bloco XCBuildConfiguration do target App (o que tem INFOPLIST_FILE) com o nome dado. */
function configAlvo(pbx, nome){
  const blocos = [...pbx.matchAll(/isa = XCBuildConfiguration;[\s\S]*?name = (\w+);/g)]
    .filter(m => m[1] === nome && m[0].includes('INFOPLIST_FILE'));
  assert.equal(blocos.length, 1, `config ${nome} do target App não encontrada`);
  return blocos[0][0];
}

test('Firebase iOS: plist do bundle certo e empacotado no app', ()=>{
  const plist = ler('ios/App/App/GoogleService-Info.plist');
  assert.match(plist, /<key>BUNDLE_ID<\/key>\s*<string>br\.com\.custta\.app<\/string>/);
  assert.match(plist, /<key>PROJECT_ID<\/key>\s*<string>app-construcao-civil<\/string>/);
  const pbx = ler('ios/App/App.xcodeproj/project.pbxproj');
  const recursos = pbx.match(/isa = PBXResourcesBuildPhase;[\s\S]*?files = \(([\s\S]*?)\);/)[1];
  assert.match(recursos, /GoogleService-Info\.plist in Resources/, 'sem o plist no bundle o FCM não inicializa');
});

test('push: aps-environment vem da configuração e bate com o perfil', ()=>{
  const ent = ler('ios/App/App/App.entitlements');
  assert.match(ent, /<key>aps-environment<\/key>\s*<string>\$\(APS_ENVIRONMENT\)<\/string>/);
  const pbx = ler('ios/App/App.xcodeproj/project.pbxproj');
  const debug = configAlvo(pbx, 'Debug'), release = configAlvo(pbx, 'Release');
  for(const c of [debug, release]){
    assert.match(c, /CODE_SIGN_ENTITLEMENTS = App\/App\.entitlements;/);
    assert.match(c, /DEVELOPMENT_TEAM = 4S7JKDKN27;/);
  }
  assert.match(debug, /APS_ENVIRONMENT = development;/);
  assert.match(debug, /CODE_SIGN_STYLE = Automatic;/);
  assert.match(release, /APS_ENVIRONMENT = production;/);
});

test('Release assina com o perfil App Store, sem depender de aparelho cadastrado', ()=>{
  const release = configAlvo(ler('ios/App/App.xcodeproj/project.pbxproj'), 'Release');
  assert.match(release, /CODE_SIGN_STYLE = Manual;/);
  assert.match(release, /PROVISIONING_PROFILE_SPECIFIER = "Custta App Store";/);
  assert.match(release, /"CODE_SIGN_IDENTITY\[sdk=iphoneos\*\]" = "Apple Distribution";/);
});

test('AppDelegate repassa token e notificação ao plugin do Firebase', ()=>{
  const app = ler('ios/App/App/AppDelegate.swift');
  assert.match(app, /capacitorDidRegisterForRemoteNotifications/);
  assert.match(app, /didReceiveRemoteNotification userInfo/);
  assert.match(app, /Notification\.Name\("didReceiveRemoteNotification"\)/);
});

test('Info.plist exige arm64, não armv7', ()=>{
  const plist = ler('ios/App/App/Info.plist');
  const caps = plist.match(/<key>UIRequiredDeviceCapabilities<\/key>\s*<array>([\s\S]*?)<\/array>/)[1];
  assert.deepEqual([...caps.matchAll(/<string>([^<]+)<\/string>/g)].map(m=>m[1]), ['arm64']);
});
```

- [ ] **Step 2: Rodar e ver falhar** — `node --test tests/capacitor.test.cjs` → FAIL nos 5 testes novos (entitlements inexistente, plist fora do Resources, etc.).

- [ ] **Step 3: `ios/App/App/App.entitlements`**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>aps-environment</key>
	<string>$(APS_ENVIRONMENT)</string>
</dict>
</plist>
```

- [ ] **Step 4: `project.pbxproj`** (tabs, como o resto do arquivo):
  - PBXBuildFile: `A1C5F0012E90000000C0FFEE /* GoogleService-Info.plist in Resources */ = {isa = PBXBuildFile; fileRef = A1C5F0022E90000000C0FFEE /* GoogleService-Info.plist */; };`
  - PBXFileReference: `A1C5F0022E90000000C0FFEE /* GoogleService-Info.plist */ = {isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = "GoogleService-Info.plist"; sourceTree = "<group>"; };` e `A1C5F0032E90000000C0FFEE /* App.entitlements */ = {isa = PBXFileReference; lastKnownFileType = text.plist.entitlements; path = App.entitlements; sourceTree = "<group>"; };`
  - Grupo `504EC3061FED79650016851F /* App */`: acrescentar os dois arquivos em `children`.
  - `504EC3021FED79650016851F /* Resources */`: acrescentar `A1C5F0012E90000000C0FFEE /* GoogleService-Info.plist in Resources */,`.
  - Debug do target (`504EC3171FED79650016851F`): `APS_ENVIRONMENT = development;`, `CODE_SIGN_ENTITLEMENTS = App/App.entitlements;`, `DEVELOPMENT_TEAM = 4S7JKDKN27;`.
  - Release do target (`504EC3181FED79650016851F`): `APS_ENVIRONMENT = production;`, `CODE_SIGN_ENTITLEMENTS = App/App.entitlements;`, `CODE_SIGN_IDENTITY = "Apple Distribution";`, `"CODE_SIGN_IDENTITY[sdk=iphoneos*]" = "Apple Distribution";`, `CODE_SIGN_STYLE = Manual;` (no lugar de Automatic), `DEVELOPMENT_TEAM = 4S7JKDKN27;`, `PROVISIONING_PROFILE_SPECIFIER = "Custta App Store";`.
  - Manter as chaves de cada bloco em ordem alfabética, como o Xcode grava.

- [ ] **Step 5: `AppDelegate.swift`** — logo depois de `didFailToRegisterForRemoteNotificationsWithError`:

```swift
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        NotificationCenter.default.post(name: Notification.Name("didReceiveRemoteNotification"), object: completionHandler, userInfo: userInfo)
    }
```

- [ ] **Step 6: `Info.plist`** — em `UIRequiredDeviceCapabilities`, `<string>armv7</string>` → `<string>arm64</string>`.

- [ ] **Step 7: Rodar** — `node --test tests/capacitor.test.cjs` → PASS; `npm run test:unit` → tudo verde; `plutil -lint ios/App/App/App.entitlements ios/App/App/Info.plist ios/App/App/GoogleService-Info.plist` → OK.

- [ ] **Step 8: Commit** (controlador) — `feat: Firebase e push prontos no app iOS, Release assinada para a App Store`.

### Task 3: Workflow `ios-testflight.yml` e `ExportOptions.plist`

**Files:**
- Create: `.github/workflows/ios-testflight.yml`
- Create: `ios/App/ExportOptions.plist`
- Test: `tests/workflow.test.cjs`

**Interfaces:**
- Consumes: Release manual com perfil `Custta App Store` e identidade `Apple Distribution` (Task 2); secrets `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8`, `APPLE_TEAM_ID` (existem) e `DIST_CERT_P12` (base64 do .p12), `DIST_CERT_SENHA`, `PERFIL_APP_STORE` (base64 do .mobileprovision) (Task 4).

- [ ] **Step 1: Testes que falham** — em `tests/workflow.test.cjs`, antes do `console.log` final:

```js
const tf = readFileSync(join(dir, 'ios-testflight.yml'), 'utf8');
const tfSemComentario = tf.split('\n').filter(l => !/^\s*#/.test(l)).join('\n');
assert.match(tf, /runs-on:\s*macos-latest/, 'o envio precisa do runner macOS');
assert.match(tf, /workflow_dispatch:/, 'o envio precisa do botão manual');
// Cada execução vira um build no TestFlight: nada de disparo em todo push.
assert.ok(!/^on:\n(?:.*\n)*?\s{2}push:/m.test(tf), 'o envio não pode disparar em push');
assert.match(tf, /cancel-in-progress:\s*false/, 'cancelar no meio pode matar um upload');
assert.ok(!/pod install/.test(tfSemComentario), 'projeto é SPM, não CocoaPods');
assert.ok(tf.indexOf('npm ci') < tf.indexOf('xcodebuild \\'), 'npm ci precisa rodar antes do xcodebuild');
// Re-run repete o run_number; a Apple recusa build repetido.
assert.match(tf, /CURRENT_PROJECT_VERSION="\$\{\{ github\.run_number \}\}\.\$\{\{ github\.run_attempt \}\}"/,
  'build number precisa crescer e não repetir em re-run');
assert.match(tf, /if:\s*always\(\)[\s\S]*delete-keychain/, 'keychain temporária precisa sumir mesmo com falha');
for(const s of ['ASC_KEY_ID', 'ASC_ISSUER_ID', 'ASC_KEY_P8', 'APPLE_TEAM_ID', 'DIST_CERT_P12', 'DIST_CERT_SENHA', 'PERFIL_APP_STORE'])
  assert.match(tf, new RegExp(`secrets\\.${s}\\b`), `workflow não lê o secret ${s}`);
assert.ok(!/-----BEGIN/.test(tf), 'chave literal no workflow — repositório é público');

const exportOpts = readFileSync(join(__dirname, '..', 'ios', 'App', 'ExportOptions.plist'), 'utf8');
assert.match(exportOpts, /<key>method<\/key>\s*<string>app-store-connect<\/string>/);
assert.match(exportOpts, /<key>destination<\/key>\s*<string>upload<\/string>/);
assert.match(exportOpts, /<key>signingStyle<\/key>\s*<string>manual<\/string>/);
assert.match(exportOpts, /<key>teamID<\/key>\s*<string>4S7JKDKN27<\/string>/);
assert.match(exportOpts, /<key>br\.com\.custta\.app<\/key>\s*<string>Custta App Store<\/string>/);
```

e trocar o texto do `console.log` final por `'ok - Actions com SHA imutável e permissão mínima; build iOS sem assinatura e sob demanda; envio ao TestFlight assinado e sob demanda'`.

- [ ] **Step 2: Rodar e ver falhar** — `node tests/workflow.test.cjs` → ENOENT em `ios-testflight.yml`.

- [ ] **Step 3: `ios/App/ExportOptions.plist`**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>destination</key>
	<string>upload</string>
	<key>manageAppVersionAndBuildNumber</key>
	<false/>
	<key>method</key>
	<string>app-store-connect</string>
	<key>provisioningProfiles</key>
	<dict>
		<key>br.com.custta.app</key>
		<string>Custta App Store</string>
	</dict>
	<key>signingCertificate</key>
	<string>Apple Distribution</string>
	<key>signingStyle</key>
	<string>manual</string>
	<key>teamID</key>
	<string>4S7JKDKN27</string>
	<key>uploadSymbols</key>
	<true/>
</dict>
</plist>
```

- [ ] **Step 4: `.github/workflows/ios-testflight.yml`** — mesmas actions e SHAs do `ios-build.yml` (`actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1`, `actions/setup-node@820762786026740c76f36085b0efc47a31fe5020 # v7.0.0`). Cabeçalho comentado em português explicando: por que assinatura manual (time sem aparelho), por que só botão + PR que mexe em assinatura, por que build number com `run_attempt`, como renovar o certificado (set/2027). Passos, nesta ordem:
  1. `on:` `workflow_dispatch:` e `pull_request:` com `paths:` `.github/workflows/ios-testflight.yml`, `ios/App/ExportOptions.plist`, `ios/App/App/App.entitlements`, `ios/App/App.xcodeproj/project.pbxproj`. `permissions: contents: read`. `concurrency: { group: ios-testflight, cancel-in-progress: false }`. Job `enviar`, `runs-on: macos-latest`, `timeout-minutes: 60`.
  2. checkout; setup-node 22 com cache npm; `xcodebuild -version`.
  3. **Os secrets de assinatura existem**: `env` com os 7 secrets; laço `for v in ...; do [ -z "${!v}" ] && echo "::error::secret $v ausente"; done` saindo 1 se faltar algum.
  4. `npm ci`; `npm run cap:sync`; `git diff --exit-code -- ios`.
  5. **Keychain temporária**: `KEYCHAIN="$RUNNER_TEMP/assinatura.keychain-db"`, senha `openssl rand -base64 32`, `security create-keychain`, `set-keychain-settings -lut 21600`, `unlock-keychain`, decodificar `DIST_CERT_P12` para `$RUNNER_TEMP/dist.p12`, `security import ... -P "$DIST_CERT_SENHA" -A -t cert -f pkcs12 -k "$KEYCHAIN"`, `security set-key-partition-list -S apple-tool:,apple: -k "$SENHA" "$KEYCHAIN"`, `security list-keychains -d user -s "$KEYCHAIN" $(security list-keychains -d user | tr -d '"')`, apagar o `.p12`, `security find-identity -v -p codesigning "$KEYCHAIN"` (log mostra a identidade, não a chave).
  6. **Perfil**: decodificar `PERFIL_APP_STORE`, ler o UUID com `security cms -D -i arquivo | plutil -extract UUID raw -o - -`, copiar para `~/Library/MobileDevice/Provisioning Profiles/$UUID.mobileprovision` **e** `~/Library/Developer/Xcode/UserData/Provisioning Profiles/$UUID.mobileprovision` (Xcode 16+ lê o segundo).
  7. **Chave da API**: `printf '%s\n' "$ASC_KEY_P8" > "$RUNNER_TEMP/asc/AuthKey_$ASC_KEY_ID.p8"`.
  8. **Arquivar**: `xcodebuild \` com `-project ios/App/App.xcodeproj -scheme App -configuration Release -destination 'generic/platform=iOS' -archivePath "$RUNNER_TEMP/Custta.xcarchive" -derivedDataPath ios/App/build -skipMacroValidation -skipPackagePluginValidation CURRENT_PROJECT_VERSION="${{ github.run_number }}.${{ github.run_attempt }}" archive`, com `set -o pipefail`.
  9. **Enviar**: `xcodebuild -exportArchive -archivePath ... -exportOptionsPlist ios/App/ExportOptions.plist -exportPath "$RUNNER_TEMP/export" -authenticationKeyPath ... -authenticationKeyID "$ASC_KEY_ID" -authenticationKeyIssuerID "$ASC_ISSUER_ID"`.
  10. **Resumo**: número do build em `$GITHUB_STEP_SUMMARY`.
  11. **Limpar** (`if: always()`): `security delete-keychain "$RUNNER_TEMP/assinatura.keychain-db" || true`; `rm -rf` da pasta `asc`, do `.p12` e dos perfis instalados.
  - Secrets só entram por `env:` do passo que usa; nunca `echo` de secret.

- [ ] **Step 5: Rodar** — `node tests/workflow.test.cjs` → `ok - ...`; `npm run test:unit` verde; `plutil -lint ios/App/ExportOptions.plist`; YAML válido (`node -e "require('js-yaml')"` não existe no repo — validar com `ruby -ryaml -e 'YAML.load_file(ARGV[0])' .github/workflows/ios-testflight.yml`).

- [ ] **Step 6: Commit** (controlador) — `ci: enviar o app iOS assinado ao TestFlight`.

### Task 4: Certificado, perfil e secrets de distribuição (controlador, local — usa as chaves)

- [ ] Gerar chave RSA 2048 + CSR em `~/Documents/custta-chaves/` (chmod 600).
- [ ] Script Node em `$CLAUDE_JOB_DIR/tmp` (fora do repo): JWT ES256 com a Team key; `GET /v1/certificates?filter[certificateType]=DISTRIBUTION` (conferir que não há outro); `GET /v1/bundleIds?filter[identifier]=br.com.custta.app`; `POST /v1/certificates` (`DISTRIBUTION`, CSR); `POST /v1/profiles` (`IOS_APP_STORE`, nome `Custta App Store`, bundle + certificado). Nunca imprimir a chave.
- [ ] `.cer` → `.p12` com `openssl pkcs12 -export -keypbe PBE-SHA1-3DES -certpbe PBE-SHA1-3DES -macalg sha1` e senha aleatória; conferir com `openssl pkcs12 -noout -passin`.
- [ ] Conferir que o perfil contém `aps-environment = production` e o Team ID.
- [ ] `gh secret set DIST_CERT_P12` (base64), `DIST_CERT_SENHA`, `PERFIL_APP_STORE` (base64), lendo de arquivo — nada pela conversa.

### Task 5: PR, CI e primeiro envio (controlador)

- [ ] Commitar spec + plano (`docs: spec e plano da Fase 5 (TestFlight)`).
- [ ] `npm run test:unit` inteiro verde; push da branch; abrir PR em prosa.
- [ ] Acompanhar `ios-build` e `ios-testflight` no PR; corrigir até os dois ficarem verdes, um commit por correção.
- [ ] Conferir pela API que o build chegou ao App Store Connect e terminou de processar (`GET /v1/builds?filter[app]=...`).

### Task 6: TestFlight interno (controlador, API)

- [ ] Criar grupo interno `Interno` (`isInternalGroup: true`, `hasAccessToAllBuilds: true`) e adicionar o Giovani (`giovanistuchi@hotmail.com`) como testador.

### Task 7: Web intacta

- [ ] Smoke do preview da Vercel do PR com `agent-browser`: abre, tela de login renderiza, sem erro de console relevante.

### Task 8: Registro

- [ ] Notion (subpágina da Fase 5 + página de estado) e memória atualizados; revisão final da branch inteira.
