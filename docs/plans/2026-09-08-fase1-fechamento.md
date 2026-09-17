# Fase 1 — Auditoria de fechamento

Data: 2026-09-08. Escopo: confiabilidade dos dados no PWA existente.

## Conferência final — 2026-09-09

- Usuário confirmou no aplicativo mobile: criar lançamento offline, fechar,
  reabrir com lançamento preservado e sincronizar automaticamente ao reconectar.
  Confirmou também bloqueio de logout offline. A versão desse novo teste manual
  não foi identificada; não comprova publicação das alterações locais v33.
- `node tests/browser/sync.cjs`: 16 verificações passaram, incluindo bloqueio de
  cliques durante logout e liberação da interface ao terminar. O teste passou a
  usar o botão da barra lateral, visível no viewport desktop.
- `npm test`: execução concluída com código 0; 33 testes de rules passaram.
- Logout offline é bloqueado mesmo sem pendências visíveis, por proteção da fila
  persistida do SDK. Não depende apenas do estado em memória da tela.
- Implementação e verificação local concluídas. Publicação da versão v33 e
  conferência da atualização no aparelho permanecem pendentes. Fase 2 não iniciada.

## Critérios e evidências

| Critério | Resultado | Evidência |
| --- | --- | --- |
| Escrita retorna promise de confirmação remota | Concluído | `tests/fila.test.mjs`: confirmação, falha terminal e escritas consecutivas. |
| Retry transitório com backoff até 30s | Concluído | `tests/sync.test.cjs` e `tests/fila.test.mjs`. |
| Persistência offline e recuperação após fechar | Concluído | `tests/browser/persistencia.cjs`, SDK Firestore real e IndexedDB; teste manual no iPhone confirmado pelo usuário para v32. |
| Queda de rede durante uma escrita | Concluído | `tests/browser/fase1.cjs`: intercepta requisição Write iniciada, corta transporte por CDP e reconecta sem reload; confirma documento remoto. |
| `permission-denied` visível e recuperável | Concluído | Rules do emulador negam escrita real. A edição permanece na tela, retry confirma depois de restaurar permissão e atualização remota seguinte aparece sem reload. |
| Erro de leitura e retomada de assinatura | Concluído | Rules negam leitura; retry recria `onSnapshot` encerrado. Confirmação de escrita não esconde erro de leitura. |
| Indicador de sincronização | Concluído | Browser testa salvando, offline, erro persistente, retry e retorno ao estado normal. |
| Logout aguarda fila e escrita em andamento | Concluído | Unidade cobre envio em voo, fila recuperada do SDK, timeout de 5s e bloqueio offline. |
| Sessão invalidada durante uso | Concluído | Auth SDK real no emulador. Remoção da conta descartável invalida refresh; app encerra sessão, limpa tela e mostra explicação. Unidade cobre falha de rede sem logout e resposta antiga sem afetar outra conta. |
| Diagnóstico global | Concluído | Browser cobre `error`, `unhandledrejection` e anel limitado a 20 entradas; unidade cobre falhas do registro PWA e tema inicial. |
| Aviso preventivo de tamanho e rejeição explícita | Concluído | Aviso a partir de 700.000 bytes UTF-8; bloqueio acima de 900.000. Testes verificam rejeição sem falso sucesso e recuperação após reduzir. |
| Monitoramento definido | Concluído conforme escopo aprovado | Anel local em memória nesta fase; Sentry permanece na Fase 3, como definido em 2026-08-27. |
| Testes gerais e rules | Concluído | `npm test`, incluindo 33 testes das rules. |

## Auditoria dos caminhos de gravação

Todos os caminhos abaixo chegam a `save()` → `CLOUD.saveDados()`, onde validação,
promise, retry e indicador são compartilhados:

- Afazeres: criar, marcar e remover.
- Obras: criar, editar, apagar, mudar fase e desfazer venda.
- Venda: registrar preço e data.
- Gastos: criar, editar, excluir e excluir parcelas individuais ou agrupadas.
- Configuração: taxa e tópicos personalizados.

O formulário de gasto usa `salvarComAviso`: sucesso apenas após confirmação.
Os demais caminhos atualizam a tela imediatamente e usam o indicador comum;
não exibem toast de sucesso antecipado. O aviso após 600ms informa espera,
sem afirmar gravação local apenas porque o tempo passou.

## Correções adicionais desta auditoria

1. O botão de retry também recria assinaturas de leitura que terminaram com erro.
2. Erros permanentes não prometem retry automático. Erro de leitura não é ocultado
   por uma escrita bem-sucedida ou simples mudança da conectividade.
3. Validação de tamanho passou para a fila: confirmação de versão anterior não
   pode esconder uma edição atual rejeitada por tamanho.
4. Refresh inválido é tratado explicitamente, inclusive `auth/invalid-refresh-token`,
   que o SDK não encerrou sozinho no teste. Verificação ao ganhar foco, ficar
   visível ou recuperar conexão, no máximo uma vez por minuto nesses eventos.
5. Falha de rede não causa logout. Resposta de uma sessão antiga não encerra outra.
6. Falhas antes ignoradas no registro do PWA e no tema entram no diagnóstico.
7. A interface bloqueia novas edições enquanto o logout aguarda a fila. Sessão
   encerrada também fecha e limpa formulários, para não deixar conteúdo da conta
   anterior aberto após o próximo login.

## Decisões que substituem o desenho inicial

- Sem debounce que retenha alterações apenas em memória: cada versão é entregue
  imediatamente ao cache persistente do SDK.
- Sem saída forçada com descarte. Conectar e sincronizar antes do logout.
- Falha terminal mantém a edição visível e o estado pendente até ação do usuário.
  Recuperação foi demonstrada; não se limpa `dirty` descartando silenciosamente
  o trabalho local.
- O aviso de espera não usa a frase “Salvo no aparelho” baseada apenas em timer.
- Monitoramento remoto permanece fora desta fase por decisão anterior registrada.

## Reprodução

Requisitos: Node.js, Java 21, dependências npm e Playwright disponível via `NODE_PATH`.
Iniciar o servidor de teste em terminal separado:

```powershell
node tests/browser/servidor.cjs
```

Executar os emuladores sequencialmente, pois usam a mesma porta:

```powershell
npm test
node tests/browser/sync.cjs
npx firebase emulators:exec --only firestore "node tests/browser/persistencia.cjs"
npx firebase emulators:exec --config firebase.test.json --project demo-custta-phase1 --only firestore,auth "node tests/browser/fase1.cjs"
```

Os testes de aceitação usam projetos demo e contas descartáveis nos emuladores.
Não alteram rules, contas ou dados de produção. O teste de persistência usa Auth
simulado; o teste de fechamento usa tanto Auth quanto Firestore reais nos emuladores.

## Limites que pertencem às próximas fases

Fase 2: reautenticação para ações sensíveis, exclusão de conta e limpeza do cache.
Fase 3: SDK local, Sentry e endurecimento adicional. Fase 4: validação nativa em
TestFlight. Abertura inicial sem SDK previamente disponível não foi convertida
em funcionalidade nova nesta fase. As pendências externas da Fase 0 não são
declaradas resolvidas por esta auditoria.

Fontes técnicas: [persistência do Firestore](https://firebase.google.com/docs/firestore/manage-data/enable-offline)
e [Auth Emulator](https://firebase.google.com/docs/emulator-suite/connect_auth).
