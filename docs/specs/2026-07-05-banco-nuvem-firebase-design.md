# Banco na nuvem (Firebase) — Design

Data: 2026-07-05 · Status: aprovado pelo usuário (opção A)

## Objetivo

Trocar o armazenamento local (localStorage) por banco na nuvem, 24/7, grátis,
com login funcionando de qualquer aparelho e sincronização em tempo real.
Site continua estático na Vercel — sem servidor próprio.

## Decisões (validadas com o usuário)

- **Serviço:** Firebase (Auth + Cloud Firestore), plano Spark (grátis, não pausa).
- **Usuários:** poucos (família/sócios). Cada um vê só as próprias obras — sem partilha.
- **Login:** e-mail + senha via Firebase Auth, com "esqueci minha senha" por e-mail.
  CPF deixa de ser credencial e vira campo do perfil no cadastro.
- **Custo:** 100% grátis, sempre.
- **Ícones no lugar de emojis:** fase 2, projeto separado (fora deste spec).

## Arquitetura

- **Modelo de dados:** um documento por usuário — `dados/{uid}` — contendo o
  mesmo objeto JSON que hoje vai pro localStorage (`{obras:[], config:{...}}`).
  Documento Firestore aguenta 1 MB ≈ décadas de gastos; aceitável.
- **Perfil:** documento `perfis/{uid}` com `{email, cpf, criado}`.
- **Escrita:** `save()` grava o blob no Firestore (`setDoc`). Debounce curto
  (~300 ms) pra não gravar a cada tecla.
- **Tempo real:** `onSnapshot` no documento do usuário; mudança vinda de outro
  aparelho atualiza `db` e chama `renderAll()`. Eco da própria escrita é
  ignorado (`hasPendingWrites`).
- **Offline:** persistência do Firestore ligada (`persistentLocalCache`).
  PWA abre e lança gastos sem internet; sincroniza ao reconectar.
- **Conflito:** última escrita vence (blob inteiro). Aceitável: usuário único
  por conta, multi-aparelho.
- **Segurança (Firestore rules):**
  ```
  match /dados/{uid}  { allow read, write: if request.auth.uid == uid; }
  match /perfis/{uid} { allow read, write: if request.auth.uid == uid; }
  ```
- **SDK:** Firebase JS v10+ modular via CDN (`https://www.gstatic.com/firebasejs/...`),
  import ESM em módulo próprio. App continua vanilla, sem bundler.

## Componentes / arquivos

| Arquivo | Papel |
|---|---|
| `cloud.js` (novo) | Config Firebase + init + API mínima: `cloudLogin`, `cloudSignup`, `cloudLogout`, `cloudResetSenha`, `watchDados(cb)`, `saveDados(blob)` |
| `auth.js` (reescrito) | Mesma tela, agora e-mail+senha; botão "esqueci minha senha"; cadastro cria conta no Firebase Auth + perfil com CPF |
| `app.js` (ajustes) | `load()/save()` trocados pela API do `cloud.js`; render disparado pelo snapshot |
| `index.html` | Campo login vira e-mail; link "esqueci minha senha"; scripts como `type="module"` onde preciso |
| `sw.js` | Não cachear chamadas do Firebase |

## Migração dos dados locais

No primeiro login em aparelho que tem dados antigos no localStorage
(`obras_data_v1::CPF`): se o documento na nuvem está vazio e existe blob local,
oferece "Importar dados deste aparelho pra sua conta?". Importou → marca flag
local pra não perguntar de novo. Nunca sobrescreve nuvem que já tem obras.

## O que o usuário precisa fazer (guiado)

1. Criar projeto no console.firebase.google.com (conta Google, grátis).
2. Ativar Authentication → e-mail/senha.
3. Criar banco Firestore (modo produção) e colar as rules acima.
4. Registrar app Web e me passar o objeto `firebaseConfig` (chaves públicas —
   podem ficar no código; a segurança vem das rules).

## Erros e estados

- Sem internet no primeiro login de um aparelho: não dá pra autenticar —
  mensagem clara "Conecte pra entrar da primeira vez". Depois disso, offline OK.
- Falha de gravação: Firestore re-tenta sozinho (fila offline). Sem UI de erro
  além de um aviso discreto se persistir.
- Login errado: mensagens em português na tela, iguais às de hoje.

## Testes

- `calc.js` intocado — 18 testes Node seguem valendo.
- E2E Playwright (Edge) contra Firebase Auth/Firestore **emulators**
  (`firebase emulators:start`) quando disponível na máquina; senão, conta de
  teste num projeto real.
- Fluxos: cadastro → lançar gasto → aparece em segunda aba/contexto em tempo
  real → logout → login → dados persistem → importação de dados locais antigos.

## Fora de escopo (YAGNI)

- Partilha de obras entre contas.
- Normalizar em tabelas/coleções por gasto.
- Troca de emojis por ícones (fase 2).
- Migração automática de senhas antigas (recadastro manual, poucos usuários).
