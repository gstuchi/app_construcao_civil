# Blindagem 4 (custo do Firebase) — plano de implementação

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> Neste time, o Forja implementa uma tarefa por vez e o Lupa revisa cada uma antes da próxima. Ninguém faz commit, push ou PR sem o Orquestrador pedir. Os passos do Giovani são conduzidos pelo Orquestrador.

**Goal:** Fechar o risco de uma conta sem limite antes de o Giovani ativar a conta completa do Google Cloud, com teto de R$ 100 por mês. Quatro peças: alerta de leituras, corte automático de gasto, chaves restritas e App Check.

**Architecture:**
- **Corte:** uma função em projeto próprio recebe os avisos do orçamento e do alerta de leituras. Em R$ 60, ou no alerta, ela desliga a API do Firestore, e a cobrança continua ligada. Em R$ 100 ela só tira a cobrança se a API não desligou, com falha persistente por 6 h, ou se o gasto vier de fora do Firestore, medido por um segundo orçamento. Cada ação tem um interruptor próprio, e a retirada da cobrança só arma com o teste de 31 dias ou o aceite do risco.
- **App Check:** o site usa reCAPTCHA Enterprise, só nos endereços publicados, e o app usa App Attest, só no Release. Entram observando. A exigência é ligada depois, no console, só para o Firestore.
- **Chaves:** restrição só no console.
- O formato do estado e as `firestore.rules` não mudam. O cron do push, com Admin SDK, não muda.

**Decisões do Giovani** (09/11; a tabela de Decisões dá o porquê):
1. Teto de R$ 100 por mês. Ele aceita que o app e os backups parem se o corte disparar.
2. O corte em dois tempos: R$ 60 desliga a API, R$ 100 tira a cobrança com as duas condições acima. Se o T1 ou o T2 reprovar, volta para a opção oficial do Google, um tempo só, tirar a cobrança em R$ 60 (`--modo-oficial`).
3. A função mora em projeto próprio.
4. O alerta de 500 leituras por minuto, por 5 minutos, aciona o primeiro tempo.
5. A retirada da cobrança tem interruptor próprio, desligado até o teste de 31 dias ou até ele aceitar o risco de perder dados.
6. Liberar `vercel.app` no reCAPTCHA e na chave web, para as prévias continuarem.
7. Cópia dos dados fora do projeto: decidir depois do teste de 31 dias.

**Tech Stack:** site com Firebase JS 12.18.0 e reCAPTCHA Enterprise; app em SwiftUI com firebase-ios-sdk 12.19.2 e App Attest; função em Node 22 no Cloud Run; orçamentos do Cloud Billing, Pub/Sub e Service Usage API.

**De onde vem.** Em `~/.claude/projects/-Users-giovanistuchi-Documents-app-construcao-civil/etapa4-roteiros/prumo-blindagem4/`: `pesquisa.md` (documentação com citações), `conselho/` (propostas e críticas), `web-relatorio.md`, `ios-relatorio.md`, `corte-relatorio.md` e os bundles dos protótipos. A CI do Swift 6.3.3 rodou no ramo `proto/b4-ios-swift63` (run 42698765597), com 10 de 10 jobs verdes na tentativa 2.

## Global Constraints

- **Site:** CSP estrita. Nada de `<style>`, `style="..."` ou `onclick=`. Arquivo novo em `vendor/firebase` entra em `ASSETS` e sobe o `CACHE` do `sw.js`. Sem dependência de runtime fora de `vendor/`, salvo o script do reCAPTCHA, que só o Google serve.
- **Estado:** o formato não muda, e as `firestore.rules` também não.
- **App:** iOS 26 mínimo. Swift 6 estrito, zero aviso novo, nada só do Swift 6.4 (a CI usa 6.3.3). Debug, emuladores e serviços falsos não ligam o App Check.
- **Função:** `corte/` não vai para a Vercel (`.vercelignore`). Nenhum teste chama o Google nem o `gcloud` de verdade. Desarmada por padrão.
- **Língua:** português no código, nos identificadores, nos comentários e na interface.
- **Commits:** autor só `Giovani Stuchi <stuchigiovani@gmail.com>`, sem `Co-Authored-By` e sem rodapé. Título conventional em português com acento, corpo em prosa, um commit por tarefa, branch e PR, nunca direto na `main`.

## Decisões

Passaram pelo conselho (3 Opus, lentes custo, risco aos dados e operação, crítica às cegas): as linhas de 1 a 8. Registro completo em `conselho/decisao.md`.

| # | Decisão | Descartado | Porquê |
|---|---|---|---|
| 1 | Primeiro tempo: desligar a API do Firestore | Tirar a cobrança em R$ 60 | A oficial ficou em último nas 3 críticas: expõe banco e backups ao apagamento documentado a cada disparo, e não chega antes, porque depende do mesmo aviso atrasado. |
| 2 | Mesma linha | Trancar só a leitura nas regras | A trava deixa gravar sem ler, e cada edição regrava o documento inteiro, então aparelhos se sobrescrevem às cegas; `push/{uid}` fica aberto (`firestore.rules:84`). |
| 3 | R$ 100 condicional | R$ 100 sempre | O custo chega atrasado e passaria de R$ 100 com o gasto já parado. |
| 4 | Segundo orçamento para o que não é Firestore | Regra de 48 h com R$ 5 | R$ 5 é 1 minuto de ataque, e o armazenamento disparava a regra. Sobra o reCAPTCHA, que não para com a API. |
| 5 | Conferir por `services.get`, e falha só conta se durar 6 h | Confiar no código de erro | `FAILED_PRECONDITION` também sai por serviço dependente. Falha passageira não pode levar ao passo irreversível. |
| 6 | Religar grava uma base por mês, e a função segue armada | Calar a função até o mês seguinte | Calaria o corte no mês do ataque. |
| 7 | Projeto próprio | Mesmo projeto | Sem cobrança, a função cairia junto. |
| 8 | Aviso e prova de vida no projeto da função | Depender do cron do push | O cron morre com a API. |
| 9 | Medir sem o crédito do teste (só `Promotional credits` desmarcado) | Líquido de créditos | A prova no descartável vale igual em produção. |
| 10 | Site com prazo de 4 s no reCAPTCHA e recusa imediata sem rede | SDK puro | Provado: sem o script, o login para 30,9 s e o Firestore não abre, mesmo só observando. Com token vencido, abrir sem rede levava 4 s; com a recusa, cerca de 58 ms. |
| 11 | Debug do app diz `nil` à fábrica do App Check | Só não chamar | Linkar o SDK já registra uma fábrica padrão, que no simulador chama a rede real. |
| 12 | Selo do reCAPTCHA escondido, com a frase na tela de login | Selo visível | O FAQ do reCAPTCHA permite, com "This site is protected by reCAPTCHA." visível. Desde 02/04/2026 os links para política e termos saíram dessa exigência. |

## Como entregar

1. **Três PRs, um risco cada,** na ordem abaixo. A ordem geral do trabalho está em "Passos do Giovani". Antes deles, este plano vai ao repo em `docs/plans/2026-11-09-blindagem4-custo.md`, por PR próprio, como o #105: o `corte/README.md` e o e-mail do corte apontam para ele.
2. **PR 1, o corte:** sem efeito no app, porque nada roda antes do G4. A volta para a opção oficial já vem no código, desarmada.
3. **PR 2, site:** só faz merge depois do G9, com a chave real no lugar de `CHAVE_RECAPTCHA_DO_SITE`. Conferir a prévia da Vercel contra a produção, com login e sincronização, e colar o link e o "como testar" no PR. Na prévia, o App Check vai observar e a página tem de abrir sem violação nova de CSP.
4. **PR 3, app:** só faz merge depois do G11. Abre o TestFlight da Blindagem 4, que só sai com o OK dele. Depois de instalar: entrar, lançar, sincronizar, e ver o tráfego aparecer em App Check → **APIs** → **Cloud Firestore** como verificado. Essa é a única prova real do App Attest.
5. **Prova do Swift 6.3.3:** ramo `proto/b4-ios-swift63`, run 42698765597, Xcode 26.6. Compilou, e os 10 jobs ficaram verdes na tentativa 2, sem mudar código. Na tentativa 1, `testVarreduraDoProximoNas71LinhasNaMaiorLetra` e `testContrasteDoOrcamentoNosDoisTemas` reprovaram (testes de tela do iOS 26, com serviços falsos) e o job `app` foi cortado pelo teto de 90 min. Na tentativa 2 o `app` levou 85 min, contra 66 da base 41246db, com os mesmos 121 casos. A abertura do app subiu 0,2 s por teste (mediana), 88% do aumento veio de depois dela, e o log não tem nenhuma linha de App Check durante os testes: é compatível com a variação da VM, que já chegou a 60% entre rodadas, mas o teto ficou perto. **No PR 3, contar com rerun do `app` se ele bater no teto.** Apagar o ramo depois do merge do PR 3.
6. **O que o Lupa não precisa provar de novo:** as mutações e os tempos anotados em cada tarefa, salvo se o código mudar.

## PR 1: a função de corte

**Ramo:** `feat/blindagem4-corte`, a partir da `main`. **Risco:** Código novo em `corte/`, fora da Vercel. Nada roda até o G4, e a função nasce desarmada. Linhas de produção: ~500.

> **Como o PR 1 entrou (10/11).** Além das 8 tarefas, a revisão trouxe 4 commits depois da Tarefa 8: a CI instala e confere a assinatura do lockfile de `corte/`; o Google falso dos testes confere o prazo e o `responseType`, e o teste do implantar exige `--max-instances=3`; incidente aberto de política desconhecida vira `corte-erro`, sem agir; e, por decisão do Giovani, a folga do `religar.sh` vale também para o orçamento de fora do Firestore quando a cobrança foi tirada. As listagens abaixo mostram o código de antes desses commits: o estado final está no código, no passo 4 de "Alerta aciona o corte" e em "Se o corte agir". Na Tarefa 1, o lockfile ficou o do protótipo, com o `google-auth-library` na 11.3.2, e a última frase da mensagem do commit mudou, porque a 11.3.3 completou os 7 dias no dia.

### Tarefa 1: chore: pacote da função de corte de gastos

**Arquivos:** `.vercelignore`, `corte/.npmrc` (novo), `corte/package.json` (novo), `tests/pacotes.test.cjs`

Rode `npm install --prefix corte` para gerar o `corte/package-lock.json` (entra no commit). `min-release-age=7` deixa `google-auth-library` em `^11.3.2`. `npm audit` mostra 3 moderadas em `uuid`, via `cloudevents`, do Functions Framework, sem conserto sem `--force`.

- [ ] **Aplicar**

````diff
diff --git a/.vercelignore b/.vercelignore
index aa2d5f8..2b456ca 100644
--- a/.vercelignore
+++ b/.vercelignore
@@ -7,6 +7,7 @@ app-ios/
 docs/
 tests/
 scripts/
+corte/
 .github/
 *.md
 firebase.json
diff --git a/corte/.npmrc b/corte/.npmrc
new file mode 100644
index 0000000..9107949
--- /dev/null
+++ b/corte/.npmrc
@@ -0,0 +1,4 @@
+# Script de instalação de dependência só roda aprovado no allowScripts do
+# package.json (npm 11+): pacote novo com script faz o install falhar em vez de
+# rodar código de terceiro. tests/pacotes.test.cjs confere a política.
+strict-allow-scripts=true
diff --git a/corte/package.json b/corte/package.json
new file mode 100644
index 0000000..c808c6b
--- /dev/null
+++ b/corte/package.json
@@ -0,0 +1,15 @@
+{
+  "name": "custta-corte",
+  "version": "0.0.0",
+  "license": "UNLICENSED",
+  "private": true,
+  "description": "Corte de gastos do Custta: Cloud Run function em projeto próprio. Não faz parte do app.",
+  "main": "index.js",
+  "engines": {
+    "node": "22"
+  },
+  "dependencies": {
+    "@google-cloud/functions-framework": "^5.0.5",
+    "google-auth-library": "^11.3.2"
+  }
+}
diff --git a/tests/pacotes.test.cjs b/tests/pacotes.test.cjs
index 510738c..497e7b0 100644
--- a/tests/pacotes.test.cjs
+++ b/tests/pacotes.test.cjs
@@ -45,6 +45,10 @@ const REVISADOS = {
     'firebase-admin': 'github.com/firebase/firebase-admin-node',
     'web-push': 'github.com/web-push-libs/web-push',
   },
+  'corte': {
+    '@google-cloud/functions-framework': 'github.com/GoogleCloudPlatform/functions-framework-nodejs',
+    'google-auth-library': 'github.com/googleapis/google-cloud-node',
+  },
 };
 
 /* Nome do pacote pela chave do lockfile: "node_modules/a/node_modules/@b/c" → "@b/c". */
````

- [ ] **Verificar**

````bash
npm run test:unit
````

- [ ] **Commit**

````bash
git add .vercelignore corte/.npmrc corte/package.json tests/pacotes.test.cjs corte/package-lock.json
git commit -F - <<'FIM'
chore: pacote da função de corte de gastos

A função de corte (Blindagem 4) roda como Cloud Run function em projeto
próprio e não faz parte do app: fica em corte/, com o próprio package.json
e lockfile, fora do deploy da Vercel pelo .vercelignore. As duas
dependências diretas foram conferidas no registro e entram na lista
revisada do teste de pacotes, junto da mesma trava de script de instalação
das outras pastas. O google-auth-library fica na 11.3.2 porque as versões
mais novas ainda não têm os 7 dias exigidos pela configuração do npm.
FIM
````

### Tarefa 2: feat: regra pura do corte de gastos

**Arquivos:** `corte/regra.js` (novo), `package.json`, `tests/corte.test.cjs` (novo)

Testes primeiro, em `tests/corte.test.cjs`. Os 16 cenários do pedido estão nomeados ali. Na CI, roda em `npm run test:unit`, sem instalar `corte/`.

- [ ] **Aplicar**

