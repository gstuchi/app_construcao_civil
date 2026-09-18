# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## O que é

Custta (ex-ObraControl, ex-"Minhas Obras") — PWA offline-first de controle de custos por obra. Vanilla JS, **sem framework, sem bundler, sem etapa de build**: os arquivos da raiz são servidos como estão. Deploy na Vercel; backend é Firebase (Auth + Firestore).

Código, comentários, identificadores e UI são em **português**. Mantenha assim ao editar (`obra`, `gasto`, `topico`, `fase`, `corrigido`).

Leia `PRODUCT.md` antes de mexer em UI: usuário-alvo não técnico, celular primeiro, dark é o padrão, "saldo em 5 segundos".

## Comandos

```bash
npm test                 # unit + rules
npm run test:unit        # node --test nos tests/*.cjs e *.mjs (sem browser, sem rede)
npm run test:browser     # emuladores + servidor estático + suítes Playwright de tests/browser/
npm run test:rules       # sobe o emulador do Firestore e roda tests/rules.test.mjs (precisa Java)
npm run rules:deploy     # firebase deploy --only firestore:rules
npm run build:www        # copia o app para www/ com CSP em <meta> (webDir do Capacitor)
npm run cap:sync         # build:www + cap sync ios

node --test tests/calc.test.cjs                              # um arquivo só
node --test --test-name-pattern="LICENSE" tests/docs.test.mjs  # um teste só (arquivos que usam node:test)
```

As rules só rodam com o emulador — use `npm run test:rules`.

`package.json` existe para teste, manutenção do SDK local, Capacitor e a função de cron do servidor (`api/`) — **nada dele é empacotado no app web**. Não adicione dependência de runtime ao browser.

CSP estrita no `vercel.json` (`default-src 'none'`, `script-src 'self'`, `style-src-attr 'none'`): nada de `<style>`, `style="..."` em atributo ou `onclick=` no HTML; Firebase e Sentry ficam versionados em `vendor/` (`npm run vendor:firebase` / `vendor:sentry`, a CI falha se o diff não estiver limpo).

Para dirigir o app num browser de verdade, suba `node tests/browser/servidor.cjs` (serve a raiz em :8123 com os headers do `vercel.json`) e chame a suíte direto — `tests/browser/rodar.cjs` só orquestra. As suítes com dados sintéticos (`mobile`, `cartao`, `nativo`, `contraste`) fazem stub de `window.CLOUD` e de `sessionStorage.splashVista` via `addInitScript`; as que usam SDK real (`fase1/2/3`, `persistencia`, `sync`) exigem os emuladores (`CUSTTA_EMULADORES=1`).

## Arquitetura

Scripts clássicos com globais, carregados na ordem em que aparecem no `index.html` — `tema.js` e `nativo.js` no `<head>`, para agir antes do primeiro paint; o resto no fim do `<body>`. Não há `import` entre eles (exceto `cloud.js`, que é `type="module"`); a comunicação é por global.

| Arquivo | Global exposto | Papel |
| --- | --- | --- |
| [calc.js](calc.js) | `OBRA_CALC` + `module.exports` | regras de negócio puras, zero DOM — é o que os testes de unidade cobrem |
| [cloud.js](cloud.js) | `window.CLOUD`, evento `cloud-pronto` | único ponto de contato com o Firebase |
| [auth.js](auth.js) | — | overlay de login (`#auth` + `body.locked`) |
| [nativo.js](nativo.js) | `OBRA_NATIVO` + `module.exports` | único ponto que toca `window.Capacitor`; no browser tudo é neutro |
| [push.js](push.js) | `OBRA_PUSH` + `module.exports` | notificações: Web Push na web, FCM no app iOS |
| [app.js](app.js) | `db`, `renderAll`, `OBRA_DIAG` | todo o estado e render da UI (~1800 linhas) |
| [ui-confirm.js](ui-confirm.js) | `OBRA_CONTA`, `OBRA_CONFIRM` | `<dialog>` de conta e as confirmações que substituem `confirm()`/`alert()` |
| [share.js](share.js) | `OBRA_SHARE` + `module.exports` | exportação JSON/CSV e o recorte `dadosDaObra` |
| [teclado.js](teclado.js) | `TECLADO` | teclado numérico próprio para digitar valor |
| [icons.js](icons.js) | `ICON` | SVGs inline (`data-ico`) |
| [styles.css](styles.css) | — | **todo o CSS do app** (temas, skins, componentes); `privacidade.css` serve só `privacidade.html` |
| [index.html](index.html) | — | markup; sem CSS e sem JavaScript inline (exigência da CSP) |

### Estado e sincronização

O app inteiro é um blob só: `{ obras: [...], config: { taxaMensal, topicosCustom } }`, gravado em `dados/{uid}` no Firestore. Não há localStorage de dados — só preferências por aparelho (localStorage: `mo_tema`, `mo_skin`, `custta-estado`; sessionStorage: `splashVista`).

