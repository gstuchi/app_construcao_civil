# Inventário do site para a etapa 4 do app nativo

Data: 2026-10-29. Este levantamento descreve o que o PWA faz hoje nos blocos da etapa 4 ("Análise"): as portas da obra, a tela Gráficos, o Relatório, o simulador "Vale a pena?" e o imprimir. Ele foi tirado da main `cec9fc0`, no worktree `etapa4-spec`. Caminhos e números de linha são dessa revisão e relativos à raiz do repositório.

O escopo vem do spec do app nativo, seção "Análise" (docs/specs/2026-10-06-app-nativo-design.md:142-145) e tabela de etapas (docs/specs/2026-10-06-app-nativo-design.md:183), e do spec da etapa 3, que deixou para cá a outra entrada do detalhe do tópico, pela legenda e pelo donut (docs/specs/2026-10-18-app-nativo-etapa3-design.md:288).

Este é um levantamento feito por leitura, e as lacunas estão em "Cobertura". Antes de portar um trecho, confira no código: o código manda, e este documento só aponta onde olhar.

**Conferência com o inventário geral.** As linhas de análise do inventário de 06/10 (docs/plans/2026-10-06-app-nativo-inventario.md, tirado da `4d9a042`) foram conferidas uma a uma na `cec9fc0`: na seção 1, os itens 4 a 8 da obra e os blocos "Gráficos", "Relatório" e "Simulador"; na seção 4, "TIR e simulador" e "Séries para gráficos". Os textos citados continuam certos. Os números de linha mudaram, a ordem de uma tabela estava trocada e duas frases eram imprecisas. As correções estão na última seção.

**Cobertura.**
- **Lidos inteiros, nos trechos da etapa:** `app.js` (1988 linhas):
  - estado, helpers e `fitNums` (app.js:1-101);
  - restauração, navegação, título e `openObra` (app.js:102-212);
  - indicadores e ações da obra e o bloco dos gráficos (app.js:321-427, 468-475);
  - donut da obra, evolução e gasto por mês (app.js:522-705);
  - voltar, donut com legenda, `byTopico`, imprimir e Gráficos (app.js:1028-1108);
  - `sheetTopico` (app.js:1128-1158), Relatório (app.js:1160-1247) e simulador (app.js:1250-1320).
- **`calc.js`:** correção, totais, lucro, TIR e séries (calc.js:62-205), `precoPorM2` (calc.js:232-234), `addMesesClampado` (calc.js:328-336), formatação (calc.js:474-487) e as exportações (calc.js:538). **`share.js`** inteiro (50 linhas).
- **Por trecho ou por grep:** `index.html` das três telas (index.html:212-240); `styles.css` do donut, do relatório, da impressão e dos gráficos (styles.css:177-182, 583-610, 780-799, 1098); `scripts/vetores-calc.mjs` (os grupos); `tests/browser/` (`fase3`, `ios`, `mobile`, `nativo`, `vidro` e `xss`, no que toca a etapa); o núcleo e as telas em `app-ios/`, só para marcar o que já existe.
- **Não li:** `cloud.js`, `auth.js`, `teclado.js`, `push.js`, o resto do CSS e os mockups (fora do repositório). Nada foi rodado: os números deste documento saem do código, não de execução.

### 1. Na obra: as portas e os gráficos de hoje

- "Ver gráficos" e "Relatório" ficam nas ações da obra e só aparecem com gastos (app.js:398-400). Cada um abre a sua tela (app.js:471-472).
- O painel "Gastos por tópico" tem um donut de 132 px, com "Total" e o `moneyShort` do total no meio, e uma legenda com os **7 primeiros** tópicos: ícone, nome e "{pct}% · {moneyShort}" (app.js:416-425, 522-547). Sem gasto, a legenda diz "Sem gastos ainda" (app.js:525). Tocar no donut abre os Gráficos, só com gastos (app.js:473).
- **Soma por tópico:** o bruto de todos os gastos, com as parcelas a vencer, do maior para o menor; no empate, o tópico que aparece primeiro nos gastos, porque o objeto nasce na ordem dos gastos e o `sort` é estável (app.js:412-414). A mesma conta está repetida em `byTopico` (app.js:1060-1064).
- **Cores:** oito (`PIE`, app.js:8; os valores `--c1` a `--c8` em styles.css:20 e styles.css:59), repetidas a partir do 9º tópico (`i % 8`, app.js:531 e 541).
- **Porcentagem:** `Math.round(val / total × 100)`. O tópico muito pequeno mostra 0% (app.js:545 e 1052).
- A evolução e o gasto por mês moram dentro da obra, com 170 px de altura (app.js:426-427).
- O mês escolhido nos dois gráficos (`evoSel`, `mesSel`) é um só para a obra e para os Gráficos e zera ao abrir uma obra (app.js:202, 552, 639).

