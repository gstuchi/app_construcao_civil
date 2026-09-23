# Cadastro completo — design

**Data:** 22/09/2026 · **Branch:** `feat/cadastro-completo`

## Objetivo

Hoje o cadastro pede só e-mail e senha de 6 caracteres. Queremos:

1. regras de senha de verdade, visíveis enquanto a pessoa digita;
2. saber quem é a pessoa (nome, sobrenome opcional);
3. saber como ela conheceu o Custta (Instagram, indicação…), pra orientar divulgação.

Sucesso = alguém de fora cria conta sem ajuda, entende na hora por que a senha foi recusada, e o perfil em `perfis/{uid}` chega com nome e origem.

## Fora do escopo

- Política de senha no servidor (Firebase Auth → *Password policy* no console). É o único lugar que impede burlar a regra chamando a API direto; fica como recomendação pós-merge, porque exige acesso ao console.
- Login social (Apple/Google), CPF, telefone.
- Mudar o fluxo de login: quem já tem senha de 6 caracteres continua entrando.

## Decisões

| Tema | Decisão | Por quê |
| --- | --- | --- |
| Senha | ≥ 8 caracteres, ≥ 1 letra, ≥ 1 número, ≤ 128, diferente do e-mail, fora de uma lista curta de senhas óbvias | Forte o bastante sem virar charada para usuário não técnico (PRODUCT.md) |
| Confirmação | Campo "Confirmar senha" no cadastro e na troca de senha | Evita conta criada com senha digitada errada no celular |
| Feedback | Checklist ao vivo sob o campo (✓ por regra) + mensagem única no envio | Mostra *o que falta* em vez de só recusar |
| iOS | `passwordrules="minlength: 8; required: digit; required: lower, upper;"` | Senha forte sugerida pelo iCloud Keychain já nasce válida |
| Nome | Obrigatório, 2–60 caracteres após `trim` | Pedido do Giovani; é usado em Ajustes |
| Sobrenome | Opcional, ≤ 80 | "sobrenome opcional" |
| Origem | Obrigatória, lista fechada: `instagram`, `indicacao`, `google`, `tiktok`, `youtube`, `outro` | Lista fechada dá número comparável; rules validam |
| Detalhe da origem | Opcional, ≤ 80, só aparece para `indicacao` ("Quem indicou?") e `outro` ("Onde?") | Indicação nominal vale ouro; os demais não precisam |
| Onde salva | `perfis/{uid}`: `nome`, `sobrenome`, `origem`, `origemDetalhe` (vazios são omitidos) | Já é o documento de perfil; `dados/{uid}` é só obras/config |
| Uso do nome | Ajustes › Conta mostra "Nome Sobrenome" acima do e-mail + botão **Editar nome** | Dado pessoal sem uso é só passivo LGPD; e quem já tem conta consegue preencher |
| Origem editável? | Não | Dado de aquisição, registrado uma vez |

## Arquitetura

### `cadastro.js` (novo) — `OBRA_CADASTRO` + `module.exports`

Regras puras, zero DOM, no padrão UMD de `dados.js`:

- `REGRAS_SENHA` — lista `{ id, texto }` na ordem do checklist.
- `validaSenha(senha, email)` → `{ ok, regras: [{ id, texto, ok }], erro }` — `erro` é a primeira regra falhando, em texto pronto para a UI.
- `ORIGENS` — `[{ id, nome, detalhe? }]`; `detalhe` é o rótulo do campo extra.
- `LIMITES_PERFIL` — `{ nome: 60, sobrenome: 80, origemDetalhe: 80 }`.
- `normalizaPerfil({ nome, sobrenome, origem, origemDetalhe })` → `{ ok, erro, perfil }` — faz `trim`, colapsa espaços, descarta detalhe quando a origem não aceita, omite vazios.
- `normalizaNome({ nome, sobrenome })` → mesmo formato, só os dois campos (usado no "Editar nome").

