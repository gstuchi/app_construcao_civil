# Vidro máximo: aurora e conteúdo em vidro

Data: 2026-09-28. Amplia o spec do Liquid Glass (`2026-09-28-vidro-liquido-design.md`, PR #23). O pedido do Giovani, com um print do app Pierre: "dá pra fazer uma versão de teste com muito liquid glass, tipo esse exemplo de app". Depois de testar a versão no iPhone (TestFlight build 10.1): "curti demais, pode mergear".

## Por que o vidro do #23 parecia pouco

O vidro só aparece quando há algo colorido passando por baixo. O Pierre parece cheio de vidro porque tem um degradê vivo atrás do topo da tela; sobre ele, chips, botões redondos e a barra de abas mostram a cor desfocada. O Custta tinha fundo escuro quase liso e vidro só na navegação, então o material existia mas quase não se via.

## Decisões

- **Aurora nas cores do Custta** (escolha do Giovani entre isso e o arco-íris do Pierre): manchas desfocadas nas cores do skin (esmeralda ou azul), presas ao topo da tela e apagando para baixo. Deriva devagar (26 s por ida); parada com movimento reduzido; some na impressão. O globo continua por cima dela.
- **Conteúdo também é vidro**: cards (menos o de saldo, que continua cor sólida), painéis, indicadores e o grupo da lista de obras. Isso amplia a regra "vidro só na navegação" do spec anterior. Os invólucros transparentes (cabeçalho da obra, moldura da lista) ficam sem vidro, porque um `backdrop-filter` neles viraria raiz de fundo e o vidro de dentro deixaria de ver a aurora.
- **Nunca vidro dentro de vidro.** O teste de navegador confere isso em toda tela visível da obra, e a verificação manual passou em todas as telas e na sheet de orçamento, no celular e no desktop.
- **Ações da obra em pílula de vidro** ("Editar orçamento", "Ver gráficos", "Relatório" e as outras secundárias). O botão primário continua cor sólida: cor chapada ao lado do vidro é o que faz o vidro aparecer, como o botão de destaque do Pierre.
- **Chips**: o selecionado vira vidro claro fosco (escuro sólido no tema claro), os outros um vidro fino com contorno de luz.
- **Borda de luz mais forte** em todo o vidro (`--vidro-brilho`): 1 px claro em cima, um reflexo fraco embaixo e o contorno de 0,5 px.
- **Leitura sobre a aurora**: o subtítulo da lista e o da obra passam para a cor do texto nos dois temas (o cinza sumia); no escuro, os botões da barra (voltar e sair) também, com uma sombra suave no texto.

## Material

Tokens novos nos quatro combos tema×cor:

| Token | Papel |
| --- | --- |
| `--aurora-1` a `--aurora-4` | cores RGB das manchas da aurora |
| `--aurora-a` | força da aurora (≈0,9 no escuro, ≈0,5 no claro) |
| `--vidro-conteudo` | preenchimento do vidro de conteúdo |
| `--vidro-luz-conteudo` | brilho dentro do filtro do conteúdo (0,62 no escuro, 1,06 no claro), para o texto branco ler sobre a aurora |
| `--vidro-filtro-conteudo` | `saturate(170%) blur(28px) brightness(var(--vidro-luz-conteudo))` |

Os recuos continuam valendo: sem `backdrop-filter`, com transparência reduzida ou com contraste aumentado, `--vidro-conteudo` vira `--surface-solid` e o filtro vira `none`.

## Risco conhecido

Vidro em muitos cards custa mais para pintar, principalmente ao rolar no iPhone. Nos testes, a página mais pesada expôs uma corrida no teste "com o teclado aberto a sheet cabe na área visível" (o aviso do `visualViewport` chegava depois do valor simulado); o teste passou a esperar dois quadros. Se a rolagem pesar no aparelho, o primeiro recuo é tirar o vidro dos cards que ficam abaixo da aurora (onde ele quase não aparece).