### 2. Tela Gráficos (`renderGraficos`, app.js:1089-1108)

- O título do painel é "Gráficos — {nome}", e logo abaixo vem "Gastos por tópico" (app.js:1097-1098). A barra mostra "Gráficos" e o voltar "‹ Obra" (app.js:166-176), que reabre a obra (app.js:1029).
- Donut de 240 px e legenda com **todos** os tópicos: ícone, nome e "{pct}% · {moneyShort}" (app.js:1033-1059). Sem gasto, "Sem gastos ainda." (app.js:1034), que a porta não alcança, porque some sem gastos.
- Tocar numa fatia ou numa linha da legenda abre a folha do tópico (app.js:1070-1075, 1106). Editar ou apagar de dentro dela repinta os Gráficos antes de remontar a folha (app.js:1150-1153), e a folha fecha quando sai o último gasto do tópico (app.js:1132).
- A evolução e o gasto por mês vêm com 300 px de altura (app.js:1101-1102), seguidos do botão "Imprimir / salvar PDF" (app.js:1103; seção 5).

**Evolução (`evoChartHtml`, app.js:570-622; `bindEvoChart`, app.js:623-635).**
- A série é `serieEvolucao(o, taxa, hoje)` (calc.js:143-168): um ponto por mês, do 1º gasto até hoje ou a venda; cada mês soma os gastos até o corte (o último dia do mês, ou o fim); os últimos 24.
- Sem série, o painel diz "Sem gastos ainda." (app.js:574).
- Com um mês só, a linha atravessa o gráfico reta (app.js:576-577).
- Escala: o maior corrigido × 1,08; grade a 25, 50, 75 e 100% com rótulos em `moneyShort` (app.js:578, 584-588). Por isso os rótulos não são redondos ("R$ 233 mil").
- Rótulos de mês "jan…dez": no máximo uns 8, e sempre o último (app.js:589-593).
- Linha do corrigido (`--chart-rec`) com área em degradê e linha do gasto (`--chart-gasto`) (app.js:612-614); legenda "Gasto" e "Corrigido pelo banco" (app.js:617-619).
- **Toque:** uma coluna transparente por mês; tocar escolhe o mês e repinta (app.js:594-598, 633). O padrão é o último mês (app.js:599, 634). A leitura fica acima: "{mmm/aa} · gasto {moneyShort} · corrigido {moneyShort}" (app.js:630-631). Não há arrasto.

**Gasto por mês (`mesChartHtml`, app.js:640-687; `bindMesChart`, app.js:688-705).**
- A série é `serieMensal(gastos)` (calc.js:173-188): o bruto de cada mês, em meses seguidos do 1º ao último gasto, **com os meses futuros das parcelas** e zeros no meio; os últimos 24.
- Sem série, não desenha nada (app.js:643).
- Escala como a da evolução (o maior × 1,08). A barra tem até 26 px e 62% da coluna, topo arredondado de 3 px e base reta; o mês zerado vira um toco de 1,5 px (app.js:645-649, 660-671).
- **Toque:** escolhe o mês sem repintar a tela (app.js:698-702). O padrão é o **último mês com gasto** (app.js:655-656, 703-704), que pode ser um mês futuro de parcela. A leitura é "{mmm/aa} · {money}" (app.js:695).
- As barras fora da seleção ficam a 50% (75% no claro) e a escolhida ganha brilho (styles.css:793-797); com "reduzir movimento", sem transição (styles.css:799).
- Não há média, maior nem quantidade de meses, e as parcelas a vencer não se distinguem dos meses pagos.

