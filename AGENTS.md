# Como contribuir com o Custta

Instruções para quem for mexer neste repositório — pessoa ou agente. O
documento técnico longo é o [CLAUDE.md](CLAUDE.md), a arquitetura está em
[docs/ARQUITETURA.md](docs/ARQUITETURA.md) e o produto, em
[PRODUCT.md](PRODUCT.md).

## Idioma

Tudo em português do Brasil: nomes de variáveis e funções, comentários, textos
da interface, mensagens de commit e descrição de PR. Os termos são os do
canteiro — `obra`, `gasto`, `topico`, `fase`, `corrigido`, `afazer`.

## Commits

- Assunto em minúsculas, sem acento, no formato `tipo: o que mudou`.
- Tipos em uso: `feat`, `fix`, `docs`, `test`, `chore`, `refactor`.
- **Um commit por funcionalidade.** Nunca junte duas implementações
  independentes no mesmo commit.
- Suba um commit por vez e confira que cada push passou.
- Autor único: Giovani Stuchi. Não acrescente linha de coautoria.
- `main` é protegida: a verificação da CI precisa passar e force push é
  bloqueado. Trabalhe em branch e abra pull request.

## Testes

Primeiro, `npm ci` (instala as ferramentas nas versões do lockfile).

```bash
npm run test:unit     # node --test; sem rede e sem browser; é o que roda mais
npm run test:rules    # emulador do Firestore; exige Java 21
npm run test:browser  # emuladores + Playwright; exige Java 21 e npx playwright install chromium
npm test              # unit + rules
```

Um arquivo ou um teste só:

```bash
node --test tests/calc.test.cjs                              # um arquivo só
node --test --test-name-pattern="LICENSE" tests/docs.test.mjs  # um teste só (arquivos que usam node:test)
```

As rules só rodam com o emulador — use `npm run test:rules`.

Para dirigir o app à mão num browser de verdade, suba
`node tests/browser/servidor.cjs` — ele serve a raiz em `:8123` com os mesmos
headers do `vercel.json`. As suítes de `tests/browser/` que usam SDK real
(`fase1`, `fase2`, `fase3`, `persistencia`, `sync`) precisam dos emuladores e
de `CUSTTA_EMULADORES=1`; as de dados sintéticos (`mobile`, `cartao`, `nativo`,
`contraste`) não precisam de nada além do servidor.

## O que quebra produção se for ignorado

1. **Arquivo JS ou CSS novo na raiz** entra na lista `ASSETS` do `sw.js` **e**
   incrementa o `CACHE` (`obras-vNN`). Sem o incremento, quem já instalou o app
   continua vendo a versão velha offline. Essa mesma lista alimenta o
   `scripts/build-www.mjs`, que monta o app iOS.
2. **A CSP é estrita** (`vercel.json`): nada de `<style>`, de `style="..."` em
   atributo nem de `onclick=` no HTML. CSS vai para `styles.css`.
3. **Mudar o formato do estado** sem atualizar `firestore.rules` derruba a
   escrita em produção. Edite as rules, some um caso em `tests/rules.test.mjs`,
   rode `npm run test:rules` e `npm run rules:deploy`. Nunca edite rules pelo
   console do Firebase.
4. **Os SDKs ficam versionados em `vendor/`**, gerados por
   `npm run vendor:firebase` e `npm run vendor:sentry`. A CI falha se o diff
   não estiver limpo.
5. **`confirm()` e `alert()` são proibidos** — somem no WKWebView do app iOS.
   Use `OBRA_CONFIRM.perguntar` e `OBRA_CONFIRM.avisar`.
6. **Nada de dependência de runtime no browser.** O app não tem bundler nem
   etapa de build; o `package.json` serve a teste, manutenção de SDK local,
   Capacitor e à função de cron em `api/`.

## Segredos

O `.gitignore` bloqueia service accounts, `.env`, chaves VAPID e certificados
iOS. A `apiKey` do Firebase em `cloud.js` é pública por design e é a única
credencial que pode aparecer num commit.

## Onde ficam spec e plano

Funcionalidade grande começa por um spec em
`docs/specs/AAAA-MM-DD-nome-design.md` e, quando o trabalho é longo, um plano
em `docs/plans/`. Antes de alterar uma tela existente, leia o spec dela.
