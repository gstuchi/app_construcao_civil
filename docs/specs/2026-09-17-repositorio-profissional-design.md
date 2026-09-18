# Apresentação do repositório — licença, capturas e documentação

Data: 2026-09-17 · Branch: `chore/repo-profissional`

## Objetivo

Fazer o repositório público parecer, à primeira vista, o que ele já é por dentro: um produto mantido com testes, CI e decisões documentadas. Cinco entregas, nenhuma delas mexe em código que roda no app.

Não é objetivo reescrever histórico de commits antigos (exigiria `push --force`, que a proteção de `main` bloqueia) nem mudar o produto.

## 1 — LICENSE proprietária

`LICENSE` na raiz. Copyright `2026 Giovani Stuchi`, todos os direitos reservados. O texto permite ler e avaliar o código; proíbe uso comercial, redistribuição, obra derivada e publicação em loja de aplicativos. Português, com um parágrafo final em inglês para leitor de fora.

`package.json` ganha `"license": "UNLICENSED"` (convenção npm para código proprietário). `"private": true` já existe.

O detector de licença do GitHub não reconhece texto proprietário customizado — a barra lateral vai mostrar o arquivo sem rótulo de licença conhecida. É o comportamento esperado e correto: rótulo só existe para licença padrão.

## 2 — Capturas no topo do README

Três capturas, nesta ordem, logo abaixo dos badges:

| Arquivo | Tela | Por quê |
| --- | --- | --- |
| `docs/img/inicio.png` | lista de obras + comparativo | mostra o produto inteiro numa imagem |
| `docs/img/obra.png` | os quatro KPIs da obra | mostra o valor corrigido, que é a ideia do app |
| `docs/img/graficos.png` | evolução e gasto por mês | mostra que há profundidade além da lista |

Renderizadas numa tabela de três colunas (o GitHub só coloca imagens lado a lado dentro de tabela), `width="260"`, cada uma com `alt` descritivo.

As fontes são as capturas 1290×2796 da loja. Para o README elas são reduzidas a 430×932 (1× do viewport), o que leva cada arquivo de ~800 KB para ~180 KB. `scripts/screenshots-loja.mjs` passa a gravar essas três versões reduzidas direto em `docs/img/`, para a próxima geração não depender de redimensionamento manual. A flag é `--readme`; sem ela o script continua gerando só as cinco da loja no diretório de saída.

`.vercelignore` ganha `docs/` — documentação e imagens não precisam ir para o deploy. Nada servido em produção mora em `docs/`.

## 3 — `docs/superpowers/` → `docs/specs/` + `docs/plans/`

`git mv` das duas pastas, preservando histórico. Depois, atualização de toda referência ao caminho antigo:

- `README.md` (link do checklist de aparelho)
- `CLAUDE.md` (seções "App iOS" e "Fluxo de trabalho")
- `teclado.js` (comentário de cabeçalho)
- `docs/planejamento-app-store.md` (duas ocorrências)
- 8 documentos dentro das pastas movidas

`CLAUDE.md` e `AGENTS.md` passam a registrar explicitamente que spec novo nasce em `docs/specs/AAAA-MM-DD-nome-design.md` e plano em `docs/plans/`. Sem esse registro, a próxima execução da skill de brainstorming recria `docs/superpowers/` pelo caminho padrão dela.

## 4 — `AGENTS.md` como instrução de contribuição

O conteúdo atual é um prompt de persona ("Respond terse like smart caveman", `/caveman lite|full|ultra|wenyan`). Ele sai do repositório e vai para `~/.claude/CLAUDE.md`, onde continua valendo para todos os projetos. O arquivo no repositório passa a conter, em pt-BR:

- **Idioma** — código, identificadores, comentários, UI e commits em português.
- **Commits** — `feat:`/`fix:`/`docs:`/`chore:`/`test:`, minúsculas, sem acento no assunto; um commit por feature; push um commit por vez; nunca commitar em `main` direto (é protegida).
- **Testes** — as quatro suítes, o que cada uma exige (Java para rules, emuladores e `CUSTTA_EMULADORES=1` para as suítes de SDK real, `node tests/browser/servidor.cjs` para dirigir o app à mão) e como rodar um arquivo só.
- **Regras que quebram produção** — CSP sem nada inline; arquivo novo na raiz entra em `ASSETS` do `sw.js` e incrementa `CACHE`; mudar o formato do estado exige editar `firestore.rules` e somar caso em `tests/rules.test.mjs`; SDK vive em `vendor/` e a CI falha se o diff não estiver limpo; `confirm()`/`alert()` são proibidos.
- **Onde ficam spec e plano.**

`CLAUDE.md` continua sendo o documento técnico longo; `AGENTS.md` é o resumo operacional e aponta para ele. Não há `CONTRIBUTING.md` — seria um terceiro arquivo dizendo o mesmo e envelheceria sozinho.

## 5 — `docs/ARQUITETURA.md`

Documento novo com:

1. **Fluxo de dados** em diagrama Mermaid (o GitHub renderiza nativamente): mutação em `db` → `save()` → `CLOUD.saveDados` (debounce 300 ms, sobrescreve o documento inteiro) → Firestore → `onSnapshot` → descarte do eco (`pendingWrites`/`localDirty` + `canon()`) → `renderAll()`.
2. **Tabela de globais** — o que cada arquivo da raiz expõe e qual é seu papel.
3. **Fronteira de segurança** — `apiKey` pública por design, segurança em `firestore.rules`, consequência de adicionar chave de topo em `db`.
4. **Service worker** — network-first, `ASSETS`, regra do `CACHE`.
5. **Notificações** — Web Push na web, FCM no iOS, `push/{uid}` em documento separado e por quê, os dois caminhos de cron.
6. **Camada nativa** — Capacitor, `nativo.js` como único ponto que toca `window.Capacitor`, `build-www` derivando a lista de arquivos do `sw.js`.

O README perde a seção "Arquitetura" com o diagrama ASCII (que está errado: diz que o CSS mora no `index.html`, o que deixou de ser verdade quando `styles.css` nasceu) e as seções longas "Segurança e ferramentas — Fase 3" e "Empacotamento nativo — Fase 4". No lugar entra um parágrafo de visão geral e o link para `docs/ARQUITETURA.md`. A tabela "Estrutura do projeto", hoje desatualizada, é corrigida e enxugada.

## Testes

`tests/docs.test.mjs`, novo, no `npm run test:unit`:

1. Nenhum arquivo versionado cita `docs/superpowers` (varre com `git ls-files`, ignora `node_modules` e `ios`).
2. `LICENSE` existe, cita "Giovani Stuchi" e o ano; `package.json` declara `UNLICENSED`.
3. `docs/ARQUITETURA.md` existe e contém um bloco ```mermaid.
4. Todo link relativo em `README.md`, `CLAUDE.md`, `AGENTS.md` e nos arquivos de `docs/` aponta para um arquivo que existe (checador de links).
5. As três imagens do README existem em `docs/img/` e têm largura 430 (lê o cabeçalho IHDR do PNG).
6. `AGENTS.md` não contém "caveman".

Além disso: `npm run test:unit`, `npm run test:rules` e `npm run test:browser` verdes, e conferida da produção com agent-browser depois do merge (o único item que toca deploy é `.vercelignore`).

## Fora do escopo

Reescrever mensagens de commits antigos, `CONTRIBUTING.md`, templates de issue e PR, tradução do README para inglês, mudança de produto.