### 3. Relatório (`renderRelatorio`, app.js:1160-1247)

- O título do painel é "Relatório — {nome}" (app.js:1210).
- **Cabeçalho** (app.js:1211-1215): "{fase} · começou em {dd/mm/aa} · {fmtMeses}"; "Correção de {taxa, com vírgula}% ao mês, da data de cada gasto até a venda ({dd/mm/aa})." ou "… até hoje ({dd/mm/aa})."; "Marque gastos para somar somente itens escolhidos.".
- **Fim da correção:** a data da venda, ou hoje (app.js:1164), uma cópia à mão do `fimCorrecao` (calc.js:70-72).
- **Grupos** (app.js:1168-1175): um por tópico; os gastos do mais antigo ao mais novo (`localeCompare` da data; na mesma data, a ordem do array); o bruto e o corrigido do grupo; os grupos do maior bruto ao menor (no empate, a ordem em que o tópico aparece nos gastos).
- **Tabela** "Tópico / gasto · Data · Bruto · Corrigido · Correção pelo banco" (app.js:1224). A linha do tópico traz ícone, nome e os três valores. A de cada gasto traz a caixinha, a descrição (ou o nome do tópico, app.js:1190), a data, o bruto, o corrigido e "+{correção}" (app.js:1183-1194). O gasto futuro tem correção de +R$ 0,00, porque os dias nunca ficam negativos (calc.js:62-66).
- **TOTAL:** `totalBruto`, `totalCorrigido` até a venda ou hoje e "+{correção}" (app.js:1177-1178, 1227).
- **Fim** (app.js:1196-1206):
  - obra com venda: "Venda em {dd/mm/aa}", "Lucro bruto (venda − gasto)" e "Acima do banco (venda − corrigido)", em verde ou vermelho pelo sinal;
  - senão, com venda estimada: "Venda estimada" e "Margem estimada (estimado − corrigido)", o estimado menos o corrigido até hoje;
  - sem as duas, nada.
- **Seleção** (app.js:1234-1245): cada caixinha atualiza o painel "Selecionados", escondido com nenhum marcado e com `aria-live="polite"` (app.js:1216-1221). Ele mostra "{N} item" ou "itens", "Bruto", "Corrigido" e "Parte do total", o bruto ÷ o total bruto × 100 com 2 casas no padrão pt-BR, ou "0%" com total zero. A seleção vive no DOM e some ao sair da tela.
- No celular, a tabela rola de lado (`.rep-scroll`, styles.css:583). Na impressão, as caixinhas e o botão somem (styles.css:599-610).
- **O Relatório não repinta sozinho:** o `renderAll` não o chama (app.js:205-210), e uma mudança de outro aparelho só aparece ao reabrir a tela.

### 4. "Vale a pena?" (`renderSimula`, app.js:1250-1259; `simulaCompute`, app.js:1261-1316; index.html:226-240)

- O título é "Será que vale a pena?" (index.html:228).
- **Obra:** só as não vendidas com gastos, na ordem do documento. Sem nenhuma, o campo diz "— crie uma obra com gastos —" e não há resultado (app.js:1252-1256, 1264). A escolhida continua escolhida a cada repintura, enquanto for elegível (app.js:1257).
- **"Se eu vender por":** campo de dinheiro com máscara (app.js:1318). Ele é preenchido com a venda estimada só quando está vazio e ninguém mexeu nele (app.js:1267).
- **"Daqui a (meses)":** campo numérico com mínimo 0 e máximo 120 no HTML (index.html:234); a conta só tira o negativo (app.js:1269).
- A nota diz: "A conta considera que não haverá mais gastos até a venda. Mude o preço e os meses pra comparar cenários: vender mais barato agora × esperar mais." (index.html:236-237).
- **Conta** (app.js:1271-1285):
  - alvo = hoje + meses, com `addMesesClampado`;
  - custo bruto = todos os gastos; corrigido até o alvo;
  - a obra com menos de 1 mês até o alvo (`mesesDeObra < 1`) fica sem taxa;
  - TIR = `tirMensal`; acima do banco = `rendimentoAcima`;
  - veredito: venda > corrigido;
  - multiplicador = TIR ÷ taxa.
