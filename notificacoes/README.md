# Notificações push — setup manual (uma vez)

O código já está pronto; falta o que só dá pra fazer no console do Firebase
e nas configurações do GitHub. Checklist:

## 1. Secrets no GitHub

Em github.com/gstuchi/app_construcao_civil → Settings → Secrets and
variables → Actions → New repository secret. Criar 4:

| Secret | Valor |
|---|---|
| `VAPID_PUBLIC` | chave pública gerada no `npx web-push generate-vapid-keys` (a mesma da constante `VAPID_PUBLICA` no app.js) |
| `VAPID_PRIVATE` | chave privada do mesmo comando (nunca commitar) |
| `VAPID_SUBJECT` | `mailto:stuchigiovani@gmail.com` |
| `FIREBASE_SERVICE_ACCOUNT` | JSON inteiro da service account (passo 2) |

## 2. Service account do Firebase

Console Firebase → projeto app-construcao-civil → ⚙ Configurações do
projeto → Contas de serviço → Gerar nova chave privada. Baixa um JSON.
Colar o conteúdo inteiro no secret `FIREBASE_SERVICE_ACCOUNT`. Apagar o
arquivo baixado depois.

## 3. Regras do Firestore

Console Firebase → Firestore → Regras. Adicionar junto das regras
existentes (dentro de `match /databases/{database}/documents`):

    match /push/{uid} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }

Publicar.

## 4. Testar

1. Fazer deploy (push pro main) e abrir o app no celular (PWA instalado).
2. Ajustes → Notificações → ligar o toggle → aceitar a permissão.
3. GitHub → aba Actions → workflow "push-diario" → Run workflow (o campo
   "Qual mensagem simular" escolhe entre `noite` e `manha`).
4. Notificação "Custta" chega no celular, mesmo com o app fechado.
   (Se não houver afazer pendente, parcela nem lembrete, o log do workflow
   mostra "nada a dizer" — criar um afazer antes de testar.)

## Avisos de orçamento

O resumo diário (`resumo.js`) também avisa de orçamento: para cada obra não
vendida com orçamento, o total e, no modo `topicos`, cada tópico previsto.
Avisa a partir de 90% (nível `perto`) e quando passa (nível `passou`); obra
vendida não entra. As frases de orçamento vêm antes das outras no corpo da
notificação, por serem a notícia mais importante do dia.

**Não repete todo dia.** Cada item (obra × total, obra × tópico) tem nível
`ok < perto < passou`. Só avisa quando o nível atual é maior que o último
avisado — a memória fica em `perfis/{uid}.avisosOrcamento`, gravada pelo
`enviar.js` depois do envio. Ficou no mesmo nível: silêncio. Desceu (aumentou
o orçamento, apagou gasto): a memória desce junto, e uma nova subida volta a
avisar.

Essa memória não fica em `push/{uid}` porque as rules dali exigem
`hasOnly(['subs', 'tokens'])` no documento inteiro — um campo a mais quebraria
a inscrição de push do cliente. Em `perfis/{uid}` o campo fica fora da lista
gravável pelo cliente (mesmo mecanismo do `plano`), então convive em paz com
o update de nome/fuso que o próprio usuário faz.

Conta sem perfil não recebe aviso de orçamento (sem memória, sem aviso —
silêncio é melhor que repetir todo dia), e o Admin SDK nunca cria perfil só
para gravar a memória. A gravação acontece depois de pelo menos uma entrega
bem-sucedida (Web Push ou FCM), ou quando não havia nada a dizer e algum
nível desceu (só pode ter sido descida, então não há envio para confirmar).
Se todos os envios falharem, a memória fica como estava e o aviso tenta de
novo no próximo disparo. Apagar a conta apaga `perfis/{uid}` e a memória vai
junto.

Mudança só de comentário nas rules — nenhum deploy de rules é necessário.

## Avisos

- Dois disparos por dia: 12:00 UTC (9h Brasília) e 21:00 UTC (18h), com
  variação de alguns minutos. A mensagem da manhã omite o "Lançou os gastos
  de hoje?" — às 9h o dia ainda não aconteceu e a pergunta seria sempre igual.
- GitHub desativa o cron após 60 dias sem atividade no repo (qualquer
  commit reativa).
- iPhone: só iOS 16.4+ com o PWA instalado na tela inicial.
- Sair da conta ou apagar a conta desliga as notificações deste aparelho (inscrição web e token do app iOS).

## Trocar para Vercel Cron (opcional, recomendado antes do lançamento)

O GitHub desativa cron após 60 dias sem atividade no repositório. A rota
`api/push-diario.js` e os `crons` do `vercel.json` já existem, mas respondem
503 enquanto `CRON_SECRET` não estiver configurado — nada é enviado em dobro.

1. Vercel → projeto → Settings → Environment Variables (Production):
   `CRON_SECRET` (valor aleatório longo), `FIREBASE_SERVICE_ACCOUNT`,
   `VAPID_PUBLIC`, `VAPID_PRIVATE`, `VAPID_SUBJECT` — mesmos valores dos secrets do GitHub.
2. **No mesmo deploy**, remover o bloco `schedule:` de `.github/workflows/push-diario.yml`
   (manter `workflow_dispatch` para teste manual) e ajustar `tests/workflow.test.cjs`.
3. Fazer o deploy. Vercel → Cron Jobs → "Run" em `/api/push-diario?periodo=noite`
   e conferir o log (`{"enviados":N,"removidos":M}`).
4. Para o app iOS, subir a chave APNs `.p8` em Firebase → Configurações do projeto →
   Cloud Messaging → Apple app configuration.