````diff
diff --git a/corte/regra.js b/corte/regra.js
new file mode 100644
index 0000000..66ca9d5
--- /dev/null
+++ b/corte/regra.js
@@ -0,0 +1,108 @@
+'use strict';
+/* Decisão pura do corte de gastos: recebe fatos, devolve o que fazer. Nada aqui toca rede,
+   disco ou relógio. Limiares valem sobre custo = costAmount − base, em centavos, para a
+   conta em reais não errar na fronteira (64,07 − 4,07 dá 59,99999999999999). */
+
+const LIMITE_API = 6000; // R$ 60,00: desliga a API do Firestore
+const LIMITE_COBRANCA = 10000; // R$ 100,00: tira a cobrança
+const ESPERA_FALHA_MS = 6 * 60 * 60 * 1000; // falha de desligar que persiste tanto vira corte da cobrança
+
+/* Mensagem que nunca vai dar certo: registra e não relança, para o Pub/Sub não repetir à toa. */
+class MensagemIlegivel extends Error {}
+
+const centavos = reais => Math.round(reais * 100);
+
+function estadoNormal(lido){
+  return { orcamentos: {}, primeiraFalha: null, apiDesligadaEm: null, cobrancaTiradaEm: null, ...(lido || {}) };
+}
+
+/* O início do período é o dia 1 num fuso qualquer (Pacífico, em geral): em UTC cai entre a véspera
+   e o dia 1. Somar 15 h leva todos eles para dentro do mês certo. */
+function intervaloDe(inicio){
+  const t = Date.parse(inicio);
+  return Number.isNaN(t) ? null : new Date(t + 15 * 3600 * 1000).toISOString().slice(0, 7);
+}
+
+function interpretarOrcamento(c){
+  const intervalo = typeof c.costIntervalStart === 'string' ? intervaloDe(c.costIntervalStart) : null;
+  if(typeof c.budgetDisplayName !== 'string' || !Number.isFinite(c.costAmount) || typeof c.currencyCode !== 'string' || !intervalo)
+    throw new MensagemIlegivel('orçamento com campo faltando ou inválido');
+  return { tipo: 'orcamento', nome: c.budgetDisplayName, custo: c.costAmount, moeda: c.currencyCode, intervalo };
+}
+
+function interpretarIncidente(inc){
+  if(!inc || typeof inc.policy_name !== 'string' || typeof inc.state !== 'string')
+    throw new MensagemIlegivel('incidente sem policy_name ou state');
+  return { tipo: 'incidente', politica: inc.policy_name, estado: inc.state };
+}
+
+/* evento é o CloudEvent do Pub/Sub: data.message.data traz o JSON em base64. */
+function interpretar(evento){
+  const bruto = evento && evento.data && evento.data.message && evento.data.message.data;
+  if(typeof bruto !== 'string' || !bruto) throw new MensagemIlegivel('mensagem sem dados');
+  let corpo;
+  try{
+    corpo = JSON.parse(Buffer.from(bruto, 'base64').toString('utf8'));
+  }catch{
+    throw new MensagemIlegivel('dados que não são JSON');
+  }
+  if(corpo && typeof corpo === 'object' && !Array.isArray(corpo)){
+    if(corpo.incident !== undefined) return interpretarIncidente(corpo.incident);
+    if(corpo.budgetDisplayName !== undefined) return interpretarOrcamento(corpo);
+  }
+  throw new MensagemIlegivel('formato desconhecido');
+}
+
+/* Guarda a mensagem no estado. Devolve o mesmo objeto quando nada muda (nada a regravar).
+   velha: true é o mês que já passou; custoCentavos é o custo que vale para os limiares.
+   Virar o mês do projeto limpa a primeiraFalha: falha velha não pode encurtar as 6 horas
+   do mês novo, porque o passo seguinte é irreversível. */
+function aplicarOrcamento(estado, msg, papel){
+  const atual = estado.orcamentos[msg.nome];
+  if(atual && msg.intervalo < atual.intervalo) return { estado, velha: true };
+  const virou = Boolean(atual) && msg.intervalo > atual.intervalo;
+  const registro = !atual || virou ? { intervalo: msg.intervalo, base: 0, maiorCusto: 0 } : atual;
+  const custoCentavos = centavos(msg.custo) - centavos(registro.base);
+  const maiorCusto = Math.max(registro.maiorCusto, msg.custo);
+  if(atual && !virou && maiorCusto === atual.maiorCusto) return { estado, custoCentavos };
+  const novo = { ...estado, orcamentos: { ...estado.orcamentos, [msg.nome]: { ...registro, maiorCusto } } };
+  if(virou && papel === 'projeto') novo.primeiraFalha = null;
+  return { estado: novo, custoCentavos };
+}
+
+/* 'projeto' é o orçamento do projeto; 'fora' é o de todos os serviços menos o Firestore. */
+function papelDoOrcamento(nome, config){
+  if(nome === config.orcamentoProjeto) return 'projeto';
+  if(nome === config.orcamentoFora) return 'fora';
+  return null;
+}
+
+function decidirOrcamento(papel, custoCentavos){
+  if(papel === 'fora') return custoCentavos >= LIMITE_COBRANCA ? 'tirar-cobranca' : 'nada';
+  return custoCentavos >= LIMITE_API ? 'desligar-api' : 'nada';
+}
+
+/* A cobrança só sai pelo orçamento do projeto quando a API não ficou desligada: é o que o
+   chamador prova (services.get) antes de perguntar. Aqui, o custo e o tempo da falha. */
+function deveTirarCobrancaPorFalha(custoCentavos, primeiraFalha, agoraMs){
+  return custoCentavos >= LIMITE_COBRANCA && Boolean(primeiraFalha) && agoraMs - Date.parse(primeiraFalha) >= ESPERA_FALHA_MS;
+}
+
+function registrarFalha(estado, agora){
+  return { ...estado, primeiraFalha: estado.primeiraFalha || agora };
+}
+
+/* API confirmada desligada encerra a falha: a contagem só anda enquanto o estado real é ligada. */
+function registrarApiDesligada(estado, agora){
+  return { ...estado, apiDesligadaEm: estado.apiDesligadaEm || agora, primeiraFalha: null };
+}
+
+function registrarCobrancaTirada(estado, agora){
+  return { ...estado, cobrancaTiradaEm: estado.cobrancaTiradaEm || agora };
+}
+
+module.exports = {
+  LIMITE_API, LIMITE_COBRANCA, ESPERA_FALHA_MS, MensagemIlegivel,
+  estadoNormal, intervaloDe, interpretar, aplicarOrcamento, papelDoOrcamento, decidirOrcamento,
+  deveTirarCobrancaPorFalha, registrarFalha, registrarApiDesligada, registrarCobrancaTirada,
+};
diff --git a/package.json b/package.json
index 61663cf..dd087bf 100644
--- a/package.json
+++ b/package.json
@@ -6,7 +6,7 @@
   "description": "Custta: aplicação estática sem build no deploy; npm mantém SDK local, testes, Capacitor e a função de cron do servidor.",
   "scripts": {
     "test": "npm run test:unit && npm run test:rules",
-    "test:unit": "node --test tests/calc.test.cjs tests/moeda.test.cjs tests/icons.test.cjs tests/logo-escrito.test.cjs tests/teclado.test.cjs tests/resumo.test.cjs tests/xss.test.cjs tests/headers.test.cjs tests/vercel.test.cjs tests/pwa.test.cjs tests/workflow.test.cjs tests/sync.test.cjs tests/fila.test.mjs tests/diagnostico.test.cjs tests/share.test.cjs tests/conta.test.mjs tests/fuso.test.cjs tests/dados.test.cjs tests/cadastro.test.cjs tests/sentry.test.cjs tests/nativo.test.cjs tests/ios.test.cjs tests/gestos.test.cjs tests/molas.test.mjs tests/vidro.test.cjs tests/build-www.test.mjs tests/capacitor.test.cjs tests/cloud-nativo.test.mjs tests/dialogos.test.cjs tests/push.test.cjs tests/push-cloud.test.mjs tests/enviar.test.cjs tests/cron.test.cjs tests/privacidade.test.cjs tests/screenshots.test.mjs tests/conta-demo.test.mjs tests/docs.test.mjs tests/google-cloud.test.mjs tests/apple-cloud.test.mjs tests/admin-deps.test.cjs tests/pacotes.test.cjs tests/sonda-banco.test.mjs tests/vetores.test.mjs tests/app-ios.test.cjs tests/compara-laudo.test.mjs",
+    "test:unit": "node --test tests/calc.test.cjs tests/moeda.test.cjs tests/icons.test.cjs tests/logo-escrito.test.cjs tests/teclado.test.cjs tests/resumo.test.cjs tests/xss.test.cjs tests/headers.test.cjs tests/vercel.test.cjs tests/pwa.test.cjs tests/workflow.test.cjs tests/sync.test.cjs tests/fila.test.mjs tests/diagnostico.test.cjs tests/share.test.cjs tests/conta.test.mjs tests/fuso.test.cjs tests/dados.test.cjs tests/cadastro.test.cjs tests/sentry.test.cjs tests/nativo.test.cjs tests/ios.test.cjs tests/gestos.test.cjs tests/molas.test.mjs tests/vidro.test.cjs tests/build-www.test.mjs tests/capacitor.test.cjs tests/cloud-nativo.test.mjs tests/dialogos.test.cjs tests/push.test.cjs tests/push-cloud.test.mjs tests/enviar.test.cjs tests/cron.test.cjs tests/privacidade.test.cjs tests/screenshots.test.mjs tests/conta-demo.test.mjs tests/docs.test.mjs tests/google-cloud.test.mjs tests/apple-cloud.test.mjs tests/admin-deps.test.cjs tests/corte.test.cjs tests/pacotes.test.cjs tests/sonda-banco.test.mjs tests/vetores.test.mjs tests/app-ios.test.cjs tests/compara-laudo.test.mjs",
     "test:rules": "firebase emulators:exec --only firestore \"node --test tests/rules.test.mjs\"",
     "rules:deploy": "firebase deploy --only firestore:rules",
     "vendor:firebase": "node scripts/vendor-firebase.mjs",
diff --git a/tests/corte.test.cjs b/tests/corte.test.cjs
new file mode 100644
index 0000000..ed3a03d
--- /dev/null
+++ b/tests/corte.test.cjs
@@ -0,0 +1,149 @@
+'use strict';
+/* Corte de gastos (corte/), a Blindagem 4: a regra é pura, o adaptador do Google roda sobre um
+   cliente HTTP falso e os scripts sobre um gcloud falso no PATH. Nada aqui usa rede nem precisa
+   do npm install de corte/ (index.js carrega as dependências só quando a função roda). */
+const { test } = require('node:test');
+const assert = require('node:assert/strict');
+const regra = require('../corte/regra.js');
+
+const b64 = c => Buffer.from(typeof c === 'string' ? c : JSON.stringify(c)).toString('base64');
+const eventoDe = corpo => ({ data: { message: { data: b64(corpo), attributes: { schemaVersion: '1.0' } } } });
+const NOV = '2026-11-01T07:00:00Z';
+const msgOrcamento = (custo, extra = {}) => ({
+  budgetDisplayName: 'projeto', costAmount: custo, costIntervalStart: NOV,
+  budgetAmount: 120, budgetAmountType: 'SPECIFIED_AMOUNT', currencyCode: 'BRL', ...extra,
+});
+
+test('regra: orçamento traz nome, custo, moeda e o mês do intervalo', ()=>{
+  assert.deepEqual(regra.interpretar(eventoDe(msgOrcamento(61.5))),
+    { tipo: 'orcamento', nome: 'projeto', custo: 61.5, moeda: 'BRL', intervalo: '2026-11' });
+});
+
+test('regra: o mês sai certo em qualquer fuso do início do período', ()=>{
+  for(const inicio of ['2026-11-01T07:00:00Z', '2026-11-01T08:00:00Z', '2026-11-01T00:00:00Z', '2026-10-31T15:00:00Z'])
+    assert.equal(regra.interpretar(eventoDe(msgOrcamento(1, { costIntervalStart: inicio }))).intervalo, '2026-11', inicio);
+  assert.equal(regra.interpretar(eventoDe(msgOrcamento(1, { costIntervalStart: '2027-01-01T08:00:00Z' }))).intervalo, '2027-01');
+});
+
+test('regra: incidente traz a política e o estado', ()=>{
+  assert.deepEqual(regra.interpretar(eventoDe({ version: '1.2', incident: { incident_id: 'x', policy_name: 'leituras', state: 'open' } })),
+    { tipo: 'incidente', politica: 'leituras', estado: 'open' });
+});
+
+test('regra: mensagem ilegível lança MensagemIlegivel', ()=>{
+  assert.equal(typeof regra.MensagemIlegivel, 'function');
+  const ruins = [
+    {},
+    { data: {} },
+    { data: { message: {} } },
+    { data: { message: { data: '' } } },
+    { data: { message: { data: 123 } } },
+    eventoDe('isto não é json'),
+    eventoDe([1, 2]),
+    eventoDe({ qualquer: 'coisa' }),
+    eventoDe(msgOrcamento('61')),
+    eventoDe(msgOrcamento(NaN)),
+    eventoDe(msgOrcamento(10, { costIntervalStart: 'ontem' })),
+    eventoDe(msgOrcamento(10, { currencyCode: undefined })),
+    eventoDe(msgOrcamento(10, { budgetDisplayName: 7 })),
+    eventoDe({ version: '1.2', incident: { state: 'open' } }),
+    eventoDe({ version: '1.2', incident: { policy_name: 'x' } }),
+  ];
+  for(const e of ruins) assert.throws(()=>regra.interpretar(e), regra.MensagemIlegivel, JSON.stringify(e));
+});
+
+test('regra: estadoNormal completa o que falta e o estado vazio não tem nada', ()=>{
+  assert.deepEqual(regra.estadoNormal(null), { orcamentos: {}, primeiraFalha: null, apiDesligadaEm: null, cobrancaTiradaEm: null });
+  assert.deepEqual(regra.estadoNormal({ primeiraFalha: 'x' }).orcamentos, {});
+  assert.equal(regra.estadoNormal({ primeiraFalha: 'x' }).primeiraFalha, 'x');
+});
+
+const msg = (custo, nome = 'projeto', intervalo = '2026-11') => ({ tipo: 'orcamento', nome, custo, moeda: 'BRL', intervalo });
+
+test('regra: primeira mensagem do orçamento cria o registro do mês', ()=>{
+  const r = regra.aplicarOrcamento(regra.estadoNormal(null), msg(61), 'projeto');
+  assert.deepEqual(r.estado.orcamentos.projeto, { intervalo: '2026-11', base: 0, maiorCusto: 61 });
+  assert.equal(r.custoCentavos, 6100);
+});
+
+test('regra: custo desconta a base em centavos, sem erro de ponto flutuante', ()=>{
+  const base = 4.07;
+  const estado = regra.estadoNormal({ orcamentos: { projeto: { intervalo: '2026-11', base, maiorCusto: base } } });
+  assert.equal(64.07 - base < 60, true, 'o caso do teste precisa ser o que quebra na conta em reais');
+  assert.equal(regra.aplicarOrcamento(estado, msg(base + 59), 'projeto').custoCentavos, 5900);
+  assert.equal(regra.aplicarOrcamento(estado, msg(64.07), 'projeto').custoCentavos, 6000);
+});
+
+test('regra: fora de ordem não mexe no maiorCusto', ()=>{
+  const estado = regra.estadoNormal({ orcamentos: { projeto: { intervalo: '2026-11', base: 0, maiorCusto: 61 } } });
+  const r = regra.aplicarOrcamento(estado, msg(40), 'projeto');
+  assert.equal(r.estado, estado, 'sem mudança devolve o mesmo objeto: nada a regravar');
+  assert.equal(r.custoCentavos, 4000);
+});
+
+test('regra: custo acima do maiorCusto sobe o maiorCusto e guarda a base', ()=>{
+  const estado = regra.estadoNormal({ orcamentos: { projeto: { intervalo: '2026-11', base: 10, maiorCusto: 61 } } });
+  const r = regra.aplicarOrcamento(estado, msg(70), 'projeto');
+  assert.deepEqual(r.estado.orcamentos.projeto, { intervalo: '2026-11', base: 10, maiorCusto: 70 });
+  assert.equal(r.custoCentavos, 6000);
+});
+
+test('regra: mês novo zera base e maiorCusto, sem tocar no outro orçamento', ()=>{
+  const fora = { intervalo: '2026-10', base: 5, maiorCusto: 5 };
+  const estado = regra.estadoNormal({ orcamentos: { projeto: { intervalo: '2026-10', base: 70, maiorCusto: 90 }, fora } });
+  const r = regra.aplicarOrcamento(estado, msg(3), 'projeto');
+  assert.deepEqual(r.estado.orcamentos.projeto, { intervalo: '2026-11', base: 0, maiorCusto: 3 });
+  assert.deepEqual(r.estado.orcamentos.fora, fora);
+  assert.equal(r.custoCentavos, 300);
+});
+
+test('regra: mensagem do mês velho depois do mês novo é ignorada', ()=>{
+  const estado = regra.estadoNormal({ orcamentos: { projeto: { intervalo: '2026-12', base: 0, maiorCusto: 2 } } });
+  const r = regra.aplicarOrcamento(estado, msg(90, 'projeto', '2026-11'), 'projeto');
+  assert.equal(r.velha, true);
+  assert.equal(r.estado, estado);
+});
+
+test('regra: virar o mês do projeto zera a primeiraFalha; o outro orçamento não mexe nela', ()=>{
+  const antes = { orcamentos: { projeto: { intervalo: '2026-10', base: 0, maiorCusto: 80 }, fora: { intervalo: '2026-10', base: 0, maiorCusto: 1 } }, primeiraFalha: '2026-10-31T20:00:00.000Z' };
+  assert.equal(regra.aplicarOrcamento(regra.estadoNormal(antes), msg(1), 'projeto').estado.primeiraFalha, null);
+  assert.equal(regra.aplicarOrcamento(regra.estadoNormal(antes), msg(1, 'fora'), 'fora').estado.primeiraFalha, antes.primeiraFalha);
+  const semRegistro = regra.estadoNormal({ primeiraFalha: '2026-10-31T20:00:00.000Z' });
+  assert.equal(regra.aplicarOrcamento(semRegistro, msg(1), 'projeto').estado.primeiraFalha, semRegistro.primeiraFalha, 'primeira mensagem do orçamento não é virada de mês');
+});
+
+test('regra: papel do orçamento pelo nome configurado', ()=>{
+  const config = { orcamentoProjeto: 'projeto', orcamentoFora: 'fora' };
+  assert.equal(regra.papelDoOrcamento('projeto', config), 'projeto');
+  assert.equal(regra.papelDoOrcamento('fora', config), 'fora');
+  assert.equal(regra.papelDoOrcamento('outro', config), null);
+});
+
+test('regra: limiares em centavos, por papel', ()=>{
+  assert.equal(regra.decidirOrcamento('projeto', 5999), 'nada');
+  assert.equal(regra.decidirOrcamento('projeto', 6000), 'desligar-api');
+  assert.equal(regra.decidirOrcamento('projeto', 30000), 'desligar-api');
+  assert.equal(regra.decidirOrcamento('fora', 9999), 'nada');
+  assert.equal(regra.decidirOrcamento('fora', 10000), 'tirar-cobranca');
+});
+
+test('regra: cobrança só sai com custo de R$ 100 e falha de 6 horas', ()=>{
+  const seis = 6 * 60 * 60 * 1000, t0 = Date.parse('2026-11-09T12:00:00.000Z'), falha = new Date(t0).toISOString();
+  assert.equal(regra.deveTirarCobrancaPorFalha(10000, falha, t0 + seis), true);
+  assert.equal(regra.deveTirarCobrancaPorFalha(10000, falha, t0 + seis - 1), false);
+  assert.equal(regra.deveTirarCobrancaPorFalha(9999, falha, t0 + seis), false);
+  assert.equal(regra.deveTirarCobrancaPorFalha(10000, null, t0 + seis), false);
+});
+
+test('regra: o que fica registrado do estado real', ()=>{
+  const agora = '2026-11-09T12:00:00.000Z', depois = '2026-11-09T13:00:00.000Z';
+  const base = regra.estadoNormal(null);
+  const falhou = regra.registrarFalha(base, agora);
+  assert.equal(falhou.primeiraFalha, agora);
+  assert.equal(regra.registrarFalha(falhou, depois).primeiraFalha, agora, 'a primeira falha não anda');
+  const desligada = regra.registrarApiDesligada(falhou, agora);
+  assert.equal(desligada.apiDesligadaEm, agora);
+  assert.equal(desligada.primeiraFalha, null, 'API confirmada desligada encerra a falha');
+  assert.equal(regra.registrarApiDesligada(desligada, depois).apiDesligadaEm, agora, 'vale a primeira vez');
+  assert.equal(regra.registrarCobrancaTirada(base, agora).cobrancaTiradaEm, agora);
+});
````

- [ ] **Verificar**

````bash
npm run test:unit
````

- [ ] **Commit**

````bash
git add corte/regra.js package.json tests/corte.test.cjs corte/package-lock.json
git commit -F - <<'FIM'
feat: regra pura do corte de gastos

A decisão do corte fica num módulo sem rede, disco ou relógio: lê a
mensagem do Pub/Sub (orçamento ou incidente), guarda o maior custo por
orçamento e por mês, desconta a base e diz o que fazer em R$ 60 e R$ 100.
A conta é em centavos porque em reais a fronteira erra: 64,07 menos 4,07
dá menos que 60. Virar o mês do projeto limpa a primeira falha, para uma
falha velha não encurtar as 6 horas antes do passo irreversível.
FIM
````

### Tarefa 3: feat: adaptador das APIs do Google para o corte

**Arquivos:** `corte/google.js` (novo), `tests/corte.test.cjs`

- [ ] **Aplicar**

````diff
diff --git a/corte/google.js b/corte/google.js
new file mode 100644
index 0000000..da7187b
--- /dev/null
+++ b/corte/google.js
@@ -0,0 +1,76 @@
+'use strict';
+/* Adaptador REST das APIs do Google, sem decisão nenhuma. `cliente` é o GoogleAuth da
+   google-auth-library (nos testes, um falso): request({ url, method, data, ... }). */
+const { estadoNormal } = require('./regra.js');
+
+const SERVICO = 'firestore.googleapis.com';
+const TEMPO_LIMITE_MS = 30000;
+
+/* Outra execução regravou o estado entre a leitura e a gravação (HTTP 412). */
+class ConflitoDeEstado extends Error {}
+
+const statusDe = erro => (erro && erro.response ? erro.response.status : undefined);
+
+function criarGoogle({ cliente, projeto, bucket, objeto = 'estado.json' }){
+  const urlApi = `https://serviceusage.googleapis.com/v1/projects/${projeto}/services/${SERVICO}`;
+  const urlCobranca = `https://cloudbilling.googleapis.com/v1/projects/${projeto}/billingInfo`;
+  const urlObjeto = `https://storage.googleapis.com/storage/v1/b/${bucket}/o/${encodeURIComponent(objeto)}`;
+  const urlUpload = `https://storage.googleapis.com/upload/storage/v1/b/${bucket}/o?uploadType=media&name=${encodeURIComponent(objeto)}&ifGenerationMatch=`;
+  const pedir = opcoes => cliente.request({ timeout: TEMPO_LIMITE_MS, ...opcoes });
+
+  /* A geração vem antes do conteúdo: se o objeto mudar entre as duas leituras, a gravação
+     condicionada recusa (412). Na ordem inversa, gravaria por cima de conteúdo que não leu. */
+  async function lerEstado(){
+    let meta;
+    try{
+      meta = await pedir({ url: `${urlObjeto}?fields=generation` });
+    }catch(e){
+      if(statusDe(e) === 404) return { estado: estadoNormal(null), geracao: '0' };
+      throw e;
+    }
+    const conteudo = await pedir({ url: `${urlObjeto}?alt=media`, responseType: 'text' });
+    return { estado: estadoNormal(JSON.parse(conteudo.data)), geracao: meta.data.generation };
+  }
+
+  async function gravarEstado(estado, geracao){
+    try{
+      await pedir({ url: urlUpload + geracao, method: 'POST', headers: { 'Content-Type': 'application/json' }, data: JSON.stringify(estado) });
+    }catch(e){
+      if(statusDe(e) === 412) throw new ConflitoDeEstado('estado.json mudou durante a gravação');
+      throw e;
+    }
+  }
+
+  return {
+    async estadoDaApi(){
+      return (await pedir({ url: urlApi })).data.state;
+    },
+    /* O Operation devolvido não interessa: quem prova o desligamento é o services.get. */
+    async desligarApi(){
+      await pedir({ url: `${urlApi}:disable`, method: 'POST', data: { disableDependentServices: false, checkIfServiceHasUsage: 'SKIP' } });
+    },
+    async cobrancaLigada(){
+      return (await pedir({ url: urlCobranca })).data.billingEnabled === true;
+    },
+    async tirarCobranca(){
+      await pedir({ url: urlCobranca, method: 'PUT', data: { billingAccountName: '' } });
+    },
+    /* Ler, transformar e regravar com ifGenerationMatch; conflito tenta uma vez de novo.
+       transformar devolve o mesmo objeto quando não há o que regravar. */
+    async atualizarEstado(transformar){
+      for(let tentativa = 1; ; tentativa++){
+        const { estado, geracao } = await lerEstado();
+        const novo = transformar(estado);
+        if(novo === estado) return estado;
+        try{
+          await gravarEstado(novo, geracao);
+          return novo;
+        }catch(e){
+          if(!(e instanceof ConflitoDeEstado) || tentativa >= 2) throw e;
+        }
+      }
+    },
+  };
+}
+
+module.exports = { criarGoogle, ConflitoDeEstado };
diff --git a/tests/corte.test.cjs b/tests/corte.test.cjs
index ed3a03d..d2b5612 100644
--- a/tests/corte.test.cjs
+++ b/tests/corte.test.cjs
@@ -147,3 +147,147 @@ test('regra: o que fica registrado do estado real', ()=>{
   assert.equal(regra.registrarApiDesligada(desligada, depois).apiDesligadaEm, agora, 'vale a primeira vez');
   assert.equal(regra.registrarCobrancaTirada(base, agora).cobrancaTiradaEm, agora);
 });
+
+const { criarGoogle, ConflitoDeEstado } = require('../corte/google.js');
+
+class ErroHttp extends Error {
+  constructor(status){ super(`HTTP ${status}`); this.response = { status }; }
+}
+
+const URL_API = 'https://serviceusage.googleapis.com/v1/projects/alvo/services/firestore.googleapis.com';
+const URL_COBRANCA = 'https://cloudbilling.googleapis.com/v1/projects/alvo/billingInfo';
+const URL_OBJETO = 'https://storage.googleapis.com/storage/v1/b/estado-teste/o/estado.json';
+const URL_UPLOAD = 'https://storage.googleapis.com/upload/storage/v1/b/estado-teste/o?uploadType=media&name=estado.json&ifGenerationMatch=';
+
+/* O Google inteiro num objeto: URL errada estoura, e falhar[rótulo] injeta erro uma vez por item. */
+function googleFalso({ api = 'ENABLED', cobranca = true, estado = null } = {}){
+  const g = { api, cobranca, estado, geracao: estado ? 5 : 0, chamadas: [], falhar: {}, enviados: [], leiturasAteDesligar: 0 };
+  const talvezFalhe = rotulo => { const f = g.falhar[rotulo]; if(f && f.length) throw f.shift(); };
+  g.cliente = { async request(o){
+    const metodo = o.method || 'GET';
+    let rotulo;
+    if(metodo === 'GET' && o.url === URL_API) rotulo = 'api-ler';
+    else if(metodo === 'POST' && o.url === `${URL_API}:disable`) rotulo = 'api-desligar';
+    else if(metodo === 'GET' && o.url === URL_COBRANCA) rotulo = 'cobranca-ler';
+    else if(metodo === 'PUT' && o.url === URL_COBRANCA) rotulo = 'cobranca-tirar';
+    else if(metodo === 'GET' && o.url === `${URL_OBJETO}?fields=generation`) rotulo = 'estado-meta';
+    else if(metodo === 'GET' && o.url === `${URL_OBJETO}?alt=media`) rotulo = 'estado-ler';
+    else if(metodo === 'POST' && o.url.startsWith(URL_UPLOAD)) rotulo = 'estado-gravar';
+    else throw new Error(`rota inesperada: ${metodo} ${o.url}`);
+    g.chamadas.push(rotulo);
+    talvezFalhe(rotulo);
+    if(rotulo === 'api-ler'){
+      if(g.leiturasAteDesligar > 0 && --g.leiturasAteDesligar === 0) g.api = 'DISABLED';
+      return { status: 200, data: { name: 'projects/1/services/firestore.googleapis.com', state: g.api } };
+    }
+    if(rotulo === 'api-desligar'){
+      assert.deepEqual(o.data, { disableDependentServices: false, checkIfServiceHasUsage: 'SKIP' });
+      if(g.demoraDesligar) g.leiturasAteDesligar = g.demoraDesligar; else g.api = 'DISABLED';
+      return { status: 200, data: { name: 'operations/x' } };
+    }
+    if(rotulo === 'cobranca-ler') return { status: 200, data: g.cobranca ? { billingEnabled: true, billingAccountName: 'billingAccounts/1' } : { billingAccountName: '' } };
+    if(rotulo === 'cobranca-tirar'){
+      assert.deepEqual(o.data, { billingAccountName: '' });
+      g.cobranca = false;
+      return { status: 200, data: { billingAccountName: '' } };
+    }
+    if(rotulo === 'estado-meta'){
+      if(!g.estado) throw new ErroHttp(404);
+      return { status: 200, data: { generation: String(g.geracao) } };
+    }
+    if(rotulo === 'estado-ler') return { status: 200, data: JSON.stringify(g.estado) };
+    const esperada = o.url.slice(URL_UPLOAD.length);
+    if(esperada !== String(g.geracao)) throw new ErroHttp(412);
+    assert.equal(o.headers['Content-Type'], 'application/json');
+    g.estado = JSON.parse(o.data);
+    g.enviados.push(g.estado);
+    g.geracao += 1;
+    return { status: 200, data: { generation: String(g.geracao) } };
+  } };
+  g.adaptador = () => criarGoogle({ cliente: g.cliente, projeto: 'alvo', bucket: 'estado-teste' });
+  return g;
+}
+
+test('google: estado da API vem do services.get', async ()=>{
+  const g = googleFalso({ api: 'DISABLED' });
+  assert.equal(await g.adaptador().estadoDaApi(), 'DISABLED');
+  assert.deepEqual(g.chamadas, ['api-ler']);
+});
+
+test('google: desligar pede services.disable sem derrubar dependente e sem checar uso', async ()=>{
+  const g = googleFalso();
+  await g.adaptador().desligarApi();
+  assert.deepEqual(g.chamadas, ['api-desligar']);
+});
+
+test('google: erro da API chega ao chamador com o status', async ()=>{
+  const g = googleFalso();
+  g.falhar['api-desligar'] = [new ErroHttp(400)];
+  await assert.rejects(g.adaptador().desligarApi(), e => e.response.status === 400);
+});
+
+test('google: cobrança ligada só com billingEnabled verdadeiro', async ()=>{
+  assert.equal(await googleFalso({ cobranca: true }).adaptador().cobrancaLigada(), true);
+  assert.equal(await googleFalso({ cobranca: false }).adaptador().cobrancaLigada(), false, 'campo ausente na resposta é falso');
+});
+
+test('google: tirar a cobrança manda billingAccountName vazio', async ()=>{
+  const g = googleFalso();
+  await g.adaptador().tirarCobranca();
+  assert.deepEqual(g.chamadas, ['cobranca-tirar']);
+  assert.equal(g.cobranca, false);
+});
+
+test('google: sem estado no bucket começa vazio e cria com ifGenerationMatch=0', async ()=>{
+  const g = googleFalso();
+  const r = await g.adaptador().atualizarEstado(e => ({ ...e, primeiraFalha: 'x' }));
+  assert.equal(r.primeiraFalha, 'x');
+  assert.deepEqual(g.chamadas, ['estado-meta', 'estado-gravar']);
+  assert.deepEqual(g.estado.orcamentos, {});
+});
+
+test('google: atualizar lê a geração antes do conteúdo e regrava com ela', async ()=>{
+  const g = googleFalso({ estado: { primeiraFalha: 'a' } });
+  const r = await g.adaptador().atualizarEstado(e => ({ ...e, apiDesligadaEm: 'b' }));
+  assert.deepEqual(g.chamadas, ['estado-meta', 'estado-ler', 'estado-gravar']);
+  assert.equal(r.primeiraFalha, 'a');
+  assert.equal(g.estado.apiDesligadaEm, 'b');
+  assert.equal(g.geracao, 6);
+});
+
+test('google: transformar sem mudança não regrava', async ()=>{
+  const g = googleFalso({ estado: { primeiraFalha: 'a' } });
+  await g.adaptador().atualizarEstado(e => e);
+  assert.deepEqual(g.chamadas, ['estado-meta', 'estado-ler']);
+});
+
+test('google: conflito na gravação tenta uma vez de novo, sobre o estado relido', async ()=>{
+  const g = googleFalso({ estado: { primeiraFalha: 'a' } });
+  g.falhar['estado-gravar'] = [new ErroHttp(412)];
+  const vistos = [];
+  await g.adaptador().atualizarEstado(e => { vistos.push(e.primeiraFalha); return { ...e, apiDesligadaEm: 'b' }; });
+  assert.deepEqual(g.chamadas, ['estado-meta', 'estado-ler', 'estado-gravar', 'estado-meta', 'estado-ler', 'estado-gravar']);
+  assert.equal(vistos.length, 2);
+  assert.equal(g.estado.apiDesligadaEm, 'b');
+});
+
+test('google: segundo conflito seguido desiste com ConflitoDeEstado', async ()=>{
+  const g = googleFalso({ estado: { primeiraFalha: 'a' } });
+  g.falhar['estado-gravar'] = [new ErroHttp(412), new ErroHttp(412)];
+  await assert.rejects(g.adaptador().atualizarEstado(e => ({ ...e, apiDesligadaEm: 'b' })), ConflitoDeEstado);
+  assert.equal(g.chamadas.filter(c => c === 'estado-gravar').length, 2);
+});
+
+test('google: falha ao ler o estado chega ao chamador, sem virar estado vazio', async ()=>{
+  const g = googleFalso({ estado: { primeiraFalha: 'a' } });
+  g.falhar['estado-meta'] = [new ErroHttp(503)];
+  await assert.rejects(g.adaptador().atualizarEstado(e => ({ ...e, apiDesligadaEm: 'b' })), e => e.response.status === 503);
+  assert.deepEqual(g.chamadas, ['estado-meta']);
+});
+
+test('google: erro na gravação que não é conflito não repete', async ()=>{
+  const g = googleFalso({ estado: { primeiraFalha: 'a' } });
+  g.falhar['estado-gravar'] = [new ErroHttp(500)];
+  await assert.rejects(g.adaptador().atualizarEstado(e => ({ ...e, apiDesligadaEm: 'b' })), e => e.response.status === 500);
+  assert.equal(g.chamadas.filter(c => c === 'estado-gravar').length, 1);
+});
````

- [ ] **Verificar**

````bash
npm run test:unit
````

- [ ] **Commit**

````bash
git add corte/google.js tests/corte.test.cjs
git commit -F - <<'FIM'
feat: adaptador das APIs do Google para o corte

Service Usage, Cloud Billing e Cloud Storage por REST, sem decisão
nenhuma: quem decide é a regra e quem prova o desligamento é o
services.get. O estado em estado.json lê a geração antes do conteúdo e
regrava com ifGenerationMatch, para uma gravação concorrente virar
conflito em vez de sobrescrever; conflito tenta uma vez de novo. Falha
ao ler o estado sobe ao chamador e nunca vira estado vazio.
FIM
````

### Tarefa 4: feat: função do corte ligada ao Pub/Sub

**Arquivos:** `corte/index.js` (novo), `corte/regra.js`, `tests/corte.test.cjs`

As mutações que importam, todas mortas no protótipo (41 de 41): `>=` para `>` em cada limiar; cortar sem as 6 h; ignorar cada `ARMADO_*`; confiar no código de erro em vez de `services.get`.

- [ ] **Aplicar**

````diff
diff --git a/corte/index.js b/corte/index.js
new file mode 100644
index 0000000..fa43025
--- /dev/null
+++ b/corte/index.js
@@ -0,0 +1,191 @@
+'use strict';
+/* Corte de gastos do Custta (Blindagem 4): Cloud Run function em projeto próprio que recebe do
+   Pub/Sub os orçamentos e o alerta de leituras e age sobre o projeto de produção. A decisão é de
+   regra.js; quem fala com o Google é google.js. Aqui só a ordem das coisas. */
+const regra = require('./regra.js');
+
+const FRAMEWORK = '@google-cloud/functions-framework';
+const VOLTAS_CONFIRMA = 6;
+const ESPERA_CONFIRMA_MS = 10000;
+
+/* Dependências de corte/ só carregam quando a função roda: o teste da raiz não as instala. */
+function carregarPadrao(env){
+  const { GoogleAuth } = require('google-auth-library');
+  const { criarGoogle } = require('./google.js');
+  const cliente = new GoogleAuth({ scopes: ['https://www.googleapis.com/auth/cloud-platform'] });
+  return criarGoogle({ cliente, projeto: env.PROJETO_ALVO, bucket: env.BUCKET_ESTADO });
+}
+
+function criarManipulador({
+  carregar = carregarPadrao, env = process.env, agora = () => new Date(),
+  escrever = linha => console.log(linha), esperar = ms => new Promise(r => setTimeout(r, ms)),
+} = {}){
+  const config = {
+    armadoApi: env.ARMADO_API === 'true',
+    armadoCobranca: env.ARMADO_COBRANCA === 'true',
+    orcamentoProjeto: env.ORCAMENTO_PROJETO,
+    orcamentoFora: env.ORCAMENTO_FORA_FIRESTORE,
+    politica: env.POLITICA_ALERTA,
+  };
+  let memo = null;
+  const google = () => (memo = memo || carregar(env));
+  const logar = (severity, marca, message, extra) => escrever(JSON.stringify({ severity, message, marca, ...extra }));
+  const acao = (message, extra) => logar('ALERT', 'corte-acao', message, extra);
+
+  /* Depois do erro basta uma leitura: o pedido não foi aceito, nada vai mudar. Depois do sucesso,
+     dá tempo à operação. Sem nenhuma leitura boa não há prova de nada: relança sem contar falha. */
+  async function confirmarDesligada(voltas){
+    let erroLeitura = null, viuLigada = false;
+    for(let i = 0; i < voltas; i++){
+      if(i > 0) await esperar(ESPERA_CONFIRMA_MS);
+      try{
+        if(await google().estadoDaApi() === 'DISABLED') return true;
+        viuLigada = true;
+      }catch(e){
+        erroLeitura = e;
+      }
+    }
+    if(!viuLigada) throw erroLeitura;
+    return false;
+  }
+
+  /* O estado.json só é tocado depois do Google, para o bucket fora do ar não segurar o alerta. */
+  async function desligarApi(contexto, iso){
+    const g = google();
+    if(await g.estadoDaApi() === 'DISABLED'){
+      await g.atualizarEstado(e => regra.registrarApiDesligada(e, iso));
+      return { fez: 'API já estava desligada' };
+    }
+    if(!config.armadoApi){
+      acao('faria desligar a API do Firestore (ARMADO_API=false)', { acao: 'faria-desligar-api', ...contexto });
+      return { fez: 'faria desligar a API' };
+    }
+    let erroDesligar = null;
+    try{
+      await g.desligarApi();
+    }catch(e){
+      erroDesligar = e;
+    }
+    /* Vale o estado real, nunca o código de erro: FAILED_PRECONDITION tanto pode ser "já desligada"
+       quanto "tem serviço dependente". */
+    if(await confirmarDesligada(erroDesligar ? 1 : VOLTAS_CONFIRMA)){
+      await g.atualizarEstado(e => regra.registrarApiDesligada(e, iso));
+      acao('API do Firestore desligada', { acao: 'desligar-api', ...contexto });
+      return { fez: 'desligou a API' };
+    }
+    const estado = await g.atualizarEstado(e => regra.registrarFalha(e, iso));
+    return {
+      fez: 'não conseguiu desligar a API', falhou: true, estado,
+      erro: erroDesligar || new Error('a API do Firestore continuou ligada depois do pedido de desligar'),
+    };
+  }
+
+  /* resolvido: a produção parou de gastar, nada a repetir. */
+  async function tirarCobranca(contexto, iso, motivo){
+    const g = google();
+    if(!await g.cobrancaLigada()){
+      await g.atualizarEstado(e => regra.registrarCobrancaTirada(e, iso));
+      return { fez: 'cobrança já estava tirada', resolvido: true };
+    }
+    if(!config.armadoCobranca){
+      acao(`faria tirar a cobrança do projeto (ARMADO_COBRANCA=false): ${motivo}`, { acao: 'faria-tirar-cobranca', ...contexto });
+      return { fez: 'faria tirar a cobrança', resolvido: false };
+    }
+    await g.tirarCobranca();
+    await g.atualizarEstado(e => regra.registrarCobrancaTirada(e, iso));
+    acao(`cobrança do projeto tirada: ${motivo}`, { acao: 'tirar-cobranca', ...contexto });
+    return { fez: 'tirou a cobrança', resolvido: true };
+  }
+
+  async function tratarOrcamento(msg, passagem, instante){
+    passagem.orcamento = msg.nome;
+    const papel = regra.papelDoOrcamento(msg.nome, config);
+    if(!papel){
+      passagem.fez = 'ignorou orçamento desconhecido';
+      logar('ERROR', 'corte-erro', `orçamento desconhecido: ${msg.nome}`, { orcamento: msg.nome });
+      return;
+    }
+    if(msg.moeda !== 'BRL'){
+      passagem.fez = 'só alarme: moeda diferente de BRL';
+      logar('ALERT', 'corte-erro', `moeda diferente de BRL: ${msg.moeda}`, { orcamento: msg.nome, moeda: msg.moeda });
+      return;
+    }
+    /* maiorCusto grava antes de agir: se a ação falhar, o religar ainda enxerga o custo. */
+    let aplicado;
+    await google().atualizarEstado(e => {
+      aplicado = regra.aplicarOrcamento(e, msg, papel);
+      return aplicado.estado;
+    });
+    if(aplicado.velha){
+      passagem.fez = 'ignorou mês velho';
+      return;
+    }
+    passagem.custo = aplicado.custoCentavos / 100;
+    const contexto = { orcamento: msg.nome, custo: passagem.custo };
+    const decisao = regra.decidirOrcamento(papel, aplicado.custoCentavos);
+    if(decisao === 'nada') return;
+    if(decisao === 'tirar-cobranca'){
+      passagem.fez = (await tirarCobranca(contexto, instante.toISOString(), 'gasto fora do Firestore passou de R$ 100')).fez;
+      return;
+    }
+    const r = await desligarApi(contexto, instante.toISOString());
+    passagem.fez = r.fez;
+    if(!r.falhou) return;
+    if(regra.deveTirarCobrancaPorFalha(aplicado.custoCentavos, r.estado.primeiraFalha, instante.getTime())){
+      const corte = await tirarCobranca(contexto, instante.toISOString(), 'a API não desligou em 6 horas de falha');
+      passagem.fez = corte.fez;
+      if(corte.resolvido) return;
+    }
+    throw r.erro;
+  }
+
+  async function tratarIncidente(msg, passagem, instante){
+    passagem.politica = msg.politica;
+    if(msg.estado !== 'open' || msg.politica !== config.politica) return;
+    const r = await desligarApi({ politica: msg.politica }, instante.toISOString());
+    passagem.fez = r.fez;
+    if(r.falhou) throw r.erro;
+  }
+
+  return async function receber(evento){
+    const passagem = { tipo: 'ilegivel', orcamento: null, custo: null, fez: 'nada' };
+    try{
+      let msg;
+      try{
+        msg = regra.interpretar(evento);
+      }catch(e){
+        if(!(e instanceof regra.MensagemIlegivel)) throw e;
+        passagem.fez = 'ignorou mensagem ilegível';
+        logar('ERROR', 'corte-erro', `mensagem ilegível: ${e.message}`, {});
+        return;
+      }
+      passagem.tipo = msg.tipo;
+      if(msg.tipo === 'incidente') await tratarIncidente(msg, passagem, agora());
+      else await tratarOrcamento(msg, passagem, agora());
+    }catch(e){
+      /* Só a mensagem: o erro da biblioteca carrega a configuração do pedido, com o token. */
+      logar('ERROR', 'corte-erro', `falha no corte: ${e.message}`, { orcamento: passagem.orcamento, custo: passagem.custo, fez: passagem.fez });
+      throw e;
+    }finally{
+      logar('INFO', 'corte-passagem', 'mensagem recebida', passagem);
+    }
+  };
+}
+
+function registrarFuncao(framework, env = process.env){
+  framework.cloudEvent('receber', criarManipulador({ env }));
+}
+
+/* Quem carrega este arquivo em produção é o próprio Functions Framework, que então existe.
+   Sem ele instalado (teste da raiz), não há onde registrar. */
+function frameworkInstalado(){
+  try{
+    require.resolve(FRAMEWORK);
+    return true;
+  }catch{
+    return false;
+  }
+}
+if(frameworkInstalado()) registrarFuncao(require(FRAMEWORK));
+
+module.exports = { criarManipulador, registrarFuncao, carregarPadrao };
diff --git a/corte/regra.js b/corte/regra.js
index 66ca9d5..a91349b 100644
--- a/corte/regra.js
+++ b/corte/regra.js
@@ -88,17 +88,19 @@ function deveTirarCobrancaPorFalha(custoCentavos, primeiraFalha, agoraMs){
   return custoCentavos >= LIMITE_COBRANCA && Boolean(primeiraFalha) && agoraMs - Date.parse(primeiraFalha) >= ESPERA_FALHA_MS;
 }
 
+/* Os três registros devolvem o mesmo objeto quando nada muda: não há o que regravar. */
 function registrarFalha(estado, agora){
-  return { ...estado, primeiraFalha: estado.primeiraFalha || agora };
+  return estado.primeiraFalha ? estado : { ...estado, primeiraFalha: agora };
 }
 
 /* API confirmada desligada encerra a falha: a contagem só anda enquanto o estado real é ligada. */
 function registrarApiDesligada(estado, agora){
+  if(estado.apiDesligadaEm && !estado.primeiraFalha) return estado;
   return { ...estado, apiDesligadaEm: estado.apiDesligadaEm || agora, primeiraFalha: null };
 }
 
 function registrarCobrancaTirada(estado, agora){
-  return { ...estado, cobrancaTiradaEm: estado.cobrancaTiradaEm || agora };
+  return estado.cobrancaTiradaEm ? estado : { ...estado, cobrancaTiradaEm: agora };
 }
 
 module.exports = {
diff --git a/tests/corte.test.cjs b/tests/corte.test.cjs
index d2b5612..67a9b3a 100644
--- a/tests/corte.test.cjs
+++ b/tests/corte.test.cjs
@@ -146,6 +146,10 @@ test('regra: o que fica registrado do estado real', ()=>{
   assert.equal(desligada.primeiraFalha, null, 'API confirmada desligada encerra a falha');
   assert.equal(regra.registrarApiDesligada(desligada, depois).apiDesligadaEm, agora, 'vale a primeira vez');
   assert.equal(regra.registrarCobrancaTirada(base, agora).cobrancaTiradaEm, agora);
+  const tirada = regra.registrarCobrancaTirada(base, agora);
+  assert.equal(regra.registrarFalha(falhou, depois), falhou, 'sem mudança, nada a regravar');
+  assert.equal(regra.registrarApiDesligada(desligada, depois), desligada);
+  assert.equal(regra.registrarCobrancaTirada(tirada, depois), tirada);
 });
 
 const { criarGoogle, ConflitoDeEstado } = require('../corte/google.js');
@@ -291,3 +295,422 @@ test('google: erro na gravação que não é conflito não repete', async ()=>{
   await assert.rejects(g.adaptador().atualizarEstado(e => ({ ...e, apiDesligadaEm: 'b' })), e => e.response.status === 500);
   assert.equal(g.chamadas.filter(c => c === 'estado-gravar').length, 1);
 });
+
+const { criarManipulador, registrarFuncao } = require('../corte/index.js');
+
+const T0 = '2026-11-09T12:00:00.000Z';
+const mais = (iso, ms) => new Date(Date.parse(iso) + ms).toISOString();
+const SEIS_HORAS = 6 * 60 * 60 * 1000;
+const ENV = { ARMADO_API: 'true', ARMADO_COBRANCA: 'true', ORCAMENTO_PROJETO: 'projeto', ORCAMENTO_FORA_FIRESTORE: 'fora',
+  POLITICA_ALERTA: 'leituras', PROJETO_ALVO: 'alvo', BUCKET_ESTADO: 'estado-teste' };
+const incidente = (politica, estado) => ({ version: '1.2', incident: { incident_id: 'i', policy_name: politica, state: estado } });
+const foraDe = custo => msgOrcamento(custo, { budgetDisplayName: 'fora' });
+const semEstado = chamadas => chamadas.filter(c => !c.startsWith('estado-'));
+
+async function rodar(g, corpo, { env = {}, agora = T0, evento } = {}){
+  const linhas = [];
+  const receber = criarManipulador({
+    carregar: () => g.adaptador(), env: { ...ENV, ...env }, agora: () => new Date(agora),
+    escrever: l => linhas.push(JSON.parse(l)), esperar: async () => {},
+  });
+  let erro = null;
+  try{ await receber(evento || eventoDe(corpo)); }catch(e){ erro = e; }
+  return { erro, linhas, de: m => linhas.filter(l => l.marca === m) };
+}
+function passagemUnica(r){
+  assert.equal(r.de('corte-passagem').length, 1, 'uma passagem por mensagem');
+  return r.de('corte-passagem')[0];
+}
+const estadoCom = (orcamentos, resto = {}) => ({ orcamentos, primeiraFalha: null, apiDesligadaEm: null, cobrancaTiradaEm: null, ...resto });
+const noMes = (maiorCusto, base = 0, intervalo = '2026-11') => ({ intervalo, base, maiorCusto });
+
+test('cenário 1: 59,99 não faz nada e registra a passagem', async ()=>{
+  const g = googleFalso();
+  const r = await rodar(g, msgOrcamento(59.99));
+  assert.equal(r.erro, null);
+  assert.deepEqual(semEstado(g.chamadas), []);
+  const p = passagemUnica(r);
+  assert.equal(p.severity, 'INFO'); assert.equal(p.custo, 59.99); assert.equal(p.orcamento, 'projeto'); assert.equal(p.fez, 'nada'); assert.ok(p.message);
+  assert.deepEqual(r.de('corte-acao'), []);
+  assert.equal(g.estado.orcamentos.projeto.maiorCusto, 59.99);
+});
+
+test('cenário 2: 60,00 desliga a API e confere pelo services.get', async ()=>{
+  const g = googleFalso();
+  const r = await rodar(g, msgOrcamento(60));
+  assert.equal(r.erro, null);
+  assert.deepEqual(semEstado(g.chamadas), ['api-ler', 'api-desligar', 'api-ler']);
+  const [a] = r.de('corte-acao');
+  assert.equal(a.severity, 'ALERT'); assert.equal(a.custo, 60); assert.equal(a.orcamento, 'projeto'); assert.equal(a.acao, 'desligar-api');
+  assert.equal(g.estado.apiDesligadaEm, T0);
+  assert.equal(passagemUnica(r).fez, 'desligou a API');
+});
+
+test('cenário 3: repetida com a API já desligada não chama disable nem regrava', async ()=>{
+  const g = googleFalso({ api: 'DISABLED', estado: estadoCom({ projeto: noMes(60) }, { apiDesligadaEm: T0 }) });
+  const r = await rodar(g, msgOrcamento(60));
+  assert.equal(r.erro, null);
+  assert.deepEqual(semEstado(g.chamadas), ['api-ler']);
+  assert.ok(!g.chamadas.includes('estado-gravar'));
+  assert.deepEqual(r.de('corte-acao'), []);
+  assert.equal(passagemUnica(r).fez, 'API já estava desligada');
+});
+
+test('cenário 4: 40 depois de 61 não muda o maiorCusto nem faz nada', async ()=>{
+  const g = googleFalso({ estado: estadoCom({ projeto: noMes(61) }) });
+  const r = await rodar(g, msgOrcamento(40));
+  assert.equal(r.erro, null);
+  assert.deepEqual(g.chamadas, ['estado-meta', 'estado-ler']);
+  assert.equal(g.estado.orcamentos.projeto.maiorCusto, 61);
+  assert.equal(passagemUnica(r).custo, 40);
+});
+
+test('cenário 5: primeira mensagem em 300 desliga a API e, confirmada, não tira a cobrança', async ()=>{
+  const g = googleFalso();
+  const r = await rodar(g, msgOrcamento(300));
+  assert.equal(r.erro, null);
+  assert.deepEqual(semEstado(g.chamadas), ['api-ler', 'api-desligar', 'api-ler']);
+  assert.equal(g.cobranca, true);
+  assert.equal(g.estado.cobrancaTiradaEm, null);
+});
+
+test('cenário 6: 120 com a API desligada não toca na cobrança', async ()=>{
+  const g = googleFalso({ api: 'DISABLED' });
+  const r = await rodar(g, msgOrcamento(120));
+  assert.equal(r.erro, null);
+  assert.deepEqual(semEstado(g.chamadas), ['api-ler']);
+});
+
+test('cenário 7: disable falha com custo de 100 ou mais: grava a primeira falha, relança e não corta', async ()=>{
+  const erro = new ErroHttp(403);
+  const g = googleFalso();
+  g.falhar['api-desligar'] = [erro];
+  const r = await rodar(g, msgOrcamento(120));
+  assert.equal(r.erro, erro);
+  assert.equal(g.estado.primeiraFalha, T0);
+  assert.deepEqual(semEstado(g.chamadas), ['api-ler', 'api-desligar', 'api-ler']);
+  assert.equal(r.de('corte-erro').length, 1);
+  assert.equal(r.de('corte-erro')[0].custo, 120);
+  passagemUnica(r);
+});
+
+test('cenário 7: falha com menos de 6 horas ainda não corta', async ()=>{
+  const g = googleFalso({ estado: estadoCom({ projeto: noMes(120) }, { primeiraFalha: T0 }) });
+  g.falhar['api-desligar'] = [new ErroHttp(403)];
+  const r = await rodar(g, msgOrcamento(120), { agora: mais(T0, SEIS_HORAS - 1) });
+  assert.ok(r.erro);
+  assert.ok(!g.chamadas.some(c => c.startsWith('cobranca-')));
+  assert.equal(g.estado.primeiraFalha, T0, 'a contagem não recomeça');
+});
+
+test('cenário 7: falha que persiste 6 horas tira a cobrança e não relança', async ()=>{
+  const g = googleFalso({ estado: estadoCom({ projeto: noMes(120) }, { primeiraFalha: T0 }) });
+  g.falhar['api-desligar'] = [new ErroHttp(403)];
+  const agora = mais(T0, SEIS_HORAS);
+  const r = await rodar(g, msgOrcamento(120), { agora });
+  assert.equal(r.erro, null);
+  assert.deepEqual(semEstado(g.chamadas), ['api-ler', 'api-desligar', 'api-ler', 'cobranca-ler', 'cobranca-tirar']);
+  assert.equal(g.estado.cobrancaTiradaEm, agora);
+  assert.equal(r.de('corte-acao')[0].acao, 'tirar-cobranca');
+  assert.equal(passagemUnica(r).fez, 'tirou a cobrança');
+});
+
+test('cenário 7: com ARMADO_COBRANCA=false, 6 horas de falha só dizem que faria, e relança', async ()=>{
+  const g = googleFalso({ estado: estadoCom({ projeto: noMes(120) }, { primeiraFalha: T0 }) });
+  g.falhar['api-desligar'] = [new ErroHttp(403)];
+  const r = await rodar(g, msgOrcamento(120), { agora: mais(T0, SEIS_HORAS), env: { ARMADO_COBRANCA: 'false' } });
+  assert.ok(r.erro);
+  assert.deepEqual(semEstado(g.chamadas), ['api-ler', 'api-desligar', 'api-ler', 'cobranca-ler']);
+  assert.match(r.de('corte-acao')[0].message, /faria/);
+});
+
+test('cenário 7: 99,99 com falha antiga não corta', async ()=>{
+  const g = googleFalso({ estado: estadoCom({ projeto: noMes(99.99) }, { primeiraFalha: T0 }) });
+  g.falhar['api-desligar'] = [new ErroHttp(403)];
+  const r = await rodar(g, msgOrcamento(99.99), { agora: mais(T0, 3 * SEIS_HORAS) });
+  assert.ok(r.erro);
+  assert.ok(!g.chamadas.some(c => c.startsWith('cobranca-')));
+});
+
+test('estado real: FAILED_PRECONDITION com a API ligada é falha, não sucesso', async ()=>{
+  const g = googleFalso();
+  g.falhar['api-desligar'] = [new ErroHttp(400)];
+  const r = await rodar(g, msgOrcamento(60));
+  assert.ok(r.erro);
+  assert.equal(g.estado.primeiraFalha, T0);
+  assert.equal(g.estado.apiDesligadaEm, null);
+});
+
+test('estado real: disable com erro e services.get DISABLED não é falha', async ()=>{
+  const g = googleFalso();
+  g.falhar['api-desligar'] = [new ErroHttp(403)];
+  const original = g.cliente.request;
+  g.cliente.request = async o => {
+    try{ return await original(o); }
+    catch(e){ if(o.url.endsWith(':disable')) g.api = 'DISABLED'; throw e; }
+  };
+  const r = await rodar(g, msgOrcamento(120));
+  assert.equal(r.erro, null);
+  assert.equal(g.estado.primeiraFalha, null);
+  assert.equal(g.estado.apiDesligadaEm, T0);
+});
+
+test('estado real: disable sem erro, mas a API continua ligada, conta como falha', async ()=>{
+  const g = googleFalso();
+  g.demoraDesligar = 1000;
+  const r = await rodar(g, msgOrcamento(60));
+  assert.ok(r.erro);
+  assert.equal(g.estado.primeiraFalha, T0);
+  assert.equal(g.chamadas.filter(c => c === 'api-ler').length, 7, 'uma leitura antes e seis de confirmação');
+});
+
+test('estado real: desligamento que demora é confirmado sem registrar falha', async ()=>{
+  const g = googleFalso();
+  g.demoraDesligar = 3;
+  const r = await rodar(g, msgOrcamento(60));
+  assert.equal(r.erro, null);
+  assert.equal(g.estado.primeiraFalha, null);
+  assert.equal(g.estado.apiDesligadaEm, T0);
+});
+
+test('estado real: sem conseguir ler o services.get depois do erro não conta falha', async ()=>{
+  const g = googleFalso();
+  const erroDesligar = new ErroHttp(403), erroLer = new ErroHttp(503);
+  g.falhar['api-desligar'] = [erroDesligar];
+  const original = g.cliente.request;
+  let leituras = 0;
+  g.cliente.request = async o => {
+    if(o.url.endsWith('firestore.googleapis.com') && !o.method && ++leituras > 1) throw erroLer;
+    return original(o);
+  };
+  const r = await rodar(g, msgOrcamento(120));
+  assert.equal(r.erro, erroLer);
+  assert.equal(g.estado.primeiraFalha, null);
+});
+
+test('estado real: API confirmada desligada encerra a falha anterior', async ()=>{
+  const g = googleFalso({ api: 'DISABLED', estado: estadoCom({ projeto: noMes(120) }, { primeiraFalha: T0 }) });
+  const r = await rodar(g, msgOrcamento(120), { agora: mais(T0, 2 * SEIS_HORAS) });
+  assert.equal(r.erro, null);
+  assert.equal(g.estado.primeiraFalha, null);
+  assert.ok(!g.chamadas.some(c => c.startsWith('cobranca-')));
+});
+
+test('cenário 8: falha ao ler o estado com a API desligada relança e não corta', async ()=>{
+  const erro = new ErroHttp(503);
+  const g = googleFalso({ api: 'DISABLED', estado: estadoCom({ projeto: noMes(120) }, { primeiraFalha: T0 }) });
+  g.falhar['estado-meta'] = [erro];
+  const r = await rodar(g, msgOrcamento(300), { agora: mais(T0, 3 * SEIS_HORAS) });
+  assert.equal(r.erro, erro);
+  assert.deepEqual(semEstado(g.chamadas), []);
+  assert.equal(r.de('corte-erro').length, 1);
+  passagemUnica(r);
+});
+
+test('cenário 9: orçamento fora do Firestore em 99,99 não faz nada', async ()=>{
+  const g = googleFalso();
+  const r = await rodar(g, foraDe(99.99));
+  assert.equal(r.erro, null);
+  assert.deepEqual(semEstado(g.chamadas), []);
+  assert.equal(passagemUnica(r).orcamento, 'fora');
+});
+
+test('cenário 9: orçamento fora do Firestore em 100 tira a cobrança sem esperar e sem olhar a API', async ()=>{
+  const g = googleFalso();
+  const r = await rodar(g, foraDe(100));
+  assert.equal(r.erro, null);
+  assert.deepEqual(semEstado(g.chamadas), ['cobranca-ler', 'cobranca-tirar']);
+  assert.equal(g.estado.cobrancaTiradaEm, T0);
+  assert.equal(r.de('corte-acao')[0].acao, 'tirar-cobranca');
+});
+
+test('cenário 10: alerta open da política certa desliga a API, sem olhar custo', async ()=>{
+  const g = googleFalso();
+  const r = await rodar(g, incidente('leituras', 'open'));
+  assert.equal(r.erro, null);
+  assert.deepEqual(semEstado(g.chamadas), ['api-ler', 'api-desligar', 'api-ler']);
+  assert.equal(g.estado.apiDesligadaEm, T0);
+  assert.equal(r.de('corte-acao')[0].acao, 'desligar-api');
+  assert.equal(passagemUnica(r).tipo, 'incidente');
+});
+
+test('cenário 10: alerta closed ou de outra política não faz nada', async ()=>{
+  for(const corpo of [incidente('leituras', 'closed'), incidente('outra', 'open')]){
+    const g = googleFalso();
+    const r = await rodar(g, corpo);
+    assert.equal(r.erro, null);
+    assert.deepEqual(g.chamadas, [], JSON.stringify(corpo));
+    assert.equal(passagemUnica(r).fez, 'nada');
+  }
+});
+
+test('cenário 10: bucket fora do ar não segura o desligar do alerta', async ()=>{
+  const erro = new ErroHttp(503);
+  const g = googleFalso();
+  g.falhar['estado-meta'] = [erro];
+  const r = await rodar(g, incidente('leituras', 'open'));
+  assert.equal(r.erro, erro, 'relança para o Pub/Sub repetir e o registro entrar');
+  assert.deepEqual(semEstado(g.chamadas), ['api-ler', 'api-desligar', 'api-ler']);
+  assert.equal(g.api, 'DISABLED');
+});
+
+test('cenário 10: alerta com disable falhando registra a falha, relança e não corta', async ()=>{
+  const g = googleFalso({ estado: estadoCom({ projeto: noMes(500) }, { primeiraFalha: T0 }) });
+  g.falhar['api-desligar'] = [new ErroHttp(403)];
+  const r = await rodar(g, incidente('leituras', 'open'), { agora: mais(T0, 3 * SEIS_HORAS) });
+  assert.ok(r.erro);
+  assert.ok(!g.chamadas.some(c => c.startsWith('cobranca-')));
+});
+
+test('cenário 11: desarmado só registra que faria', async ()=>{
+  const env = { ARMADO_API: 'false', ARMADO_COBRANCA: 'false' };
+  const g1 = googleFalso();
+  const r1 = await rodar(g1, msgOrcamento(120), { env });
+  assert.equal(r1.erro, null);
+  assert.deepEqual(semEstado(g1.chamadas), ['api-ler']);
+  assert.match(r1.de('corte-acao')[0].message, /faria/);
+  assert.equal(r1.de('corte-acao')[0].severity, 'ALERT');
+  assert.equal(g1.estado.primeiraFalha, null, 'desarmado não tentou: não é falha');
+  assert.equal(passagemUnica(r1).fez, 'faria desligar a API');
+
+  const g2 = googleFalso();
+  const r2 = await rodar(g2, foraDe(100), { env });
+  assert.deepEqual(semEstado(g2.chamadas), ['cobranca-ler']);
+  assert.match(r2.de('corte-acao')[0].message, /faria/);
+
+  const g3 = googleFalso();
+  const r3 = await rodar(g3, incidente('leituras', 'open'), { env });
+  assert.deepEqual(semEstado(g3.chamadas), ['api-ler']);
+  assert.match(r3.de('corte-acao')[0].message, /faria/);
+});
+
+test('cenário 11: os dois interruptores são independentes', async ()=>{
+  const g1 = googleFalso();
+  await rodar(g1, foraDe(100), { env: { ARMADO_API: 'true', ARMADO_COBRANCA: 'false' } });
+  assert.ok(!g1.chamadas.includes('cobranca-tirar'));
+  const g2 = googleFalso();
+  await rodar(g2, msgOrcamento(60), { env: { ARMADO_API: 'true', ARMADO_COBRANCA: 'false' } });
+  assert.ok(g2.chamadas.includes('api-desligar'));
+  const g3 = googleFalso();
+  await rodar(g3, msgOrcamento(60), { env: { ARMADO_API: 'false', ARMADO_COBRANCA: 'true' } });
+  assert.ok(!g3.chamadas.includes('api-desligar'));
+  const g4 = googleFalso();
+  await rodar(g4, foraDe(100), { env: { ARMADO_API: 'false', ARMADO_COBRANCA: 'true' } });
+  assert.ok(g4.chamadas.includes('cobranca-tirar'));
+});
+
+test('cenário 11: só o texto exato true arma', async ()=>{
+  for(const valor of ['TRUE', '1', 'sim', '', undefined]){
+    const g = googleFalso();
+    const r = await rodar(g, msgOrcamento(120), { env: { ARMADO_API: valor } });
+    assert.ok(!g.chamadas.includes('api-desligar'), String(valor));
+    assert.match(r.de('corte-acao')[0].message, /faria/, String(valor));
+  }
+});
+
+test('cenário 12: mês novo zera base e maiorCusto; mensagem do mês velho é ignorada', async ()=>{
+  const g = googleFalso({ estado: estadoCom({ projeto: noMes(90, 70, '2026-10') }) });
+  const r1 = await rodar(g, msgOrcamento(65));
+  assert.equal(r1.erro, null);
+  assert.deepEqual(g.estado.orcamentos.projeto, { intervalo: '2026-11', base: 0, maiorCusto: 65 });
+  assert.ok(g.chamadas.includes('api-desligar'), 'sem a base de outubro, 65 passa de 60');
+
+  const h = googleFalso({ estado: estadoCom({ projeto: noMes(5) }) });
+  const r2 = await rodar(h, msgOrcamento(90, { costIntervalStart: '2026-10-01T07:00:00Z' }));
+  assert.equal(r2.erro, null);
+  assert.deepEqual(h.chamadas, ['estado-meta', 'estado-ler']);
+  assert.equal(h.estado.orcamentos.projeto.maiorCusto, 5);
+  assert.equal(passagemUnica(r2).fez, 'ignorou mês velho');
+});
+
+test('cenário 13: depois de religar, X + 59 não faz nada e X + 60 desliga de novo', async ()=>{
+  for(const base of [12.34, 4.07]){
+    const quase = googleFalso({ estado: estadoCom({ projeto: noMes(base, base) }) });
+    const r1 = await rodar(quase, msgOrcamento(Math.round((base + 59) * 100) / 100));
+    assert.equal(r1.erro, null);
+    assert.deepEqual(semEstado(quase.chamadas), [], `base ${base}`);
+    const passou = googleFalso({ estado: estadoCom({ projeto: noMes(base, base) }) });
+    const r2 = await rodar(passou, msgOrcamento(Math.round((base + 60) * 100) / 100));
+    assert.equal(r2.erro, null);
+    assert.ok(passou.chamadas.includes('api-desligar'), `base ${base}`);
+    assert.equal(r2.de('corte-acao')[0].custo, 60);
+  }
+});
+
+test('cenário 14: moeda diferente de BRL só dá alarme', async ()=>{
+  const g = googleFalso({ estado: estadoCom({ projeto: noMes(1) }) });
+  const r = await rodar(g, msgOrcamento(500, { currencyCode: 'USD' }));
+  assert.equal(r.erro, null);
+  assert.deepEqual(g.chamadas, []);
+  const [e] = r.de('corte-erro');
+  assert.equal(e.severity, 'ALERT');
+  assert.match(e.message, /moeda/);
+  assert.equal(g.estado.orcamentos.projeto.maiorCusto, 1);
+  passagemUnica(r);
+});
+
+test('cenário 15: mensagem ilegível registra erro e não relança', async ()=>{
+  for(const evento of [{ data: {} }, eventoDe('lixo'), eventoDe({ qualquer: 1 })]){
+    const g = googleFalso();
+    const r = await rodar(g, null, { evento });
+    assert.equal(r.erro, null);
+    assert.deepEqual(g.chamadas, []);
+    assert.equal(r.de('corte-erro').length, 1);
+    passagemUnica(r);
+  }
+});
+
+test('cenário 16: cobrança já tirada não chama update', async ()=>{
+  const g = googleFalso({ cobranca: false });
+  const r = await rodar(g, foraDe(150));
+  assert.equal(r.erro, null);
+  assert.deepEqual(semEstado(g.chamadas), ['cobranca-ler']);
+  assert.equal(g.estado.cobrancaTiradaEm, T0);
+  assert.deepEqual(r.de('corte-acao'), []);
+});
+
+test('cenário 16: falha de 6 horas com a cobrança já tirada não chama update nem relança', async ()=>{
+  const g = googleFalso({ cobranca: false, estado: estadoCom({ projeto: noMes(120) }, { primeiraFalha: T0 }) });
+  g.falhar['api-desligar'] = [new ErroHttp(403)];
+  const r = await rodar(g, msgOrcamento(120), { agora: mais(T0, SEIS_HORAS) });
+  assert.equal(r.erro, null);
+  assert.ok(g.chamadas.includes('cobranca-ler'));
+  assert.ok(!g.chamadas.includes('cobranca-tirar'));
+  assert.equal(passagemUnica(r).fez, 'cobrança já estava tirada');
+});
+
+test('orçamento com nome desconhecido dá erro, sem relançar e sem agir', async ()=>{
+  const g = googleFalso();
+  const r = await rodar(g, msgOrcamento(500, { budgetDisplayName: 'renomeado' }));
+  assert.equal(r.erro, null);
+  assert.deepEqual(g.chamadas, []);
+  assert.match(r.de('corte-erro')[0].message, /renomeado/);
+  passagemUnica(r);
+});
+
+test('falha ao tirar a cobrança relança para o Pub/Sub repetir', async ()=>{
+  const erro = new ErroHttp(503);
+  const g = googleFalso();
+  g.falhar['cobranca-tirar'] = [erro];
+  const r = await rodar(g, foraDe(100));
+  assert.equal(r.erro, erro);
+  assert.equal(g.estado.cobrancaTiradaEm, null);
+  assert.equal(r.de('corte-erro').length, 1);
+});
+
+test('toda linha do registro é um JSON com severity, message e marca', async ()=>{
+  const g = googleFalso();
+  const r = await rodar(g, msgOrcamento(60));
+  assert.ok(r.linhas.length >= 2);
+  for(const l of r.linhas){
+    assert.equal(typeof l.severity, 'string');
+    assert.equal(typeof l.message, 'string');
+    assert.match(l.marca, /^corte-(passagem|acao|erro)$/);
+  }
+});
+
+test('index registra a função receber no framework de CloudEvents', ()=>{
+  const registrados = [];
+  registrarFuncao({ cloudEvent: (nome, fn) => registrados.push([nome, typeof fn]) }, ENV);
+  assert.deepEqual(registrados, [['receber', 'function']]);
+});
````

- [ ] **Verificar**

````bash
npm run test:unit
````

- [ ] **Commit**

````bash
git add corte/index.js corte/regra.js tests/corte.test.cjs
git commit -F - <<'FIM'
feat: função do corte ligada ao Pub/Sub

A função recebe orçamentos e o alerta de leituras e decide pela regra
pura, com dois interruptores independentes que por padrão só registram o
que fariam. Depois de pedir para desligar a API, vale o que o
services.get mostra, nunca o código de erro; a falha que persiste 6 horas
com custo de R$ 100 é o único caminho do orçamento do projeto até a
cobrança. Falha transitória relança para o Pub/Sub repetir e mensagem
ilegível não, e toda mensagem deixa uma linha de passagem como prova de
vida.
FIM
````

### Tarefa 5: feat: script de religar a API depois do corte

**Arquivos:** `corte/religar.sh` (novo), `tests/corte.test.cjs`

Testado com um `gcloud` falso no `PATH`, conferindo a ordem: a base grava **antes** de religar a API. Precisa de `gcloud` e `python3`, os dois no Cloud Shell.

- [ ] **Aplicar**

````diff
diff --git a/corte/religar.sh b/corte/religar.sh
new file mode 100755
index 0000000..4e9f9fb
--- /dev/null
+++ b/corte/religar.sh
@@ -0,0 +1,84 @@
+#!/usr/bin/env bash
+# Volta depois de um corte: grava a base do mês e só então religa a API do Firestore.
+# Roda no Cloud Shell, sem o Mac: precisa só de gcloud e de python3 (que o Cloud Shell traz).
+#
+# Uso: corte/religar.sh [--folga N]     N em reais, padrão 0
+#
+# A função continua armada e os gatilhos valem sobre custo = costAmount - base. A folga soma à
+# base do orçamento do projeto o gasto do ataque que o relatório atrasado ainda vai mostrar. O
+# orçamento de fora do Firestore nunca leva folga e só ganha base nova se a cobrança foi tirada:
+# sem corte, base nova subiria o teto de quem gasta fora do Firestore.
+set -euo pipefail
+
+uso(){ echo "uso: religar.sh [--folga N]" >&2; exit 2; }
+
+FOLGA=0
+while [ $# -gt 0 ]; do
+  case "$1" in
+    --folga) [ $# -ge 2 ] || uso; FOLGA="$2"; shift 2;;
+    *) uso;;
+  esac
+done
+case "$FOLGA" in
+  ''|.|*[!0-9.]*|*.*.*) uso;;
+esac
+
+PROJETO_ALVO="${PROJETO_ALVO:-app-construcao-civil}"
+BUCKET_ESTADO="${BUCKET_ESTADO:-custta-corte-estado}"
+ORCAMENTO_PROJETO="${ORCAMENTO_PROJETO:-custta-projeto}"
+ORCAMENTO_FORA_FIRESTORE="${ORCAMENTO_FORA_FIRESTORE:-custta-fora-firestore}"
+OBJETO="gs://$BUCKET_ESTADO/estado.json"
+PASTA="$(mktemp -d)"
+trap 'rm -rf "$PASTA"' EXIT
+
+# A geração vem antes do conteúdo: se o objeto mudar no meio, a gravação condicionada recusa.
+# Cada comando tem o próprio || return porque set -e não vale dentro de função chamada em if.
+gravar_base(){
+  local geracao
+  geracao="$(gcloud storage objects describe "$OBJETO" --format='value(generation)')" || return 1
+  [ -n "$geracao" ] || return 1
+  gcloud storage cat "$OBJETO" > "$PASTA/atual.json" || return 1
+  FOLGA="$FOLGA" ORCAMENTO_PROJETO="$ORCAMENTO_PROJETO" ORCAMENTO_FORA_FIRESTORE="$ORCAMENTO_FORA_FIRESTORE" \
+    python3 - "$PASTA/atual.json" "$PASTA/novo.json" "$PASTA/vale-agora.txt" <<'PY' || return 1
+import json, os, sys
+
+LIMITE_API, LIMITE_COBRANCA = 60, 100  # os de corte/regra.js, em reais
+
+origem, destino, vale_agora = sys.argv[1:4]
+folga = float(os.environ["FOLGA"])
+with open(origem, encoding="utf-8") as f:
+    estado = json.load(f)
+orcamentos = estado.get("orcamentos") or {}
+
+def rebasear(orcamento, acrescimo):
+    orcamento["base"] = round(float(orcamento.get("maiorCusto", 0)) + acrescimo, 2)
+    return orcamento["base"]
+
+def reais(valor):
+    return f"R$ {valor:.2f}".replace(".", ",")
+
+projeto = orcamentos.get(os.environ["ORCAMENTO_PROJETO"])
+base_projeto = rebasear(projeto, folga) if projeto is not None else 0
+linhas = [f"API cai de novo em {reais(base_projeto + LIMITE_API)}"]
+fora = orcamentos.get(os.environ["ORCAMENTO_FORA_FIRESTORE"])
+if fora is not None and estado.get("cobrancaTiradaEm"):
+    linhas.append(f"cobrança cai em {reais(rebasear(fora, 0) + LIMITE_COBRANCA)}")
+estado["primeiraFalha"] = None
+estado["apiDesligadaEm"] = None
+estado["cobrancaTiradaEm"] = None
+with open(destino, "w", encoding="utf-8") as f:
+    json.dump(estado, f, ensure_ascii=False)
+with open(vale_agora, "w", encoding="utf-8") as f:
+    f.write("\n".join(linhas) + "\n")
+PY
+  gcloud storage cp "$PASTA/novo.json" "$OBJETO" --if-generation-match="$geracao" || return 1
+}
+
+if ! gravar_base; then
+  echo "não gravou a base: tentando mais uma vez" >&2
+  gravar_base || { echo "base não gravada: a API NÃO foi religada" >&2; exit 1; }
+fi
+
+gcloud services enable firestore.googleapis.com --project "$PROJETO_ALVO"
+echo "API religada. Abra um aparelho por vez: o último a subir regrava o documento inteiro."
+cat "$PASTA/vale-agora.txt"
diff --git a/tests/corte.test.cjs b/tests/corte.test.cjs
index 67a9b3a..9bf4f9a 100644
--- a/tests/corte.test.cjs
+++ b/tests/corte.test.cjs
@@ -714,3 +714,182 @@ test('index registra a função receber no framework de CloudEvents', ()=>{
   registrarFuncao({ cloudEvent: (nome, fn) => registrados.push([nome, typeof fn]) }, ENV);
   assert.deepEqual(registrados, [['receber', 'function']]);
 });
+
+/* Os scripts rodam de verdade, com um gcloud falso no PATH que anota cada chamada, com os
+   argumentos separados por |, na ordem em que chegaram. */
+const { spawnSync } = require('node:child_process');
+const { mkdtempSync, writeFileSync, readFileSync, chmodSync, existsSync } = require('node:fs');
+const { tmpdir } = require('node:os');
+const path = require('node:path');
+
+const PASTA_CORTE = path.join(__dirname, '..', 'corte');
+const GCLOUD_FALSO = `#!/bin/sh
+(IFS='|'; printf '%s\\n' "$*") >> "$GCLOUD_DIR/log"
+case "$1 $2" in
+  "storage objects")
+    [ -f "$GCLOUD_DIR/sem-objeto" ] && exit 1
+    echo 7;;
+  "storage cat") cat "$GCLOUD_DIR/estado.json";;
+  "storage cp")
+    n=$(cat "$GCLOUD_DIR/falhas-cp")
+    if [ "$n" -gt 0 ]; then echo $((n-1)) > "$GCLOUD_DIR/falhas-cp"; echo 'precondição falhou' >&2; exit 1; fi
+    cp "$3" "$GCLOUD_DIR/gravado.json";;
+  "services enable") [ -f "$GCLOUD_DIR/falha-enable" ] && exit 1; exit 0;;
+  "functions deploy") exit 0;;
+  *) echo "gcloud falso: chamada inesperada: $*" >&2; exit 99;;
+esac
+`;
+
+function rodarScript(nome, args, { estado = '{}', falhasCp = 0, env = {}, semObjeto = false, falhaEnable = false } = {}){
+  const dir = mkdtempSync(path.join(tmpdir(), 'corte-gcloud-'));
+  writeFileSync(path.join(dir, 'gcloud'), GCLOUD_FALSO);
+  chmodSync(path.join(dir, 'gcloud'), 0o755);
+  writeFileSync(path.join(dir, 'estado.json'), typeof estado === 'string' ? estado : JSON.stringify(estado));
+  writeFileSync(path.join(dir, 'falhas-cp'), String(falhasCp));
+  if(semObjeto) writeFileSync(path.join(dir, 'sem-objeto'), '');
+  if(falhaEnable) writeFileSync(path.join(dir, 'falha-enable'), '');
+  const r = spawnSync('bash', [path.join(PASTA_CORTE, nome), ...args], {
+    encoding: 'utf8', cwd: tmpdir(), env: { ...process.env, PATH: `${dir}:${process.env.PATH}`, GCLOUD_DIR: dir, ...env },
+  });
+  const arquivoLog = path.join(dir, 'log'), gravado = path.join(dir, 'gravado.json');
+  return {
+    status: r.status, saida: r.stdout + r.stderr,
+    log: existsSync(arquivoLog) ? readFileSync(arquivoLog, 'utf8').split('\n').filter(Boolean).map(l => l.split('|')) : [],
+    gravado: existsSync(gravado) ? JSON.parse(readFileSync(gravado, 'utf8')) : null,
+  };
+}
+const ESTADO_CORTADO = {
+  orcamentos: { 'custta-projeto': { intervalo: '2026-11', base: 0, maiorCusto: 84.2 }, 'custta-fora-firestore': { intervalo: '2026-11', base: 3, maiorCusto: 12.5 } },
+  primeiraFalha: '2026-11-09T12:00:00.000Z', apiDesligadaEm: '2026-11-09T13:00:00.000Z', cobrancaTiradaEm: '2026-11-09T14:00:00.000Z',
+};
+const OBJETO_GS = 'gs://custta-corte-estado/estado.json';
+const nomeDe = chamada => chamada.slice(0, 3).join(' ');
+
+test('religar: lê a geração, depois o conteúdo, grava condicionado e só então religa', ()=>{
+  const r = rodarScript('religar.sh', [], { estado: ESTADO_CORTADO });
+  assert.equal(r.status, 0, r.saida);
+  assert.deepEqual(r.log.map(nomeDe), [
+    `storage objects describe`, `storage cat ${OBJETO_GS}`, `storage cp ${r.log[2][2]}`, 'services enable firestore.googleapis.com',
+  ]);
+  assert.deepEqual(r.log[0].slice(3), [OBJETO_GS, '--format=value(generation)']);
+  assert.deepEqual(r.log[2].slice(3), [OBJETO_GS, '--if-generation-match=7']);
+  assert.deepEqual(r.log[3], ['services', 'enable', 'firestore.googleapis.com', '--project', 'app-construcao-civil']);
+});
+
+test('religar: com a cobrança tirada, base vira o maiorCusto nos dois orçamentos e os três registros zeram', ()=>{
+  const r = rodarScript('religar.sh', [], { estado: ESTADO_CORTADO });
+  assert.equal(r.status, 0, r.saida);
+  assert.deepEqual(r.gravado, {
+    orcamentos: { 'custta-projeto': { intervalo: '2026-11', base: 84.2, maiorCusto: 84.2 }, 'custta-fora-firestore': { intervalo: '2026-11', base: 12.5, maiorCusto: 12.5 } },
+    primeiraFalha: null, apiDesligadaEm: null, cobrancaTiradaEm: null,
+  });
+});
+
+test('religar: sem cobrança tirada, o orçamento de fora do Firestore não muda, com folga ou sem', ()=>{
+  const estado = { ...ESTADO_CORTADO, cobrancaTiradaEm: null };
+  for(const args of [[], ['--folga', '15']]){
+    const r = rodarScript('religar.sh', args, { estado });
+    assert.equal(r.status, 0, r.saida);
+    assert.deepEqual(r.gravado.orcamentos['custta-fora-firestore'], ESTADO_CORTADO.orcamentos['custta-fora-firestore'], args.join(' '));
+    assert.equal(r.gravado.primeiraFalha, null);
+    assert.equal(r.gravado.apiDesligadaEm, null);
+    assert.equal(r.gravado.cobrancaTiradaEm, null);
+  }
+});
+
+test('religar: --folga soma só à base do orçamento do projeto, sem ruído de ponto flutuante', ()=>{
+  const r = rodarScript('religar.sh', ['--folga', '15'], { estado: ESTADO_CORTADO });
+  assert.equal(r.status, 0, r.saida);
+  assert.equal(r.gravado.orcamentos['custta-projeto'].base, 99.2);
+  assert.equal(r.gravado.orcamentos['custta-fora-firestore'].base, 12.5, 'fora do Firestore nunca leva folga');
+  const fino = rodarScript('religar.sh', ['--folga', '0.1'], { estado: { orcamentos: { 'custta-projeto': noMes(0.2) } } });
+  assert.equal(fino.gravado.orcamentos['custta-projeto'].base, 0.3);
+});
+
+test('religar: os nomes dos orçamentos trocam por ambiente; orçamento de outro nome não muda', ()=>{
+  const outro = noMes(50, 1);
+  const estado = { orcamentos: { p: noMes(10), f: noMes(20), 'custta-projeto': outro }, cobrancaTiradaEm: '2026-11-09T14:00:00.000Z' };
+  const r = rodarScript('religar.sh', ['--folga', '5'], { estado, env: { ORCAMENTO_PROJETO: 'p', ORCAMENTO_FORA_FIRESTORE: 'f' } });
+  assert.equal(r.status, 0, r.saida);
+  assert.deepEqual(r.gravado.orcamentos, { p: noMes(10, 15), f: noMes(20, 20), 'custta-projeto': outro });
+});
+
+const emReais = v => `R$ ${v.toFixed(2).replace('.', ',')}`;
+
+test('religar: termina dizendo em quanto cada corte volta, calculado da base gravada', ()=>{
+  const r = rodarScript('religar.sh', ['--folga', '15'], { estado: ESTADO_CORTADO });
+  assert.equal(r.status, 0, r.saida);
+  const fim = r.saida.trim().split('\n').slice(-2);
+  assert.deepEqual(fim, ['API cai de novo em R$ 159,20', 'cobrança cai em R$ 112,50']);
+  /* Os limites vivem em regra.js e o script, sem Node, repete os dois: mudar lá sem mudar aqui quebra. */
+  const { 'custta-projeto': projeto, 'custta-fora-firestore': fora } = r.gravado.orcamentos;
+  assert.deepEqual(fim, [`API cai de novo em ${emReais(projeto.base + regra.LIMITE_API / 100)}`, `cobrança cai em ${emReais(fora.base + regra.LIMITE_COBRANCA / 100)}`]);
+});
+
+test('religar: sem cobrança tirada, não fala de cobrança', ()=>{
+  const r = rodarScript('religar.sh', [], { estado: { ...ESTADO_CORTADO, cobrancaTiradaEm: null } });
+  assert.equal(r.status, 0, r.saida);
+  assert.match(r.saida, /API cai de novo em R\$ 144,20\n$/);
+  assert.doesNotMatch(r.saida, /cobrança cai/);
+});
+
+test('religar: sem registro dos orçamentos, a API cai no limite cheio e a cobrança não muda', ()=>{
+  const r = rodarScript('religar.sh', ['--folga', '15'], { estado: { orcamentos: {}, cobrancaTiradaEm: '2026-11-09T14:00:00.000Z' } });
+  assert.equal(r.status, 0, r.saida);
+  assert.match(r.saida, /API cai de novo em R\$ 60,00\n$/);
+  assert.doesNotMatch(r.saida, /cobrança cai/);
+  assert.equal(r.gravado.cobrancaTiradaEm, null);
+});
+
+test('religar: argumento errado para antes de qualquer gcloud', ()=>{
+  for(const args of [['--folga', 'abc'], ['--folga', '-5'], ['--folga'], ['--folga', '1.2.3'], ['--outro']]){
+    const r = rodarScript('religar.sh', args, { estado: ESTADO_CORTADO });
+    assert.notEqual(r.status, 0, args.join(' '));
+    assert.deepEqual(r.log, [], args.join(' '));
+  }
+});
+
+test('religar: conflito na gravação tenta uma vez de novo, relendo tudo', ()=>{
+  const r = rodarScript('religar.sh', [], { estado: ESTADO_CORTADO, falhasCp: 1 });
+  assert.equal(r.status, 0, r.saida);
+  assert.deepEqual(r.log.map(c => c.slice(0, 2).join(' ')), [
+    'storage objects', 'storage cat', 'storage cp', 'storage objects', 'storage cat', 'storage cp', 'services enable',
+  ]);
+  assert.equal(r.saida.match(/API cai de novo/g).length, 1, 'o que vale agora sai uma vez só');
+});
+
+test('religar: sem conseguir gravar a base, não religa a API', ()=>{
+  const r = rodarScript('religar.sh', [], { estado: ESTADO_CORTADO, falhasCp: 2 });
+  assert.notEqual(r.status, 0);
+  assert.ok(!r.log.some(c => c[0] === 'services'), 'a base grava antes de religar');
+  assert.equal(r.log.filter(c => c[1] === 'cp').length, 2);
+});
+
+test('religar: estado.json ausente ou ilegível para sem gravar nem religar', ()=>{
+  const sem = rodarScript('religar.sh', [], { estado: ESTADO_CORTADO, semObjeto: true });
+  assert.notEqual(sem.status, 0);
+  assert.ok(!sem.log.some(c => c[1] === 'cp' || c[0] === 'services'));
+  const ruim = rodarScript('religar.sh', [], { estado: 'não é json' });
+  assert.notEqual(ruim.status, 0);
+  assert.ok(!ruim.log.some(c => c[1] === 'cp' || c[0] === 'services'));
+});
+
+test('religar: falha ao religar aparece no código de saída', ()=>{
+  const r = rodarScript('religar.sh', [], { estado: ESTADO_CORTADO, falhaEnable: true });
+  assert.notEqual(r.status, 0);
+  assert.ok(r.gravado, 'a base já está gravada: repetir o script é seguro');
+  assert.doesNotMatch(r.saida, /API cai de novo/);
+});
+
+test('religar: projeto e bucket trocam por ambiente, para o projeto descartável', ()=>{
+  const r = rodarScript('religar.sh', [], { estado: ESTADO_CORTADO, env: { PROJETO_ALVO: 'descartavel', BUCKET_ESTADO: 'balde' } });
+  assert.equal(r.status, 0, r.saida);
+  assert.equal(r.log[1][2], 'gs://balde/estado.json');
+  assert.deepEqual(r.log[3], ['services', 'enable', 'firestore.googleapis.com', '--project', 'descartavel']);
+});
+
+test('religar: roda no Cloud Shell só com gcloud e python3, sem Node', ()=>{
+  const texto = readFileSync(path.join(PASTA_CORTE, 'religar.sh'), 'utf8');
+  assert.match(texto, /python3/);
+  assert.doesNotMatch(texto, /\b(node|npm|npx|jq)\b/);
+});
````

- [ ] **Verificar**

````bash
npm run test:unit
````

- [ ] **Commit**

````bash
git add corte/religar.sh tests/corte.test.cjs
git commit -F - <<'FIM'
feat: script de religar a API depois do corte

O religar grava a base do mês, zera a falha, o desligamento e o corte da
cobrança, e só depois roda o gcloud services enable: se a base não gravar,
a API continua desligada, porque religar sem base faria o próximo
relatório derrubar tudo de novo. A folga vale só para o orçamento do
projeto; o de fora do Firestore só ganha base nova, sem folga, se a
cobrança foi tirada, para a volta não subir o teto de quem gasta fora do
Firestore. No fim o script diz em que valor cada corte volta a valer, a
partir da base gravada. Roda no Cloud Shell só com gcloud e python3, que
o Cloud Shell traz, e a gravação usa a geração lida antes do conteúdo. Os
testes usam um gcloud falso no PATH e conferem argumentos e ordem.
FIM
````

### Tarefa 6: feat: script de implantar a função de corte

**Arquivos:** `corte/implantar.sh` (novo), `tests/corte.test.cjs`

Nomes-padrão: função e tópico `custta-corte`, orçamentos `custta-projeto` e `custta-fora-firestore`, política `custta-leituras`. O ID real do projeto entra por `PROJETO_FUNCAO`, e o bucket por `BUCKET_ESTADO`.

- [ ] **Aplicar**

````diff
diff --git a/corte/implantar.sh b/corte/implantar.sh
new file mode 100755
index 0000000..59f7256
--- /dev/null
+++ b/corte/implantar.sh
@@ -0,0 +1,43 @@
+#!/usr/bin/env bash
+# Implanta a função de corte no projeto próprio dela. Sem argumento sobe desarmada: só registra
+# o que faria.
+#
+# Uso: corte/implantar.sh [--armar-api] [--armar-cobranca]
+set -euo pipefail
+
+ARMADO_API=false
+ARMADO_COBRANCA=false
+while [ $# -gt 0 ]; do
+  case "$1" in
+    --armar-api) ARMADO_API=true;;
+    --armar-cobranca) ARMADO_COBRANCA=true;;
+    *) echo "uso: implantar.sh [--armar-api] [--armar-cobranca]" >&2; exit 2;;
+  esac
+  shift
+done
+
+PASTA="$(cd "$(dirname "$0")" && pwd)"
+PROJETO_FUNCAO="${PROJETO_FUNCAO:-custta-corte}"
+PROJETO_ALVO="${PROJETO_ALVO:-app-construcao-civil}"
+BUCKET_ESTADO="${BUCKET_ESTADO:-custta-corte-estado}"
+ORCAMENTO_PROJETO="${ORCAMENTO_PROJETO:-custta-projeto}"
+ORCAMENTO_FORA_FIRESTORE="${ORCAMENTO_FORA_FIRESTORE:-custta-fora-firestore}"
+POLITICA_ALERTA="${POLITICA_ALERTA:-custta-leituras}"
+CONTA="custta-corte@${PROJETO_FUNCAO}.iam.gserviceaccount.com"
+
+# timeout de 300 s: a confirmação do desligamento espera até 1 minuto, além das chamadas.
+gcloud functions deploy custta-corte \
+  --gen2 \
+  --runtime=nodejs22 \
+  --region=us-central1 \
+  --source="$PASTA" \
+  --entry-point=receber \
+  --trigger-topic=custta-corte \
+  --retry \
+  --service-account="$CONTA" \
+  --trigger-service-account="$CONTA" \
+  --no-allow-unauthenticated \
+  --timeout=300s \
+  --max-instances=3 \
+  --set-env-vars="ARMADO_API=$ARMADO_API,ARMADO_COBRANCA=$ARMADO_COBRANCA,PROJETO_ALVO=$PROJETO_ALVO,BUCKET_ESTADO=$BUCKET_ESTADO,ORCAMENTO_PROJETO=$ORCAMENTO_PROJETO,ORCAMENTO_FORA_FIRESTORE=$ORCAMENTO_FORA_FIRESTORE,POLITICA_ALERTA=$POLITICA_ALERTA" \
+  --project="$PROJETO_FUNCAO"
diff --git a/tests/corte.test.cjs b/tests/corte.test.cjs
index 9bf4f9a..08515f9 100644
--- a/tests/corte.test.cjs
+++ b/tests/corte.test.cjs
@@ -893,3 +893,45 @@ test('religar: roda no Cloud Shell só com gcloud e python3, sem Node', ()=>{
   assert.match(texto, /python3/);
   assert.doesNotMatch(texto, /\b(node|npm|npx|jq)\b/);
 });
