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
3. GitHub → aba Actions → workflow "push-diario" → Run workflow.
4. Notificação "Minhas Obras" chega no celular, mesmo com o app fechado.
   (Se não houver afazer pendente, parcela nem lembrete, o log do workflow
   mostra "nada a dizer" — criar um afazer antes de testar.)

## Avisos

- Cron roda 21:00 UTC = 18h Brasília, com variação de alguns minutos.
- GitHub desativa o cron após 60 dias sem atividade no repo (qualquer
  commit reativa).
- iPhone: só iOS 16.4+ com o PWA instalado na tela inicial.
- Sair da conta não desliga as notificações do aparelho; desligue o toggle antes de trocar de conta.
