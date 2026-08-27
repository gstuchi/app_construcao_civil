# Confiabilidade dos dados — design

Data: 2026-08-27 · Aprovado por Giovani no chat.

Fase 1 do plano de lançamento na App Store
(`C:\Users\User\.claude\plans\breezy-jumping-ladybug.md`). É a fase de maior
severidade do plano: trava a Fase 2, porque exclusão de conta exige escrita
confiável e falha visível.

Pedido de origem: hoje `app.js` mostra "Gasto lançado com sucesso" antes de
saber se o dado foi gravado, e uma escrita que falha congela a sincronização
remota em silêncio. `cloud.js` guarda o blob pra próxima tentativa e avisa a UI
(`cloud-erro`), mas **não agenda tentativa nenhuma** — o toast diz "vamos tentar
de novo sozinhos" e isso é mentira: o dado só sobe se o usuário salvar outra
coisa por acaso. Enquanto isso `dirty` fica `true` pra sempre e o guard de eco
em `app.js` (`meta.pendingWrites || meta.localDirty`) descarta todo snapshot
seguinte.

Dois itens da Fase 1 já foram entregues na auditoria de 2026-08-26 e ficam
**fora de escopo**: a guarda de tamanho do blob (`OBRA_CALC.blobCabe` em
`save()`) e o erro de escrita visível (`cloud-erro` + toast com janela de 30s).

## Decisões tomadas

1. **Confirmação offline é honesta, não silenciosa.** Sem servidor, o toast diz
   "Salvo no aparelho — sobe quando a internet voltar". Com servidor, o
   "sucesso" só sai depois do ack.
2. **Indicador discreto.** Pill no header, ao lado de `#btnSair`, invisível
   quando está tudo sincronizado.
3. **Monitoramento:** captura global agora, guardando os últimos erros no
   aparelho. Sentry entra na Fase 3, junto com a CSP que precisa listar a
   origem dele. A decisão fica registrada aqui porque é insumo da política de
   privacidade (Fase 2) e dos App Privacy labels (Fase 5).
4. **Falha terminal não descarta dado.** Para o backoff, mostra erro que não
   some sozinho, segura o estado na tela e oferece "Tentar de novo". Sem cópia
   de socorro em `localStorage` — seria reintroduzir o vazamento entre contas
   que a Fase 0 apagou.
5. **Arquitetura:** máquina de estado dentro de `cloud.js`, UI só escuta. Sem
   `sync.js` novo (mais um global e mais um bump de `CACHE` no `sw.js` pra ~80
   linhas), sem orquestração em `app.js` (regra de nuvem morando na camada de
   render).

## Arquitetura

`cloud.js` passa a ser dono da fila de escrita e da classificação de erro.
`app.js` ganha um listener e a pill. Nenhuma mudança em `firestore.rules` — o
formato do documento não muda, então não há caso novo em `tests/rules.test.mjs`.

### 1. Máquina de estado da escrita (`cloud.js`)

Estados, expostos num evento único `cloud-estado` com
`{ estado, code, tentativa }`:

| Estado | Significado |
| --- | --- |
| `ocioso` | nada pendente; tudo que foi salvo chegou no servidor |
| `salvando` | há blob pendente, primeira tentativa em voo |
| `repetindo` | falha transitória; backoff agendado |
| `offline` | `navigator.onLine === false`, ou falha transitória com rede caída |
| `erro` | falha terminal; backoff parado, precisa de ação |

`flushSave()` deixa de ser fire-and-forget:

- Sucesso: `dirty = false` se não entrou blob novo no meio, estado `ocioso`,
  resolve as promises pendentes.
- Falha **transitória** (`unavailable`, `deadline-exceeded`, `resource-exhausted`,
  `cancelled`, `internal`, ou erro sem `code`): reguarda o blob, agenda retry
  com backoff exponencial 1s, 2s, 4s, 8s, 16s, teto 30s, estado `repetindo`
  (ou `offline` se `navigator.onLine` for falso).
- Falha **terminal** (`permission-denied`, `unauthenticated`, `invalid-argument`,
  `not-found`, `failed-precondition`): para o backoff, mantém `pendingBlob` e
  `dirty = true`, estado `erro`, rejeita as promises pendentes com o code.

Um `online` do navegador cancela o backoff em curso e tenta na hora — não
adianta esperar 16s se a rede acabou de voltar. `offline` do navegador leva ao
estado `offline` sem tentar.

`CLOUD.tentarDeNovo()`: zera o contador de tentativas e chama `flushSave()`.
É o que o botão "Tentar de novo" chama.

`CLOUD.estado()`: devolve o estado atual, pra pill se pintar certo no primeiro
paint sem esperar evento.

### 2. `saveDados` devolve promise

`saveDados(blob)` continua com debounce de 300ms e passa a devolver uma promise
que resolve quando **aquele** blob (ou um posterior, já que o documento é
sobrescrito inteiro) chegou no servidor, e rejeita na falha terminal. As
promises de saves coalescidos pelo debounce resolvem juntas — é uma fila de
`resolve`/`reject` guardada junto com `pendingBlob`, não uma promise por
chamada.

Offline com cache persistente, a promise do `setDoc` **não resolve** até o
servidor confirmar. Isso é esperado, e é o que o timer de 600ms da seção 3 e a
pill da seção 4 cobrem.

### 3. Feedback no lugar certo (`app.js`)

