# Fase 5 — build assinado e envio ao TestFlight

Data: 2026-09-25. Continuação da Fase 4 (Capacitor) e do `ios-build.yml` (PR #10), que já compila o app sem assinatura.

## Objetivo

Um botão na aba Actions (e, sozinho, todo PR que mexe em assinatura) que monta o app iOS, assina com a conta Apple do Giovani e envia o build ao TestFlight — sem Mac com Xcode, sem passo manual. Pronto quando: um build aparece no TestFlight, instala no iPhone pelo app TestFlight e recebe o resumo diário por push.

## O que já existe fora do repositório (feito em 25/09)

- App ID `br.com.custta.app` com Push Notifications; Team ID `4S7JKDKN27`.
- Chave APNs `CN53C2TH4N` (Sandbox & Production) enviada ao Firebase nos dois ambientes.
- App iOS registrado no Firebase; `GoogleService-Info.plist` baixado.
- App "Custta" criado no App Store Connect (pt-BR, SKU `custta-ios`).
- Team API key `9FKXA7MU3H` com papel Admin; secrets `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8`, `APPLE_TEAM_ID` no GitHub.

## Decisões

**Assinatura manual com certificado e perfil criados uma vez pela API, não assinatura automática na nuvem.** A automática (`-allowProvisioningUpdates` com a API key) assina o `archive` com um perfil de *desenvolvimento*, e a Apple não gera perfil de desenvolvimento para time sem aparelho cadastrado ("Your team has no devices"). A conta é nova e não tem aparelho. O caminho manual evita isso: um certificado Apple Distribution e um perfil App Store (`Custta App Store`, que não exige aparelho) são criados uma única vez pela API do App Store Connect, a partir de uma chave privada gerada nesta máquina. O `.p12` e o perfil vão para secrets do GitHub (`DIST_CERT_P12`, `DIST_CERT_SENHA`, `PERFIL_APP_STORE`); cópia em `~/Documents/custta-chaves/`. Gerar certificado a cada build esgotaria o limite da Apple (poucos certificados de distribuição por time). O certificado e o perfil valem um ano — renovar em set/2027.

**Assinatura manual só na configuração Release do target App, no `project.pbxproj`.** Passar `PROVISIONING_PROFILE_SPECIFIER` pela linha de comando valeria para todos os targets, inclusive os bundles de recurso dos pacotes Swift do Firebase, e o `xcodebuild` recusa perfil em target que não aceita perfil. Debug continua automático. O `ios-build.yml` sem assinatura segue funcionando porque `CODE_SIGNING_ALLOWED=NO` desliga a checagem de perfil.

**`aps-environment` vem de variável.** `App.entitlements` diz `$(APS_ENVIRONMENT)`; Debug = `development`, Release = `production`. Com valor fixo, o perfil App Store (produção) recusaria um entitlements dizendo `development`, e vice-versa.

**`GoogleService-Info.plist` versionado.** Não é segredo: a `API_KEY` dele é do mesmo tipo da que já está em `cloud.js` e sai dentro de todo `.ipa` publicado. O plugin `@capacitor-firebase/messaging` chama `FirebaseApp.configure()` sozinho quando encontra o arquivo no bundle. Endurecimento opcional (fora do escopo): restringir essa chave a apps iOS com o bundle `br.com.custta.app` no Google Cloud.

**Número do build = `github.run_number` do workflow de envio.** A Apple exige número crescente por versão; o `run_number` só cresce. Versão de marketing continua `1.0` no projeto.

**Envio por `xcodebuild -exportArchive` com `destination = upload`**, autenticado pela API key. É o caminho atual da Apple; `altool` fica de reserva se o upload direto falhar.

**Disparo.** `workflow_dispatch` (botão) e `pull_request` só quando o PR mexe no próprio workflow, no `ExportOptions.plist`, no `App.entitlements` ou no `project.pbxproj` — mudança de assinatura precisa provar o envio antes do merge. Não roda em todo push nem em todo PR: cada execução gera um build no TestFlight. `concurrency` sem cancelar execução em andamento, para não matar um upload no meio.

**Keychain temporária** criada no runner, com senha aleatória, apagada no fim (`if: always()`), junto com o `.p8` e o perfil escritos em `$RUNNER_TEMP`.

**Grupo interno do TestFlight** criado pela API depois do primeiro upload, com acesso a todos os builds e o Giovani como testador, para o build chegar no app TestFlight sem clique no painel.

## Mudanças no app nativo

- `capacitor.config.json` e `project.pbxproj`: bundle `br.com.custta.app` (feito no primeiro commit).
- `ios/App/App/GoogleService-Info.plist` no grupo e na fase Resources do target.
- `ios/App/App/App.entitlements` com `aps-environment = $(APS_ENVIRONMENT)`; `CODE_SIGN_ENTITLEMENTS` e `DEVELOPMENT_TEAM` nas duas configurações.
- `AppDelegate.swift`: repassar `didReceiveRemoteNotification` ao plugin, como a documentação do `@capacitor-firebase/messaging` pede.
- `Info.plist`: `UIRequiredDeviceCapabilities` passa de `armv7` para `arm64`. O binário é só arm64 (iOS 15+); declarar armv7 é herança do template.

O lado web e o servidor não mudam: `push.js` já tem o caminho nativo (FCM → `push/{uid}.tokens`) e `notificacoes/enviar.js` já envia FCM com payload APNs.

## Testes

- `tests/capacitor.test.cjs`: bundle igual em Capacitor e Xcode; plist do Firebase com o bundle certo e no Resources; entitlements com a variável e os dois valores; `arm64`; Release manual com o perfil `Custta App Store`; AppDelegate repassando a notificação.
- `tests/workflow.test.cjs`: workflow de envio com SHA imutável e permissão mínima (regra geral já existente), sem disparo em push, com limpeza da keychain em `always()`, sem `pod install`, `npm ci` antes do `xcodebuild`, e sem nenhum segredo literal.
- CI: `ios-build.yml` (sem assinatura) continua verde no PR; `ios-testflight.yml` roda no PR e precisa terminar com o upload aceito.
- Web: suíte unitária inteira verde; smoke do preview da Vercel com agent-browser (a web não muda, mas o PR passa por ela).

## Fora do escopo

Login com Apple (e Google no nativo), metadados da página da loja, conta demo em produção, envio para revisão.
