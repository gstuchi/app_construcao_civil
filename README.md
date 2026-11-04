<div align="center">

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/img/logo-escuro.svg">
  <img src="docs/img/logo.svg" width="260" alt="custta.">
</picture>

**Controle de custos e lucro por obra, na ponta do lápis.**

App de iPhone e PWA offline-first para acompanhar quanto cada obra custou, quanto o dinheiro renderia no banco no mesmo período (valor corrigido) e o lucro real na venda — bruto e acima do banco.

O site está em produção; o app de iPhone está sendo refeito em SwiftUI nativo, em teste no TestFlight, com a mesma conta e os mesmos dados.

![Status](https://img.shields.io/badge/status-em%20produ%C3%A7%C3%A3o-2ecc71)
![PWA](https://img.shields.io/badge/PWA-offline--first-3ad17e)
![Stack](https://img.shields.io/badge/stack-vanilla%20JS-f7df1e)
![iOS](https://img.shields.io/badge/iOS-SwiftUI-0a84ff)
![Deploy](https://img.shields.io/badge/deploy-Vercel-black)

https://github.com/user-attachments/assets/7c2f952a-e6cd-4389-88f7-c39ecff4bedb

</div>

---


## Sumário

- [Visão geral](#visão-geral)
- [Funcionalidades](#funcionalidades)
- [Arquitetura](#arquitetura)
- [Estrutura do projeto](#estrutura-do-projeto)
- [Por que a raiz tem tantos arquivos](#por-que-a-raiz-tem-tantos-arquivos)
- [Documentação](#documentação)
- [Licença](#licença)

## Visão geral

Custta é um aplicativo para construtores acompanharem o custo de suas obras no dia a dia, como site instalável (PWA) e como app de iPhone. O uso é primariamente no celular: ao pagar um fornecedor ou fechar uma compra, o gasto é lançado; a qualquer momento a pessoa confere o total gasto, o valor corrigido e a margem.

O produto é pensado para um usuário não técnico, com foco em **clareza em 5 segundos**: um número importante por vez, tipografia generosa e linguagem simples em PT-BR.

## Funcionalidades

- **Gastos por obra** organizados por tópico (terreno, fundação, acabamento…), pagos via Pix ou cartão parcelável.
- **Valor bruto × valor corrigido** — quanto o dinheiro renderia no banco no período, com taxa configurável (padrão 1% a.m.).
- **Lucro na venda** — apurado em dois eixos: bruto e acima do rendimento de banco.
- **Orçamento previsto × real** — por total ou por tópico, com o quanto já foi gasto de cada um.
- **A pagar** — parcelas e gastos futuros dos próximos 30 dias, mês a mês.
- **Afazeres** da obra e **busca** nos lançamentos, com filtro por mês.
- **Ciclo de vida da obra** em três fases: em construção → pronta (à venda) → vendida.
- **Gráficos**: distribuição por tópico (donut), evolução da obra e gasto por mês, com saída em PDF.
- **Relatório** da obra, agrupado por tópico, com a correção do período.
- **Simulador "Vale a pena?"** — margem e TIR mensal estimadas por preço e prazo de venda, comparadas ao banco.
- **Exportação** dos dados em JSON e CSV.
- **Offline-first** — dados persistidos no aparelho; sincronização em nuvem quando há rede.
- **Multiusuário** — conta por e-mail, Google ou Apple (Firebase), dados isolados por usuário.
- **Notificações** diárias de orçamento, afazeres, parcelas do mês e lembrete de lançar.

## Arquitetura

Aplicação **vanilla**: HTML, CSS e JavaScript servidos como arquivos estáticos,
sem framework e sem etapa de build no deploy. O estado do usuário é um único
documento no Firestore, sincronizado em tempo real e disponível offline pelo
IndexedDB do próprio SDK. `calc.js` concentra os cálculos financeiros e não toca
no DOM, o que o torna testável em Node; `cloud.js` é o único ponto de contato
com o Firebase; `sw.js` é network-first, então o cache só serve como retrato
para o modo offline.

O app nativo usa o mesmo documento. As regras dele ficam em `CusttaNucleo`,
cópia em Swift do `calc.js` e do `dados.js`; os vetores de
`tests/vetores/calc.json` fazem a CI falhar se os dois lados divergem.

Fluxo de dados, globais, segurança e camada nativa: **[docs/ARQUITETURA.md](docs/ARQUITETURA.md)**.

## Estrutura do projeto

| Caminho | Responsabilidade |
| --- | --- |
| `index.html` | markup da página — sem CSS e sem JavaScript inline (exigência da CSP) |
| `styles.css` | todo o CSS do app: temas e componentes |
| `app.js` | estado e render da interface |
| `calc.js` | cálculos puros de obra (correção monetária, parcelas) — sem DOM |
| `dados.js`, `cadastro.js` | regras do documento e do cadastro — sem DOM |
| `cloud.js`, `auth.js` | Firebase (Auth + Firestore) e a tela de login |
| `nativo.js`, `push.js`, `share.js`, `ui-confirm.js` | camada nativa, notificações, exportação e diálogos |
| `gestos.js`, `teclado.js`, `tema.js`, `icons.js` | gestos, teclado de valor, tema e ícones |
| `sw.js`, `manifest.json` | service worker e manifesto do PWA |
| `firestore.rules` | as regras que de fato protegem os dados |
| `vendor/` | SDKs do Firebase e do Sentry, versionados em vez de vindos de CDN |
| `app-ios/` | app nativo de iPhone em SwiftUI e o núcleo em Swift (`CusttaNucleo`); falta só a análise (gráficos, relatório e PDF) |
| `ios/` | projeto Capacitor do app para iPhone (o atual, até o nativo substituí-lo) |
| `api/`, `notificacoes/` | função de cron e o job de notificações — não fazem parte do app web |
| `tests/` | unidade, rules e suítes de browser |
| `docs/` | arquitetura, specs e planos |

## Por que a raiz tem tantos arquivos

O app não tem bundler nem etapa de build: os arquivos da raiz são exatamente o que o navegador baixa. `index.html` carrega cada script na ordem declarada, `styles.css` traz todo o CSS e `sw.js` lista esses mesmos arquivos no precache. `package.json` serve a testes, SDK local (`vendor/`), Capacitor e ao cron de `api/`; nada dele vai ao navegador. Os dois apps de iPhone ficam fora da raiz: o nativo em `app-ios/` e o Capacitor em `ios/`, que embrulha o site a partir de `www/`, gerado por `npm run build:www` e não versionado.

## Documentação

- **[docs/ARQUITETURA.md](docs/ARQUITETURA.md)** — fluxo de dados, globais, segurança, service worker, push e camada nativa.
- **[AGENTS.md](AGENTS.md)** — idioma, estilo de commit, como rodar os testes e o que quebra produção.
- **[PRODUCT.md](PRODUCT.md)** — usuário-alvo e princípios de design.
- **[docs/planejamento-app-store.md](docs/planejamento-app-store.md)** — as fases do caminho até a App Store.
- **[docs/specs/2026-10-06-app-nativo-design.md](docs/specs/2026-10-06-app-nativo-design.md)** — decisões e etapas do app nativo.
- **[docs/specs/](docs/specs/)** e **[docs/plans/](docs/plans/)** — o spec e o plano de cada funcionalidade, antes do código.

## Licença

Proprietária — ver [LICENSE](LICENSE). O código é público para leitura e
avaliação; uso, redistribuição e publicação em loja dependem de autorização
por escrito.