+
+const envDe = chamada => Object.fromEntries(chamada.find(a => a.startsWith('--set-env-vars=')).slice('--set-env-vars='.length).split(',').map(p => p.split('=')));
+
+test('implantar: sem argumento, sobe desarmada, com os parâmetros combinados', ()=>{
+  const r = rodarScript('implantar.sh', []);
+  assert.equal(r.status, 0, r.saida);
+  assert.equal(r.log.length, 1);
+  const c = r.log[0];
+  assert.deepEqual(c.slice(0, 3), ['functions', 'deploy', 'custta-corte']);
+  const conta = 'custta-corte@custta-corte.iam.gserviceaccount.com';
+  for(const flag of ['--gen2', '--runtime=nodejs22', '--region=us-central1', `--source=${PASTA_CORTE}`, '--entry-point=receber',
+    '--trigger-topic=custta-corte', '--retry', `--service-account=${conta}`, `--trigger-service-account=${conta}`,
+    '--no-allow-unauthenticated', '--timeout=300s', '--project=custta-corte']) assert.ok(c.includes(flag), flag);
+  assert.deepEqual(envDe(c), {
+    ARMADO_API: 'false', ARMADO_COBRANCA: 'false', PROJETO_ALVO: 'app-construcao-civil', BUCKET_ESTADO: 'custta-corte-estado',
+    ORCAMENTO_PROJETO: 'custta-projeto', ORCAMENTO_FORA_FIRESTORE: 'custta-fora-firestore', POLITICA_ALERTA: 'custta-leituras',
+  });
+});
+
+test('implantar: cada interruptor arma só pelo próprio argumento', ()=>{
+  const so = args => { const r = rodarScript('implantar.sh', args); assert.equal(r.status, 0, r.saida); const e = envDe(r.log[0]); return [e.ARMADO_API, e.ARMADO_COBRANCA]; };
+  assert.deepEqual(so(['--armar-api']), ['true', 'false']);
+  assert.deepEqual(so(['--armar-cobranca']), ['false', 'true']);
+  assert.deepEqual(so(['--armar-api', '--armar-cobranca']), ['true', 'true']);
+});
+
+test('implantar: argumento desconhecido para antes do gcloud', ()=>{
+  for(const args of [['--armar'], ['true'], ['--armar-api', 'x']]){
+    const r = rodarScript('implantar.sh', args);
+    assert.notEqual(r.status, 0, args.join(' '));
+    assert.deepEqual(r.log, [], args.join(' '));
+  }
+});
+
+test('implantar: projetos e nomes trocam por ambiente, para o projeto descartável', ()=>{
+  const r = rodarScript('implantar.sh', [], { env: { PROJETO_FUNCAO: 'corte-teste', PROJETO_ALVO: 'descartavel', BUCKET_ESTADO: 'balde' } });
+  assert.equal(r.status, 0, r.saida);
+  assert.ok(r.log[0].includes('--project=corte-teste'));
+  assert.ok(r.log[0].includes('--service-account=custta-corte@corte-teste.iam.gserviceaccount.com'));
+  assert.equal(envDe(r.log[0]).PROJETO_ALVO, 'descartavel');
+  assert.equal(envDe(r.log[0]).BUCKET_ESTADO, 'balde');
+});
````

