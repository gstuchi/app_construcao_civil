# Fase 4 — Empacotamento com Capacitor

Data: 2026-09-16 · Branch: `feat/fase4` · Origem: [planejamento](../../planejamento-app-store.md#fase-4--empacotamento-com-capacitor)

## Objetivo

Deixar o Custta pronto para virar binário iOS via Capacitor sem quebrar o PWA de produção: projeto `ios/` versionado, comportamento web preservado, pontos incompatíveis com WKWebView condicionados, push nativo (FCM) codificado ponta a ponta e adições nativas que respondem à Guideline 4.2.

## Restrições desta execução

- **Sem matrícula Apple Developer.** Bundle ID provisório `com.gstuchi.custta`, definido só em `capacitor.config.json`. Chave APNs, TestFlight e envio real ao iPhone ficam no checklist de aparelho.
- **Sem Xcode nesta máquina.** Validação iOS vai até `npx cap sync ios`. Build, simulador e aparelho ficam no checklist.
- **Web continua sem build e sem dependência de runtime** (PRODUCT.md, princípio 5). Pacotes Capacitor são devDependencies usadas só pelo projeto nativo.
- **GitHub Actions continua enviando push.** O caminho Vercel Cron fica pronto e inerte.
- Commits separados por feature, autor único Giovani Stuchi, um push por commit em `feat/fase4`.

## Decisão de arquitetura: adaptador `nativo.js`

No WKWebView o Capacitor injeta `window.Capacitor` com `isNativePlatform()` e `Plugins.<Nome>` para todo plugin nativo instalado. Um script clássico `nativo.js` (global `OBRA_NATIVO`, `module.exports` para teste) é o **único** lugar que toca `window.Capacitor`:

| Função | Nativo | Web |
| --- | --- | --- |
| `ehNativo()` | `Capacitor.isNativePlatform()` | `false` |
| `plugin(nome)` | `Capacitor.Plugins[nome]` ou `null` | `null` |
| `compartilharArquivo({nome, texto, tipo, titulo})` | `Filesystem.writeFile` (Cache) + `Share.share({files:[uri]})` | `null` (chamador segue caminho web) |
| `vibrar()` | `Haptics.impact({style:'LIGHT'})`, erro engolido e registrado | no-op |
| `barraStatus(claro)` | `StatusBar.setStyle({style: claro?'LIGHT':'DARK'})` | no-op |
| `esconderSplash()` | `SplashScreen.hide()` | no-op |
| `aoSegundoPlano(fn)` | `App.addListener('appStateChange', s=>!s.isActive&&fn())` | no-op |

Erros de plugin nunca propagam para a UI: são registrados em `OBRA_DIAG` e a função devolve resultado neutro. Rejeitadas: vendorizar os pacotes JS dos plugins com esbuild (mais arquivos, diff de vendor, sem ganho funcional) e bundler (viola o princípio 5).

Plugins (devDependencies, versão estável atual da linha 8): `@capacitor/core`, `@capacitor/cli`, `@capacitor/ios`, `@capacitor/app`, `@capacitor/share`, `@capacitor/filesystem`, `@capacitor/haptics`, `@capacitor/status-bar`, `@capacitor/splash-screen`, `@capacitor-firebase/messaging`.

## 4a — Esqueleto

- `capacitor.config.json`: `appId com.gstuchi.custta`, `appName Custta`, `webDir www`, `SplashScreen.launchAutoHide false`, `backgroundColor #04100C`.
- `scripts/build-www.mjs` (`npm run build:www`): limpa e recria `www/` copiando a lista explícita de arquivos servidos (a mesma de `ASSETS` do `sw.js`, lida do próprio `sw.js` para não duplicar), mais `nativo.js`/`push.js`/`versao.json`. No `www/index.html` injeta `<meta http-equiv="Content-Security-Policy">` derivada do header do `vercel.json`, sem as diretivas que meta não aceita (`frame-ancestors`, `upgrade-insecure-requests`) (o FCM roda no SDK nativo, fora da CSP). Falha com código ≠ 0 se algum arquivo listado não existir.
- `npm run cap:sync` = `build:www` + `npx cap sync ios`.
- `npx cap add ios`, `ios/` commitado. `Info.plist`: `ITSAppUsesNonExemptEncryption=false`, `UISupportedInterfaceOrientations` só retrato, `UIBackgroundModes` com `remote-notification`. `TARGETED_DEVICE_FAMILY = 1` no `project.pbxproj`.
- `.gitignore`: sai `ios/`, entra `www/`, `ios/App/Pods/`, `ios/App/App/public/`, `ios/DerivedData/`.
- Teste: `tests/build-www.test.mjs` roda o script num diretório temporário e verifica cópia, meta CSP sem `unsafe-inline` e erro em arquivo ausente. `tests/capacitor.test.cjs` verifica config e as chaves do `Info.plist`.

## 4b — Condicionais

- `index.html`: viewport vira `width=device-width, initial-scale=1, viewport-fit=cover` (pinch-zoom liberado em web e nativo).
- `pwa.js`: não registra SW quando `OBRA_NATIVO.ehNativo()`. `nativo.js` carrega antes de `pwa.js`.
- `beforeinstallprompt`: ignorado no nativo.
- Ajustes → Notificações no nativo: nota "Afazeres pendentes, parcelas do mês e lembrete de lançar gastos. Você pode desligar quando quiser." (sem menção a Safari/Tela de Início).
- `#relPrint` e `#grafPrint`: no nativo, rótulo "Compartilhar" e ação exporta o CSV via `OBRA_SHARE.exportar(db,'csv')`. Web inalterada.
- `confirm()`/`alert()` (app.js 395, 655, 740, 1469, 1470; auth.js 23) → `OBRA_CONFIRM.perguntar(msg, {confirmar, perigo})` e `OBRA_CONFIRM.avisar(msg)`, promessas sobre `<dialog>` nativo acrescentado em `ui-confirm.js`. Vale para web também (um caminho só). Esc/cancelar resolve `false`.
- `cloud.js`: `persistentSingleTabManager` quando nativo, `persistentMultipleTabManager` na web.
- Gambiarra `visualViewport`: mantida; entra no checklist de aparelho.

## 4c — Push

- **`push.js`** (global `OBRA_PUSH`, `module.exports` para teste) extrai de `app.js` todo o bloco de push. Interface: `suportado()`, `ativo(): Promise<bool>`, `ativar(): Promise<bool>`, `desativar()`, `permissaoPendente(): Promise<bool>`, `aoAbrirNotificacao(fn)`, e mantém `desativa()` usado por `auth.js`.
  - Web: implementação atual (VAPID, `subs`).
  - Nativo: `FirebaseMessaging.requestPermissions` → `getToken` → `CLOUD.savePushToken(hash(token), {token, plataforma:'ios', criado})`; desativar = `deleteToken` + `CLOUD.removePushToken`. `notificationActionPerformed` → `fn(data.obraId)`.
- `cloud.js`: `savePushToken`/`removePushToken` análogos a `savePushSub`, em `push/{uid}.tokens.<chave>`; exclusão de conta e logout desativam também o token. Rules já aceitam `tokens` como map ≤ 10; somar teste de rules para token válido e 11º token rejeitado.
- `app.js`: `OBRA_PUSH.aoAbrirNotificacao(id => id && obraById(id) ? openObra(id) : showView('inicio'))`, aplicado depois do primeiro snapshot.
- **`notificacoes/resumo.js`**: `montaResumo` inclui `obraId` quando exatamente uma obra contribui para as linhas; senão omite.
- **`notificacoes/envia.js`** vira `enviaTodos({db, webpush, messaging, periodo, agora, log})` exportado + CLI fino. Para cada `tokens.<k>`: `messaging.send({token, notification:{title,body}, data:{obraId?}, apns:{payload:{aps:{sound:'default'}}}})`; `messaging/registration-token-not-registered` e `invalid-argument` removem o token. `sw.js` passa a abrir `./#obra=<id>` quando o payload web tiver `obraId`, e `app.js` consome esse hash uma vez.
- **Vercel Cron**: `api/push-diario.js` chama `enviaTodos`; responde 401 sem `Authorization: Bearer ${CRON_SECRET}` e 503 se `CRON_SECRET` não existir. `vercel.json` ganha `crons` 12:00 e 21:00 UTC com `?periodo=manha|noite`. Dependências do servidor ficam em `notificacoes/package.json`; `api/` importa de lá. `notificacoes/README.md` ganha "Trocar para Vercel Cron" (secrets, desligar o `schedule` do workflow no mesmo deploy para não enviar em dobro).
- Testes: `tests/push.test.cjs` (web e nativo com fakes), `notificacoes` testes de `enviaTodos` com messaging/webpush falsos, `tests/cron.test.mjs` (401/503/200 com `enviaTodos` injetado), rules.

## 4d — Adições nativas

- Share: `OBRA_SHARE.exportar` tenta `OBRA_NATIVO.compartilharArquivo` antes do caminho web.
- Haptics: `OBRA_NATIVO.vibrar()` ao confirmar lançamento de gasto com sucesso.
- Status bar: `aplicaTema`, `aplicaSkin` e o boot chamam `OBRA_NATIVO.barraStatus(temaClaro())`.
- Splash: no nativo `splash-pre.js` remove o splash web e `splash.js` não roda; `OBRA_NATIVO.esconderSplash()` quando `CLOUD.ready` resolve (teto 8s).
- Segundo plano: `OBRA_NATIVO.aoSegundoPlano(() => CLOUD.flush?.())` — expõe o flush existente se ainda não público.

## 4e — Riscos do aparelho

- **Restauração de estado**: `showView`/`openObra` gravam `{tab, obraAberta}` em `localStorage['custta-estado']` (try/catch). Após o primeiro snapshot com dados, `bootCloud` restaura uma vez se a obra existir. Logout apaga a chave.
- **Versão**: `versao.json` na raiz `{ "versao": "1.0.0", "loja": "itms-apps://apps.apple.com/app/idPENDENTE" }`; `build-www` grava `APP_VERSAO` em `www/versao-app.js`; no nativo, Ajustes busca `versao.json` do domínio de produção (`https://app-construcao-civil.vercel.app/versao.json`, domínio acrescido ao `connect-src` da meta CSP do `www/`) e mostra banner dispensável quando maior. Comparação semver em `calc.js` (`versaoMaior`), testada. Sem ID da loja, o banner não aparece.
- **SDKs congelados**: `docs/sdks-fase4.md` lista Firebase Auth/Firestore/Messaging, Sentry e plugins Capacitor com dados coletados; `privacidade.html` passa a citar token de dispositivo do FCM.
- `sw.js`: `nativo.js`, `push.js` em `ASSETS`, `CACHE` incrementado; `tests/pwa.test.cjs` cobre.
- CSP web: `connect-src` inalterado exceto o necessário; `tests/headers.test.cjs` atualizado se mudar.

## Testes e aceite

1. `npm run test:unit`, `npm run test:rules`, `npm run test:browser` verdes.
2. Nova suíte Playwright `tests/browser/nativo.cjs` com `window.Capacitor` falso via `addInitScript`: SW não registra, botões viram Compartilhar e chamam Share, confirmação por dialog, status bar chamada ao trocar tema, toque em notificação abre a obra, estado restaurado após reload. Entra em `rodar.cjs`.
3. Validação manual com **agent-browser** em web e nativo simulado, 390×844 e 1280×800: zoom liberado, diálogos no lugar de `confirm`, zero violação de CSP no console.
4. `npm run cap:sync` conclui sem erro.
5. `docs/superpowers/plans/2026-09-16-fase4-checklist-aparelho.md`: o que só valida com Xcode/iPhone/Apple (build, TestFlight, push real com app fechado, modo avião, exclusão de conta no binário, pinch-zoom, teclado, sessão após uma semana).

## Fora do escopo

App Check, OTA, `@capacitor/keyboard`, auth nativa, desligar o cron do GitHub, Fase 5.