- **Venda ≤ 0:** "Digite o preço de venda pra ver a conta." (app.js:1275-1277).
- **Cartão** (app.js:1296-1300): "Vale a pena" (com o ✓) ou "Rende menos que o banco" (com o alerta); "{x,xx}% ao mês" ou "—"; e a linha "vendendo hoje" ou "vendendo daqui a {N} mês/meses" · "banco paga {taxa}%" · "rende {N,N}× o banco" (só com taxa e multiplicador ≥ 1) · "obra com menos de 1 mês — % ao mês ainda não diz muito".
- **Tabela "Relatório da simulação"**, colunas "Pelo bruto" e "Pelo corrigido" (app.js:1301-1314), nesta ordem: "Custo até a venda"; "Venda"; "Lucro"; "% sobre o custo"; "% sobre a venda" (1 casa); "Rendimento ao mês" (a TIR e o acima do banco, "x,xx% a.m."); "Preço por m² ({área} m²)", só com área. Valor nulo vira "—" (app.js:1290-1293). O lucro e as duas porcentagens ficam verdes ou vermelhos pelo sinal (app.js:1308-1310); custo, venda, rendimento e R$/m² não têm cor.

### 5. Imprimir, PDF e compartilhar

- **Web:** "Imprimir / salvar PDF" chama `window.print()` (app.js:1079). O CSS de impressão mostra só a tela ativa, em preto sobre branco, sem caixinhas, botões e aurora (styles.css:599-610, 1098).
- **App iOS de hoje (Capacitor):** o botão vira "Compartilhar planilha" e exporta o CSV da obra (`dadosDaObra`) pela folha do sistema; no erro, "Não foi possível compartilhar. Tente novamente." (app.js:1077-1086; share.js:20-23, 27-46). O nome do arquivo é `custta-AAAA-MM-DD.csv` (share.js:30).
- O site não tem PDF próprio: o "PDF" é a impressão da tela. O PDF do app nativo é novo.

### 6. O que o núcleo do app já tem

| Regra | `calc.js` | `CusttaNucleo` | Vetores |
| --- | --- | --- | --- |
| `corrigido`, `fimCorrecao`, `totalBruto`, `totalCorrigido` | calc.js:67-79 | Correcao.swift:11-27 | sim (o `fimCorrecao` pelos totais) |
| `resumoTopico` | calc.js:82-89 | Correcao.swift:43 | sim |
| `lucroVenda`, `mesesDeObra`, `precoPorM2` | calc.js:90-99, 232-234 | Correcao.swift:58, 65, 70 | sim |
| `tirMensal`, `rendimentoAcima`, `resumoVenda` | calc.js:108-138 | Tir.swift:6, 21, 33 | sim |
| `serieEvolucao`, `serieMensal`, `serieEvolucaoAgregada` | calc.js:143-205 | Series.swift:32, 61, 83 | sim |
| `addMesesClampado` | calc.js:328-336 | Datas.swift:91 | sim |
| `semAcento`, `filtraGastos` | calc.js:238, 241 | Listas.swift:49, 95 | sim |
| `money`, `moneyShort`, `moneyCurto`, `fmtMeses`, `numParaCampo` | calc.js:474-487, 387 | Moeda.swift:70, 101, 116, 130, 39 | sim |
| Gasto por tópico (a ordem do donut) | — (app.js:412-414, 1060-1064) | DentroDaObra.swift:62 (`gastoPorTopico`, da etapa 3) | não |

Os caminhos do núcleo são relativos a `app-ios/CusttaNucleo/Sources/CusttaNucleo/`.

### Regras que só vivem no app.js