Carregado em `index.html` antes de `auth.js` e `ui-confirm.js`, entra no `ASSETS` do `sw.js`.

### `cloud.js`

- `signup(email, senha, perfil)` — grava `{ email, criado, tz, ...perfil }`. O perfil chega já normalizado; `cloud.js` não revalida (as rules são a fronteira).
- `lerPerfil()` → `{ nome, sobrenome }` ou `null` (`getDoc` em `perfis/{uid}`; erro → `null`, não quebra Ajustes).
- `salvarNome(nome, sobrenome)` — `updateDoc`; sobrenome vazio vira `deleteField()`.
- `trocarSenha` passa a exigir a regra nova via `OBRA_CADASTRO.validaSenha` (código `auth/weak-password` quando falha).

### `auth.js` + `index.html`

Formulário de cadastro, nesta ordem: Nome · Sobrenome (opcional) · E-mail · Senha (+ checklist) · Confirmar senha · Como conheceu (select) · detalhe condicional · Criar conta. Validação no envio na mesma ordem; foco vai para o primeiro campo inválido. `msgErro` de `weak-password` passa a citar a regra nova. Sem `style=` nem script inline (CSP).

### `ui-confirm.js`

- "Trocar senha": campo de confirmação + checklist, rótulo "Nova senha" sem "(mínimo 6)".
- Novo tipo `abrir('nome')`: dialog com Nome e Sobrenome, salva por `CLOUD.salvarNome`.

### `app.js`

`renderAjustes` mostra `#ajNome` (via `CLOUD.lerPerfil`, cacheado por uid na sessão) e liga `#ajNomeEditar`.

### `firestore.rules`

- `create`: `hasOnly(['email','criado','tz','nome','sobrenome','origem','origemDetalhe'])`.
- `update`: `affectedKeys().hasOnly(['email','tz','nome','sobrenome'])`.
- `perfilClienteOk()` ganha: `nome` string 1–60, `sobrenome` string ≤ 80, `origem` ∈ lista, `origemDetalhe` string ≤ 80 — todos opcionais (perfis antigos seguem válidos; o obrigatório é garantido no cliente).
- `plano` e `cpf` continuam rejeitados.

**Ordem de deploy:** as rules novas aceitam o cliente antigo e o novo. Então `npm run rules:deploy` **antes** do merge em `main` — o contrário faz o cadastro em produção falhar ao gravar o perfil.

### `privacidade.html`

Lista de dados coletados ganha nome, sobrenome (opcional) e como conheceu o Custta, com a finalidade (identificar a conta em Ajustes e entender por onde o app é conhecido). Versão vigente → 22 de setembro de 2026.

## Erros

- Falha de rede no cadastro → mensagem existente ("Sem internet…").
- Conta criada mas perfil não gravado (raro): comportamento atual preservado — a conta existe; o nome pode ser preenchido depois em Ajustes.
- `lerPerfil` falhando → Ajustes mostra só o e-mail e o botão "Adicionar nome".

## Testes

- `tests/cadastro.test.cjs` — cada regra de senha, e-mail igual, lista óbvia, normalização de perfil/nome, origem inválida, detalhe descartado.
- `tests/rules.test.mjs` — cadastro com campos novos aceito; origem fora da lista, nome > 60, tipo errado, chave desconhecida rejeitados; update de nome/sobrenome aceito; update de `origem` rejeitado.
- `tests/conta.test.mjs` / stub — `trocarSenha` recusa senha fraca antes de reautenticar.
- `tests/privacidade.test.cjs` — nova data e menção aos campos.
- `tests/browser/cadastro.cjs` (Playwright + emuladores, entra no `rodar.cjs`) — checklist reage, senha fraca bloqueia, confirmação diferente bloqueia, origem "Indicação" mostra o detalhe, cadastro completo grava perfil e Ajustes mostra o nome, editar nome persiste.
- Validação manual com `agent-browser` no mobile (390×844) e desktop, dark e claro.
