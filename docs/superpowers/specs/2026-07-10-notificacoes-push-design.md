# Notificações push — design

Data: 2026-07-10 · Aprovado por Giovani. Motivo: o pai quer ser lembrado no
celular, com o app fechado, dos afazeres pendentes, das parcelas de cartão do
mês e de lançar os gastos do dia. Resumo diário às 18h (Brasília), no máximo
uma notificação por dia; dia sem nada a dizer não notifica.

## Arquitetura

Web Push padrão (VAPID) — sem SDK de messaging no cliente, app segue vanilla.
O envio sai de um cron no GitHub Actions (repo já está no GitHub), custo zero,
sem plano Blaze.

1. **App (Ajustes):** painel "Notificações" com toggle no mesmo estilo do
   painel Aparência. Ativar → `Notification.requestPermission()` →
   `registration.pushManager.subscribe({ userVisibleOnly:true,
   applicationServerKey: VAPID_PUBLICA })` → salva a inscrição no Firestore.
   Desativar → `subscription.unsubscribe()` + remove do Firestore.
2. **Service worker (`sw.js`):** handler de `push` faz
   `self.registration.showNotification(titulo, { body, icon, badge })` com o
   JSON do payload; handler de `notificationclick` fecha a notificação e
   foca/abre o app (`clients.matchAll` → `focus()`, senão `openWindow('./')`).
   Bump do cache pra `obras-v21`.
3. **Cron (GitHub Actions):** workflow `.github/workflows/push-diario.yml`,
   `schedule: '0 21 * * *'` (21:00 UTC = 18h Brasília) + `workflow_dispatch`
   pra teste manual. Roda `notificacoes/envia.js` (Node): Admin SDK lê todos
   os docs de `push/`, pra cada uid lê `dados/{uid}`, monta o resumo e envia
   com a lib `web-push`.

## Dado no Firestore

Documento **separado** `push/{uid}` — nunca dentro de `dados/{uid}`, porque
`saveDados` reescreve o blob inteiro e um aparelho apagaria a inscrição do
outro. Formato:

```text
push/{uid} = { subs: { <hashDoEndpoint>: { endpoint, keys:{p256dh, auth}, criado } } }
```

- Mapa por hash do endpoint (endpoint tem `/` — não serve de chave): cada
  aparelho uma entrada; celular e desktop convivem.
- App escreve a própria entrada com `setDoc(..., { merge:true })` e apaga com
  `deleteField()`.
- Rules do Firestore ganham: `match /push/{uid}` → read/write se
  `request.auth.uid == uid`. (Admin SDK do cron ignora rules.)

## Conteúdo do resumo

Função pura `montaResumo(dados, hojeISO)` → `{ titulo, corpo } | null`.
Linhas do corpo, na ordem, só as que se aplicam:

- **Afazeres:** soma de `o.afazeres` com `feito:false` em todas as obras.
  N > 0 → "N afazeres pendentes" (singular/plural correto).
- **Parcelas:** só quando `hojeISO` é dia 1: gastos (de qualquer obra) com
  `data` no mês corrente e `data >= hojeISO` — na prática, as parcelas
  lançadas com data futura que caem neste mês. N > 0 → "N parcelas vencem
  este mês (R$ X)".
- **Lembrete:** nenhum gasto com `data === hojeISO` em nenhuma obra →
  "Lançou os gastos de hoje?".
- Corpo vazio → retorna `null` → não envia. Título: "Minhas Obras".

## Segredos e setup (uma vez, manual no console/GitHub)

- `npx web-push generate-vapid-keys`: chave pública vira constante
  `VAPID_PUBLICA` no app; privada vira secret `VAPID_PRIVATE` no GitHub.
- Service account (console Firebase → contas de serviço → gerar chave JSON)
  vira secret `FIREBASE_SERVICE_ACCOUNT`.
- Secret `VAPID_SUBJECT` = `mailto:stuchigiovani@gmail.com`.
- Publicar as rules novas do Firestore.

## Limpeza e falhas

- Envio que retorna 404/410 (inscrição morta) → cron apaga a entrada do doc.
- Outras falhas de envio: loga e segue pro próximo usuário; workflow não
  falha por um aparelho fora do ar.
- Permissão negada no browser: toggle volta pra desligado com aviso curto
  ("Permissão negada nas configurações do navegador").

## Isolamento e teste

- Cliente: funções `ativaPush()`/`desativaPush()` + render do painel em
  `app.js`, padrão do toggle de tema. `VAPID_PUBLICA` constante no topo.
- Cron: `notificacoes/envia.js` separa `montaResumo` (pura, exportada) do
  I/O; `package.json` próprio na pasta `notificacoes/`.
- Unit (Node, sem rede): `montaResumo` — casos: só afazeres; dia 1 com
  parcelas; lançou hoje (sem lembrete); nada a dizer (null); plurais.
- Manual: `workflow_dispatch` e conferir a notificação chegando no celular
  com o app fechado.
- E2E e regressões existentes continuam verdes; bump `obras-v21` no SW.

## Avisos

- GitHub desativa cron após 60 dias sem atividade no repo (commits regulares
  resolvem).
- Push exige PWA instalado + permissão concedida uma vez. iPhone: só iOS
  16.4+ com PWA na tela inicial.
- Horário do cron do GitHub varia alguns minutos (fila compartilhada) —
  aceitável pra resumo diário.

## Fora de escopo (YAGNI)

Sem tempo real (outro aparelho mudou dados), sem horário configurável, sem
escolher quais gatilhos, sem notificação por obra, sem FCM/Blaze.