1. **Gasto por tópico:** a soma bruta por tópico e a ordem, do maior para o menor, com o empate pela ordem dos gastos (app.js:412-414, 1060-1064). O núcleo já tem a cópia (`gastoPorTopico`), sem vetor do site.
2. **Grupos do relatório:** fim da correção, gastos por data, grupos por bruto, o bruto e o corrigido de cada grupo e de cada gasto, e os totais (app.js:1164-1178, 1188).
3. **Fim do relatório:** venda, lucro bruto e acima do banco; ou venda estimada e margem; ou nada (app.js:1196-1206).
4. **Linha da correção** do cabeçalho, até a venda ou até hoje (app.js:1213).
5. **Soma da seleção:** quantidade com "item"/"itens", bruto, corrigido e parte do total com 2 casas (app.js:1235-1243).
6. **Simulador:** as obras elegíveis, o preço inicial pela venda estimada, os meses sem negativo, a conta (alvo, menos de 1 mês, TIR, acima do banco, veredito, multiplicador) e os textos do cartão e da tabela (app.js:1252-1257, 1267-1312).
7. **Mês escolhido por padrão** nos gráficos: o último na evolução e o último com gasto no gasto por mês (app.js:599, 655-656).
8. **Escala e rótulos dos eixos:** o maior × 1,08, a grade em quartos e uns 8 rótulos de mês (app.js:578-593, 645-657).

### Achados

1. **O Total gasto inclui as parcelas a vencer, e a evolução para em hoje.** Na Casa Alphaville do mockup, R$ 842 mil no total e R$ 777 mil no último ponto da evolução (achado do Croqui). Nada no site explica a diferença.
2. **O gasto por mês abre no último mês com gasto**, que pode ser um mês futuro de parcela: abril de 2027 na mesma obra (achado do Croqui).
3. **Relatório e Gráficos não acompanham mudança de outro aparelho:** o `renderAll` não os repinta (app.js:205-210). Só editar de dentro da folha do tópico repinta os Gráficos (app.js:1151).
4. **Trocar de obra no simulador não troca o preço:** o campo só é preenchido quando está vazio (app.js:1267), e a segunda obra fica com a venda estimada da primeira.
5. **O teto de 120 meses só existe no `<input>`** (index.html:234): digitado à mão, um prazo maior entra na conta (app.js:1269).
6. **A legenda do donut da obra mostra só 7 tópicos**, sem dizer que há mais (app.js:539).
7. **Tópico muito pequeno aparece com 0%** (app.js:545, 1052).
8. **O mês escolhido é um só para a obra e os Gráficos** (app.js:552, 639): escolher um mês na obra muda o que os Gráficos abrem.

### Conferência do inventário geral (docs/plans/2026-10-06-app-nativo-inventario.md)

As linhas abaixo citam a `4d9a042`; na `cec9fc0`:
- `PILHA_OBRAS` (app.js:184) está em app.js:129, e a direção da troca (app.js:186-189) em app.js:130-134.
- O título que encolhe (IntersectionObserver, app.js:238-251) está em app.js:183-196.
- O "‹ Obras"/"‹ Obra" (app.js:226-230) está em app.js:167-176; voltar do relatório e dos gráficos (app.js:1117-1118), em app.js:1028-1029.
- "Evolução da obra … Vazio: 'Sem gastos ainda.' (app.js:621)": app.js:574. Barras de gasto por mês (app.js:691): app.js:640.
- Gráficos (app.js:1176): app.js:1089. Relatório (app.js:1251-1340): app.js:1160-1247. Simulador (app.js:1341-1413): app.js:1250-1320.
- "O CSV da obra usa `dadosDaObra` (app.js:1170)": app.js:1083, e só no app iOS de hoje, no lugar do imprimir.
- Ordem das linhas da tabela do simulador: é "Custo até a venda", "Venda", "Lucro", "% sobre o custo", "% sobre a venda", "Rendimento ao mês" e "Preço por m²". O inventário punha "Venda" antes do custo.
- "'Daqui a (meses)': de 0 a 120": o limite está só no HTML; a conta aceita mais (achado 5).
- "Card de resultado … rende N,N× o banco": só aparece com taxa e multiplicador ≥ 1, e a linha ganha "obra com menos de 1 mês — % ao mês ainda não diz muito" quando a obra é nova demais.
- As funções de `calc.js` são exportadas em calc.js:538, não em calc.js:382.