`save()` passa a devolver a promise de `CLOUD.saveDados` (mantendo o
early-return da guarda de tamanho, que devolve promise rejeitada).

Helper novo `salvarComAviso(msgOk)`, usado nos pontos de `save()` que hoje dão
toast (`app.js:814` e os demais em 647/654/1116/1131/1143):

- corre a promise contra um timer de 600ms;
- servidor respondeu primeiro → `toast(msgOk)` (ex.: "Gasto lançado com sucesso");
- timer venceu primeiro → `toast('Salvo no aparelho — sobe quando a internet voltar')`,
  e o resto fica por conta da pill; **não** dispara um segundo toast quando
  subir depois, pra não pipocar aviso fora de contexto;
- rejeitou → o toast de erro já existente (com a janela de 30s) e a pill em `erro`.

Fechar a folha e re-renderizar continuam imediatos, como hoje. O usuário nunca
espera a rede pra ver o gasto na lista.

### 4. Pill de sincronização (`index.html` + `app.js`)

Markup novo dentro do `div` do header, antes de `#btnSair`:
`<span id="syncPill" class="sync-pill hidden" role="status" aria-live="polite"></span>`.

`renderSync(estado)` em `app.js` escuta `cloud-estado` e pinta:

| Estado | Pill |
| --- | --- |
| `ocioso` | escondida |
| `salvando`, `repetindo` | "Salvando…" com o ícone girando |
| `offline` | "Sem conexão" |
| `erro` | "Não salvou" em cor de alerta, clicável → chama `CLOUD.tentarDeNovo()` |

CSS em `index.html` usando as custom properties existentes — nada de cor
hardcoded, senão quebra um dos quatro combos tema×skin. Ícones via `data-ico`
(`icons.js` ganha os que faltarem).

`renderSync` também escuta `online`/`offline` do navegador pra refletir queda de
rede mesmo sem escrita pendente.

### 5. Erro de leitura no `onSnapshot` (`cloud.js`)

`watchDados` ganha o terceiro argumento do `onSnapshot`, o callback de erro:
dispara `cloud-estado` com `erro` e o code. Sem isso, uma regra errada em
produção pararia a chegada de dados sem sintoma nenhum na tela — risco criado
pela própria Fase 0.

### 6. Logout com flush (`cloud.js` + `auth.js`)

`logout()` hoje faz `pendingBlob = null` antes do `signOut`, destruindo trabalho
não salvo em silêncio. Passa a:

1. se há pendência, forçar `flushSave()` e aguardar (teto de 5s);
2. subiu → `signOut` normal;
3. não subiu → devolve rejeição com `{ code: 'pendente' }`, e `auth.js` pergunta
   com texto explícito ("Tem lançamento que ainda não subiu. Sair mesmo assim
   descarta.") antes de sair de verdade;
4. o `desativa()` do push continua acontecendo antes do `signOut`, como hoje.

### 7. Sessão expirada (`auth.js`)

Sessão expirada é evento raro — o refresh token não vence sozinho, e ficar
offline **não** desloga. Só cai aqui quando a conta é apagada/desativada, a
senha muda em outro aparelho, ou o token é revogado.

`auth.js` passa a distinguir "nunca logou" de "estava logado e caiu": se
`onAuth` receber `null` depois de já ter recebido um usuário, e não foi um
logout iniciado pelo usuário, `locked(true)` mostra a mensagem "Sua sessão
expirou por segurança. Entre de novo pra continuar." no `#lMsg`.

### 8. Captura global de erro (`app.js`)

`window.onerror` + `unhandledrejection` gravam num anel de 20 entradas em
memória (`{ hora, msg, stack }`) e mostram toast genérico uma vez a cada 30s,
reusando a janela de anti-spam que já existe pro `cloud-erro`. O anel fica
exposto em `window.OBRA_DIAG` — é o gancho que o Sentry da Fase 3 substitui.

Os dois catches vazios de hoje (`index.html:786`, `app.js:1266-1269`) passam a
registrar no anel em vez de engolir.

## Fora de escopo

Sentry (Fase 3), exclusão de conta e reautenticação (Fase 2), qualquer mudança
em `firestore.rules`, refatoração de `app.js`, e fila de escritas por operação
(o documento é sobrescrito inteiro; não há merge a fazer).

## Pronto quando

- Com o devtools offline, lançar um gasto mostra "Salvo no aparelho", nunca
  "sucesso"; a pill mostra "Sem conexão".
- Voltando a rede, o dado sobe sozinho sem reload e a pill some.
- Matar a rede no meio da escrita e restaurar depois faz o dado chegar.
- `permission-denied` forçado mostra erro que não some sozinho, com "Tentar de
  novo" funcionando, e o app **não** congela a sincronização.
- Sair da conta com escrita pendente pergunta antes de descartar.
- `npm test` verde (unit + rules).

## Como verificar

Estender o procedimento Playwright de `.claude/skills/verify/SKILL.md` com
alternância offline/online via CDP (`Network.emulateNetworkConditions`). É o
primeiro teste e2e real do projeto e vira o molde da Fase 3.

Teste de unidade novo para a classificação de erro e o cálculo do backoff:
extrair essas duas funções puras pra `calc.js` (`OBRA_CALC.erroEhTerminal`,
`OBRA_CALC.proximoBackoff`) e cobrir em `tests/` com `node --test`, sem browser
e sem rede — segue o padrão dos 5 arquivos de teste que já existem.
