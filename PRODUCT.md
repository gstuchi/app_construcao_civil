# Product

## Register

product

## Users

Pai do Giovani — construtor de casas de alto padrão, não técnico, meia-idade, usa principalmente no celular (Android, PWA instalado). Prefere letra maior (óculos de leitura). Contexto: lançar gastos da obra no dia a dia (ao pagar fornecedor, fechar compra) e conferir o total gasto e a margem. Giovani (filho) mantém o app.

## Product Purpose

Controle de custos de obras offline-first: gastos por obra separados por tópico (terreno, fundação, acabamento...), valor bruto e valor corrigido (quanto renderia no banco, taxa configurável, padrão 1% a.m.) e lucro real na venda — bruto e acima do banco. Obras têm 3 fases: em construção → pronta (à venda) → vendida. Tudo digitado manualmente, salvo no aparelho (localStorage), por usuário (login local CPF+senha). Sucesso = o pai abre o app, entende em 5 segundos quanto cada obra custou e, ao vender, confia no número do lucro.

## Brand Personality

Premium, calmo, impressionante. Dark tech elegante — profundidade de azul-noite, brilho pontual, sensação "isso parece caro" — mas com números grandes, legíveis e linguagem simples em PT-BR. Wow na primeira impressão, clareza no uso diário.

## Anti-references

- Site de trade/cripto agressivo: nada de verde/vermelho piscando, tickers, setas de urgência, cassino visual.
- Densidade de terminal: o brilho nunca pode custar legibilidade; um número importante por vez.

## Design Principles

1. **Saldo em 5 segundos** — a informação principal de cada tela domina a hierarquia; decoração nunca compete com número.
2. **Wow que não cansa** — efeitos (globo, glow) vivem no fundo e nas bordas; o conteúdo em si é calmo e estável.
3. **Letra generosa** — base de texto maior que o padrão; números financeiros sempre tabulares e grandes.
4. **Dark é a identidade** — tema único dark premium; sem modo claro para manter a assinatura visual consistente.
5. **Offline é sagrado** — nenhum efeito pode exigir rede, framework ou build; vanilla only.

## Accessibility & Inclusion

- Texto corpo ≥16px, números-chave ≥24px; contraste ≥4.5:1 sobre os fundos escuros (testar sobre o glow).
- `prefers-reduced-motion`: globo estático e transições instantâneas.
- Alvos de toque ≥44px (uso principal é celular).
