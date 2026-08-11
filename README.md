# ObraControl

Controle de custos e lucro por obra, na ponta do lápis.

PWA offline-first pra acompanhar quanto cada obra custou, quanto renderia no banco (valor corrigido) e o lucro real na venda. Feito pra rodar no iPhone, instalado pela Tela de Início, com números grandes e linguagem simples em PT-BR.

## O que faz

- **Gastos por obra**, separados por tópico (terreno, fundação, acabamento…), com pagamento em Pix ou cartão (parcelável).
- **Valor bruto × valor corrigido** — quanto o dinheiro renderia no banco no período, taxa configurável (padrão 1% a.m.).
- **Lucro na venda** — bruto e acima do banco.
- **3 fases da obra**: em construção → pronta (à venda) → vendida.
- **Gráficos**: donut por tópico e gasto por mês.
- **Vale a pena?** — simulador de margem por preço de venda.
- **Offline**: tudo salvo no aparelho; sincroniza na nuvem quando há rede.

## Stack

Vanilla puro — **sem build, sem framework, sem npm** no app. HTML + CSS + JavaScript clássico, servido como arquivo estático.

| Arquivo | Papel |
| --- | --- |
| `index.html` | Estrutura, todo o CSS (temas, componentes), markup do modal/toast |
| `app.js` | Lógica da UI, render, formulários, modal, toast |
| `calc.js` | Cálculos puros de obra (correção, parcelas) — sem DOM, testável em Node |
| `auth.js` | Tela de login (Firebase e-mail + senha) |
| `cloud.js` | Único arquivo que fala com Firebase (auth + Firestore) |
| `icons.js` | Ícones SVG inline |
| `splash.js` / `globe.js` | Splash de abertura e globo de pontos (100% offline) |
| `sw.js` | Service worker (network-first; cache é o retrato pro offline) |
| `manifest.json` | Manifesto PWA |

Dados no `localStorage` por usuário; nuvem via Firebase (as chaves no `cloud.js` são públicas — segurança vem das rules do Firestore).

## Rodar local

Não tem build. Serve a raiz do repo em HTTP e abre no browser:

```bash
# qualquer servidor estático serve. Ex com Python:
python -m http.server 8123
# depois abre http://localhost:8123/
```

No iPhone da mesma rede WiFi: `http://IP-DA-MAQUINA:8123/`.

## Deploy

Push na `main` → Vercel builda e publica sozinho (site estático, sem passo de build).

Ao mudar arquivos do app, subir o número do cache no `sw.js` (`const CACHE = 'obras-vNN'`) pra forçar atualização nos aparelhos.

## Testes

Cálculos puros (`calc.js`) rodam em Node, sem dependências:

```bash
node tests/calc.test.cjs
node tests/moeda.test.cjs
node tests/icons.test.cjs
```

## Notificações push

Backend separado em `notificacoes/` (Node + Firebase). Ver `notificacoes/README.md`.
