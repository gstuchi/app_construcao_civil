# Product

## Register

product

## Users

Pai do Giovani — usuário não técnico, meia-idade, usa principalmente no celular (Android, PWA instalado) e às vezes no computador. Prefere letra maior (óculos de leitura). Contexto: conferir as finanças do dia a dia em momentos rápidos — fim do dia, ao pagar uma conta, ao fechar uma venda. Giovani (filho) mantém o app e também o usa.

## Product Purpose

Dashboard financeiro pessoal offline-first: gastos e receitas do mês, contas a pagar, faturamento do pequeno negócio e investimentos. Tudo digitado manualmente, salvo no aparelho (localStorage), por usuário (login local CPF+senha). Sucesso = o pai abre todo dia, entende o saldo em 5 segundos e confia no que vê.

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
