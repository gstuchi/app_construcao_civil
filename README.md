<div align="center">

# ObraControl

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

ObraControl é um aplicativo instalável (PWA) para construtores acompanharem o custo de suas obras no dia a dia. O uso é primariamente no celular: ao pagar um fornecedor ou fechar uma compra, o gasto é lançado; a qualquer momento a pessoa confere o total gasto, o valor corrigido e a margem.

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

Aplicação **vanilla**, sem framework, sem bundler e sem etapa de build. HTML, CSS e JavaScript clássico servidos como arquivos estáticos. A persistência é local (`localStorage`) com sincronização opcional via Firebase.

```text
Browser (PWA)
├── index.html         UI + CSS (temas, componentes, modal, toast)
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

## Decisões de projeto

- **Vanilla, sem build** — offline e simplicidade são requisitos de produto; nenhum efeito visual pode exigir rede, framework ou etapa de build.
- **Dark como padrão** — o tema escuro é a assinatura visual; o modo claro existe nos Ajustes com o mesmo rigor de contraste.
- **Legibilidade acima de densidade** — texto de corpo ≥16px, números-chave ≥24px, alvos de toque ≥44px; contraste alvo ≥4.5:1.
- **`prefers-reduced-motion`** — animações do globo e transições são desligadas quando o sistema pede.

---

<div align="center">
<sub>Feito para acompanhar obras reais, no celular, sem depender de conexão.</sub>
</div>
