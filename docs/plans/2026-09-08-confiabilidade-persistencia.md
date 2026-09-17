# Fase 1 — Persistência offline e saída segura

## Problema confirmado

O aplicativo mantinha alterações offline em `pendingBlob`, sem chamar o SDK.
O fechamento da página perdia essa memória. O aviso de gravação no aparelho
era disparado por um timer, sem comprovar persistência. O logout ignorava
escritas em andamento porque verificava apenas `pendingBlob`.

## Implementação

- [x] Entregar cada versão ao Firestore imediatamente, inclusive offline.
- [x] Manter a ordem na fila persistente do SDK, sem aguardar confirmação remota
  para entregar a próxima alteração.
- [x] Ignorar respostas de versões e sessões antigas na fila da aplicação.
- [x] Restaurar snapshots locais com escritas pendentes após reabrir o aplicativo.
- [x] Acompanhar mudanças de metadados para atualizar a sincronização.
- [x] Aguardar a fila da aplicação e `waitForPendingWrites` antes do logout,
  incluindo alterações persistidas em sessões anteriores.
- [x] Bloquear novas escritas durante a saída e manter a sessão quando há timeout.
- [x] Cancelar push somente depois de confirmar as escritas e antes de sair.
- [x] Remover saída forçada que descartava pendências. Offline, reconectar antes
  de sair. Essa decisão substitui o descarte previsto na especificação anterior.
- [x] Substituir o aviso baseado em tempo por mensagem de espera. Apenas a
  confirmação do servidor dispara sucesso.
- [x] Atualizar a versão do cache do service worker.

## Verificação

`npm run test:unit` cobre fila, timeout, logout em voo, alterações consecutivas
offline, recuperação de snapshots e troca de conta. O teste de interface
`tests/browser/sync.cjs` cobre mensagens e indicador no Chromium.

`tests/browser/persistencia.cjs` utiliza o SDK Firestore real, IndexedDB e um
projeto `demo-custta-offline` no emulador. Auth é um duplo de teste; nenhuma
conta ou documento de produção é alterado. O teste desativa a rede pelo SDK,
grava duas alterações, fecha a página, abre outra no mesmo contexto do navegador,
confirma os dados na interface e reativa a rede para verificar o documento no
servidor. Isso não equivale a matar o processo do iPhone ou testar autenticação real.

Para executar, disponibilizar Playwright pelo `NODE_PATH`, iniciar
`node tests/browser/servidor.cjs` e rodar:

```powershell
node tests/browser/sync.cjs
npx firebase emulators:exec --only firestore "node tests/browser/persistencia.cjs"
```

## Limites e próximos passos

- Validar fechamento e reabertura no iPhone real, inclusive pressão de armazenamento.
- Testar autenticação real e mudanças de sessão junto da exclusão de conta na Fase 2.
- O Firebase ainda vem de CDN. Abertura sem SDK previamente disponível permanece
  dependente da Fase 3 (SDK local), antes do empacotamento nativo.
- Confirmar em produção as pendências administrativas da Fase 0: rules publicadas,
  conta exposta excluída, auditoria do histórico e conta Apple/bundle ID.
- A captura global existente permanece em memória; Sentry segue previsto para
  a Fase 3 conforme a especificação aprovada em 2026-08-27.

Referência: [persistência offline do Firestore](https://firebase.google.com/docs/firestore/manage-data/enable-offline).
