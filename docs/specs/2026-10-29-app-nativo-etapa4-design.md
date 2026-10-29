# Custta nativo, etapa 4: análise

Data: 2026-10-29. Spec da etapa 4 do app nativo (`docs/specs/2026-10-06-app-nativo-design.md`, seção "Etapas"): Gráficos, Relatório, "Vale a pena?" e PDF, e a tela da obra na identidade nova que o mockup desta etapa trouxe. Ele junta o que o Giovani aprovou no mockup do Croqui (duas partes, fechado em 28/10) e as decisões de planejamento que já têm recomendação. As decisões grandes passaram pelo conselho em 29/10 (seção "Decisões do conselho"); o plano de implementação, com protótipo, tarefas e código, é escrito a partir daqui.

## Contexto

A etapa 3 terminou no código com o PR 3 (#88, `bb3ef21`), depois do PR 0 do site (#79), do orçamento (#83), da aparência em Ajustes (#84) e do A pagar com o detalhe do tópico (#85); o plano dela entrou no #82. A main está em `cec9fc0`.

A etapa 4 só lê o estado. Gráficos, Relatório, "Vale a pena?" e PDF fazem contas sobre o que já existe: nenhuma mutação nova, nenhuma chave nova no blob, e as `firestore.rules` não mudam. As gravações que se alcançam pelas telas novas são as das etapas 2 e 3: o "Ver gastos" do anel e as linhas da lista abrem a folha do detalhe do tópico, que edita e apaga gasto, e o + da cápsula abre a folha de gasto novo (confirmação 6 de 29/10, em "Decisões de desenho"). O PDF é gerado no aparelho e só sai pela folha de compartilhar do sistema.

A etapa também traz a identidade nova do Custta, decidida com o Giovani em 28/10: blocos de vidro sobre a aurora, números em SF Mono, o verde de destaque e um bloco sólido por tela. Ela entra na obra e nas telas novas. Os valores dos tokens globais foram aprovados por ele no mockup, e em 29/10 ele aprovou levar esses tokens e a cápsula de abas ao app inteiro. O resto do app (lista de obras, folhas, Ajustes, entrar e as telas empurradas da obra que o mockup não desenha, Orçamento e Afazeres) continua com a cara da etapa 3 até uma decisão dele.

## Mockup aprovado

Fora do repositório, em `~/Documents/custta-mockups/nativo/etapa4/` (abrir no Chrome; usa a pasta `../etapa3/globo/` e, na parte 2, o logo de `../../logo/kit/`). O resumo e as decisões estão no `LEIA-ME.md` da pasta; o pedido ao Croqui, com as 8 decisões do Giovani de 28/10 que não se reabrem, está no `BRIEF.md`. O mockup foi fechado em 28/10/2026, com a busca no Relatório.

| Parte | Arquivo | O que desenha | Aprovação |
| --- | --- | --- | --- |
| 1 | `parte1.html` | a obra na identidade nova (com e sem orçamento, sem gastos, pronta e vendida) e os Gráficos (anel, evolução, gasto por mês, toque e estados) | 28/10: as 7 recomendações, o texto mais escuro do claro e os 3 ajustes (título em SF Mono 600, cápsula da obra e grade de bordas 16/34); depois, pedida por ele, a barra empilhada no lugar do mini-anel da obra |
| 2 | `parte2.html` | o Relatório (com Selecionar e busca), o "Vale a pena?", o PDF e a folha de compartilhar | 28/10: as 7 recomendações, as 3 da busca e o globo a 70% no escuro |

- Os 103 prints (46 da parte 1 e 57 da parte 2) são a referência da conferência visual. Os números vêm do `calc.js` da `cec9fc0` sobre a Casa Alphaville da etapa 3 (46 gastos, hoje 12/10/26, 1% ao mês). `gera-dados-p1.cjs` e `gera-dados-p2.cjs` refazem os dados; `medir-p1.cjs` e `medir-p2.cjs`, o contraste.
- Medidas, tokens e o que é obrigatório ou sugestão estão em "Medidas e especificação" e "O que vem do site" do `parte1.html` e em "O que vem do site" do `parte2.html`. Este spec não repete medida: aponta para lá.
- **O mockup guarda seis restos de versões anteriores**, e o spec segue a versão aprovada:
  - o topo da parte 2 no `LEIA-ME.md` ainda diz "aguardando o ok dele", e o topo do `parte1.html`, que a parte 2 "ainda não começou";
  - a decisão 4 da parte 2 (o âmbar do claro) ainda diz "preciso do ok", o `SolidoAmbar` do claro está como "proposta" e a nota do quadro `sim-abaixo-claro` diz que ele só decidiu o do escuro; o título da seção diz que as 7 primeiras foram aprovadas em 28/10. Ele confirmou o âmbar do claro em 29/10;
  - o título pequeno da barra na letra máxima aparece com 20 pt (ajuste 1 e a linha do título nas medidas) e com 22 pt (a linha "Letra máxima" das medidas): vale 20, o da opção C, que ele escolheu;
  - a nota do quadro `graf-evo-claro` diz "Eixos e rótulos em #3B574B", o valor de antes do texto mais escuro do claro;
  - a opção C do `ajustes-titulo.html`, onde ele escolheu o título, diz que a barra fica em 15 pt; as medidas e o CSS do `parte1.html` dizem 16: vale 16;
  - o "Decidido pelo Croqui" do LEIA-ME e do `parte1.html` ainda diz que o botão de PDF dos Gráficos fica para a parte 2; as "Mudanças de 29/10 na parte 1" o puseram no fim dos Gráficos.

O inventário do site para esta etapa, com arquivo e linha conferidos na `cec9fc0`, está em `docs/plans/2026-10-29-app-nativo-etapa4-inventario.md`. Os "achados" citados aqui são os dele.

## Decisões de desenho (aprovadas no mockup)

Aqui entra o que o mockup atribui ao Giovani: as duas partes que ele aprovou (o "O que entrou" de cada uma), as 8 decisões do `BRIEF.md` ("brief 1" a "brief 8"), as decisões de cada parte no `LEIA-ME.md`, os 3 ajustes de 28/10 e as mudanças que ele pediu depois; no fim, as sete confirmações de 29/10. O que o LEIA-ME e os HTML põem em "Decidido pelo Croqui" está em "Decisões tomadas por recomendação".

**Identidade (brief 1 a 4 e 8; ajustes 1 e 3).**
- Vidro sobre a aurora, na dose do app: o Transparente; o Fosco, quando escolhido em Ajustes ou com Aumentar contraste; sólido, com Reduzir transparência. Nunca vidro dentro de vidro.
- Um assunto por bloco, com cantos de ~26 pt e o número principal grande com legenda pequena.
- **Um bloco sólido protagonista por tela**, verde com texto escuro, que não é vidro. Na obra, o Total gasto (ou o lucro, na vendida); no Relatório, o total da obra (ou o resumo dos achados, na busca); no "Vale a pena?", o veredito.
- **Números em SF Mono**, com o R$ e os centavos menores **na linha do número**, nunca sobrescritos e nunca abaixo de 11 pt (brief 2). O mono foi escolha dele contra a recomendação e não se rediscute. No mockup, os números levam tracking de −0,035 em (`parte1.css:77`).
- **Título em SF Mono 600** (ajuste 1, opção C): 30 pt com tracking −0,045 em, e o título pequeno da barra em 16 pt; na letra máxima, 44 e 20 pt. O app fica com duas famílias: SF Pro no texto, SF Mono nos números e títulos.
- **Grade de bordas** (ajuste 3): borda externa de 16 pt para toda forma (bloco, cápsula, botão, cápsula de abas, voltar) e para o título solto; interna de 34 pt para todo texto, chip, ponto ou ícone dentro de uma forma, inclusive a calha do eixo Y; o mesmo à direita; a letra máxima não muda as bordas. A exceção é o texto centralizado (botões, leitura do anel, estado vazio). Hoje a obra do app usa 20 pt dos lados (ObraView.swift:126), e a cápsula de abas também (CapsulaDeAbas.swift:55).
- **Verde de destaque `#3AD17E`** (brief 3; no claro, a linha em `#177A4A`): linha do gasto, mês aceso, "Ver gastos" e o bloco sólido.
- Fora o clima de cripto e de terminal (brief 8): nada piscando, nada de setas de bolsa, nada de muitos números pequenos juntos; a letra continua generosa.

**O número que encolhe (brief 2).** O spec resolve o encolher:
- O valor fica numa linha e encolhe só o necessário para caber, sem corte e sem reticências, até o R$ e os centavos chegarem a 11 pt. Na linha de lista na letra padrão (17 pt), 0,58 do corpo já fica abaixo de 11: o R$ e os centavos ficam em 11 pt, e o valor quase não tem para onde encolher. Quando não cabe ao lado do nome, ele desce para baixo do nome, como o mockup desenha na letra máxima, e lá encolhe se precisar.
- Uma peça só para todo valor da identidade nova. A `ValorEmDinheiro` de hoje já é um texto só, com o R$ dentro para encolher junto (Componentes.swift:284-302). Ela ganha a forma mono, com os centavos no mesmo texto e o piso do encolher calculado pelos 11 pt, no lugar do 0,5 fixo de hoje.
- No sólido, o piso não chega a ser alcançado. Com o avanço de ~0,6 em do SF Mono, um total de R$ 1.000.000.000,00 cabe nos 307 pt do sólido na letra máxima em 375 pt com o corpo perto de 30 pt e o R$ perto de 17 pt; o tracking dos números do mockup dá ainda mais folga. O plano prova com teste de largura no maior valor, na letra máxima em 375 pt, e o laudo confere que nada corta.
- O VoiceOver lê o valor inteiro ("R$ 842.317,45"), num elemento só.

**Tela da obra (parte 1, decisões 3 e 4; ajuste 2; a barra empilhada).**
- De cima para baixo: o título; a cápsula com o chip da fase em cima e "começou em … · N meses" embaixo, os dois na borda de 34 pt (ajuste 2); o Total gasto no sólido; um bloco de vidro por assunto, na ordem da etapa 3 (Orçamento, Corrigido pelo banco, A pagar · 30 dias, Venda estimada); as ações da fase; as portas "Ver gráficos" e "Relatório", só com gastos, como no site; os Afazeres; o bloco "Gastos por tópico"; e os Lançamentos com lupa, mês, "A vencer" fechado e os meses. Nada da etapa 3 some.
- **Barra empilhada** (pedida por ele, no lugar do mini-anel): um pedaço por tópico, com largura proporcional, cantos redondos, vão de 3 pt e largura mínima de 8 pt; os 6 maiores nas cores do anel e "Outros" em cinza, sobre a placa. A legenda fica numa coluna, com os 4 maiores (3 na letra máxima), o nome inteiro (quebra em vez de cortar) e "e mais N tópicos". O bloco inteiro abre os Gráficos; o anel animado fica só lá.
- **Evolução e gasto por mês saem da obra** (decisão 3) e moram só nos Gráficos.
- **Estados:** sem orçamento, o bloco some e "Definir orçamento" entra nas ações; sem gastos, o sólido mostra R$ 0,00 com o convite para lançar o primeiro gasto; somem as portas (como no site) e a barra de tópicos, e a lupa e o mês somem como na obra do app desde a etapa 3 (ObraView.swift:97). O site mostra o donut vazio, a busca e o mês (app.js:416-441). Pronta e vendida, com as ações do site.
- **Obra vendida (decisão 4: A):** o sólido mostra o lucro bruto e o acima do banco, e o Total gasto passa a um bloco de vidro logo abaixo. Com prejuízo, vale a B: o sólido volta a ser o Total gasto, e o lucro vai para o bloco da venda, em âmbar, nunca vermelho.

**Gráficos (brief 4 e 5; parte 1, decisões 1, 2 e 5 a 7).**
- Tela empurrada pela porta ou pela barra, com o título "Gráficos" e o nome da obra numa cápsula. Na ordem do site: tópicos, evolução e gasto por mês; no fim, "Exportar PDF".
- **Anel por tópico** (brief 5; decisões 1 e 2): os 6 maiores nas seis cores novas e "Outros" em cinza (a lista mostra todos). Pontas redondas que montam uma na outra, com aro de 2,5 pt na ponta, trilho apagado e o total no meio. Cada linha da lista tem seta e abre direto o detalhe do tópico, a folha da etapa 3.
- **Entrada** (brief 5): cada pedaço sai do topo, dá a volta e assenta no lugar, em 1,2 s, `cubic-bezier(0, 0, .58, 1)`, com 0,1 s entre pedaços e opacidade só no 1º quarto. Com Reduzir movimento, aparece pronto.
- **Toque C** (brief 5): o pedaço escolhido engrossa e os outros apagam **pela cor** (sem `filter`); o meio mostra nome, valor, % e "Ver gastos ›"; o 2º toque no mesmo pedaço solta. "Outros" mostra quantos tópicos junta, sem "Ver gastos": o caminho são as linhas cinzas da lista.
- **Evolução** (brief 4; decisão 7): linha do gasto com degradê e o tracejado "no banco já seria". O valor lido fica acima do gráfico. A linha para em hoje (ou na venda), como o site, e o que ficou de fora vira uma frase em âmbar.
- **Gasto por mês** (brief 4; decisões 5 e 7): barras com o mês escolhido aceso em verde e os outros apagados; as parcelas a vencer tracejadas e hachuradas; embaixo, média, maior e meses (confirmação 2).
- **Toque nos gráficos de mês** (decisão 5): tocar ou arrastar o dedo, com o gráfico inteiro como alvo; o mês mais perto do dedo é o escolhido; a seleção fica ao soltar; o valor lido fica acima. **O padrão é este mês**, não o último com gasto, que o site usa e que na Casa Alphaville cairia em abril de 2027, um mês a vencer.
- **Sem os chips "6 meses / 1 ano / Tudo"** (decisão 6). Passando de 24 meses, aparece "Mostrando os últimos 24 meses.".
- **Parcelas a vencer** (decisão 7): o Total gasto (R$ 842 mil) inclui R$ 65,5 mil a vencer, e a evolução para em hoje (R$ 777 mil). O gasto por mês mostra as parcelas tracejadas, e a evolução avisa em âmbar quanto ficou de fora.
- **Estados** (desenhados no mockup): 1 gasto; 1 mês só, com a linha reta e um ponto, como o site; 1 tópico só, com o anel cheio, sem emenda; tópico pequeno demais; e sem gastos, com o trilho vazio e a frase do site. Esse último só se alcança apagando o último gasto pela folha do tópico, porque a porta some sem gastos.

**Relatório (brief 6; parte 2, decisões 2, 3 e 8 a 10).**
- Empurrado pela porta da obra. O total no sólido (bruto, corrigido, correção); um bloco por tópico, que abre e fecha com os gastos (bruto e corrigido de cada um); no fim, a venda e a margem. Nada de tabela rolando de lado. A cápsula repete as linhas do site (fase, "começou em…" e a regra da correção); tópicos do maior para o menor bruto e gastos do mais antigo ao mais novo, como no site; as parcelas levam "(n/de)". Cada bloco diz quantos gastos tem e a parte da obra com 1 casa ("2 gastos · 38,0%"), que o site não mostra.
- **Obra vendida:** a correção vai até a venda; no fim, "Venda em …", "Lucro bruto (venda − gasto)" e "Acima do banco (venda − corrigido)", com prejuízo em âmbar, nunca vermelho. Sem venda estimada, o bloco do fim não existe.
- **Selecionar** (brief 6; decisão 3), como selecionar fotos, com a **barra de soma** embaixo: quantos itens, bruto, corrigido e % do total (2 casas, como o site). Cada gasto e cada tópico ganham um marcador de 44 pt; o do tópico tem 3 estados (nenhum, parte e todos) e marca todos os gastos dele. Estados desenhados: nenhum marcado, um e vários; a seleção atravessa os tópicos, e o tópico fechado diz quantos marcou. O "OK", a barra no lugar da cápsula de abas e o texto da barra vazia são do Croqui (seção "Decisões tomadas por recomendação").
- **O PDF é sempre o relatório inteiro** (decisão 2). O Selecionar serve para somar; um "Exportar seleção" na barra de soma fica para depois, se ele quiser.
- **Busca** (decisões 8 a 10):
  - a lupa mora na barra, ao lado do "Selecionar", com o botão redondo da etapa 3, que vira X; o toque abre o campo "Buscar gasto ou tópico" abaixo do título, com o teclado; fechado o teclado, o campo vira o chip "“ceramica” ×";
  - é a busca da etapa 3, sem acento e sem diferença de maiúscula, na descrição ou no nome do tópico; só ficam os gastos que batem, os tópicos com achados abrem sozinhos, e os sem achados somem;
  - o **resumo dos achados** (N de M gastos, bruto, corrigido e parte do total, com 2 casas) toma o lugar do sólido, e a meta da obra some, para os resultados ficarem acima do teclado;
  - o Selecionar vale sobre o resultado: marcadores só nos achados, soma só dos marcados à vista, o aviso dos marcados que a busca escondeu ("e mais 1 marcado fora da busca") e o atalho "Marcar os N achados" no resumo.

**"Vale a pena?" (parte 2, decisões 4 a 7).**
- Aba própria: a cápsula passa a ter Obras | Vale a pena? | Ajustes, e o + some nessa aba (confirmação 6).
- Os campos do site num bloco: **Obra**, **Se eu vender por** (no teclado de valor da etapa 3) e **Daqui a (meses)**, com − e +; a nota do site dentro do bloco.
- O veredito é o sólido: **verde** "Vale a pena" ou **âmbar** "Rende menos que o banco" (`#FFD98A` no escuro; `#F2C15A`, com texto `#2B1B00`, no claro: decisão 4, com o claro confirmado em 29/10), com a taxa ao mês, "vendendo daqui a N meses" e "banco paga 1% · rende N× o banco".
- A **faixa** com o custo, o ponto em que empata com o banco e a venda (a zona hachurada é "acima do banco"), com os 3 valores numa lista embaixo, cada um com o seu marcador (decisão 6).
- A tabela do site, **pelo bruto × pelo corrigido**, com R$/m² quando a obra tem área, em pares: o rótulo em cima e os dois valores embaixo; na letra máxima, um por linha (decisão 7). O lucro negativo vai em âmbar (nota do quadro `sim-abaixo-baixo`).
- Estados do site: sem obra elegível ("— crie uma obra com gastos —"), sem preço ("Digite o preço de venda pra ver a conta.") e obra com menos de 1 mês, com a taxa "—" e a frase do site (decisão 5: manter o site). **Achado do Croqui:** nesse caso o veredito sai pelo preço contra o custo corrigido e pode dar "Vale a pena" em verde sem taxa.

**PDF (brief 7; parte 2, decisões 1 e 2).**
- Um botão só, "Exportar PDF", no fim dos Gráficos e no fim do Relatório, sem tela de opções. Ele gera o PDF na hora e abre a folha de compartilhar do iOS (arquivo `Custta-Casa-Alphaville.pdf` no exemplo; AirDrop, Mensagens, Salvar em Arquivos, Imprimir), que é desenhada pelo sistema.
- Papel branco, verde escuro, logo `custta.` no topo e o número da página no rodapé ("página N de M"); números e título em SF Mono. O PDF é papel: não muda com o tema nem com a letra.
- **Página 1, o resumo:** os 3 números (o 1º é o "Total gasto", com "inclui R$ … a vencer" quando houver: confirmação 3), o anel com as 6 cores, a linha do gasto e do corrigido e o gasto por mês. Na obra vendida, o 3º número é a venda, com o lucro bruto e o acima do banco; sem venda estimada, "—", sem margem inventada.
- **Da página 2 em diante, todos os gastos por tópico** (bruto, corrigido e correção), com a venda e a margem no fim. O cabeçalho da tabela se repete em cada página; um tópico que não cabe quebra entre as linhas, e a página seguinte o retoma com "(continuação)".

**Tokens globais: os valores aprovados**, no app inteiro (confirmação 5).
- O texto mais escuro do claro (28/10): o âmbar de texto `#6F4705` → `#5E3A03` e o secundário `#3B574B` → `#2F4A3F` (o que isso muda no app está na tabela de tokens).
- O globo a 70% no escuro (28/10).
- O verde de destaque, as seis cores do anel e a cor própria dos números positivos (`DestaqueNumero`, nas "Mudanças de 29/10 na parte 1", pedidas por ele).

**Contraste medido no mockup.** O pior texto foi 4,56:1 na parte 1 (chip da fase, no claro) e 4,53:1 na parte 2 (valor da tabela do "Vale a pena?", no claro). No escuro, o pior foi 4,99:1 e 5,29:1. A pior marca de gráfico ficou em 3,04:1 (o verde-água, no claro), e o pior texto do PDF em 4,80:1 (número forte, branco no verde). No iPhone o vidro é o do sistema, e a medida que vale é a do laudo do app.

**Confirmadas por ele em 29/10.** Eram recomendação deste spec ou do Croqui, ou o mockup ainda as marcava como proposta; ele aprovou as sete juntas ("aprovo as 7").
1. **O âmbar do claro:** o sólido `#F2C15A`, com o texto `#2B1B00`.
2. **Média, maior e meses** embaixo do gasto por mês (vieram do quadro de exploração do Croqui; o site não tem), com a conta deste spec: do 1º gasto até este mês, com os meses zerados e sem as parcelas a vencer.
3. **Página 1 do PDF: "Total gasto"** no lugar de "Gasto até hoje", com "inclui R$ … a vencer" quando houver. O número tem as parcelas a vencer (parte 1, decisão 7), e "até hoje" o desmentia.
4. **Os dois alinhamentos do site no PR 0:** o preço acompanha a venda estimada da obra escolhida enquanto a pessoa não digitou, e os meses ficam entre 0 e 120 na conta (seção "PR 0 do site").
5. **Os tokens globais e a cápsula de abas (borda de 16 pt) no app inteiro:** um só para todas as telas. Trocar só nas telas novas pediria tokens duplicados e faria a cápsula pular de lugar ao trocar de aba (16 pt nas telas novas, 20 nas outras). O laudo inteiro prova que nada caiu (seção "Testes e validação", item 6).
6. **O + da cápsula:** some na aba "Vale a pena?", como em Ajustes e como o site, que o esconde nessa aba (app.js:153); nos Gráficos e no Relatório, lança gasto na obra, como nas telas Orçamento e Afazeres (o site o esconde nessas telas); no Selecionar, sai junto com a cápsula. O mockup desenhava o + nas três telas.
7. **A folha do detalhe do tópico fica como na etapa 3**, porque as folhas estão fora desta etapa. O texto a 34 pt do ajuste 3 entra quando as folhas entrarem; nesta etapa, na folha, só o "% da obra" muda, com o "<1%" (seção "Regras: iguais ao site").

### Tokens: do mockup para o app

Os valores são do mockup. A coluna "No app" é recomendação deste spec: onde o app já tem um token com o mesmo papel e valor igual ou mais forte, ele fica; o laudo do app decide no fim.

| Token do mockup | Escuro | Claro | No app |
| --- | --- | --- | --- |
| `Destaque` | #3AD17E | #177A4A | o `Destaque` de hoje, igual |
| `DestaqueSolido` (o bloco) | #3AD17E | #3AD17E | novo |
| `TintaSobreDestaque` | #04100C | #04100C | novo |
| `DestaqueTexto` (texto verde) | #3AD17E | #0E7A41 | novo; o `Positivo` de hoje tem o mesmo claro e #35D68A no escuro |
| `DestaqueNumero` (lucro e margem) | #8CF0B4 | #0A5530 | o `PositivoNoVidro` de hoje (#8CF0BC e #084A27): quase igual no escuro, mais escuro no claro |
| `Placa` | #04100C a 58% | #FFFFFF a 66% | novo |
| `PlacaForte` | #04100C a 84% | #FFFFFF a 92% | novo |
| `HaloTitulo` | #04100C a 38% (62% na letra máxima) | nenhum | o `HaloDoTitulo` de hoje (30% atrás do nome da obra no escuro e 10% no claro, Aurora.swift:192-195), recalibrado pelo laudo |
| `Grafico1` a `Grafico6` | #199E70, #3987E5, #D55181, #9085E9, #D95926, #14A3C7 | #10976A, #2A78D6, #D14F86, #6250D6, #DC5A1E, #0C86A4 | novos |
| `GraficoOutros` | #8FA89C | #5E7A6E | novo |
| `LinhaBanco` | #B8D4C7 | #2F4A3F | o `SecundarioTransparente` do app (#D6E8E0 e #2B463B), mais forte |
| `BarraApagada` | #EAFFF6 a 40% | #142B23 a 58% | novo |
| `GradeGrafico` / `EixoGrafico` | #EAFFF6 a 14% / 30% | #142B23 a 14% / 32% | novos |
| `AmbarTexto` | #FFD98A | #5E3A03 (era #6F4705) | o `AlertaNoVidro` de hoje, com o claro escurecido (valor aprovado; no app inteiro pela confirmação 5) |
| `SecundarioTransparente` do mockup | #B8D4C7 | #2F4A3F (era #3B574B) | o `SecundarioTransparente` do app já é #D6E8E0 e #2B463B, mais escuro no claro que o novo valor: nada muda |
| `SecundarioForte` (letra máxima) | #D6E8E0 | #2A453A | o `SecundarioTransparente` do app (#D6E8E0 e #2B463B, um passo mais claro que #2A453A no claro); token novo só se o laudo da letra máxima pedir |
| `AnelApagado` | #123128 | #DCEAE3 | novo |
| `AnelSeparador` | #04100C a 55% | #FFFFFF a 75% | novo |
| `SolidoAmbar` | #FFD98A | #F2C15A | novo |
| `TintaSobreAmbar` | #2B1B00 | #2B1B00 | novo |
| `PdfVerde`, `PdfTexto`, `PdfSecundario`, `PdfCaixa` | #177A4A, #13261E, #3B574B, #F2F7F4 | (papel, iguais nos dois temas) | constantes do PDF, fora dos temas |

- O anel do PDF usa as cores do claro (`Grafico1` a `Grafico6` e `GraficoOutros`).
- **`SecundarioFosco`:** no claro, o app usa #3B574B no Fosco (Vidro.swift:104), justamente o valor velho do mockup. O mockup só mediu o Transparente; recomendação: o Fosco fica como está, e o laudo do Fosco confere.
- Os chips usam os fundos sólidos da etapa 3 (`PositivoFundo`, `AlertaFundo`, `InformacaoFundo`).
- **Globo:** o mockup apagou o globo de 100% para 70% no escuro. Mas o app já põe o globo a 40% no escuro dentro do app (decisão dele de 09/10, Globo.swift:82), e não dá para saber, pela imagem do mockup, se ela já tinha esse 40%. Recomendação: o plano mede no simulador o brilho dos pontos contra o do mockup e fica com o mais apagado dos dois; o globo nunca fica mais claro que hoje.

## Regras: iguais ao site

O comportamento vem do site de hoje (`app.js`: as portas da obra, `renderGraficos`, `evoChartHtml`, `mesChartHtml`, `renderRelatorio`, `renderSimula` e `simulaCompute`; `calc.js`), lido na `cec9fc0`. O inventário tem o arquivo e a linha de cada uma. As contas já estão no núcleo com vetores: correção, totais, lucro, TIR, acima do banco, resumo da venda, as duas séries, meses de obra, R$/m², `addMesesClampado`, `filtraGastos` e `semAcento`. As regras que importam para o código:

- **Gasto por tópico** (anel, lista e barra empilhada): o bruto de todos os gastos, com as parcelas a vencer; do maior para o menor; no empate, a ordem em que o tópico aparece nos gastos. A % de cada tópico é `Math.round(bruto / total × 100)`, a mesma do detalhe do tópico; abaixo de 1%, o app mostra "<1%" (Croqui), e o detalhe passa a mostrar o mesmo (recomendação).
- **Evolução:** `serieEvolucao`, um ponto por mês, do 1º gasto até hoje ou a venda, com o corte no fim de cada mês e os últimos 24. Com um mês só, a linha é reta.
- **Gasto por mês:** `serieMensal`, o bruto de cada mês, do 1º ao último gasto, com os meses futuros das parcelas e os zeros no meio; os últimos 24.
- **Relatório:**
  - a correção vai até a venda ou até hoje;
  - gastos por data (na mesma data, a ordem do documento) e tópicos por bruto (no empate, a ordem em que aparecem);
  - o corrigido de cada gasto e de cada tópico, e o total bruto e corrigido; descrição vazia vira o nome do tópico;
  - no fim: na vendida, venda, lucro bruto e acima do banco; com venda estimada, a venda estimada e a margem (a estimada menos o corrigido até hoje); sem as duas, nada;
  - a soma da seleção: "N item" ou "N itens", bruto, corrigido e parte do total com 2 casas, ou "0%" com total zero.
- **"Vale a pena?":**
  - obras elegíveis: as não vendidas com gastos, na ordem do documento; a escolhida continua escolhida enquanto for elegível;
  - preço inicial: a venda estimada da obra; meses: nunca negativos;
  - a conta: alvo = hoje + meses (`addMesesClampado`); custo bruto de todos os gastos; corrigido até o alvo; obra com menos de 1 mês até o alvo fica sem taxa; TIR por `tirMensal`; acima do banco por `rendimentoAcima`; veredito por venda > corrigido; o multiplicador (TIR ÷ taxa), com 1 casa, só quando é 1 ou mais;
  - os textos do cartão e da tabela do site (inventário, seção 4).
- **Busca no Relatório:** `filtraGastos` e `semAcento`, com o texto aparado, como os lançamentos da etapa 3.
- **Formato do estado:** nenhuma chave nova; as `firestore.rules` não mudam nesta etapa.

**Onde o app fica diferente do site, com o porquê:**

| O quê | Site | App | Por quê |
| --- | --- | --- | --- |
| Gráficos na obra | donut, evolução e gasto por mês | só a barra empilhada de tópicos | parte 1, decisão 3, e a troca pedida por ele |
| Cores do anel | 8 cores, repetidas do 9º tópico em diante | 6 cores e "Outros" em cinza | parte 1, decisões 1 e 2: as cores do quadro não separavam os pedaços (ΔE 10,8) |
| Legenda da obra | 7 tópicos, sem dizer que há mais (achado 6) | os 4 maiores e "e mais N tópicos" | a barra empilhada |
| Toque no anel | abre a folha do tópico | escolhe; "Ver gastos" e a linha abrem a folha | brief 5, toque C |
| Mês padrão do gasto por mês | o último com gasto, que pode ser futuro (achado 2) | este mês | parte 1, decisão 5 |
| Toque nos gráficos de mês | tocar numa coluna | tocar ou arrastar, com o gráfico inteiro como alvo | parte 1, decisão 5 |
| Parcelas a vencer | iguais aos meses pagos; nada explica a diferença (achado 1) | tracejadas, e uma frase em âmbar | parte 1, decisão 7 |
| Relatório | tabela que rola de lado, caixinha por gasto | blocos por tópico; Selecionar com marcador também no tópico | brief 6; parte 2, decisão 3 |
| Busca no Relatório | não existe | lupa, chip e resumo dos achados | parte 2, decisões 8 a 10 |
| Veredito | cartão com ✓ ou alerta | sólido verde ou âmbar | brief 4; parte 2, decisão 4 |
| Números negativos (lucro, acima do banco, margem) | vermelhos (`neg`) | âmbar, nunca vermelho | parte 1, decisão 4; notas dos quadros `rel-vendida-fim` e `sim-abaixo-baixo` |
| Faixa do "Vale a pena?" | não existe | custo, empate com o banco e venda | brief 4 |
| PDF | a impressão da tela, na web; a planilha CSV, no app iOS de hoje | PDF próprio e completo, pela folha de compartilhar | brief 7; parte 2, decisão 1. O CSV é da etapa 5 |

**Iguais ao site, de propósito:** a obra com menos de 1 mês (parte 2, decisão 5); a evolução que para em hoje ou na venda; as portas só com gastos; os textos do site, salvo os novos que o mockup marca em âmbar.

## PR 0 do site: as regras que só vivem no app.js

Como nas etapas 2 e 3, a regra que só existe dentro do `app.js` sobe antes para o `calc.js`, num PR só do site, e entra nos vetores (`scripts/vetores-calc.mjs`), para site e app serem conferidos pelos mesmos casos. A forma é a do PR 0 das etapas 2 e 3:
- a cópia em Swift e o leitor de cada grupo de vetores entram no mesmo commit da regra, porque o núcleo barra grupo de vetor sem leitor;
- o comportamento do site não muda (as suítes de browser que abrem o Relatório ou o simulador, `fase3`, `ios`, `mobile`, `nativo`, `vidro` e `xss`, continuam verdes), salvo os dois alinhamentos abaixo, que ele aprovou em 29/10;
- uma subida só do `CACHE` do `sw.js`, no fim.

**As seis regras** (inventário, "Regras que só vivem no app.js", itens 1 a 6; linhas do `app.js` da `cec9fc0`):

| # | Regra | `app.js` | Sobe para |
| --- | --- | --- | --- |
| 1 | Gasto por tópico: a soma bruta por tópico e a ordem, com o empate pela ordem dos gastos. O núcleo já tem a cópia (`gastoPorTopico`, DentroDaObra.swift:62), sem vetor | 412-414, 1060-1064 | `calc.js` |
| 2 | Grupos do relatório: o fim da correção (hoje uma cópia à mão do `fimCorrecao`), a ordem dos gastos e dos tópicos, o bruto e o corrigido de cada gasto e de cada grupo, e os totais | 1164-1178, 1188 | `calc.js` |
| 3 | Fim do relatório: venda, lucro bruto e acima do banco; ou venda estimada e margem; ou nada | 1196-1206 | `calc.js` |
| 4 | A linha da correção: "Correção de {taxa}% ao mês, da data de cada gasto até a venda ({data})." ou "… até hoje ({data})." | 1213 | `calc.js` |
| 5 | Soma da seleção: "N item"/"N itens", bruto, corrigido e parte do total com 2 casas ("0%" com total zero). Serve também ao resumo dos achados da busca | 1235-1243 | `calc.js` |
| 6 | Simulador: as obras elegíveis e a escolhida, o preço inicial, os meses, a conta (alvo, menos de 1 mês, TIR, acima do banco, veredito, multiplicador) e os textos do cartão e da tabela | 1252-1257, 1267-1312 | `calc.js` |

- O mês escolhido por padrão nos gráficos e a escala dos eixos (inventário, itens 7 e 8) ficam no `app.js`: o app faz diferente, e não há regra a dividir.
- **Dois alinhamentos, aprovados pelo Giovani em 29/10 (confirmação 4).** Subir a regra 6 já com o comportamento do app evita duas cópias diferentes da mesma conta, como os três alinhamentos da etapa 3:
  - o preço acompanha a venda estimada da obra escolhida enquanto a pessoa não digitou (no site, a segunda obra herda o preço da primeira: achado 4);
  - os meses ficam entre 0 e 120 na conta (no site, o teto só existe no `<input>`: achado 5).

**Armadilhas conferidas.** Nenhuma chave nova no blob, então as rules não mudam. Nenhum arquivo novo na raiz, então o `ASSETS` do `sw.js` não muda; o `CACHE` sobe uma vez, porque `calc.js` e `app.js` mudam. Nenhuma dependência de runtime no browser. Nada inline no HTML (CSP).

**Regras novas do app, sem vetor do site** (com teste próprio, como o "Tópico inicial" da etapa 2):
- os pedaços do anel e da barra: até 7 tópicos, um pedaço cada; com 8 ou mais, os 6 maiores e "Outros", com a soma e quantos tópicos junta;
- o "<1%" e o piso de arco e de largura;
- o mês padrão do gasto por mês: este mês, o da venda na vendida e, fora da série, o último com gasto (é o que o quadro faz);
- os meses a vencer (depois deste mês ou da venda), as frases do que ficou fora da evolução (a vencer, ou com data depois da venda) e o "Inclui R$ … a vencer." do anel;
- a parte da obra de cada tópico no Relatório, com 1 casa;
- média, maior e meses (confirmação 2);
- a escala redonda e os rótulos do eixo X;
- "N de M gastos" por tópico na busca;
- a paginação do PDF.

## Arquitetura

As três camadas do spec do app nativo, sem pacote novo.

**Núcleo (`CusttaNucleo`).**
- A cópia das seis regras do PR 0, com os vetores, e as regras novas do app, com teste próprio.
- A paginação do PDF como conta pura: a altura de cada linha, onde a página quebra, o "(continuação)", o cabeçalho repetido e a descrição maior que uma página, partida entre as linhas do texto. Assim ela se testa sem tela.
- Nenhuma mutação nova.

**Dados e estado (app).**
- O `ModeloApp` não ganha ação: as telas novas leem o estado do `Sincronizador`.
- A seleção e a busca do Relatório e o mês escolhido nos gráficos moram na tela, como o filtro dos lançamentos da etapa 3: não vão para a nuvem e zeram ao sair.
- Uma mudança vinda de outro aparelho redesenha Gráficos e Relatório na hora (o site não redesenha: achado 3), sem perder a seleção, a busca nem o foco do campo. O gasto que some sai da soma.
- Os campos do "Vale a pena?" moram na aba enquanto o app está aberto. Se a obra escolhida deixa de ser elegível (vendida ou apagada), a escolha cai na primeira elegível, como no site.

**Telas (app).**
- **Obra:** reescrita em blocos, mantendo da etapa 3 a lista, a busca, o filtro por mês, os afazeres, as folhas e os gestos. A linha de lançamento da obra ganha o valor em mono e o ícone pequeno na 2ª linha; as folhas (A pagar e detalhe do tópico) continuam com a linha da etapa 3.
- **Gráficos e Relatório:** empurrados no caminho de Obras (`RotaDeObras`, ObrasView.swift:5), como a tela Orçamento.
- **"Vale a pena?":** uma aba nova. Hoje a `Aba` tem `obras` e `ajustes` (CapsulaDeAbas.swift:18-20), e o `PrincipalView` já anota que essa aba chega na etapa 4 (PrincipalView.swift:4).
- **Barra de soma:** no Selecionar, ela toma o lugar da cápsula de abas, que é um `safeAreaBar` do `PrincipalView` (PrincipalView.swift:29).
- **Gráficos e anel:** desenhados pelo app, sem Swift Charts, com marcas em `Shape` e o texto em views (conselho, item 1). O Giovani aprovou em 29/10 a troca da linha 67 do spec geral.
- **Telas da análise:** moram em `Custta/Analise/`, ligadas ao resto do app por uma costura só, feita no PR da obra (seção "PRs").
- **PDF:** tabelas em UIKit fora da thread principal e a página 1 composta em SwiftUI, com a folha de compartilhar do sistema (conselho, item 2).
- **Teclado de valor:** o `TecladoDeValor` da etapa 3, num campo só (sem ‹ ›).

## PRs

**Decisões do Giovani (29/10, no adendo ao conselho).**
1. **Corte por risco.** O alvo é de ~500 a 1.000 linhas de código de produção por PR; teste, vetor gerado, `vendor/` e docs não contam. Um PR acima de ~1.000 leva a justificativa escrita no próprio PR.
2. **O PR 1 vira três**, nesta ordem: (a) os tokens globais sozinhos, com o laudo inteiro provando que nada caiu nas etapas 1 a 3; (b) as peças da identidade; (c) a obra reescrita.
3. **TestFlight por marco, não por PR.** Um marco junta os PRs que formam uma entrega testável no iPhone.

**Decisões do Giovani (29/10, nas respostas ao conselho).**
1. **A linha 67 do spec geral:** sai o "Gráficos com Swift Charts", e os três gráficos são desenhados pelo app (conselho, item 1). Ele perguntou se a animação de girar do anel continua; continua, e foi por isso que aprovou a troca.
2. **As duas sondas na CI,** num ramo `proto/`, só com o job delas: o gerador do PDF fora da thread principal no Swift 6.3.3 e a marcação para leitor de tela no iOS 26.
3. **Merge no meio do marco sem OK por lado a lado antes.** Com a CI toda verde, a revisão aprovada e nenhum rerun no iOS 26, o Orquestrador mescla, até 5 seguidos; no 5º, manda a ele um resumo com os prints lado a lado (simulador × mockup) de cada PR. Sempre com o OK dele: o 1a (tokens globais), com o antes × depois das telas principais no claro e no escuro, e o TestFlight de cada fecho de marco. Enquanto um PR espera o OK, o time segue no seguinte, empilhado, com no máximo 2 esperando.
4. **O "Vale a pena?" adiantado,** abrindo o marco 2, **e os 3 marcos** como no conselho.

**O corte (conselho, item 3; aprovado por ele em 29/10).** São 11 PRs em 3 marcos. As linhas são de produção, estimadas pela régua dos PRs das etapas 2 e 3, cujos PRs de tela ficaram entre ~1.100 e ~2.100. Os portões estão explicados depois da tabela.

| Ordem | PR | O que entrega | Linhas (est.) | Portões | Marco | Escondido na `main` até o seguinte |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 0 (site) | as seis regras do `app.js` no `calc.js`, com vetores, cópia em Swift e leitores; os dois alinhamentos; uma subida do `CACHE` | ~600–850 | núcleo | — | nada no site: os dois alinhamentos vão ao ar no merge; no app, as regras ficam no núcleo, sem tela |
| 2 | 0b (núcleo) | as regras novas do app (pedaços, piso, "<1%", escala, rótulos, mês padrão, a vencer, frases, média, maior e meses, "N de M", parte com 1 casa) e a paginação do PDF | ~450–600 | núcleo | — | regras sem uso |
| 3 | 1a | os tokens globais, com o âmbar do claro, a cápsula de abas com borda de 16, o globo e o halo do título | ~50–150 de Swift (o catálogo de cores não conta) | tudo, com a comparação | 1 | tokens novos sem uso |
| 4 | 1b | as peças: bloco, sólido verde e âmbar, número mono com piso de 11 pt, título em SF Mono, grade 16/34, placa, cápsula de metadados, hachura, barra empilhada e linha de lançamento mono | ~600–800 | tudo, com a comparação (`ValorEmDinheiro` tem 20 usos) | 1 | peças sem tela |
| 5 | 1c | a obra em blocos, com todos os estados; a costura das telas da análise em `Custta/Analise/` (rota, abertura de Debug e dados falsos, ainda sem destino); o modo de marcas apagadas do laudo | ~1.000–1.200 | tudo, com a comparação | **1, fecha** | a barra empilhada sem toque e sem "Gráficos ›"; nenhuma porta |
| 6 | 4a | "Vale a pena?": a aba (a cápsula com 3 abas, e o + some nela), campos, veredito, faixa, tabela e estados | ~750–950 | tudo, com a comparação (a cápsula de toda tela) | 2 | nada |
| 7 | 2a | Gráficos: a tela; o anel, com entrada, toque C, "Ver gastos" e "Outros"; a lista com seta para a folha; os estados | ~700–900 | telas novas | 2 | a tela só abre pelo Debug |
| 8 | 2b | evolução e gasto por mês (toque, arrasto, vibração, ajustável e descritor, hachura, 24 meses); a barra empilhada da obra passa a abrir os Gráficos | ~850–1.000 | tudo | **2, fecha** | sem o "Exportar PDF"; nenhuma porta |
| 9 | 3a | Relatório: sólido, cápsula, blocos por tópico, fim (venda e margem), estados; a busca, com o resumo dos achados | ~850–950 | telas novas | 3 | a tela só abre pelo Debug |
| 10 | 3b | Selecionar: marcadores, tópico com 3 estados, barra de soma no lugar da cápsula, Selecionar sobre a busca, seleção que sobrevive à mudança remota; a fileira de portas da obra aparece | ~650–750 | tudo, com a comparação | 3 | sem o "Exportar PDF" |
| 11 | 4b | PDF: gerador, página 1, folha de compartilhar, os botões no fim dos Gráficos e do Relatório; o checklist do aparelho da etapa | ~750–950 (mais ~100 da marcação, se a sonda passar) | tudo | **3, fecha** | — |

**Acima de ~1.000.**
- **O 1c (~1.000 a 1.200).** A obra é uma tela só, e quase metade das linhas é a obra da etapa 3 saindo. Partir o PR deixaria duas identidades na tela mais usada e trocaria duas vezes as cenas da obra no laudo. O que dava para separar (a barra empilhada e a linha mono) já foi para o 1b. Se as fatias do plano passarem de ~1.300, os Lançamentos viram um 1d, com o OK do Giovani, porque foi ele quem fixou os três PRs.
- **Os outros.** Se o 2b passar de ~1.000, a evolução vira um 2c, que fecha o marco 2. Se o 3a passar, a busca vira um PR entre o 3a e o 3b. Se o 4b passar com a marcação, a marcação vira um PR seguinte, que fecha o marco 3.

**Portões por superfície.** Um job no Ubuntu, que não ocupa vaga de macOS, lê o diff do PR e escolhe o nível. Na dúvida, roda tudo.

| Nível | Quando | O que roda |
| --- | --- | --- |
| núcleo | o PR só mexe em `CusttaNucleo/`, no site e nos vetores | `nucleo` e um job de unidade (o build Release sem assinatura e os testes de unidade) |
| telas novas | o PR só mexe em `Custta/Analise/` e nos testes dela | o nível núcleo, mais os jobs da etapa 4 (tela, laudo e auditoria das telas novas, no iOS 26, de até ~45 min cada) |
| tudo | qualquer outro arquivo do app, o catálogo de cores, os testes compartilhados (laudo e auditoria) ou o workflow; e sempre o PR que fecha o marco | todos os jobs |

- **A comparação.** Todo PR que muda peça compartilhada (tokens, peças, a obra, a cápsula, o `PrincipalView`) compara o laudo inteiro palavra por palavra com o do commit anterior (seção "Testes e validação", item 6).
- **Onde moram o filtro e os jobs.** O filtro, a guarda dele no `tests/workflow.test.cjs` e os jobs da etapa 4 entram num PR que já roda tudo, antes do 2a. O conjunto inteiro sob demanda sai por `workflow_dispatch`, nunca por rótulo.
- **O laudo no Pro Max.** O laudo inteiro no Pro Max continua no Mac, no fim de cada PR. Na CI, um aparelho só.
- **Para encurtar a espera.**
  - O portão do Mac vale por tarefa, e o push para a CI vai nos pontos de controle, com os consertos juntos, porque cada push cancela o run em curso.
  - As sondas `proto/` rodam só com o job delas, fora da janela do run do PR.

**Escondido na `main`.** Só por ausência: a porta, o toque, o botão ou a aba entram no PR que completa o destino. Até lá, os testes abrem a tela pelo `CUSTTA_ABRIR=<rota>:<id>` de Debug, que não vai ao Release (o `nm` confere). A `main` fica publicável em qualquer commit.

**Marcos e espera.**
- **O build.** O TestFlight sai do merge que fecha o marco, com uma tag (`etapa4-marco-1`, …). Um conserto urgente sai da tag, não da `main` no meio do marco.
- **A espera.** Dentro do marco, nenhum PR espera build. O 1º PR do marco seguinte pode ser feito durante o teste do Giovani no iPhone, mas só é mesclado depois do OK dele no build.
- **O merge no meio do marco (decisão 3 dele, acima).** Não há OK por lado a lado antes: com os testes passando, o Orquestrador mescla, até 5 seguidos, e o 5º leva a ele o resumo com os prints lado a lado de cada PR. O 1a e o TestFlight de cada fecho esperam o OK dele, e o iPhone fica para o fecho.
- **O checklist.** Cada marco tem um checklist do aparelho, com VoiceOver, Controle por Voz e a letra máxima. O da etapa fecha no 4b.
- **Cada PR nasce num worktree novo,** a partir da `origin/main` atualizada, ou empilhado sobre o PR que espera o OK dele, com no máximo 2 esperando.

## Conta

A etapa não grava nada novo, e os builds seguem na conta de sempre. Os caminhos de gravação que se alcançam pelas telas novas são os das etapas 2 e 3 (editar e apagar gasto na folha do detalhe do tópico e, pelo +, lançar gasto), já conferidos no aparelho. Os itens do checklist que mexem em gasto usam uma obra de teste criada no próprio app e apagada no fim. O PDF fica no aparelho até a pessoa escolher para onde mandar.

## Testes e validação

Os mesmos portões da etapa 3, estendidos:

1. **Vetores:** as seis regras do PR 0 conferidas contra o site (`swift test` no job `nucleo`), com casos fora do exemplo de sempre: vendida, sem venda estimada, margem negativa, taxa com vírgula, obra com menos de 1 mês, venda zero, meses 0, 1 e 120, área zero, multiplicador abaixo de 1, gasto futuro, empate de bruto e gastos na mesma data. O nome do caso não prova nada sem um caso que mate a mutação.
2. **Unidade do app:** as regras novas (pedaços do anel e da barra com 1, 7 e 8 tópicos, "<1%", mês padrão, meses a vencer, a frase do que ficou fora, escala redonda, "N de M gastos"), a seleção que sobrevive a uma mudança remota, a paginação do PDF (quebra de tópico, "(continuação)", cabeçalho repetido, "página N de M", vendida e sem venda) e o número que encolhe (teste de largura no maior valor, na letra máxima em 375 pt).
3. **Telas (XCUITest):**
   - a obra nos estados (sem orçamento, sem gastos, pronta, vendida com lucro e com prejuízo), as portas só com gastos e a barra que abre os Gráficos;
   - o anel: tocar, tocar de novo, "Outros", "Ver gastos" e a linha que abre a folha; editar um gasto na folha e ver o gráfico mudar atrás;
   - os gráficos de mês: tocar, arrastar e rolar a tela começando no gráfico; o ajustável que troca o mês se prova dentro do processo, porque o `increment()` do XCUITest só existe no macOS;
   - os estados dos Gráficos: 1 gasto, 1 mês, 1 tópico, tópico pequeno, a obra vendida e sem gastos (apagando o último gasto pela folha);
   - o Relatório: abrir e fechar tópico; Selecionar com nenhum, um e vários, e o marcador do tópico nos 3 estados; vendida; sem venda;
   - a busca: com e sem acento, o tópico que abre sozinho, nada encontrado e "Limpar a busca", o Selecionar sobre o resultado, "Marcar os N achados" e o aviso dos marcados fora da busca;
   - o "Vale a pena?": sem obra, sem preço, menos de 1 mês, vale, rende menos, o − e o + nos limites 0 e 120, a troca de obra;
   - "Exportar PDF": a folha do sistema aparece, e o arquivo, lido pelo PDFKit, tem as páginas e os textos esperados.
4. **Reduzir movimento:** o anel aparece pronto. O XCUITest não vê transiente, então a entrada se prova por vídeo ou por uma rajada de prints.
5. **Leitura sobre o vidro e acessibilidade:** o laudo de leitura (portão na CI) e as auditorias cobrem as telas novas e a obra nova nos dois temas, na letra padrão e na máxima, no 18 Pro e no Pro Max. As marcas de gráfico (pedaços do anel, linhas, barras e a barra empilhada) entram no laudo com o mínimo de 3:1 do mockup, por um modo de Debug que apaga só as marcas (conselho, item 1).
6. **Prova de que nada caiu nas telas das etapas 1 a 3:** os tokens globais e a cápsula de abas mudam no PR 1. O laudo inteiro roda nos dois aparelhos, e as tabelas são comparadas palavra por palavra com as do commit anterior: fora das linhas que usam um token mudado, a diferença é zero; nas que usam, o contraste só sobe. A obra, que muda inteira, ganha cenas novas no lugar das antigas.
7. **Conferência visual:** simulador lado a lado com os prints do mockup, tela a tela.
8. **Conferência cruzada:** não há mutação nova, e a da etapa 3 continua. Os números das telas novas (os grupos e a soma do Relatório e a conta do simulador) vêm do PR 0 e são conferidos pelos vetores.
9. **Site:** as suítes de browser continuam verdes no PR 0; os dois alinhamentos ganham teste de browser conferido por mutação.
10. **Aparelho:** um checklist da etapa 4 no estilo do da etapa 3, testado pelo Giovani a cada build e fechado no PR 4.

## Decisões do conselho (29/10)

O conselho rodou em 29/10, depois das sete confirmações e do adendo do Giovani sobre o tamanho dos PRs (seção "PRs").
- **Propostas:** três subagentes Opus novos, um por lente, propuseram sozinhos. As lentes: desempenho e bateria; acessibilidade e legibilidade; fidelidade ao mockup, à HIG e ao spec.
- **Crítica:** três críticos novos, nas mesmas lentes, criticaram às cegas as duas propostas das outras lentes.
- **Presidência:** o Prumo.
- **Medidas antes:** dois protótipos no simulador (iOS 27, iPhone 18 Pro), num clone fora do repositório.

**O que as medidas mostraram.**
- **Anel.** O desenho próprio é um arco por pedaço, girado por `rotationEffect`. Ele gira igual à tira do mockup nos 9 instantes, não perdeu quadro em 5 entradas e custou +0,089 s de CPU acima do fundo. O `SectorMark` do Swift Charts cresce em vez de girar e não faz a ponta que monta nem o aro. Perdeu de 1 a 3 quadros por entrada e custou +0,129 s.
- **Arrasto no gasto por mês, com o fundo parado.** O desenho próprio perdeu 0 quadro e gastou 0,125 s de CPU. O Swift Charts, com `DragGesture`, perdeu 3 quadros por arrasto (de 0 a 5), com intervalo de até 61 ms, e gastou 0,220 s. O `chartXSelection` e o `chartAngleSelection` não responderam ao toque sintetizado do XCUITest.
- **Acessibilidade.**
  - Com a acessibilidade feita à mão (um elemento ajustável com o nosso descritor), o Swift Charts e o desenho próprio empatam, com 1 achado só, o da fonte fixa do protótipo.
  - Sem nada feito à mão, o Swift Charts deu 21 "Hit area is too small" e rótulos crus ("2025-08", "222.728"). No `SectorMark`, os setores ficaram sem rótulo e sem descritor.
  - O anel próprio como lista de itens deu 0 achado na letra padrão e na máxima.
- **PDF, com 5.000 gastos (214 páginas).**
  - Tempo: as tabelas em UIKit saem em 0,76 s, contra 1,78 s em SwiftUI (3,0 contra 7,7 ms por página). A paginação leva de 121 a 134 ms.
  - Thread e memória: fora da thread principal, o UIKit a prende só na página 1 (de 9 a 20 ms) e gera o mesmo PDF. A memória fica no máximo 1,8 MB acima da de antes.
  - Conteúdo: as duas formas dão texto de verdade, 0 imagem e fontes embutidas, e nenhuma das duas marca o PDF.
  - Linhas sumidas: `draw(with:)` numa altura infinita apaga linhas das descrições longas (38, 166 e 408 linhas com 500, 2.000 e 5.000 gastos). Na altura prevista, não apaga nenhuma.
  - Quebra de linha: o `Text` do SwiftUI quebra a linha noutro lugar que a medida da paginação em 19 a 28% das descrições longas.
- **CI, nos runs do #88, pelo GitHub.** Rodam 5 jobs de macOS por vez. Um push com os 10 jobs soma de 330 a 372 min de VM e leva de 79 a 96 min de relógio. O laudo e a auditoria são 53% desses minutos, e os últimos a fechar foram laudos esperando vaga. Um push novo cancela o run em curso (`cancel-in-progress`).
- **O que não provam:** o iPhone (o simulador roda a 60 Hz, e a CPU é a do Mac), o iOS 26 da CI, o VoiceOver de verdade, o arrasto com o fundo andando e o gráfico dentro de uma tela que rola.

**Quem ganhou cada crítica.** Cada crítico comparou duas propostas.
- **Item 1 e item 2:** a proposta de fidelidade foi a melhor nas duas críticas que a leram. No item 1, a de desempenho ganhou da de acessibilidade; no item 2, a de acessibilidade ganhou da de desempenho.
- **Item 3:** a proposta de desempenho foi a melhor nas duas críticas que a leram, e a de acessibilidade ganhou da de fidelidade.

| Item | Decisão | Descartado | Por quê |
| --- | --- | --- | --- |
| 1. Gráficos | Os três desenhados pelo app, sem Swift Charts: marcas em `Shape`, todo texto em view e a acessibilidade feita à mão | tudo em Swift Charts; o anel próprio com a linha e as barras em Swift Charts; marcas e texto num `Canvas` | foi unânime nas três propostas. O Swift Charts não faz a entrada, a ponta nem o aro, e de fábrica reprova a auditoria. Com a acessibilidade feita à mão, empata no VoiceOver e perde no arrasto (medido). Contra o `Canvas` com texto pesou a crítica de acessibilidade: o texto desenhado ali escapa da auditoria, do teste de largura e do laudo |
| 2. PDF | Tabelas em UIKit fora da thread principal, na altura prevista; a página 1 composta à parte, em SwiftUI; a paginação no núcleo; a folha do UIKit | tudo em SwiftUI; o `ShareLink`; a página 1 como as views da tela; a marcação prometida sem sonda | as três propostas escolheram as tabelas em UIKit. A crítica de fidelidade mostrou que a página 1 aprovada (`parte2-pdf-1.png`) não é a tela. Duas críticas trouxeram a marcação pela API do iOS 13, e a de desempenho pediu o custo dela medido antes |
| 3. Corte e ordem | 11 PRs em 3 marcos, com o que pega o app inteiro primeiro; portões de CI por superfície que, na dúvida, rodam tudo | laudo e auditoria só no fecho do marco; escopo por lista de arquivos e por rótulo; um segundo aparelho na CI; 12 PRs em 4 marcos | pesaram três coisas. A regra da proposta de desempenho: o filtro, na dúvida, roda tudo, e a casca muda no PR que fecha o marco. A ordem da de fidelidade: a 3ª aba cedo, para as telas novas nascerem medidas com a cápsula final. A fila de 5 vagas da CI, que a crítica de desempenho mediu |

### 1. Gráficos: desenho próprio nos três

- **Conta pura.** A geometria sai de funções puras que devolvem `Path`. As regras ficam no núcleo, com teste:
  - os pedaços (6 + "Outros"), o piso de 10 pt e o "<1%";
  - o pedaço sob um ângulo e o mês sob um x;
  - a escala redonda e os rótulos do eixo X;
  - o mês padrão, os meses a vencer e as frases;
  - a média, o maior e os meses.
- **Anel.** Um `Shape` de arco por pedaço, com o aro, girado por `rotationEffect` com a curva e o atraso do mockup: é o que o protótipo mediu.
  - O toque C apaga pela cor (`Color.mix`, iOS 18) e traz o escolhido à frente por `zIndex`, sem `opacity` nem filtro no grupo.
  - A faixa de toque tem 44 pt ou mais no raio, não só a espessura do traço.
- **Gráficos de mês.** As marcas ficam em `Shape`, uma camada por estado (pago, a vencer, hachura e escolhido). O protótipo mediu o `Canvas`, então o plano mede o `Shape` com o mesmo medidor. Se o `Shape` perder quadro, as marcas, e só elas, vão para o `Canvas`.
- **Texto sempre em view.** Rótulos de eixo, leitura e legenda são `Text`, nunca `draw(Text…)` num `Canvas`, e uma guarda Node barra o desvio.
  - Os rótulos param em 19 pt. Eles ganham uma exceção na auditoria por identificador, como a do título pequeno da barra (AuditoriaUITests.swift:75-87), e um teste de largura em 375 pt na letra máxima.
  - A leitura acima do gráfico é mono e cresce com a letra.
- **Entrada.** Só quando a tela é empurrada. Não roda ao voltar da folha nem com dado novo: aí o anel troca sem girar. Um toque encerra a entrada, e a lista aceita toque já no 1º quadro. Com Reduzir movimento, o anel aparece pronto.
- **Toque e arrasto nos meses.**
  - O toque escolhe o mês.
  - O arrasto só assume quando o dedo anda na horizontal, por `UIGestureRecognizerRepresentable`, como o `ArrastoParaApagar` e a `BordaQuePergunta`. Assim a tela rola mesmo quando o dedo começa no gráfico.
  - Cada mês novo dá uma vibração de seleção.
  - Durante o arrasto, o fundo para, como na rolagem (`PausasDoFundo.mudou`, Movimento.swift:128).
  - O protótipo não tinha rolagem, então o plano prova antes a rolagem que começa no gráfico.
- **VoiceOver.**
  - **Gráfico de mês:** um elemento ajustável, com o valor do mês escolhido ("outubro de 2026, R$ 29.905,40", ou "…, a vencer"), o descritor (1 série no gasto por mês, 2 na evolução) e rótulos de voz.
  - **Prova:** o valor falado, o passo e o descritor são conta pura, com teste de unidade. A inspeção dentro do processo, como a do protótipo, fica como teste de fumaça, porque o `increment()` do XCUITest só existe no macOS.
  - **Anel:** a lista de itens do Croqui (medida, 0 achado), num contêiner cujo rótulo traz o resumo: "Gasto por tópico: R$ 842.317,45 em 14 tópicos; o maior é Terreno, 38%".
    - Cada item tem o quadro do pedaço. O toque duplo abre o detalhe do tópico, como a linha da lista, e "Outros" diz quantos tópicos junta.
    - O "Ver gastos ›" é um botão de 44 pt que o VoiceOver e o Controle por Voz alcançam.
  - **Dado novo:** quando o dado muda com a tela à vista, o VoiceOver é avisado, além da animação, como pede a HIG.
- **Laudo das marcas.** Um modo de Debug apaga só as marcas, como o texto apagado apaga o texto. Com ele, o laudo mede a 3:1 os pedaços, as linhas, as barras e a barra empilhada, nos vidros Transparente e Fosco. A `BarraApagada` conta como dado.
- **A linha 67 do spec geral (aprovada pelo Giovani em 29/10).** Passou de "Gráficos com Swift Charts" para "Gráficos desenhados em SwiftUI, no visual do Custta, com a acessibilidade dos gráficos do sistema (descritor e gráfico em áudio)". Ele perguntou se a animação de girar do anel continua; continua, e foi por isso que aprovou. A linha 110 fica: nada de biblioteca de terceiros.
- **Descartado:** a proposta de acessibilidade trocava a lista do anel por um elemento de resumo. A troca não foi medida e mudava a recomendação do Croqui (crítica de fidelidade). O resumo foi para o rótulo do contêiner.

### 2. PDF: tabelas em UIKit, página 1 à parte

- **Página 1.** É composta à parte, como em `parte2-pdf-1.png`:
  - o anel com a legenda ao lado e nada no meio;
  - o "Gasto acumulado" sem eixo;
  - as barras todas `PdfVerde`, com as futuras só no contorno.
  
  O desenho usa as marcas do item 1 (a geometria e os `Shape`), não as views da tela. O ambiente é explícito (claro, letra padrão, pt-BR, a paleta do PDF), com fontes fixas. O `ImageRenderer` a desenha na thread principal num PDF de uma página, que entra no arquivo por `drawPDFPage`.
- **Da página 2 em diante.** O `UIGraphicsPDFRenderer` desenha com `NSAttributedString.draw(with:)`, sempre na altura prevista (`ceil(h) + 1`), nunca na infinita.
  - Medida e desenho usam a mesma string e a mesma largura.
  - Roda num `Task.detached`, com uma `autoreleasepool` por página, e escreve direto no arquivo.
- **Paginação no núcleo.**
  - Recebe as linhas de texto medidas, pelo mesmo motor do desenho.
  - Parte a descrição maior que uma página.
  - Repete o cabeçalho e põe o "(continuação)" sem os totais.
  - Mantém o fim inteiro numa página e numera "página N de M".
  - A largura da coluna de valor sai do maior valor.
- **Botão.**
  - Fica desabilitado no toque.
  - Se a geração passar de ~150 ms, vira "Gerando PDF…", com o indicador do sistema e o aviso ao VoiceOver. É um texto novo.
  - Um erro abre um alerta.
  - Sair da tela cancela a geração e apaga o arquivo parcial.
  - O fundo para durante a geração e com a folha aberta, como já para com uma folha aberta (PrincipalView.swift:54).
- **Folha.** É o `UIActivityViewController`, com a URL do arquivo pronto. O arquivo fica em `tmp/PDF/<uuid>/Custta-<obra>.pdf`, sai ao fechar a folha, e o app varre os restos ao abrir. O `ShareLink` saiu: ele pede a URL antes do toque, ou gera às cegas depois da escolha do destino, sem retorno nem erro.
- **Leitor de tela.**
  - O título do documento (`kCGPDFContextTitle`) entra sempre.
  - A marcação entra se a sonda passar. Ela usa a API do iOS 13 (`CGPDFContextBeginTag`/`EndTag`): documento em pt-BR, títulos, tabela com linhas e células e figura com texto alternativo na página 1.
  - A sonda confere quatro coisas: a árvore gravada no iOS 26, a tabela atravessando páginas, a leitura pelo VoiceOver da Pré-Visualização e o custo com 5.000 gastos (tempo até +15%, memória e tamanho).
  - Se a sonda não passar, o PDF sai sem marcação, na mesma forma.
- **Testes.**
  - Ler o PDF de volta: páginas, textos, valores inteiros, a ordem da linha e da página 1, 0 imagem, fontes embutidas com `ToUnicode`.
  - Tinta em cada linha prevista, com descrições longas, na CI. É a prova contra as linhas que sumiam na altura infinita.
  - Uma descrição de 3.000 caracteres.
  - O mesmo PDF com o app no escuro, na letra máxima, com Negrito, Aumentar contraste, Reduzir transparência e o Fosco: igual em texto e em pixels. Nunca em bytes, porque o `/ID` e a data mudam.
- **Duas sondas na CI (OK do Giovani em 29/10)**, num ramo `proto/`, só com o job, como na etapa 3. Uma prova o gerador fora da thread principal no Swift 6.3.3; a outra, a marcação no iOS 26. O resultado entra no plano do marco 3.
- **Descartado:**
  - tudo em SwiftUI: é 2,3 vezes mais lento, prende a thread principal, e o `Text` quebra a linha noutro lugar que a paginação;
  - a comparação por bytes: reprova sempre;
  - a página 1 como as views da tela "em modo papel": não é o desenho aprovado.

### 3. Corte e ordem dos PRs

A tabela e as regras estão na seção "PRs". O voto:
- **Ordem.** Primeiro vem o que pega o app inteiro: os tokens, as peças, a obra e a 3ª aba (o "Vale a pena?", que muda a cápsula de toda tela). Depois vêm os Gráficos e o Relatório, e por último o PDF, que depende dos dois. Assim os Gráficos e o Relatório nascem medidos com a cápsula final (crítica de acessibilidade).
- **Escondido na `main`.** Só por ausência, sem chave de liga-desliga. A porta, o toque ou o botão entram no PR que completa o destino. Até lá, a tela só abre pelo `CUSTTA_ABRIR=<rota>:<id>` de Debug (PrincipalView.swift:176-190), e o `nm` confere que ele não vai ao Release. A fileira de portas só aparece com as duas portas com destino, porque o mockup nunca mostra uma porta sozinha. Assim a `main` fica publicável em qualquer commit.
- **Laudo e auditoria só no fecho do marco: não é seguro, e foi unânime.** O iOS 26 já pegou no laudo e na auditoria o que o Mac não via: a sombra do voltar e achados que só saíram na CI. Adiado, o vermelho cai no PR que fecha o marco, com dois ou três PRs já mesclados e a bisseção a 40–60 min por rodada. A variante segura, com os portões por superfície da seção "PRs", dá quase todo o ganho:
  - os PRs do meio do marco que só trazem tela nova rodam 5 jobs, uns 45 min por tentativa, contra 13 jobs e 90 min ou mais;
  - os PRs sem tela rodam 2 jobs, uns 20 min.
- **Descartado:**
  - escopo por lista de arquivos e por rótulo: na dúvida, roda menos; e pôr o rótulo dispara um run novo, que cancela o anterior;
  - um segundo aparelho na CI: o laudo inteiro do Pro Max roda no Mac, no fim de cada PR, como desde 24/10;
  - 12 PRs em 4 marcos: cada PR e cada TestFlight a mais pagam de novo o custo fixo de fechar.
- **Respostas do Giovani (29/10, seção "PRs").** O "Vale a pena?" adiantado, abrindo o marco 2, e os 3 marcos foram aprovados. O OK por lado a lado no meio do marco não ficou: com os testes passando, o Orquestrador mescla, e só o 1a e o TestFlight de cada fecho esperam o OK dele.

**Referências que mudariam o voto.** Nenhuma das 8 muda a técnica dos gráficos nem a do PDF.
- **1:** pode trocar o gesto dos meses: segurar para varrer, ou passos com setas, se o Controle por Voz falhar no aparelho.
- **2:** mexe no 6 + "Outros", no 0b e no 2a.
- **4:** não muda nada. Ele aprovou a tira que gira, e mesmo um anel que só cresce ficaria sem a ponta e sem o aro no Swift Charts.
- **7:** pode mexer nas colunas, pedir PDF/A (`kCGPDFContextCreatePDFA`, iOS 14) ou reforçar a marcação.
- **5, 6 e 8:** mudam o tamanho do 3b e do 4a.

Ficam de fora do conselho, porque o mockup ou o spec já fixam ou porque são pequenas:
- os textos, as medidas e os tokens do mockup;
- o número em mono que encolhe;
- a busca do Relatório pela regra da etapa 3;
- a seleção, a busca e o mês escolhido morando na tela;
- a barra de soma no lugar da cápsula;
- a conta.

## Decisões tomadas por recomendação

**Do Croqui, no mockup (rotina; o Giovani pode mudar).**
- **Tópico pequeno:** piso de 10 pt de arco por pedaço, tirado do maior; o % verdadeiro na lista e no meio ("<1%", onde o site arredonda para 0%); o alvo do toque é o pedaço mais perto do dedo, e a lista é o caminho seguro.
- **Escala dos eixos em números redondos** (R$ 250 mil, 500 mil…); o site usa frações do máximo.
- **Obra vendida nos Gráficos:** a evolução para na venda ("até a venda"), e o gasto por mês usa o mês da venda no lugar de "este mês".
- **Contraste:** a cápsula de vidro nos metadados e no contador "Lançamentos"; os chips nos fundos sólidos da etapa 3; o texto verde do claro em `#0E7A41`, o do site; "Marcar como pronta" e o + na Tinta a 100%; a placa (tom chapado, sem desfoque, que não é vidro) atrás do anel e dos gráficos.
- **Letra máxima:** o `SecundarioForte` e a camada do tom a 66% no escuro, a conferir no laudo do app; o meio do anel some, e a leitura vem embaixo, com "Ver gastos ›" de 72 pt; a lista do anel em três linhas por tópico; os rótulos de eixo param em 19 pt, com 2 linhas e 3 meses; os chips param em 32 pt; as portas empilham.
- **VoiceOver:** cada gráfico é um elemento ajustável (deslizar para cima e para baixo troca o mês), com um resumo falado; o anel é uma lista de itens ("Terreno, 38%, R$ 319.847,85"); cada bloco de tópico do Relatório é um botão; no Selecionar, os gastos são botões com estado marcado, e a barra de soma é uma região viva; a faixa tem um rótulo falado com os 3 valores; o chip da busca é um botão ("Busca: ceramica, remover"), e o resumo é uma região viva.
- **Reduzir movimento:** o anel aparece pronto, e o toque só engrossa e apaga, sem animar.
- **Relatório:** "Selecionar" vira "OK"; a barra de soma ocupa o lugar da cápsula de abas e, vazia, diz "Nenhum gasto marcado · Toque nos gastos para somar."; a cor do ponto do tópico é a do anel; com marcador, o texto do gasto começa depois dele (a única exceção à grade de 34 pt).
- **PDF:** sem o endereço do site no rodapé (não há o oficial); o tópico que quebra repete o título com "(continuação)", sem os totais; os números das tabelas em SF Mono; o PDF sai sempre completo, mesmo com a busca aberta.
- **Busca:** cada tópico diz "N de M gastos" e soma só os achados; sem achados, "Nada encontrado com esse filtro." (do site) e o botão "Limpar a busca" (da etapa 3); o teclado é o do sistema; a barra de soma ganhou um vidro mais denso (na letra máxima, o texto de baixo passava borrado por trás).
- **Textos novos**, marcados em âmbar no mockup ("Textos que não são do site", nas duas partes):
  - o meio do anel ("total gasto · N tópicos · Ver gastos ›") e a leitura da evolução ("outubro de 2026 · até hoje · no banco já seria", no lugar do "out/26 · gasto … · corrigido …" do site);
  - "Fora do gráfico: R$ … a vencer (depois de hoje).", e na vendida a frase do quadro `est-vendida` ("… com data depois da venda.");
  - "Inclui R$ … a vencer.", "Outros · N tópicos", "Lucro da venda · acima do banco" e "e mais N tópicos";
  - os convites da obra e dos Gráficos sem gastos, os rótulos do gasto por mês e os textos da barra de soma, da faixa e do PDF;
  - o "Gerando PDF…" do botão, quando a geração passa de ~150 ms (conselho, item 2).

**Deste spec.**
- **PR 0 na forma das etapas 2 e 3:** a cópia em Swift e os leitores no mesmo PR do site, para os dois lados serem conferidos pelos mesmos vetores desde o primeiro commit.
- **Tokens pelo valor** (tabela de tokens): reaproveitar o token do app que já existe com o mesmo papel e valor igual ou mais forte, e criar só o que falta.
- **Globo:** nunca mais claro que hoje; o plano mede e fica com o mais apagado.
- **Halo do título:** a regra do app, o menor passo que fecha 4,5:1 no Pro Max (decisão dele de 10/10, Aurora.swift:186-188); o 38% do mockup (62% na letra máxima) é o ponto de partida.
- **O % do meio do anel sem casa decimal**, como a lista e o detalhe do tópico. O quadro mostra "10,8% da obra" no meio e "11%" na linha, lado a lado; o site arredonda igual nos dois lugares para o número não mudar ao abrir (app.js:1135). Pelo mesmo motivo, o "<1%" da lista vale também no "% da obra" da folha do detalhe, que hoje mostraria "0% da obra" (`Math.round`, calc.js:88). O Relatório fica com a casa decimal do quadro ("38,0%"), porque lá não há outro % ao lado.
- **Os valores da lista e do meio do anel sem centavos, arredondados ao real.** O quadro corta os centavos (R$ 319.847,85 vira "R$ 319.847"); arredondado, fica R$ 319.848, como o `moneyShort` do site arredonda. O VoiceOver diz o valor com centavos.
- **Obra vendida com lucro e "acima do banco" negativo:** prejuízo é o lucro bruto negativo. Com lucro e o acima do banco negativo, o sólido continua o lucro, e o acima do banco aparece com o sinal de menos.
- **"Mostrando os últimos 24 meses."** só quando a série foi cortada. O quadro mostra o aviso também com exatamente 24 meses.
- **O mês corrente no gasto por mês** conta inteiro, como o quadro (pago, mesmo com parcela que ainda vence neste mês). A frase da evolução dá o valor exato a vencer.
- **Nome do arquivo:** `Custta-` e o nome da obra, com espaços trocados por hífen e sem os caracteres que o sistema de arquivos recusa, como no exemplo do mockup (`Custta-Casa-Alphaville.pdf`).

## Referências que faltam (para o Giovani procurar junto)

Regra dele: ninguém improvisa referência. O Croqui desenhou sem estas e listou:
1. **Seleção em gráfico de barras estreito no iPhone:** como Saúde, Fitness, Copilot ou Robinhood tratam 20 barras de 16 pt (toque no gráfico todo, arrasto, passos com setas).
2. **Anel com muitos tópicos:** como um app financeiro de ponta mostra 14 categorias ("Outros" em cinza, só os maiores, ou lista com barras no lugar do anel).
3. **Número mono grande na letra máxima:** como um app de números faz um valor de seis dígitos com centavos caber em 307 pt (encolher, quebrar em duas linhas ou trocar para texto).
4. **Entrada do anel:** só há a descrição do Donut Chart do 21st.dev (código fechado). Se houver gravação, vale conferir se o pedaço gira ou só cresce.
5. **Seleção múltipla em lista agrupada:** como Fotos, Arquivos, Copilot ou Monarch resolvem "marcar o grupo inteiro" e a barra de soma embaixo.
6. **Veredito financeiro sem cara de cripto:** como um app de investimentos mostra "rende menos que a referência" em tom de aviso, e não de erro.
7. **PDF de relatório de obra:** um exemplo real que contador ou banco aceite (as colunas e os totais que esperam).
8. **Teclado de valor em campo único:** o da etapa 3 tinha ‹ › para trocar de tópico; aqui há um campo só.

O conselho de 29/10 seguiu sem elas. As que mudariam o voto estão no fim de "Decisões do conselho".

## Riscos

- **Peças compartilhadas no app inteiro** (confirmação 5): o âmbar de texto do claro, o globo, o halo do título e a cápsula de abas mudam telas das etapas 1 a 3. Mitigado pela comparação palavra por palavra do laudo inteiro (seção "Testes e validação", item 6).
- **A obra reescrita** é a tela mais usada. Os testes de tela das etapas 2 e 3 sobre ela (lista, busca, arrastar, "A vencer", folhas, destaque da linha nova, rolagem) continuam verdes, e as cenas novas entram no laudo.
- **Gráficos desenhados pelo app** (conselho, item 1). A acessibilidade dos gráficos é feita à mão: o ajustável, o descritor, a lista do anel e os rótulos de eixo. As mitigações:
  - o valor falado, o passo e o descritor em conta pura, com teste;
  - a inspeção dentro do processo;
  - a auditoria e o laudo das marcas no iOS 26;
  - o VoiceOver de verdade no checklist de cada marco.
- **O PDF.** Os riscos são a descrição longa, a obra com milhares de gastos, a fonte mono no arquivo e o PDF que não pode depender do tema nem da letra. O protótipo mediu tudo isso no iOS 27 (conselho, item 2). Faltam o iPhone, o iOS 26, o Swift 6.3.3 da CI e a marcação, que dependem das sondas aprovadas por ele em 29/10.
- **O número que encolhe:** o laudo não vê corte; a prova é o teste de largura do plano.
- **Barra de soma, teclado e cápsula:** busca e Selecionar abertos juntos, na letra máxima, em 375 pt (13 mini).
- **Mudança de outro aparelho com o Selecionar aberto:** a seleção sobrevive e o gasto que some sai da soma; pede teste com escrita remota pelo emulador, como o achado 3 da etapa 3.
- **Tempo da CI.** No último run do `app-ios.yml` (#88, 27/10): `app` em 50 min e `app-etapa3` em 58 (teto de 90); os outros, de 26 a 42 min (teto de 60). As telas novas somam cenas ao laudo e às auditorias; o plano mede e abre jobs da etapa 4, como fez na etapa 3. A CI roda 5 jobs de macOS por vez, então cada job a mais soma espera; os portões por superfície (seção "PRs") cortam os jobs dos PRs que só trazem regra ou tela nova.
- **Confirmações:** as sete que este spec pedia foram aprovadas por ele em 29/10 (fim de "Decisões de desenho"). As outras recomendações que mexem em detalhe do quadro (o % do meio do anel, os centavos, o "<1%" na folha, o aviso dos 24 meses) seguem se ele não vetar.

## Fora do escopo

- **O resto do app na identidade nova:** lista de obras, folhas, Ajustes, entrar e as telas Orçamento e Afazeres. Decisão dele, para depois.
- **Etapa 5:** exportar (CSV e JSON), tópicos próprios, notificações e o resto de Ajustes.
- **PDF da seleção ou da busca** ("Exportar seleção") e os chips de período: só se ele pedir.
- **Lembrar a tela ao reabrir:** o site volta ao Relatório e aos Gráficos depois de recarregar (app.js:118-119). É um item transversal do spec do app nativo, ainda sem etapa marcada, e as duas telas entram nele quando ele for feito.
- **Fora da etapa:** mudança no site além do PR 0; mudança nas `firestore.rules`.