- [ ] **Verificar**

````bash
npm run test:unit
````

- [ ] **Commit**

````bash
git add corte/implantar.sh tests/corte.test.cjs
git commit -F - <<'FIM'
feat: script de implantar a função de corte

Sem argumento a função sobe com os dois interruptores em false, e cada um
só arma pelo próprio argumento; argumento desconhecido para antes do
gcloud, para um erro de digitação não implantar outra coisa. O projeto e
os nomes têm padrão de produção e trocam por variável de ambiente, para o
mesmo script servir no projeto descartável.
FIM
````

### Tarefa 7: docs: README do corte de gastos

**Arquivos:** `corte/README.md` (novo)

- [ ] **Aplicar**

````diff
diff --git a/corte/README.md b/corte/README.md
new file mode 100644
index 0000000..0df98ff
--- /dev/null
+++ b/corte/README.md
@@ -0,0 +1,14 @@
+# Corte de gastos
+
+Cloud Run function em projeto próprio (`custta-corte`), fora do app. Recebe do Pub/Sub dois orçamentos e o alerta de leituras e age sobre o projeto de produção:
+
+- R$ 60 no orçamento do projeto, ou alerta aberto: desliga a API do Firestore. A cobrança fica.
+- R$ 100 no orçamento do projeto: tira a cobrança só se a API não desligou, com falha por 6 horas.
+- R$ 100 no orçamento de todos os serviços menos o Firestore: tira a cobrança.
+
+Nunca religa nada. Os dois interruptores (`ARMADO_API`, `ARMADO_COBRANCA`) começam em `false`: desarmada, a função só registra o que faria.
+
+- `implantar.sh [--armar-api] [--armar-cobranca]`: implanta a função.
+- `religar.sh [--folga N]`: volta depois de um corte; roda no Cloud Shell.
+
+O roteiro de implantação e de volta está no plano da Blindagem 4, em `docs/plans/`. Os testes ficam em `tests/corte.test.cjs`.
````

- [ ] **Verificar**

````bash
npm run test:unit
````

- [ ] **Commit**

````bash
git add corte/README.md
git commit -F - <<'FIM'
docs: README do corte de gastos

Diz o que a função faz, o que os dois interruptores significam e onde
fica o roteiro, sem nada de segredo.
FIM
````

### Tarefa 8: feat: modo oficial do corte, para a volta às provas reprovadas

**Arquivos:** `corte/README.md`, `corte/implantar.sh`, `corte/index.js`, `corte/regra.js`, `tests/corte.test.cjs`

É a volta aprovada se o T1 ou o T2 reprovar. Fica desligada: só `--modo-oficial` a liga, e a retirada da cobrança continua dependendo do `--armar-cobranca`.

- [ ] **Aplicar**

````diff
diff --git a/corte/README.md b/corte/README.md
index 0df98ff..5c12720 100644
--- a/corte/README.md
+++ b/corte/README.md
@@ -6,9 +6,11 @@ Cloud Run function em projeto próprio (`custta-corte`), fora do app. Recebe do
 - R$ 100 no orçamento do projeto: tira a cobrança só se a API não desligou, com falha por 6 horas.
 - R$ 100 no orçamento de todos os serviços menos o Firestore: tira a cobrança.
 
+Com `MODO_CORTE=oficial`, a receita oficial do Google para a volta às provas reprovadas, é um tempo só: R$ 60 no orçamento do projeto tira a cobrança na hora, sem tentar desligar a API, e o alerta de leituras só registra. O orçamento de fora do Firestore não muda. O padrão é `dois-tempos`; valor desconhecido dá `corte-erro` e nenhuma ação.
+
 Nunca religa nada. Os dois interruptores (`ARMADO_API`, `ARMADO_COBRANCA`) começam em `false`: desarmada, a função só registra o que faria.
 
-- `implantar.sh [--armar-api] [--armar-cobranca]`: implanta a função.
+- `implantar.sh [--armar-api] [--armar-cobranca] [--modo-oficial]`: implanta a função.
 - `religar.sh [--folga N]`: volta depois de um corte; roda no Cloud Shell.
 
 O roteiro de implantação e de volta está no plano da Blindagem 4, em `docs/plans/`. Os testes ficam em `tests/corte.test.cjs`.
diff --git a/corte/implantar.sh b/corte/implantar.sh
index 59f7256..881b332 100755
--- a/corte/implantar.sh
+++ b/corte/implantar.sh
@@ -2,16 +2,21 @@
 # Implanta a função de corte no projeto próprio dela. Sem argumento sobe desarmada: só registra
 # o que faria.
 #
-# Uso: corte/implantar.sh [--armar-api] [--armar-cobranca]
+# Uso: corte/implantar.sh [--armar-api] [--armar-cobranca] [--modo-oficial]
+#
+# --modo-oficial é a receita oficial do Google, para a volta às provas reprovadas: um tempo só,
+# tira a cobrança em R$ 60. Não arma nada: continua valendo --armar-cobranca. Sem ele, dois-tempos.
 set -euo pipefail
 
 ARMADO_API=false
 ARMADO_COBRANCA=false
+MODO_CORTE=dois-tempos
 while [ $# -gt 0 ]; do
   case "$1" in
     --armar-api) ARMADO_API=true;;
     --armar-cobranca) ARMADO_COBRANCA=true;;
-    *) echo "uso: implantar.sh [--armar-api] [--armar-cobranca]" >&2; exit 2;;
+    --modo-oficial) MODO_CORTE=oficial;;
+    *) echo "uso: implantar.sh [--armar-api] [--armar-cobranca] [--modo-oficial]" >&2; exit 2;;
   esac
   shift
 done
@@ -39,5 +44,5 @@ gcloud functions deploy custta-corte \
   --no-allow-unauthenticated \
   --timeout=300s \
   --max-instances=3 \
-  --set-env-vars="ARMADO_API=$ARMADO_API,ARMADO_COBRANCA=$ARMADO_COBRANCA,PROJETO_ALVO=$PROJETO_ALVO,BUCKET_ESTADO=$BUCKET_ESTADO,ORCAMENTO_PROJETO=$ORCAMENTO_PROJETO,ORCAMENTO_FORA_FIRESTORE=$ORCAMENTO_FORA_FIRESTORE,POLITICA_ALERTA=$POLITICA_ALERTA" \
+  --set-env-vars="ARMADO_API=$ARMADO_API,ARMADO_COBRANCA=$ARMADO_COBRANCA,MODO_CORTE=$MODO_CORTE,PROJETO_ALVO=$PROJETO_ALVO,BUCKET_ESTADO=$BUCKET_ESTADO,ORCAMENTO_PROJETO=$ORCAMENTO_PROJETO,ORCAMENTO_FORA_FIRESTORE=$ORCAMENTO_FORA_FIRESTORE,POLITICA_ALERTA=$POLITICA_ALERTA" \
   --project="$PROJETO_FUNCAO"
