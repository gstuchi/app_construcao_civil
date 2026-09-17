<div align="center">

# custta.

**Controle de custos e lucro por obra, na ponta do lápis.**

PWA offline-first para acompanhar quanto cada obra custou, quanto o dinheiro renderia no banco no mesmo período (valor corrigido) e o lucro real na venda — bruto e acima do banco.

![Status](https://img.shields.io/badge/status-em%20produ%C3%A7%C3%A3o-2ecc71)
![PWA](https://img.shields.io/badge/PWA-offline--first-3ad17e)
![Stack](https://img.shields.io/badge/stack-vanilla%20JS-f7df1e)
![Build](https://img.shields.io/badge/build-nenhum-lightgrey)
![Deploy](https://img.shields.io/badge/deploy-Vercel-black)

</div>

---


## Sumário

- [Visão geral](#visão-geral)
- [Funcionalidades](#funcionalidades)
- [Arquitetura](#arquitetura)
- [Rodar localmente](#rodar-localmente)
- [Testes](#testes)
- [Deploy](#deploy)
- [Estrutura do projeto](#estrutura-do-projeto)
- [Decisões de projeto](#decisões-de-projeto)

## Visão geral

Custta é um aplicativo instalável (PWA) para construtores acompanharem o custo de suas obras no dia a dia. O uso é primariamente no celular: ao pagar um fornecedor ou fechar uma compra, o gasto é lançado; a qualquer momento a pessoa confere o total gasto, o valor corrigido e a margem.

O produto é pensado para um usuário não técnico, com foco em **clareza em 5 segundos**: um número importante por vez, tipografia generosa e linguagem simples em PT-BR.

## Funcionalidades

- **Gastos por obra** organizados por tópico (terreno, fundação, acabamento…), pagos via Pix ou cartão parcelável.
- **Valor bruto × valor corrigido** — quanto o dinheiro renderia no banco no período, com taxa configurável (padrão 1% a.m.).
- **Lucro na venda** — apurado em dois eixos: bruto e acima do rendimento de banco.
- **Ciclo de vida da obra** em três fases: em construção → pronta (à venda) → vendida.
- **Gráficos**: distribuição por tópico (donut) e gasto por mês.
- **Simulador "Vale a pena?"** — margem estimada por preço de venda.
- **Offline-first** — dados persistidos no aparelho; sincronização em nuvem quando há rede.
- **Multiusuário** — login por conta (Firebase), dados isolados por usuário.

## Arquitetura

Aplicação **vanilla**, sem framework e sem etapa de build no deploy. HTML, CSS e JavaScript são servidos como arquivos estáticos. Auth mantém a sessão; Firestore persiste dados em IndexedDB e sincroniza por usuário. localStorage guarda preferências e marcador de limpeza de cache.

```text
Browser (PWA)
├── index.html         estrutura da UI
├── styles.css         temas, componentes, modal, toast
├── dados.js           validação do documento e limites de texto
├── app.js             estado, render, formulários, modal, toast
├── calc.js            regras de negócio puras (correção, parcelas) — sem DOM
├── auth.js ─┐
│            ├──────►  cloud.js  ──►  Firebase (Auth + Firestore)
└── (dados) ─┘
└── sw.js              service worker (network-first) → funciona offline
```

- **`calc.js`** concentra os cálculos financeiros e não toca no DOM, o que o torna testável isoladamente em Node.
- **`cloud.js`** é o único ponto de contato com o Firebase. As chaves de configuração são públicas por natureza; a segurança é imposta pelas *rules* do Firestore.
- **`sw.js`** usa estratégia *network-first*: online sempre busca a versão mais recente, e o cache serve apenas como retrato para o modo offline.



## Estrutura do projeto

| Caminho | Responsabilidade |
| --- | --- |
| `index.html` | Estrutura da página, todo o CSS (temas claro/escuro, componentes) e markup do modal/toast |
| `app.js` | Lógica da interface: render, formulários, modais, notificações |
| `calc.js` | Cálculos puros de obra (correção monetária, parcelas) — sem DOM |
| `auth.js` | Tela de login (Firebase, e-mail + senha) |
| `cloud.js` | Integração com Firebase (Auth + Firestore) |
| `icons.js` | Ícones SVG inline |
| `splash.js`, `globe.js` | Splash de abertura e globo de pontos (100% offline) |
| `sw.js` | Service worker (network-first) |
| `manifest.json` | Manifesto PWA |
| `tests/` | Testes de unidade em Node (`.cjs`) |
| `notificacoes/` | Backend de notificações push (Node + Firebase) — ver `notificacoes/README.md` |
| `docs/` | Especificações e notas de design |


## Por que a raiz tem tantos arquivos

O app não tem bundler nem etapa de build: os arquivos da raiz são exatamente o que o navegador baixa. `index.html` carrega cada script na ordem declarada, `styles.css` traz todo o CSS e `sw.js` lista esses mesmos arquivos no precache. `package.json` existe para testes, manutenção do SDK local (`vendor/`), Capacitor e a função de cron em `api/` — nada dele vai para o navegador. O projeto iOS fica em `ios/`; `www/` é gerado por `npm run build:www` e não é versionado.

## Segurança e ferramentas — Fase 3

Sentry usa SDK 10.74.0 local em `vendor/sentry/` (`npm run vendor:sentry`).
`sentry-config.js` contém somente DSN público, ambiente e release. DSN vazio
desativa envio; ao configurar, permitir exatamente seu host em `connect-src`
no `vercel.json`. Nunca incluir token administrativo no cliente.
`sentry.js` envia categoria e stack técnica sem mensagens livres, conta ou
dados de obras. Sem replay/tracing, até 20 eventos por carregamento, duplicatas
limitadas por minuto e sem persistência offline. `tests/browser/sentry.cjs`
inspeciona envelopes reais do SDK com transporte interceptado.

O SDK Firebase 12.18.0 fica em `vendor/firebase/`, com licença e módulos versionados. Não é carregado de gstatic.com. npm é ferramenta de manutenção e testes; abrir e publicar o app continua sem build. `npm run vendor:firebase` usa esbuild somente para atualizar essa distribuição local e deve ser seguido de revisão dos arquivos e atualização do cache em `sw.js`.

- `npm ci`: instala ferramentas com versões do lockfile.
- `npm test`: testes unitários e regras no emulador Firestore (Java 21).
- `npm ci --prefix notificacoes` e `npx playwright install chromium`: preparação dos testes de navegador.
- `npm run test:browser`: inicia servidor e emuladores, testa UI, CSP, SDK offline, sincronização e exclusão. Não usa contas ou documentos de produção.
- GitHub Actions executa os testes em pushes para main e pull requests.

CSP permite scripts e estilos locais, sem `unsafe-inline`. CSS está em arquivos; propriedades dinâmicas dos gráficos são controladas por JavaScript. Textos são escapados na renderização. Novas edições limitam nome a 120, descrição e afazer a 500, tópico a 80 caracteres. Dados antigos não são truncados por esses limites; normalização preserva campos desconhecidos para compatibilidade entre versões. Taxa aceita valores maiores que zero e até 20% ao mês; entrada inválida mostra mensagem e mantém taxa anterior.

## Empacotamento nativo — Fase 4

O mesmo código roda como app iOS via Capacitor (`ios/`, `npm run build:www`, `npm run cap:sync`), com share sheet, push nativo (FCM), haptics, barra de status e splash nativos, sem mudar a arquitetura vanilla nem exigir build no deploy web. Código concluído em `feat/fase4`; build, TestFlight e push real dependem de matrícula Apple — ver [checklist de aparelho](docs/plans/2026-09-16-fase4-checklist-aparelho.md).