Fluxo: mutação em `db` → `save()` → `CLOUD.saveDados` (entrega cada versão na hora à fila persistente do SDK e sobrescreve o documento inteiro) → `onSnapshot` volta → `bootCloud` ignora o eco (`meta.pendingWrites || meta.localDirty`, mais comparação `canon()`) → `renderAll()`.

Consequências práticas:

- **`saveDados` reescreve o blob inteiro.** Qualquer coisa que não deva ser sobrescrita por outro aparelho mora em documento separado — foi por isso que as inscrições de push viraram `push/{uid}`.
- Depois de mexer em `db`, sempre `save()` **e** `renderAll()` (ou o `render*` da view).
- Objeto obra: `{id, nome, fase: 'construcao'|'pronta'|'vendida', dataInicio, valorEstimadoVenda, areaM2, gastos: [], afazeres?: []}`. Gasto: `{id, valor, topico, descricao, data, pagamento}`; compra parcelada gera N gastos irmãos com `grupoId` comum e `parcela: {n, de}`.

### Fronteira de segurança

A `apiKey` em `cloud.js` é **pública por design**. A segurança está em [firestore.rules](firestore.rules), que valida a forma do blob (`hasOnly`, limites de tamanho, faixa de `taxaMensal`) em `dados/{uid}`, `perfis/{uid}` e `push/{uid}`.

Adicionar uma chave de topo em `db` **quebra as escritas em produção** se as rules não forem atualizadas junto. Ao mudar o formato do estado: editar `firestore.rules`, adicionar caso em `tests/rules.test.mjs`, `npm run test:rules`, `npm run rules:deploy`. Nunca editar rules pelo console do Firebase.

### Service worker

[sw.js](sw.js) é network-first. Ao **criar um arquivo JS/CSS novo na raiz**: adicione em `ASSETS` **e** incremente `CACHE` (`obras-vNN`). Sem o bump, aparelhos já instalados continuam com o retrato velho offline.

### Notificações push

`notificacoes/` é um cron do GitHub Actions ([.github/workflows/push-diario.yml](.github/workflows/push-diario.yml)) que dispara duas vezes ao dia — 12:00 UTC (9h Brasília) e 21:00 UTC (18h). O workflow deriva `PERIODO` (`manha`/`noite`) do cron que disparou, e `montaResumo` usa isso pra omitir o "Lançou os gastos de hoje?" de manhã. Roda com Admin SDK (ignora rules) e lê `push/{uid}`. É ferramenta de CI com `package.json` próprio — não faz parte do app. Chave VAPID pública fica hardcoded em `app.js`; a privada é secret do repositório.

### App iOS (Capacitor)

`ios/` é versionado; `www/` é gerado. Condicione comportamento nativo só via `OBRA_NATIVO.ehNativo()`. `confirm()`/`alert()` são proibidos (somem no WKWebView) — use `OBRA_CONFIRM`. Arquivo novo na raiz entra em `sw.js` `ASSETS`, que também alimenta `build-www`. Pendências de aparelho: `docs/plans/2026-09-16-fase4-checklist-aparelho.md`.

## UI

- Todo o CSS vive em `styles.css`. Cores vêm de custom properties; tema (`data-theme="light"`) e skin (`data-skin="azul"`) são atributos no `<html>`, aplicados por `tema.js` antes do primeiro paint. Não hardcode cor fora das variáveis — quebra um dos quatro combos tema×skin.
- Views são `<section class="view" id="v-*">`; `showView(tab)` troca. Cada uma tem seu `render*()` em `app.js`.
- **A navegação existe duplicada**: `aside.side` (desktop ≥900px) e `nav.tabs` (mobile), com os mesmos `data-tab`. Ao dirigir por browser, qualifique o seletor. Verifique mudanças visuais nos dois viewports.
- Modais: `openSheet(html)` / `closeSheet()` (bottom sheet + backdrop); conta e confirmações usam `<dialog>` (`OBRA_CONTA.abrir`, `OBRA_CONFIRM.perguntar`). Feedback: `toast(msg, tipo)`.
- Campos de dinheiro: `maskMoney(sel)` na entrada, `OBRA_CALC.parseNum` na leitura.

Um hook PostToolUse (`.claude/settings.local.json`) roda o detector da skill `impeccable` após cada Edit/Write em arquivo de UI e devolve achados como system reminder.

## Fluxo de trabalho

Features maiores começam por um documento em `docs/specs/AAAA-MM-DD-nome-design.md` (e às vezes um plano em `docs/plans/`) antes do código — vale ler o spec correspondente antes de mexer numa tela existente.

Commits em português, estilo `feat: `/`fix: `/`docs: `, minúsculas, sem acento no assunto.

`.gitignore` bloqueia service accounts, `.env`, chaves VAPID e certificados iOS. A apiKey do Firebase é a única credencial que pode aparecer em commit.