diff --git a/corte/index.js b/corte/index.js
index fa43025..308ac70 100644
--- a/corte/index.js
+++ b/corte/index.js
@@ -26,6 +26,7 @@ function criarManipulador({
     orcamentoProjeto: env.ORCAMENTO_PROJETO,
     orcamentoFora: env.ORCAMENTO_FORA_FIRESTORE,
     politica: env.POLITICA_ALERTA,
+    modo: regra.modoDoCorte(env.MODO_CORTE),
   };
   let memo = null;
   const google = () => (memo = memo || carregar(env));
@@ -122,10 +123,11 @@ function criarManipulador({
     }
     passagem.custo = aplicado.custoCentavos / 100;
     const contexto = { orcamento: msg.nome, custo: passagem.custo };
-    const decisao = regra.decidirOrcamento(papel, aplicado.custoCentavos);
+    const decisao = regra.decidirOrcamento(papel, aplicado.custoCentavos, config.modo);
     if(decisao === 'nada') return;
     if(decisao === 'tirar-cobranca'){
-      passagem.fez = (await tirarCobranca(contexto, instante.toISOString(), 'gasto fora do Firestore passou de R$ 100')).fez;
+      const motivo = papel === 'fora' ? 'gasto fora do Firestore passou de R$ 100' : 'modo oficial: gasto do projeto chegou a R$ 60';
+      passagem.fez = (await tirarCobranca(contexto, instante.toISOString(), motivo)).fez;
       return;
     }
     const r = await desligarApi(contexto, instante.toISOString());
@@ -142,6 +144,10 @@ function criarManipulador({
   async function tratarIncidente(msg, passagem, instante){
     passagem.politica = msg.politica;
     if(msg.estado !== 'open' || msg.politica !== config.politica) return;
+    if(config.modo === 'oficial'){
+      passagem.fez = 'só registrou o alerta: o modo oficial não age nele';
+      return;
+    }
     const r = await desligarApi({ politica: msg.politica }, instante.toISOString());
     passagem.fez = r.fez;
     if(r.falhou) throw r.erro;
@@ -160,6 +166,11 @@ function criarManipulador({
         return;
       }
       passagem.tipo = msg.tipo;
+      if(!config.modo){
+        passagem.fez = 'não agiu: MODO_CORTE desconhecido';
+        logar('ALERT', 'corte-erro', `MODO_CORTE desconhecido: ${env.MODO_CORTE}`, {});
+        return;
+      }
       if(msg.tipo === 'incidente') await tratarIncidente(msg, passagem, agora());
       else await tratarOrcamento(msg, passagem, agora());
     }catch(e){
diff --git a/corte/regra.js b/corte/regra.js
index a91349b..d2469f0 100644
--- a/corte/regra.js
+++ b/corte/regra.js
@@ -3,7 +3,7 @@
    disco ou relógio. Limiares valem sobre custo = costAmount − base, em centavos, para a
    conta em reais não errar na fronteira (64,07 − 4,07 dá 59,99999999999999). */
 
-const LIMITE_API = 6000; // R$ 60,00: desliga a API do Firestore
+const LIMITE_API = 6000; // R$ 60,00: desliga a API do Firestore (no modo oficial, tira a cobrança)
 const LIMITE_COBRANCA = 10000; // R$ 100,00: tira a cobrança
 const ESPERA_FALHA_MS = 6 * 60 * 60 * 1000; // falha de desligar que persiste tanto vira corte da cobrança
 
@@ -77,9 +77,17 @@ function papelDoOrcamento(nome, config){
   return null;
 }
 
-function decidirOrcamento(papel, custoCentavos){
+/* Sem a variável vale dois-tempos. Qualquer outro texto devolve null: a função não age. */
+function modoDoCorte(valor){
+  if(valor === undefined) return 'dois-tempos';
+  return valor === 'dois-tempos' || valor === 'oficial' ? valor : null;
+}
+
+/* No modo oficial, a receita do Google, o orçamento do projeto vai direto à cobrança. */
+function decidirOrcamento(papel, custoCentavos, modo = 'dois-tempos'){
   if(papel === 'fora') return custoCentavos >= LIMITE_COBRANCA ? 'tirar-cobranca' : 'nada';
-  return custoCentavos >= LIMITE_API ? 'desligar-api' : 'nada';
+  if(custoCentavos < LIMITE_API) return 'nada';
+  return modo === 'oficial' ? 'tirar-cobranca' : 'desligar-api';
 }
 
 /* A cobrança só sai pelo orçamento do projeto quando a API não ficou desligada: é o que o
@@ -105,6 +113,6 @@ function registrarCobrancaTirada(estado, agora){
 
 module.exports = {
   LIMITE_API, LIMITE_COBRANCA, ESPERA_FALHA_MS, MensagemIlegivel,
-  estadoNormal, intervaloDe, interpretar, aplicarOrcamento, papelDoOrcamento, decidirOrcamento,
+  estadoNormal, intervaloDe, interpretar, aplicarOrcamento, papelDoOrcamento, modoDoCorte, decidirOrcamento,
   deveTirarCobrancaPorFalha, registrarFalha, registrarApiDesligada, registrarCobrancaTirada,
 };
diff --git a/tests/corte.test.cjs b/tests/corte.test.cjs
index 08515f9..e027276 100644
--- a/tests/corte.test.cjs
+++ b/tests/corte.test.cjs
@@ -127,6 +127,22 @@ test('regra: limiares em centavos, por papel', ()=>{
   assert.equal(regra.decidirOrcamento('fora', 10000), 'tirar-cobranca');
 });
 
+test('regra: no modo oficial o projeto tira a cobrança em R$ 60 e o de fora não muda', ()=>{
+  assert.equal(regra.decidirOrcamento('projeto', 5999, 'oficial'), 'nada');
+  assert.equal(regra.decidirOrcamento('projeto', 6000, 'oficial'), 'tirar-cobranca');
+  assert.equal(regra.decidirOrcamento('projeto', 30000, 'oficial'), 'tirar-cobranca');
+  assert.equal(regra.decidirOrcamento('fora', 9999, 'oficial'), 'nada');
+  assert.equal(regra.decidirOrcamento('fora', 10000, 'oficial'), 'tirar-cobranca');
+  assert.equal(regra.decidirOrcamento('projeto', 6000, 'dois-tempos'), 'desligar-api');
+});
+
+test('regra: modo do corte só aceita o texto exato, e sem variável vale dois-tempos', ()=>{
+  assert.equal(regra.modoDoCorte(undefined), 'dois-tempos');
+  assert.equal(regra.modoDoCorte('dois-tempos'), 'dois-tempos');
+  assert.equal(regra.modoDoCorte('oficial'), 'oficial');
+  for(const valor of ['OFICIAL', 'oficial ', '', 'dois_tempos', 'true']) assert.equal(regra.modoDoCorte(valor), null, JSON.stringify(valor));
+});
+
 test('regra: cobrança só sai com custo de R$ 100 e falha de 6 horas', ()=>{
   const seis = 6 * 60 * 60 * 1000, t0 = Date.parse('2026-11-09T12:00:00.000Z'), falha = new Date(t0).toISOString();
   assert.equal(regra.deveTirarCobrancaPorFalha(10000, falha, t0 + seis), true);
@@ -679,6 +695,122 @@ test('cenário 16: falha de 6 horas com a cobrança já tirada não chama update
   assert.equal(passagemUnica(r).fez, 'cobrança já estava tirada');
 });
 
+const OFICIAL = { MODO_CORTE: 'oficial' };
+
+test('cenário 17: modo oficial, 59,99 no projeto não faz nada', async ()=>{
+  const g = googleFalso();
+  const r = await rodar(g, msgOrcamento(59.99), { env: OFICIAL });
+  assert.equal(r.erro, null);
+  assert.deepEqual(semEstado(g.chamadas), []);
+  assert.deepEqual(r.de('corte-acao'), []);
+  assert.equal(passagemUnica(r).fez, 'nada');
+});
+
+test('cenário 17: modo oficial, 60 no projeto tira a cobrança sem olhar a API e sem esperar as 6 horas', async ()=>{
+  const g = googleFalso();
+  const r = await rodar(g, msgOrcamento(60), { env: OFICIAL });
+  assert.equal(r.erro, null);
+  assert.deepEqual(semEstado(g.chamadas), ['cobranca-ler', 'cobranca-tirar']);
+  assert.equal(g.cobranca, false);
+  assert.equal(g.api, 'ENABLED');
+  assert.equal(g.estado.cobrancaTiradaEm, T0);
+  assert.equal(g.estado.primeiraFalha, null);
+  assert.equal(g.estado.apiDesligadaEm, null);
+  assert.equal(g.estado.orcamentos.projeto.maiorCusto, 60);
+  const a = r.de('corte-acao')[0];
+  assert.equal(a.acao, 'tirar-cobranca'); assert.equal(a.severity, 'ALERT'); assert.equal(a.orcamento, 'projeto'); assert.equal(a.custo, 60);
+  assert.equal(passagemUnica(r).fez, 'tirou a cobrança');
+});
+
+test('cenário 17: modo oficial vale sobre o custo descontada a base', async ()=>{
+  const quase = googleFalso({ estado: estadoCom({ projeto: noMes(12.34, 12.34) }) });
+  await rodar(quase, msgOrcamento(72.33), { env: OFICIAL });
+  assert.deepEqual(semEstado(quase.chamadas), []);
+  const passou = googleFalso({ estado: estadoCom({ projeto: noMes(12.34, 12.34) }) });
+  const r = await rodar(passou, msgOrcamento(72.34), { env: OFICIAL });
+  assert.deepEqual(semEstado(passou.chamadas), ['cobranca-ler', 'cobranca-tirar']);
+  assert.equal(r.de('corte-acao')[0].custo, 60);
+});
+
+test('cenário 17: modo oficial com ARMADO_COBRANCA=false só registra que faria, mesmo com a API armada', async ()=>{
+  const g = googleFalso();
+  const r = await rodar(g, msgOrcamento(300), { env: { ...OFICIAL, ARMADO_API: 'true', ARMADO_COBRANCA: 'false' } });
+  assert.equal(r.erro, null);
+  assert.deepEqual(semEstado(g.chamadas), ['cobranca-ler']);
+  assert.equal(g.cobranca, true);
+  assert.equal(g.estado.cobrancaTiradaEm, null);
+  assert.equal(r.de('corte-acao')[0].acao, 'faria-tirar-cobranca');
+  assert.match(r.de('corte-acao')[0].message, /faria/);
+  assert.equal(passagemUnica(r).fez, 'faria tirar a cobrança');
+});
+
+test('cenário 17: modo oficial com a cobrança já tirada não chama update nem relança', async ()=>{
+  const g = googleFalso({ cobranca: false, estado: estadoCom({ projeto: noMes(70) }, { cobrancaTiradaEm: T0 }) });
+  const r = await rodar(g, msgOrcamento(80), { env: OFICIAL, agora: mais(T0, 3600000) });
+  assert.equal(r.erro, null);
+  assert.deepEqual(semEstado(g.chamadas), ['cobranca-ler']);
+  assert.equal(g.estado.cobrancaTiradaEm, T0);
+  assert.equal(passagemUnica(r).fez, 'cobrança já estava tirada');
+});
+
+test('cenário 17: modo oficial, falha ao tirar a cobrança relança para o Pub/Sub repetir', async ()=>{
+  const erro = new ErroHttp(503);
+  const g = googleFalso();
+  g.falhar['cobranca-tirar'] = [erro];
+  const r = await rodar(g, msgOrcamento(60), { env: OFICIAL });
+  assert.equal(r.erro, erro);
+  assert.equal(g.estado.cobrancaTiradaEm, null);
+  assert.ok(!g.chamadas.some(c => c.startsWith('api-')));
+});
+
+test('cenário 17: modo oficial não muda o orçamento fora do Firestore', async ()=>{
+  const abaixo = googleFalso();
+  await rodar(abaixo, foraDe(99.99), { env: OFICIAL });
+  assert.deepEqual(semEstado(abaixo.chamadas), []);
+  const acima = googleFalso();
+  const r = await rodar(acima, foraDe(100), { env: OFICIAL });
+  assert.equal(r.erro, null);
+  assert.deepEqual(semEstado(acima.chamadas), ['cobranca-ler', 'cobranca-tirar']);
+  assert.match(r.de('corte-acao')[0].message, /fora do Firestore/);
+});
+
+test('cenário 17: modo oficial, alerta aberto só registra, sem ação e sem falar com o Google', async ()=>{
+  const g = googleFalso();
+  const r = await rodar(g, incidente('leituras', 'open'), { env: OFICIAL });
+  assert.equal(r.erro, null);
+  assert.deepEqual(g.chamadas, []);
+  assert.deepEqual(r.de('corte-acao'), []);
+  assert.deepEqual(r.de('corte-erro'), []);
+  const p = passagemUnica(r);
+  assert.equal(p.tipo, 'incidente'); assert.equal(p.politica, 'leituras'); assert.match(p.fez, /registrou/);
+});
+
+test('cenário 18: dois-tempos escrito é o mesmo corte de quando a variável não existe', async ()=>{
+  const env = { MODO_CORTE: 'dois-tempos' };
+  const g1 = googleFalso();
+  await rodar(g1, msgOrcamento(60), { env });
+  assert.deepEqual(semEstado(g1.chamadas), ['api-ler', 'api-desligar', 'api-ler']);
+  const g2 = googleFalso();
+  await rodar(g2, incidente('leituras', 'open'), { env });
+  assert.deepEqual(semEstado(g2.chamadas), ['api-ler', 'api-desligar', 'api-ler']);
+});
+
+test('cenário 18: MODO_CORTE desconhecido dá corte-erro e nenhuma ação, em qualquer mensagem', async ()=>{
+  for(const valor of ['OFICIAL', 'oficial ', '', 'dois_tempos']){
+    for(const corpo of [msgOrcamento(300), foraDe(300), incidente('leituras', 'open')]){
+      const g = googleFalso();
+      const r = await rodar(g, corpo, { env: { MODO_CORTE: valor } });
+      const caso = JSON.stringify([valor, corpo]);
+      assert.equal(r.erro, null, caso);
+      assert.deepEqual(g.chamadas, [], caso);
+      assert.deepEqual(r.de('corte-acao'), [], caso);
+      assert.equal(r.de('corte-erro').length, 1, caso);
+      assert.match(r.de('corte-erro')[0].message, /MODO_CORTE/, caso);
+      passagemUnica(r);
+    }
+  }
+});
+
 test('orçamento com nome desconhecido dá erro, sem relançar e sem agir', async ()=>{
   const g = googleFalso();
   const r = await rodar(g, msgOrcamento(500, { budgetDisplayName: 'renomeado' }));
@@ -907,7 +1039,7 @@ test('implantar: sem argumento, sobe desarmada, com os parâmetros combinados',
     '--trigger-topic=custta-corte', '--retry', `--service-account=${conta}`, `--trigger-service-account=${conta}`,
     '--no-allow-unauthenticated', '--timeout=300s', '--project=custta-corte']) assert.ok(c.includes(flag), flag);
   assert.deepEqual(envDe(c), {
-    ARMADO_API: 'false', ARMADO_COBRANCA: 'false', PROJETO_ALVO: 'app-construcao-civil', BUCKET_ESTADO: 'custta-corte-estado',
+    ARMADO_API: 'false', ARMADO_COBRANCA: 'false', MODO_CORTE: 'dois-tempos', PROJETO_ALVO: 'app-construcao-civil', BUCKET_ESTADO: 'custta-corte-estado',
     ORCAMENTO_PROJETO: 'custta-projeto', ORCAMENTO_FORA_FIRESTORE: 'custta-fora-firestore', POLITICA_ALERTA: 'custta-leituras',
   });
 });
@@ -919,8 +1051,18 @@ test('implantar: cada interruptor arma só pelo próprio argumento', ()=>{
   assert.deepEqual(so(['--armar-api', '--armar-cobranca']), ['true', 'true']);
 });
 
+test('implantar: --modo-oficial passa MODO_CORTE=oficial; sem ele, dois-tempos', ()=>{
+  const env = (args, ambiente) => { const r = rodarScript('implantar.sh', args, { env: ambiente }); assert.equal(r.status, 0, r.saida); return envDe(r.log[0]); };
+  assert.equal(env(['--modo-oficial']).MODO_CORTE, 'oficial');
+  assert.equal(env(['--armar-cobranca', '--modo-oficial']).MODO_CORTE, 'oficial');
+  assert.equal(env(['--armar-api', '--armar-cobranca']).MODO_CORTE, 'dois-tempos');
+  assert.equal(env([], { MODO_CORTE: 'oficial' }).MODO_CORTE, 'dois-tempos', 'só o argumento muda o modo');
+  const desarmada = env(['--modo-oficial']);
+  assert.deepEqual([desarmada.ARMADO_API, desarmada.ARMADO_COBRANCA], ['false', 'false'], 'o modo não arma nada');
+});
+
 test('implantar: argumento desconhecido para antes do gcloud', ()=>{
-  for(const args of [['--armar'], ['true'], ['--armar-api', 'x']]){
+  for(const args of [['--armar'], ['true'], ['--armar-api', 'x'], ['--modo'], ['--modo-oficial', 'x']]){
     const r = rodarScript('implantar.sh', args);
     assert.notEqual(r.status, 0, args.join(' '));
     assert.deepEqual(r.log, [], args.join(' '));
````

- [ ] **Verificar**

````bash
npm run test:unit
````

- [ ] **Commit**

````bash
git add corte/README.md corte/implantar.sh corte/index.js corte/regra.js tests/corte.test.cjs
git commit -F - <<'FIM'
feat: modo oficial do corte, para a volta às provas reprovadas

Se as provas reprovarem o desligamento da API, a volta é à receita oficial
do Google, já aprovada pelo dono: um tempo só, tirar a cobrança em R$ 60.
A variável MODO_CORTE escolhe o caminho e o padrão continua dois-tempos,
que não muda em nada. Em oficial, o orçamento do projeto com custo a partir
de R$ 60 tira a cobrança sem tentar desligar a API e sem esperar as 6
horas, respeitando ARMADO_COBRANCA; o orçamento de fora do Firestore segue
igual e o alerta de leituras só fica registrado. Valor desconhecido dá
corte-erro e a função não age, porque o passo em jogo é irreversível. O
implantar.sh só muda de modo pelo argumento --modo-oficial, que não arma
nada sozinho.
FIM
````

## PR 2: App Check no site

**Ramo:** `feat/blindagem4-app-check-site`, a partir da `main`. **Risco:** Script de terceiro no login e CSP nova. Só faz merge depois do G9, com a chave real. Linhas de produção: ~55, fora o `vendor/`.

### Tarefa 9: chore: SDK do App Check no vendor do Firebase

**Arquivos:** `scripts/vendor-firebase.mjs`, `sw.js`

Aplique o diff em `scripts/vendor-firebase.mjs` e `sw.js` e rode `npm ci` e `npm run vendor:firebase`. O `vendor/` e o `assets.json` saem do comando: `firebase-app-check.js`, 17.892 B novos, e o pedaço compartilhado muda de nome (`shared-VONABDH2.js` para `shared-I5BZCWVA.js`). Se o nome do pedaço sair diferente, ajuste o `ASSETS` do `sw.js`.

- [ ] **Aplicar**

````diff
diff --git a/scripts/vendor-firebase.mjs b/scripts/vendor-firebase.mjs
index c76eed1..5adfa60 100644
--- a/scripts/vendor-firebase.mjs
+++ b/scripts/vendor-firebase.mjs
@@ -7,7 +7,7 @@ const require=createRequire(import.meta.url);
 const versao=require('firebase/package.json').version;
 await mkdir('vendor/firebase',{recursive:true});
 const result=await build({
-  entryPoints:{'firebase-app':'firebase/app','firebase-auth':'firebase/auth','firebase-firestore':'firebase/firestore'},
+  entryPoints:{'firebase-app':'firebase/app','firebase-auth':'firebase/auth','firebase-firestore':'firebase/firestore','firebase-app-check':'firebase/app-check'},
   bundle:true, splitting:true, format:'esm', platform:'browser', target:'es2022',
   outdir:'vendor/firebase', chunkNames:'shared-[hash]', minify:true, legalComments:'eof',
   write:false, metafile:true,
diff --git a/sw.js b/sw.js
index d698ed7..077db27 100644
--- a/sw.js
+++ b/sw.js
@@ -1,7 +1,7 @@
 /* Service worker — network-first. Online sempre pega a versão nova; o cache
    é só o retrato pra funcionar offline. Bump CACHE ao mudar arquivos. */
-const CACHE = 'obras-v72';
-const ASSETS = ['./vendor/sentry/sentry.js', './sentry-config.js', './sentry.js', './vendor/firebase/firebase-app.js', './vendor/firebase/firebase-auth.js', './vendor/firebase/firebase-firestore.js', './vendor/firebase/shared-VONABDH2.js', './styles.css', './privacidade.css', './dados.js', './cadastro.js', './', './index.html', './app.js', './gestos.js', './push.js', './share.js', './ui-confirm.js', './privacidade.html', './auth.js', './globe.js', './calc.js', './cloud.js', './icons.js', './splash.js', './splash-pre.js', './teclado.js', './tema.js', './nativo.js', './pwa.js', './manifest.json', './apple-touch-icon.png', './icon-192.png', './icon-512.png', './favicon.svg', './google-g.svg', './fontes/hanken-grotesk-800.woff2'];
+const CACHE = 'obras-v73';
+const ASSETS = ['./vendor/sentry/sentry.js', './sentry-config.js', './sentry.js', './vendor/firebase/firebase-app.js', './vendor/firebase/firebase-auth.js', './vendor/firebase/firebase-firestore.js', './vendor/firebase/firebase-app-check.js', './vendor/firebase/shared-I5BZCWVA.js', './styles.css', './privacidade.css', './dados.js', './cadastro.js', './', './index.html', './app.js', './gestos.js', './push.js', './share.js', './ui-confirm.js', './privacidade.html', './auth.js', './globe.js', './calc.js', './cloud.js', './icons.js', './splash.js', './splash-pre.js', './teclado.js', './tema.js', './nativo.js', './pwa.js', './manifest.json', './apple-touch-icon.png', './icon-192.png', './icon-512.png', './favicon.svg', './google-g.svg', './fontes/hanken-grotesk-800.woff2'];
 
 self.addEventListener('install', e => {
   // {cache:'reload'} garante que o precache pega os arquivos frescos, não o cache HTTP do browser
````

- [ ] **Verificar**

````bash
npm run test:unit
````

- [ ] **Commit**

````bash
git add scripts/vendor-firebase.mjs sw.js vendor/firebase
git commit -F - <<'FIM'
chore: SDK do App Check no vendor do Firebase

O App Check entra no site só observando, e o SDK dele precisa morar em vendor/ como os outros módulos do Firebase, porque o app não tem etapa de build. O novo ponto de entrada mudou o nome do pedaço compartilhado gerado pelo esbuild, então o sw.js troca o nome antigo pelo novo, acrescenta o firebase-app-check.js e sobe o cache para o aparelho instalado baixar o retrato novo.
FIM
````

### Tarefa 10: feat: CSP aceita o reCAPTCHA do App Check no site

**Arquivos:** `scripts/build-www.mjs`, `tests/build-www.test.mjs`, `tests/headers.test.cjs`, `vercel.json`

Violação real observada no experimento com o script público: nenhuma no Chromium; no WebKit, 2 `style-src-elem: inline` do próprio script, sem efeito visível. **Não abra `style-src`.**

- [ ] **Aplicar**

````diff
diff --git a/scripts/build-www.mjs b/scripts/build-www.mjs
index bf05934..813f458 100644
--- a/scripts/build-www.mjs
+++ b/scripts/build-www.mjs
@@ -9,12 +9,14 @@ export const PRODUCAO = 'https://app-construcao-civil.vercel.app';
 
 /* <meta> não aceita frame-ancestors, report-uri, sandbox nem upgrade-insecure-requests.
    Produção entra em connect-src para o aviso de versão do app nativo.
-   O app nativo não tem login com Google: sai o script do Google e o frame-src. */
+   O app nativo não tem login com Google: sai o script do Google e o frame-src.
+   O App Check também não liga nele: saem os endereços do reCAPTCHA. */
 export function cspNativa(csp){
   return csp.split(';').map(d => d.trim()).filter(Boolean)
     .filter(d => !/^(frame-ancestors|upgrade-insecure-requests|report-uri|sandbox|frame-src)\b/.test(d))
     .map(d => d.startsWith('connect-src') ? `${d} ${PRODUCAO}` : d)
     .map(d => d.startsWith('script-src') ? d.replace(' https://apis.google.com', '') : d)
+    .map(d => d.replace(/ https:\/\/www\.(google|gstatic)\.com\/recaptcha\//g, ''))
     .join('; ');
 }
 
diff --git a/tests/build-www.test.mjs b/tests/build-www.test.mjs
index e1df0a8..0f0a91c 100644
--- a/tests/build-www.test.mjs
+++ b/tests/build-www.test.mjs
@@ -39,6 +39,12 @@ test('cspNativa tira o que só o login com Google da web usa', ()=>{
   assert.ok(nativa.includes("script-src 'self'"));
 });
 
+test('cspNativa tira o reCAPTCHA, que só o site publicado usa', ()=>{
+  const nativa = cspNativa("default-src 'none'; script-src 'self' https://www.google.com/recaptcha/ https://www.gstatic.com/recaptcha/; connect-src 'self' https://*.googleapis.com https://www.google.com/recaptcha/");
+  assert.ok(!nativa.includes('recaptcha'));
+  assert.ok(nativa.includes("connect-src 'self' https://*.googleapis.com"));
+});
+
 test('arquivo listado ausente falha', async()=>{
   const falsa = await mkdtemp(join(tmpdir(), 'custta-raiz-'));
   await writeFile(join(falsa, 'sw.js'), "const ASSETS = ['./', './index.html', './falta.js'];");
diff --git a/tests/headers.test.cjs b/tests/headers.test.cjs
index b4714f2..6f43e22 100644
--- a/tests/headers.test.cjs
+++ b/tests/headers.test.cjs
@@ -10,7 +10,7 @@ const headers = Object.fromEntries(vercel.headers[0].headers.map(h => [h.key.toL
 
 assert.ok(headers['content-security-policy'], 'CSP ausente');
 assert.ok(!headers['content-security-policy'].includes('unsafe-inline'));
-assert.ok(!headers['content-security-policy'].includes('gstatic'));
+assert.ok(!/gstatic\.com(?!\/recaptcha\/)/.test(headers['content-security-policy']), 'gstatic só no caminho do reCAPTCHA');
 for(const nome of ['index.html','privacidade.html','app.js']){
   const texto=readFileSync(join(raiz,nome),'utf8');
   assert.ok(!/<style\b|\sstyle=/.test(texto), `${nome}: CSS inline`);
@@ -30,8 +30,9 @@ assert.ok(versaoHeaders, 'versao.json precisa de CORS para o app nativo');
 assert.deepStrictEqual(versaoHeaders.headers.find(h => h.key === 'Access-Control-Allow-Origin'), { key:'Access-Control-Allow-Origin', value:'capacitor://localhost' });
 
 const csp = headers['content-security-policy'];
-assert.ok(/script-src 'self' https:\/\/apis\.google\.com(;|$)/.test(csp), 'script-src do login com Google');
-assert.ok(csp.includes("frame-src 'self' https://app-construcao-civil.firebaseapp.com"), 'frame-src do login com Google');
+assert.ok(/script-src 'self' https:\/\/apis\.google\.com https:\/\/www\.google\.com\/recaptcha\/ https:\/\/www\.gstatic\.com\/recaptcha\/(;|$)/.test(csp), 'script-src do login com Google e do reCAPTCHA');
+assert.ok(/frame-src 'self' https:\/\/app-construcao-civil\.firebaseapp\.com https:\/\/www\.google\.com\/recaptcha\/ https:\/\/recaptcha\.google\.com\/recaptcha\/(;|$)/.test(csp), 'frame-src do login com Google e do reCAPTCHA');
+assert.ok(/connect-src [^;]* https:\/\/www\.google\.com\/recaptcha\/(;|$| )/.test(csp), 'connect-src do reCAPTCHA');
 const fonteApp = new RegExp('^' + vercel.headers[0].source + '$');
 assert.ok(fonteApp.test('/') && fonteApp.test('/index.html') && fonteApp.test('/privacidade.html'), 'CSP precisa cobrir o app');
 assert.ok(!fonteApp.test('/__/auth/handler') && !fonteApp.test('/__/firebase/init.json'), 'CSP do Custta não pode cobrir o handler do Firebase');
diff --git a/vercel.json b/vercel.json
index 82c7c0b..5368e55 100644
--- a/vercel.json
+++ b/vercel.json
@@ -12,7 +12,7 @@
       "headers": [
         {
           "key": "Content-Security-Policy",
-          "value": "default-src 'none'; script-src 'self' https://apis.google.com; connect-src 'self' https://o4512062092017664.ingest.us.sentry.io https://*.googleapis.com https://*.firebaseio.com wss://*.firebaseio.com; frame-src 'self' https://app-construcao-civil.firebaseapp.com; img-src 'self' data:; style-src 'self'; style-src-attr 'none'; font-src 'self'; manifest-src 'self'; worker-src 'self'; base-uri 'none'; object-src 'none'; frame-ancestors 'none'; form-action 'self'; upgrade-insecure-requests"
+          "value": "default-src 'none'; script-src 'self' https://apis.google.com https://www.google.com/recaptcha/ https://www.gstatic.com/recaptcha/; connect-src 'self' https://o4512062092017664.ingest.us.sentry.io https://*.googleapis.com https://*.firebaseio.com wss://*.firebaseio.com https://www.google.com/recaptcha/; frame-src 'self' https://app-construcao-civil.firebaseapp.com https://www.google.com/recaptcha/ https://recaptcha.google.com/recaptcha/; img-src 'self' data:; style-src 'self'; style-src-attr 'none'; font-src 'self'; manifest-src 'self'; worker-src 'self'; base-uri 'none'; object-src 'none'; frame-ancestors 'none'; form-action 'self'; upgrade-insecure-requests"
         },
         {
           "key": "X-Content-Type-Options",
````

- [ ] **Verificar**

````bash
npm run test:unit
````

- [ ] **Commit**

````bash
git add scripts/build-www.mjs tests/build-www.test.mjs tests/headers.test.cjs vercel.json
git commit -F - <<'FIM'
feat: CSP aceita o reCAPTCHA do App Check no site

O App Check do site carrega o script do reCAPTCHA Enterprise e abre o iframe dele, então a CSP passa a aceitar os caminhos documentados pelo Google em script-src, frame-src e connect-src; a troca do token já estava coberta pelo googleapis. O app nativo não usa o reCAPTCHA, então o build do www tira esses endereços da CSP dele. O teste dos cabeçalhos fixa os novos valores e só deixa o gstatic no caminho do reCAPTCHA.
FIM
````

### Tarefa 11: feat: App Check do site só observando, nos endereços publicados

**Arquivos:** `cloud.js`, `tests/browser/app-check.cjs` (novo), `tests/browser/rodar.cjs`, `tests/helpers/firebase-stub.mjs`

Escreva a suíte primeiro. Antes do `cloud.js`, `node tests/browser/app-check.cjs` (com `node tests/browser/servidor.cjs` no ar) cai com **"não pediu o script do reCAPTCHA"** (0 `ok`). Mutações que a suíte pega: sem a guarda de endereço (`http://127.0.0.1:8123/` pediu o reCAPTCHA); sem `initializeAppCheck`; provedor sem prazo (TimeoutError em entrar, script bloqueado). `CHAVE_RECAPTCHA_DO_SITE` é trocada pelo valor real do G9 antes do merge, num lugar só.

- [ ] **Aplicar**

````diff
diff --git a/cloud.js b/cloud.js
index a37890c..915ddbb 100644
--- a/cloud.js
+++ b/cloud.js
@@ -2,6 +2,7 @@
    Expõe window.CLOUD pros scripts clássicos (auth.js, app.js).
    As chaves abaixo são públicas; a segurança vem das rules do Firestore. */
 import { initializeApp } from './vendor/firebase/firebase-app.js';
+import { initializeAppCheck, ReCaptchaEnterpriseProvider } from './vendor/firebase/firebase-app-check.js';
 import {
   getAuth, onAuthStateChanged, createUserWithEmailAndPassword,
   signInWithEmailAndPassword, sendPasswordResetEmail, signOut, getIdToken,
@@ -33,7 +34,46 @@ const firebaseConfig = {
    idToken porque o client é do mesmo projeto (111188093030). */
 const GOOGLE_CLIENT_ID_WEB = '111188093030-76cph7rdbibirr8l61jn72r3i3f92e8u.apps.googleusercontent.com';
 
+/* Chave pública do reCAPTCHA Enterprise do site. */
+const CHAVE_RECAPTCHA = 'CHAVE_RECAPTCHA_DO_SITE';
+
+/* O App Check só observa, e só nos endereços publicados: em 127.0.0.1, em
+   localhost e no WKWebView (capacitor://localhost) ele não liga. */
+function enderecoPublicado(){
+  const host = globalThis.location?.hostname || '';
+  return host === 'custta.com.br' || host.endsWith('.vercel.app');
+}
+
+/* O SDK não trata falha no carregamento do script do reCAPTCHA: se ele não chega
+   (bloqueador, rede filtrada, app aberto sem internet), getToken nunca responde e
+   o Auth e o Firestore esperam para sempre pelo token. Com prazo, a falha vira um
+   erro que o SDK já absorve: o pedido sai com o token de erro dele, o App Check só
+   observa, e a próxima tentativa funciona quando o reCAPTCHA chegar. Uma tentativa
+   por vez, com o mesmo prazo para quem chegar depois: bloqueado, só o primeiro espera. */
+const PRAZO_RECAPTCHA = 4000;
+class ProvedorReCaptcha extends ReCaptchaEnterpriseProvider {
+  #emVoo = null;
+  #inicio = 0;
+  getToken(){
+    /* Sem rede o script não chega: o prazo só deixaria a tela de login à vista por 4 s
+       antes do dado em cache aparecer. onLine verdadeiro não garante rede; aí vale o prazo. */
+    if(navigator.onLine === false) return Promise.reject(new Error('reCAPTCHA sem rede'));
+    if(!this.#emVoo){
+      this.#inicio = Date.now();
+      this.#emVoo = super.getToken().finally(()=>{ this.#emVoo = null; });
+    }
+    const resta = Math.max(0, this.#inicio + PRAZO_RECAPTCHA - Date.now());
+    return Promise.race([this.#emVoo, new Promise((_, falha)=>{ setTimeout(falha, resta, new Error('reCAPTCHA sem resposta')); })]);
+  }
+}
+
 const app = initializeApp(firebaseConfig);
+if(enderecoPublicado()){
+  initializeAppCheck(app, {
+    provider: new ProvedorReCaptcha(CHAVE_RECAPTCHA),
+    isTokenAutoRefreshEnabled: true,
+  });
+}
 const auth = getAuth(app);
 /* Qual botão mandou para o redirect: o erro na volta diz "Apple" ou "Google". */
 const CHAVE_REDIRECT = 'custta-redirect';
diff --git a/tests/browser/app-check.cjs b/tests/browser/app-check.cjs
new file mode 100644
index 0000000..17ae5be
--- /dev/null
+++ b/tests/browser/app-check.cjs
@@ -0,0 +1,227 @@
+/* App Check do site, só observando. Tudo falso por route, sem rede e sem
+   emulador: o site sai dos arquivos locais em hosts falsos, com a CSP real do
+   vercel.json; o reCAPTCHA é um script de mentira, o Auth responde pronto e o
+   Firestore fala por um WebChannel falso. Em 127.0.0.1 e localhost a página vem
+   do servidor.cjs, que precisa estar no ar na 8123 (o rodar.cjs sobe).
+   Uso: node tests/browser/app-check.cjs */
+const assert=require('node:assert/strict');
+const fs=require('node:fs');
+const path=require('node:path');
+const {chromium}=require('playwright');
+
+const RAIZ=path.resolve(__dirname,'../..');
+const CABECALHOS=Object.fromEntries(require('../../vercel.json').headers[0].headers.map(h=>[h.key,h.value]));
+const TIPOS={'.html':'text/html','.js':'text/javascript','.json':'application/json','.css':'text/css','.svg':'image/svg+xml','.png':'image/png','.woff2':'font/woff2'};
+const TOKEN_RECAPTCHA='recaptcha-falso';
+const TOKEN_APP_CHECK='app-check-falso';
+const UID='uid-falso';
+const HORA='2026-11-09T12:00:00.000000Z';
+const MARCA='dG9rZW4=';
+const CAMPOS={
+  obras:{arrayValue:{values:[{mapValue:{fields:{
+    id:{stringValue:'o1'},nome:{stringValue:'Obra do falso'},fase:{stringValue:'construcao'},
+    dataInicio:{stringValue:'2026-01-01'},gastos:{arrayValue:{}},
+  }}}]}},
+  config:{mapValue:{fields:{taxaMensal:{doubleValue:1}}}},
+};
+const SCRIPT_RECAPTCHA=`window.grecaptcha={enterprise:{
+  ready(cb){cb();},
+  render(_el,o){window.__retornoRecaptcha=o.callback;return 0;},
+  execute(){window.__retornoRecaptcha();return Promise.resolve('${TOKEN_RECAPTCHA}');},
+}};`;
+const cors=rota=>({'access-control-allow-origin':rota.request().headers().origin||'*','access-control-allow-credentials':'true'});
+const json=(rota,corpo)=>rota.fulfill({status:200,headers:{...cors(rota),'content-type':'application/json'},body:JSON.stringify(corpo)});
+function jwt(){
+  const b=o=>Buffer.from(JSON.stringify(o)).toString('base64url');
+  const agora=Math.floor(Date.now()/1000);
+  return `${b({alg:'none'})}.${b({sub:UID,user_id:UID,iat:agora,exp:agora+3600,email:'ana@example.com'})}.x`;
+}
+function servirSite(rota,url){
+  const rel=url.pathname==='/'?'/index.html':decodeURIComponent(url.pathname);
+  if(rel==='/sentry-config.js') return rota.fulfill({status:200,headers:{...CABECALHOS,'content-type':'text/javascript'},body:'window.CUSTTA_SENTRY_CONFIG={dsn:""};'});
+  const arq=path.join(RAIZ,rel);
+  if(!arq.startsWith(RAIZ+path.sep)||!fs.existsSync(arq)||fs.statSync(arq).isDirectory()) return rota.fulfill({status:404,body:'nao achei'});
+  return rota.fulfill({status:200,headers:{...CABECALHOS,'content-type':TIPOS[path.extname(arq)]||'application/octet-stream'},body:fs.readFileSync(arq)});
+}
+function responderAuth(rota,r){
+  const url=rota.request().url();
+  r.auth.push(rota.request().headers()['x-firebase-appcheck']);
+  if(url.includes('accounts:signInWithPassword')) return json(rota,{localId:UID,email:'ana@example.com',idToken:jwt(),refreshToken:'r',expiresIn:'3600',registered:true});
+  if(url.includes('accounts:lookup')) return json(rota,{users:[{localId:UID,email:'ana@example.com',emailVerified:true,passwordHash:'x',providerUserInfo:[{providerId:'password',federatedId:'ana@example.com',email:'ana@example.com'}],validSince:'1',lastLoginAt:'1',createdAt:'1'}]});
+  if(url.includes('securetoken')) return json(rota,{access_token:jwt(),expires_in:'3600',token_type:'Bearer',refresh_token:'r',id_token:jwt(),user_id:UID,project_id:'app-construcao-civil'});
+  return json(rota,{});
+}
+/* WebChannel falso: o POST de abertura devolve o handshake e entrega os cabeçalhos
+   no corpo (campo headers, sem preflight); as mensagens saem pelo back channel, o
+   GET longo, sempre em quadros "tamanho\njson\n". */
+function criarFirestore(r){
+  const canais=new Map();
+  let contador=0;
+  const quadro=o=>{ const t=JSON.stringify(o)+'\n'; return `${t.length}\n${t}`; };
+  const texto=(rota,corpo)=>rota.fulfill({status:200,headers:{...cors(rota),'content-type':'text/plain'},body:corpo});
+  function solta(c){
+    if(!c.pendente||!c.fila.length) return;
+    const rota=c.pendente; c.pendente=null;
+    texto(rota,quadro(c.fila.splice(0)));
+  }
+  function envia(c,msg){ c.fila.push([++c.ultimo,[msg]]); solta(c); }
+  function aoListen(c,msg){
+    const alvo=msg.addTarget;
+    if(!alvo) return;
+    const nome=alvo.documents.documents[0];
+    envia(c,{targetChange:{targetChangeType:'ADD',targetIds:[alvo.targetId]}});
+    if(nome.includes('/dados/')) envia(c,{documentChange:{document:{name:nome,fields:CAMPOS,createTime:HORA,updateTime:HORA},targetIds:[alvo.targetId]}});
+    else envia(c,{documentDelete:{document:nome,removedTargetIds:[alvo.targetId],readTime:HORA}});
+    envia(c,{targetChange:{targetChangeType:'CURRENT',targetIds:[alvo.targetId],resumeToken:MARCA,readTime:HORA}});
+    envia(c,{targetChange:{targetChangeType:'NO_CHANGE',targetIds:[],resumeToken:MARCA,readTime:HORA}});
+  }
+  function aoWrite(c,msg){
+    if(!msg.writes){ envia(c,{streamId:'s',streamToken:MARCA}); return; }
+    r.escritas.push(...msg.writes);
+    envia(c,{streamToken:MARCA,writeResults:msg.writes.map(()=>({updateTime:HORA})),commitTime:HORA});
+  }
+  return rota=>{
+    const pedido=rota.request(), url=new URL(pedido.url());
+    const tipo=url.pathname.includes('/Write/')?'Write':'Listen';
+    if(pedido.method()!=='POST'){
+      const c=canais.get(url.searchParams.get('SID'));
+      if(!c||url.searchParams.get('TYPE')==='terminate') return texto(rota,'');
+      c.pendente=rota; solta(c);
+      return;
+    }
+    const corpo=new URLSearchParams(pedido.postData()||'');
+    let c=canais.get(url.searchParams.get('SID'));
+    const abertura=!c;
+    if(abertura){
+      c={sid:'sessao'+(++contador),fila:[],ultimo:0,pendente:null};
+      canais.set(c.sid,c);
+      r.abertura[tipo].push(corpo.get('headers')||'');
+    }
+    for(let i=0;i<Number(corpo.get('count')||0);i++) (tipo==='Listen'?aoListen:aoWrite)(c,JSON.parse(corpo.get(`req${i}___data__`)));
+    return texto(rota,quadro(abertura?[[0,['c',c.sid,'',8,12,30000]]]:[1,c.ultimo,0]));
+  };
+}
+/* Contexto com os falsos. Quem não tem falso e sai de onde não devia cai em r.fora;
+   o gapi do login social (apis.google.com) não interessa aqui e é só abortado. */
+async function contexto(browser,hostsFalsos,{reCaptcha='responde'}={}){
+  const ctx=await browser.newContext({serviceWorkers:'block',viewport:{width:390,height:844}});
+  const r={script:[],troca:[],auth:[],abertura:{Listen:[],Write:[]},escritas:[],violacoes:[],erros:[],fora:[]};
+  await ctx.exposeBinding('__registraCSP',(_s,v)=>r.violacoes.push(v));
+  await ctx.addInitScript(()=>{
+    sessionStorage.setItem('splashVista','1');
+    addEventListener('securitypolicyviolation',e=>window.__registraCSP(e.violatedDirective+': '+e.blockedURI));
+  });
+  await ctx.route(()=>true,rota=>{
+    const url=new URL(rota.request().url());
+    if(hostsFalsos.includes(url.hostname)) return servirSite(rota,url);
+    if(['localhost','127.0.0.1'].includes(url.hostname)&&url.port==='8123') return rota.continue();
+    if(url.hostname!=='apis.google.com') r.fora.push(url.href);
+    return rota.abort();
+  });
+  await ctx.route(/^https:\/\/www\.google\.com\/recaptcha\//,rota=>{
+    r.script.push(rota.request().url());
+    if(reCaptcha==='aborta') return rota.abort();
+    return rota.fulfill({status:200,headers:{'content-type':'text/javascript'},body:SCRIPT_RECAPTCHA});
+  });
+  await ctx.route(/^https:\/\/content-firebaseappcheck\.googleapis\.com\//,rota=>{
+    r.troca.push({url:rota.request().url(),corpo:rota.request().postData()||''});
+    return json(rota,{token:TOKEN_APP_CHECK,ttl:'3600s'});
+  });
+  await ctx.route(/^https:\/\/(identitytoolkit|securetoken)\.googleapis\.com\//,rota=>responderAuth(rota,r));
+  await ctx.route(/^https:\/\/firestore\.googleapis\.com\//,criarFirestore(r));
+  return {ctx,r};
+}
+async function abrir(ctx,r,endereco){
+  const page=await ctx.newPage();
+  page.setDefaultTimeout(15000);
+  page.on('pageerror',e=>r.erros.push(e.message));
+  await page.goto(endereco);
+  await page.waitForFunction(()=>window.CLOUD);
+  await page.evaluate(()=>CLOUD.ready);
+  return page;
+}
+async function ate(cond,rotulo){
+  const fim=Date.now()+15000;
+  while(!cond()){
+    if(Date.now()>fim) assert.fail(rotulo);
+    await new Promise(res=>setTimeout(res,50));
+  }
+}
+/* Entrar pela tela, ver o dado do servidor falso chegar e gravar uma mudança. */
+async function entrarESincronizar(page,r){
+  await page.waitForSelector('#fLogin',{state:'visible'});
+  await page.fill('#lEmail','ana@example.com');
+  await page.fill('#lSenha','Obra2026x');
+  await page.click('#fLogin button[type=submit]');
+  await page.waitForFunction(()=>!document.body.classList.contains('locked'));
+  await page.waitForFunction(()=>db.obras.some(o=>o.nome==='Obra do falso'));
+  await page.evaluate(()=>{ db.obras[0].nome='Obra alterada'; save(); });
+  await ate(()=>r.escritas.some(e=>JSON.stringify(e).includes('Obra alterada')),'a escrita não chegou ao Firestore falso');
+  await page.waitForFunction(()=>CLOUD.estado()==='ocioso');
+}
+const semIncidentes=r=>{
+  assert.deepEqual(r.violacoes,[],'violação de CSP');
+  assert.deepEqual(r.erros,[],'erro de página');
+  assert.deepEqual(r.fora,[],'pedido fora dos falsos');
+};
+/* No WebChannel o cabeçalho vai no corpo do POST, em minúsculas. */
+const tokenDaAbertura=h=>/(?:^|\r\n)x-firebase-appcheck:([^\r\n]*)/i.exec(h)?.[1];
+
+(async()=>{
+  const browser=await chromium.launch();
+  try{
+    /* 1. Endereço publicado: pede o script, troca o token e o Firestore e o Auth levam o token. */
+    {
+      const {ctx,r}=await contexto(browser,['custta.com.br']);
+      const page=await abrir(ctx,r,'https://custta.com.br/');
+      await entrarESincronizar(page,r);
+      assert.ok(r.script.length>0,'não pediu o script do reCAPTCHA');
+      assert.match(r.script[0],/^https:\/\/www\.google\.com\/recaptcha\/enterprise\.js/);
+      await ate(()=>r.troca.length>0,'não trocou o token do App Check');
+      assert.equal(r.troca.length,1,'uma troca só');
+      assert.ok(r.troca[0].url.includes('exchangeRecaptchaEnterpriseToken'),r.troca[0].url);
+      assert.ok(r.troca[0].corpo.includes(TOKEN_RECAPTCHA),'o token do reCAPTCHA vai na troca');
+      assert.ok(r.abertura.Listen.length>0,'abriu o Listen');
+      assert.ok(r.abertura.Listen.every(h=>tokenDaAbertura(h)===TOKEN_APP_CHECK),'Listen sem o token do App Check');
+      assert.ok(r.abertura.Write.some(h=>tokenDaAbertura(h)===TOKEN_APP_CHECK),'Write sem o token do App Check');
+      assert.ok(r.auth.length>0&&r.auth.every(t=>t===TOKEN_APP_CHECK),'Auth sem o token do App Check');
+      semIncidentes(r);
+      console.log('ok - custta.com.br pede o reCAPTCHA, troca o token e Firestore e Auth levam o X-Firebase-AppCheck');
+      await ctx.close();
+    }
+    /* 2. Outros endereços publicados também ligam. */
+    for(const host of ['app-construcao-civil.vercel.app','app-construcao-civil-git-proto-b4-gstuchi.vercel.app']){
+      const {ctx,r}=await contexto(browser,[host]);
+      await abrir(ctx,r,`https://${host}/`);
+      assert.ok(r.script.length>0,`${host} não pediu o script do reCAPTCHA`);
+      semIncidentes(r);
+      console.log(`ok - ${host} liga o App Check`);
+      await ctx.close();
+    }
+    /* 3. Endereços não publicados não ligam, nem os parecidos com os publicados. */
+    for(const endereco of ['http://127.0.0.1:8123/','http://localhost:8123/','https://custta.com.br.exemplo.net/','https://falso-vercel.app.exemplo.net/']){
+      const url=new URL(endereco);
+      const {ctx,r}=await contexto(browser,url.port?[]:[url.hostname]);
+      const page=await abrir(ctx,r,endereco);
+      await entrarESincronizar(page,r);
+      assert.deepEqual(r.script,[],`${endereco} pediu o reCAPTCHA`);
+      assert.deepEqual(r.troca,[],`${endereco} trocou token`);
+      assert.ok(r.abertura.Listen.length>0,'abriu o Listen');
+      assert.ok(!r.abertura.Listen.some(tokenDaAbertura),`${endereco}: o Listen levou token`);
+      semIncidentes(r);
+      console.log(`ok - ${url.host} não liga o App Check e entra e sincroniza`);
+      await ctx.close();
+    }
+    /* 4. Script do reCAPTCHA bloqueado: entrar e sincronizar seguem, sem token e sem erro novo. */
+    {
+      const {ctx,r}=await contexto(browser,['custta.com.br'],{reCaptcha:'aborta'});
+      const page=await abrir(ctx,r,'https://custta.com.br/');
+      await entrarESincronizar(page,r);
+      assert.ok(r.script.length>0,'não tentou carregar o script');
+      assert.deepEqual(r.troca,[],'não pode trocar token sem o reCAPTCHA');
+      semIncidentes(r);
+      console.log('ok - script do reCAPTCHA bloqueado: entrar e sincronizar seguem, sem erro de página');
+      await ctx.close();
+    }
+  }finally{ await browser.close(); }
+})().catch(e=>{console.error(e);process.exitCode=1;});
diff --git a/tests/browser/rodar.cjs b/tests/browser/rodar.cjs
index 9c446d4..37ba0a1 100644
--- a/tests/browser/rodar.cjs
+++ b/tests/browser/rodar.cjs
@@ -35,5 +35,6 @@ const run=(file,args=[])=>new Promise((resolve,reject)=>{
     await run('tests/browser/cadastro.cjs');
     await run('tests/browser/google.cjs');
     await run('tests/browser/apple.cjs');
+    await run('tests/browser/app-check.cjs');
   }finally{server.kill();}
 })().catch(e=>{console.error(e);process.exitCode=1;});
diff --git a/tests/helpers/firebase-stub.mjs b/tests/helpers/firebase-stub.mjs
index 3a6ecb7..987da78 100644
--- a/tests/helpers/firebase-stub.mjs
+++ b/tests/helpers/firebase-stub.mjs
@@ -22,6 +22,10 @@ export const __ctrl = {
 };
 
 export function initializeApp(config){ __ctrl.config = config; return { nome: 'stub' }; }
+export function initializeAppCheck(){ return { nome: 'app-check-stub' }; }
+export class ReCaptchaEnterpriseProvider{
+  getToken(){ return Promise.resolve({ token:'app-check-teste', expireTimeMillis:0 }); }
+}
 export function getAuth(){ return { nome: 'auth-stub', currentUser:{ uid:'u-teste', email:'teste@exemplo.com' } }; }
 export function getIdToken(){ return __ctrl.token; }
 export const EmailAuthProvider = { credential:(email,senha)=>({email,senha}) };
````

- [ ] **Verificar**

````bash
npm run test:unit
````

- [ ] **Commit**

````bash
git add cloud.js tests/browser/app-check.cjs tests/browser/rodar.cjs tests/helpers/firebase-stub.mjs
git commit -F - <<'FIM'
feat: App Check do site só observando, nos endereços publicados

O site passa a pedir o token do App Check pelo reCAPTCHA Enterprise antes de abrir o Auth e o Firestore, só em custta.com.br e nos endereços da Vercel, para que os testes locais e o app nativo sigam como estão. Nada exige o token ainda: ele só alimenta a observação no console.

O SDK não trata erro no carregamento do script do reCAPTCHA, e sem ele o getToken nunca responde: o login fica 30 segundos parado e termina em "sem internet", e o Firestore nunca abre. Por isso o provedor usa a mesma classe com um prazo de 4 segundos, por tentativa, com um único pedido por vez. Vencido o prazo, o pedido sai com o token de erro do SDK e a próxima tentativa volta a valer quando o reCAPTCHA chegar. A suíte app-check prova o caminho feliz, a guarda de endereço e o script bloqueado, com tudo falso por route e a CSP real.
FIM
````

### Tarefa 12: feat: selo do reCAPTCHA escondido e aviso na tela de login

**Arquivos:** `index.html`, `privacidade.html`, `styles.css`

Prints de referência: `web-prints/login-*.png` no clone. Conferir 390 e 1280 de largura, nos dois temas.

- [ ] **Aplicar**

````diff
diff --git a/index.html b/index.html
index 309b41f..49efc55 100644
--- a/index.html
+++ b/index.html
@@ -138,6 +138,7 @@
             <button class="linklike" type="button" id="pOutra">Usar outra conta</button>
           </form>
           <p class="layout-20"><a class="layout-21" href="privacidade.html">Política de Privacidade</a></p>
+          <p class="auth-recaptcha">Este site é protegido pelo reCAPTCHA.</p>
         </div>
       </div>
     </div>
diff --git a/privacidade.html b/privacidade.html
index 9327062..cb0662e 100644
--- a/privacidade.html
+++ b/privacidade.html
@@ -41,6 +41,7 @@
 
   <h2>4. Armazenamento e fornecedores</h2>
   <p>O aplicativo utiliza armazenamento local no dispositivo e serviços de nuvem para autenticação e sincronização. A infraestrutura pode envolver <strong>Google Firebase</strong> e <strong>Vercel</strong>, que tratam dados conforme seus próprios termos e medidas de segurança. O acesso aos dados de cada conta é isolado por regras de autorização.</p>
+  <p>O site usa o <strong>reCAPTCHA</strong> do Google para barrar acesso automatizado, e o Google trata os dados dessa verificação conforme seus próprios termos.</p>
   <p>Você pode entrar com e-mail e senha, com sua conta Google ou com sua conta Apple. Ao entrar com a Apple, recebemos da Apple um identificador da conta, o e-mail — que pode ser um endereço de retransmissão terminado em <strong>@privaterelay.appleid.com</strong>, se você escolher ocultar seu e-mail — e, no primeiro acesso, o nome que você autorizar. Ao apagar a conta, também pedimos à Apple que desfaça a ligação com o Custta.</p>
 
   <p>Quando o monitoramento está configurado, utilizamos <strong>Sentry</strong> para receber diagnósticos técnicos de falhas: categoria do erro, versão do aplicativo, horário e arquivo/linha do código. Mensagens livres, dados das obras, e-mail, identificador da conta, cookies, parâmetros de URL e histórico de cliques não são incluídos nos eventos. Não usamos gravação de sessão (replay) nem rastreamento de desempenho. O serviço recebe a conexão de rede, incluindo endereço IP para transporte; a integração substitui o IP do evento pelo valor fixo 0.0.0.0 para impedir identificação e geolocalização no diagnóstico. O diagnóstico local mantém até 20 erros em memória e é descartado ao fechar ou recarregar a página.</p>
diff --git a/styles.css b/styles.css
index 9fcfdfa..b39a684 100644
--- a/styles.css
+++ b/styles.css
@@ -827,6 +827,10 @@ body .layout-18{width:22px;height:60px;animation-delay:1.62s}
 body .layout-19{width:100%}
 body .layout-20{text-align:center;margin-top:14px;font-size:13px}
 body .layout-21{color:var(--muted)}
+/* Selo do reCAPTCHA escondido: no lugar dele, o texto da tela de login. O app nativo não usa o reCAPTCHA. */
+.grecaptcha-badge{visibility:hidden}
+body .auth-recaptcha{text-align:center;margin-top:6px;font-size:12px;color:var(--muted)}
+html.nativo .auth-recaptcha{display:none}
 body .layout-22{display:flex;align-items:center}
 body .layout-23{width:100%;margin-top:12px}
 body .layout-24{display:flex;gap:16px;justify-content:center;margin-top:10px;font-size:12.5px;color:var(--muted)}
````

- [ ] **Verificar**

````bash
npm run test:unit
````

- [ ] **Commit**

````bash
git add index.html privacidade.html styles.css
git commit -F - <<'FIM'
feat: selo do reCAPTCHA escondido e aviso na tela de login

O selo flutuante do reCAPTCHA não combina com a tela de login, então o CSS o esconde e a própria tela passa a dizer que o site é protegido pelo reCAPTCHA, sem aparecer no app nativo, que não usa o reCAPTCHA. A política de privacidade ganha uma frase explicando que o reCAPTCHA do Google barra acesso automatizado.
FIM
````

### Tarefa 13: test: abrir sem rede e reCAPTCHA lento na suíte do App Check

**Arquivos:** `tests/browser/app-check.cjs`

Sem a linha `navigator.onLine` do provedor, o teste cai com **"a obra levou 4058 ms para aparecer sem rede"**. Sem rede: cerca de 58 ms, com token vencido ou válido. reCAPTCHA lento: login destrava em 3,99 s.

- [ ] **Aplicar**

````diff
diff --git a/tests/browser/app-check.cjs b/tests/browser/app-check.cjs
index 17ae5be..31cbed1 100644
--- a/tests/browser/app-check.cjs
+++ b/tests/browser/app-check.cjs
@@ -16,6 +16,7 @@ const TOKEN_RECAPTCHA='recaptcha-falso';
 const TOKEN_APP_CHECK='app-check-falso';
 const UID='uid-falso';
 const HORA='2026-11-09T12:00:00.000000Z';
+const HORA_ESCRITA='2026-11-09T12:00:01.000000Z';
 const MARCA='dG9rZW4=';
 const CAMPOS={
   obras:{arrayValue:{values:[{mapValue:{fields:{
@@ -78,7 +79,8 @@ function criarFirestore(r){
   function aoWrite(c,msg){
     if(!msg.writes){ envia(c,{streamId:'s',streamToken:MARCA}); return; }
     r.escritas.push(...msg.writes);
-    envia(c,{streamToken:MARCA,writeResults:msg.writes.map(()=>({updateTime:HORA})),commitTime:HORA});
+    /* Hora depois da do documento e o serverTimestamp respondido: só assim o SDK grava a escrita no cache. */
+    envia(c,{streamToken:MARCA,writeResults:msg.writes.map(w=>({updateTime:HORA_ESCRITA,transformResults:(w.updateTransforms||[]).map(()=>({timestampValue:HORA_ESCRITA}))})),commitTime:HORA_ESCRITA});
   }
   return rota=>{
     const pedido=rota.request(), url=new URL(pedido.url());
@@ -105,7 +107,8 @@ function criarFirestore(r){
    o gapi do login social (apis.google.com) não interessa aqui e é só abortado. */
 async function contexto(browser,hostsFalsos,{reCaptcha='responde'}={}){
   const ctx=await browser.newContext({serviceWorkers:'block',viewport:{width:390,height:844}});
-  const r={script:[],troca:[],auth:[],abertura:{Listen:[],Write:[]},escritas:[],violacoes:[],erros:[],fora:[]};
+  const r={script:[],troca:[],auth:[],abertura:{Listen:[],Write:[]},escritas:[],violacoes:[],erros:[],fora:[],scriptEntregue:false};
+  r.atrasoDoScript=new Promise(solta=>{ r.soltaScript=solta; });
   await ctx.exposeBinding('__registraCSP',(_s,v)=>r.violacoes.push(v));
   await ctx.addInitScript(()=>{
     sessionStorage.setItem('splashVista','1');
@@ -118,9 +121,10 @@ async function contexto(browser,hostsFalsos,{reCaptcha='responde'}={}){
     if(url.hostname!=='apis.google.com') r.fora.push(url.href);
     return rota.abort();
   });
-  await ctx.route(/^https:\/\/www\.google\.com\/recaptcha\//,rota=>{
+  await ctx.route(/^https:\/\/www\.google\.com\/recaptcha\//,async rota=>{
     r.script.push(rota.request().url());
     if(reCaptcha==='aborta') return rota.abort();
+    if(reCaptcha==='lento'){ await r.atrasoDoScript; r.scriptEntregue=true; }
     return rota.fulfill({status:200,headers:{'content-type':'text/javascript'},body:SCRIPT_RECAPTCHA});
   });
   await ctx.route(/^https:\/\/content-firebaseappcheck\.googleapis\.com\//,rota=>{
@@ -131,11 +135,11 @@ async function contexto(browser,hostsFalsos,{reCaptcha='responde'}={}){
   await ctx.route(/^https:\/\/firestore\.googleapis\.com\//,criarFirestore(r));
   return {ctx,r};
 }
-async function abrir(ctx,r,endereco){
+async function abrir(ctx,r,endereco,waitUntil='load'){
   const page=await ctx.newPage();
   page.setDefaultTimeout(15000);
   page.on('pageerror',e=>r.erros.push(e.message));
-  await page.goto(endereco);
+  await page.goto(endereco,{waitUntil});
   await page.waitForFunction(()=>window.CLOUD);
   await page.evaluate(()=>CLOUD.ready);
   return page;
@@ -148,10 +152,13 @@ async function ate(cond,rotulo){
   }
 }
 /* Entrar pela tela, ver o dado do servidor falso chegar e gravar uma mudança. */
-async function entrarESincronizar(page,r){
+async function preencherLogin(page){
   await page.waitForSelector('#fLogin',{state:'visible'});
   await page.fill('#lEmail','ana@example.com');
   await page.fill('#lSenha','Obra2026x');
+}
+async function entrarESincronizar(page,r){
+  await preencherLogin(page);
   await page.click('#fLogin button[type=submit]');
   await page.waitForFunction(()=>!document.body.classList.contains('locked'));
   await page.waitForFunction(()=>db.obras.some(o=>o.nome==='Obra do falso'));
@@ -159,6 +166,35 @@ async function entrarESincronizar(page,r){
   await ate(()=>r.escritas.some(e=>JSON.stringify(e).includes('Obra alterada')),'a escrita não chegou ao Firestore falso');
   await page.waitForFunction(()=>CLOUD.estado()==='ocioso');
 }
+/* Sem rede: navigator.onLine falso e todo o Google abortado (a rota mais nova vale
+   primeiro). O site segue vindo do route, no lugar do service worker. */
+async function tirarARede(ctx){
+  await ctx.setOffline(true);
+  await ctx.route(/^https:\/\/([^/]+\.)?(google|googleapis|gstatic)\.com\//,rota=>rota.abort());
+}
+/* Recarrega e devolve os ms, desde o início da navegação, até a obra estar na tela destravada. */
+async function recarregarEMedir(page,nome){
+  await page.reload();
+  const marca=await page.waitForFunction(n=>!document.body.classList.contains('locked')&&document.body.innerText.includes(n)&&performance.now(),nome);
+  return Math.round(await marca.jsonValue());
+}
+/* Deixa vencido o token do App Check guardado, como depois de uma hora sem abrir o app. Devolve quantos achou. */
+const vencerTokenGuardado=page=>page.evaluate(()=>new Promise((pronto,falha)=>{
+  const aberto=indexedDB.open('firebase-app-check-database');
+  aberto.onerror=()=>falha(aberto.error);
+  aberto.onsuccess=()=>{
+    const banco=aberto.result, tx=banco.transaction('firebase-app-check-store','readwrite'), cursor=tx.objectStore('firebase-app-check-store').openCursor();
+    let achados=0;
+    cursor.onsuccess=()=>{
+      const c=cursor.result;
+      if(!c) return;
+      c.update({...c.value,value:{...c.value.value,expireTimeMillis:Date.now()-1000}});
+      achados++; c.continue();
+    };
+    tx.oncomplete=()=>{ banco.close(); pronto(achados); };
+    tx.onerror=()=>falha(tx.error);
+  };
+}));
 const semIncidentes=r=>{
   assert.deepEqual(r.violacoes,[],'violação de CSP');
   assert.deepEqual(r.erros,[],'erro de página');
@@ -223,5 +259,50 @@ const tokenDaAbertura=h=>/(?:^|\r\n)x-firebase-appcheck:([^\r\n]*)/i.exec(h)?.[1
       console.log('ok - script do reCAPTCHA bloqueado: entrar e sincronizar seguem, sem erro de página');
       await ctx.close();
     }
+    /* 5. Sem rede, com dado em cache: a obra aparece na hora, com o token do App Check
+       guardado válido ou vencido (o normal depois de uma hora): vencido, o provedor
+       desiste sem esperar o prazo. */
+    for(const vencido of [false,true]){
+      const {ctx,r}=await contexto(browser,['custta.com.br']);
+      const page=await abrir(ctx,r,'https://custta.com.br/');
+      await entrarESincronizar(page,r);
+      if(vencido) assert.ok(await vencerTokenGuardado(page)>0,'não achou o token guardado');
+      await tirarARede(ctx);
+      const ms=await recarregarEMedir(page,'Obra alterada');
+      assert.ok(ms<1000,`a obra levou ${ms} ms para aparecer sem rede`);
+      /* Sem rede, o WebChannel testa a conexão com um pixel do Google, que o img-src barra (com ou sem App Check). */
+      r.violacoes=r.violacoes.filter(v=>!v.startsWith('img-src: https://www.google.com/images/cleardot.gif'));
+      semIncidentes(r);
+      console.log(`ok - sem rede, token ${vencido?'vencido':'válido'}: a obra em cache aparece em ${ms} ms`);
+      await ctx.close();
+    }
+    /* 6. reCAPTCHA lento: o script chega 8 s depois do clique. O login destrava no prazo,
+       antes dele, e o pedido seguinte já leva token válido: o prazo não prende o token. */
+    {
+      const {ctx,r}=await contexto(browser,['custta.com.br'],{reCaptcha:'lento'});
+      /* O load espera o script injetado; aqui ele só chega depois do clique. O prazo conta
+         do primeiro pedido de token, que o App Check faz logo na abertura, não do clique. */
+      const aberto=Date.now();
+      const page=await abrir(ctx,r,'https://custta.com.br/','domcontentloaded');
+      await preencherLogin(page);
+      const inicio=Date.now();
+      setTimeout(r.soltaScript,8000);
+      await page.click('#fLogin button[type=submit]');
+      await page.waitForFunction(()=>!document.body.classList.contains('locked'));
+      const ms=Date.now()-inicio;
+      assert.ok(!r.scriptEntregue,'o login esperou o script chegar');
+      assert.ok(Date.now()-aberto>=3900&&ms<6000,`o login destravou em ${ms} ms`);
+      assert.deepEqual(r.troca,[],'trocou token antes do script chegar');
+      assert.ok(r.auth.length>0&&!r.auth.includes(TOKEN_APP_CHECK),'o login não podia ter token válido');
+      await page.waitForFunction(()=>db.obras.some(o=>o.nome==='Obra do falso'));
+      await ate(()=>r.troca.length>0,'não trocou o token depois que o script chegou');
+      await page.waitForTimeout(300); // o provedor só solta a tentativa em voo depois da resposta da troca
+      await page.evaluate(()=>{ db.obras[0].nome='Obra alterada'; save(); });
+      await ate(()=>r.escritas.some(e=>JSON.stringify(e).includes('Obra alterada')),'a escrita não chegou ao Firestore falso');
+      assert.ok(r.abertura.Write.some(h=>tokenDaAbertura(h)===TOKEN_APP_CHECK),'o pedido seguinte não levou o token válido');
+      semIncidentes(r);
+      console.log(`ok - reCAPTCHA lento: login destrava em ${ms} ms e o pedido seguinte leva token válido`);
+      await ctx.close();
+    }
   }finally{ await browser.close(); }
 })().catch(e=>{console.error(e);process.exitCode=1;});
````

- [ ] **Verificar**

````bash
npm run test:unit
````

- [ ] **Commit**

````bash
git add tests/browser/app-check.cjs
git commit -F - <<'FIM'
test: abrir sem rede e reCAPTCHA lento na suíte do App Check

A suíte só exercitava o App Check com rede, e o app é offline-first. Os cenários
novos abrem o site publicado falso sem rede, com o dado em cache, e exigem a obra
na tela em menos de 1 s, com o token guardado válido e com ele vencido, porque sem
rede o provedor desiste na hora em vez de esperar o prazo. Outro cenário entrega o
script do reCAPTCHA só 8 s depois do clique: o login destrava no prazo e o pedido
seguinte já leva token válido, o que prova que o prazo não prende o token para sempre.

O falso do Firestore passa a responder à escrita com hora posterior à do documento
e com o serverTimestamp, para o SDK gravar a escrita no cache de verdade.
FIM
````

### Tarefa 14: docs: registra o App Check do site no CLAUDE.md

**Arquivos:** `CLAUDE.md`

- [ ] **Aplicar**

````diff
diff --git a/CLAUDE.md b/CLAUDE.md
index af4a7d4..b507d8c 100644
--- a/CLAUDE.md
+++ b/CLAUDE.md
@@ -86,6 +86,8 @@ Adicionar uma chave de topo em `db` **quebra as escritas em produção** se as r
 
 `npm run sonda:banco` ([scripts/sonda-banco.mjs](scripts/sonda-banco.mjs)) prova o que está **no ar** (`test:rules` prova o arquivo, no emulador). Só com a apiKey pública, cria 2 contas descartáveis `@example.com` e faz 45 verificações: controles positivos (o dono grava, lê e atualiza o que é dele, inclusive o próprio nome via máscara; sem isso um 403 não prova nada) e ataques (sem login, uma conta contra a outra, campo ou formato proibido, caminhos estranhos, os outros bancos do projeto), confere que o dado da vítima não mudou e apaga contas e documentos no fim. Saída 0 = banco fechado e nada sobrou; 1 = algum ataque passou, controle positivo falhou ou sobrou conta ou documento (a saída mostra o caminho ou o uid para apagar no console). Sem `--producao` sai com 2 sem tocar a rede; o script do npm já passa a flag.
 
+**App Check** (só observando; a exigência é do console): o site liga em `custta.com.br` e `*.vercel.app` (`enderecoPublicado`, em `cloud.js`), então testes e emuladores ficam de fora. O `ProvedorReCaptcha` limita a espera a 4 s e recusa na hora sem rede, porque o SDK puro segura o Auth e o Firestore quando o script do reCAPTCHA não chega. Na CSP, `https://www.google.com/recaptcha/`, `https://www.gstatic.com/recaptcha/` e `https://recaptcha.google.com/recaptcha/` existem só para ele.
+
 ### Service worker
 
 [sw.js](sw.js) é network-first. Ao **criar um arquivo JS/CSS novo na raiz**: adicione em `ASSETS` **e** incremente `CACHE` (`obras-vNN`). Sem o bump, aparelhos já instalados continuam com o retrato velho offline.
````

- [ ] **Verificar**, a rodada inteira do PR

````bash
npm run test:unit
npm run test:rules
npm run test:browser
````

- [ ] **Commit**

````bash
git add CLAUDE.md
git commit -F - <<'FIM'
docs: registra o App Check do site no CLAUDE.md

A guarda de endereço e o prazo do reCAPTCHA são decisões que não se deduzem do código: sem elas, alguém tira o prazo achando que sobrou e trava o login de quem bloqueia o script.
FIM
````

## PR 3: App Check no app

**Ramo:** `feat/blindagem4-app-check-app`, a partir da `main`. **Risco:** Assinatura e App Attest. Só faz merge depois do G11. Fecha o marco do TestFlight, que sai com o OK dele. Linhas de produção: ~60.

### Tarefa 15: feat: App Check só observando, com App Attest, no Release do app nativo

**Arquivos:** `CLAUDE.md`, `app-ios/Custta.xcodeproj/project.pbxproj`, `app-ios/Custta/Composicao.swift`, `app-ios/Custta/Custta.entitlements`, `app-ios/Custta/Dados/FabricaDeProva.swift` (novo), `app-ios/CusttaTests/ComposicaoTests.swift`, `tests/app-ios.test.cjs`

Vermelho antes de consertar: `debugNaoLigaAppCheck` e `fabricaDeProvaEntregaAppAttest` em `ComposicaoTests`. Prova do Release por `nm` e desmontagem: `FabricaDeProva` só é pedida por `montar` no Release; no Debug, `prepararAppCheck` chama com `nil`. Experimento sem App Attest no simulador: 24/24 em 1,92 s contra 1,76 s; o SDK avisa e segue com token de marcação. Atestação real, só em aparelho, depois do TestFlight.

- [ ] **Aplicar**

````diff
diff --git a/CLAUDE.md b/CLAUDE.md
index af4a7d4..97dfa11 100644
--- a/CLAUDE.md
+++ b/CLAUDE.md
@@ -102,6 +102,8 @@ Adicionar uma chave de topo em `db` **quebra as escritas em produção** se as r
 
 App em SwiftUI que vai substituir o Capacitor (spec `docs/specs/2026-10-06-app-nativo-design.md`, planos `docs/plans/2026-10-06-app-nativo-*`, mockup aprovado da etapa 1 em `~/Documents/custta-mockups/nativo/etapa1/final.html`, com a borda de rolagem do `final-v2.html` e as decisões de 10/10 no `final-v4.html`). O `app-ios/Custta.xcodeproj` é escrito à mão no formato do Xcode 16 (pastas sincronizadas): arquivo novo dentro de `Custta/`, `CusttaTests/` ou `CusttaUITests/` entra no alvo sozinho; não deixe o Xcode subir o `objectVersion` (77), porque a CI usa o Xcode 26 (`tests/app-ios.test.cjs` barra). As regras moram no pacote `app-ios/CusttaNucleo`, puro e conferido contra os vetores do site; o app tem a identidade em `Custta/Identidade/` (tokens de cor e de vidro, aurora, globo, título escrito à mão, superfícies de vidro e cápsula de abas, escritos uma vez e reusados), as telas, o `ModeloApp` e a camada fina do Firebase em `Custta/Dados/`. A cara é a do PWA: cores só por tokens (`scripts/cores-app-ios.mjs`; rode o script depois de mudar), ícones do `icons.js` (`scripts/icones-app-ios.mjs`), logo e globo iguais aos do site (as guardas comparam), toda superfície por `.superficie(_:em:)` com a dose de vidro da tela (`VidroTokens`), nunca vidro dentro de vidro, a mesma borda de rolagem em toda tela que rola (`.bordaDeRolagem(abas:)`), e animação própria só olhando o Reduzir movimento. O vidro do iOS não acompanha escala nem transformação 3D, e a auditoria de contraste do Xcode não lê vidro: as cores são auditadas com superfícies sólidas (e os pares de texto sobre sólido, em Node, pelo `PARES_SOLIDOS`), e a leitura sobre o vidro de verdade é medida pelo laudo de leitura (`LeituraNoVidroUITests`: dois prints do mesmo quadro, com e sem o texto, e 4,5:1 no pior ponto de cada palavra; portão no Mac e na CI, em jobs próprios em paralelo ao `app` (`laudo`; `auditoria`, com as auditorias e a leitura da folha do gasto; e `laudo-parte3`, com as leituras e as auditorias da parte 3 da etapa 2; divididos para cada um ficar com folga no teto de 60 min), que medem a lista sob a cápsula em menos rolagens; o texto que o sistema desenha, como os botões dos alertas, é medido contra o fundo em volta das letras, e as exceções têm nome no teste). No escuro, uma camada do tom do fundo sob o vidro (`VidroTokens.escurecimento`: 50% no Transparente e 20% no Fosco, a navegação com a mesma dose do conteúdo) e o globo mais fundo dentro do app fecham a leitura; com Aumentar contraste, o secundário é o `SecundarioTransparente`, o mais forte (ligar a opção não pode baixar a leitura); o âmbar das etiquetas é o `AlertaEtiqueta` (no claro, mais escuro que o Alerta do site) e a linha fina dos cartões de vidro é a `LinhaNoVidro` (o `Linha` sólido some sobre o vidro no escuro); mexer na dose de vidro, na aurora, no globo ou na borda pede o laudo de novo. Nenhum build vai ao TestFlight com o laudo reprovando no Mac. Pacotes Swift: só firebase-ios-sdk e GoogleSignIn-iOS, em versão exata, com o `Package.resolved` versionado (para atualizar, botão "resolver de novo" do workflow `app-ios`); a Roboto Medium do botão do Google é a única fonte embutida, travada por SHA-256. Em Debug o app aceita `CUSTTA_SERVICOS=falsos` (telas e testes de tela; dados `vitrine` por padrão, as obras do mockup, e `exemplo` nos testes) e `CUSTTA_EMULADORES=1` (emuladores, com uma chave falsa, para um pedido que escape deles ser recusado pela produção); o Release não tem nenhum dos dois. Os emuladores rodam num FirebaseApp próprio (`Composicao.nomeDoAppDosEmuladores`), para a sessão deles nunca ocupar a vaga da produção no keychain. Nenhum teste monta a composição com rede, e cada agente roda os testes no seu simulador (`CUSTTA_SIMULADOR=<udid>`). A CI (`app-ios.yml`) roda o núcleo, o build Release sem assinatura e os testes no simulador com os serviços falsos; os testes contra os emuladores e a conferência cruzada rodam no Mac e são obrigatórios antes de cada envio. O app nunca grava antes de ver os dados da conta (`Sincronizador`, erro `nao-carregado`, com o alerta do texto do site, ou o do erro de leitura quando a escuta falhou antes de carregar); conta sem documento conta como vista quando o servidor já respondeu a ela neste aparelho (marca `custta-servidor-respondeu` no `UserDefaults`, apagada junto com o cache e sempre que a conta aparece com documento: o `UserDefaults` volta no restore do backup e o cache do Firestore não). Telas que gravam: a mudança vem do núcleo (mutações de `Estado`, as mesmas regras do `dados.js`), o `ModeloApp.gravar` a aplica na hora (`Sincronizador.aplicar`; a tela anima na mesma transação) e a resposta do servidor segue pela pílula de sincronização. Folha com passos é `.folhaDoApp` em volta de um `NavigationStack` e `.passoDaFolha` em cada passo (voltar e borda do sistema; pergunta antes de descartar pelo ×, ao puxar e pelo escapar do VoiceOver); valor de dinheiro se digita sempre no `TecladoDeValor`. As folhas da obra (`FolhaDaObra`, nova e editar) e da venda (`FolhaDaVenda`) seguem o mesmo molde, e o que uma folha pede a Obras depois de gravar (entrar na obra criada, trocar a obra por trás da folha, voltar e apagar) passa por `Folhas.navegar`. Os textos da obra, das fases e dos estados moram em `ObraEFases.swift`, no núcleo. O erro de gravação que não passa sozinho vira o alerta "Não salvou" uma vez por erro (`ModeloApp.alertaDeGravacao`, contado por `Sincronizador.confirmadas`); os outros avisos seguem no topo. Cartão de vidro que cresce (um mês da lista, o "A vencer") é um `CartaoDaLista`: com o vidro aplicado ao próprio conteúdo, o iOS 27 estica o quadro de acessibilidade da primeira linha até o cartão inteiro. Sair segue o `cloud.js`: para a escuta, grava a marca `custta-limpar-cache` (`UserDefaults`), sai e apaga o cache; a abertura seguinte termina uma limpeza interrompida. Se apagar o cache falhar, a entrada fica bloqueada e o alerta "Finalizar saída" pede para limpar de novo, como o `cacheBloqueado` do site. Os identificadores de acessibilidade são contrato com os testes, inclusive a conferência cruzada. O Xcode da CI é fixo (`DEVELOPER_DIR` do 26.6). O `PrivacyInfo.xcprivacy` acompanha a política de privacidade do site: dado novo coletado entra nos dois. Envio: workflow `app-ios-testflight`, no botão, versão 2.0 no mesmo cadastro (`br.com.custta.app`). Pendências de aparelho: `docs/plans/2026-10-06-app-nativo-etapa1-checklist-aparelho.md` e `docs/plans/2026-10-13-app-nativo-etapa2-checklist-aparelho.md`. O app grava na conta de quem entra; a conta de teste da etapa 2 (`scripts/conta-demo.mjs --importar`, com as obras exportadas pelo site; o arquivo, com dados pessoais, nunca entra no repositório) continua disponível para testar um build antes de gravar na conta de sempre.
 
+App Check no app nativo: `Composicao.prepararAppCheck` liga o App Attest só no Release e diz `nil` no Debug, porque linkar o `FirebaseAppCheck` já registra uma fábrica padrão, que no simulador chama a rede real.
+
 ## UI
 
 - Todo o CSS vive em `styles.css`. Cores vêm de custom properties; o tema (`data-theme="light"`) é atributo no `<html>`, aplicado por `tema.js` antes do primeiro paint. Pele só a esmeralda (a azul saiu em 21/10/2026, no site e no app): escuro e claro são as duas combinações conferidas. Não hardcode cor fora das variáveis — quebra um dos temas.
diff --git a/app-ios/Custta.xcodeproj/project.pbxproj b/app-ios/Custta.xcodeproj/project.pbxproj
index 63092de..f3252c8 100644
--- a/app-ios/Custta.xcodeproj/project.pbxproj
+++ b/app-ios/Custta.xcodeproj/project.pbxproj
@@ -11,6 +11,7 @@
 		C05A00000000000000000091 /* FirebaseFirestore in Frameworks */ = {isa = PBXBuildFile; productRef = C05A00000000000000000081 /* FirebaseFirestore */; };
 		C05A00000000000000000092 /* GoogleSignIn in Frameworks */ = {isa = PBXBuildFile; productRef = C05A00000000000000000082 /* GoogleSignIn */; };
 		C05A00000000000000000093 /* CusttaNucleo in Frameworks */ = {isa = PBXBuildFile; productRef = C05A00000000000000000083 /* CusttaNucleo */; };
+		C05A00000000000000000094 /* FirebaseAppCheck in Frameworks */ = {isa = PBXBuildFile; productRef = C05A00000000000000000084 /* FirebaseAppCheck */; };
 /* End PBXBuildFile section */
 
 /* Begin PBXContainerItemProxy section */
@@ -76,6 +77,7 @@
 				C05A00000000000000000091 /* FirebaseFirestore in Frameworks */,
 				C05A00000000000000000092 /* GoogleSignIn in Frameworks */,
 				C05A00000000000000000093 /* CusttaNucleo in Frameworks */,
+				C05A00000000000000000094 /* FirebaseAppCheck in Frameworks */,
 			);
 			runOnlyForDeploymentPostprocessing = 0;
 		};
@@ -140,6 +142,7 @@
 				C05A00000000000000000081 /* FirebaseFirestore */,
 				C05A00000000000000000082 /* GoogleSignIn */,
 				C05A00000000000000000083 /* CusttaNucleo */,
+				C05A00000000000000000084 /* FirebaseAppCheck */,
 			);
 			productName = Custta;
 			productReference = C05A00000000000000000010 /* Custta.app */;
@@ -580,6 +583,11 @@
 			package = C05A00000000000000000072 /* XCLocalSwiftPackageReference "CusttaNucleo" */;
 			productName = CusttaNucleo;
 		};
+		C05A00000000000000000084 /* FirebaseAppCheck */ = {
+			isa = XCSwiftPackageProductDependency;
+			package = C05A00000000000000000070 /* XCRemoteSwiftPackageReference "firebase-ios-sdk" */;
+			productName = FirebaseAppCheck;
+		};
 /* End XCSwiftPackageProductDependency section */
 	};
 	rootObject = C05A00000000000000000001 /* Project object */;
diff --git a/app-ios/Custta/Composicao.swift b/app-ios/Custta/Composicao.swift
index 9f91a07..ea26cdb 100644
--- a/app-ios/Custta/Composicao.swift
+++ b/app-ios/Custta/Composicao.swift
@@ -1,4 +1,5 @@
 import Foundation
+import FirebaseAppCheck
 import FirebaseCore
 import FirebaseAuth
 import CusttaNucleo
@@ -49,6 +50,7 @@ enum Composicao {
     static func configurarFirebase(emuladores: Bool) -> FirebaseApp {
         guard emuladores else {
             if let app = FirebaseApp.app() { return app }
+            prepararAppCheck()
             FirebaseApp.configure()
             return FirebaseApp.app()!
         }
@@ -57,6 +59,17 @@ enum Composicao {
         return FirebaseApp.app(name: nomeDoAppDosEmuladores)!
     }
 
+    /// O App Check nasce junto com o FirebaseApp e lê a fábrica nesse momento: precisa rodar antes do configure. No Release, a
+    /// prova do aparelho. No Debug, fábrica nenhuma, porque o SDK registra uma sozinho ao carregar (no simulador, a de depuração,
+    /// que iria à rede do Google a cada token): sem fábrica, o App Check não nasce.
+    private static func prepararAppCheck() {
+        #if DEBUG
+        AppCheck.setAppCheckProviderFactory(nil)
+        #else
+        AppCheck.setAppCheckProviderFactory(FabricaDeProva())
+        #endif
+    }
+
     /// Chave falsa dos emuladores. O emulador do Auth aceita qualquer chave e a produção recusa esta: um pedido que
     /// escape dos emuladores (um useEmulator esquecido) falha em vez de criar conta na produção. Tem o formato das
     /// chaves do Google (39 caracteres, "A" na frente, só base64url), senão o FirebaseInstallations derruba o
@@ -65,6 +78,7 @@ enum Composicao {
 
     /// As opções do GoogleService-Info.plist com o projeto e a chave dos emuladores (o app e os testes contra eles).
     static func opcoesDosEmuladores() -> FirebaseOptions {
+        prepararAppCheck() // antes de qualquer configure nos emuladores, inclusive os dos testes, que vêm todos por aqui
         let caminho = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist")!
         let opcoes = FirebaseOptions(contentsOfFile: caminho)!
         opcoes.projectID = projetoDosEmuladores
diff --git a/app-ios/Custta/Custta.entitlements b/app-ios/Custta/Custta.entitlements
index 36fd019..0548162 100644
--- a/app-ios/Custta/Custta.entitlements
+++ b/app-ios/Custta/Custta.entitlements
@@ -8,5 +8,7 @@
 	<array>
 		<string>Default</string>
 	</array>
+	<key>com.apple.developer.devicecheck.appattest-environment</key>
+	<string>production</string>
 </dict>
 </plist>
diff --git a/app-ios/Custta/Dados/FabricaDeProva.swift b/app-ios/Custta/Dados/FabricaDeProva.swift
new file mode 100644
index 0000000..3ba478b
--- /dev/null
+++ b/app-ios/Custta/Dados/FabricaDeProva.swift
@@ -0,0 +1,12 @@
+import FirebaseAppCheck
+import FirebaseCore
+
+/* A prova de que o pedido vem do app de verdade, num iPhone de verdade: o App Attest da Apple, entregue ao App Check
+   do Firebase. Ninguém ativa a exigência: o console só observa, então uma prova que falha não barra login nem gravação.
+   Só o Release registra esta fábrica (Composicao.configurarFirebase, antes do configure). Debug, emuladores e serviços
+   falsos não a registram. Sem DeviceCheck: o app exige iOS 26, e todo iPhone com esse sistema tem o App Attest. */
+final class FabricaDeProva: NSObject, AppCheckProviderFactory {
+    func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
+        AppAttestProvider(app: app)
+    }
+}
diff --git a/app-ios/CusttaTests/ComposicaoTests.swift b/app-ios/CusttaTests/ComposicaoTests.swift
index 3812a62..d7392aa 100644
--- a/app-ios/CusttaTests/ComposicaoTests.swift
+++ b/app-ios/CusttaTests/ComposicaoTests.swift
@@ -1,5 +1,6 @@
 import Foundation
 import Testing
+import FirebaseAppCheck
 import FirebaseCore
 @testable import Custta
 
@@ -38,4 +39,19 @@ struct ComposicaoTests {
         #expect(Composicao.configurarFirebase(emuladores: true) === app, "reabrir devolve o mesmo app (configurar de novo derruba)")
         #expect(FirebaseApp.app() == nil, "o app padrão fica só para a produção")
     }
+
+    /// No Debug (emuladores, testes, app aberto pelo Xcode) o App Check não nasce: o SDK registra sozinho uma fábrica ao
+    /// carregar (no simulador, a de depuração, que iria à rede do Google a cada token), e a composição a tira.
+    @Test func debugNaoLigaAppCheck() {
+        let app = Composicao.configurarFirebase(emuladores: true)
+        #expect(AppCheck.appCheck(app: app) == nil, "o App Check só nasce no Release")
+    }
+
+    /// A fábrica do App Check entrega o provedor do App Attest, sem rede: criar o provedor não fala com ninguém, e é o
+    /// pedido de token que iria à Apple e ao Firebase. Aqui ninguém pede token.
+    @Test func fabricaDeProvaEntregaAppAttest() {
+        let app = Composicao.configurarFirebase(emuladores: true)
+        let provedor = FabricaDeProva().createProvider(with: app)
+        #expect(provedor is AppAttestProvider)
+    }
 }
diff --git a/tests/app-ios.test.cjs b/tests/app-ios.test.cjs
index bd8f4ed..128794e 100644
--- a/tests/app-ios.test.cjs
+++ b/tests/app-ios.test.cjs
@@ -72,7 +72,7 @@ test('pacotes: só Firebase e GoogleSignIn, em versão exata, e o Package.resolv
   assert.deepEqual(remotos.map(r => r.url).sort(), ['https://github.com/firebase/firebase-ios-sdk.git', 'https://github.com/google/GoogleSignIn-iOS']);
   for(const r of remotos) assert.equal(r.tipo, 'exactVersion', `${r.url} preso por versão exata`);
   assert.deepEqual([...new Set([...pbx.matchAll(/isa = XCSwiftPackageProductDependency;[^}]*productName = (\w+);/g)].map(m => m[1]))].sort(),
-    ['CusttaNucleo', 'FirebaseAuth', 'FirebaseFirestore', 'GoogleSignIn']);
+    ['CusttaNucleo', 'FirebaseAppCheck', 'FirebaseAuth', 'FirebaseFirestore', 'GoogleSignIn']);
   assert.match(pbx, /isa = XCLocalSwiftPackageReference;\s*relativePath = CusttaNucleo;/);
 
   const pins = JSON.parse(ler(RESOLVED)).pins;
@@ -96,9 +96,13 @@ test('o app nativo não leva o Sentry', () => {
 });
 
 test('reaproveita do app de hoje: Firebase, entitlements e o esquema de URL do Google', () => {
-  // Enquanto ios/ existir (até a remoção do Capacitor), as cópias não podem divergir.
+  // Enquanto ios/ existir (até a remoção do Capacitor), as cópias não podem divergir. O nativo leva a mais só o App
+  // Attest do App Check, no ambiente de produção: o App Check não aceita token do ambiente de testes da Apple.
   assert.equal(ler('app-ios/Custta/GoogleService-Info.plist'), ler('ios/App/App/GoogleService-Info.plist'));
-  assert.equal(ler('app-ios/Custta/Custta.entitlements'), ler('ios/App/App/App.entitlements'));
+  const appAttest = /\t<key>com\.apple\.developer\.devicecheck\.appattest-environment<\/key>\n\t<string>production<\/string>\n/;
+  const entitlements = ler('app-ios/Custta/Custta.entitlements');
+  assert.match(entitlements, appAttest);
+  assert.equal(entitlements.replace(appAttest, ''), ler('ios/App/App/App.entitlements'));
   const google = ler('app-ios/Custta/GoogleService-Info.plist');
   const valor = chave => google.match(new RegExp(`<key>${chave}</key>\\s*<string>([^<]+)</string>`))[1];
   const info = ler('app-ios/Custta/Info.plist');
````

- [ ] **Verificar**, a rodada inteira do PR

````bash
xcodebuild build -project app-ios/Custta.xcodeproj -scheme Custta -configuration Debug -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO | tail -5
xcodebuild build -project app-ios/Custta.xcodeproj -scheme Custta -configuration Release -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO | tail -5
xcodebuild test -project app-ios/Custta.xcodeproj -scheme Custta -destination 'platform=iOS Simulator,name=iPhone 18 Pro' -only-testing:CusttaTests/ComposicaoTests -collect-test-diagnostics never | tail -5
node --test tests/app-ios.test.cjs tests/docs.test.mjs
````

- [ ] **Commit**

````bash
git add CLAUDE.md app-ios/Custta.xcodeproj/project.pbxproj app-ios/Custta/Composicao.swift app-ios/Custta/Custta.entitlements app-ios/Custta/Dados/FabricaDeProva.swift app-ios/CusttaTests/ComposicaoTests.swift tests/app-ios.test.cjs
git commit -F - <<'FIM'
feat: App Check só observando, com App Attest, no Release do app nativo

Prepara o app para a exigência do App Check no Firestore. O Release registra a
FabricaDeProva antes do FirebaseApp.configure e passa a mandar o token do App
Attest; nada é bloqueado enquanto o console só observa.

O Debug e os emuladores não ligam, e isso exige dizer nil: só de linkar o
FirebaseAppCheck, o SDK registra uma fábrica padrão no +load, que no simulador
chama a rede real do Google. O entitlement vai como production porque o App
Check não aceita token do ambiente de testes da Apple.
FIM
````

## Provas no projeto descartável

O corte não fica armado antes disto. O Orquestrador conduz, e um agente roda os comandos com o login do Giovani. Nada aqui toca em `app-construcao-civil`, salvo a leitura do G2.

**Datas.** T1 longo e T3 duram 31 dias e **têm de começar até 02/12/2026** para fechar antes de 04/01/2027. Comece o quanto antes: se começarem até 14/11, o alvo de ativar em 15/12 se mantém. Se 04/01 chegar com o T1 longo em aberto, o Giovani decide.

**Se o T1 ou o T2 reprovar, a volta é a opção oficial do Google,** um tempo só, tirar a cobrança em R$ 60: reimplantar com `--modo-oficial` (Tarefa 8). A retirada da cobrança continua dependendo do T3 aprovado ou do aceite do risco.

**Projetos.** Criados no G3, com a mesma conta de cobrança. O crédito paga: cerca de R$ 70 somados, R$ 0 em dinheiro.

| Projeto | Uso |
|---|---|
| `CORTE` (`custta-corte-XXXX`) | A função, o tópico e os buckets |
| `A` (`custta-descartavel-a-XXXX`) | T4, T6, T5, T2, T1 curto, depois T1 longo |
| `B` (`custta-descartavel-b-XXXX`) | T3 |

**Preparo de A e B.** Um agente faz, nesta ordem, com os valores lidos no G2:
1. `npx firebase projects:addfirebase <projeto>`, na pasta do repo. Autenticação por e-mail ligada. Registrar um app web e, em A, um app iOS `br.com.custta.app` para o Simulador.
2. Ligar as mesmas APIs de `servicos-producao.txt`, com `gcloud services enable`. Sem isso, um serviço dependente que impeça desligar não aparece.
3. `gcloud firestore databases create --project <projeto> --location <região de produção> --type firestore-native`, na mesma edição de produção.
4. `gcloud firestore databases update --project <projeto> --database '(default)' --enable-pitr --delete-protection`.
5. `gcloud firestore backups schedules create --project <projeto> --database '(default)' --recurrence daily --retention 6w`. Retenção de 6 semanas, porque a prova dura 31 dias.
6. `npx firebase deploy --only firestore:rules --project <projeto>`, com as `firestore.rules` da `main`.
7. Criar 2 contas de teste e semear `dados/{uid}`, com um documento de 1 MiB e um pequeno.
8. **Esperar 48 h**, para haver backup.

Linha de base, antes de cada teste, em `provas/<teste>-antes.txt`: `gcloud firestore databases describe`, `gcloud firestore backups list`, `gcloud firestore backups schedules list --database '(default)'` e o SHA-256 de cada documento.

**Religar A entre os testes:** `PROJETO_ALVO=A BUCKET_ESTADO=CORTE-teste ORCAMENTO_PROJETO=teste-projeto ORCAMENTO_FORA_FIRESTORE=teste-fora bash corte/religar.sh --folga 0`.

**Desligar como a função:** `curl -X POST -H "Authorization: Bearer $(gcloud auth print-access-token)" -H 'Content-Type: application/json' -d '{"disableDependentServices":false,"checkIfServiceHasUsage":"SKIP"}' https://serviceusage.googleapis.com/v1/projects/A/services/firestore.googleapis.com:disable`. O `gcloud services disable` sem `--force` recusa serviço usado nos últimos 30 dias, e com `--force` desliga os dependentes: nenhum dos dois é o que a função faz.

| Teste | Passos | Passa se | Reprova, e o que acontece |
|---|---|---|---|
| **T4. Orçamento real e atraso.** A | Orçamento `teste-projeto` em A com os valores do G7, publicando no tópico; antes de criar, conferir o papel de publicador no tópico (G7, "Publicador do orçamento no tópico"). Função desarmada, como no G4. Baixar 17 GiB por REST em loop, acima dos 10 GiB grátis, anotando início e fim. Repetir em outro dia. | `costAmount` chega ao gasto real, e a mensagem chega à função. Anotar o atraso e o intervalo entre mensagens. Até 24 h é o esperado. | Mais de 48 h, ou custo que nunca aparece: chamar o Prumo, porque mexe nos gatilhos. |
| **T6. Alerta aciona.** A | Em A, `gcloud services enable pubsub.googleapis.com monitoring.googleapis.com --project A`. Política `teste-leituras`, igual à do G1, com canal Pub/Sub no tópico (os 3 passos de "Alerta aciona" do G7, em A). Implantar com `--armar-api`. Loop de leituras a 600/min por 10 min (6.000 leituras). Depois, religar e repetir o loop: tem de sair um `open` novo. | API desligada em até 15 min do início, nas duas vezes, com `corte-acao` no registro. | Não dispara, ou não dispara da segunda vez: conferir o canal, o limiar e o dado ausente do G1. |
| **T5. Lógica e permissões.** A, depois de religar | Só os papéis do G4, entre projetos. Implantar com `--armar-api`. Publicar à mão os cenários de `tests/corte.test.cjs`. Usar o `religar.sh` no segundo ataque. Tirar só o `serviceUsageAdmin` e ver a falha persistente; o `serviceUsageViewer` fica, senão a `primeiraFalha` não grava. Devolver o papel e religar A no fim. | Cada cenário decide como no teste. | Decisão errada: corrigir a função. |
| **T2. Fila dos aparelhos.** A, decide a opção | Site apontado para A, e Simulador iOS Debug com o plist de A (serviços reais, nunca o de produção). (1) Sem rede, 3 lançamentos; fechar e abrir sem rede; desligar a API; voltar a rede, esperar 10 min, anotar código, `hasPendingWrites` e pílula; religar e medir a volta. (2) Gravando a cada 5 s durante o desligamento (conexão aberta). (3) Site e iPhone lançando durante a queda, com um deles com cache de dias antes. Religar um por vez. | Nenhum lançamento recusado nem perdido, nos dois aparelhos, e a fila sobe ao religar. Anotar quem ganha no último-grava-vence. | Gravação recusada ou perdida: **volta à opção oficial.** |
| **T1 curto.** A, decide a opção | Linha de base. Desligar como a função, e anotar erro de dependente. Ler pelo SDK e por REST, e anotar o código e em quanto tempo cai. Em 1 h, religar, medir a volta, comparar com a linha de base. | Desliga sem erro, documentos iguais, PITR e proteção intactos, agendamento presente. | Falha por dependente, documento diferente, PITR ou proteção alterados: **volta à opção oficial.** |
| **T1 longo.** A, 31 dias. **Começa até 02/12** | Desligar como a função, e deixar. Em 31 dias, `gcloud services enable firestore.googleapis.com --project A`, comparar com a linha de base, listar backups, anotar se rodou backup no meio. | Documentos iguais e os backups de antes do corte seguem listados e restauráveis. | Documento ou backup perdido: **volta à opção oficial.** |
| **T3. Sem cobrança.** B, 31 dias. **Começa até 02/12** | Linha de base. Dar em B `roles/browser` e `roles/billing.projectManager` à conta da função. Implantar com `PROJETO_ALVO=B` e `--armar-api --armar-cobranca`, publicar uma mensagem `teste-fora` de R$ 100,01. Conferir que a cobrança saiu só com esse papel. **Só depois desta mensagem vem o G7**, que devolve a função à produção. Em 1 h, 24 h, 72 h e 31 dias: ler pelo SDK e listar backups. Depois religar a cobrança, anotar o tempo, comparar, restaurar um backup de antes do corte em banco novo. | Documentos voltam, e backups de antes do corte seguem restauráveis. Só então o `--armar-cobranca` pode ser usado em produção. | Dado perdido: a retirada da cobrança fica desarmada, e a cópia fora do projeto volta à mesa. Precisa de `billing.admin`: usar, e registrar. |

**O que as provas não provam:** o que acontece depois de 31 dias; a conta completa, que só existe depois de ativar (repetir o T1 curto depois); um ataque real sob carga; que o Google não mude o comportamento.

**Fim das provas:** apagar os orçamentos e as políticas de teste antes do G14. Depois, `gcloud projects delete A` e `B`, guardando `provas/` no vault.

## Passos do Giovani

O Orquestrador conduz cada passo na hora. Os rótulos vêm da documentação oficial, em inglês; a tela dele pode estar em português. **Onde está "rótulo não documentado", o Orquestrador confere na tela.**

Comando no Mac: ele digita `! <comando>` no terminal do Orquestrador, para o login ficar com ele. `CORTE`, `A` e `B` são os IDs reais anotados no G3.

Ninguém toca na aba **APIs** do App Check antes do G13: é lá que fica o botão de exigir.

| Passo | O quê | Quando |
|---|---|---|
| G1 | Alerta de leituras | Primeiro |
| G2 | Instalar e entrar no `gcloud`, ler a produção | Antes do G3 |
| G3 | Criar os 3 projetos | Antes do G4 |
| G4 | Função nas provas | Depois do merge do PR 1 |
| G5 | Provas curtas (T4, T6, T5, T2, T1 curto) | Logo depois do G4 |
| G6 | **Começar T1 longo e T3** | **Até 02/12/2026** |
| G7 | Função em produção, simulando | Depois de o T3 publicar a mensagem |
| G8 | Restringir as chaves | Depois do G5 |
| G9 | Chave do reCAPTCHA | Antes do merge do PR 2 |
| G10 | Registrar site e app no App Check | Com o G9 |
| G11 | App Attest na Apple | Antes do merge do PR 3 |
| G12 | Medir por 2 semanas | Depois do TestFlight com App Check |
| G13 | Exigir, só no Firestore | Medição boa |
| G14 | Armar o corte | Fim do T1 longo |
| G15 | Ativar a conta completa | **Até 04/01/2027** |

### G1. Alerta de leituras

1. Abrir `console.cloud.google.com/monitoring/alerting?project=app-construcao-civil`.
2. **Edit notification channels** → seção **Email** → **Add New** → o e-mail dele, descrição `Custta alerta` → **Save**.
3. Voltar e clicar **Create policy**.
4. **Select a metric**: na barra de filtro, digitar `read_ops_count`. Escolher `firestore.googleapis.com/document/read_ops_count` (rótulo de tela não documentado) → **Apply**.
5. **Rolling window**: `1 min`. **Rolling window function**: `sum`.
6. **Across time series** → **Expand** → **Time series aggregation**: `sum`. **Next**.
7. **Condition type**: `Threshold`. **Alert trigger**: `Any time series violates`. **Threshold position**: `Above threshold`. **Threshold value**: `500`. Em **Advanced options**: **Retest window** `5 min`; **Evaluation missing data** `Missing data points treated as values that don't violate the policy condition`. **Next**.
8. **Notifications and name**: marcar `Custta alerta`. **Alert autoclose duration**: `30 min`. **Documentation**: `Leituras acima de 500 por minuto, por 5 minutos. O uso normal é de poucas leituras por dia. Abra Firestore > Uso e chame o Claude.` **Alert name**: `custta-leituras`, exato: é por este nome que a função reconhece o alerta. **Create policy**.

Pronto quando: a política aparece na lista. Desfazer: apagar a política. A métrica leva até ~5 min para aparecer.

### G2. Instalar e entrar no gcloud, ler a produção

1. `! brew install --cask gcloud-cli`. Este Mac ainda não tem o `gcloud`.
2. `! gcloud auth login`, com a conta dona do projeto. `! gcloud auth application-default login`, para os scripts das provas.
3. Um agente roda e guarda em `prumo-blindagem4/provas/` (só leitura):
   - `gcloud services list --enabled --project app-construcao-civil` → `servicos-producao.txt`;
   - `gcloud firestore databases describe --project app-construcao-civil` → região, edição, PITR e proteção;
   - `gcloud firestore backups schedules list --database '(default)' --project app-construcao-civil`;
   - `gcloud billing projects describe app-construcao-civil` → ID da conta de cobrança.

### G3. Criar os 3 projetos

1. Em `console.cloud.google.com/projectcreate`, criar três, com nomes `custta-corte`, `custta-descartavel-a` e `custta-descartavel-b`. O Google acrescenta um sufixo ao ID se o nome estiver em uso: **anotar os três IDs**.
2. Em `console.cloud.google.com/billing/projects`, ligar os três à conta de cobrança do Custta (**Change billing**).
3. Se a tela recusar por limite de projetos na conta de teste, parar e chamar o Prumo: a documentação não dá esse limite.

### G4. Função nas provas

Depois do merge do PR 1. Um agente roda, com o login dele.

1. `gcloud services enable iam.googleapis.com billingbudgets.googleapis.com cloudbilling.googleapis.com cloudbuild.googleapis.com cloudfunctions.googleapis.com eventarc.googleapis.com run.googleapis.com pubsub.googleapis.com artifactregistry.googleapis.com storage.googleapis.com serviceusage.googleapis.com monitoring.googleapis.com logging.googleapis.com --project CORTE`.
2. `gcloud pubsub topics create custta-corte --project CORTE`.
3. `gcloud storage buckets create gs://CORTE-teste --project CORTE --location us-central1 --uniform-bucket-level-access`. **Bucket só das provas.** O de produção é outro, no G7.
4. `gcloud iam service-accounts create custta-corte --project CORTE`. Em todos os comandos abaixo, `CONTA` é `serviceAccount:custta-corte@CORTE.iam.gserviceaccount.com`.
5. `gcloud storage buckets add-iam-policy-binding gs://CORTE-teste --member CONTA --role roles/storage.objectUser`.
6. Em A: `gcloud projects add-iam-policy-binding A --member CONTA --role <papel>`, para `roles/serviceusage.serviceUsageViewer`, `roles/serviceusage.serviceUsageAdmin`, `roles/browser` e `roles/billing.projectManager`.
7. **Papel de build, antes do primeiro deploy.** O build da função roda como a conta padrão do Compute do projeto do corte, `<número>-compute@developer.gserviceaccount.com`, que lá não tinha papel nenhum. Em 10/11 o primeiro deploy falhou com "Could not build the function due to a missing permission on the build service account", e o erro aponta para `cloud.google.com/functions/docs/troubleshooting#build-service-account`. Ler o número com `gcloud projects describe CORTE --format='value(projectNumber)'` e rodar `gcloud projects add-iam-policy-binding CORTE --member serviceAccount:<número>-compute@developer.gserviceaccount.com --role roles/cloudbuild.builds.builder`, com o número digitado. Em 10/11 o papel entrou depois da falha, e o deploy seguinte passou. Dar o papel antes do primeiro deploy não foi provado, porque o log não mostra se a conta já existia: se o comando recusar por conta inexistente, implantar uma vez (item 8), ver falhar, dar o papel e implantar de novo.
8. Implantar para as provas, sempre com estas variáveis: `PROJETO_FUNCAO=CORTE PROJETO_ALVO=A BUCKET_ESTADO=CORTE-teste ORCAMENTO_PROJETO=teste-projeto ORCAMENTO_FORA_FIRESTORE=teste-fora POLITICA_ALERTA=teste-leituras bash corte/implantar.sh`. Cada prova acrescenta o argumento que precisa.
9. Depois do primeiro deploy: `gcloud run services add-iam-policy-binding custta-corte --region us-central1 --member CONTA --role roles/run.invoker --project CORTE` e `gcloud projects add-iam-policy-binding CORTE --member CONTA --role roles/eventarc.eventReceiver`.

### G5 e G6. Provas

Seção "Provas no projeto descartável". **O G6 tem data: até 02/12/2026.**

### G7. Função em produção, simulando

Depois de o T3 publicar a sua mensagem: a função é reimplantada aqui, e ela não pode voltar para a produção enquanto o T3 precisa dela. Antes: apagar os orçamentos e a política de teste de A que publicam no tópico.

**Peças (um agente roda):**
1. `gcloud storage buckets create gs://CORTE-estado --project CORTE --location us-central1 --uniform-bucket-level-access`, e o papel `roles/storage.objectUser` para `CONTA`, como no G4.
2. **Só leitura em produção, por enquanto:** `gcloud projects add-iam-policy-binding app-construcao-civil --member CONTA --role roles/serviceusage.serviceUsageViewer` e `--role roles/browser`.
3. `PROJETO_FUNCAO=CORTE BUCKET_ESTADO=CORTE-estado bash corte/implantar.sh`, sem argumentos. Fica simulando, apontada para a produção.
4. Conferir em `servicos-producao.txt` se `pubsub.googleapis.com` e `monitoring.googleapis.com` estão ligadas em produção. A documentação pede as duas nos dois projetos para o canal Pub/Sub. Se faltar: `gcloud services enable <api> --project app-construcao-civil`.

**Orçamento do projeto**, em `console.cloud.google.com/billing/budgets` → escolher a conta → **Create budget**:
- **Name**: `custta-projeto`. **Next**.
- **Time range**: `Monthly`. **Projects**: só `app-construcao-civil`. **Services**: `Select all`. **Savings**: desmarcar só **Promotional credits**. **Next**.
- **Budget type**: `Specified amount`. **Target amount**: `100`. **Next**.
- Limites em **Actual**: `25%`, `60%`, `100%`. **Email alerts to billing admins and users** marcado.
- Conectar o tópico Pub/Sub (rótulo não documentado): projeto `CORTE`, tópico `custta-corte`. **Finish**.

Com esse criado, apagar o orçamento antigo de R$ 25. O novo tem o mesmo aviso, sem o crédito do teste descontado.

**Orçamento fora do Firestore**, o mesmo caminho:
- **Name**: `custta-fora-firestore`. **Projects**: só `app-construcao-civil`. **Services**: selecionar todos e desmarcar **Cloud Firestore**. **Savings**: desmarcar só **Promotional credits**.
- **Target amount**: `100`. Limite em **Actual**: `100%`. Mesmo tópico. **Finish**.

**Publicador do orçamento no tópico.** Os avisos dos orçamentos chegam ao tópico `custta-corte` pela conta `billing-budget-alert@system.gserviceaccount.com`, com `roles/pubsub.publisher` no tópico. Em 10/11 o papel foi dado à mão antes de criar o `teste-projeto` por `gcloud`, e os avisos chegaram à função. Criar o orçamento sem o papel, e o caminho do console, não foram testados. O papel é do tópico, não do orçamento: basta uma vez, e vale para os dois orçamentos acima e para o `teste-projeto` do T4. Antes de criar um orçamento, por qualquer caminho, conferir com `gcloud pubsub topics get-iam-policy custta-corte --project CORTE`. Se faltar: `gcloud pubsub topics add-iam-policy-binding custta-corte --project CORTE --member serviceAccount:billing-budget-alert@system.gserviceaccount.com --role roles/pubsub.publisher`.

**Alerta aciona o corte:**
1. Em `console.cloud.google.com/monitoring/alerting?project=app-construcao-civil` → **Edit notification channels** → **Pub/Sub** → **Add New**. A janela mostra a conta `service-<número>@gcp-sa-monitoring-notification.iam.gserviceaccount.com`.
2. Em `console.cloud.google.com/cloudpubsub/topic/list?project=CORTE` → `custta-corte` → **Permissions** → **Add principal** → essa conta → **Pub/Sub Publisher** → **Save**.
3. Voltar, informar o tópico `projects/CORTE/topics/custta-corte`, **Send test notification**, **Add channel**.
4. Editar a política `custta-leituras` e marcar esse canal também. A mensagem de teste chega como incidente simulado. Se ela vier aberta e com outro nome de política, a função deixa um `corte-erro` de política desconhecida e não age: é o esperado aqui, e o aviso `Custta: o corte falhou`, se já existir, manda e-mail por isso. Fechada, ou aberta com o nome `custta-leituras`, a função simulando só registra.

**Avisos, no projeto `CORTE`**, sem depender do Mac:
- Criar um canal de e-mail também em `CORTE`: o canal do G1 fica em outro projeto.
- **O corte agiu.** Em `console.cloud.google.com/logs/query?project=CORTE`, consulta `jsonPayload.marca="corte-acao" AND NOT jsonPayload.acao:"faria"`, criar alerta de log, nome `Custta: o corte agiu`. Na documentação do alerta, colar o comando de volta de "Se o corte agir", com o ID real, para ele ter no celular. Limite: 20 notificações por dia.
- **O corte falhou.** Mesma tela, consulta `jsonPayload.marca="corte-erro"`, nome `Custta: o corte falhou`.
- **O corte parou.** Em Alerting → **Create policy** → métrica `run.googleapis.com/request_count` do serviço `custta-corte`, filtro `response_code_class="2xx"` → **Condition type** `Metric absence` → **Trigger absence time** `23,5 h` (o máximo) → nome `Custta: o corte parou de responder`.

Pronto quando: a função registra `corte-passagem` depois da primeira mensagem do orçamento, que pode levar horas.

### G8. Restringir as chaves

Rótulos de memória, conferir na tela: `console.cloud.google.com/apis/credentials?project=app-construcao-civil` → clicar na chave → **Restrições de aplicativo**.

**Primeiro o iOS.**
1. `iOS key (auto created by Firebase)`, terminada em `…PpSltdk`.
2. **Apps iOS** → bundle ID `br.com.custta.app` → **Salvar**. Não mexer em "Restrições de API".
3. Esperar 5 min. No TestFlight, sair e entrar, lançar um gasto, ver sincronizar. Push: Actions → `push-diario` → **Run workflow**.

**Depois a web.**
4. `Browser key (auto created by Firebase)`, terminada em `…NzzpjAGPCLNTKU`.
5. **Sites**, um por linha: `custta.com.br/*`, `app-construcao-civil.vercel.app/*`, `*.vercel.app/*`, `app-construcao-civil.firebaseapp.com/*`.
6. **Salvar**. Esperar 5 min. Em `custta.com.br`, entrar com e-mail, Google e Apple e lançar um gasto. Abrir uma prévia da Vercel e entrar.

`www.custta.com.br` não entra: responde 308, conferido em 09/11.

Desfazer: **Nenhuma** → **Salvar**, poucos minutos (prazo não documentado).

### G9. Chave do reCAPTCHA

1. `console.cloud.google.com/security/recaptcha?project=app-construcao-civil` → **Keys** → **Create key**.
2. **Display name**: `Custta site`. **Application type**: `Web`. **Disable domain verification** desligado.
3. **Domain list** → **Add a domain**: `custta.com.br`; **Add a domain**: `vercel.app`. Se recusar `vercel.app`, usar `app-construcao-civil.vercel.app`; as prévias passam a contar como inválidas na medição.
4. Por pontuação (padrão), sem desafio. **Create key**. Passar a chave ao Orquestrador. É pública e entra no código.

Mudança na lista leva até 30 min.

### G10. Registrar site e app no App Check

Só observa, nada é bloqueado. `console.firebase.google.com/project/app-construcao-civil/appcheck`, aba **Apps**.
1. App web → **reCAPTCHA Enterprise** → chave do G9 → validade (TTL) de **1 dia** → **Save**. Não mexer no limiar (0,5).
2. App iOS `br.com.custta.app` → **App Attest** → validade de **1 dia**. Se pedir o Team ID: `4S7JKDKN27`.

### G11. App Attest na Apple

Sem isto, a CI cai em "Arquivar" e nada vai ao TestFlight.
1. `developer.apple.com/account` → **Certificates, IDs & Profiles** → **Identifiers** → `br.com.custta.app` → marcar **App Attest** → **Save**.
2. **Profiles** → `Custta App Store` → **Edit** → **Save** → **Download**. Guardar em `~/Documents/custta-chaves/`.
3. `! base64 -i ~/Documents/custta-chaves/<arquivo>.mobileprovision | gh secret set PERFIL_APP_STORE -R gstuchi/app_construcao_civil`.

### G12. Medir por 2 semanas

Depois do TestFlight com App Check e do site no ar. App Check → **APIs** → **Cloud Firestore**, só olhar. Ir ao G13 com 7 dias seguidos em que quase tudo aparece verificado, e o que sobra é build antigo conhecido. Rever o prazo de 4 s do site com esses números.

### G13. Exigir, só no Firestore

1. Avisar quem usa: abrir o site e atualizar o TestFlight antes.
2. App Check → **APIs** → **Cloud Firestore** → **Enforce** → confirmar. Autenticação fica de fora, porque é Preview. Leva até 15 min.
3. Depois: site e app (entrar, lançar, sincronizar), prévia da Vercel, e Actions → `push-diario` → **Run workflow**. É este último que prova que o cron fica fora do App Check.

Desfazer: mesma linha → **Unenforced (monitoring only)**.

### G14. Armar o corte

Só com T1 curto, T1 longo, T2, T4, T5 e T6 aprovados, salvo o item 5.
1. Conferir: nenhum orçamento nem política de teste publicando no tópico, e `gcloud storage cat gs://CORTE-estado/estado.json` só com dados de produção.
2. Somar a escrita na produção: `gcloud projects add-iam-policy-binding app-construcao-civil --member CONTA --role roles/serviceusage.serviceUsageAdmin`.
3. `PROJETO_FUNCAO=CORTE BUCKET_ESTADO=CORTE-estado bash corte/implantar.sh --armar-api`.
4. **Retirada da cobrança:** só depois do T3 aprovado, **ou** com o aceite explícito dele do risco de perder dados. `gcloud projects add-iam-policy-binding app-construcao-civil --member CONTA --role roles/billing.projectManager`, e depois `PROJETO_FUNCAO=CORTE BUCKET_ESTADO=CORTE-estado bash corte/implantar.sh --armar-api --armar-cobranca`.
5. **Se o T1 ou o T2 reprovou, no lugar dos itens 2 a 4:** com a mesma condição do item 4, somar `roles/billing.projectManager` como lá, e `PROJETO_FUNCAO=CORTE BUCKET_ESTADO=CORTE-estado bash corte/implantar.sh --modo-oficial --armar-cobranca`. O alerta de leituras fica só no e-mail.

Desfazer: o mesmo comando, sem os argumentos de armar.

### G15. Ativar a conta completa

Depois do G14. Firebase → card **Plano de faturamento** → **Fazer upgrade**. No console do Google Cloud, a documentação chama de **Activate**. Limite: 04/01/2027. No mesmo dia, conferir que o orçamento, o tópico e a função continuam ligados e que chegou uma `corte-passagem` nova: a documentação não diz o que o upgrade faz com eles.

## Se o corte agir

O Giovani fica sabendo por e-mail: `Custta: o corte agiu`, `Custta: o corte falhou`, os e-mails do orçamento ou o alerta de leituras. O site e o app continuam com o cache. Quem usa vê "Salvando…" sem fim.

**Não religue sem entender.** Com a API fora, as métricas ficam zeradas, com ou sem robô. Só religando se descobre se ele continua, e por isso a função fica armada e corta de novo.

**Só a API desligou (o caso comum).** Dá para fazer sem Mac, no Cloud Shell do Google, pelo celular. Leva cerca de 15 minutos.
1. Decidir a folga **antes** do comando. Com menos de 24 h do pico, o custo atrasado ainda sobe, e `--folga 0` faz a API cair de novo. `--folga 100` evita isso, mas adia o próximo corte e sobe o teto do mês em R$ 100. Se a cobrança também foi tirada, a mesma folga vale para o orçamento de fora do Firestore e sobe o teto dele no mesmo tanto. Só o Giovani decide.
2. Em `shell.cloud.google.com`, com o ID real no lugar de `CORTE` e a folga escolhida:
   `rm -rf app_construcao_civil; git clone https://github.com/gstuchi/app_construcao_civil && cd app_construcao_civil && BUCKET_ESTADO=CORTE-estado bash corte/religar.sh --folga 0`
   Grava a base e, só depois, religa a API. O script imprime em quanto a API cai de novo. Na opção oficial, esse valor é o da cobrança.
3. Avisar quem usa: abrir **um aparelho de cada vez, com internet**. Cada salvamento regrava o documento inteiro, e o último a subir apaga o outro. O PITR de 7 dias desfaz, e um agente faz isso num banco novo.
4. Conferir que o site e o app leem e gravam. `gcloud firestore databases describe --project app-construcao-civil` (PITR e proteção) e `gcloud firestore backups schedules list --database '(default)' --project app-construcao-civil`. Recriar o que faltar.

**A cobrança foi tirada.** Só com o interruptor armado, e só se a API não desligou, se o gasto foi de fora do Firestore, ou na opção oficial. De 40 minutos a mais de um dia.
1. Rodar o `religar.sh`, como acima, **antes** de religar a cobrança, para a função não cortar de novo. A folga escolhida no passo 1 de cima vale aqui também para o orçamento de fora do Firestore: com menos de 24 h do pico, `--folga 0` deixa o custo atrasado do mesmo ataque tirar a cobrança de novo assim que ela voltar. Se a última linha falhar (ligar a API sem cobrança), a base já ficou gravada: siga.
2. Em `console.cloud.google.com/billing/projects`, **Change billing** no projeto `app-construcao-civil`. O Google diz que pode levar até 24 h, sem garantia.
3. `gcloud services enable firestore.googleapis.com --project app-construcao-civil`.
4. Conferir banco, PITR, agendamentos e backups. Ligar o PITR de novo antes de restaurar. Dado perdido: restaurar backup em banco novo e copiar por conta, com um agente.

## Depois

- **Cópia fora do projeto:** decidir com o resultado do T3.
- **Repetir o T1 curto** depois de ativar a conta completa: as provas rodam só na conta de teste.
- **Refazer o T5** a cada 6 meses, ou ao mexer na função.
- **Apagar** o ramo `proto/b4-ios-swift63` e os projetos descartáveis.
- **Vault:** registrar `Custta — Estado do projeto` ao fim de cada etapa.
