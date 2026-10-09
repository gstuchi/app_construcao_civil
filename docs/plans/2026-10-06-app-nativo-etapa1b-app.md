# App base nativo (etapa 1B do app nativo) — plano de implementação

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> Neste time: o Forja implementa uma tarefa por vez, o Lupa revisa cada uma antes da próxima; nas tarefas de tela, o Verniz confere o simulador lado a lado com o mockup aprovado. Ninguém faz commit, push ou PR sem o Orquestrador pedir; quando pedir, valem os comandos de commit de cada tarefa.

**Replanejamento de 08/10/2026 — telas primeiro.** O PR 1 (#59, Tarefas 1 e 2) entrou na `main` em 08/10 (`3acb6d6`), e o Giovani viu o app mostrar só "Custta" num fundo branco depois de dois dias de trabalho. Decisão dele: o visual do mockup aprovado entra já, com dados de exemplo, e o Firebase e a sincronização são ligados depois. O próximo PR entrega no simulador as telas da etapa 1 com a cara do PWA (aurora e globo nativos, título escrito à mão, vidro por tela, cápsula de abas) rodando com os serviços falsos; o PR 3 liga o Firebase; o PR 4 faz a conferência cruzada e o TestFlight. As tarefas foram renumeradas na ordem nova:

| Antes | Agora | O que é |
| --- | --- | --- |
| 1, 2 | 1, 2 | projeto e CI (feitas, PR 1) |
| 10 | 3 | cores, vidro e ícones por tokens (refeita com o mockup) |
| — | 4, 5 | aurora e globo; título escrito à mão (novas) |
| 3, 4, 5 | 6, 7, 8 | regras do cadastro, regras das telas (mais o comparativo), Sincronizador (mesmo código) |
| 6, 7, 8 (partes sem Firebase) | 9 | relógio e rede, conta e dados falsos, modelo das telas |
| 11 | 10 | telas da etapa 1 (refeitas com o mockup) |
| 12 | 11 | acessibilidade verificada (refeita) |
| 9 | — | o portão de desenho foi o mockup aprovado em 06/10: virou a seção "Resultado do portão de desenho" |
| 6, 7, 8 (partes com Firebase) | 12, 13, 14 | camada do Firestore, conta no Firebase, composição de produção |
| 13, 14, 15 | 15, 16, 17 | conferência cruzada, envio ao TestFlight, documentação e build |

**Goal:** Primeiro build 2.0 do app nativo no TestFlight: o Giovani entra na conta (e-mail e senha, Apple ou Google), vê as obras com os totais iguais aos do site, vê chegar ao iPhone uma mudança feita no site e abre o app em modo avião com tudo lá. No caminho, o PR 2 já mostra no simulador todas as telas da etapa 1 com a cara do mockup aprovado, com dados de exemplo.

**Architecture:** Projeto Xcode `app-ios/Custta.xcodeproj` escrito à mão no formato do Xcode 16+ (pastas sincronizadas), com o app `Custta`, os testes de unidade `CusttaTests` (hospedados no app) e os de tela `CusttaUITests`. O app usa o pacote local `CusttaNucleo` (Parte A) e só dois pacotes de terceiros, travados: firebase-ios-sdk 12.19.2 e GoogleSignIn-iOS 8.0.0. Quatro camadas: o **núcleo** ganha as regras do cadastro, as regras das telas, a tradução dos erros do Firebase e o `Sincronizador` (porte da fila do `cloud.js` e do eco do `app.js`, puro, testado com transporte e relógio falsos); a **identidade** (`app-ios/Custta/Identidade/`) recria em SwiftUI a cara do PWA — tokens de cor e de vidro, aurora, globo, título escrito à mão, superfícies de vidro e a cápsula de abas —, escrita uma vez e reusada em todas as telas; as **telas** são SwiftUI sobre um `ModeloApp` observável, que é o `db` e o `auth.js` do site; a **camada de dados** é fina sobre o SDK (`TransporteFirebase`, `ContaFirebase`) e chega no PR 3. Em Debug o app aceita serviços falsos (telas e testes de tela, sem rede) e, a partir do PR 3, os emuladores do Firebase (integração e conferência cruzada com o site).

**Visual:** a cara do PWA de hoje, escrita em código nativo, como o Giovani aprovou no mockup `~/Documents/custta-mockups/nativo/etapa1/final.html` em 06/10 (spec, "Decisões > Visual"; dose de vidro por tela no commit `9a84ae7`). O que o mockup decide e o que ainda falta decidir estão na seção "Resultado do portão de desenho".

**Tech Stack:** Xcode 26.6 na CI (`macos-26`) e Xcode 27 no Mac do Giovani; Swift 6 com concorrência estrita; SwiftUI (iOS 26, com o Liquid Glass do sistema: `glassEffect`, `safeAreaBar`), Observation, Swift Testing, XCTest e XCUITest; FirebaseAuth e FirebaseFirestore 12.19.2; GoogleSignIn 8.0.0; AuthenticationServices, CryptoKit e Network do sistema; a fonte Roboto Medium (v3.016, OFL) só no botão do Google. No Node: firebase-tools (emuladores) e o SDK JavaScript `firebase` 12.18.0 que já está nas devDependencies, só no roteiro da conferência cruzada.

**Spec:** `docs/specs/2026-10-06-app-nativo-design.md` (Decisões; Desenho 1 a 8; Etapas, linha 1; Testes e validação 2, 4, 5, 6 e 7). Depende da Parte A (`docs/plans/2026-10-06-app-nativo-etapa1a-nucleo.md`) já na `main`. Inventário do site, com arquivo e linha: `docs/plans/2026-10-06-app-nativo-inventario.md` (seções 5 e 6). Mockup aprovado: `~/Documents/custta-mockups/nativo/etapa1/final.html`, com os prints em `prints-com-refracao/final-*.png`.

**Validação deste plano (08/10/2026, replanejamento):** o código das Tarefas 3 a 11 (PR 2) foi escrito e rodado num protótipo sobre a `origin/main` de 08/10 (`3acb6d6`), no Xcode 27 do Mac; o texto deste plano, aplicado numa cópia limpa da `origin/main` por um script que segue cada passo (arquivos inteiros, trechos no fim, instruções em prosa), reproduz o protótipo byte a byte (174 arquivos). No protótipo: núcleo com 123 testes em 22 suítes; `npm run test:unit` com 351; `tests/app-ios.test.cjs` com 17; `CusttaTests` com 32 testes em 7 suítes; `CusttaUITests` com 26 (19 de fluxo e 7 auditorias, a de contraste sobre o vidro como falha esperada); na prova de regressão, com o texto claro sobre a marca, a auditoria dos quatro combos reprova (2 achados); o build Release compila. PR 3 (Tarefas 12 a 14, o código Firebase validado no plano anterior, recomposto), na cópia limpa: build Release compila, `xcodebuild test` com os falsos verde (46 testes de unidade, com os de emulador pulados, e os 26 de tela) e `npm run test:app-ios:emuladores` verde (os mesmos 46, nenhum pulado). PR 4 (Tarefas 15 a 17), na cópia limpa: guardas (18), `node tests/workflow.test.cjs`, `tests/docs.test.mjs` e `npm run test:unit` (352) verdes, e `npm run test:app-ios:cruzado` verde (`ok - site e app na mesma conta: totais e orçamentos iguais, mudança do site chegou ao app, gasto lançado no app chegou ao site sem perder nada`). O envio ao TestFlight (Tarefa 17, Step 6) não foi rodado. O Mac só tem o Swift 6.4: nenhum recurso só do 6.4 ou do SDK do iOS 27 foi usado (alvo iOS 26), e o job `app` da CI, no Xcode 26.6, confere no primeiro push do PR 2.

## Global Constraints

- **Padrão profissional (regra do Giovani, 06/10):** "Quero tudo o mais profissional possível; se precisar de referência, me diga que a gente procura junto." Faltou referência para uma decisão de desenho, código, teste ou texto: ninguém improvisa; a falta vai ao Orquestrador, que procura com o Giovani.
- **A cara é a do mockup aprovado** (`final.html`, 06/10), comparada no simulador lado a lado com os prints `final-*.png` nos quatro combos (escuro e claro, esmeralda e azul) e na maior letra. O comportamento é o do sistema. Diferença que o código não consegue fazer igual ao mockup não se resolve à mão: vai para a lista do Giovani (seção "Resultado do portão de desenho").
- Projeto `app-ios/Custta.xcodeproj`, `objectVersion = 77`, pastas sincronizadas; bundle `br.com.custta.app`; `MARKETING_VERSION = 2.0`; `IPHONEOS_DEPLOYMENT_TARGET = 26.0`; `TARGETED_DEVICE_FAMILY = 1`; só retrato. Não abra e salve o projeto num Xcode que suba o formato: `tests/app-ios.test.cjs` barra.
- Pacotes de terceiros: só `firebase-ios-sdk` (produtos FirebaseAuth e FirebaseFirestore) e `GoogleSignIn-iOS` (produto GoogleSignIn), com `kind = exactVersion`, `Package.resolved` versionado e `-onlyUsePackageVersionsFromResolvedFile` em todo `xcodebuild` da CI. Sem Sentry. Nenhum pacote npm no app. A única dependência de fora que não é pacote é a fonte Roboto Medium do botão do Google, travada por versão e SHA-256, com a licença ao lado.
- Reaproveitar de `ios/App/App/`: `GoogleService-Info.plist` e `App.entitlements` (push e Sign in with Apple) copiados sem mudança, e o esquema de URL `REVERSED_CLIENT_ID` com `GIDClientID` no `Info.plist`.
- Nenhuma chave nova no blob; `firestore.rules` não muda; `perfis/{uid}` com os mesmos campos e limites (`email`, `criado`, `tz`, `nome`, `sobrenome`, `origem`, `origemDetalhe`).
- Nenhuma tela escreve em `dados/{uid}` nesta etapa; a escrita existe e é testada no `Sincronizador`, no transporte e na conferência cruzada.
- Requisitos da seção 8 do spec: legível e sem corte até o maior tamanho de letra de acessibilidade (`UICTContentSizeCategoryAccessibilityXXXL`), todo controle com rótulo para o VoiceOver, alvos de toque de 44 pt ou mais, cores só por tokens (Esmeralda e Azul, claro e escuro), escuro por padrão; aurora, globo e logo param com Reduzir movimento, no Modo de Pouca Energia, durante a rolagem e fora da tela; "Aumentar contraste" leva ao Fosco com contorno e "Reduzir transparência" a superfícies sólidas. Não crescem com a letra, por decisão do mockup: o logo, a aurora, o globo, a cápsula de abas e os botões da Apple e do Google (os dois últimos com o Visualizador de Conteúdo Grande).
- **Nunca vidro dentro de vidro:** o que fica dentro de uma superfície de vidro é sólido (campos, botões, etiquetas, barras); toda superfície usa `.superficie(_:em:)`, que aplica a dose da tela.
- O app nunca grava antes de ver os dados da conta (snapshot do servidor, ou do cache com o documento): `Sincronizador.salvar` recusa com `nao-carregado`. Vale para toda tela que gravar, desta etapa em diante.
- Os identificadores de acessibilidade das telas e o valor de acessibilidade da linha de obra ("Em construção · 14 meses, total gasto R$ …, 70% do orçamento" ou "X% · passou R$ …") são contrato com os testes, inclusive a conferência cruzada (`email`, `senha`, `entrar`, `obra-<id>`).
- Todo `xcodebuild` e `swift` da CI roda com o `DEVELOPER_DIR` do Xcode 26.6 (decisão "Xcode da CI" da Parte A). Nada só do Swift 6.4: o Mac compila com o 6.4 e a CI com o 6.3.3.
- Os workflows do Capacitor (`ios-build.yml`, `ios-testflight.yml`) não mudam.
- Mockups em `~/Documents/custta-mockups/`, nunca no repositório.
- Testes contra os emuladores: projeto `demo-custta-phase2`, portas 8080 (Firestore) e 9099 (Auth), como o `firebase.test.json`. Rodam com a assinatura de simulador do Xcode (sem `CODE_SIGNING_ALLOWED=NO`): sem ela o app não tem entitlements e o Firebase Auth falha no keychain (erro −34018).
- Identificadores, comentários, textos de tela e commits em português. Textos de tela iguais aos do site, salvo onde o mockup aprovado decidiu outra coisa (seção "Resultado do portão de desenho").
- Commits: um por mudança lógica, `tipo: descrição` em minúsculas com acento, corpo em prosa quando não é trivial, autor Giovani Stuchi, **sem linha de coautoria**. Branch + PR, nunca direto na `main`. Um worktree por entrega em `.claude/worktrees/<nome>`, criado da `origin/main`: cada linha da tabela "Como entregar" é uma tarefa do Orquestrador, com branch, worktree e PR próprios.
- Escapes de caractere nos trechos de código usam a forma `\u{a0}` (vale em JavaScript e Swift). Copie exatamente.


## Decisões

| Ponto | Decisão | Por quê |
| --- | --- | --- |
| Ordem dos PRs | **Telas primeiro** (decisão do Giovani, 08/10): PR 2 com a identidade, as regras do núcleo, o modelo e as telas sobre os serviços falsos; PR 3 com o Firebase; PR 4 com a conferência cruzada e o TestFlight. | Depois de dois dias, o app mostrava só "Custta" num fundo branco. Na ordem antiga, o visual só aparecia no PR 4. |
| Ordem dentro do PR 2 | A identidade vem antes: tokens (3), aurora e globo (4) e título escrito à mão (5). Depois o núcleo (6 a 8), o modelo (9), as telas (10) e a acessibilidade (11). | Depois da Tarefa 5 o app já abre com a aurora, o globo e o logo se escrevendo: o Orquestrador manda o print ao Giovani (ponto de controle) enquanto o núcleo, que é código já validado, entra. |
| Modelo antes do Firebase | O `Sincronizador` (núcleo puro) entra no PR 2, antes do `ModeloApp`; não há protocolo nem falso novo para ele. Só o que fala com o SDK (`BancoFirebase`, `TransporteFirebase`, `ContaFirebase`, a composição de produção) vai para o PR 3. | O `TransporteFalsoApp` já é o falso do `Sincronizador`, e as telas mostram os estados dele (salvando, sem conexão, não salvou, não sincronizou, erro de leitura, nunca grava antes de ver os dados). Um protocolo só para adiar o `Sincronizador` duplicaria essa máquina de estados e seria jogado fora. |
| Release no PR 2 | `Composicao.montar()` devolve o modelo com os serviços falsos em Debug e nil em Release até o PR 3; com nil o app mostra a abertura (aurora, globo e logo). | O Release não leva os falsos (só Debug) e ainda não tem serviço de verdade; o build Release continua compilando na CI. |
| Como o projeto Xcode nasce | `project.pbxproj` escrito à mão, formato do Xcode 16+ (`objectVersion = 77`) com pastas sincronizadas; sem XcodeGen nem Tuist. | Ferramenta geradora seria mais uma dependência fora da política de pacotes revisados. Com pastas sincronizadas, arquivo novo numa pasta entra no alvo sem tocar no `project.pbxproj`. A guarda de `objectVersion` impede que um Xcode mais novo suba o formato e quebre a CI (Xcode 26). |
| Par de versões dos SDKs | firebase-ios-sdk **12.19.2** e GoogleSignIn-iOS **8.0.0**, `exactVersion`. | É o par que já resolve no `Package.resolved` do app Capacitor (app-check 11.3.2, gtm-session-fetcher 3.5.0); o Firebase 13 não fecha com o GoogleSignIn 8 (`docs/sdks-fase4.md`). FirebaseMessaging entra na etapa 5, do mesmo pacote, sem mudar os pins. |
| Client do Google | O client **iOS** do `GoogleService-Info.plist` (`GIDClientID` no `Info.plist`), não o client web que o plugin do Capacitor usava. | É o caminho padrão do SDK nativo do Google com o Firebase iOS; o uid é o mesmo do site e do app de hoje. |
| Login com a Apple | `SignInWithAppleButton(.continue)` do SwiftUI com nonce (32 bytes aleatórios; a Apple recebe o SHA-256) e `OAuthProvider.appleCredential(withIDToken:rawNonce:fullName:)`. O nome do primeiro login vai para o `displayName`. | Botão e fluxo do sistema (o mockup pede o botão oficial, "Continuar com a Apple", em cápsula). Gravar o nome repete o `gravaNome` do `cloud.js`: o "Falta pouco" não pede o nome de novo (a revisão da Apple reprova). |
| Botão do Google | Botão próprio pelas regras do Google: cores fixas (claro `#FFFFFF`/`#747775`/`#1F1F1F`, escuro `#131314`/`#8E918F`/`#E3E3E3`), G oficial (`google-g.svg` do site) e Roboto Medium 14/20 embutida só nele (googlefonts/roboto-3-classic v3.016, OFL, SHA-256 conferido pela guarda). Texto "Continuar com o Google" até o Giovani confirmar o oficial. | Decisão do mockup. O `GIDSignInButton` do SDK traria outro produto do pacote e outro texto ("Fazer login com o Google"). |
| Estado e sincronização | `Sincronizador` no núcleo, `@MainActor @Observable`, com `TransporteDados` e `Relogio` injetados; `TransporteFirebase` só converte tipos e códigos. Retornos do Firestore na fila principal (`dispatchQueue = .main`). | A regra da fila, do backoff, da guarda de tamanho, do eco e de só gravar depois de ver os dados fica testável sem simulador (29 testes com falsos). |
| Sair da conta | Na ordem do `cloud.js`: espera a fila (5 s no máximo; sem rede pede para conectar e não sai), confere que a conta é a mesma, para a escuta, grava a marca de limpeza, faz `signOut` e `GIDSignIn.signOut()`, encerra o Firestore e apaga o cache e só então tira a marca. Confirmação pelo **alerta do sistema** ("Sair da conta?", Cancelar e Sair), no sair do topo de Obras e de Ajustes e no botão de Ajustes; sem rede, um segundo alerta explica. | Igual ao `logout` do `cloud.js` (`cloud.js:263-292` e `572-592`). O alerta foi decidido pelo Giovani no mockup (o diálogo de vidro do site ficou descartado). |
| Nome do Google ou da Apple no limite (`nomeDoGoogle`) | Corta em unidades UTF-16 como o site, mas sem partir um emoji ao meio (`prefixoUTF16`). | A `String` do Swift não representa meia letra; a diferença é de um caractere num caso raríssimo. |
| Abas | Só **Obras** e **Ajustes** nesta etapa, numa **cápsula de abas própria** (vidro da navegação, lente que desliza, VoiceOver com "1 de 2" e "selecionada", 44 pt, Visualizador de Conteúdo Grande); sem o +. Só a aba escolhida fica montada. | Decisão do mockup. O `TabView` do sistema pinta um fundo opaco por trás das abas no iOS 26 (a aurora sumia; visto no simulador) e uma aba só escondida continuava na árvore do VoiceOver pela barra de navegação. O que tiver de sobreviver à troca de aba (o caminho dentro de Obras, na etapa 2) mora no `PrincipalView`. |
| Lista sem obras | "Nenhuma obra ainda." e "Nesta versão de teste, crie as obras pelo site. Elas aparecem aqui sozinhas." | Texto provisório confirmado pelo Giovani no mockup (o do site manda tocar no "+", que não existe na etapa 1). |
| Lista de obras | Cartão de vidro por obra (ícone da fase, nome, etiqueta da fase, meses, barra e texto do orçamento, total gasto), "N obras" em pílula de vidro e o **"Comparativo entre obras"** (gasto × corrigido pela taxa, com duas ou mais obras com gasto, como o `drawComp` do `app.js`). | O mockup aprovado traz o comparativo na etapa 1. A regra mora no núcleo (`comparativoEntreObras`, Tarefa 7). |
| Esqueci a senha | Dentro do cartão de entrar, com o e-mail digitado nele, como no site: sem e-mail válido, "Digite seu e-mail no campo acima primeiro."; e-mail sem conta mostra "E-mail ou senha incorretos." | O mockup aprovado mostra o fluxo do site; a folha do esqueleto antigo (com `emailRedefinir`, `enviarLink` e `mensagemRedefinir`) saiu. Não revelar se o e-mail existe é decisão de produto e do console do Firebase, não desta etapa. |
| Cores | 47 tokens × 2 peles × claro/escuro, gerados por `scripts/cores-app-ios.mjs` a partir do `styles.css` e do mockup aprovado (texto sobre o vidro por nível, contorno do "Aumentar contraste", tintas do vidro, aurora, globo, botão do Google). | Tokens com nome estável no código; mudança de cor é na tabela do script, nunca no catálogo nem na tela. A guarda confere que a aurora tem as cores do `styles.css`. |
| Vidro | `VidroTokens.para(tela:escolha:opcoes:)`: entrada sempre Fosco (`Glass.regular`); app Transparente (`Glass.clear`, padrão) ou Fosco (escolha de Ajustes › Aparência, etapa 5, chave `custta.vidro`); "Aumentar contraste" → Fosco com contorno de 1,5 pt; "Reduzir transparência" → superfícies sólidas. Tintas do mockup por papel (cartão de entrada, segmentado, conteúdo, navegação). | Dose escolhida pelo Giovani em 06/10. Aro, sombra e refração vêm do `glassEffect` do sistema. |
| Aurora | Camada desenhada uma vez (`Canvas`, a um terço do tamanho e ampliada) com os quatro brilhos e o degradê do `#aurora` do site, que só se move na deriva de 26 s (ida e volta) a 30 quadros por segundo; intensidade por tela (a de hoje na entrada, a funda no app, a do site no claro) e transição de 0,9 s ao entrar e 0,6 s ao sair. | Fiel ao CSS do site e barata: o quadro custa uma transformação, não um redesenho. O mockup sugeria `MeshGradient`; o `Canvas` reproduz as elipses e o degradê do site sem aproximar. |
| Globo | `Canvas` a 30 quadros por segundo com os mesmos continentes e a mesma grade do `globe.js` (2,2°), pontos agrupados em dez faixas de profundidade (um desenho por faixa, não por ponto). | Mesmo desenho do site; a guarda confere que os continentes são os do `globe.js`. |
| Título escrito à mão | Os caminhos do `.logo-escrito` do `index.html` (guarda compara), lidos por um leitor de SVG próprio, com os tempos do `styles.css` e a vibração leve do carimbo do ponto (como o app de hoje); pronto com Reduzir movimento ou Pouca Energia. | Uma fonte só para o logo: o site muda, a guarda avisa. |
| Cartão de entrada | **Reto** (sem a inclinação 3D do site); ao rolar, o título sobe 80 pt e esmaece e a dica some, como no `auth.js`. | O vidro do iOS não acompanha a inclinação: no simulador do iOS 27, com `rotation3DEffect` a lâmina de vidro ignora a escala de 85% e fica maior que o conteúdo, e com uma projeção própria ela nem inclina. **Pendente do Giovani** (seção "Resultado do portão de desenho"). |
| Ícones | Os traços do `icons.js` do site viram image sets vetoriais em molde (`scripts/icones-app-ios.mjs`, só os usados); os ícones de mensagem (✓, !, cadeado) são SF Symbols. | Decisão do mockup ("os ícones do PWA viram símbolos próprios"). |
| Serviços falsos | `ContaFalsa`, `TransporteFalsoApp` e `DadosDeExemplo` dentro do app, só em Debug, ligados por `CUSTTA_SERVICOS=falsos` (e, no PR 2, também sem variável nenhuma). Dados: `vitrine` (padrão, as três obras do mockup com as datas contadas de hoje, para comparar lado a lado), `exemplo` (os dos testes) e `vazio`. | Os testes de tela abrem o app de verdade; o falso precisa estar no binário. O Release (TestFlight) não leva nada disso. |
| Opções do iPhone nos testes | Em Debug, `-custta.reduzirMovimento`, `-custta.reduzirTransparencia`, `-custta.aumentarContraste` e `-custta.quadroDaAurora` ligam as opções e congelam a aurora num quadro. | O XCUITest não muda os ajustes de acessibilidade do sistema. |
| Build number do TestFlight | `run_number.run_attempt` do workflow novo, na versão 2.0. | A Apple exige número único dentro da mesma versão; 2.0 é uma versão nova no mesmo cadastro. |
| Lista de obras só leitura | Entra na etapa 1 por decisão do Orquestrador; no spec ela abre a etapa 2. | É o que torna a sincronização testável no aparelho. |
| Gravar só depois de ver os dados | `Sincronizador.salvar` recusa (`nao-carregado`) até chegar um snapshot do servidor ou um do cache com o documento; cache sem documento não conta. | Sem a guarda, quem entrasse sem rede e criasse uma obra (etapa 2) regravaria o documento inteiro por cima das obras que só o servidor tem. O site tem a mesma guarda desde o #52. |
| Guarda de gravação: pendências obrigatórias da etapa 2 | Antes da primeira tela que grava: (1) uma marca por conta "o servidor já respondeu", apagada junto com o cache, entrando na condição da guarda; (2) uma mensagem própria para `nao-carregado` na tela que grava. | Hoje a guarda é conservadora, como a do site desde o #52. |
| Documento com tipo que o JSON não tem | A leitura falha com `formato-desconhecido` e o app para de gravar; a lista diz que os dados não puderam ser lidos e que nada foi alterado, com "Tentar de novo". | Quem não leu o documento inteiro não grava. |
| `Package.resolved` | Semeado do `Package.resolved` do app de hoje (`ios/`), sem os dois pins do Capacitor. | As dependências transitivas ficam nas versões que já estão em produção. |
| Manifesto de privacidade | `PrivacyInfo.xcprivacy` mínimo já na etapa 1 (feito no PR 1). | Sem o manifesto a Apple manda o aviso ITMS-91053 a cada envio. |
| Reduzir movimento e aumentar contraste | Aurora, globo e logo param (logo pronto) e o título não se move ao rolar; "Aumentar contraste" vale **já na etapa 1** (Fosco com contorno de 1,5 pt, decidido no mockup), e não na etapa 6 como o esqueleto recomendava. | Requisitos da seção 8 e decisão do mockup. |

**Decisões grandes deste replanejamento fora do conselho.** A regra do conselho nas decisões grandes (três subagentes com lentes diferentes, crítica às cegas) chegou ao Planejador no meio deste replanejamento, com o código já validado; estas decisões foram tomadas sem ele, e o Giovani decide se alguma passa pelo conselho antes da Tarefa 3:

| Decisão | Alternativa descartada | Por quê |
| --- | --- | --- |
| Ordem: identidade (3 a 5) antes do núcleo (6 a 8), modelo e telas no PR 2, Firebase no PR 3 | Núcleo primeiro, ou Firebase antes das telas (plano anterior) | O Giovani vê a cara do app no primeiro ou segundo dia; nada das telas depende do Firebase. |
| Aurora desenhada uma vez e só movida; globo em dez faixas; 30 quadros; tudo para na rolagem, com Pouca Energia e com Reduzir movimento | `MeshGradient` ou shader redesenhando a cada quadro, a 60 quadros | Menor custo de bateria com o mesmo desenho do site; a medida de verdade é a do aparelho (checklist). |
| Contraste auditado com superfícies sólidas; sobre o vidro, falha esperada e medida no aparelho | Auditar sobre o vidro, ou engrossar as tintas do vidro até a auditoria passar | A auditoria do Xcode não lê vidro (reprova até texto escuro sobre sólido); engrossar a tinta foge do mockup aprovado. |
| Cartão de entrada reto | Inclinação 3D do site | O vidro do iOS não acompanha a inclinação (pendência 3 do portão). |
| Cápsula de abas própria, só a aba escolhida montada | `TabView` do sistema | O `TabView` pinta fundo opaco atrás das abas no iOS 26 e esconde a aurora. |


## O que roda na CI e o que roda só no Mac

| Testes | Onde | Por quê |
| --- | --- | --- |
| Núcleo (`swift test`, 123 testes) | CI, job `nucleo`, e `npm run test:nucleo` | Rápido, sem simulador, pega divergência com o site a cada PR que mexe nas regras. |
| Unidade do app com falsos e sem rede (`CoresTests`, `VidroTokensTests`, `MovimentoTests`, `FundoTests`, `LogoTests`, `ModeloAppTests`, `FumacaTests`; no PR 3, `ConversaoDoDocumentoTests`, `BancoFirebaseTests`, `ErrosDoSDKTests`) | CI, job `app` | Sem rede e sem keychain; roda com `CODE_SIGNING_ALLOWED=NO`. |
| Tela com falsos e auditorias de acessibilidade (`CusttaUITests`) | CI, job `app` | Determinístico (sem rede) e é onde os requisitos da seção 8 viram teste. |
| Guardas em Node (`tests/app-ios.test.cjs`: tokens, ícones, logo e globo iguais aos do site, fonte travada, Reduzir movimento) | CI, `npm run test:unit` | Sem Xcode. |
| Integração contra os emuladores (`TransporteFirebaseTests`, `ContaFirebaseTests`) | Mac: `npm run test:app-ios:emuladores` | Precisa de Java, dos emuladores e da assinatura de simulador (keychain do Auth). |
| Conferência cruzada site ↔ app (`tests/app-ios/cruzado.mjs`) | Mac: `npm run test:app-ios:cruzado` | Mesmo motivo, mais o auxiliar HTTP que o teste de tela chama para "mudar no site". Portão obrigatório antes de cada build do TestFlight (Tarefa 17). |
| Conferência visual com o mockup | Mac, simulador (Verniz, nas Tarefas 4, 5 e 10) | Lado a lado com os prints `final-*.png`, nos quatro combos e na maior letra. |

## Resultado do portão de desenho

A antiga Tarefa 9 (portão de desenho) aconteceu: o Giovani aprovou o mockup `~/Documents/custta-mockups/nativo/etapa1/final.html` em 06/10/2026 (prints em `prints-com-refracao/final-*.png`; spec atualizado no commit `9a84ae7`). O que ele decide, nos oito pontos que o portão pedia:

1. **Mockups aprovados:** `final.html`, telas 1 a 11 (entrar, título sobre a aurora, estados, criar conta, falta pouco, transição, aviso de e-mail, obras, sincronização, Ajustes, letra máxima), mais as notas "Não fica igual", "Tokens", "Contraste" e "Referências".
2. **Fidelidade ao PWA:** as telas têm a cara do site (título escrito à mão com a dica "Role para entrar", segmentado "Entrar | Criar conta", cartão de vidro com Apple, Google, "ou", campos sólidos e links sublinhados; lista em cartões de vidro com ícone da fase, etiqueta, meses, orçamento e total; "N obras"; comparativo; aviso de e-mail; sincronização e sair na barra; cápsula de abas). Mudam, com motivo: o botão oficial da Apple; o do Google pelas regras do Google; o halo atrás do título no escuro (o título branco sobre a aurora clara ficava em 2,6:1); sucesso e sessão expirada sem vermelho (✓ na cor do link, cadeado neutro); o "Não salvou" com rótulo na cor do texto e só o ponto vermelho; Ajustes só com a Conta e a versão.
3. **Dose de vidro:** entrada sempre Fosco (vidro regular; cartão com tinta de 44%, claro 52%; segmentado 24%, claro 34%) com a aurora de hoje (92% esmeralda, 100% azul) e halo de 45% atrás do título, do logo e da dica, só no escuro; app Transparente (vidro claro; cartões e painéis 6%, claro 14%; abas e barra 8%, claro 16%) com a aurora funda no escuro (48% e 52%); no claro a aurora do site (55% e 52%) nas duas; Fosco como opção em Ajustes › Aparência (etapa 5: 24%/34% e 22%/36%). A aurora assenta em 0,9 s ao entrar e clareia em 0,6 s ao sair.
4. **Onde o nativo não pode ou não deve ficar igual ao PWA:** os 20 itens do mockup (botões da Apple e do Google, áreas seguras, cápsula própria, teclado e app Senhas, menu do sistema na origem, mensagens sem vermelho, alerta do sistema para sair, pílula de sincronização de 44 pt, letra grande até o AX5, aurora e vidro por tela, transição da aurora, cores de texto por nível, botão principal sólido, pausa do movimento, opções de acessibilidade, nunca vidro dentro de vidro, ícones em catálogo, sair no topo de Obras).
5. **Tokens aprovados:** a tabela de vidro por tela e as cores de texto sobre o vidro (secundário, link e erro nos quatro combos), em `scripts/cores-app-ios.mjs` e `VidroTokens` (Tarefa 3).
6. **Textos e ícones:** lista vazia "Nenhuma obra ainda." / "Nesta versão de teste, crie as obras pelo site. Elas aparecem aqui sozinhas."; "Você entrou com a Apple." e "Você entrou com o Google" com o e-mail; "Versão 2.0 (1)"; "Continuar com a Apple" e "Continuar com o Google"; sair com "Sair da conta?", Cancelar e Sair; o logo "tt." azul na pele azul como no PWA; ícones das fases do site (guindaste, casa, check).
7. **Cápsula de abas na etapa 1:** duas abas (Obras e Ajustes), nenhum +.
8. **Alto contraste:** entra já ("Aumentar contraste" → Fosco com contorno de 1,5 pt; "Reduzir transparência" → superfícies sólidas, com a aurora continuando), e não na etapa 6.

### O que ainda falta decidir com o Giovani

O Orquestrador leva esta lista; até a resposta, o PR 2 segue a recomendação de cada item, que é trocável sem mexer na estrutura.

1. **Texto oficial do botão do Google em português** (pendência do próprio mockup). Hoje: "Continuar com o Google". Se o Google pedir outro, troca uma constante em `BotaoGoogle`.
2. **Print do app Tempo do iPhone, no claro e no escuro** (pendência do próprio mockup), para calibrar o vidro claro no aparelho. Até lá valem as tintas do mockup; a calibração entra no checklist do aparelho (Tarefa 17).
3. **Cartão de entrada inclinado do site.** O vidro do iOS não acompanha a inclinação 3D (no simulador do iOS 27, a lâmina de vidro fica maior que o conteúdo inclinado). Recomendação: cartão reto, com o título subindo e esmaecendo ao rolar, como no site (é o que o PR 2 faz). Alternativa, pior: inclinar com o cartão sólido, sem vidro, até ele endireitar.
4. **Seta ">" nas linhas de obra na etapa 1.** O mockup mostra a seta, mas na etapa 1 a obra não abre (a tela da obra chega na etapa 2), e a seta promete navegação. Recomendação: tirar a seta até a etapa 2. O PR 2 segue o mockup (com a seta) até a resposta.

Ajustes que o código fez sobre o mockup, para o Giovani saber (não pedem decisão):

- **Segmento escolhido sólido** ("Entrar | Criar conta"): no mockup a pílula escolhida tem 90% da tinta; a 90%, o branco sobre ela fica em 4,4:1 no claro (a auditoria do Xcode reprovou). Com 100% fecha 5,3:1.
- **Contraste sobre o vidro:** a auditoria do Xcode não lê fundo de vidro (no simulador ela reprova até texto escuro sobre a pílula sólida do segmentado, e os mesmos textos com tinta de 6% ou de 50%). As cores passam com superfícies sólidas nos quatro combos; sobre o vidro, a medida que vale é a do aparelho, junto com a calibração do item 2.

## Referências que faltam

As seis do plano anterior, com o que o mockup resolveu:

1. **Liquid Glass nativo para calibrar a dose:** decidido no mockup (dose por tela). Falta só a calibração fina do vidro claro no aparelho, com o print do app Tempo (item 2 acima).
2. **Fundo animado que não pesa:** decidido no código (aurora desenhada uma vez e só movida, a 30 quadros por segundo; globo em faixas de profundidade a 30 quadros; tudo para na rolagem, em segundo plano, com Pouca Energia e com Reduzir movimento). A medida no iPhone fica no checklist do aparelho (Tarefa 17): rolar liso e dez minutos sem esquentar.
3. **Identidade no maior tamanho de letra:** decidido no mockup (tela 11: tudo empilha e rola; logo, aurora, globo, cápsula e botões sociais não crescem).
4. **Legibilidade sobre vidro e aurora:** decidido no mockup (halo de 45%, cores de texto por nível, medidas no pior ponto); no código, a auditoria de contraste do Xcode roda com a aurora congelada nos extremos da deriva (Tarefa 11).
5. **Comportamento do sistema que o PWA imita:** decidido no mockup (os 20 itens).
6. **Título escrito à mão:** decidido: os mesmos traços e tempos do site; com Reduzir movimento aparece pronto.


## Review Focus

1. **Primeiro uso sem internet** (app recém-instalado ou cache vazio, em modo avião): esperado é a tela de entrar ou a lista esperando a conexão ("Sem conexão"), e nunca gravar: nem um documento vazio, nem uma edição por cima das obras do servidor. Testes: `salvarSoDepoisDeVerOsDados` nos três cenários (Tarefa 8) e `abrirOAppNaoGravaNada` nos mesmos três (Tarefa 9).
2. **Falta de rede ao conferir a sessão:** nunca desloga. Teste: `sessaoQueEncerraAConta` (Tarefa 7) e `ContaFirebase.verificarSessao`, que só sai por código de sessão inválida (Tarefa 13).
3. **Conta Google ou Apple cujo perfil outro aparelho gravou no meio do "Falta pouco":** as rules recusam o segundo perfil e o app tem de seguir para a lista. Teste: `perfilGravadoPorOutroAparelhoSegueParaOApp` (Tarefa 9).
4. **Mudança do site chegando enquanto há gravação local pendente:** o eco não pode desfazer a edição local. Teste: `ecoComGravacaoLocalPendenteEIgnorado` (Tarefa 8) e a conferência cruzada (Tarefa 15).
5. **Maior tamanho de letra com nome de obra longo e valor alto** ("Residencial Jardim das Acácias, Bloco B, Casa 12", R$ 123,5 mi), sobre o vidro: nada corta e a cápsula de abas não cresce. Teste: `testObrasNoMaiorTamanho` (Tarefa 11), que audita a lista com a obra o4 dos dados de exemplo antes e depois de rolar.

## Riscos

**Identidade (PR 2).** É o maior custo novo e o maior risco técnico da etapa 1:

- **Vidro do iOS e animação 3D:** o `glassEffect` não acompanha escala nem projeção (motivo do cartão reto, pendência 3). Qualquer efeito novo sobre uma superfície de vidro precisa ser visto no simulador antes de entrar no plano.
- **Desempenho da aurora e do globo na rolagem e bateria:** a aurora é uma camada pronta que só se move e o globo redesenha a 30 quadros por segundo em dez faixas; os dois param durante a rolagem e no Modo de Pouca Energia. Só o aparelho mede de verdade (checklist da Tarefa 17: rolar liso no iPhone do Giovani e, antes da loja, no iPhone 16 Pro do pai; dez minutos sem esquentar).
- **Contraste sobre o vidro e a aurora:** a auditoria do Xcode mede o quadro do instante; a Tarefa 11 congela a aurora no quadro inicial e nos dois extremos da deriva. O vidro do iOS se adapta ao que está atrás, então as medidas do mockup precisam ser refeitas no aparelho (checklist).
- **Vidro claro (Transparente) sobre conteúdo:** a cápsula de abas e a barra mostram o que passa por baixo; a `safeAreaBar` dá o efeito de borda do sistema. A calibração final depende do print do app Tempo (pendência 2).
- **Letra grande:** a cápsula de abas, o logo e os botões sociais não crescem (decisão do mockup); a auditoria de tipo dinâmico os deixa de fora pelo identificador, e o Visualizador de Conteúdo Grande cobre a leitura.

**O que a etapa 1 tem de provar no aparelho** (checklist da Tarefa 17): rolar a lista com aurora e globo sem engasgar; dez minutos de uso sem esquentar; com Reduzir movimento, aurora e globo parados e o logo pronto; com Reduzir transparência, superfícies sólidas e legíveis; com Aumentar contraste, Fosco com contorno; no maior tamanho de letra, nada cortado sobre o vidro; o vidro claro calibrado com o print do Tempo.

**Outros riscos abertos:** o primeiro envio assinado ao TestFlight depende dos secrets e do perfil "Custta App Store" de hoje (mesmo App ID); o login de verdade com Apple e Google só se prova no aparelho; a resposta do Giovani às pendências 3 e 4 pode pedir uma rodada curta na Tarefa 10; o PR 2 é grande (nove tarefas): o ponto de controle depois da Tarefa 5 e o PR em rascunho desde o primeiro commit (CI com o Xcode 26.6 a cada push) servem para o erro aparecer cedo.

## Como entregar

| PR | Branch e worktree | Tarefas | Estimativa (dias de trabalho do time) |
| --- | --- | --- | --- |
| 1 | `feat/app-nativo-projeto` | 1 e 2 | feito (#59, `3acb6d6`, 08/10) |
| 2 | `feat/app-nativo-telas` em `.claude/worktrees/app-nativo-telas` | 3 a 11 | 4 a 6 (ponto de controle visual ao fim da Tarefa 5, no 1º ou 2º dia) |
| 3 | `feat/app-nativo-firebase` em `.claude/worktrees/app-nativo-firebase` | 12, 13 e 14 | 2 a 3 |
| 4 | `feat/app-nativo-testflight` em `.claude/worktrees/app-nativo-testflight` | 15, 16 e 17 | 1,5 a 2 |

A estimativa conta implementação, revisão do Lupa (e a conferência visual do Verniz nas Tarefas 4, 5 e 10), correções e a primeira passada na CI, com o código já escrito e validado neste plano. As Tarefas 6, 7 e 8 são o código do núcleo já validado no plano anterior (a 7 ganhou o comparativo). Fica fora da conta do time o tempo do Giovani: responder às pendências do portão, aprovar os PRs, rodar o checklist do iPhone (cerca de 1 hora) e o vaivém das correções que ele pedir.

```bash
# na raiz do repositório principal; de dentro de um worktree, a linha abaixo sobe até ela
cd "$(git rev-parse --path-format=absolute --git-common-dir)/.."
git fetch origin
git worktree add .claude/worktrees/app-nativo-telas -b feat/app-nativo-telas origin/main
cd .claude/worktrees/app-nativo-telas && npm ci
```

Ordem: cada PR começa depois que o anterior entrou na `main` (o worktree nasce da `origin/main` atualizada).

**Ponto de controle do PR 2:** ao fim da Tarefa 5, o app abre com a aurora, o globo e o título se escrevendo. O Orquestrador manda ao Giovani o print (e, se quiser, o vídeo: `xcrun simctl io <id> recordVideo`) antes de seguir, e de novo ao fim da Tarefa 10, com as telas lado a lado com o mockup.

**Na entrega de cada PR:** descrição em prosa (contexto, o que muda, decisão técnica), o link da prévia da Vercel conferido e o "como testar". Nenhum PR desta parte muda o que vai para a Vercel (`app-ios/` está no `.vercelignore`): a prévia confirma que o site continua igual, e o "como testar" diz qual comando prova o que mudou (`npm run test:nucleo`, o `xcodebuild test` do simulador, `npm run test:app-ios:emuladores` ou `npm run test:app-ios:cruzado`) e, no PR 2, como abrir o app no simulador com os falsos (`node scripts/simulador-ios.mjs`, `xcodebuild build`, `xcrun simctl install` e `launch`; sem variável, a conta começa deslogada e qualquer e-mail entra com a senha `Casa2026x`; `SIMCTL_CHILD_CUSTTA_CONTA=senha` abre direto nas obras). Do PR 3 em diante, o Debug sem variável fala com o Firebase de produção; os falsos pedem `SIMCTL_CHILD_CUSTTA_SERVICOS=falsos`.

**PR aberto cedo:** o Orquestrador abre cada PR desta parte como rascunho logo depois do primeiro commit, para a CI do app rodar com o Xcode da CI desde a primeira tarefa.

Todos os comandos rodam na raiz do worktree. `DESTINO` nos comandos de teste é a saída de `node scripts/simulador-ios.mjs` (Tarefa 2).

## Mapa de arquivos

| Arquivo | Responsabilidade |
| --- | --- |
| `app-ios/Custta.xcodeproj/` (project.pbxproj, workspace, Package.resolved, scheme) | projeto, alvos, pacotes travados |
| `app-ios/Custta/CusttaApp.swift` | entrada do app: a raiz com o modelo, ou a abertura sem ele |
| `app-ios/Custta/Composicao.swift` | monta os serviços: falsos (Debug, PR 2); produção e emuladores (PR 3) |
| `app-ios/Custta/Identidade/Paleta.swift`, `Vidro.swift` | tokens de cor, aparência, dose de vidro por tela, opções do iPhone, `.superficie(_:em:)` |
| `app-ios/Custta/Identidade/Movimento.swift`, `Aurora.swift`, `Globo.swift` | tempo pausável, curvas do CSS, rolagem; aurora, halo e globo |
| `app-ios/Custta/Identidade/CaminhoSVG.swift`, `LogoEscrito.swift` | leitor de caminho SVG; título escrito à mão |
| `app-ios/Custta/Identidade/Componentes.swift`, `CapsulaDeAbas.swift` | campo, botões (principal, secundário, Apple, Google), mensagem, link, etiqueta, barra; cápsula de abas |
| `app-ios/Custta/Fontes/Roboto-Medium.ttf`, `OFL-Roboto.txt` | fonte do botão do Google e a licença |
| `app-ios/Custta/Conta/ServicoConta.swift` | protocolo da conta, `Usuario`, `CredencialApple`, `ErroConta` |
| `app-ios/Custta/Dados/Sistema.swift` | relógio, rede e janela do sistema |
| `app-ios/Custta/Dados/BancoFirebase.swift`, `TransporteFirebase.swift`, `ContaFirebase.swift` | Firestore, transporte do estado, conta no Firebase Auth (PR 3) |
| `app-ios/Custta/Estado/ModeloApp.swift` | fase da tela, conta, sincronização e avisos |
| `app-ios/Custta/Falsos/*.swift` | conta, transporte e dados falsos (só Debug) |
| `app-ios/Custta/Telas/*.swift` | raiz, entrada (entrar, criar conta, falta pouco), principal (abas e barra), obras, Ajustes |
| `app-ios/Custta/Assets.xcassets` (`Esmeralda/`, `Azul/`, `Icones/`, `LogoGoogle`), `Info.plist`, `Custta.entitlements`, `GoogleService-Info.plist`, `PrivacyInfo.xcprivacy` | catálogo gerado, configuração |
| `app-ios/CusttaNucleo/Sources/CusttaNucleo/Cadastro.swift`, `Telas.swift`, `ErrosFirebase.swift`, `Sincronizador.swift` | regras do cadastro, das telas (com o comparativo), códigos de erro e sincronização |
| `app-ios/CusttaTests/*.swift`, `app-ios/CusttaUITests/*.swift` | testes de unidade, de integração (emuladores) e de tela |
| `app-ios/ExportOptions.plist` | opções do envio ao TestFlight |
| `scripts/simulador-ios.mjs`, `scripts/cores-app-ios.mjs`, `scripts/icones-app-ios.mjs`, `tests/app-ios/cruzado.mjs` | simulador para os testes, catálogo de cores, ícones, conferência cruzada |
| `tests/app-ios.test.cjs`, `tests/workflow.test.cjs`, `tests/vetores.test.mjs` | guardas em Node |
| `.github/workflows/app-ios.yml`, `.github/workflows/app-ios-testflight.yml` | CI e envio ao TestFlight |
| `scripts/vetores-calc.mjs`, `tests/vetores/calc.json` | vetores do `cadastro.js` (Tarefa 6) |
| `CLAUDE.md`, `docs/plans/2026-10-06-app-nativo-etapa1-checklist-aparelho.md` | instrução do app nativo para os agentes e checklist do aparelho |

---

### Task 1: Projeto Xcode e pacotes travados

**Files:**
- Create: `app-ios/Custta.xcodeproj/project.pbxproj`
- Create: `app-ios/Custta.xcodeproj/project.xcworkspace/contents.xcworkspacedata`
- Create (semeado do `Package.resolved` do app de hoje e versionado): `app-ios/Custta.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`
- Create: `app-ios/Custta.xcodeproj/xcshareddata/xcschemes/Custta.xcscheme`
- Create: `app-ios/Custta/CusttaApp.swift`, `app-ios/Custta/Info.plist`, `app-ios/Custta/PrivacyInfo.xcprivacy`
- Create (cópias): `app-ios/Custta/Custta.entitlements` (de `ios/App/App/App.entitlements`), `app-ios/Custta/GoogleService-Info.plist` (de `ios/App/App/GoogleService-Info.plist`), `app-ios/Custta/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png` (de `ios/App/App/Assets.xcassets/AppIcon.appiconset/AppIcon-512@2x.png`)
- Create: `app-ios/Custta/Assets.xcassets/Contents.json`, `AppIcon.appiconset/Contents.json`, `AccentColor.colorset/Contents.json`, `FundoAbertura.colorset/Contents.json`
- Create: `app-ios/CusttaTests/FumacaTests.swift`, `app-ios/CusttaUITests/AberturaUITests.swift`
- Create: `tests/app-ios.test.cjs`
- Modify: `package.json` (`tests/app-ios.test.cjs` no `test:unit`)

**Interfaces:**
- Consumes: pacote `app-ios/CusttaNucleo` (Parte A).
- Produces: alvos `Custta`, `CusttaTests` (unidade, `TEST_HOST` = app) e `CusttaUITests`; scheme compartilhado `Custta`; produtos `FirebaseAuth`, `FirebaseFirestore`, `GoogleSignIn` e `CusttaNucleo` ligados ao app. Os ids do `project.pbxproj` usam o prefixo `C05A`. As tarefas seguintes só criam arquivos dentro das pastas sincronizadas.

- [ ] **Step 1: Escrever as guardas que falham**

`tests/app-ios.test.cjs` (as Tarefas 3, 4, 5, 10, 12 e 15 acrescentam testes no fim deste arquivo):

```js
'use strict';
/* Guardas do app nativo (app-ios/) que o Xcode não confere sozinho: formato do projeto, bundle,
   versão e plataforma, assinatura, pacotes travados, o que vem do app de hoje (ios/App/App),
   cores por token e os scripts dos testes locais. Sem rede e sem Xcode: roda no test:unit. */
const { test } = require('node:test');
const assert = require('node:assert/strict');
const { readFileSync, readdirSync, statSync } = require('node:fs');
const { join } = require('node:path');
const { execFileSync } = require('node:child_process');

const RAIZ = join(__dirname, '..');
const ler = p => readFileSync(join(RAIZ, p), 'utf8');
const PBX = 'app-ios/Custta.xcodeproj/project.pbxproj';
const RESOLVED = 'app-ios/Custta.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved';

/* Blocos de build settings do alvo Custta (os que apontam para Custta/Info.plist), por nome. */
function configsDoApp(){
  const blocos = [...ler(PBX).matchAll(/isa = XCBuildConfiguration;\s*buildSettings = \{([\s\S]*?)\};\s*name = (\w+);/g)];
  return Object.fromEntries(blocos.filter(m => m[1].includes('INFOPLIST_FILE = Custta/Info.plist;')).map(m => [m[2], m[1]]));
}

function arquivosSwift(pasta){
  const r = [];
  for(const nome of readdirSync(join(RAIZ, pasta))){
    const rel = join(pasta, nome);
    if(statSync(join(RAIZ, rel)).isDirectory()) r.push(...arquivosSwift(rel));
    else if(nome.endsWith('.swift')) r.push(rel);
  }
  return r;
}

test('projeto no formato do Xcode 16+ (pastas sincronizadas), que o Xcode 26 da CI abre', () => {
  const pbx = ler(PBX);
  assert.match(pbx, /objectVersion = 77;/, 'abrir e salvar num Xcode mais novo pode subir o formato e quebrar a CI (Xcode 26)');
  assert.match(pbx, /preferredProjectObjectVersion = 77;/);
  for(const pasta of ['Custta', 'CusttaTests', 'CusttaUITests'])
    assert.match(pbx, new RegExp(`isa = PBXFileSystemSynchronizedRootGroup;[^}]*path = ${pasta};`), `pasta sincronizada ${pasta}`);
});

test('app: bundle br.com.custta.app, versão 2.0, iOS 26, só iPhone e só retrato', () => {
  const configs = configsDoApp();
  assert.deepEqual(Object.keys(configs).sort(), ['Debug', 'Release']);
  for(const [nome, c] of Object.entries(configs)){
    assert.match(c, /PRODUCT_BUNDLE_IDENTIFIER = br\.com\.custta\.app;/, nome);
    assert.match(c, /MARKETING_VERSION = 2\.0;/, nome);
    assert.match(c, /TARGETED_DEVICE_FAMILY = 1;/, nome);
    assert.match(c, /INFOPLIST_KEY_UISupportedInterfaceOrientations = UIInterfaceOrientationPortrait;/, nome);
    assert.match(c, /CODE_SIGN_ENTITLEMENTS = Custta\/Custta\.entitlements;/, nome);
  }
  const pbx = ler(PBX);
  const alvos = [...pbx.matchAll(/IPHONEOS_DEPLOYMENT_TARGET = ([\d.]+);/g)].map(m => m[1]);
  assert.ok(alvos.length >= 2 && alvos.every(v => v === '26.0'), `iOS mínimo 26.0: ${alvos}`);
  assert.ok(!pbx.includes('TARGETED_DEVICE_FAMILY = "1,2"'), 'só iPhone');
});

test('Release assina com o perfil App Store e push de produção; Debug assina sozinho', () => {
  const { Debug, Release } = configsDoApp();
  assert.match(Release, /CODE_SIGN_STYLE = Manual;/);
  assert.match(Release, /PROVISIONING_PROFILE_SPECIFIER = "Custta App Store";/);
  assert.match(Release, /"CODE_SIGN_IDENTITY\[sdk=iphoneos\*\]" = "Apple Distribution";/);
  assert.match(Release, /APS_ENVIRONMENT = production;/);
  assert.match(Debug, /CODE_SIGN_STYLE = Automatic;/);
  assert.match(Debug, /APS_ENVIRONMENT = development;/);
  assert.match(ler(PBX), /DEVELOPMENT_TEAM = 4S7JKDKN27;/);
});

test('pacotes: só Firebase e GoogleSignIn, em versão exata, e o Package.resolved bate', () => {
  const pbx = ler(PBX);
  const remotos = [...pbx.matchAll(/repositoryURL = "([^"]+)";\s*requirement = \{\s*kind = (\w+);\s*version = ([\d.]+);/g)]
    .map(m => ({ url: m[1], tipo: m[2], versao: m[3] }));
  assert.deepEqual(remotos.map(r => r.url).sort(), ['https://github.com/firebase/firebase-ios-sdk.git', 'https://github.com/google/GoogleSignIn-iOS']);
  for(const r of remotos) assert.equal(r.tipo, 'exactVersion', `${r.url} preso por versão exata`);
  assert.deepEqual([...new Set([...pbx.matchAll(/isa = XCSwiftPackageProductDependency;[^}]*productName = (\w+);/g)].map(m => m[1]))].sort(),
    ['CusttaNucleo', 'FirebaseAuth', 'FirebaseFirestore', 'GoogleSignIn']);
  assert.match(pbx, /isa = XCLocalSwiftPackageReference;\s*relativePath = CusttaNucleo;/);

  const pins = JSON.parse(ler(RESOLVED)).pins;
  for(const r of remotos){
    const id = r.url.split('/').pop().replace(/\.git$/, '').toLowerCase();
    assert.equal(pins.find(p => p.identity === id)?.state.version, r.versao, `${id} no Package.resolved`);
  }
  // Mesma regra do app de hoje (tests/workflow.test.cjs): dono revisado, versão e commit, nunca branch.
  const DONOS = new Set(['firebase', 'google', 'openid', 'googleads']);
  for(const p of pins){
    const dono = /^https:\/\/github\.com\/([^/]+)\//.exec(p.location)?.[1];
    assert.ok(DONOS.has(dono), `${p.identity}: dono ${dono} não revisado`);
    assert.match(p.state.revision, /^[0-9a-f]{40}$/, `${p.identity} preso por commit`);
    assert.ok(p.state.version, `${p.identity} preso por versão`);
  }
});

test('o app nativo não leva o Sentry', () => {
  assert.doesNotMatch(ler(PBX), /sentry/i);
  for(const f of arquivosSwift('app-ios/Custta')) assert.doesNotMatch(ler(f), /import Sentry|SentrySDK/, f);
});

test('reaproveita do app de hoje: Firebase, entitlements e o esquema de URL do Google', () => {
  // Enquanto ios/ existir (até a remoção do Capacitor), as cópias não podem divergir.
  assert.equal(ler('app-ios/Custta/GoogleService-Info.plist'), ler('ios/App/App/GoogleService-Info.plist'));
  assert.equal(ler('app-ios/Custta/Custta.entitlements'), ler('ios/App/App/App.entitlements'));
  const google = ler('app-ios/Custta/GoogleService-Info.plist');
  const valor = chave => google.match(new RegExp(`<key>${chave}</key>\\s*<string>([^<]+)</string>`))[1];
  const info = ler('app-ios/Custta/Info.plist');
  assert.equal(info.match(/<key>GIDClientID<\/key>\s*<string>([^<]+)<\/string>/)?.[1], valor('CLIENT_ID'));
  assert.ok(info.includes(`<string>${valor('REVERSED_CLIENT_ID')}</string>`), 'sem o esquema o login do Google derruba o app');
});

test('ícone 1024×1024 sem canal alfa', () => {
  const png = readFileSync(join(RAIZ, 'app-ios/Custta/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png'));
  assert.equal(png.toString('ascii', 12, 16), 'IHDR');
  assert.equal(png.readUInt32BE(16), 1024);
  assert.equal(png.readUInt32BE(20), 1024);
  assert.equal(png[25], 2, 'a App Store recusa ícone com canal alfa (ITMS-90717)');
});

test('scheme compartilhado Custta com o app e os dois alvos de teste', () => {
  const xml = ler('app-ios/Custta.xcodeproj/xcshareddata/xcschemes/Custta.xcscheme');
  for(const alvo of ['Custta', 'CusttaTests', 'CusttaUITests']) assert.match(xml, new RegExp(`BlueprintName = "${alvo}"`), alvo);
  assert.match(xml, /ReferencedContainer = "container:Custta\.xcodeproj"/);
});

test('manifesto de privacidade: sem rastreamento, UserDefaults pelo motivo certo e os dados da política', () => {
  const m = ler('app-ios/Custta/PrivacyInfo.xcprivacy');
  assert.match(m, /<key>NSPrivacyTracking<\/key>\s*<false\/>/);
  assert.match(m, /<key>NSPrivacyTrackingDomains<\/key>\s*<array\/>/);
  assert.match(m, /NSPrivacyAccessedAPICategoryUserDefaults<\/string>[\s\S]*?<string>CA92\.1<\/string>/, '@AppStorage e a marca de limpeza usam UserDefaults');
  // Os mesmos dados da política de privacidade do site (privacidade.html); o token do FCM entra na etapa 5.
  for(const tipo of ['EmailAddress', 'Name', 'UserID', 'OtherUserContent', 'OtherDataTypes'])
    assert.match(m, new RegExp(`NSPrivacyCollectedDataType${tipo}<`), `dado coletado ${tipo}`);
  assert.doesNotMatch(m, /<key>NSPrivacyCollectedDataTypeTracking<\/key>\s*<true\/>/, 'nada coletado para rastrear');
});
```

Acrescente `tests/app-ios.test.cjs` ao fim da lista do `test:unit` no `package.json`.

- [ ] **Step 2: Rodar e ver falhar**

Run: `node --test tests/app-ios.test.cjs`
Expected: FAIL com `ENOENT: no such file or directory, open '…/app-ios/Custta.xcodeproj/project.pbxproj'`.

- [ ] **Step 3: Criar o projeto**

`app-ios/Custta.xcodeproj/project.pbxproj`:

```text
// !$*UTF8*$!
{
	archiveVersion = 1;
	classes = {
	};
	objectVersion = 77;
	objects = {

/* Begin PBXBuildFile section */
		C05A00000000000000000090 /* FirebaseAuth in Frameworks */ = {isa = PBXBuildFile; productRef = C05A00000000000000000080 /* FirebaseAuth */; };
		C05A00000000000000000091 /* FirebaseFirestore in Frameworks */ = {isa = PBXBuildFile; productRef = C05A00000000000000000081 /* FirebaseFirestore */; };
		C05A00000000000000000092 /* GoogleSignIn in Frameworks */ = {isa = PBXBuildFile; productRef = C05A00000000000000000082 /* GoogleSignIn */; };
		C05A00000000000000000093 /* CusttaNucleo in Frameworks */ = {isa = PBXBuildFile; productRef = C05A00000000000000000083 /* CusttaNucleo */; };
/* End PBXBuildFile section */

/* Begin PBXContainerItemProxy section */
		C05A00000000000000000050 /* PBXContainerItemProxy */ = {
			isa = PBXContainerItemProxy;
			containerPortal = C05A00000000000000000001 /* Project object */;
			proxyType = 1;
			remoteGlobalIDString = C05A00000000000000000030;
			remoteInfo = Custta;
		};
		C05A00000000000000000052 /* PBXContainerItemProxy */ = {
			isa = PBXContainerItemProxy;
			containerPortal = C05A00000000000000000001 /* Project object */;
			proxyType = 1;
			remoteGlobalIDString = C05A00000000000000000030;
			remoteInfo = Custta;
		};
/* End PBXContainerItemProxy section */

/* Begin PBXFileReference section */
		C05A00000000000000000010 /* Custta.app */ = {isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = Custta.app; sourceTree = BUILT_PRODUCTS_DIR; };
		C05A00000000000000000011 /* CusttaTests.xctest */ = {isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = CusttaTests.xctest; sourceTree = BUILT_PRODUCTS_DIR; };
		C05A00000000000000000012 /* CusttaUITests.xctest */ = {isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = CusttaUITests.xctest; sourceTree = BUILT_PRODUCTS_DIR; };
/* End PBXFileReference section */

/* Begin PBXFileSystemSynchronizedBuildFileExceptionSet section */
		C05A00000000000000000023 /* Exceptions for "Custta" folder in "Custta" target */ = {
			isa = PBXFileSystemSynchronizedBuildFileExceptionSet;
			membershipExceptions = (
				Info.plist,
			);
			target = C05A00000000000000000030 /* Custta */;
		};
/* End PBXFileSystemSynchronizedBuildFileExceptionSet section */

/* Begin PBXFileSystemSynchronizedRootGroup section */
		C05A00000000000000000020 /* Custta */ = {
			isa = PBXFileSystemSynchronizedRootGroup;
			exceptions = (
				C05A00000000000000000023 /* Exceptions for "Custta" folder in "Custta" target */,
			);
			path = Custta;
			sourceTree = "<group>";
		};
		C05A00000000000000000021 /* CusttaTests */ = {
			isa = PBXFileSystemSynchronizedRootGroup;
			path = CusttaTests;
			sourceTree = "<group>";
		};
		C05A00000000000000000022 /* CusttaUITests */ = {
			isa = PBXFileSystemSynchronizedRootGroup;
			path = CusttaUITests;
			sourceTree = "<group>";
		};
/* End PBXFileSystemSynchronizedRootGroup section */

/* Begin PBXFrameworksBuildPhase section */
		C05A00000000000000000041 /* Frameworks */ = {
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
				C05A00000000000000000090 /* FirebaseAuth in Frameworks */,
				C05A00000000000000000091 /* FirebaseFirestore in Frameworks */,
				C05A00000000000000000092 /* GoogleSignIn in Frameworks */,
				C05A00000000000000000093 /* CusttaNucleo in Frameworks */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
		C05A00000000000000000044 /* Frameworks */ = {
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
		C05A00000000000000000047 /* Frameworks */ = {
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
		C05A00000000000000000002 = {
			isa = PBXGroup;
			children = (
				C05A00000000000000000020 /* Custta */,
				C05A00000000000000000021 /* CusttaTests */,
				C05A00000000000000000022 /* CusttaUITests */,
				C05A00000000000000000003 /* Products */,
			);
			sourceTree = "<group>";
		};
		C05A00000000000000000003 /* Products */ = {
			isa = PBXGroup;
			children = (
				C05A00000000000000000010 /* Custta.app */,
				C05A00000000000000000011 /* CusttaTests.xctest */,
				C05A00000000000000000012 /* CusttaUITests.xctest */,
			);
			name = Products;
			sourceTree = "<group>";
		};
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
		C05A00000000000000000030 /* Custta */ = {
			isa = PBXNativeTarget;
			buildConfigurationList = C05A00000000000000000063 /* Build configuration list for PBXNativeTarget "Custta" */;
			buildPhases = (
				C05A00000000000000000040 /* Sources */,
				C05A00000000000000000041 /* Frameworks */,
				C05A00000000000000000042 /* Resources */,
			);
			buildRules = (
			);
			dependencies = (
			);
			fileSystemSynchronizedGroups = (
				C05A00000000000000000020 /* Custta */,
			);
			name = Custta;
			packageProductDependencies = (
				C05A00000000000000000080 /* FirebaseAuth */,
				C05A00000000000000000081 /* FirebaseFirestore */,
				C05A00000000000000000082 /* GoogleSignIn */,
				C05A00000000000000000083 /* CusttaNucleo */,
			);
			productName = Custta;
			productReference = C05A00000000000000000010 /* Custta.app */;
			productType = "com.apple.product-type.application";
		};
		C05A00000000000000000031 /* CusttaTests */ = {
			isa = PBXNativeTarget;
			buildConfigurationList = C05A00000000000000000066 /* Build configuration list for PBXNativeTarget "CusttaTests" */;
			buildPhases = (
				C05A00000000000000000043 /* Sources */,
				C05A00000000000000000044 /* Frameworks */,
				C05A00000000000000000045 /* Resources */,
			);
			buildRules = (
			);
			dependencies = (
				C05A00000000000000000051 /* PBXTargetDependency */,
			);
			fileSystemSynchronizedGroups = (
				C05A00000000000000000021 /* CusttaTests */,
			);
			name = CusttaTests;
			packageProductDependencies = (
			);
			productName = CusttaTests;
			productReference = C05A00000000000000000011 /* CusttaTests.xctest */;
			productType = "com.apple.product-type.bundle.unit-test";
		};
		C05A00000000000000000032 /* CusttaUITests */ = {
			isa = PBXNativeTarget;
			buildConfigurationList = C05A00000000000000000069 /* Build configuration list for PBXNativeTarget "CusttaUITests" */;
			buildPhases = (
				C05A00000000000000000046 /* Sources */,
				C05A00000000000000000047 /* Frameworks */,
				C05A00000000000000000048 /* Resources */,
			);
			buildRules = (
			);
			dependencies = (
				C05A00000000000000000053 /* PBXTargetDependency */,
			);
			fileSystemSynchronizedGroups = (
				C05A00000000000000000022 /* CusttaUITests */,
			);
			name = CusttaUITests;
			packageProductDependencies = (
			);
			productName = CusttaUITests;
			productReference = C05A00000000000000000012 /* CusttaUITests.xctest */;
			productType = "com.apple.product-type.bundle.ui-testing";
		};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
		C05A00000000000000000001 /* Project object */ = {
			isa = PBXProject;
			attributes = {
				BuildIndependentTargetsInParallel = 1;
				LastSwiftUpdateCheck = 2600;
				LastUpgradeCheck = 2600;
				TargetAttributes = {
					C05A00000000000000000030 = {
						CreatedOnToolsVersion = 26.0;
					};
					C05A00000000000000000031 = {
						CreatedOnToolsVersion = 26.0;
						TestTargetID = C05A00000000000000000030;
					};
					C05A00000000000000000032 = {
						CreatedOnToolsVersion = 26.0;
						TestTargetID = C05A00000000000000000030;
					};
				};
			};
			buildConfigurationList = C05A00000000000000000060 /* Build configuration list for PBXProject "Custta" */;
			developmentRegion = "pt-BR";
			hasScannedForEncodings = 0;
			knownRegions = (
				"pt-BR",
				Base,
			);
			mainGroup = C05A00000000000000000002;
			minimizedProjectReferenceProxies = 1;
			packageReferences = (
				C05A00000000000000000070 /* XCRemoteSwiftPackageReference "firebase-ios-sdk" */,
				C05A00000000000000000071 /* XCRemoteSwiftPackageReference "GoogleSignIn-iOS" */,
				C05A00000000000000000072 /* XCLocalSwiftPackageReference "CusttaNucleo" */,
			);
			preferredProjectObjectVersion = 77;
			productRefGroup = C05A00000000000000000003 /* Products */;
			projectDirPath = "";
			projectRoot = "";
			targets = (
				C05A00000000000000000030 /* Custta */,
				C05A00000000000000000031 /* CusttaTests */,
				C05A00000000000000000032 /* CusttaUITests */,
			);
		};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
		C05A00000000000000000042 /* Resources */ = {
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
		C05A00000000000000000045 /* Resources */ = {
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
		C05A00000000000000000048 /* Resources */ = {
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
		C05A00000000000000000040 /* Sources */ = {
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
		C05A00000000000000000043 /* Sources */ = {
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
		C05A00000000000000000046 /* Sources */ = {
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXSourcesBuildPhase section */

/* Begin PBXTargetDependency section */
		C05A00000000000000000051 /* PBXTargetDependency */ = {
			isa = PBXTargetDependency;
			target = C05A00000000000000000030 /* Custta */;
			targetProxy = C05A00000000000000000050 /* PBXContainerItemProxy */;
		};
		C05A00000000000000000053 /* PBXTargetDependency */ = {
			isa = PBXTargetDependency;
			target = C05A00000000000000000030 /* Custta */;
			targetProxy = C05A00000000000000000052 /* PBXContainerItemProxy */;
		};
/* End PBXTargetDependency section */

/* Begin XCBuildConfiguration section */
		C05A00000000000000000061 /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ALWAYS_SEARCH_USER_PATHS = NO;
				ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = dwarf;
				DEVELOPMENT_TEAM = 4S7JKDKN27;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				ENABLE_TESTABILITY = YES;
				ENABLE_USER_SCRIPT_SANDBOXING = YES;
				GCC_C_LANGUAGE_STANDARD = gnu17;
				GCC_DYNAMIC_NO_PIC = NO;
				GCC_NO_COMMON_BLOCKS = YES;
				GCC_OPTIMIZATION_LEVEL = 0;
				GCC_PREPROCESSOR_DEFINITIONS = (
					"DEBUG=1",
					"$(inherited)",
				);
				IPHONEOS_DEPLOYMENT_TARGET = 26.0;
				LOCALIZATION_PREFERS_STRING_CATALOGS = YES;
				MTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
				ONLY_ACTIVE_ARCH = YES;
				SDKROOT = iphoneos;
				SWIFT_ACTIVE_COMPILATION_CONDITIONS = "DEBUG $(inherited)";
				SWIFT_OPTIMIZATION_LEVEL = "-Onone";
				SWIFT_VERSION = 6.0;
			};
			name = Debug;
		};
		C05A00000000000000000062 /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ALWAYS_SEARCH_USER_PATHS = NO;
				ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
				DEVELOPMENT_TEAM = 4S7JKDKN27;
				ENABLE_NS_ASSERTIONS = NO;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				ENABLE_USER_SCRIPT_SANDBOXING = YES;
				GCC_C_LANGUAGE_STANDARD = gnu17;
				GCC_NO_COMMON_BLOCKS = YES;
				IPHONEOS_DEPLOYMENT_TARGET = 26.0;
				LOCALIZATION_PREFERS_STRING_CATALOGS = YES;
				MTL_ENABLE_DEBUG_INFO = NO;
				SDKROOT = iphoneos;
				SWIFT_COMPILATION_MODE = wholemodule;
				SWIFT_VERSION = 6.0;
				VALIDATE_PRODUCT = YES;
			};
			name = Release;
		};
		C05A00000000000000000064 /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				APS_ENVIRONMENT = development;
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGN_ENTITLEMENTS = Custta/Custta.entitlements;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				ENABLE_PREVIEWS = YES;
				GENERATE_INFOPLIST_FILE = YES;
				INFOPLIST_FILE = Custta/Info.plist;
				INFOPLIST_KEY_CFBundleDisplayName = Custta;
				INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO;
				INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
				INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;
				INFOPLIST_KEY_UISupportedInterfaceOrientations = UIInterfaceOrientationPortrait;
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = 2.0;
				PRODUCT_BUNDLE_IDENTIFIER = br.com.custta.app;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SUPPORTED_PLATFORMS = "iphoneos iphonesimulator";
				SUPPORTS_MACCATALYST = NO;
				SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD = NO;
				SUPPORTS_XR_DESIGNED_FOR_IPHONE_IPAD = NO;
				SWIFT_EMIT_LOC_STRINGS = YES;
				TARGETED_DEVICE_FAMILY = 1;
			};
			name = Debug;
		};
		C05A00000000000000000065 /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				APS_ENVIRONMENT = production;
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGN_ENTITLEMENTS = Custta/Custta.entitlements;
				CODE_SIGN_STYLE = Manual;
				"CODE_SIGN_IDENTITY[sdk=iphoneos*]" = "Apple Distribution";
				CURRENT_PROJECT_VERSION = 1;
				GENERATE_INFOPLIST_FILE = YES;
				INFOPLIST_FILE = Custta/Info.plist;
				INFOPLIST_KEY_CFBundleDisplayName = Custta;
				INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO;
				INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
				INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;
				INFOPLIST_KEY_UISupportedInterfaceOrientations = UIInterfaceOrientationPortrait;
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = 2.0;
				PRODUCT_BUNDLE_IDENTIFIER = br.com.custta.app;
				PRODUCT_NAME = "$(TARGET_NAME)";
				PROVISIONING_PROFILE_SPECIFIER = "Custta App Store";
				SUPPORTED_PLATFORMS = "iphoneos iphonesimulator";
				SUPPORTS_MACCATALYST = NO;
				SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD = NO;
				SUPPORTS_XR_DESIGNED_FOR_IPHONE_IPAD = NO;
				SWIFT_EMIT_LOC_STRINGS = YES;
				TARGETED_DEVICE_FAMILY = 1;
			};
			name = Release;
		};
		C05A00000000000000000067 /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				BUNDLE_LOADER = "$(TEST_HOST)";
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				GENERATE_INFOPLIST_FILE = YES;
				MARKETING_VERSION = 2.0;
				PRODUCT_BUNDLE_IDENTIFIER = br.com.custta.app.testes;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SUPPORTED_PLATFORMS = "iphoneos iphonesimulator";
				TARGETED_DEVICE_FAMILY = 1;
				TEST_HOST = "$(BUILT_PRODUCTS_DIR)/Custta.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/Custta";
			};
			name = Debug;
		};
		C05A00000000000000000068 /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				BUNDLE_LOADER = "$(TEST_HOST)";
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				GENERATE_INFOPLIST_FILE = YES;
				MARKETING_VERSION = 2.0;
				PRODUCT_BUNDLE_IDENTIFIER = br.com.custta.app.testes;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SUPPORTED_PLATFORMS = "iphoneos iphonesimulator";
				TARGETED_DEVICE_FAMILY = 1;
				TEST_HOST = "$(BUILT_PRODUCTS_DIR)/Custta.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/Custta";
			};
			name = Release;
		};
		C05A0000000000000000006A /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				GENERATE_INFOPLIST_FILE = YES;
				MARKETING_VERSION = 2.0;
				PRODUCT_BUNDLE_IDENTIFIER = br.com.custta.app.testes-de-tela;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SUPPORTED_PLATFORMS = "iphoneos iphonesimulator";
				TARGETED_DEVICE_FAMILY = 1;
				TEST_TARGET_NAME = Custta;
			};
			name = Debug;
		};
		C05A0000000000000000006B /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				GENERATE_INFOPLIST_FILE = YES;
				MARKETING_VERSION = 2.0;
				PRODUCT_BUNDLE_IDENTIFIER = br.com.custta.app.testes-de-tela;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SUPPORTED_PLATFORMS = "iphoneos iphonesimulator";
				TARGETED_DEVICE_FAMILY = 1;
				TEST_TARGET_NAME = Custta;
			};
			name = Release;
		};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
		C05A00000000000000000060 /* Build configuration list for PBXProject "Custta" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				C05A00000000000000000061 /* Debug */,
				C05A00000000000000000062 /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
		C05A00000000000000000063 /* Build configuration list for PBXNativeTarget "Custta" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				C05A00000000000000000064 /* Debug */,
				C05A00000000000000000065 /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
		C05A00000000000000000066 /* Build configuration list for PBXNativeTarget "CusttaTests" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				C05A00000000000000000067 /* Debug */,
				C05A00000000000000000068 /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
		C05A00000000000000000069 /* Build configuration list for PBXNativeTarget "CusttaUITests" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				C05A0000000000000000006A /* Debug */,
				C05A0000000000000000006B /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
/* End XCConfigurationList section */

/* Begin XCLocalSwiftPackageReference section */
		C05A00000000000000000072 /* XCLocalSwiftPackageReference "CusttaNucleo" */ = {
			isa = XCLocalSwiftPackageReference;
			relativePath = CusttaNucleo;
		};
/* End XCLocalSwiftPackageReference section */

/* Begin XCRemoteSwiftPackageReference section */
		C05A00000000000000000070 /* XCRemoteSwiftPackageReference "firebase-ios-sdk" */ = {
			isa = XCRemoteSwiftPackageReference;
			repositoryURL = "https://github.com/firebase/firebase-ios-sdk.git";
			requirement = {
				kind = exactVersion;
				version = 12.19.2;
			};
		};
		C05A00000000000000000071 /* XCRemoteSwiftPackageReference "GoogleSignIn-iOS" */ = {
			isa = XCRemoteSwiftPackageReference;
			repositoryURL = "https://github.com/google/GoogleSignIn-iOS";
			requirement = {
				kind = exactVersion;
				version = 8.0.0;
			};
		};
/* End XCRemoteSwiftPackageReference section */

/* Begin XCSwiftPackageProductDependency section */
		C05A00000000000000000080 /* FirebaseAuth */ = {
			isa = XCSwiftPackageProductDependency;
			package = C05A00000000000000000070 /* XCRemoteSwiftPackageReference "firebase-ios-sdk" */;
			productName = FirebaseAuth;
		};
		C05A00000000000000000081 /* FirebaseFirestore */ = {
			isa = XCSwiftPackageProductDependency;
			package = C05A00000000000000000070 /* XCRemoteSwiftPackageReference "firebase-ios-sdk" */;
			productName = FirebaseFirestore;
		};
		C05A00000000000000000082 /* GoogleSignIn */ = {
			isa = XCSwiftPackageProductDependency;
			package = C05A00000000000000000071 /* XCRemoteSwiftPackageReference "GoogleSignIn-iOS" */;
			productName = GoogleSignIn;
		};
		C05A00000000000000000083 /* CusttaNucleo */ = {
			isa = XCSwiftPackageProductDependency;
			package = C05A00000000000000000072 /* XCLocalSwiftPackageReference "CusttaNucleo" */;
			productName = CusttaNucleo;
		};
/* End XCSwiftPackageProductDependency section */
	};
	rootObject = C05A00000000000000000001 /* Project object */;
}
```

`app-ios/Custta.xcodeproj/project.xcworkspace/contents.xcworkspacedata`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Workspace
   version = "1.0">
   <FileRef
      location = "self:">
   </FileRef>
</Workspace>
```

`app-ios/Custta.xcodeproj/xcshareddata/xcschemes/Custta.xcscheme`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "2600"
   version = "1.7">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES"
      buildArchitectures = "Automatic">
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "YES"
            buildForProfiling = "YES"
            buildForArchiving = "YES"
            buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "C05A00000000000000000030"
               BuildableName = "Custta.app"
               BlueprintName = "Custta"
               ReferencedContainer = "container:Custta.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES">
      <Testables>
         <TestableReference
            skipped = "NO"
            parallelizable = "NO">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "C05A00000000000000000031"
               BuildableName = "CusttaTests.xctest"
               BlueprintName = "CusttaTests"
               ReferencedContainer = "container:Custta.xcodeproj">
            </BuildableReference>
         </TestableReference>
         <TestableReference
            skipped = "NO"
            parallelizable = "NO">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "C05A00000000000000000032"
               BuildableName = "CusttaUITests.xctest"
               BlueprintName = "CusttaUITests"
               ReferencedContainer = "container:Custta.xcodeproj">
            </BuildableReference>
         </TestableReference>
      </Testables>
   </TestAction>
   <LaunchAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "NO">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "C05A00000000000000000030"
            BuildableName = "Custta.app"
            BlueprintName = "Custta"
            ReferencedContainer = "container:Custta.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction
      buildConfiguration = "Release"
      shouldUseLaunchSchemeArgsEnv = "YES"
      savedToolIdentifier = ""
      useCustomWorkingDirectory = "NO"
      debugDocumentVersioning = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "C05A00000000000000000030"
            BuildableName = "Custta.app"
            BlueprintName = "Custta"
            ReferencedContainer = "container:Custta.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction
      buildConfiguration = "Debug">
   </AnalyzeAction>
   <ArchiveAction
      buildConfiguration = "Release"
      revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>
```

`app-ios/Custta/CusttaApp.swift` (a Tarefa 4 troca este corpo pela abertura com o fundo, e a Tarefa 10 pela raiz das telas):

```swift
import SwiftUI

@main
struct CusttaApp: App {
    var body: some Scene {
        WindowGroup { Text("Custta").accessibilityIdentifier("abertura") }
    }
}
```

`app-ios/Custta/Info.plist` (o resto das chaves sai das `INFOPLIST_KEY_*` do projeto):

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleURLTypes</key>
	<array>
		<dict>
			<key>CFBundleTypeRole</key>
			<string>Editor</string>
			<key>CFBundleURLSchemes</key>
			<array>
				<string>com.googleusercontent.apps.111188093030-lr3tolevnspbn07s3lk8egklk1tlju6h</string>
			</array>
		</dict>
	</array>
	<key>GIDClientID</key>
	<string>111188093030-lr3tolevnspbn07s3lk8egklk1tlju6h.apps.googleusercontent.com</string>
	<key>UILaunchScreen</key>
	<dict>
		<key>UIColorName</key>
		<string>FundoAbertura</string>
	</dict>
</dict>
</plist>
```

`app-ios/Custta/PrivacyInfo.xcprivacy` (manifesto de privacidade: sem rastreamento; `UserDefaults` pelo motivo CA92.1, porque o app usa `@AppStorage` e a marca de limpeza do cache; os dados coletados são os da política de privacidade do site. Os SDKs do Firebase e do Google trazem os manifestos deles):

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>NSPrivacyTracking</key>
	<false/>
	<key>NSPrivacyTrackingDomains</key>
	<array/>
	<key>NSPrivacyAccessedAPITypes</key>
	<array>
		<dict>
			<key>NSPrivacyAccessedAPIType</key>
			<string>NSPrivacyAccessedAPICategoryUserDefaults</string>
			<key>NSPrivacyAccessedAPITypeReasons</key>
			<array>
				<string>CA92.1</string>
			</array>
		</dict>
	</array>
	<key>NSPrivacyCollectedDataTypes</key>
	<array>
		<dict>
			<key>NSPrivacyCollectedDataType</key>
			<string>NSPrivacyCollectedDataTypeEmailAddress</string>
			<key>NSPrivacyCollectedDataTypeLinked</key>
			<true/>
			<key>NSPrivacyCollectedDataTypeTracking</key>
			<false/>
			<key>NSPrivacyCollectedDataTypePurposes</key>
			<array>
				<string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string>
			</array>
		</dict>
		<dict>
			<key>NSPrivacyCollectedDataType</key>
			<string>NSPrivacyCollectedDataTypeName</string>
			<key>NSPrivacyCollectedDataTypeLinked</key>
			<true/>
			<key>NSPrivacyCollectedDataTypeTracking</key>
			<false/>
			<key>NSPrivacyCollectedDataTypePurposes</key>
			<array>
				<string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string>
			</array>
		</dict>
		<dict>
			<key>NSPrivacyCollectedDataType</key>
			<string>NSPrivacyCollectedDataTypeUserID</string>
			<key>NSPrivacyCollectedDataTypeLinked</key>
			<true/>
			<key>NSPrivacyCollectedDataTypeTracking</key>
			<false/>
			<key>NSPrivacyCollectedDataTypePurposes</key>
			<array>
				<string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string>
			</array>
		</dict>
		<dict>
			<key>NSPrivacyCollectedDataType</key>
			<string>NSPrivacyCollectedDataTypeOtherUserContent</string>
			<key>NSPrivacyCollectedDataTypeLinked</key>
			<true/>
			<key>NSPrivacyCollectedDataTypeTracking</key>
			<false/>
			<key>NSPrivacyCollectedDataTypePurposes</key>
			<array>
				<string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string>
			</array>
		</dict>
		<dict>
			<key>NSPrivacyCollectedDataType</key>
			<string>NSPrivacyCollectedDataTypeOtherDataTypes</string>
			<key>NSPrivacyCollectedDataTypeLinked</key>
			<true/>
			<key>NSPrivacyCollectedDataTypeTracking</key>
			<false/>
			<key>NSPrivacyCollectedDataTypePurposes</key>
			<array>
				<string>NSPrivacyCollectedDataTypePurposeAnalytics</string>
			</array>
		</dict>
	</array>
</dict>
</plist>
```

Cópias e catálogo:

```bash
cp ios/App/App/App.entitlements app-ios/Custta/Custta.entitlements
cp ios/App/App/GoogleService-Info.plist app-ios/Custta/GoogleService-Info.plist
mkdir -p app-ios/Custta/Assets.xcassets/AppIcon.appiconset app-ios/Custta/Assets.xcassets/AccentColor.colorset app-ios/Custta/Assets.xcassets/FundoAbertura.colorset
cp ios/App/App/Assets.xcassets/AppIcon.appiconset/AppIcon-512@2x.png app-ios/Custta/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png
```

`app-ios/Custta/Assets.xcassets/Contents.json`:

```json
{
  "info" : { "author" : "xcode", "version" : 1 }
}
```

`app-ios/Custta/Assets.xcassets/AppIcon.appiconset/Contents.json`:

```json
{
  "images" : [ { "filename" : "AppIcon-1024.png", "idiom" : "universal", "platform" : "ios", "size" : "1024x1024" } ],
  "info" : { "author" : "xcode", "version" : 1 }
}
```

`app-ios/Custta/Assets.xcassets/AccentColor.colorset/Contents.json` (a marca esmeralda; a tinta de verdade vem da `Paleta`, Tarefa 3):

```json
{
  "colors" : [
    { "idiom" : "universal", "color" : { "color-space" : "srgb", "components" : { "red" : "0x0B", "green" : "0x7A", "blue" : "0x68", "alpha" : "1.000" } } },
    { "idiom" : "universal", "appearances" : [ { "appearance" : "luminosity", "value" : "dark" } ],
      "color" : { "color-space" : "srgb", "components" : { "red" : "0x14", "green" : "0xB3", "blue" : "0x9A", "alpha" : "1.000" } } }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
```

`app-ios/Custta/Assets.xcassets/FundoAbertura.colorset/Contents.json` (o fundo escuro da abertura de hoje, `#04100C`, sem clarão branco):

```json
{
  "colors" : [
    { "idiom" : "universal", "color" : { "color-space" : "srgb", "components" : { "red" : "0x04", "green" : "0x10", "blue" : "0x0C", "alpha" : "1.000" } } }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
```

`app-ios/CusttaTests/FumacaTests.swift`:

```swift
import Testing
@testable import Custta
import CusttaNucleo

@Test func appEnxergaONucleo() {
    #expect(limiteBlob == 900_000)
}
```

`app-ios/CusttaUITests/AberturaUITests.swift`:

```swift
import XCTest

final class AberturaUITests: XCTestCase {
    @MainActor func testAppAbre() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.staticTexts["abertura"].waitForExistence(timeout: 10))
    }
}
```

Semeie o `Package.resolved` com o do app de hoje, sem os dois pins do Capacitor: as dependências transitivas ficam nas versões que já estão em produção, em vez de "a mais nova do dia". O Xcode só recalcula o `originHash`:

```bash
mkdir -p app-ios/Custta.xcodeproj/project.xcworkspace/xcshareddata/swiftpm
node -e "
const fs = require('fs');
const r = JSON.parse(fs.readFileSync('ios/App/App.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved', 'utf8'));
r.pins = r.pins.filter(p => p.location.indexOf('github.com/ionic-team/') < 0);
delete r.originHash;
fs.writeFileSync('app-ios/Custta.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved', JSON.stringify(r, null, 2) + '\n');
"
xcodebuild -resolvePackageDependencies -project app-ios/Custta.xcodeproj -scheme Custta
```

Expected: `Resolved source packages:` com `Firebase … @ 12.19.2`, `GoogleSignIn … @ 8.0.0`, `AppCheck … @ 11.3.2` e `GTMSessionFetcher … @ 3.5.0`. Confira que o Xcode manteve os 16 pins do app de hoje:

```bash
node -e "
const fs = require('fs');
const pins = (c, f = () => true) => JSON.parse(fs.readFileSync(c, 'utf8')).pins.filter(f).map(p => p.identity + '@' + p.state.revision).sort().join(' ');
const hoje = pins('ios/App/App.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved', p => p.location.indexOf('github.com/ionic-team/') < 0);
const nosso = pins('app-ios/Custta.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved');
if(nosso === hoje) console.log('ok - os 16 pins do app de hoje'); else { console.error('o Xcode mudou os pins'); process.exit(1); }
"
```

- [ ] **Step 4: Rodar e ver passar**

Run: `node --test tests/app-ios.test.cjs`
Expected: 9 testes verdes.

Run: `xcodebuild test -project app-ios/Custta.xcodeproj -scheme Custta -destination "platform=iOS Simulator,name=iPhone 17" -skipMacroValidation -skipPackagePluginValidation -onlyUsePackageVersionsFromResolvedFile CODE_SIGNING_ALLOWED=NO` (troque o nome por um iPhone da lista do `xcrun simctl list devices available`)
Expected: `** TEST SUCCEEDED **` com `appEnxergaONucleo` e `testAppAbre`.

Confira também que o `xcodebuild` não reescreveu o projeto: `git status app-ios/Custta.xcodeproj` só mostra os arquivos novos.

- [ ] **Step 5: Commit**

```bash
git add app-ios/Custta.xcodeproj app-ios/Custta app-ios/CusttaTests app-ios/CusttaUITests tests/app-ios.test.cjs package.json
git commit -m "feat: projeto do app nativo com pacotes travados" -m "Projeto Xcode escrito à mão no formato do Xcode 16 (pastas sincronizadas), sem gerador de terceiros: app br.com.custta.app versão 2.0 para iOS 26, só iPhone e só retrato, testes de unidade e de tela. Pacotes presos por versão exata no par que já resolve no app de hoje (Firebase 12.19.2 e GoogleSignIn 8.0.0), com o Package.resolved semeado do app de hoje (as transitivas nas versões que já estão em produção). GoogleService-Info.plist, entitlements e o esquema do Google vêm do app Capacitor, e a guarda em Node não deixa as cópias divergirem nem o formato do projeto subir. O manifesto de privacidade entra já, com os dados da política do site."
```

---

### Task 2: CI do app no simulador

**Files:**
- Create: `scripts/simulador-ios.mjs`
- Modify: `.github/workflows/app-ios.yml` (job `app`, caminhos e botão "resolver de novo")
- Modify: `tests/workflow.test.cjs` (bloco do app nativo)

**Interfaces:**
- Consumes: projeto da Tarefa 1; job `nucleo` da Parte A.
- Produces: `destinoDoSimulador(): string` e `testarNoSimulador(alvos: string[], env?: Record<string,string>): Promise<void>` em `scripts/simulador-ios.mjs` (as Tarefas 12 e 15 usam); CLI `node scripts/simulador-ios.mjs` (imprime o destino) e `node scripts/simulador-ios.mjs --testar <alvo>... [--emuladores]`.

- [ ] **Step 1: Escrever a guarda que falha**

Em `tests/workflow.test.cjs`, troque o bloco `/* App nativo (app-ios/): o núcleo roda swift test … */` (que a Parte A criou, até a linha antes do `console.log` final) por:

```js
/* App nativo (app-ios/): núcleo contra os vetores do site e app no simulador, num macOS fixo. */
const appIos = readFileSync(join(dir, 'app-ios.yml'), 'utf8');
const appIosSemComentario = appIos.split('\n').filter(l => !/^\s*#/.test(l)).join('\n');
assert.match(appIos, /runs-on:\s*macos-26/, 'o app nativo precisa do runner macOS 26 (Xcode 26)');
assert.match(appIos, /swift test --package-path app-ios\/CusttaNucleo/, 'sem o swift test do núcleo');
assert.match(appIos, /TZ:\s*America\/Sao_Paulo/, 'os testes do núcleo rodam no fuso dos vetores');
assert.match(appIos, /DEVELOPER_DIR:\s*\/Applications\/Xcode_26\.6\.app\/Contents\/Developer/, 'o Xcode da CI é fixo: o padrão do runner muda sem aviso');
for(const caminho of ['app-ios/**', 'calc.js', 'dados.js', 'push.js', 'scripts/vetores-calc.mjs', 'tests/vetores/**'])
  assert.ok(appIos.includes(`- '${caminho}'`), `app-ios.yml não dispara quando ${caminho} muda`);
assert.ok(!/^on:\n(?:.*\n)*?\s{2}push:/m.test(appIos), 'o app nativo não roda em todo push');
assert.match(appIos, /workflow_dispatch:/, 'o app nativo precisa do botão manual');
assert.match(appIos, /resolver_de_novo:/, 'sem o botão de resolver os pacotes Swift do app nativo de novo');
assert.match(appIosSemComentario, /-project app-ios\/Custta\.xcodeproj[\s\S]*-configuration Release[\s\S]*CODE_SIGNING_ALLOWED=NO/, 'o app compila em Release sem assinatura');
assert.match(appIosSemComentario, /xcodebuild test[\s\S]*-destination "\$DESTINO"/, 'os testes rodam no simulador escolhido pelo script');
assert.equal((appIosSemComentario.match(/-onlyUsePackageVersionsFromResolvedFile/g) || []).length, 2, 'build e testes com os pacotes travados');
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `node tests/workflow.test.cjs`
Expected: FAIL com `sem o botão de resolver os pacotes Swift do app nativo de novo`.

- [ ] **Step 3: Escrever o script do simulador e o job**

`scripts/simulador-ios.mjs`:

```js
/* Simulador para os testes do app nativo (app-ios/). Os nomes dos iPhones mudam de um Xcode
   para outro, então o destino não fica fixo no workflow nem nos scripts.

   node scripts/simulador-ios.mjs                         imprime o destino do xcodebuild
   node scripts/simulador-ios.mjs --testar <alvo>... [--emuladores]
       roda `xcodebuild test -only-testing:<alvo>` (ex.: CusttaTests). Com --emuladores, passa
       CUSTTA_EMULADORES=1 aos testes (os que dependem dos emuladores do Firebase deixam de
       pular). Assina para o simulador, como o Xcode faz: sem assinatura o app não tem
       entitlements e o Firebase Auth falha no keychain (erro -34018). */
import { execFileSync, spawn } from 'node:child_process';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const RAIZ = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');

/** "platform=iOS Simulator,id=…" do primeiro iPhone do iOS mais novo instalado. */
export function destinoDoSimulador(){
  const lista = JSON.parse(execFileSync('xcrun', ['simctl', 'list', 'devices', 'available', '-j'], { encoding: 'utf8' })).devices;
  const versao = runtime => (/iOS-(\d+)-(\d+)/.exec(runtime) || []).slice(1).map(Number);
  const runtimes = Object.keys(lista).filter(r => /SimRuntime\.iOS-/.test(r))
    .sort((a, b) => { const [x1, y1] = versao(a), [x2, y2] = versao(b); return x2 - x1 || y2 - y1; });
  for(const runtime of runtimes){
    const iphone = lista[runtime].find(d => d.isAvailable !== false && d.name.startsWith('iPhone'));
    if(iphone) return `platform=iOS Simulator,id=${iphone.udid}`;
  }
  throw new Error('nenhum iPhone no simulador: instale um runtime de iOS no Xcode (Settings > Components)');
}

/** xcodebuild test só dos alvos pedidos. `env` chega ao processo do teste (prefixo TEST_RUNNER_).
    Assíncrono de propósito: quem chama pode atender pedidos do teste enquanto ele roda. */
export function testarNoSimulador(alvos, env = {}){
  const ambiente = { ...process.env };
  for(const [k, v] of Object.entries(env)) ambiente[`TEST_RUNNER_${k}`] = v;
  const args = ['test', '-project', 'app-ios/Custta.xcodeproj', '-scheme', 'Custta', '-destination', destinoDoSimulador(),
    '-skipMacroValidation', '-skipPackagePluginValidation', '-onlyUsePackageVersionsFromResolvedFile',
    ...alvos.map(a => `-only-testing:${a}`)];
  return new Promise((resolve, reject) => spawn('xcodebuild', args, { cwd: RAIZ, stdio: 'inherit', env: ambiente })
    .on('error', reject)
    .on('exit', c => c === 0 ? resolve() : reject(new Error(`xcodebuild test falhou (${alvos.join(', ')})`))));
}

if(process.argv[1] === fileURLToPath(import.meta.url)){
  const args = process.argv.slice(2);
  try{
    if(args[0] === '--testar'){
      await testarNoSimulador(args.slice(1).filter(a => !a.startsWith('--')), args.includes('--emuladores') ? { CUSTTA_EMULADORES: '1' } : {});
    }else{
      console.log(destinoDoSimulador());
    }
  }catch(erro){
    console.error(erro.message);
    process.exit(1);
  }
}
```

Troque o `.github/workflows/app-ios.yml` inteiro por:

```yaml
name: app-ios
# App nativo em SwiftUI (app-ios/), num macOS 26 (Xcode 26):
# - nucleo: swift test do pacote CusttaNucleo, que confere as regras reescritas em Swift contra os
#   vetores gerados do site (tests/vetores/calc.json); por isso também dispara quando calc.js,
#   dados.js, push.js ou o gerador mudam;
# - app: compila o app em Release sem assinatura (o caminho do TestFlight) e roda os testes de
#   unidade e de tela no simulador com os serviços falsos.
# Os testes contra os emuladores do Firebase e a conferência cruzada com o site rodam no Mac
# (npm run test:app-ios:emuladores e npm run test:app-ios:cruzado): precisam de Java, dos
# emuladores e da assinatura de simulador para o keychain do Firebase Auth.
#
# Por que macos-26 fixo, e não macos-latest: o projeto é do Xcode 16+ (objectVersion 77) e o pacote
# pede Swift 6.2; trocar de imagem tem de ser decisão, não surpresa no meio de um PR. Pelo mesmo motivo
# o Xcode é fixo (DEVELOPER_DIR): o padrão do runner muda sem aviso.
on:
  pull_request:
    paths:
      - 'app-ios/**'
      - 'calc.js'
      - 'dados.js'
      - 'push.js'
      - 'scripts/vetores-calc.mjs'
      - 'scripts/simulador-ios.mjs'
      - 'tests/vetores/**'
      - '.github/workflows/app-ios.yml'
  workflow_dispatch:
    inputs:
      resolver_de_novo:
        description: 'Resolver os pacotes Swift do app nativo de novo e mostrar o Package.resolved novo no resumo'
        type: boolean
        default: false

permissions:
  contents: read

env:
  DEVELOPER_DIR: /Applications/Xcode_26.6.app/Contents/Developer

concurrency:
  group: app-ios-${{ github.ref }}
  cancel-in-progress: true

jobs:
  nucleo:
    runs-on: macos-26
    timeout-minutes: 20
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1

      # Fica no log: o runner troca de Xcode com o tempo e é a primeira coisa a conferir
      # quando um teste que passava começa a quebrar sozinho.
      - name: Versão do Xcode e do Swift
        run: |
          xcodebuild -version
          swift --version

      - name: Núcleo contra os vetores do site
        env:
          TZ: America/Sao_Paulo
        run: swift test --package-path app-ios/CusttaNucleo

  app:
    runs-on: macos-26
    timeout-minutes: 45
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
      - uses: actions/setup-node@820762786026740c76f36085b0efc47a31fe5020 # v7.0.0
        with:
          node-version: 22

      - name: Versão do Xcode
        run: xcodebuild -version

      # Pacotes Swift travados: o build usa só as versões do Package.resolved versionado. Para
      # atualizar, rode este workflow no botão com "resolver de novo", confira repositórios e
      # versões no resumo e versione o arquivo novo junto com a mudança do project.pbxproj.
      - name: Resolver os pacotes Swift de novo
        if: inputs.resolver_de_novo
        run: |
          set -o pipefail
          ARQ=app-ios/Custta.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
          rm -f "$ARQ"
          xcodebuild -resolvePackageDependencies -project app-ios/Custta.xcodeproj -scheme Custta
          { echo '### Package.resolved novo (app nativo)'; echo '```json'; cat "$ARQ"; echo '```'; } >> "$GITHUB_STEP_SUMMARY"
          cat "$ARQ"

      # -skipMacroValidation / -skipPackagePluginValidation: em CI não há quem aprove macro ou
      # plugin de pacote, e sem as flags o xcodebuild falha em vez de perguntar.
      # CODE_SIGNING_* zerados: a Release está configurada para o perfil "Custta App Store", e
      # este build prova que ela compila sem segredo nenhum (a assinatura mora no envio).
      - name: Compilar (Release, sem assinatura)
        run: |
          set -o pipefail
          xcodebuild \
            -project app-ios/Custta.xcodeproj \
            -scheme Custta \
            -configuration Release \
            -destination 'generic/platform=iOS' \
            -derivedDataPath app-ios/build \
            -skipMacroValidation \
            -skipPackagePluginValidation \
            -onlyUsePackageVersionsFromResolvedFile \
            CODE_SIGNING_ALLOWED=NO \
            CODE_SIGNING_REQUIRED=NO \
            CODE_SIGN_IDENTITY= \
            build

      # Testes com os serviços falsos (nada de rede): unidade e tela, inclusive as auditorias de
      # acessibilidade. Os que dependem dos emuladores pulam sozinhos aqui.
      - name: Testes de unidade e de tela no simulador
        run: |
          set -o pipefail
          DESTINO="$(node scripts/simulador-ios.mjs)"
          echo "Simulador: $DESTINO"
          xcodebuild test \
            -project app-ios/Custta.xcodeproj \
            -scheme Custta \
            -destination "$DESTINO" \
            -derivedDataPath app-ios/build \
            -skipMacroValidation \
            -skipPackagePluginValidation \
            -onlyUsePackageVersionsFromResolvedFile \
            CODE_SIGNING_ALLOWED=NO
```

- [ ] **Step 4: Rodar e ver passar**

Run: `node tests/workflow.test.cjs && node scripts/simulador-ios.mjs`
Expected: `ok - Actions com SHA imutável…` e uma linha `platform=iOS Simulator,id=…`.

Run: `xcodebuild test -project app-ios/Custta.xcodeproj -scheme Custta -destination "$(node scripts/simulador-ios.mjs)" -skipMacroValidation -skipPackagePluginValidation -onlyUsePackageVersionsFromResolvedFile CODE_SIGNING_ALLOWED=NO`
Expected: `** TEST SUCCEEDED **`.

Depois do push, o PR roda os dois jobs no `macos-26` (Xcode 26.6). É a primeira prova com o Xcode da CI; se o build quebrar só lá, abra o log do passo "Versão do Xcode" e trate antes da Tarefa 3.

- [ ] **Step 5: Commit**

```bash
git add scripts/simulador-ios.mjs .github/workflows/app-ios.yml tests/workflow.test.cjs
git commit -m "ci: app nativo compila e testa no simulador" -m "O workflow app-ios ganha o job app: compila em Release sem assinatura, como o envio ao TestFlight compila, e roda os testes de unidade e de tela no simulador com os pacotes travados. O simulador sai de scripts/simulador-ios.mjs, porque o nome dos iPhones muda a cada Xcode. O botão de resolver os pacotes de novo segue a mesma política do app de hoje."
```

---

### Task 3: Cores, vidro e ícones por tokens

**Files:**
- Create: `scripts/cores-app-ios.mjs`, `scripts/icones-app-ios.mjs`
- Create (gerados): `app-ios/Custta/Assets.xcassets/Esmeralda/` e `app-ios/Custta/Assets.xcassets/Azul/` (um `Contents.json` de pasta e um color set por token), `app-ios/Custta/Assets.xcassets/Icones/` (um `Contents.json` de pasta e um image set por ícone)
- Modify (gerados): `app-ios/Custta/Assets.xcassets/AccentColor.colorset/Contents.json`, `app-ios/Custta/Assets.xcassets/FundoAbertura.colorset/Contents.json`
- Create: `app-ios/Custta/Identidade/Paleta.swift`, `app-ios/Custta/Identidade/Vidro.swift`
- Test: `app-ios/CusttaTests/CoresTests.swift`
- Modify: `tests/app-ios.test.cjs` (quatro testes no fim)

**Interfaces:**
- Consumes: catálogo da Tarefa 1; `styles.css` (aurora e cores dos quatro combos) e `icons.js` do site; tokens do mockup aprovado (seção "Resultado do portão de desenho").
- Produces: em Swift, `enum Pele: String, CaseIterable { case esmeralda = "Esmeralda", azul = "Azul" }`; `enum Token: String, CaseIterable` (os nomes do catálogo, de `fundo` a `globoAro`); `struct Paleta: Equatable { var pele: Pele; static func nome(_ token: Token, _ pele: Pele) -> String; func cor(_ token: Token) -> Color }`; `EnvironmentValues.paleta`; `enum Aparencia { static let chaveTema = "custta.tema", chavePele = "custta.pele", chaveVidro = "custta.vidro"; static func esquema(_:) -> ColorScheme; static func pele(_:) -> Pele; static func vidro(_:) -> EscolhaDeVidro }`; `enum TelaDoVidro { entrada, app }`; `enum EscolhaDeVidro: String, CaseIterable { transparente, fosco }`; `enum NivelDeVidro { transparente, fosco, solido }`; `enum PapelDoVidro { cartaoEntrada, segmentado, conteudo, navegacao }`; `struct OpcoesDoAparelho: Equatable { var reduzirMovimento, reduzirTransparencia, aumentarContraste, poucaEnergia: Bool; var animaFundo: Bool }`; `struct VidroTokens: Equatable { let nivel: NivelDeVidro; let contorno: Bool; static func para(tela:escolha:opcoes:) -> VidroTokens; func tinta(_:escuro:) -> Double; func corDaTinta(_:) -> Token; var secundario: Token; var link: Token }`; `EnvironmentValues.opcoes`, `EnvironmentValues.vidro`; `View.superficie(_ papel: PapelDoVidro, em forma: some InsettableShape) -> some View`; image sets `Icones/predio`, `engrenagem`, `sair`, `guindaste`, `casa`, `check`, `olho`, `olhoFechado`, `setaBaixo`. Em Node, `scripts/cores-app-ios.mjs` exporta `CORES`, `colorSet(valores)` e `arquivos()`; `scripts/icones-app-ios.mjs` exporta `USADOS`, `svg(nome)` e `arquivos()`.

As cores vêm do `styles.css` nos quatro combos e, para o que o mockup aprovado decidiu, da tabela "Tokens de vidro, agora por tela" do `final.html`: texto secundário, link e erro sobre o vidro por nível, contorno do "Aumentar contraste", tintas do vidro por papel, aurora, globo, o realce do logo e as cores fixas do botão do Google. Valor com transparência vai como `#RRGGBBAA`. Os ícones são os traços do `icons.js` do site, só os que as telas usam.

- [ ] **Step 1: Escrever os testes que falham**

`app-ios/CusttaTests/CoresTests.swift`:

```swift
import Testing
import UIKit
import SwiftUI
@testable import Custta

/* Cores só por tokens: cada token existe nas duas peles, com variante clara e escura; os de fundo e de
   texto mudam entre claro e escuro. */
@MainActor
struct CoresTests {
    @Test(arguments: Pele.allCases)
    func todoTokenExisteNaPele(_ pele: Pele) {
        for token in Token.allCases {
            let nome = Paleta.nome(token, pele)
            let cor = UIColor(named: nome, in: .main, compatibleWith: nil)
            #expect(cor?.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light)) != nil, "\(nome) sem variante clara")
            #expect(cor?.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark)) != nil, "\(nome) sem variante escura")
        }
    }

    @Test(arguments: Pele.allCases)
    func fundoETextoMudamComOTema(_ pele: Pele) {
        for token in [Token.fundo, .superficie, .texto, .textoSecundario, .marca, .campo] {
            let cor = UIColor(named: Paleta.nome(token, pele), in: .main, compatibleWith: nil)
            #expect(cor?.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
                    != cor?.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark)), "\(token) igual nos dois temas")
        }
    }

    @Test func aparenciaPadraoEscuraEsmeraldaTransparente() {
        #expect(Aparencia.esquema("qualquer") == .dark)
        #expect(Aparencia.esquema("claro") == .light)
        #expect(Aparencia.pele("azul") == .azul && Aparencia.pele("") == .esmeralda)
        #expect(Aparencia.vidro("fosco") == .fosco && Aparencia.vidro("") == .transparente)
    }
}

/* Dose de vidro por tela, do mockup aprovado. */
struct VidroTokensTests {
    @Test func entradaSempreFosco() {
        for escolha in EscolhaDeVidro.allCases {
            #expect(VidroTokens.para(tela: .entrada, escolha: escolha, opcoes: OpcoesDoAparelho()).nivel == .fosco)
        }
    }

    @Test func appSegueAEscolha() {
        #expect(VidroTokens.para(tela: .app, escolha: .transparente, opcoes: OpcoesDoAparelho()).nivel == .transparente)
        #expect(VidroTokens.para(tela: .app, escolha: .fosco, opcoes: OpcoesDoAparelho()).nivel == .fosco)
    }

    @Test func opcoesDoIPhonePassamPorCima() {
        let contraste = VidroTokens.para(tela: .app, escolha: .transparente, opcoes: OpcoesDoAparelho(aumentarContraste: true))
        #expect(contraste.nivel == .fosco && contraste.contorno, "Aumentar contraste: Fosco com contorno")
        let solido = VidroTokens.para(tela: .entrada, escolha: .fosco,
                                      opcoes: OpcoesDoAparelho(reduzirTransparencia: true, aumentarContraste: true))
        #expect(solido.nivel == .solido && !solido.contorno, "Reduzir transparência: superfícies sólidas")
    }

    @Test func tintasDoMockup() {
        let transparente = VidroTokens(nivel: .transparente, contorno: false), fosco = VidroTokens(nivel: .fosco, contorno: false)
        #expect(transparente.tinta(.conteudo, escuro: true) == 0.06 && transparente.tinta(.conteudo, escuro: false) == 0.14)
        #expect(transparente.tinta(.navegacao, escuro: true) == 0.08 && transparente.tinta(.navegacao, escuro: false) == 0.16)
        #expect(fosco.tinta(.cartaoEntrada, escuro: true) == 0.44 && fosco.tinta(.cartaoEntrada, escuro: false) == 0.52)
        #expect(fosco.tinta(.segmentado, escuro: true) == 0.24 && fosco.tinta(.conteudo, escuro: false) == 0.34)
        #expect(fosco.tinta(.navegacao, escuro: true) == 0.22 && fosco.tinta(.navegacao, escuro: false) == 0.36)
    }

    @Test func textoSobreOVidroPorNivel() {
        #expect(VidroTokens(nivel: .transparente, contorno: false).secundario == .secundarioTransparente)
        #expect(VidroTokens(nivel: .fosco, contorno: false).secundario == .secundarioFosco)
        #expect(VidroTokens(nivel: .solido, contorno: false).secundario == .secundarioSolido)
        #expect(VidroTokens(nivel: .transparente, contorno: false).link == .texto, "link solto na cor do texto")
        #expect(VidroTokens(nivel: .fosco, contorno: false).link == .linkNoVidro)
    }

    @Test func fundoSoAndaSemReduzirMovimentoESemPoucaEnergia() {
        #expect(OpcoesDoAparelho().animaFundo)
        #expect(!OpcoesDoAparelho(reduzirMovimento: true).animaFundo)
        #expect(!OpcoesDoAparelho(poucaEnergia: true).animaFundo)
    }
}
```

No fim de `tests/app-ios.test.cjs`:

```js
test('cores só por tokens: nenhuma cor solta no código do app', () => {
  const solta = /\bColor\s*\(\s*(red|hue|white|\.sRGB|\.displayP3|uiColor)\b|\bUIColor\s*\(\s*(red|white|hue|displayP3)\b|#colorLiteral|\bColor\.(red|green|blue|orange|yellow|pink|purple|black|white|gray|brown|cyan|mint|indigo|teal)\b|\.foreground(Style|Color)\(\s*\.(red|green|blue|orange|yellow|pink|purple|black|white|gray)\b/;
  for(const f of arquivosSwift('app-ios/Custta')) assert.doesNotMatch(ler(f), solta, `${f}: use paleta.cor(.token)`);
});

test('catálogo de cores em dia com scripts/cores-app-ios.mjs e com os tokens da Paleta', () => {
  execFileSync(process.execPath, ['scripts/cores-app-ios.mjs', '--conferir'], { cwd: RAIZ, stdio: 'pipe' });
  const paleta = ler('app-ios/Custta/Identidade/Paleta.swift');
  const enumToken = paleta.slice(paleta.indexOf('enum Token'), paleta.indexOf('}', paleta.indexOf('enum Token')));
  const tokens = [...enumToken.matchAll(/case \w+ = "(\w+)"/g)].map(m => m[1]).sort();
  const tabela = ler('scripts/cores-app-ios.mjs');
  for(const pele of ['Esmeralda', 'Azul']){
    const bloco = tabela.slice(tabela.indexOf(`${pele}: {`), tabela.indexOf('}', tabela.indexOf(`${pele}: {`)));
    assert.deepEqual([...bloco.matchAll(/^\s+(\w+): \['/gm)].map(m => m[1]).sort(), tokens, `tokens da pele ${pele}`);
  }
});

test('aurora nas mesmas cores do site, nos quatro combos', async () => {
  const { CORES } = await import(join(RAIZ, 'scripts/cores-app-ios.mjs'));
  const css = ler('styles.css');
  const combos = { Esmeralda: [':root{', 'html[data-theme="light"]{'], Azul: ['html[data-skin="azul"]{', 'html[data-skin="azul"][data-theme="light"]{'] };
  const hex = rgb => '#' + rgb.split(',').map(n => Number(n).toString(16).padStart(2, '0').toUpperCase()).join('');
  for(const [pele, [escuro, claro]] of Object.entries(combos)){
    for(const [lado, seletor] of [[0, escuro], [1, claro]]){
      const bloco = css.slice(css.indexOf(seletor + '\n    --aurora-1'));
      for(const n of [1, 2, 3, 4])
        assert.equal(CORES[pele][`Aurora${n}`][lado], hex(bloco.match(new RegExp(`--aurora-${n}:([\\d,]+);`))[1]), `${pele} Aurora${n}`);
    }
  }
});

test('ícones em dia com o icons.js do site', () => {
  execFileSync(process.execPath, ['scripts/icones-app-ios.mjs', '--conferir'], { cwd: RAIZ, stdio: 'pipe' });
});
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `node --test tests/app-ios.test.cjs`
Expected: FAIL nos testes do catálogo e dos ícones: `Cannot find module '…/scripts/cores-app-ios.mjs'`.

Run: `xcodebuild test -project app-ios/Custta.xcodeproj -scheme Custta -destination "$(node scripts/simulador-ios.mjs)" -skipMacroValidation -skipPackagePluginValidation -onlyUsePackageVersionsFromResolvedFile CODE_SIGNING_ALLOWED=NO -only-testing:CusttaTests/CoresTests -only-testing:CusttaTests/VidroTokensTests`
Expected: FAIL na compilação: `cannot find type 'Pele' in scope`.

- [ ] **Step 3: Escrever os geradores e gravar o catálogo**

`scripts/cores-app-ios.mjs`:

```js
/* Cores do app nativo por token (spec, seção 8: "cores só por tokens"). A tabela abaixo é a
   fonte e o script grava os color sets do catálogo app-ios/Custta/Assets.xcassets: um por token
   e pele, com variante clara e escura, mais a cor de destaque do sistema e o fundo da abertura.
   Valores: os do styles.css do site nos quatro combos (escuro e claro, esmeralda e azul) e os do
   mockup aprovado da etapa 1 (~/Documents/custta-mockups/nativo/etapa1/final.html: tons de texto
   sobre o vidro, contorno do "Aumentar contraste", tintas do vidro e aurora). Mudança de cor é
   aqui, nunca no catálogo à mão. tests/app-ios.test.cjs roda --conferir.

   Uso: node scripts/cores-app-ios.mjs            grava o catálogo
        node scripts/cores-app-ios.mjs --conferir  só confere (sai com 1 se algo difere) */
import { mkdirSync, writeFileSync, readFileSync, existsSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const CATALOGO = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../app-ios/Custta/Assets.xcassets');

/* token: [escuro, claro], por pele; '#RRGGBB' ou '#RRGGBBAA'. Origem no styles.css (:root,
   [data-theme="light"], [data-skin="azul"] e os dois juntos) e no final.html. */
export const CORES = {
  Esmeralda: {
    Fundo: ['#04100C', '#EDF5F1'],                  // --bg
    Superficie: ['#0C241D', '#FFFFFF'],             // --surface-solid: vidro com "Reduzir transparência"
    Linha: ['#1B3D33', '#C6DCD1'],                  // --line
    Texto: ['#EAFFF6', '#13261E'],                  // --text
    TextoSecundario: ['#86AA9A', '#4D685C'],        // --muted
    TextoTerciario: ['#64887A', '#5F7A6D'],         // "(opcional)" nos rótulos
    Marca: ['#14B39A', '#0B7A68'],                  // --brand
    Destaque: ['#3AD17E', '#177A4A'],               // --accent
    Positivo: ['#35D68A', '#0E7A41'],               // --profit; fase vendida
    PositivoFundo: ['#0C2F1E', '#D7F2E2'],
    Alerta: ['#E0A83A', '#8A5A06'],                 // --warn; fase em construção
    AlertaFundo: ['#33260F', '#F5ECD2'],
    Informacao: ['#3AA0E0', '#1C68A0'],             // fase pronta
    InformacaoFundo: ['#0E2735', '#DCEBF7'],
    Negativo: ['#FB7185', '#C22E55'],               // --red
    SobreMarca: ['#04100C', '#FFFFFF'],             // --btn-ink: texto do botão principal
    Tinta: ['#14B39A', '#0B7A68'],                  // segmentado escolhido (e o + da etapa 2)
    SobreTinta: ['#04100C', '#FFFFFF'],
    Campo: ['#10322A', '#E2EFE8'],                  // campos sólidos do cartão de entrada
    CampoBorda: ['#1B3D33', '#C6DCD1'],
    FantasmaFundo: ['#0A3F30', '#D6F0E7'],          // botão secundário ("Reenviar link", "Sair da conta")
    FantasmaTexto: ['#8FE8D5', '#096453'],
    SecundarioFosco: ['#B8D4C7', '#3B574B'],        // texto secundário sobre o Fosco (entrada e opção)
    SecundarioTransparente: ['#D6E8E0', '#2B463B'], // sobre o Transparente corrigido
    SecundarioSolido: ['#9DBDAF', '#4D685C'],       // sobre a superfície sólida
    LinkNoVidro: ['#8FE8D5', '#075243'],            // link e aba ativa sobre o vidro
    ErroNoVidro: ['#FFA3B3', '#A3153F'],
    Contorno: ['#EAFFF68C', '#13261E73'],           // "Aumentar contraste": 1,5 pt em volta do vidro
    LenteAba: ['#FFFFFF1C', '#142B2312'],           // fundo da aba escolhida na cápsula
    TintaConteudo: ['#061611', '#FFFFFF'],          // vidro dos cartões e painéis
    TintaCartao: ['#0A1E18', '#FAFDFB'],            // vidro do cartão de entrada
    TintaNavegacao: ['#081A14', '#F6FAF8'],         // vidro da cápsula, do sair e da sincronização
    Aurora1: ['#10B9A0', '#14B39A'],
    Aurora2: ['#28C86E', '#3AD17E'],
    Aurora3: ['#085A96', '#3C96C8'],
    Aurora4: ['#78EBC3', '#96F0D2'],
    RealceLogo: ['#B8F5D2', '#0B7A68'],             // início do degradê do "tt." no escuro
    SombraDoTexto: ['#00000059', '#00000000'],      // --sombra-txt: texto solto sobre a aurora (só no escuro)
    GoogleFundo: ['#131314', '#FFFFFF'],            // regras do botão do Google, iguais nas duas peles
    GoogleBorda: ['#8E918F', '#747775'],
    GoogleTexto: ['#E3E3E3', '#1F1F1F'],
    GloboTerra: ['#14B39A', '#14B39A'],             // globe.js: o claro usa o mesmo, com o globo a 40%
    GloboBrilho: ['#A8FFE0', '#A8FFE0'],
    GloboOceano: ['#0F7C6A', '#0F7C6A'],
    GloboHalo: ['#14B39A', '#14B39A'],
    GloboAro: ['#3AD17E', '#3AD17E'],
  },
  Azul: {
    Fundo: ['#070C18', '#EEF2F9'],
    Superficie: ['#111A2E', '#FFFFFF'],
    Linha: ['#243250', '#CDD8E8'],
    Texto: ['#EEF4FB', '#16233C'],
    TextoSecundario: ['#A3B4CA', '#556685'],
    TextoTerciario: ['#6E82A0', '#617594'],
    Marca: ['#5B8CFF', '#3560CF'],
    Destaque: ['#A78BFA', '#6D4FC9'],
    Positivo: ['#4ADE80', '#0E7A41'],
    PositivoFundo: ['#0C2B1C', '#D7F2E2'],
    Alerta: ['#FBBF24', '#8A5A06'],
    AlertaFundo: ['#33280F', '#F8ECC9'],
    Informacao: ['#60A5FA', '#2A63C4'],
    InformacaoFundo: ['#122238', '#DCE9FA'],
    Negativo: ['#FB7185', '#C22E55'],
    SobreMarca: ['#070C18', '#FFFFFF'],
    Tinta: ['#3B6CF0', '#3560CF'],
    SobreTinta: ['#FFFFFF', '#FFFFFF'],
    Campo: ['#182338', '#E7EDF7'],
    CampoBorda: ['#243250', '#CDD8E8'],
    FantasmaFundo: ['#16244A', '#DDE7FB'],
    FantasmaTexto: ['#A8C2FF', '#2B4FB0'],
    SecundarioFosco: ['#C4D1E3', '#36445F'],
    SecundarioTransparente: ['#DCE4F0', '#26324A'],
    SecundarioSolido: ['#A3B4CA', '#556685'],
    LinkNoVidro: ['#A8C2FF', '#223F92'],
    ErroNoVidro: ['#FFA3B3', '#A3153F'],
    Contorno: ['#EEF4FB8C', '#16233C73'],
    LenteAba: ['#FFFFFF1C', '#172B4D12'],
    TintaConteudo: ['#080C1C', '#FFFFFF'],
    TintaCartao: ['#0E1628', '#FBFCFF'],
    TintaNavegacao: ['#0A1020', '#F7F9FD'],
    Aurora1: ['#3B6CF0', '#3B6CF0'],
    Aurora2: ['#6E96FF', '#608CFF'],
    Aurora3: ['#6E32C8', '#8C5ADC'],
    Aurora4: ['#78D2FF', '#96D2FF'],
    RealceLogo: ['#D4E0FF', '#3560CF'],
    SombraDoTexto: ['#00000059', '#00000000'],
    GoogleFundo: ['#131314', '#FFFFFF'],
    GoogleBorda: ['#8E918F', '#747775'],
    GoogleTexto: ['#E3E3E3', '#1F1F1F'],
    GloboTerra: ['#608CFF', '#608CFF'],
    GloboBrilho: ['#A0C4FF', '#A0C4FF'],
    GloboOceano: ['#4E72E0', '#4E72E0'],
    GloboHalo: ['#3A64F5', '#3A64F5'],
    GloboAro: ['#648CFF', '#648CFF'],
  },
};

const info = { author: 'xcode', version: 1 };
const componente = hex => ({ 'color-space': 'srgb',
  components: { red: '0x' + hex.slice(1, 3), green: '0x' + hex.slice(3, 5), blue: '0x' + hex.slice(5, 7),
    alpha: hex.length === 9 ? (parseInt(hex.slice(7, 9), 16) / 255).toFixed(3) : '1.000' } });

/** Color set com a variante clara (padrão) e a escura. */
export function colorSet([escuro, claro]){
  return { colors: [
    { idiom: 'universal', color: componente(claro) },
    { idiom: 'universal', appearances: [{ appearance: 'luminosity', value: 'dark' }], color: componente(escuro) },
  ], info };
}

/** Arquivos do catálogo que a tabela define: caminho relativo → texto. */
export function arquivos(){
  const json = o => JSON.stringify(o, null, 2) + '\n';
  const r = {};
  for(const [pele, tokens] of Object.entries(CORES)){
    r[`${pele}/Contents.json`] = json({ info, properties: { 'provides-namespace': true } });
    for(const [token, valores] of Object.entries(tokens)) r[`${pele}/${token}.colorset/Contents.json`] = json(colorSet(valores));
  }
  // Destaque dos controles do sistema antes da paleta valer, e o fundo da abertura (escuro, sem clarão).
  r['AccentColor.colorset/Contents.json'] = json(colorSet(CORES.Esmeralda.Marca));
  r['FundoAbertura.colorset/Contents.json'] = json({ colors: [{ idiom: 'universal', color: componente(CORES.Esmeralda.Fundo[0]) }], info });
  return r;
}

if(process.argv[1] === fileURLToPath(import.meta.url)){
  const conferir = process.argv.includes('--conferir');
  const diferentes = [];
  for(const [rel, texto] of Object.entries(arquivos())){
    const destino = path.join(CATALOGO, rel);
    if(conferir){
      if(!existsSync(destino) || readFileSync(destino, 'utf8') !== texto) diferentes.push(rel);
      continue;
    }
    mkdirSync(path.dirname(destino), { recursive: true });
    writeFileSync(destino, texto);
  }
  if(diferentes.length){
    console.error('catálogo de cores defasado; rode node scripts/cores-app-ios.mjs:\n' + diferentes.join('\n'));
    process.exit(1);
  }
  console.log(conferir ? 'ok - catálogo de cores em dia' : 'cores gravadas em app-ios/Custta/Assets.xcassets');
}
```

`scripts/icones-app-ios.mjs`:

```js
/* Ícones do app nativo: os mesmos traços do icons.js do site (decisão do mockup aprovado: "os
   ícones do PWA viram símbolos próprios no asset catalog"). O script grava um image set vetorial
   por ícone em app-ios/Custta/Assets.xcassets/Icones, como molde (template): a cor vem da tela,
   por token. Ícone novo no app entra na lista USADOS. tests/app-ios.test.cjs roda --conferir.

   Uso: node scripts/icones-app-ios.mjs            grava o catálogo
        node scripts/icones-app-ios.mjs --conferir  só confere (sai com 1 se algo difere) */
import { mkdirSync, writeFileSync, readFileSync, existsSync } from 'node:fs';
import path from 'node:path';
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';

const require = createRequire(import.meta.url);
const { ICONES } = require('../icons.js');
const PASTA = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../app-ios/Custta/Assets.xcassets/Icones');

/** Ícones que as telas usam: abas, fases da obra, sair, olho da senha e a seta da dica. */
export const USADOS = ['predio', 'engrenagem', 'sair', 'guindaste', 'casa', 'check', 'olho', 'olhoFechado', 'setaBaixo'];

const info = { author: 'xcode', version: 1 };

/** O SVG do ícone, com o traço do ICON() do site (24 × 24, linha 2, pontas redondas). */
export function svg(nome){
  if(!ICONES[nome]) throw new Error(`ícone ${nome} não existe no icons.js`);
  return '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#000" '
    + `stroke-width="2" stroke-linecap="round" stroke-linejoin="round">${ICONES[nome]}</svg>\n`;
}

/** Arquivos do catálogo: caminho relativo à pasta Icones → texto. */
export function arquivos(){
  const json = o => JSON.stringify(o, null, 2) + '\n';
  const r = { 'Contents.json': json({ info, properties: { 'provides-namespace': true } }) };
  for(const nome of USADOS){
    r[`${nome}.imageset/${nome}.svg`] = svg(nome);
    r[`${nome}.imageset/Contents.json`] = json({ images: [{ filename: `${nome}.svg`, idiom: 'universal' }], info,
      properties: { 'preserves-vector-representation': true, 'template-rendering-intent': 'template' } });
  }
  return r;
}

if(process.argv[1] === fileURLToPath(import.meta.url)){
  const conferir = process.argv.includes('--conferir');
  const diferentes = [];
  for(const [rel, texto] of Object.entries(arquivos())){
    const destino = path.join(PASTA, rel);
    if(conferir){
      if(!existsSync(destino) || readFileSync(destino, 'utf8') !== texto) diferentes.push(rel);
      continue;
    }
    mkdirSync(path.dirname(destino), { recursive: true });
    writeFileSync(destino, texto);
  }
  if(diferentes.length){
    console.error('ícones defasados; rode node scripts/icones-app-ios.mjs:\n' + diferentes.join('\n'));
    process.exit(1);
  }
  console.log(conferir ? 'ok - ícones em dia' : 'ícones gravados em app-ios/Custta/Assets.xcassets/Icones');
}
```

Run: `node scripts/cores-app-ios.mjs && node scripts/icones-app-ios.mjs`
Expected: `cores gravadas em app-ios/Custta/Assets.xcassets` e `ícones gravados em app-ios/Custta/Assets.xcassets/Icones`; `git status` mostra as pastas `Esmeralda/`, `Azul/` e `Icones/` novas e o `AccentColor` e o `FundoAbertura` reformatados (mesmos valores).

- [ ] **Step 4: Escrever a paleta e o vidro**

`app-ios/Custta/Identidade/Paleta.swift`:

```swift
import SwiftUI

/* Cores só por tokens (spec, seção 8): cada token existe no Assets.xcassets para as duas peles
   (Esmeralda e Azul), com variante clara e escura, gerado por scripts/cores-app-ios.mjs.
   Nenhuma cor solta nas telas (componentes RGB ou cor nomeada do sistema): tests/app-ios.test.cjs confere. */

enum Pele: String, CaseIterable, Sendable {
    case esmeralda = "Esmeralda"
    case azul = "Azul"
}

enum Token: String, CaseIterable, Sendable {
    case fundo = "Fundo"
    case superficie = "Superficie"
    case linha = "Linha"
    case texto = "Texto"
    case textoSecundario = "TextoSecundario"
    case textoTerciario = "TextoTerciario"
    case marca = "Marca"
    case destaque = "Destaque"
    case positivo = "Positivo"
    case positivoFundo = "PositivoFundo"
    case alerta = "Alerta"
    case alertaFundo = "AlertaFundo"
    case informacao = "Informacao"
    case informacaoFundo = "InformacaoFundo"
    case negativo = "Negativo"
    /// Texto sobre a cor da marca (o --btn-ink do site): escuro no tema escuro, branco no claro.
    case sobreMarca = "SobreMarca"
    case tinta = "Tinta"
    case sobreTinta = "SobreTinta"
    case campo = "Campo"
    case campoBorda = "CampoBorda"
    case fantasmaFundo = "FantasmaFundo"
    case fantasmaTexto = "FantasmaTexto"
    case secundarioFosco = "SecundarioFosco"
    case secundarioTransparente = "SecundarioTransparente"
    case secundarioSolido = "SecundarioSolido"
    case linkNoVidro = "LinkNoVidro"
    case erroNoVidro = "ErroNoVidro"
    case contorno = "Contorno"
    case lenteAba = "LenteAba"
    case tintaConteudo = "TintaConteudo"
    case tintaCartao = "TintaCartao"
    case tintaNavegacao = "TintaNavegacao"
    case aurora1 = "Aurora1"
    case aurora2 = "Aurora2"
    case aurora3 = "Aurora3"
    case aurora4 = "Aurora4"
    case realceLogo = "RealceLogo"
    case sombraDoTexto = "SombraDoTexto"
    case googleFundo = "GoogleFundo"
    case googleBorda = "GoogleBorda"
    case googleTexto = "GoogleTexto"
    case globoTerra = "GloboTerra"
    case globoBrilho = "GloboBrilho"
    case globoOceano = "GloboOceano"
    case globoHalo = "GloboHalo"
    case globoAro = "GloboAro"
}

struct Paleta: Equatable, Sendable {
    var pele: Pele = .esmeralda

    /// Nome no catálogo: "Esmeralda/Marca".
    static func nome(_ token: Token, _ pele: Pele) -> String { "\(pele.rawValue)/\(token.rawValue)" }

    func cor(_ token: Token) -> Color { Color(Self.nome(token, pele)) }
}

extension EnvironmentValues {
    @Entry var paleta = Paleta()
}

/// Aparência deste aparelho: escuro, esmeralda e vidro Transparente por padrão. A tela de Ajustes da
/// etapa 5 grava as três chaves; os testes de tela passam `-custta.tema claro -custta.pele azul -custta.vidro fosco`.
enum Aparencia {
    static let chaveTema = "custta.tema"
    static let chavePele = "custta.pele"
    static let chaveVidro = "custta.vidro"
    static func esquema(_ tema: String) -> ColorScheme { tema == "claro" ? .light : .dark }
    static func pele(_ valor: String) -> Pele { valor == "azul" ? .azul : .esmeralda }
    static func vidro(_ valor: String) -> EscolhaDeVidro { valor == "fosco" ? .fosco : .transparente }
}
```

`app-ios/Custta/Identidade/Vidro.swift`:

```swift
import SwiftUI

/* Dose de vidro por tela (decisão do Giovani em 06/10; mockup aprovado, "Tokens de vidro, agora por
   tela"): entrar, criar conta e falta pouco usam sempre o Fosco; as telas do app, o Transparente
   (padrão) ou o Fosco escolhido em Ajustes › Aparência (etapa 5). As opções do iPhone passam por
   cima das duas: "Aumentar contraste" leva tudo ao Fosco com contorno de 1,5 pt e "Reduzir
   transparência", a superfícies sólidas (a aurora continua). Aro especular, sombra e refração são
   do glassEffect do sistema. Nunca vidro dentro de vidro: o que fica dentro de uma superfície é sólido. */

enum TelaDoVidro: Sendable { case entrada, app }

/// A escolha de Ajustes › Aparência (etapa 5); até lá vale o padrão, Transparente.
enum EscolhaDeVidro: String, CaseIterable, Sendable { case transparente, fosco }

/// O nível que vale de fato, depois das opções do iPhone.
enum NivelDeVidro: Sendable { case transparente, fosco, solido }

/// O papel de cada superfície: a tinta muda com ele.
enum PapelDoVidro: Sendable {
    /// O cartão de entrar, criar conta e falta pouco.
    case cartaoEntrada
    /// "Entrar | Criar conta", fora do cartão.
    case segmentado
    /// Cartões e painéis das telas do app.
    case conteudo
    /// Cápsula de abas, sair e sincronização.
    case navegacao
}

/// As opções do iPhone que mudam o visual, lidas uma vez na raiz. Em Debug, os testes de tela ligam
/// cada uma por argumento (`-custta.reduzirMovimento YES`), porque o XCUITest não muda os ajustes do sistema.
struct OpcoesDoAparelho: Equatable, Sendable {
    var reduzirMovimento = false
    var reduzirTransparencia = false
    var aumentarContraste = false
    /// Modo de Pouca Energia: aurora, globo e logo param, como com Reduzir movimento.
    var poucaEnergia = false

    /// Animação própria (aurora, globo, logo, cartão que se endireita) só sem os dois.
    var animaFundo: Bool { !reduzirMovimento && !poucaEnergia }
}

struct VidroTokens: Equatable, Sendable {
    let nivel: NivelDeVidro
    let contorno: Bool

    static func para(tela: TelaDoVidro, escolha: EscolhaDeVidro, opcoes: OpcoesDoAparelho) -> VidroTokens {
        if opcoes.reduzirTransparencia { return VidroTokens(nivel: .solido, contorno: false) }
        let fosco = tela == .entrada || escolha == .fosco || opcoes.aumentarContraste
        return VidroTokens(nivel: fosco ? .fosco : .transparente, contorno: opcoes.aumentarContraste)
    }

    /// Opacidade da tinta sobre o vidro, do mockup aprovado.
    func tinta(_ papel: PapelDoVidro, escuro: Bool) -> Double {
        switch (nivel, papel) {
        case (.solido, _): return 1
        case (.fosco, .cartaoEntrada): return escuro ? 0.44 : 0.52
        case (.fosco, .segmentado), (.fosco, .conteudo): return escuro ? 0.24 : 0.34
        case (.fosco, .navegacao): return escuro ? 0.22 : 0.36
        case (.transparente, .navegacao): return escuro ? 0.08 : 0.16
        case (.transparente, _): return escuro ? 0.06 : 0.14
        }
    }

    func corDaTinta(_ papel: PapelDoVidro) -> Token {
        switch papel {
        case .cartaoEntrada: return .tintaCartao
        case .segmentado, .conteudo: return .tintaConteudo
        case .navegacao: return .tintaNavegacao
        }
    }

    /// Texto secundário sobre a superfície (o --muted do site não fecha 4,5:1 sobre o vidro).
    var secundario: Token {
        switch nivel {
        case .transparente: return .secundarioTransparente
        case .fosco: return .secundarioFosco
        case .solido: return .secundarioSolido
        }
    }

    /// Link solto: no Transparente, a cor do texto com sublinhado da marca; nos outros, a cor do link sobre o vidro.
    var link: Token { nivel == .transparente ? .texto : .linkNoVidro }
}

extension EnvironmentValues {
    @Entry var opcoes = OpcoesDoAparelho()
    @Entry var vidro = VidroTokens.para(tela: .app, escolha: .transparente, opcoes: OpcoesDoAparelho())
}

/// Superfície de vidro (ou sólida) no papel dado, com a tinta, o material e o contorno do nível.
struct Superficie<Forma: InsettableShape>: ViewModifier {
    let papel: PapelDoVidro
    let forma: Forma
    @Environment(\.vidro) private var vidro
    @Environment(\.paleta) private var paleta
    @Environment(\.colorScheme) private var esquema

    func body(content: Content) -> some View {
        let tinta = paleta.cor(vidro.corDaTinta(papel)).opacity(vidro.tinta(papel, escuro: esquema == .dark))
        Group {
            switch vidro.nivel {
            case .solido: content.background(paleta.cor(.superficie), in: forma)
            case .fosco: content.glassEffect(.regular.tint(tinta), in: forma)
            case .transparente: content.glassEffect(.clear.tint(tinta), in: forma)
            }
        }
        .overlay {
            if vidro.contorno { forma.strokeBorder(paleta.cor(.contorno), lineWidth: 1.5) }
        }
    }
}

extension View {
    func superficie<Forma: InsettableShape>(_ papel: PapelDoVidro, em forma: Forma) -> some View {
        modifier(Superficie(papel: papel, forma: forma))
    }
}
```

- [ ] **Step 5: Rodar e ver passar**

Run: `node --test tests/app-ios.test.cjs`
Expected: todos verdes, inclusive "catálogo de cores em dia", "aurora nas mesmas cores do site" e "ícones em dia".

Run: o `xcodebuild test` do Step 2.
Expected: `CoresTests` (5 casos) e `VidroTokensTests` (6) verdes.

- [ ] **Step 6: Commit**

```bash
git add scripts/cores-app-ios.mjs scripts/icones-app-ios.mjs app-ios/Custta/Assets.xcassets app-ios/Custta/Identidade app-ios/CusttaTests/CoresTests.swift tests/app-ios.test.cjs
git commit -m "feat: cores, vidro e ícones do app nativo por tokens" -m "As cores dos quatro combos do site e as do mockup aprovado (texto sobre o vidro por nível, contorno do Aumentar contraste, tintas do vidro, aurora, globo e botão do Google) viram color sets gerados por scripts/cores-app-ios.mjs, e os ícones do icons.js viram image sets vetoriais em molde. VidroTokens decide a dose por tela: a entrada sempre no Fosco, o app no Transparente ou no Fosco escolhido, o Aumentar contraste no Fosco com contorno e o Reduzir transparência em superfícies sólidas; toda superfície passa por .superficie(_:em:). As guardas barram cor solta nas telas, catálogo defasado e aurora ou ícone diferente do site."
```

---

### Task 4: Fundo com aurora e globo

**Files:**
- Create: `app-ios/Custta/Identidade/Movimento.swift`, `app-ios/Custta/Identidade/Aurora.swift`, `app-ios/Custta/Identidade/Globo.swift`
- Modify: `app-ios/Custta/CusttaApp.swift` (a abertura com a aurora e o globo no lugar do texto da Tarefa 1)
- Modify: `app-ios/CusttaUITests/AberturaUITests.swift`
- Test: `app-ios/CusttaTests/FundoTests.swift`
- Modify: `tests/app-ios.test.cjs` (dois testes no fim)

**Interfaces:**
- Consumes: `Paleta`, `Token` (`aurora1`…`aurora4`, `fundo`, `globo*`), `TelaDoVidro`, `Pele`, `OpcoesDoAparelho` (Tarefa 3); `#aurora` do `styles.css` e `globe.js` do site.
- Produces: `struct TempoPausavel: Equatable { mutating func rodar(em:); mutating func parar(em:); func segundos(em:) -> TimeInterval }`; `struct CurvaBezier { init(x1:y1:x2:y2:); static let suave; func y(_:) -> Double }`; `@MainActor @Observable final class Rolagem { var rolando: Bool; func mudou(_: ScrollPhase) }`; `EnvironmentValues.rolagem: Rolagem?`; `View.pausaOFundoAoRolar()`; `struct RelogioDoFundo<Conteudo: View>: View { init(rodando:conteudo:) }`; `enum Aurora { static func intensidade(tela:pele:escuro:) -> Double; static func transicao(paraOApp:) -> Animation }`; `struct Deriva: Equatable { x, y, giro, escala; static let quadros; static func em(segundos:) -> Deriva }`; `struct FundoAurora: View { init(intensidade: Double, animada: Bool, deslocamento: TimeInterval = 0) }`; `struct CamadaAurora: View, Animatable, Equatable`; `struct HaloDoTitulo: View { init(grande: Bool) }`; `enum PontosDoGlobo { static let continentes; static func ehTerra(_:_:) -> Bool; static let todos: (terra: [SIMD3<Double>], oceano: [SIMD3<Double>]) }`; `struct Globo: View { init(animado: Bool) }`; `struct AberturaView: View` (em `CusttaApp.swift`).

A aurora é a do `#aurora` do site, ponto por ponto: quatro brilhos elípticos e o degradê de 100° numa camada 60% mais larga e 30% mais alta que a área visível, que cobre 78% da altura da tela e some para baixo (máscara de 40% a 100%), derivando 26 s de ida e 26 de volta pelos três quadros do `@keyframes aurora-deriva`. A camada é desenhada a um terço do tamanho e ampliada (degradê liso não perde nada) e só redesenha quando a cor ou a intensidade mudam; a deriva só a move. O globo é o do `globe.js`: mesmos continentes, mesma grade de 2,2°, mesmo centro, raio, halo, aro, cores e giro, a 30 quadros por segundo, com os pontos agrupados em dez faixas de profundidade. Os dois param com Reduzir movimento e no Modo de Pouca Energia (quem chama passa `animada: false`), durante a rolagem (a tela chama `.pausaOFundoAoRolar()`) e fora da tela, sem pular ao voltar (`TempoPausavel`). O halo atrás do título é desenhado aqui e usado na Tarefa 10.

- [ ] **Step 1: Escrever os testes que falham**

`app-ios/CusttaTests/FundoTests.swift`:

```swift
import Foundation
import Testing
@testable import Custta

/* O tempo do fundo e as curvas do CSS. */
struct MovimentoTests {
    @Test func tempoSoCorreRodando() {
        let t0 = Date(timeIntervalSince1970: 1000)
        var tempo = TempoPausavel()
        #expect(tempo.segundos(em: t0) == 0)
        tempo.rodar(em: t0)
        #expect(tempo.segundos(em: t0.addingTimeInterval(2)) == 2)
        tempo.parar(em: t0.addingTimeInterval(3))
        #expect(tempo.segundos(em: t0.addingTimeInterval(60)) == 3, "parado não anda")
        tempo.rodar(em: t0.addingTimeInterval(60))
        #expect(tempo.segundos(em: t0.addingTimeInterval(61)) == 4, "volta de onde parou, sem pular")
    }

    @Test func curvasDoCSS() {
        #expect(CurvaBezier.suave.y(0) == 0 && CurvaBezier.suave.y(1) == 1)
        #expect(abs(CurvaBezier.suave.y(0.5) - 0.5) < 1e-6, "ease-in-out é simétrica")
        #expect(CurvaBezier.suave.y(0.25) < 0.25, "começa devagar")
        let carimbo = CurvaBezier(x1: 0.3, y1: 1.6, x2: 0.5, y2: 1)
        #expect((0..<100).map { carimbo.y(Double($0) / 100) }.max()! > 1, "o carimbo do ponto passa do tamanho e volta")
    }
}

/* A aurora e o globo do PWA. */
struct FundoTests {
    @Test func intensidadeDaAuroraPorTela() {
        #expect(Aurora.intensidade(tela: .entrada, pele: .esmeralda, escuro: true) == 0.92)
        #expect(Aurora.intensidade(tela: .entrada, pele: .azul, escuro: true) == 1)
        #expect(Aurora.intensidade(tela: .app, pele: .esmeralda, escuro: true) == 0.48)
        #expect(Aurora.intensidade(tela: .app, pele: .azul, escuro: true) == 0.52)
        for tela in [TelaDoVidro.entrada, .app] {
            #expect(Aurora.intensidade(tela: tela, pele: .esmeralda, escuro: false) == 0.55)
            #expect(Aurora.intensidade(tela: tela, pele: .azul, escuro: false) == 0.52)
        }
    }

    @Test func derivaPassaPelosQuadrosDoSiteEVolta() {
        func perto(_ a: Deriva, _ b: Deriva) -> Bool {
            abs(a.x - b.x) < 1e-9 && abs(a.y - b.y) < 1e-9 && abs(a.giro - b.giro) < 1e-9 && abs(a.escala - b.escala) < 1e-9
        }
        #expect(perto(Deriva.em(segundos: 0), Deriva.quadros[0]))
        #expect(perto(Deriva.em(segundos: 13), Deriva.quadros[1]))
        #expect(perto(Deriva.em(segundos: 26), Deriva.quadros[2]))
        #expect(perto(Deriva.em(segundos: 39), Deriva.quadros[1]), "na volta passa pelo meio de novo")
        #expect(perto(Deriva.em(segundos: 52), Deriva.quadros[0]), "ciclo de 52 s")
    }

    @Test func globoComTerraEOceano() {
        let pontos = PontosDoGlobo.todos
        #expect(pontos.terra.count > 1000 && pontos.oceano.count > 3000)
        #expect(PontosDoGlobo.ehTerra(-47, -15), "Brasil")
        #expect(!PontosDoGlobo.ehTerra(-30, 0), "Atlântico")
        #expect(PontosDoGlobo.ehTerra(0, -80), "Antártida")
        for p in pontos.terra.prefix(50) { #expect(abs(p.x * p.x + p.y * p.y + p.z * p.z - 1) < 1e-9) }
    }
}
```

No fim de `tests/app-ios.test.cjs`:

```js
test('globo com os mesmos continentes do globe.js', () => {
  const pares = texto => [...texto.matchAll(/\[\s*(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)\s*\]|\(\s*(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)\s*\)/g)]
    .map(m => (m[1] ?? m[3]) + ',' + (m[2] ?? m[4]));
  const js = ler('globe.js'), swift = ler('app-ios/Custta/Identidade/Globo.swift');
  const doSite = pares(js.slice(js.indexOf('const CONTINENTS'), js.indexOf('];', js.indexOf('const CONTINENTS'))));
  const doApp = pares(swift.slice(swift.indexOf('static let continentes'), swift.indexOf('    ]\n', swift.indexOf('static let continentes'))));
  assert.ok(doSite.length > 150);
  assert.deepEqual(doApp, doSite);
});

test('animação própria respeita Reduzir movimento', () => {
  for(const f of arquivosSwift('app-ios/Custta')){
    const t = ler(f);
    if(/withAnimation|\.animation\(|\.transition\(/.test(t))
      assert.match(t, /accessibilityReduceMotion|reduzirMovimento/, `${f}: anima sem olhar o Reduzir movimento`);
  }
});
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `node --test tests/app-ios.test.cjs`
Expected: FAIL em "globo com os mesmos continentes do globe.js": `ENOENT … Globo.swift`.

Run: `xcodebuild test -project app-ios/Custta.xcodeproj -scheme Custta -destination "$(node scripts/simulador-ios.mjs)" -skipMacroValidation -skipPackagePluginValidation -onlyUsePackageVersionsFromResolvedFile CODE_SIGNING_ALLOWED=NO -only-testing:CusttaTests/MovimentoTests -only-testing:CusttaTests/FundoTests`
Expected: FAIL na compilação: `cannot find 'TempoPausavel' in scope`.

- [ ] **Step 3: Implementar o movimento, a aurora e o globo**

`app-ios/Custta/Identidade/Movimento.swift`:

```swift
import SwiftUI
import Observation

/* O que move o fundo (aurora, globo, logo) e quando ele para: com Reduzir movimento e no Modo de
   Pouca Energia (OpcoesDoAparelho.animaFundo), durante a rolagem (volta 400 ms depois de parar, como
   o globe.js) e fora da tela. O tempo da animação só corre enquanto ela roda: pausar e voltar não
   faz a aurora pular. */

/// Tempo que só corre enquanto a animação roda.
struct TempoPausavel: Equatable, Sendable {
    private(set) var acumulado: TimeInterval = 0
    /// Quando o trecho atual começou; nil com a animação parada.
    private(set) var inicio: Date?

    mutating func rodar(em agora: Date) {
        if inicio == nil { inicio = agora }
    }

    mutating func parar(em agora: Date) {
        guard let inicio else { return }
        acumulado += max(0, agora.timeIntervalSince(inicio))
        self.inicio = nil
    }

    func segundos(em agora: Date) -> TimeInterval {
        acumulado + (inicio.map { max(0, agora.timeIntervalSince($0)) } ?? 0)
    }
}

/// cubic-bezier(x1, y1, x2, y2) do CSS: o progresso da animação no instante x (0…1).
struct CurvaBezier: Equatable, Sendable {
    let x1, y1, x2, y2: Double

    static let suave = CurvaBezier(x1: 0.42, y1: 0, x2: 0.58, y2: 1)        // ease-in-out

    init(x1: Double, y1: Double, x2: Double, y2: Double) {
        self.x1 = x1; self.y1 = y1; self.x2 = x2; self.y2 = y2
    }

    private func ponto(_ t: Double, _ a: Double, _ b: Double) -> Double {
        let u = 1 - t
        return 3 * u * u * t * a + 3 * u * t * t * b + t * t * t
    }

    func y(_ x: Double) -> Double {
        if x <= 0 { return 0 }
        if x >= 1 { return 1 }
        var baixo = 0.0, alto = 1.0, t = x
        for _ in 0..<40 {                      // bisseção: x(t) só cresce com t
            let atual = ponto(t, x1, x2)
            if abs(atual - x) < 1e-7 { break }
            if atual < x { baixo = t } else { alto = t }
            t = (baixo + alto) / 2
        }
        return ponto(t, y1, y2)
    }
}

/// Rolagem em andamento: o fundo pausa já e só volta 400 ms depois de a rolagem parar.
@MainActor @Observable
final class Rolagem {
    private(set) var rolando = false
    @ObservationIgnored private var retomada: Task<Void, Never>?

    func mudou(_ fase: ScrollPhase) {
        retomada?.cancel()
        if fase != .idle {
            rolando = true
            return
        }
        retomada = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }
            self?.rolando = false
        }
    }
}

extension EnvironmentValues {
    @Entry var rolagem: Rolagem?
}

extension View {
    /// A tela avisa o fundo quando rola (ScrollView ou List).
    func pausaOFundoAoRolar() -> some View { modifier(AvisaRolagem()) }
}

private struct AvisaRolagem: ViewModifier {
    @Environment(\.rolagem) private var rolagem

    func body(content: Content) -> some View {
        content.onScrollPhaseChange { _, fase in rolagem?.mudou(fase) }
    }
}

/// Relógio de uma animação do fundo: corre com `rodando` e para sem pular. Quem usa passa `rodando` já
/// com `opcoes.reduzirMovimento`, a Pouca Energia e a rolagem descontados (OpcoesDoAparelho.animaFundo).
struct RelogioDoFundo<Conteudo: View>: View {
    let rodando: Bool
    @ViewBuilder let conteudo: (TimeInterval) -> Conteudo
    @State private var tempo = TempoPausavel()

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: !rodando)) { contexto in
            conteudo(tempo.segundos(em: contexto.date))
        }
        .onAppear { if rodando { tempo.rodar(em: .now) } }
        .onDisappear { tempo.parar(em: .now) }
        .onChange(of: rodando) { _, roda in
            if roda { tempo.rodar(em: .now) } else { tempo.parar(em: .now) }
        }
    }
}
```

`app-ios/Custta/Identidade/Aurora.swift`:

```swift
import SwiftUI

/* A aurora do PWA (#aurora do styles.css) em SwiftUI: quatro brilhos elípticos e um degradê de base
   nas cores do skin, numa camada maior que a área visível (−15% em cima e embaixo, −30% dos lados)
   que deriva devagar (26 s de ida e 26 de volta). Cobre 78% da altura da tela, passa por trás da
   barra de status e some para baixo. A camada só é redesenhada quando a cor ou a intensidade mudam;
   a deriva só a move, então o quadro custa uma transformação. */

enum Aurora {
    /// Intensidade do mockup aprovado: a de hoje na entrada, a funda dentro do app (no escuro); no claro,
    /// a do site nas duas.
    static func intensidade(tela: TelaDoVidro, pele: Pele, escuro: Bool) -> Double {
        switch (escuro, tela, pele) {
        case (false, _, .esmeralda): return 0.55
        case (false, _, .azul): return 0.52
        case (true, .entrada, .esmeralda): return 0.92
        case (true, .entrada, .azul): return 1
        case (true, .app, .esmeralda): return 0.48
        case (true, .app, .azul): return 0.52
        }
    }

    /// Ao entrar a aurora assenta em 0,9 s; ao sair, clareia em 0,6 s (curva suave de saída).
    static func transicao(paraOApp: Bool) -> Animation {
        .timingCurve(0.2, 0.8, 0.2, 1, duration: paraOApp ? 0.9 : 0.6)
    }
}

/// Um quadro da deriva (keyframes aurora-deriva do site): deslocamento em fração da camada, giro e escala.
struct Deriva: Equatable, Sendable {
    var x: Double
    var y: Double
    var giro: Double
    var escala: Double

    static let quadros = [
        Deriva(x: -0.04, y: -0.02, giro: 0, escala: 1),
        Deriva(x: 0.05, y: 0.03, giro: 8, escala: 1.08),
        Deriva(x: -0.02, y: 0.04, giro: -6, escala: 1.02),
    ]

    /// 26 s de ida e 26 de volta; cada trecho entre quadros com ease-in-out, como o CSS.
    static func em(segundos t: TimeInterval) -> Deriva {
        let ciclo = t.truncatingRemainder(dividingBy: 52)
        let p = ciclo <= 26 ? ciclo / 26 : (52 - ciclo) / 26
        let (a, b, local) = p < 0.5 ? (quadros[0], quadros[1], p / 0.5) : (quadros[1], quadros[2], (p - 0.5) / 0.5)
        let e = CurvaBezier.suave.y(local)
        return Deriva(x: a.x + (b.x - a.x) * e, y: a.y + (b.y - a.y) * e,
                      giro: a.giro + (b.giro - a.giro) * e, escala: a.escala + (b.escala - a.escala) * e)
    }
}

/// O fundo de todas as telas: a cor de fundo e a aurora por cima.
struct FundoAurora: View {
    /// Intensidade da aurora (animável: a transição entre a entrada e o app passa por aqui).
    let intensidade: Double
    let animada: Bool
    /// Segundos de deriva somados ao relógio (os testes de contraste congelam a aurora num quadro dado).
    var deslocamento: TimeInterval = 0
    @Environment(\.paleta) private var paleta

    var body: some View {
        GeometryReader { geo in
            let largura = geo.size.width, altura = geo.size.height * 0.78
            RelogioDoFundo(rodando: animada) { segundos in
                let d = Deriva.em(segundos: segundos + deslocamento)
                // Desenhada a um terço do tamanho e ampliada: degradê liso não perde nada e a camada
                // ocupa um nono da memória.
                CamadaAurora(cores: [paleta.cor(.aurora1), paleta.cor(.aurora2), paleta.cor(.aurora3), paleta.cor(.aurora4)],
                             intensidade: intensidade)
                    .equatable()
                    .frame(width: largura * 1.6 / 3, height: altura * 1.3 / 3)
                    .scaleEffect(3)
                    .frame(width: largura * 1.6, height: altura * 1.3)
                    .scaleEffect(d.escala)
                    .rotationEffect(.degrees(d.giro))
                    .offset(x: d.x * largura * 1.6, y: d.y * altura * 1.3)
            }
            .frame(width: largura, height: altura)
            .clipped()
            .mask(LinearGradient(stops: [.init(color: .black, location: 0.4), .init(color: .black.opacity(0), location: 1)],
                                 startPoint: .top, endPoint: .bottom))
        }
        .background(paleta.cor(.fundo))
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// A camada desenhada: base em degradê de 100° e os quatro brilhos, de baixo para cima.
struct CamadaAurora: View, Animatable, Equatable {
    let cores: [Color]
    var intensidade: Double

    nonisolated var animatableData: Double {
        get { intensidade }
        set { intensidade = newValue }
    }

    /// Brilhos do CSS: tamanho e centro em fração da camada, cor (índice) e onde o brilho some.
    private static let brilhos: [(rx: Double, ry: Double, cx: Double, cy: Double, cor: Int, fim: Double)] = [
        (0.24, 0.24, 0.44, 0.12, 3, 0.70),
        (0.48, 0.44, 0.52, 0.52, 2, 0.74),
        (0.50, 0.52, 0.84, 0.16, 1, 0.70),
        (0.55, 0.55, 0.16, 0.26, 0, 0.70),
    ]

    var body: some View {
        Canvas { contexto, tamanho in
            let w = tamanho.width, h = tamanho.height, a = intensidade
            // linear-gradient(100deg, A3, A1 35%, A2 65%, A3): a linha passa pelo centro.
            let angulo = 100.0 * .pi / 180
            let direcao = CGVector(dx: sin(angulo), dy: -cos(angulo))
            let meia = (abs(w * sin(angulo)) + abs(h * cos(angulo))) / 2
            let base = Gradient(stops: [
                .init(color: cores[2].opacity(a), location: 0), .init(color: cores[0].opacity(a), location: 0.35),
                .init(color: cores[1].opacity(a), location: 0.65), .init(color: cores[2].opacity(a), location: 1),
            ])
            contexto.fill(Path(CGRect(origin: .zero, size: tamanho)),
                          with: .linearGradient(base, startPoint: CGPoint(x: w / 2 - direcao.dx * meia, y: h / 2 - direcao.dy * meia),
                                                endPoint: CGPoint(x: w / 2 + direcao.dx * meia, y: h / 2 + direcao.dy * meia)))
            for b in Self.brilhos {
                let cor = cores[b.cor]
                contexto.drawLayer { camada in
                    camada.translateBy(x: b.cx * w, y: b.cy * h)
                    camada.scaleBy(x: b.rx * w, y: b.ry * h)
                    camada.fill(Path(ellipseIn: CGRect(x: -1, y: -1, width: 2, height: 2)),
                                with: .radialGradient(Gradient(stops: [.init(color: cor.opacity(a), location: 0),
                                                                       .init(color: cor.opacity(0), location: b.fim)]),
                                                      center: .zero, startRadius: 0, endRadius: 1))
                }
            }
        }
    }
}

/// Halo do título sobre a aurora clara da entrada, só no escuro: tom do fundo a 45% no centro, com borda
/// gradual. Nos tamanhos de acessibilidade cresce junto com o título e o miolo fica mais largo.
struct HaloDoTitulo: View {
    let grande: Bool
    @Environment(\.paleta) private var paleta
    @Environment(\.colorScheme) private var esquema

    var body: some View {
        let a = esquema == .dark ? 0.45 : 0
        let fundo = paleta.cor(.fundo)
        let paradas: [(Double, Double)] = grande
            ? [(0, 1), (0.66, 1), (0.76, 0.8), (0.87, 0.45), (0.95, 0.15), (1, 0)]
            : [(0, 1), (0.46, 1), (0.60, 0.82), (0.74, 0.5), (0.88, 0.18), (1, 0)]
        EllipticalGradient(stops: paradas.map { .init(color: fundo.opacity(a * $0.1), location: $0.0) },
                           center: .center, startRadiusFraction: 0, endRadiusFraction: 0.5)
            .padding(grande ? EdgeInsets(top: -96, leading: -70, bottom: -80, trailing: -70)
                            : EdgeInsets(top: -64, leading: -78, bottom: -58, trailing: -78))
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}
```

`app-ios/Custta/Identidade/Globo.swift`:

```swift
import SwiftUI

/* O globo em pontos do PWA (globe.js), em SwiftUI: continentes reais por polígonos, terra brilhante
   e oceano em grade tênue, só o hemisfério da frente, girando a 0,04 rad/s a 30 quadros por segundo.
   Centro em 80% da largura e 42% da altura; raio de 46% da altura ou 55% da largura, o menor. Halo
   atmosférico e aro de "planeta" em volta. No claro fica a 40%, como marca-d'água. Para (no ângulo
   1,2) com Reduzir movimento, Pouca Energia e durante a rolagem. */

enum PontosDoGlobo {
    /// Continentes (longitude, latitude), aproximados: os mesmos do globe.js.
    static let continentes: [[(Double, Double)]] = [
        [(-168, 66), (-140, 70), (-125, 71), (-110, 72), (-95, 72), (-80, 68), (-75, 62), (-58, 50), (-65, 45), (-74, 40), (-80, 32), (-81, 25), (-90, 19), (-97, 16), (-105, 20), (-111, 24), (-117, 33), (-124, 41), (-128, 50), (-140, 60), (-155, 58), (-165, 60), (-168, 66)],
        [(-52, 60), (-42, 60), (-22, 70), (-18, 76), (-30, 82), (-58, 80), (-68, 76), (-60, 66), (-52, 60)],
        [(-79, 9), (-70, 12), (-60, 9), (-52, 4), (-44, -3), (-35, -6), (-38, -13), (-48, -26), (-56, -35), (-65, -41), (-71, -52), (-75, -48), (-73, -37), (-71, -18), (-77, -6), (-80, 0), (-79, 9)],
        [(-9, 37), (-8, 43), (-2, 48), (0, 52), (7, 58), (12, 56), (18, 55), (25, 58), (30, 60), (40, 66), (55, 68), (60, 60), (50, 50), (40, 47), (30, 46), (25, 40), (15, 38), (5, 36), (-9, 37)],
        [(-17, 15), (-10, 25), (-6, 35), (10, 37), (20, 32), (32, 31), (35, 22), (43, 11), (51, 12), (45, 0), (40, -10), (35, -20), (32, -29), (25, -34), (18, -34), (14, -22), (12, -8), (8, 0), (-8, 5), (-13, 9), (-17, 15)],
        [(30, 46), (40, 47), (50, 50), (60, 60), (55, 68), (70, 73), (90, 76), (110, 77), (130, 72), (145, 70), (160, 68), (178, 66), (178, 62), (162, 58), (155, 52), (142, 46), (135, 43), (128, 39), (122, 34), (120, 26), (110, 18), (103, 8), (98, 12), (92, 20), (88, 22), (80, 12), (73, 18), (68, 24), (60, 26), (50, 28), (40, 36), (33, 40), (30, 46)],
        [(114, -22), (117, -16), (124, -13), (133, -11), (142, -13), (147, -19), (151, -25), (153, -30), (148, -38), (139, -37), (131, -33), (122, -33), (114, -27), (114, -22)],
        [(95, 5), (105, 3), (115, 0), (125, -3), (135, -5), (140, -8), (130, -9), (118, -9), (108, -7), (98, -2), (95, 5)],
        [(130, 32), (135, 34), (140, 36), (142, 42), (144, 44), (140, 40), (136, 35), (130, 32)],
    ]

    static func dentro(_ lon: Double, _ lat: Double, _ poligono: [(Double, Double)]) -> Bool {
        var dentro = false
        var j = poligono.count - 1
        for i in poligono.indices {
            let (xi, yi) = poligono[i], (xj, yj) = poligono[j]
            if (yi > lat) != (yj > lat) && lon < (xj - xi) * (lat - yi) / (yj - yi) + xi { dentro.toggle() }
            j = i
        }
        return dentro
    }

    static func ehTerra(_ lon: Double, _ lat: Double) -> Bool {
        lat < -72 || continentes.contains { dentro(lon, lat, $0) }
    }

    /// Pontos na esfera unitária, calculados uma vez (grade do celular: 2,2°).
    static let todos: (terra: [SIMD3<Double>], oceano: [SIMD3<Double>]) = {
        var terra: [SIMD3<Double>] = [], oceano: [SIMD3<Double>] = []
        let passo = 2.2, rad = Double.pi / 180
        var lat = -84.0
        while lat <= 84 {
            let cosL = cos(lat * rad)
            let passoLon = max(passo, passo / max(cosL, 0.08))
            var lon = -180.0
            while lon < 180 {
                let p = SIMD3(cosL * cos(lon * rad), sin(lat * rad), cosL * sin(lon * rad))
                if ehTerra(lon, lat) { terra.append(p) } else { oceano.append(p) }
                lon += passoLon
            }
            lat += passo
        }
        return (terra, oceano)
    }()
}

struct Globo: View {
    let animado: Bool
    @Environment(\.paleta) private var paleta
    @Environment(\.colorScheme) private var esquema

    /// Faixas de profundidade: um desenho por faixa e cor, em vez de um por ponto.
    private static let faixas = 10

    var body: some View {
        RelogioDoFundo(rodando: animado) { segundos in
            Canvas { contexto, tamanho in
                desenhar(contexto, tamanho, angulo: 1.2 + 0.04 * segundos)
            }
        }
        .opacity(esquema == .dark ? 1 : 0.4)
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func desenhar(_ contexto: GraphicsContext, _ tamanho: CGSize, angulo: Double) {
        let w = tamanho.width, h = tamanho.height
        let r = min(h * 0.46, w * 0.55), cx = w * 0.80, cy = h * 0.42
        let halo = paleta.cor(.globoHalo)
        contexto.fill(Path(CGRect(origin: .zero, size: tamanho)),
                      with: .radialGradient(Gradient(stops: [.init(color: halo.opacity(0.22), location: 0),
                                                             .init(color: halo.opacity(0.07), location: 0.7),
                                                             .init(color: halo.opacity(0), location: 1)]),
                                            center: CGPoint(x: cx, y: cy), startRadius: r * 0.4, endRadius: r * 1.35))
        contexto.stroke(Path(ellipseIn: CGRect(x: cx - r * 1.01, y: cy - r * 1.01, width: r * 2.02, height: r * 2.02)),
                        with: .color(paleta.cor(.globoAro).opacity(0.18)), lineWidth: 1.2)
        let s = sin(angulo), c = cos(angulo)
        desenharPontos(PontosDoGlobo.todos.oceano, contexto, s, c, cx, cy, r, w, h, terra: false)
        desenharPontos(PontosDoGlobo.todos.terra, contexto, s, c, cx, cy, r, w, h, terra: true)
    }

    private func desenharPontos(_ pontos: [SIMD3<Double>], _ contexto: GraphicsContext, _ s: Double, _ c: Double,
                                _ cx: Double, _ cy: Double, _ r: Double, _ w: Double, _ h: Double, terra: Bool) {
        let n = Self.faixas
        var caminhos = Array(repeating: Path(), count: n)
        var brilho = Array(repeating: Path(), count: n)
        for p in pontos {
            let x = p.x * c - p.z * s, z = p.x * s + p.z * c
            guard z >= 0.02 else { continue }                          // só o hemisfério da frente
            let sx = cx + x * r, sy = cy - p.y * r
            guard sx >= -6, sx <= w + 6, sy >= -6, sy <= h + 6 else { continue }
            let faixa = min(n - 1, Int(z * Double(n)))
            let profundidade = (Double(faixa) + 0.5) / Double(n)
            let lado = terra ? 1.5 + profundidade * 1.7 : 1.1 + profundidade * 1.0
            let quadrado = CGRect(x: sx - lado / 2, y: sy - lado / 2, width: lado, height: lado)
            if terra && z > 0.7 { brilho[faixa].addRect(quadrado) } else { caminhos[faixa].addRect(quadrado) }
        }
        let cor = paleta.cor(terra ? .globoTerra : .globoOceano), corBrilho = paleta.cor(.globoBrilho)
        for faixa in 0..<n {
            let profundidade = (Double(faixa) + 0.5) / Double(n)
            let alfa = terra ? 0.30 + profundidade * 0.62 : 0.10 + profundidade * 0.20
            if !caminhos[faixa].isEmpty { contexto.fill(caminhos[faixa], with: .color(cor.opacity(alfa))) }
            if !brilho[faixa].isEmpty { contexto.fill(brilho[faixa], with: .color(corBrilho.opacity(alfa))) }
        }
    }
}
```

- [ ] **Step 4: A abertura com o fundo**

`app-ios/Custta/CusttaApp.swift` (troque o corpo da Tarefa 1; a Tarefa 5 põe o logo e a Tarefa 10 a raiz das telas):

```swift
import SwiftUI

@main
struct CusttaApp: App {
    var body: some Scene {
        WindowGroup { AberturaView() }
    }
}

/// A abertura: o fundo do Custta, a aurora e o globo, enquanto o app não tem a tela de entrar.
struct AberturaView: View {
    @Environment(\.accessibilityReduceMotion) private var reduzirMovimento

    var body: some View {
        ZStack {
            FundoAurora(intensidade: Aurora.intensidade(tela: .entrada, pele: .esmeralda, escuro: true), animada: !reduzirMovimento)
            Globo(animado: !reduzirMovimento)
        }
        .preferredColorScheme(.dark)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Custta")
        .accessibilityIdentifier("abertura")
    }
}
```

`app-ios/CusttaUITests/AberturaUITests.swift`:

```swift
import XCTest

final class AberturaUITests: XCTestCase {
    @MainActor func testAppAbre() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.descendants(matching: .any)["abertura"].waitForExistence(timeout: 10))
    }
}
```

- [ ] **Step 5: Rodar e ver passar**

Run: `node --test tests/app-ios.test.cjs`
Expected: verde, inclusive "globo com os mesmos continentes do globe.js" e "animação própria respeita Reduzir movimento".

Run: `xcodebuild test -project app-ios/Custta.xcodeproj -scheme Custta -destination "$(node scripts/simulador-ios.mjs)" -skipMacroValidation -skipPackagePluginValidation -onlyUsePackageVersionsFromResolvedFile CODE_SIGNING_ALLOWED=NO`
Expected: `** TEST SUCCEEDED **`, com `MovimentoTests` (2), `FundoTests` (3) e `testAppAbre` verdes.

Conferência visual (Verniz): abra o app no simulador (`xcrun simctl install` e `launch`) e compare com a tela 1 do `final.html` no escuro: a aurora no brilho de hoje, derivando devagar, e o globo girando à direita, passando por trás da barra de status. Com `xcrun simctl io <id> recordVideo` dá para ver a deriva.

- [ ] **Step 6: Commit**

```bash
git add app-ios/Custta/Identidade/Movimento.swift app-ios/Custta/Identidade/Aurora.swift app-ios/Custta/Identidade/Globo.swift app-ios/Custta/CusttaApp.swift app-ios/CusttaTests/FundoTests.swift app-ios/CusttaUITests/AberturaUITests.swift tests/app-ios.test.cjs
git commit -m "feat: aurora e globo do PWA no app nativo" -m "A aurora do site (quatro brilhos e o degradê de 100°, derivando 26 s de ida e volta) vira uma camada desenhada uma vez e só movida, a 30 quadros por segundo, com a intensidade por tela do mockup. O globo usa os mesmos continentes e a mesma grade do globe.js, desenhado em dez faixas de profundidade. Os dois param com Reduzir movimento, Pouca Energia, durante a rolagem e fora da tela, e voltam sem pular. A abertura passa a mostrar o fundo no lugar do texto; a guarda confere que os continentes são os do site."
```

---

### Task 5: Título escrito à mão

**Files:**
- Create: `app-ios/Custta/Identidade/CaminhoSVG.swift`, `app-ios/Custta/Identidade/LogoEscrito.swift`
- Modify: `app-ios/Custta/CusttaApp.swift` (o logo na abertura)
- Test: `app-ios/CusttaTests/LogoTests.swift`
- Modify: `tests/app-ios.test.cjs` (teste no fim)

**Interfaces:**
- Consumes: `Paleta` (`texto`, `marca`, `fundo`, `realceLogo`, `destaque`) (Tarefa 3); `RelogioDoFundo`, `CurvaBezier`, `EnvironmentValues.rolagem` (Tarefa 4); o `.logo-escrito` do `index.html` e os tempos do `styles.css` (`le-p0`…`le-p8`, `leCarimba`, `le-fim`, `leVarre`, `leSome`).
- Produces: `enum CaminhoSVG { struct ErroDeLeitura: Error; static func ler(_ d: String) throws -> Path; static func arco(...) }`; `enum LogoCaminhos { struct Letra; static let letras, ponto, tracos, carimbo, vibracao, inteiras, varredura, some, total, caixa, larguraDaPena; static let caminhos }`; `struct LogoEscrito: View { init(animado: Bool, altura: CGFloat = 33) }`.

O logo é o do site, não um desenho novo: os mesmos caminhos do `index.html` (que `tests/logo-escrito.test.cjs` protege), lidos por um leitor de SVG próprio (comandos absolutos, com o arco convertido em Bézier). Cada letra aparece sob o traço da sua caneta (máscara de linha de 180 com pontas redondas, `stroke-dashoffset` de 1,1 a 0 com a curva do site); aos 2,25 s as letras ficam inteiras; o ponto carimba a partir da base (curva com repique) e o app vibra de leve 120 ms depois, como o `auth.js` faz no app de hoje; no escuro, o realce varre o "tt." da esquerda para a direita com o degradê do site e o "tt" escuro some debaixo dele aos 3 s. Com Reduzir movimento ou Pouca Energia aparece pronto (quem chama passa `animado: false`); pausa durante a rolagem. O logo tem 33 pt de altura e não cresce com a letra; a leitura do VoiceOver fica no título que o contém (Tarefa 10).

- [ ] **Step 1: Escrever os testes que falham**

`app-ios/CusttaTests/LogoTests.swift`:

```swift
import Foundation
import Testing
import SwiftUI
@testable import Custta

/* O leitor de caminhos SVG e o logo escrito. */
struct LogoTests {
    @Test func leComandosERepeticao() throws {
        let p = try CaminhoSVG.ler("M0 0 10 0V10H0Z")
        #expect(p.boundingRect == CGRect(x: 0, y: 0, width: 10, height: 10))
        let curva = try CaminhoSVG.ler("M0 0Q5 10 10 0C10 -5 0 -5 0 0")
        #expect(curva.currentPoint == CGPoint(x: 0, y: 0))
        #expect(throws: CaminhoSVG.ErroDeLeitura.self) { try CaminhoSVG.ler("M0 0 X1 1") }
    }

    @Test func arcoTerminaNoPontoDado() throws {
        let p = try CaminhoSVG.ler("M478 -385 L405 -355 A165 195 0 1 0 405 -135 L478 -105")
        let caixa = p.boundingRect
        // A elipse de raios 165 e 195 passa por (405, −355) e (405, −135): o centro fica em
        // x = 405 − 165·√(1 − (110/195)²) ≈ 268,76, e o ponto mais à esquerda do c, 165 antes disso.
        #expect(abs(caixa.minX - (405 - 165 * (1 - pow(110.0 / 195, 2)).squareRoot() - 165)) < 0.01)
        #expect(abs(caixa.maxX - 478) < 0.01, "o Path guarda a caixa em precisão simples")
        let arco = try CaminhoSVG.ler("M0 0 A10 10 0 0 1 20 0")
        #expect(abs(arco.currentPoint!.x - 20) < 1e-9 && abs(arco.currentPoint!.y) < 1e-9)
    }

    @Test func caminhosDoLogoLidosENaCaixa() {
        let c = LogoCaminhos.caminhos
        #expect(c.letras.count == 6 && c.letras.filter(\.tt).count == 2)
        #expect(c.letras.flatMap(\.penas).count == LogoCaminhos.tracos.count)
        for letra in c.letras {
            #expect(!letra.glifo.isEmpty && !letra.penas.contains(where: \.isEmpty))
            #expect(LogoCaminhos.caixa.insetBy(dx: -1, dy: -1).contains(letra.glifo.boundingRect))
        }
        #expect(!c.ponto.isEmpty)
    }

    @Test func temposEmOrdem() {
        let inicios = LogoCaminhos.tracos.map(\.inicio)
        #expect(inicios == inicios.sorted())
        #expect(LogoCaminhos.carimbo.inicio > inicios.last!)
        #expect(LogoCaminhos.vibracao > LogoCaminhos.carimbo.inicio && LogoCaminhos.inteiras < LogoCaminhos.varredura.inicio)
        #expect(LogoCaminhos.total > LogoCaminhos.some)
    }
}
```

No fim de `tests/app-ios.test.cjs`:

```js
test('o logo escrito do app usa os caminhos do logo do site', () => {
  const svg = ler('index.html').match(/<svg class="logo-escrito"[\s\S]*?<\/svg>/)[0];
  const swift = ler('app-ios/Custta/Identidade/LogoEscrito.swift');
  const caminhos = [...svg.matchAll(/\sd="([^"]+)"/g)].map(m => m[1]);
  assert.ok(caminhos.length >= 16, 'caminhos do logo no index.html');
  for(const d of caminhos) assert.ok(swift.includes(`"${d}"`), `caminho do logo ausente no app: ${d.slice(0, 40)}…`);
});
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `node --test tests/app-ios.test.cjs`
Expected: FAIL em "o logo escrito do app usa os caminhos do logo do site": `ENOENT … LogoEscrito.swift`.

Run: `xcodebuild test -project app-ios/Custta.xcodeproj -scheme Custta -destination "$(node scripts/simulador-ios.mjs)" -skipMacroValidation -skipPackagePluginValidation -onlyUsePackageVersionsFromResolvedFile CODE_SIGNING_ALLOWED=NO -only-testing:CusttaTests/LogoTests`
Expected: FAIL na compilação: `cannot find 'CaminhoSVG' in scope`.

- [ ] **Step 3: Implementar o leitor e o logo**

`app-ios/Custta/Identidade/CaminhoSVG.swift`:

```swift
import SwiftUI

/* Lê o atributo `d` de um caminho SVG (comandos absolutos M, L, H, V, C, Q, A e Z, com repetição
   implícita) num Path do SwiftUI. Serve ao logo escrito, que usa os mesmos caminhos do index.html
   (tests/app-ios.test.cjs confere que são iguais). O arco vira curvas de Bézier de até 90°, pela
   conversão da especificação do SVG (apêndice F.6). */
enum CaminhoSVG {
    struct ErroDeLeitura: Error, Equatable {
        let perto: String
    }

    static func ler(_ d: String) throws -> Path {
        var itens = Leitor(d)
        var path = Path()
        var atual = CGPoint.zero
        var inicio = CGPoint.zero
        var comando: Character = " "
        while let proximo = itens.proximoComando(anterior: comando) {
            comando = proximo
            switch comando {
            case "M":
                atual = try itens.ponto(); inicio = atual
                path.move(to: atual)
                comando = "L"                                  // pares seguidos depois de M são linhas
            case "L":
                atual = try itens.ponto(); path.addLine(to: atual)
            case "H":
                atual.x = try itens.numero(); path.addLine(to: atual)
            case "V":
                atual.y = try itens.numero(); path.addLine(to: atual)
            case "C":
                let c1 = try itens.ponto(), c2 = try itens.ponto(); atual = try itens.ponto()
                path.addCurve(to: atual, control1: c1, control2: c2)
            case "Q":
                let c = try itens.ponto(); atual = try itens.ponto()
                path.addQuadCurve(to: atual, control: c)
            case "A":
                let rx = try itens.numero(), ry = try itens.numero(), giro = try itens.numero()
                let grande = try itens.numero() != 0, horario = try itens.numero() != 0
                let fim = try itens.ponto()
                arco(&path, de: atual, ate: fim, rx: rx, ry: ry, giro: giro, grande: grande, horario: horario)
                atual = fim
            case "Z":
                path.closeSubpath(); atual = inicio
            default:
                throw ErroDeLeitura(perto: String(comando))
            }
        }
        return path
    }

    /// Arco elíptico do SVG em curvas de Bézier.
    static func arco(_ path: inout Path, de p1: CGPoint, ate p2: CGPoint, rx rxDado: Double, ry ryDado: Double,
                     giro: Double, grande: Bool, horario: Bool) {
        var rx = abs(rxDado), ry = abs(ryDado)
        guard rx > 0, ry > 0, p1 != p2 else { path.addLine(to: p2); return }
        let phi = giro * .pi / 180, cosPhi = cos(phi), sinPhi = sin(phi)
        let dx = (p1.x - p2.x) / 2, dy = (p1.y - p2.y) / 2
        let x1 = cosPhi * dx + sinPhi * dy, y1 = -sinPhi * dx + cosPhi * dy
        let lambda = x1 * x1 / (rx * rx) + y1 * y1 / (ry * ry)
        if lambda > 1 { rx *= lambda.squareRoot(); ry *= lambda.squareRoot() }
        let num = rx * rx * ry * ry - rx * rx * y1 * y1 - ry * ry * x1 * x1
        let den = rx * rx * y1 * y1 + ry * ry * x1 * x1
        let coef = (grande != horario ? 1.0 : -1.0) * max(0, num / den).squareRoot()
        let cxL = coef * rx * y1 / ry, cyL = -coef * ry * x1 / rx
        let cx = cosPhi * cxL - sinPhi * cyL + (p1.x + p2.x) / 2
        let cy = sinPhi * cxL + cosPhi * cyL + (p1.y + p2.y) / 2
        func angulo(_ ux: Double, _ uy: Double, _ vx: Double, _ vy: Double) -> Double {
            atan2(ux * vy - uy * vx, ux * vx + uy * vy)
        }
        let ux = (x1 - cxL) / rx, uy = (y1 - cyL) / ry, vx = (-x1 - cxL) / rx, vy = (-y1 - cyL) / ry
        let theta1 = angulo(1, 0, ux, uy)
        var delta = angulo(ux, uy, vx, vy)
        if !horario && delta > 0 { delta -= 2 * .pi }
        if horario && delta < 0 { delta += 2 * .pi }
        let partes = max(1, Int((abs(delta) / (.pi / 2)).rounded(.up)))
        let passo = delta / Double(partes)
        let k = 4.0 / 3.0 * tan(passo / 4)
        func noPlano(_ x: Double, _ y: Double) -> CGPoint {
            CGPoint(x: cx + rx * cosPhi * x - ry * sinPhi * y, y: cy + rx * sinPhi * x + ry * cosPhi * y)
        }
        var theta = theta1
        for _ in 0..<partes {
            let a = cos(theta), b = sin(theta), c = cos(theta + passo), d = sin(theta + passo)
            path.addCurve(to: noPlano(c, d), control1: noPlano(a - k * b, b + k * a), control2: noPlano(c + k * d, d - k * c))
            theta += passo
        }
    }

    /// Os números e comandos do atributo `d`, em ordem.
    private struct Leitor {
        private let caracteres: [Character]
        private var i = 0

        init(_ d: String) { caracteres = Array(d) }

        private mutating func pularSeparadores() {
            while i < caracteres.count, caracteres[i] == " " || caracteres[i] == "," || caracteres[i].isNewline { i += 1 }
        }

        /// O próximo comando; se vier número, repete o anterior.
        mutating func proximoComando(anterior: Character) -> Character? {
            pularSeparadores()
            guard i < caracteres.count else { return nil }
            if caracteres[i].isLetter { defer { i += 1 }; return caracteres[i] }
            return anterior
        }

        mutating func numero() throws -> Double {
            pularSeparadores()
            let comeco = i
            if i < caracteres.count, caracteres[i] == "-" || caracteres[i] == "+" { i += 1 }
            var viuPonto = false
            while i < caracteres.count, caracteres[i].isNumber || (caracteres[i] == "." && !viuPonto) {
                if caracteres[i] == "." { viuPonto = true }
                i += 1
            }
            guard let n = Double(String(caracteres[comeco..<i])) else {
                throw ErroDeLeitura(perto: String(caracteres[comeco..<min(caracteres.count, comeco + 12)]))
            }
            return n
        }

        mutating func ponto() throws -> CGPoint {
            let x = try numero()
            return CGPoint(x: x, y: try numero())
        }
    }
}
```

`app-ios/Custta/Identidade/LogoEscrito.swift` (os caminhos são cópia exata dos do `index.html`; a guarda compara):

```swift
import SwiftUI

/* Título escrito à mão (o .logo-escrito do index.html): cada letra aparece sob um traço de caneta,
   na ordem e nos tempos do styles.css; o ponto carimba (com vibração leve, como no app de hoje) e, no
   escuro, um brilho varre o "tt." com o degradê do realce. Com Reduzir movimento ou Pouca Energia
   aparece pronto. Os caminhos são os do index.html, que tests/logo-escrito.test.cjs protege;
   tests/app-ios.test.cjs confere que os dois continuam iguais. */
enum LogoCaminhos {
    struct Letra: Sendable {
        let glifo: String
        /// Traços de caneta que revelam a letra.
        let penas: [String]
        /// O "tt" da marca (cor da marca no claro; no escuro, coberto pelo realce).
        let tt: Bool
    }

    static let letras: [Letra] = [
        // c
        Letra(glifo: "M279 10Q217 10 172 -12Q126 -33 96 -70Q65 -106 50 -152Q35 -198 35 -247Q35 -296 50 -342Q65 -388 96 -424Q126 -460 172 -482Q217 -503 279 -503Q355 -503 411 -467Q467 -431 495 -356L375 -308Q364 -342 342 -363Q319 -384 279 -384Q241 -384 218 -364Q194 -344 183 -312Q172 -281 172 -247Q172 -213 183 -181Q194 -149 218 -129Q241 -109 279 -109Q319 -109 342 -130Q364 -151 375 -185L495 -137Q467 -63 411 -26Q355 10 279 10Z",
              penas: ["M478 -385 L405 -355 A165 195 0 1 0 405 -135 L478 -105"],
              tt: false),
        // u
        Letra(glifo: "M728 10Q665 10 624 -14Q584 -39 565 -84Q546 -128 546 -187V-493H683V-217Q683 -188 690 -164Q696 -139 714 -124Q733 -109 770 -109Q815 -109 836 -136Q856 -162 862 -208Q868 -255 868 -314V-493H1006V0H868V-107L884 -94Q861 -36 820 -13Q778 10 728 10Z",
              penas: ["M600 -493 V-200 C600 15 922 15 922 -230 V-493 V10"],
              tt: false),
        // s
        Letra(glifo: "M1265 10Q1209 10 1167 -6Q1125 -22 1097 -46Q1069 -69 1051 -89L1145 -171Q1162 -146 1192 -123Q1221 -100 1266 -100Q1299 -100 1318 -113Q1336 -126 1336 -143Q1336 -159 1324 -168Q1312 -178 1292 -185Q1272 -192 1247 -199Q1219 -206 1189 -216Q1159 -227 1133 -244Q1107 -261 1091 -288Q1075 -314 1075 -354Q1075 -421 1128 -462Q1180 -503 1265 -503Q1325 -503 1374 -480Q1423 -457 1452 -413L1367 -346Q1349 -372 1321 -386Q1293 -401 1262 -401Q1236 -401 1220 -392Q1203 -382 1203 -367Q1203 -356 1211 -348Q1219 -341 1237 -335Q1255 -329 1286 -321Q1315 -314 1347 -304Q1379 -294 1408 -276Q1436 -259 1454 -230Q1471 -202 1471 -159Q1471 -109 1446 -70Q1420 -32 1374 -11Q1327 10 1265 10Z",
              penas: ["M1412 -392 C1362 -457 1282 -460 1232 -460 C1152 -460 1104 -412 1104 -352 C1104 -284 1172 -268 1252 -244 C1342 -217 1398 -192 1398 -138 C1398 -58 1322 -38 1242 -38 C1162 -38 1108 -73 1070 -118"],
              tt: false),
        // t
        Letra(glifo: "M1729 10Q1688 10 1652 -6Q1616 -21 1594 -56Q1572 -91 1572 -151V-602L1711 -676V-190Q1711 -146 1722 -124Q1734 -102 1767 -102Q1777 -102 1790 -104Q1802 -106 1816 -110V-5Q1795 3 1774 6Q1752 10 1729 10ZM1486 -386V-493H1816V-386Z",
              penas: ["M1641 -690 V-160 C1641 -40 1700 -45 1790 -55", "M1486 -440 H1816"],
              tt: true),
        // t
        Letra(glifo: "M2073 10Q2032 10 1996 -6Q1960 -21 1938 -56Q1916 -91 1916 -151V-602L2055 -676V-190Q2055 -146 2066 -124Q2078 -102 2111 -102Q2121 -102 2134 -104Q2146 -106 2160 -110V-5Q2139 3 2118 6Q2096 10 2073 10ZM1830 -386V-493H2160V-386Z",
              penas: ["M1985 -690 V-160 C1985 -40 2044 -45 2134 -55", "M1830 -440 H2160"],
              tt: true),
        // a
        Letra(glifo: "M2534 0 2524 -66V-312Q2524 -352 2498 -370Q2471 -388 2429 -388Q2390 -388 2348 -373Q2305 -358 2275 -334L2211 -429Q2267 -470 2322 -486Q2377 -503 2441 -503Q2544 -503 2602 -452Q2660 -401 2660 -312V0ZM2391 10Q2337 10 2294 -10Q2251 -30 2226 -68Q2201 -105 2201 -154Q2201 -197 2219 -228Q2237 -259 2267 -276Q2291 -290 2321 -296Q2351 -302 2384 -302H2535V-201H2404Q2390 -201 2378 -198Q2366 -196 2356 -189Q2348 -183 2344 -174Q2339 -165 2339 -154Q2339 -129 2358 -114Q2378 -100 2411 -100Q2442 -100 2468 -113Q2493 -126 2508 -149Q2524 -172 2524 -201L2556 -126Q2540 -74 2514 -44Q2487 -15 2456 -2Q2424 10 2391 10Z",
              penas: ["M2235 -365 C2300 -440 2380 -450 2440 -450 C2560 -450 2600 -380 2600 -300 V0", "M2600 -265 H2385 C2285 -265 2255 -200 2255 -150 C2255 -75 2305 -45 2372 -45 C2470 -45 2560 -90 2590 -180"],
              tt: false)
    ]
    static let ponto = "M2730 0V-137H2874V0Z"

    /// Início e duração (s) de cada traço, na ordem das penas (le-p0 a le-p8 do styles.css).
    static let tracos: [(inicio: Double, duracao: Double)] = [
        (0, 0.3), (0.26, 0.34), (0.56, 0.3), (0.84, 0.22), (1.02, 0.12), (1.12, 0.22), (1.3, 0.12), (1.4, 0.24), (1.6, 0.24),
    ]
    static let curvaDoTraco = CurvaBezier(x1: 0.45, y1: 0.05, x2: 0.35, y2: 1)
    static let carimbo = (inicio: 1.86, duracao: 0.34)
    static let curvaDoCarimbo = CurvaBezier(x1: 0.3, y1: 1.6, x2: 0.5, y2: 1)
    /// A vibração do carimbo, 120 ms depois de ele começar (auth.js).
    static let vibracao = 1.98
    /// Daqui em diante as letras aparecem inteiras (le-fim).
    static let inteiras = 2.25
    static let varredura = (inicio: 2.35, duracao: 0.65)
    static let curvaDaVarredura = CurvaBezier(x1: 0.65, y1: 0, x2: 0.35, y2: 1)
    /// No escuro, o "tt" escuro some debaixo do realce (le-tt).
    static let some = 3.0
    static let total = 3.05

    /// A caixa do desenho (viewBox "0 -700 2900 720") e a largura do traço da caneta.
    static let caixa = CGRect(x: 0, y: -700, width: 2900, height: 720)
    static let larguraDaPena = 180.0

    /// Os caminhos já lidos (uma vez).
    static let caminhos: (letras: [(glifo: Path, penas: [Path], tt: Bool)], ponto: Path) = {
        let lidas = letras.map { l in
            ((try? CaminhoSVG.ler(l.glifo)) ?? Path(), l.penas.map { (try? CaminhoSVG.ler($0)) ?? Path() }, l.tt)
        }
        return (lidas, (try? CaminhoSVG.ler(ponto)) ?? Path())
    }()
}

struct LogoEscrito: View {
    /// false: aparece pronto (Reduzir movimento, Pouca Energia).
    let animado: Bool
    /// Altura do logo: não cresce com a letra grande (decisão do mockup).
    var altura: CGFloat = 33
    @Environment(\.paleta) private var paleta
    @Environment(\.colorScheme) private var esquema
    @Environment(\.rolagem) private var rolagem
    @State private var terminou = false
    @State private var carimbou = false

    var body: some View {
        let largura = altura * LogoCaminhos.caixa.width / LogoCaminhos.caixa.height
        RelogioDoFundo(rodando: animado && !terminou && !(rolagem?.rolando ?? false)) { segundos in
            let t = animado ? segundos : LogoCaminhos.total
            Canvas { contexto, tamanho in desenhar(contexto, tamanho, t: t) }
                .onChange(of: t >= LogoCaminhos.vibracao) { _, passou in if passou { carimbou = true } }
                .onChange(of: t >= LogoCaminhos.total) { _, acabou in if acabou { terminou = true } }
        }
        .frame(width: largura, height: altura)
        .sensoryFeedback(.impact(weight: .light), trigger: carimbou) { _, novo in novo }
        .accessibilityHidden(true)
    }

    private static func progresso(_ t: Double, _ inicio: Double, _ duracao: Double, _ curva: CurvaBezier) -> Double {
        curva.y(min(1, max(0, (t - inicio) / duracao)))
    }

    private func desenhar(_ contexto: GraphicsContext, _ tamanho: CGSize, t: Double) {
        var c = contexto
        let escala = tamanho.height / LogoCaminhos.caixa.height
        c.scaleBy(x: escala, y: escala)
        c.translateBy(x: -LogoCaminhos.caixa.minX, y: -LogoCaminhos.caixa.minY)
        let escuro = esquema == .dark
        let texto = paleta.cor(.texto), marca = paleta.cor(.marca), fundo = paleta.cor(.fundo)
        var indicePena = 0
        for letra in LogoCaminhos.caminhos.letras {
            let penas = letra.penas.indices.map { indicePena + $0 }
            indicePena += letra.penas.count
            if letra.tt && escuro && t >= LogoCaminhos.some { continue }
            let cor = letra.tt ? (escuro ? fundo : marca) : texto
            if t >= LogoCaminhos.inteiras {
                c.fill(letra.glifo, with: .color(cor))
                continue
            }
            var camada = c
            camada.clipToLayer { mascara in
                for (i, pena) in zip(penas, letra.penas) {
                    let (inicio, duracao) = LogoCaminhos.tracos[i]
                    let fim = 1 - 1.1 * (1 - Self.progresso(t, inicio, duracao, LogoCaminhos.curvaDoTraco))
                    guard fim > 0 else { continue }
                    mascara.stroke(pena.trimmedPath(from: 0, to: min(1, fim)), with: .color(.black),
                                   style: StrokeStyle(lineWidth: LogoCaminhos.larguraDaPena, lineCap: .round, lineJoin: .round))
                }
            }
            camada.fill(letra.glifo, with: .color(cor))
        }
        // O ponto carimba a partir da base.
        let ponto = LogoCaminhos.caminhos.ponto, caixa = ponto.boundingRect
        let s = Self.progresso(t, LogoCaminhos.carimbo.inicio, LogoCaminhos.carimbo.duracao, LogoCaminhos.curvaDoCarimbo)
        if s > 0 {
            var p = c
            p.translateBy(x: caixa.midX, y: caixa.maxY)
            p.scaleBy(x: s, y: s)
            p.translateBy(x: -caixa.midX, y: -caixa.maxY)
            p.fill(ponto, with: .color(escuro ? fundo : marca))
        }
        // No escuro, o realce varre o "tt." da esquerda para a direita.
        guard escuro else { return }
        let v = Self.progresso(t, LogoCaminhos.varredura.inicio, LogoCaminhos.varredura.duracao, LogoCaminhos.curvaDaVarredura)
        guard v > 0 else { return }
        var realce = c
        realce.clip(to: Path(CGRect(x: 1440, y: -800, width: 1500 * v, height: 900)))
        let degrade = Gradient(colors: [paleta.cor(.realceLogo), paleta.cor(.destaque)])
        for letra in LogoCaminhos.caminhos.letras where letra.tt {
            realce.fill(letra.glifo, with: .linearGradient(degrade, startPoint: CGPoint(x: 0, y: -690), endPoint: CGPoint(x: 0, y: 10)))
        }
        realce.fill(ponto, with: .linearGradient(degrade, startPoint: CGPoint(x: 0, y: caixa.minY), endPoint: CGPoint(x: 0, y: caixa.maxY)))
    }
}
```

`app-ios/Custta/CusttaApp.swift` (o logo entra na abertura):

```swift
import SwiftUI

@main
struct CusttaApp: App {
    var body: some Scene {
        WindowGroup { AberturaView() }
    }
}

/// A abertura: o fundo do Custta e o título se escrevendo, enquanto o app não tem a tela de entrar.
struct AberturaView: View {
    @Environment(\.accessibilityReduceMotion) private var reduzirMovimento

    var body: some View {
        ZStack {
            FundoAurora(intensidade: Aurora.intensidade(tela: .entrada, pele: .esmeralda, escuro: true), animada: !reduzirMovimento)
            Globo(animado: !reduzirMovimento)
            LogoEscrito(animado: !reduzirMovimento)
        }
        .preferredColorScheme(.dark)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Custta")
        .accessibilityIdentifier("abertura")
    }
}
```

- [ ] **Step 4: Rodar e ver passar**

Run: `node --test tests/app-ios.test.cjs`
Expected: verde, inclusive "o logo escrito do app usa os caminhos do logo do site".

Run: `xcodebuild test -project app-ios/Custta.xcodeproj -scheme Custta -destination "$(node scripts/simulador-ios.mjs)" -skipMacroValidation -skipPackagePluginValidation -onlyUsePackageVersionsFromResolvedFile CODE_SIGNING_ALLOWED=NO`
Expected: `** TEST SUCCEEDED **`, com `LogoTests` (4) verdes.

Conferência visual (Verniz): o logo se escreve na abertura em cerca de 3 s, com o carimbo do ponto e, no escuro, o realce varrendo o "tt."; com `xcrun simctl launch <id> br.com.custta.app` e `xcrun simctl io <id> recordVideo` grave os 4 primeiros segundos e compare com o logo do site.

**Ponto de controle (Orquestrador):** com a Tarefa 5, o app já abre com a aurora, o globo e o título se escrevendo. Mande ao Giovani o vídeo ou o print antes de seguir para a Tarefa 6.

- [ ] **Step 5: Commit**

```bash
git add app-ios/Custta/Identidade/CaminhoSVG.swift app-ios/Custta/Identidade/LogoEscrito.swift app-ios/Custta/CusttaApp.swift app-ios/CusttaTests/LogoTests.swift tests/app-ios.test.cjs
git commit -m "feat: título escrito à mão no app nativo" -m "O logo do site se escreve no app com os mesmos caminhos do index.html e os mesmos tempos do styles.css: cada letra sob o traço da sua caneta, o ponto carimbando com uma vibração leve, como no app de hoje, e, no escuro, o realce varrendo o tt. Um leitor de caminho SVG próprio (com o arco convertido em Bézier) lê os caminhos; a guarda confere que eles continuam iguais aos do site. Com Reduzir movimento ou Pouca Energia o logo aparece pronto."
```

---

### Task 6: Regras do cadastro nos vetores e no núcleo

**Files:**
- Modify: `scripts/vetores-calc.mjs` (carrega `cadastro.js` e ganha o bloco do cadastro)
- Modify (gerado): `tests/vetores/calc.json`
- Modify: `tests/vetores.test.mjs`, `CLAUDE.md` (parágrafo dos vetores), `.github/workflows/app-ios.yml` e `tests/workflow.test.cjs` (caminho `cadastro.js`)
- Create: `app-ios/CusttaNucleo/Sources/CusttaNucleo/Cadastro.swift`
- Create: `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/CadastroTests.swift`

**Interfaces:**
- Consumes: `aparadoJS`, `ehEspacoJS`, `ehDigito`, `ValorJSON` (Parte A).
- Produces: `public struct RegraSenha { id, texto }`, `public let regrasSenha`, `public struct RegraAvaliada { id, texto, ok }`, `public struct ResultadoSenha { ok, regras, erro }`, `public func validaSenha(_ senha: String?, email: String?) -> ResultadoSenha`; `public struct Origem { id, nome, detalhe: String? }`, `public let origens`; `public enum LimitesPerfil { nome = 60, sobrenome = 80, origemDetalhe = 80 }`; `public struct PerfilCadastro { nome, sobrenome, origem, origemDetalhe: String?; var campos: [String: ValorJSON] }`; `public struct ResultadoPerfil { ok, campo, erro, perfil: PerfilCadastro? }`; `public func normalizaNome(nome:sobrenome:) -> ResultadoPerfil`; `public func normalizaPerfil(nome:sobrenome:origem:origemDetalhe:nomeOpcional:) -> ResultadoPerfil`; `public func nomeDoGoogle(_:) -> (nome: String, sobrenome: String)`; `public func mensagemErroSocial(codigo:provedor:) -> String`; `public func mensagemErroSenha(codigo:tela:) -> String`.

- [ ] **Step 1: Escrever o teste do site que falha**

Em `tests/vetores.test.mjs`, depois do teste do `calc.js`:

```js
test('toda exportação do cadastro.js tem vetor', () => {
  const faltam = Object.keys(require('../cadastro.js')).filter(k => !vetores.grupos[`cadastro.${k}`]);
  assert.deepEqual(faltam, []);
});
```

Run: `node --test tests/vetores.test.mjs`
Expected: FAIL com a lista `[ 'REGRAS_SENHA', 'validaSenha', 'ORIGENS', … ]`.

- [ ] **Step 2: Gerar os vetores do cadastro**

Em `scripts/vetores-calc.mjs`, logo depois de `const P = require('../push.js');`, acrescente `const K = require('../cadastro.js');`. No comentário do topo, troque "do calc.js, do dados.js e do push.js" por "do calc.js, do dados.js, do push.js e do cadastro.js". Antes do bloco `/* ---------- primitivas do JavaScript que as regras usam ---------- */`, acrescente:

```js
/* ---------- cadastro.js ---------- */
constante('cadastro.REGRAS_SENHA', K.REGRAS_SENHA);
constante('cadastro.ORIGENS', K.ORIGENS);
constante('cadastro.LIMITES_PERFIL', K.LIMITES_PERFIL);
const senha = (nome, ...args) => caso('cadastro.validaSenha', nome, args, K.validaSenha);
senha('boa', 'Casa2026x', 'joao@exemplo.com');
senha('curta', 'Ab1', 'joao@exemplo.com');
senha('sem letra', '12345678', 'joao@exemplo.com');
senha('sem número', 'abcdefgh', 'joao@exemplo.com');
senha('igual ao e-mail, sem diferença de caixa', 'joao1234@exemplo.com', '  JOAO1234@exemplo.com ');
senha('óbvia da lista', 'Senha123', 'joao@exemplo.com');
senha('óbvia com espaços em volta', '  custta123 ', 'joao@exemplo.com');
senha('129 caracteres', 'a1'.repeat(64) + 'b', 'joao@exemplo.com');
senha('128 caracteres', 'a1'.repeat(64), 'joao@exemplo.com');
senha('letra acentuada conta como letra', 'çãoé1234', 'joao@exemplo.com');
senha('emoji conta duas unidades no tamanho', '😀😀😀1a', 'joao@exemplo.com');
senha('dígito árabe não é número', 'abcdefg٣', 'joao@exemplo.com');
senha('sem e-mail', 'Casa2026x');
senha('nula', null, null);
const nomeK = (nome, d) => caso('cadastro.normalizaNome', nome, [d], K.normalizaNome);
nomeK('nome e sobrenome', { nome: '  João  ', sobrenome: ' da   Silva ' });
nomeK('sem sobrenome', { nome: 'Ana' });
nomeK('nome vazio', { nome: '   ' });
nomeK('nome de uma letra', { nome: 'A' });
nomeK('nome com 61', { nome: 'x'.repeat(61) });
nomeK('sobrenome com 81', { nome: 'Ana', sobrenome: 'y'.repeat(81) });
nomeK('espaços variados viram um', { nome: 'Ana\u{a0}\tMaria', sobrenome: 'Souza\nLima' });
nomeK('nulo', null);
const perfilK = (nome, ...args) => caso('cadastro.normalizaPerfil', nome, args, K.normalizaPerfil);
perfilK('completo com indicação', { nome: 'Ana', sobrenome: 'Lima', origem: 'indicacao', origemDetalhe: '  Pedro  ' });
perfilK('origem sem detalhe ignora o detalhe', { nome: 'Ana', origem: 'instagram', origemDetalhe: 'x' });
perfilK('detalhe vazio some', { nome: 'Ana', origem: 'outro', origemDetalhe: '   ' });
perfilK('detalhe com 81', { nome: 'Ana', origem: 'outro', origemDetalhe: 'z'.repeat(81) });
perfilK('sem origem', { nome: 'Ana' });
perfilK('origem desconhecida', { nome: 'Ana', origem: 'facebook' });
perfilK('nome inválido falha antes da origem', { nome: '', origem: 'google' });
perfilK('conta Apple: nome opcional', { nome: '', origem: 'youtube' }, { nomeOpcional: true });
perfilK('conta Apple com nome válido guarda o nome', { nome: 'Bia', origem: 'tiktok' }, { nomeOpcional: true });
perfilK('nulo', null);
for(const n of ['João da Silva Souza', '  Ana  ', '', 'Maria', 'x'.repeat(70) + ' Sobrenome', 'Maria ' + 'y'.repeat(90)])
  caso('cadastro.nomeDoGoogle', JSON.stringify(n.length > 30 ? n.slice(0, 30) + '…' : n), [n], K.nomeDoGoogle);
caso('cadastro.nomeDoGoogle', 'nulo', [null], K.nomeDoGoogle);
const CODIGOS_SOCIAIS = ['auth/popup-closed-by-user', 'auth/cancelled-popup-request', 'auth/user-cancelled', 'quota-exceeded-for-quota-metric-x',
  '1000', 1000, 'auth/account-exists-with-different-credential', 'auth/unauthorized-domain', 'auth/operation-not-allowed',
  'auth/operation-not-supported-in-this-environment', 'auth/web-storage-unsupported', 'auth/network-request-failed', 'auth/too-many-requests',
  'auth/algo-novo', null];
for(const provedor of ['apple.com', 'google.com', 'outro'])
  for(const code of CODIGOS_SOCIAIS) caso('cadastro.mensagemErroSocial', `${provedor} ${JSON.stringify(code)}`, [code, provedor], K.mensagemErroSocial);
for(const code of ['auth/popup-closed-by-user', 'auth/network-request-failed', '1000'])
  caso('cadastro.mensagemErroGoogle', String(code), [code], K.mensagemErroGoogle);
const CODIGOS_SENHA = ['auth/invalid-credential', 'auth/wrong-password', 'auth/user-not-found', 'auth/email-already-in-use', 'auth/invalid-email',
  'auth/weak-password', 'auth/too-many-requests', 'quota-exceeded-for-quota-metric-x', 'auth/network-request-failed', 'auth/algo-novo', null];
for(const tela of ['login', 'cadastro', 'redefinir'])
  for(const code of CODIGOS_SENHA) caso('cadastro.mensagemErroSenha', `${tela} ${code}`, [code, tela], K.mensagemErroSenha);

```

Run: `npm run vetores && node --test tests/vetores.test.mjs`
Expected: `tests/vetores/calc.json: 62 grupos, 670 casos` (os 547 casos da `main` de 08/10 mais 123 do cadastro) e 5 testes verdes.

No parágrafo **Vetores compartilhados** do `CLAUDE.md`, troque "as regras de `calc.js`, `dados.js` e a chave do token do `push.js`" por "as regras de `calc.js`, `dados.js`, `cadastro.js` e a chave do token do `push.js`", e no comentário do `npm run vetores` (bloco de comandos), troque "casos de calc.js, dados.js e push.js" por "casos de calc.js, dados.js, push.js e cadastro.js". No `app-ios.yml`, acrescente `- 'cadastro.js'` aos caminhos depois de `- 'push.js'`; no `tests/workflow.test.cjs`, acrescente `'cadastro.js'` à lista de caminhos depois de `'push.js'`.

- [ ] **Step 3: Escrever o teste Swift que falha**

`app-ios/CusttaNucleo/Tests/CusttaNucleoTests/CadastroTests.swift`:

```swift
import Testing
@testable import CusttaNucleo

private func texto(_ v: ValorJSON?) -> String? {
    switch v {
    case .texto(let s)?: return s
    case .numero(let n)?: return numeroJS(n)
    default: return nil
    }
}

extension ResultadoSenha {
    var json: ValorJSON {
        .objeto(["ok": .booleano(ok), "erro": .texto(erro),
                 "regras": .lista(regras.map { .objeto(["id": .texto($0.id), "texto": .texto($0.texto), "ok": .booleano($0.ok)]) })])
    }
}
extension ResultadoPerfil {
    var json: ValorJSON {
        .objeto(["ok": .booleano(ok), "campo": .texto(campo), "erro": .texto(erro), "perfil": perfil.map { .objeto($0.campos) } ?? .nulo])
    }
}

struct CadastroTests {
    @Test func constantesIguaisAoSite() {
        #expect(.lista(regrasSenha.map { .objeto(["id": .texto($0.id), "texto": .texto($0.texto)]) }) == Vetores.casos("cadastro.REGRAS_SENHA")[0].saida)
        let o = origens.map { o -> ValorJSON in
            var c: [String: ValorJSON] = ["id": .texto(o.id), "nome": .texto(o.nome)]
            if let d = o.detalhe { c["detalhe"] = .texto(d) }
            return .objeto(c)
        }
        #expect(.lista(o) == Vetores.casos("cadastro.ORIGENS")[0].saida)
        #expect(.objeto(["nome": .numero(60), "sobrenome": .numero(80), "origemDetalhe": .numero(80)]) == Vetores.casos("cadastro.LIMITES_PERFIL")[0].saida)
        #expect(LimitesPerfil.nome == 60 && LimitesPerfil.sobrenome == 80 && LimitesPerfil.origemDetalhe == 80)
    }

    @Test func senha() {
        for c in Vetores.casos("cadastro.validaSenha") {
            confere(validaSenha(texto(c.arg(0)), email: texto(c.arg(1))).json, c.saida, .exata, c.caso)
        }
    }

    @Test func nome() {
        for c in Vetores.casos("cadastro.normalizaNome") {
            let d = c.arg(0)?.comoObjeto
            confere(normalizaNome(nome: texto(d?["nome"]), sobrenome: texto(d?["sobrenome"])).json, c.saida, .exata, c.caso)
        }
    }

    @Test func perfil() {
        for c in Vetores.casos("cadastro.normalizaPerfil") {
            let d = c.arg(0)?.comoObjeto
            let opcional = c.arg(1)?.comoObjeto?["nomeOpcional"] == .booleano(true)
            let r = normalizaPerfil(nome: texto(d?["nome"]), sobrenome: texto(d?["sobrenome"]), origem: texto(d?["origem"]),
                                    origemDetalhe: texto(d?["origemDetalhe"]), nomeOpcional: opcional)
            confere(r.json, c.saida, .exata, c.caso)
        }
    }

    @Test func nomeVindoDoGoogleOuDaApple() {
        for c in Vetores.casos("cadastro.nomeDoGoogle") {
            let (n, s) = nomeDoGoogle(texto(c.arg(0)))
            #expect(ValorJSON.objeto(["nome": .texto(n), "sobrenome": .texto(s)]) == c.saida, "\(c.caso)")
        }
    }

    @Test func mensagensDeErro() {
        for c in Vetores.casos("cadastro.mensagemErroSocial") {
            #expect(mensagemErroSocial(codigo: texto(c.arg(0)), provedor: texto(c.arg(1))) == c.saida.comoTexto, "\(c.caso)")
        }
        for c in Vetores.casos("cadastro.mensagemErroGoogle") {
            #expect(mensagemErroSocial(codigo: texto(c.arg(0)), provedor: "google.com") == c.saida.comoTexto, "\(c.caso)")
        }
        for c in Vetores.casos("cadastro.mensagemErroSenha") {
            #expect(mensagemErroSenha(codigo: texto(c.arg(0)), tela: texto(c.arg(1))) == c.saida.comoTexto, "\(c.caso)")
        }
    }
}
```

A `CoberturaTests` da Parte A lê os próprios arquivos de teste: os grupos do cadastro passam a contar sozinhos quando o `CadastroTests` lê os casos deles (até lá ela falha, como deve).

Run: `swift test --package-path app-ios/CusttaNucleo --filter CadastroTests`
Expected: FAIL na compilação: `cannot find type 'ResultadoSenha' in scope`.

- [ ] **Step 4: Implementar e ver passar**

`app-ios/CusttaNucleo/Sources/CusttaNucleo/Cadastro.swift`:

```swift
import Foundation

/* Porte do cadastro.js: regras de senha, nome e "como conheceu", e as mensagens de erro de login.
   As firestore.rules repetem os limites e a lista de origens: mudou aqui, muda lá e no site.
   Tamanhos contam unidades UTF-16, como o `length` do JavaScript (mais restritivo que as rules). */

public struct RegraSenha: Equatable, Sendable {
    public let id: String
    public let texto: String
}

public let regrasSenha: [RegraSenha] = [
    RegraSenha(id: "tamanho", texto: "8 caracteres ou mais"),
    RegraSenha(id: "letra", texto: "Uma letra"),
    RegraSenha(id: "numero", texto: "Um número"),
    RegraSenha(id: "email", texto: "Diferente do e-mail"),
    RegraSenha(id: "comum", texto: "Não é uma senha óbvia"),
]

private let errosSenha = ["tamanho": "Use pelo menos 8 caracteres.", "letra": "Inclua pelo menos uma letra.",
                          "numero": "Inclua pelo menos um número.", "email": "A senha não pode ser igual ao e-mail.",
                          "comum": "Essa senha é muito comum. Escolha outra."]

/// Lista curta de propósito: pega o óbvio que passaria nas outras regras.
private let senhasComuns: Set<String> = ["senha123", "senha1234", "12345678a", "123456789a", "a12345678", "abc12345", "abcd1234",
    "qwerty123", "password1", "password123", "custta123", "obra1234", "mudar123", "brasil123", "admin123"]

public struct RegraAvaliada: Equatable, Sendable {
    public let id: String
    public let texto: String
    public let ok: Bool
}

public struct ResultadoSenha: Equatable, Sendable {
    public let ok: Bool
    public let regras: [RegraAvaliada]
    public let erro: String
}

private func ehLetra(_ u: Unicode.Scalar) -> Bool {
    switch u.properties.generalCategory {
    case .uppercaseLetter, .lowercaseLetter, .titlecaseLetter, .modifierLetter, .otherLetter: return true
    default: return false
    }
}

/// `validaSenha` do cadastro.js; o checklist da tela usa `regras`.
public func validaSenha(_ senha: String?, email: String?) -> ResultadoSenha {
    let s = senha ?? ""
    let chave = aparadoJS(s).lowercased()
    let e = aparadoJS(email ?? "").lowercased()
    let passa: [String: Bool] = [
        "tamanho": s.utf16.count >= 8,
        "letra": s.unicodeScalars.contains(where: ehLetra),
        "numero": s.unicodeScalars.contains(where: ehDigito),
        "email": !(!e.isEmpty && chave == e),
        "comum": !senhasComuns.contains(chave),
    ]
    let regras = regrasSenha.map { RegraAvaliada(id: $0.id, texto: $0.texto, ok: passa[$0.id]!) }
    if let falha = regras.first(where: { !$0.ok }) { return ResultadoSenha(ok: false, regras: regras, erro: errosSenha[falha.id]!) }
    if s.utf16.count > 128 { return ResultadoSenha(ok: false, regras: regras, erro: "Use no máximo 128 caracteres.") }
    return ResultadoSenha(ok: true, regras: regras, erro: "")
}

public struct Origem: Equatable, Sendable {
    public let id: String
    public let nome: String
    /// Rótulo do campo de detalhe, quando a origem tem um.
    public let detalhe: String?
}

public let origens: [Origem] = [
    Origem(id: "instagram", nome: "Instagram", detalhe: nil),
    Origem(id: "indicacao", nome: "Indicação de alguém", detalhe: "Quem indicou? (opcional)"),
    Origem(id: "google", nome: "Pesquisa no Google", detalhe: nil),
    Origem(id: "tiktok", nome: "TikTok", detalhe: nil),
    Origem(id: "youtube", nome: "YouTube", detalhe: nil),
    Origem(id: "outro", nome: "Outro", detalhe: "Onde? (opcional)"),
]

public enum LimitesPerfil {
    public static let nome = 60
    public static let sobrenome = 80
    public static let origemDetalhe = 80
}

/// O que vai para `perfis/{uid}` além de e-mail, data e fuso.
public struct PerfilCadastro: Equatable, Sendable {
    public var nome: String?
    public var sobrenome: String?
    public var origem: String?
    public var origemDetalhe: String?

    public init(nome: String? = nil, sobrenome: String? = nil, origem: String? = nil, origemDetalhe: String? = nil) {
        self.nome = nome; self.sobrenome = sobrenome; self.origem = origem; self.origemDetalhe = origemDetalhe
    }

    /// Só as chaves presentes, como o objeto `perfil` do site.
    public var campos: [String: ValorJSON] {
        var c: [String: ValorJSON] = [:]
        if let nome { c["nome"] = .texto(nome) }
        if let sobrenome { c["sobrenome"] = .texto(sobrenome) }
        if let origem { c["origem"] = .texto(origem) }
        if let origemDetalhe { c["origemDetalhe"] = .texto(origemDetalhe) }
        return c
    }
}

public struct ResultadoPerfil: Equatable, Sendable {
    public let ok: Bool
    /// Campo com problema ("nome", "sobrenome", "origem", "origemDetalhe"); "" quando ok.
    public let campo: String
    public let erro: String
    public let perfil: PerfilCadastro?

    static func falhou(_ campo: String, _ erro: String) -> ResultadoPerfil { ResultadoPerfil(ok: false, campo: campo, erro: erro, perfil: nil) }
}

/// `limpa` do cadastro.js: tira os espaços das pontas e junta os do meio num só.
func limpa(_ s: String?) -> String {
    var r = ""
    var espaco = false
    for u in aparadoJS(s ?? "").unicodeScalars {
        if ehEspacoJS(u) { espaco = true; continue }
        if espaco { r.append(" "); espaco = false }
        r.unicodeScalars.append(u)
    }
    return r
}

/// `normalizaNome` do cadastro.js.
public func normalizaNome(nome: String?, sobrenome: String?) -> ResultadoPerfil {
    let n = limpa(nome), s = limpa(sobrenome)
    if n.isEmpty { return .falhou("nome", "Digite seu nome.") }
    if n.utf16.count < 2 { return .falhou("nome", "O nome precisa de pelo menos 2 letras.") }
    if n.utf16.count > LimitesPerfil.nome { return .falhou("nome", "Use no máximo 60 caracteres no nome.") }
    if s.utf16.count > LimitesPerfil.sobrenome { return .falhou("sobrenome", "Use no máximo 80 caracteres no sobrenome.") }
    return ResultadoPerfil(ok: true, campo: "", erro: "", perfil: PerfilCadastro(nome: n, sobrenome: s.isEmpty ? nil : s))
}

/// `normalizaPerfil` do cadastro.js. `nomeOpcional`: conta Apple, cujo nome vem da Apple e a tela não pede de novo.
public func normalizaPerfil(nome: String?, sobrenome: String?, origem: String?, origemDetalhe: String?,
                            nomeOpcional: Bool = false) -> ResultadoPerfil {
    var base = normalizaNome(nome: nome, sobrenome: sobrenome)
    if !base.ok && nomeOpcional { base = ResultadoPerfil(ok: true, campo: "", erro: "", perfil: PerfilCadastro()) }
    if !base.ok { return base }
    guard let o = origens.first(where: { $0.id == origem }) else { return .falhou("origem", "Conte como conheceu o Custta.") }
    var perfil = base.perfil!
    perfil.origem = o.id
    if o.detalhe != nil {
        let detalhe = limpa(origemDetalhe)
        if detalhe.utf16.count > LimitesPerfil.origemDetalhe { return .falhou("origemDetalhe", "Use no máximo 80 caracteres.") }
        if !detalhe.isEmpty { perfil.origemDetalhe = detalhe }
    }
    return ResultadoPerfil(ok: true, campo: "", erro: "", perfil: perfil)
}

/// Os primeiros `n` unidades UTF-16, sem partir um emoji ao meio.
func prefixoUTF16(_ s: String, _ n: Int) -> String {
    var r = String.UnicodeScalarView()
    var usadas = 0
    for u in s.unicodeScalars {
        let tamanho = u.utf16.count
        if usadas + tamanho > n { break }
        r.append(u)
        usadas += tamanho
    }
    return String(r)
}

/// `nomeDoGoogle` do cadastro.js: a primeira palavra é o nome, o resto o sobrenome, cortados nos limites.
public func nomeDoGoogle(_ nomeDeExibicao: String?) -> (nome: String, sobrenome: String) {
    let partes = limpa(nomeDeExibicao).split(separator: " ").map(String.init)
    return (prefixoUTF16(partes.first ?? "", LimitesPerfil.nome),
            prefixoUTF16(partes.dropFirst().joined(separator: " "), LimitesPerfil.sobrenome))
}

private let desistiu: Set<String> = ["auth/popup-closed-by-user", "auth/cancelled-popup-request", "auth/user-cancelled"]
private let muitasTentativas = "Muitas tentativas. Espere um pouco."

/// `mensagemErroSocial` do cadastro.js; "" quando a pessoa desistiu (não é erro para mostrar).
public func mensagemErroSocial(codigo: String?, provedor: String?) -> String {
    let apple = provedor == "apple.com"
    let curto = apple ? "com a Apple" : "com Google"
    let longo = apple ? "com a Apple" : "com o Google"
    guard let c = codigo else { return "Não deu certo entrar \(longo). Tente de novo." }
    if desistiu.contains(c) { return "" }
    if c.contains("quota-exceeded") { return muitasTentativas }
    if c == "1000" && apple { return "Confira se o iPhone está conectado a um ID Apple (em Ajustes) ou entre com e-mail e senha." }
    switch c {
    case "auth/account-exists-with-different-credential": return "Este e-mail já tem conta no Custta. Entre do jeito que você usou da primeira vez."
    case "auth/unauthorized-domain": return "Login \(curto) indisponível neste endereço. Use custta.com.br."
    case "auth/operation-not-allowed": return "Login \(curto) ainda não está disponível. Use e-mail e senha."
    case "auth/operation-not-supported-in-this-environment", "auth/web-storage-unsupported":
        return "Seu navegador bloqueou o login \(curto). Use e-mail e senha."
    case "auth/network-request-failed": return "Sem internet. Conecte pra entrar."
    case "auth/too-many-requests": return muitasTentativas
    default: return "Não deu certo entrar \(longo). Tente de novo."
    }
}

/// `mensagemErroSenha` do cadastro.js; `tela` é "login", "cadastro" ou "redefinir".
public func mensagemErroSenha(codigo: String?, tela: String?) -> String {
    let c = codigo ?? ""
    if c.contains("invalid-credential") || c.contains("wrong-password") || c.contains("user-not-found") { return "E-mail ou senha incorretos." }
    if c.contains("email-already-in-use") { return "Este e-mail já tem conta. Use \"Entrar\"." }
    if c.contains("invalid-email") { return "E-mail inválido." }
    if c.contains("weak-password") { return "Senha fraca: use 8 caracteres ou mais, com letra e número." }
    if c.contains("too-many-requests") {
        return tela == "login" ? "Muitas tentativas. Espere alguns minutos ou redefina a senha em \"Esqueci minha senha\"." : muitasTentativas
    }
    if c.contains("quota-exceeded") { return muitasTentativas }
    if c.contains("network-request-failed") { return "Sem internet. Conecte pra entrar." }
    return "Não deu certo. Tente de novo."
}
```

Run: `swift test --package-path app-ios/CusttaNucleo && npm run test:unit`
Expected: núcleo inteiro verde (com `CadastroTests`, 6 testes, e a `CoberturaTests` achando nele os grupos do cadastro) e `test:unit` verde.

- [ ] **Step 5: Commit**

```bash
git add scripts/vetores-calc.mjs tests/vetores/calc.json tests/vetores.test.mjs CLAUDE.md .github/workflows/app-ios.yml tests/workflow.test.cjs app-ios/CusttaNucleo
git commit -m "feat: regras do cadastro do site no núcleo do app nativo" -m "Senha com as cinco regras e o limite de 128, nome e sobrenome com os limites das rules, origem com o detalhe opcional, nome vindo do Google ou da Apple e as mensagens de erro de login: o mesmo cadastro.js, conferido pelos vetores (cadastro.js entra no gerador e no teste de cobertura). Tamanhos em unidades UTF-16, como o length do JavaScript."
```

---

### Task 7: Regras das telas e códigos de erro do Firebase

**Files:**
- Create: `app-ios/CusttaNucleo/Sources/CusttaNucleo/Telas.swift`
- Create: `app-ios/CusttaNucleo/Sources/CusttaNucleo/ErrosFirebase.swift`
- Test: `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/TelasTests.swift`, `ErrosFirebaseTests.swift`

**Interfaces:**
- Consumes: `normalizaPerfil`, `validaSenha`, `PerfilCadastro`, `mensagemErroSocial`, `mensagemErroSenha` (Tarefa 6); `totalCorrigido`, `ordenadoEstavel`, `menorJS`, `moedaCurtaSemZero`, `numeroJS`, `orcamentoObra`, `Fase`, `Obra`, `erroEhTerminal` (Parte A).
- Produces: `public func emailParece(_:) -> Bool`; `public func validarEntrada(email:senha:) -> String?`; `public enum ResultadoCadastro { case ok(PerfilCadastro), falhou(campo: String, erro: String) }`; `public func validarCadastro(nome:sobrenome:email:senha:confirmacao:origem:origemDetalhe:) -> ResultadoCadastro`; `Fase.rotulo: String`; `public func obrasOrdenadas(_:) -> [Obra]`; `public func textoOrcamentoNaLista(_:) -> String`; `public struct LinhaComparativo: Identifiable { id, nome: String; bruto, corrigido, fracaoBruto, fracaoCorrigido: Double }`; `public func comparativoEntreObras(_:taxa:hoje:) -> [LinhaComparativo]`; `public func textoErroDeLeitura(_ codigo: String) -> String`; `public enum Nonce { static func gerar() -> String; static func sha256(_:) -> String }`; `public let dominioAuth, dominioFirestore, dominioApple, dominioGoogle: String`; `public func codigoDeErroDeConta(dominio:codigo:) -> String`; `public func codigoDeErroFirestore(dominio:codigo:) -> String`; `public func sessaoInvalida(_:) -> Bool`.

- [ ] **Step 1: Escrever os testes que falham**

`app-ios/CusttaNucleo/Tests/CusttaNucleoTests/TelasTests.swift`:

```swift
import Testing
@testable import CusttaNucleo

struct TelasTests {
    /// Saídas do /^\S+@\S+\.\S+$/ do auth.js, conferidas no Node.
    @Test func emailComoORegexDoSite() {
        let casos: [(String, Bool)] = [("a@b.c", true), ("joao@exemplo.com", true), ("a@@b.c", true), ("a@b.", false), ("a@.b", false),
            ("a.b@c", false), ("@b.c", false), ("a@b", false), ("a b@c.d", false), (" a@b.c", false), ("a@b.c ", false), ("a@b.c.d", true),
            ("a@b..c", true), ("ção@é.br", true), ("a@b\u{00A0}.c", false), ("", false), ("a@.b.c", true), ("a.@b.c", true)]
        for (email, esperado) in casos { #expect(emailParece(email) == esperado, "\(email)") }
    }

    @Test func entrarPedeEmailESenha() {
        #expect(validarEntrada(email: "joao", senha: "x") == "Digite seu e-mail.")
        #expect(validarEntrada(email: " joao@exemplo.com ", senha: "") == "Digite a senha.")
        #expect(validarEntrada(email: "joao@exemplo.com", senha: "x") == nil)
    }

    @Test func cadastroNaOrdemDoSite() {
        func v(nome: String = "Ana", email: String = "ana@exemplo.com", senha: String = "Casa2026x", confirmacao: String = "Casa2026x",
               origem: String? = "google", detalhe: String = "") -> ResultadoCadastro {
            validarCadastro(nome: nome, sobrenome: "", email: email, senha: senha, confirmacao: confirmacao, origem: origem, origemDetalhe: detalhe)
        }
        #expect(v(nome: "A", email: "errado", senha: "x", confirmacao: "y", origem: nil) == .falhou(campo: "nome", erro: "O nome precisa de pelo menos 2 letras."))
        #expect(v(email: "errado", senha: "x", confirmacao: "y", origem: nil) == .falhou(campo: "email", erro: "E-mail inválido."))
        #expect(v(senha: "curta1", confirmacao: "y", origem: nil) == .falhou(campo: "senha", erro: "Use pelo menos 8 caracteres."))
        #expect(v(confirmacao: "outra", origem: nil) == .falhou(campo: "confirmacao", erro: "As senhas não são iguais."))
        #expect(v(origem: nil) == .falhou(campo: "origem", erro: "Conte como conheceu o Custta."))
        #expect(v(origem: "outro", detalhe: String(repeating: "z", count: 81)) == .falhou(campo: "origemDetalhe", erro: "Use no máximo 80 caracteres."))
        #expect(v() == .ok(PerfilCadastro(nome: "Ana", origem: "google")))
    }

    @Test func listaDeObrasNaOrdemDoSite() {
        let estado = Estado.de(.objeto(["obras": .lista([
            .objeto(["id": .texto("v"), "nome": .texto("Vendida nova"), "dataInicio": .texto("2026-05-01"), "fase": .texto("vendida"),
                     "venda": .objeto(["valor": .numero(1), "data": .texto("2026-06-01")])]),
            .objeto(["id": .texto("a"), "nome": .texto("Antiga"), "dataInicio": .texto("2024-01-01")]),
            .objeto(["id": .texto("n"), "nome": .texto("Nova"), "dataInicio": .texto("2026-01-01"), "fase": .texto("pronta")]),
        ])]))
        #expect(obrasOrdenadas(estado.obras).map(\.id) == ["n", "a", "v"])
        #expect(estado.obras.map(\.fase.rotulo) == ["Vendida", "Em construção", "Pronta · à venda"])
    }

    @Test func textoDoOrcamentoNaLista() {
        func obra(total: Double, gasto: Double) -> Obra {
            Estado.de(.objeto(["obras": .lista([.objeto(["id": .texto("o"), "dataInicio": .texto("2026-01-01"),
                "orcamento": .objeto(["modo": .texto("total"), "total": .numero(total)]),
                "gastos": .lista([.objeto(["id": .texto("g"), "valor": .numero(gasto), "data": .texto("2026-01-02")])])])])])).obras[0]
        }
        #expect(textoOrcamentoNaLista(orcamentoObra(obra(total: 100_000, gasto: 45_000))!) == "45% do orçamento")
        #expect(textoOrcamentoNaLista(orcamentoObra(obra(total: 100_000, gasto: 108_000))!) == "108% · passou R$ 8 mil")
    }

    /// Valores do totalCorrigido do calc.js, conferidos no Node.
    @Test func comparativoComoODoSite() {
        let estado = Estado.de(.objeto(["obras": .lista([
            .objeto(["id": .texto("b"), "nome": .texto("B"), "dataInicio": .texto("2025-01-01"), "fase": .texto("vendida"),
                     "venda": .objeto(["valor": .numero(1), "data": .texto("2026-01-01")]),
                     "gastos": .lista([.objeto(["id": .texto("h"), "valor": .numero(50_000), "data": .texto("2025-01-01")])])]),
            .objeto(["id": .texto("s"), "nome": .texto("Sem gasto"), "dataInicio": .texto("2026-02-01")]),
            .objeto(["id": .texto("a"), "nome": .texto("A"), "dataInicio": .texto("2026-01-01"),
                     "gastos": .lista([.objeto(["id": .texto("g"), "valor": .numero(100_000), "data": .texto("2026-01-01")])])]),
        ])]))
        let linhas = comparativoEntreObras(estado.obras, taxa: 1, hoje: "2026-07-01")
        #expect(linhas.map(\.id) == ["a", "b"], "só as obras com gasto, na ordem da lista")
        #expect(abs(linhas[0].corrigido - 106_095.12340622896) < 1e-6)
        #expect(abs(linhas[1].corrigido - 56_336.09497694363) < 1e-6, "a vendida corrige até a venda")
        #expect(linhas[0].fracaoCorrigido == 1)
        #expect(abs(linhas[1].fracaoBruto - 50_000 / 106_095.12340622896) < 1e-12)
        #expect(comparativoEntreObras(Array(estado.obras.prefix(2)), taxa: 1, hoje: "2026-07-01").isEmpty,
                "com uma só obra com gasto não há comparativo")
    }

    @Test func erroDeLeituraDizQueNadaFoiAlterado() {
        #expect(textoErroDeLeitura("formato-desconhecido").contains("formato"))
        for codigo in ["formato-desconhecido", "permission-denied", "unavailable"] {
            #expect(textoErroDeLeitura(codigo).contains("Nada foi alterado"), "\(codigo)")
        }
    }

    @Test func nonceDaApple() {
        let n = Nonce.gerar()
        #expect(n.count == 64 && n.allSatisfy(\.isHexDigit))
        #expect(Nonce.gerar() != n)
        #expect(Nonce.sha256("abc") == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
    }
}
```

`app-ios/CusttaNucleo/Tests/CusttaNucleoTests/ErrosFirebaseTests.swift`:

```swift
import Testing
@testable import CusttaNucleo

struct ErrosFirebaseTests {
    @Test func contaNoFormatoDoSite() {
        #expect(codigoDeErroDeConta(dominio: dominioAuth, codigo: 17009) == "auth/wrong-password")
        #expect(codigoDeErroDeConta(dominio: dominioAuth, codigo: 17020) == "auth/network-request-failed")
        #expect(codigoDeErroDeConta(dominio: dominioAuth, codigo: 17052) == "auth/quota-exceeded")
        #expect(codigoDeErroDeConta(dominio: dominioAuth, codigo: 99999) == "auth/erro-99999")
        #expect(codigoDeErroDeConta(dominio: dominioApple, codigo: 1001) == "auth/user-cancelled")
        #expect(codigoDeErroDeConta(dominio: dominioApple, codigo: 1000) == "1000")
        #expect(codigoDeErroDeConta(dominio: dominioGoogle, codigo: -5) == "auth/user-cancelled")
        #expect(codigoDeErroDeConta(dominio: "NSURLErrorDomain", codigo: -1009) == "auth/network-request-failed")
        #expect(mensagemErroSocial(codigo: codigoDeErroDeConta(dominio: dominioApple, codigo: 1001), provedor: "apple.com") == "")
        #expect(mensagemErroSenha(codigo: codigoDeErroDeConta(dominio: dominioAuth, codigo: 17004), tela: "login") == "E-mail ou senha incorretos.")
    }

    @Test func firestoreNoFormatoDoSite() {
        #expect(codigoDeErroFirestore(dominio: dominioFirestore, codigo: 7) == "permission-denied")
        #expect(codigoDeErroFirestore(dominio: dominioFirestore, codigo: 14) == "unavailable")
        #expect(codigoDeErroFirestore(dominio: dominioFirestore, codigo: 16) == "unauthenticated")
        #expect(codigoDeErroFirestore(dominio: "outro", codigo: 7) == "desconhecido")
        #expect(erroEhTerminal(codigo: codigoDeErroFirestore(dominio: dominioFirestore, codigo: 3)))
        #expect(!erroEhTerminal(codigo: codigoDeErroFirestore(dominio: dominioFirestore, codigo: 14)))
    }

    @Test func sessaoQueEncerraAConta() {
        #expect(sessaoInvalida("auth/user-token-expired"))
        #expect(sessaoInvalida("auth/user-not-found"))
        #expect(!sessaoInvalida("auth/network-request-failed"), "falta de rede nunca desloga")
    }
}
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `swift test --package-path app-ios/CusttaNucleo --filter "TelasTests|ErrosFirebaseTests"`
Expected: FAIL na compilação: `cannot find 'emailParece' in scope`.

- [ ] **Step 3: Implementar**

`app-ios/CusttaNucleo/Sources/CusttaNucleo/Telas.swift`:

```swift
import Foundation
import CryptoKit
import Security

/* Regras das telas da etapa 1 que não dependem de SwiftUI nem do Firebase: validação dos
   formulários de conta (na ordem do auth.js), ordem e textos da lista de obras e o nonce do
   login com a Apple. */

/// O `/^\S+@\S+\.\S+$/` do auth.js: sem espaço, com "@" e um ponto depois dele que não é a primeira nem a última letra.
public func emailParece(_ email: String) -> Bool {
    let u = Array(email.unicodeScalars)
    if u.isEmpty || u.contains(where: ehEspacoJS) { return false }
    for (i, c) in u.enumerated() where c == "@" && i >= 1 {
        let resto = Array(u[(i + 1)...])
        if resto.count >= 3, resto[1...(resto.count - 2)].contains(".") { return true }
    }
    return false
}

/// Mensagem do formulário de entrar (auth.js), ou nil se pode tentar.
public func validarEntrada(email: String, senha: String) -> String? {
    if !emailParece(aparadoJS(email)) { return "Digite seu e-mail." }
    if senha.isEmpty { return "Digite a senha." }
    return nil
}

public enum ResultadoCadastro: Equatable, Sendable {
    case ok(PerfilCadastro)
    /// `campo`: "nome", "sobrenome", "email", "senha", "confirmacao", "origem" ou "origemDetalhe".
    case falhou(campo: String, erro: String)
}

/// Validação do criar conta na ordem do auth.js: nome e sobrenome, e-mail, senha, confirmação, origem.
public func validarCadastro(nome: String, sobrenome: String, email: String, senha: String, confirmacao: String,
                            origem: String?, origemDetalhe: String) -> ResultadoCadastro {
    let perfil = normalizaPerfil(nome: nome, sobrenome: sobrenome, origem: origem, origemDetalhe: origemDetalhe)
    if !perfil.ok && (perfil.campo == "nome" || perfil.campo == "sobrenome") { return .falhou(campo: perfil.campo, erro: perfil.erro) }
    let e = aparadoJS(email)
    if !emailParece(e) { return .falhou(campo: "email", erro: "E-mail inválido.") }
    let regra = validaSenha(senha, email: e)
    if !regra.ok { return .falhou(campo: "senha", erro: regra.erro) }
    if confirmacao != senha { return .falhou(campo: "confirmacao", erro: "As senhas não são iguais.") }
    if !perfil.ok { return .falhou(campo: perfil.campo, erro: perfil.erro) }
    return .ok(perfil.perfil!)
}

public extension Fase {
    /// Rótulo da fase no site (FASES do app.js).
    var rotulo: String {
        switch self {
        case .construcao: return "Em construção"
        case .pronta: return "Pronta · à venda"
        case .vendida: return "Vendida"
        }
    }
}

/// Ordem da lista de obras do app.js: não vendidas primeiro, depois a que começou mais recente.
public func obrasOrdenadas(_ obras: [Obra]) -> [Obra] {
    ordenadoEstavel(obras) { a, b in
        let va = a.fase == .vendida, vb = b.fase == .vendida
        if va != vb { return !va }
        return menorJS(b.dataInicio, a.dataInicio)
    }
}

/// Texto da linha de orçamento na lista de obras: "X% do orçamento" ou "X% · passou R$ Y".
public func textoOrcamentoNaLista(_ r: ResumoOrcamento) -> String {
    let pct = numeroJS(r.geral.pct)
    return r.geral.nivel == .passou ? "\(pct)% · passou \(moedaCurtaSemZero(-r.geral.sobra))" : "\(pct)% do orçamento"
}

/// Texto da lista de obras quando a leitura falha antes de carregar. Nada foi gravado: o app só grava
/// depois de ver os dados (Sincronizador).
public func textoErroDeLeitura(_ codigo: String) -> String {
    if codigo == "formato-desconhecido" {
        return "Seus dados na nuvem têm um formato que este app ainda não sabe ler. Nada foi alterado: as obras continuam salvas como estavam."
    }
    return "Não deu para buscar suas obras agora. Confira a internet e tente de novo. Nada foi alterado: as obras continuam salvas como estavam."
}

/// Nonce do login com a Apple: 32 bytes aleatórios em hexadecimal (a Apple assina o SHA-256 dele).
public enum Nonce {
    public static func gerar() -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        precondition(status == errSecSuccess, "SecRandomCopyBytes falhou: \(status)")
        return bytes.map { String(format: "%02x", $0) }.joined()
    }

    public static func sha256(_ texto: String) -> String {
        SHA256.hash(data: Data(texto.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}

/// Uma barra do "Comparativo entre obras" (drawComp do app.js): gasto bruto e corrigido pela taxa, com as
/// larguras em fração do maior corrigido.
public struct LinhaComparativo: Equatable, Sendable, Identifiable {
    public let id: String
    public let nome: String
    public let bruto: Double
    public let corrigido: Double
    public let fracaoBruto: Double
    public let fracaoCorrigido: Double
}

/// O comparativo da lista de obras: as obras com gasto, na ordem da lista; vazio com menos de duas.
public func comparativoEntreObras(_ obras: [Obra], taxa: Double, hoje: String) -> [LinhaComparativo] {
    let comGasto = obrasOrdenadas(obras).filter { totalBruto($0) > 0 }
    guard comGasto.count >= 2 else { return [] }
    let valores = comGasto.map { (obra: $0, bruto: totalBruto($0), corrigido: totalCorrigido($0, taxa: taxa, hoje: hoje)) }
    let maior = max(valores.map(\.corrigido).max() ?? 1, 1)
    return valores.map {
        LinhaComparativo(id: $0.obra.id, nome: $0.obra.nome, bruto: $0.bruto, corrigido: $0.corrigido,
                         fracaoBruto: $0.bruto / maior, fracaoCorrigido: $0.corrigido / maior)
    }
}
```

`app-ios/CusttaNucleo/Sources/CusttaNucleo/ErrosFirebase.swift`:

```swift
import Foundation

/* Os SDKs do iOS devolvem NSError com domínio e número; o site trabalha com os códigos do SDK
   JavaScript ("auth/wrong-password", "permission-denied"). Estas tabelas traduzem um no outro
   para as mensagens (cadastro) e a fila (erroEhTerminal) serem as mesmas do site.
   Números de FIRAuthErrors.h e FIRFirestoreErrors.h (códigos do gRPC). */

public let dominioAuth = "FIRAuthErrorDomain"
public let dominioFirestore = "FIRFirestoreErrorDomain"
public let dominioApple = "com.apple.AuthenticationServices.AuthorizationError"
public let dominioGoogle = "com.google.GIDSignIn"

private let errosAuth: [Int: String] = [
    17004: "auth/invalid-credential", 17005: "auth/user-disabled", 17006: "auth/operation-not-allowed",
    17007: "auth/email-already-in-use", 17008: "auth/invalid-email", 17009: "auth/wrong-password",
    17010: "auth/too-many-requests", 17011: "auth/user-not-found", 17012: "auth/account-exists-with-different-credential",
    17014: "auth/requires-recent-login", 17017: "auth/invalid-user-token", 17020: "auth/network-request-failed",
    17021: "auth/user-token-expired", 17026: "auth/weak-password", 17034: "auth/missing-email", 17052: "auth/quota-exceeded",
]

private let errosFirestore: [Int: String] = [
    1: "cancelled", 2: "unknown", 3: "invalid-argument", 4: "deadline-exceeded", 5: "not-found", 6: "already-exists",
    7: "permission-denied", 8: "resource-exhausted", 9: "failed-precondition", 10: "aborted", 11: "out-of-range",
    12: "unimplemented", 13: "internal", 14: "unavailable", 15: "data-loss", 16: "unauthenticated",
]

/// Código no formato do site para erro de login (Firebase Auth, Apple, Google ou rede).
public func codigoDeErroDeConta(dominio: String, codigo: Int) -> String {
    switch dominio {
    case dominioAuth: return errosAuth[codigo] ?? "auth/erro-\(codigo)"
    case dominioApple: return codigo == 1001 ? "auth/user-cancelled" : codigo == 1000 ? "1000" : "auth/apple-\(codigo)"
    case dominioGoogle: return codigo == -5 ? "auth/user-cancelled" : "auth/google-\(codigo)"
    case NSURLErrorDomain: return "auth/network-request-failed"
    default: return "auth/erro-\(codigo)"
    }
}

/// Código no formato do site para erro do Firestore ("permission-denied"); "desconhecido" fora do domínio.
public func codigoDeErroFirestore(dominio: String, codigo: Int) -> String {
    guard dominio == dominioFirestore else { return "desconhecido" }
    return errosFirestore[codigo] ?? "desconhecido"
}

/// Erros de sessão que encerram a conta no aparelho (SESSAO_INVALIDA do cloud.js). Falta de rede nunca está aqui.
/// `auth/invalid-refresh-token` fica pela paridade com o site: nenhum código do SDK iOS chega nele.
public func sessaoInvalida(_ codigo: String) -> Bool {
    ["auth/invalid-refresh-token", "auth/user-disabled", "auth/user-token-expired", "auth/user-not-found", "auth/invalid-user-token"].contains(codigo)
}
```

- [ ] **Step 4: Rodar e ver passar**

Run: `swift test --package-path app-ios/CusttaNucleo --filter "TelasTests|ErrosFirebaseTests"`
Expected: `Test run with 11 tests in 2 suites passed`. Os números das tabelas são conferidos contra as constantes dos próprios SDKs na Tarefa 13 (`ErrosDoSDKTests`), onde o Firebase e o GoogleSignIn já estão ligados.

- [ ] **Step 5: Commit**

```bash
git add app-ios/CusttaNucleo
git commit -m "feat: regras das telas de conta e códigos de erro do Firebase no núcleo" -m "Validação de entrar e de criar conta na ordem do auth.js, ordem e textos da lista de obras do app.js, nonce do login com a Apple e a tradução dos erros do Firebase iOS para os códigos do SDK JavaScript, para as mensagens e a fila serem as do site. Falta de rede nunca conta como sessão inválida."
```

---

### Task 8: Sincronizador

**Files:**
- Create: `app-ios/CusttaNucleo/Sources/CusttaNucleo/Sincronizador.swift`
- Create: `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/Falsos.swift`
- Test: `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/SincronizadorTests.swift`

**Interfaces:**
- Consumes: `Estado`, `normaliza`, `mesmoConteudo`, `tamanhoBlob`, `blobCabe`, `limiteBlob`, `avisoBlob`, `erroEhTerminal`, `proximoBackoff`, `ValorJSON` (Parte A).
- Produces:
  - `public enum OrigemErro: String { case escrita, leitura }`; `public enum EstadoSinc: Equatable { case ocioso, salvando, repetindo, offline, erro(codigo: String, origem: OrigemErro) }`
  - `public struct Instantaneo { dados: ValorJSON?; doCache: Bool; gravacaoPendente: Bool; init(dados:doCache:gravacaoPendente:) }`
  - `@MainActor public protocol Cancelavel: AnyObject { func cancelar() }`
  - `@MainActor public protocol TransporteDados: AnyObject { func escutar(uid:aoReceber:aoFalhar:) -> any Cancelavel; func gravar(uid:blob:concluir:); func aguardarGravacoesPendentes(concluir:) }` (retornos `@MainActor`; `concluir(nil)` = servidor confirmou, `concluir(codigo)` = erro)
  - `@MainActor public protocol Relogio: AnyObject { var agoraMs: Int64 { get }; func agendar(depois ms: Int, _ acao:) -> any Cancelavel }`
  - `public struct ErroSinc: Error, Equatable { let codigo: String }`
  - `public enum AvisoSinc: Equatable { case pertoDoLimite, naoSalvou(codigo:terminal:), naoLeu(codigo:); var mensagem: String }`
  - `public struct IndicadorSinc { rotulo: String; girando: Bool; erro: Bool; dica: String }`; `public func indicador(_ e: EstadoSinc) -> IndicadorSinc?`
  - `@MainActor @Observable public final class Sincronizador { estadoSinc: EstadoSinc; estado: Estado; dadosCarregados: Bool; aoAvisar: ((AvisoSinc) -> Void)?; aoPedirVerificacaoDeSessao: (() -> Void)?; init(transporte:relogio:online:); temPendencia: Bool; iniciar(uid:); parar(); salvar(_:) async throws; tentarDeNovo(); aguardarFila(timeoutMs:) async -> Bool; redeMudou(online:) }`. `dadosCarregados` só fica verdadeiro com snapshot do servidor ou de cache com documento, e volta a falso com `formato-desconhecido`; enquanto for falso, `salvar` lança `ErroSinc(codigo: "nao-carregado")`.

- [ ] **Step 1: Escrever os falsos e os testes que falham**

`app-ios/CusttaNucleo/Tests/CusttaNucleoTests/Falsos.swift`:

```swift
@testable import CusttaNucleo

/* Transporte e relógio falsos: o teste decide quando o servidor confirma, quando chega
   snapshot e quando o tempo passa. */

@MainActor final class TransporteFalso: TransporteDados {
    final class Escuta: Cancelavel {
        let uid: String
        let aoReceber: @MainActor (Instantaneo) -> Void
        let aoFalhar: @MainActor (String) -> Void
        var cancelada = false
        init(uid: String, aoReceber: @escaping @MainActor (Instantaneo) -> Void, aoFalhar: @escaping @MainActor (String) -> Void) {
            self.uid = uid; self.aoReceber = aoReceber; self.aoFalhar = aoFalhar
        }
        func cancelar() { cancelada = true }
    }
    struct Gravacao {
        let uid: String
        let blob: ValorJSON
        let concluir: @MainActor (String?) -> Void
    }

    var escutas: [Escuta] = []
    var gravacoes: [Gravacao] = []
    var esperasDePendentes: [@MainActor (String?) -> Void] = []

    func escutar(uid: String, aoReceber: @escaping @MainActor (Instantaneo) -> Void,
                 aoFalhar: @escaping @MainActor (String) -> Void) -> any Cancelavel {
        let e = Escuta(uid: uid, aoReceber: aoReceber, aoFalhar: aoFalhar)
        escutas.append(e)
        return e
    }
    func gravar(uid: String, blob: ValorJSON, concluir: @escaping @MainActor (String?) -> Void) {
        gravacoes.append(Gravacao(uid: uid, blob: blob, concluir: concluir))
    }
    func aguardarGravacoesPendentes(concluir: @escaping @MainActor (String?) -> Void) {
        esperasDePendentes.append(concluir)
    }

    /// Snapshot na escuta mais recente.
    func chega(_ dados: ValorJSON?, doCache: Bool = false, pendente: Bool = false) {
        escutas.last!.aoReceber(Instantaneo(dados: dados, doCache: doCache, gravacaoPendente: pendente))
    }
}

@MainActor final class RelogioFalso: Relogio {
    final class Agendado: Cancelavel {
        let quando: Int64
        let acao: @MainActor () -> Void
        var cancelado = false
        init(quando: Int64, acao: @escaping @MainActor () -> Void) { self.quando = quando; self.acao = acao }
        func cancelar() { cancelado = true }
    }
    var agoraMs: Int64 = 1_000_000
    var agendados: [Agendado] = []

    func agendar(depois ms: Int, _ acao: @escaping @MainActor () -> Void) -> any Cancelavel {
        let a = Agendado(quando: agoraMs + Int64(ms), acao: acao)
        agendados.append(a)
        return a
    }
    /// Esperas ainda valendo, em milissegundos a partir de agora.
    var proximos: [Int64] { agendados.filter { !$0.cancelado }.map { $0.quando - agoraMs } }

    func avancar(_ ms: Int) {
        agoraMs += Int64(ms)
        while let a = agendados.first(where: { !$0.cancelado && $0.quando <= agoraMs }) {
            a.cancelado = true
            a.acao()
        }
    }
}

/// Deixa as tarefas da fila principal andarem até a condição valer (ou desiste depois de 200 voltas).
@MainActor func ate(_ condicao: @MainActor () -> Bool) async {
    for _ in 0..<200 where !condicao() { await Task.yield() }
}

func blobCom(_ nomes: [String], taxa: Double = 1, extra: [String: ValorJSON] = [:]) -> ValorJSON {
    .objeto(["obras": .lista(nomes.enumerated().map { i, nome in
        .objeto(["id": .texto("o\(i)"), "nome": .texto(nome), "dataInicio": .texto("2026-01-01"), "gastos": .lista([])].merging(extra) { $1 })
    }), "config": .objeto(["taxaMensal": .numero(taxa), "topicosCustom": .lista([])])])
}

/// Roda a operação sem deixar o teste travar: o teste espera o fim com `ate` e, se ela não terminar,
/// falha em vez de esperar para sempre. O `.timeLimit` sozinho não basta: a espera de `salvar` não
/// responde a cancelamento, e o teste ficaria preso mesmo depois de registrar a falha.
@MainActor final class Desfecho {
    private(set) var terminou = false
    private(set) var erro: (any Error)?
    init(_ operacao: @escaping @MainActor () async throws -> Void) {
        Task { @MainActor in
            do { try await operacao() } catch { self.erro = error }
            self.terminou = true
        }
    }
}
```

`app-ios/CusttaNucleo/Tests/CusttaNucleoTests/SincronizadorTests.swift`:

```swift
import Testing
@testable import CusttaNucleo

@MainActor
struct SincronizadorEscritaTests {
    let transporte = TransporteFalso()
    let relogio = RelogioFalso()

    /// Conta aberta e já vista: o servidor respondeu que o documento ainda não existe.
    func montar(online: Bool = true) -> Sincronizador {
        let s = Sincronizador(transporte: transporte, relogio: relogio, online: online)
        s.iniciar(uid: "u1")
        transporte.chega(nil)
        return s
    }

    @Test func salvarEntregaNaHoraEVoltaSoComAConfirmacao() async throws {
        let s = montar()
        let tarefa = Task { try await s.salvar(Estado.de(blobCom(["Casa"]))) }
        await ate { transporte.gravacoes.count == 1 }
        #expect(transporte.gravacoes[0].uid == "u1")
        #expect(s.estadoSinc == .salvando)
        #expect(s.estado.obras.map(\.nome) == ["Casa"], "a tela vê a mudança antes do servidor")
        transporte.gravacoes[0].concluir(nil)
        try await tarefa.value
        #expect(s.estadoSinc == .ocioso)
        #expect(!s.temPendencia)
    }

    @Test func semRedeMostraSemConexaoEEnviaMesmoAssim() async throws {
        let s = montar(online: false)
        let tarefa = Task { try await s.salvar(Estado.de(blobCom(["Casa"]))) }
        await ate { transporte.gravacoes.count == 1 }
        #expect(s.estadoSinc == .offline)
        s.redeMudou(online: true)
        #expect(s.estadoSinc == .salvando)
        transporte.gravacoes[0].concluir(nil)
        try await tarefa.value
        #expect(s.estadoSinc == .ocioso)
    }

    @Test func soAConfirmacaoDaVersaoMaisNovaConta() async throws {
        let s = montar()
        let primeira = Task { try await s.salvar(Estado.de(blobCom(["A"]))) }
        await ate { transporte.gravacoes.count == 1 }
        let segunda = Task { try await s.salvar(Estado.de(blobCom(["A", "B"]))) }
        await ate { transporte.gravacoes.count == 2 }
        transporte.gravacoes[0].concluir(nil)
        #expect(s.estadoSinc == .salvando, "confirmação velha não encerra a fila")
        transporte.gravacoes[1].concluir(nil)
        try await primeira.value
        try await segunda.value
        #expect(s.estadoSinc == .ocioso)
    }

    @Test func erroTerminalParaERejeita() async {
        var avisos: [AvisoSinc] = []
        let s = montar()
        s.aoAvisar = { avisos.append($0) }
        let tarefa = Task { try await s.salvar(Estado.de(blobCom(["A"]))) }
        await ate { transporte.gravacoes.count == 1 }
        transporte.gravacoes[0].concluir("permission-denied")
        await #expect(throws: ErroSinc(codigo: "permission-denied")) { try await tarefa.value }
        #expect(s.estadoSinc == .erro(codigo: "permission-denied", origem: .escrita))
        #expect(relogio.proximos.isEmpty, "terminal não agenda nova tentativa")
        #expect(avisos == [.naoSalvou(codigo: "permission-denied", terminal: true)])
        #expect(indicador(s.estadoSinc)?.rotulo == "Não salvou")
    }

    @Test func erroTransitorioTentaDeNovoComBackoff() async throws {
        let s = montar()
        let tarefa = Task { try await s.salvar(Estado.de(blobCom(["A"]))) }
        await ate { transporte.gravacoes.count == 1 }
        transporte.gravacoes[0].concluir("unavailable")
        #expect(s.estadoSinc == .repetindo)
        #expect(relogio.proximos == [1000])
        relogio.avancar(1000)
        #expect(transporte.gravacoes.count == 2)
        transporte.gravacoes[1].concluir("unavailable")
        #expect(relogio.proximos == [2000])
        relogio.avancar(2000)
        transporte.gravacoes[2].concluir(nil)
        try await tarefa.value
        #expect(s.estadoSinc == .ocioso)
    }

    @Test func acimaDoLimiteNaoGravaEAvisa() async {
        var avisos: [AvisoSinc] = []
        let s = montar()
        s.aoAvisar = { avisos.append($0) }
        let grande = Estado.de(blobCom(["A"], extra: ["notas": .texto(String(repeating: "a", count: 900_000))]))
        await #expect(throws: ErroSinc(codigo: "limite")) { try await s.salvar(grande) }
        #expect(transporte.gravacoes.isEmpty)
        #expect(s.estadoSinc == .erro(codigo: "limite", origem: .escrita))
        #expect(avisos.last?.mensagem == "Não salvou: limite de dados atingido. Reduza os dados e tente novamente.")
    }

    @Test func pertoDoLimiteAvisaUmaVezAteVoltarParaBaixo() async throws {
        var avisos: [AvisoSinc] = []
        let s = montar()
        s.aoAvisar = { avisos.append($0) }
        let perto = Estado.de(blobCom(["A"], extra: ["notas": .texto(String(repeating: "a", count: 750_000))]))
        for i in 0..<2 {
            let t = Task { try await s.salvar(perto) }
            await ate { transporte.gravacoes.count == i + 1 }
            transporte.gravacoes[i].concluir(nil)
            try await t.value
        }
        #expect(avisos.filter { $0 == .pertoDoLimite }.count == 1)
        let pequeno = Task { try await s.salvar(Estado.de(blobCom(["A"]))) }
        await ate { transporte.gravacoes.count == 3 }
        transporte.gravacoes[2].concluir(nil)
        try await pequeno.value
        let t = Task { try await s.salvar(perto) }
        await ate { transporte.gravacoes.count == 4 }
        transporte.gravacoes[3].concluir(nil)
        try await t.value
        #expect(avisos.filter { $0 == .pertoDoLimite }.count == 2, "voltou para baixo de 700 mil: avisa de novo")
    }

    @Test func redeQueVoltaTentaJaOQueEstavaPendente() async throws {
        let s = montar()
        var pedidosDeSessao = 0
        s.aoPedirVerificacaoDeSessao = { pedidosDeSessao += 1 }
        let tarefa = Task { try await s.salvar(Estado.de(blobCom(["A"]))) }
        await ate { transporte.gravacoes.count == 1 }
        transporte.gravacoes[0].concluir("unavailable")
        relogio.avancar(1000)
        transporte.gravacoes[1].concluir("unavailable")
        s.redeMudou(online: true)
        relogio.avancar(0)
        #expect(transporte.gravacoes.count == 3, "não espera os 2 s do backoff")
        #expect(pedidosDeSessao == 1)
        transporte.gravacoes[2].concluir(nil)
        try await tarefa.value
    }

    @Test func redeQueCaiMostraSemConexaoMasNaoApagaErro() async {
        let s = montar()
        s.redeMudou(online: false)
        #expect(s.estadoSinc == .offline)
        s.redeMudou(online: true)
        #expect(s.estadoSinc == .ocioso)
        let tarefa = Task { try await s.salvar(Estado.de(blobCom(["A"]))) }
        await ate { transporte.gravacoes.count == 1 }
        transporte.gravacoes[0].concluir("invalid-argument")
        _ = try? await tarefa.value
        s.redeMudou(online: false)
        #expect(s.estadoSinc == .erro(codigo: "invalid-argument", origem: .escrita))
    }

    @Test func tentarDeNovoDepoisDeErroTerminalReenvia() async throws {
        let s = montar()
        let primeira = Task { try await s.salvar(Estado.de(blobCom(["A"]))) }
        await ate { transporte.gravacoes.count == 1 }
        transporte.gravacoes[0].concluir("permission-denied")
        _ = try? await primeira.value
        s.tentarDeNovo()
        #expect(transporte.gravacoes.count == 2)
        #expect(s.estadoSinc == .salvando)
        transporte.gravacoes[1].concluir(nil)
        #expect(s.estadoSinc == .ocioso)
    }

    @Test func naoAutenticadoPedeParaConferirASessao() async {
        let s = montar()
        var pedidos = 0
        s.aoPedirVerificacaoDeSessao = { pedidos += 1 }
        let tarefa = Task { try await s.salvar(Estado.de(blobCom(["A"]))) }
        await ate { transporte.gravacoes.count == 1 }
        transporte.gravacoes[0].concluir("unauthenticated")
        _ = try? await tarefa.value
        #expect(pedidos == 1)
    }

    @Test func semContaNaoSalva() async {
        let s = Sincronizador(transporte: transporte, relogio: relogio)
        var avisos: [AvisoSinc] = []
        s.aoAvisar = { avisos.append($0) }
        await #expect(throws: ErroSinc(codigo: "cancelled")) { try await s.salvar(.vazio) }
        #expect(transporte.gravacoes.isEmpty)
        #expect(avisos == [.naoSalvou(codigo: "cancelled", terminal: true)])
    }

    @Test func avisoTransitorioNoMaximoUmACada30Segundos() async {
        var avisos: [AvisoSinc] = []
        let s = montar()
        s.aoAvisar = { avisos.append($0) }
        let tarefa = Task { try await s.salvar(Estado.de(blobCom(["A"]))) }
        await ate { transporte.gravacoes.count == 1 }
        transporte.gravacoes[0].concluir("unavailable")
        relogio.avancar(1000)
        transporte.gravacoes[1].concluir("unavailable")
        #expect(avisos.count == 1)
        relogio.avancar(30_000)
        transporte.gravacoes[2].concluir("unavailable")
        #expect(avisos.count == 2)
        #expect(avisos[0].mensagem == "Sem salvar na nuvem agora — vamos tentar de novo sozinhos.")
        s.parar()
        _ = try? await tarefa.value
    }

    @Test func aguardarFilaEsperaATarefaEOSDK() async {
        let s = montar()
        let tarefa = Task { try await s.salvar(Estado.de(blobCom(["A"]))) }
        await ate { transporte.gravacoes.count == 1 }
        let fila = Task { await s.aguardarFila() }
        await ate { transporte.esperasDePendentes.count == 1 }
        transporte.gravacoes.last!.concluir(nil)
        transporte.esperasDePendentes[0](nil)
        #expect(await fila.value == true)
        _ = try? await tarefa.value
    }

    @Test func aguardarFilaDesisteDepoisDoTempo() async {
        let s = montar()
        let fila = Task { await s.aguardarFila(timeoutMs: 5000) }
        await ate { transporte.esperasDePendentes.count == 1 }
        relogio.avancar(5000)
        #expect(await fila.value == false)
    }

    @Test func pararRejeitaQuemEsperavaEZeraTudo() async {
        let s = montar()
        let tarefa = Task { try await s.salvar(Estado.de(blobCom(["A"]))) }
        await ate { transporte.gravacoes.count == 1 }
        s.parar()
        await #expect(throws: ErroSinc(codigo: "cancelled")) { try await tarefa.value }
        transporte.gravacoes[0].concluir(nil)
        #expect(s.estadoSinc == .ocioso)
        #expect(s.estado == .vazio)
        #expect(transporte.escutas[0].cancelada)
    }
}

@MainActor
struct SincronizadorLeituraTests {
    let transporte = TransporteFalso()
    let relogio = RelogioFalso()

    func montar() -> Sincronizador {
        let s = Sincronizador(transporte: transporte, relogio: relogio)
        s.iniciar(uid: "u1")
        return s
    }

    @Test func snapshotNormalizaETrocaOEstado() {
        let s = montar()
        #expect(!s.dadosCarregados)
        transporte.chega(blobCom(["Casa"], taxa: 99))
        #expect(s.estado.obras.map(\.nome) == ["Casa"])
        #expect(s.estado.config.taxaMensal == 1, "passou pela normalização")
        #expect(s.dadosCarregados)
    }

    @Test func documentoQueNaoExisteViraEstadoVazio() {
        let s = montar()
        transporte.chega(nil)
        #expect(s.estado == .vazio)
        #expect(s.dadosCarregados)
    }

    @Test func snapshotIgualNaoTrocaOEstado() {
        let s = montar()
        transporte.chega(blobCom(["Casa"]))
        let antes = s.estado
        transporte.chega(blobCom(["Casa"]))
        #expect(s.estado == antes)
    }

    @Test func ecoComGravacaoLocalPendenteEIgnorado() async throws {
        let s = montar()
        transporte.chega(blobCom(["Velha"]))
        let tarefa = Task { try await s.salvar(Estado.de(blobCom(["Nova"]))) }
        await ate { transporte.gravacoes.count == 1 }
        transporte.chega(blobCom(["Velha"]), doCache: true, pendente: true)
        #expect(s.estado.obras.map(\.nome) == ["Nova"], "snapshot com edição local pendente não troca o estado")
        transporte.gravacoes[0].concluir(nil)
        try await tarefa.value
        transporte.chega(blobCom(["Do site"]))
        #expect(s.estado.obras.map(\.nome) == ["Do site"], "depois da confirmação, mudança de fora entra")
    }

    @Test func gravacaoPendenteNoCacheMostraSalvando() {
        let s = montar()
        transporte.chega(blobCom(["A"]), doCache: true, pendente: true)
        #expect(s.estadoSinc == .salvando)
        transporte.chega(blobCom(["A"]))
        #expect(s.estadoSinc == .ocioso)
    }

    @Test func erroDeLeituraMostraNaoSincronizouEAvisa() {
        var avisos: [AvisoSinc] = []
        let s = montar()
        s.aoAvisar = { avisos.append($0) }
        transporte.escutas[0].aoFalhar("permission-denied")
        #expect(s.estadoSinc == .erro(codigo: "permission-denied", origem: .leitura))
        #expect(indicador(s.estadoSinc)?.rotulo == "Não sincronizou")
        #expect(avisos == [.naoLeu(codigo: "permission-denied")])
        #expect(avisos[0].mensagem == "Não consegui ler seus dados da nuvem agora (permission-denied).")
        s.redeMudou(online: false)
        #expect(s.estadoSinc == .erro(codigo: "permission-denied", origem: .leitura), "erro de leitura não some sozinho")
    }

    @Test func tentarDeNovoReabreAEscutaQueFalhou() {
        let s = montar()
        transporte.escutas[0].aoFalhar("unavailable")
        s.tentarDeNovo()
        #expect(transporte.escutas.count == 2)
        transporte.chega(blobCom(["A"]))
        #expect(s.estadoSinc == .ocioso)
        #expect(s.estado.obras.count == 1)
    }

    @Test func snapshotDeEscutaAntigaEIgnorado() {
        let s = montar()
        let antiga = transporte.escutas[0]
        s.iniciar(uid: "u2")
        antiga.aoReceber(Instantaneo(dados: blobCom(["Da outra conta"]), doCache: false, gravacaoPendente: false))
        #expect(s.estado == .vazio)
        #expect(antiga.cancelada)
    }

    @Test func indicadorInvisivelQuandoEmDia() {
        #expect(indicador(.ocioso) == nil)
        #expect(indicador(.salvando)?.girando == true)
        #expect(indicador(.repetindo)?.rotulo == "Salvando…")
        #expect(indicador(.offline)?.rotulo == "Sem conexão")
        #expect(indicador(.erro(codigo: "x", origem: .escrita))?.dica == "Não foi possível sincronizar. Toque para tentar de novo.")
    }
}

/// Os três jeitos de abrir o app: só grava quem já viu os dados de verdade.
struct CenarioDeAbertura: Sendable, CustomTestStringConvertible {
    let nome: String
    let doCache: Bool
    let comDocumento: Bool
    let podeGravar: Bool
    var testDescription: String { nome }
}

private let cenariosDeAbertura = [
    CenarioDeAbertura(nome: "sem rede e sem dados no aparelho", doCache: true, comDocumento: false, podeGravar: false),
    CenarioDeAbertura(nome: "com rede e conta ainda sem documento", doCache: false, comDocumento: false, podeGravar: true),
    CenarioDeAbertura(nome: "sem rede e com o blob no cache", doCache: true, comDocumento: true, podeGravar: true),
]

/* Sem a guarda, `salvar` ficaria esperando uma confirmação que o transporte falso nunca dá. As esperas
   destes testes são limitadas (`Desfecho` e `ate`), então eles falham na hora em vez de travar; o
   limite de tempo é a última trava. */
@MainActor
@Suite(.timeLimit(.minutes(1)))
struct SincronizadorCarregamentoTests {
    @Test(arguments: cenariosDeAbertura)
    func salvarSoDepoisDeVerOsDados(_ c: CenarioDeAbertura) async {
        let transporte = TransporteFalso()
        let s = Sincronizador(transporte: transporte, relogio: RelogioFalso(), online: !c.doCache)
        s.iniciar(uid: "u1")
        transporte.chega(c.comDocumento ? blobCom(["Casa"]) : nil, doCache: c.doCache)
        #expect(s.dadosCarregados == c.podeGravar)
        let d = Desfecho { try await s.salvar(Estado.de(blobCom(["Nova"]))) }
        if c.podeGravar {
            await ate { transporte.gravacoes.count == 1 }
            #expect(transporte.gravacoes.count == 1)
            transporte.gravacoes.first?.concluir(nil)
            await ate { d.terminou }
            #expect(d.terminou && d.erro == nil)
        } else {
            await ate { d.terminou }
            #expect(d.terminou, "salvar tem de recusar na hora")
            #expect(d.erro as? ErroSinc == ErroSinc(codigo: "nao-carregado"))
            #expect(transporte.gravacoes.isEmpty, "nada sobe por cima do documento que só o servidor tem")
            #expect(s.estado == .vazio, "a edição recusada não troca o estado")
        }
    }

    @Test func erroDeLeituraAntesDeCarregarNaoDeixaGravar() async {
        let transporte = TransporteFalso()
        let s = Sincronizador(transporte: transporte, relogio: RelogioFalso())
        s.iniciar(uid: "u1")
        transporte.escutas[0].aoFalhar("formato-desconhecido")
        let d = Desfecho { try await s.salvar(Estado.de(blobCom(["Nova"]))) }
        await ate { d.terminou }
        #expect(d.erro as? ErroSinc == ErroSinc(codigo: "nao-carregado"))
        #expect(transporte.gravacoes.isEmpty)
        #expect(indicador(s.estadoSinc)?.rotulo == "Não sincronizou")
    }

    @Test func documentoIlegivelDepoisDeCarregadoVoltaANaoGravar() async {
        let transporte = TransporteFalso()
        let s = Sincronizador(transporte: transporte, relogio: RelogioFalso())
        s.iniciar(uid: "u1")
        transporte.chega(blobCom(["Casa"]), doCache: true)
        #expect(s.dadosCarregados)
        transporte.escutas[0].aoFalhar("formato-desconhecido")
        #expect(!s.dadosCarregados, "quem não leu o documento inteiro não grava")
        let d = Desfecho { try await s.salvar(Estado.de(blobCom(["Nova"]))) }
        await ate { d.terminou }
        #expect(d.erro as? ErroSinc == ErroSinc(codigo: "nao-carregado"))
        #expect(transporte.gravacoes.isEmpty)
        #expect(s.estado.obras.map(\.nome) == ["Casa"], "a tela continua com o que já tinha lido")
        transporte.chega(blobCom(["Casa", "Sobrado"]))
        #expect(s.dadosCarregados, "um snapshot bom depois volta a deixar gravar")
    }

    @Test func erroDoFirestoreDepoisDeCarregadoNaoBloqueia() {
        let transporte = TransporteFalso()
        let s = Sincronizador(transporte: transporte, relogio: RelogioFalso())
        s.iniciar(uid: "u1")
        transporte.chega(blobCom(["Casa"]))
        transporte.escutas[0].aoFalhar("unavailable")
        #expect(s.dadosCarregados, "o que foi lido continua inteiro; como no site, dá para gravar")
    }
}
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `swift test --package-path app-ios/CusttaNucleo --filter Sincronizador`
Expected: FAIL na compilação: `cannot find type 'TransporteDados' in scope`.

- [ ] **Step 3: Implementar**

`app-ios/CusttaNucleo/Sources/CusttaNucleo/Sincronizador.swift`:

```swift
import Foundation
import Observation

/* A sincronização do documento `dados/{uid}`, porte da fila de escrita do cloud.js e do eco do
   app.js. Não conhece o Firebase: fala com um TransporteDados (o do app é fino, sobre o SDK) e
   mede o tempo com um Relogio, os dois falsos nos testes.

   Regras que vêm do site:
   - grava o documento inteiro; cada versão vai na hora para o transporte (a fila persistente do
     SDK guarda a ordem, inclusive sem rede); a última gravação vale;
   - a confirmação só conta para a versão mais recente;
   - erro terminal para e espera ação; transitório tenta de novo com proximoBackoff;
   - acima de 900.000 bytes não grava; entre 700.000 e 900.000 avisa uma vez;
   - snapshot que chega com gravação local pendente não troca o estado; os outros passam pela
     normalização e só trocam o estado se o conteúdo mudou.

   Como o site, nunca grava antes de ver os dados: até chegar um snapshot do servidor, ou do
   cache com o documento, `salvar` recusa com "nao-carregado". Uma regra a mais que o site: volta
   a recusar se chegar um documento que não deu para ler inteiro ("formato-desconhecido"). Sem
   isso, uma edição regravaria o documento inteiro por cima do que o app não viu. */

public enum OrigemErro: String, Sendable {
    case escrita, leitura
}

public enum EstadoSinc: Equatable, Sendable {
    case ocioso, salvando, repetindo, offline
    case erro(codigo: String, origem: OrigemErro)

    var ehErro: Bool { if case .erro = self { return true }; return false }
}

/// O que o snapshot do documento traz.
public struct Instantaneo: Sendable {
    /// nil: o documento não existe.
    public let dados: ValorJSON?
    public let doCache: Bool
    public let gravacaoPendente: Bool
    public init(dados: ValorJSON?, doCache: Bool, gravacaoPendente: Bool) {
        self.dados = dados; self.doCache = doCache; self.gravacaoPendente = gravacaoPendente
    }
}

@MainActor public protocol Cancelavel: AnyObject {
    func cancelar()
}

/// O banco visto pelo Sincronizador. Todo retorno chega na fila principal.
@MainActor public protocol TransporteDados: AnyObject {
    /// Escuta `dados/{uid}` com as mudanças de metadados (cache, gravação pendente). `aoFalhar` recebe o
    /// código do erro: do Firestore ("permission-denied"), que encerra a escuta, ou "formato-desconhecido"
    /// (documento com tipo que o JSON não tem), que não encerra: o próximo snapshot bom volta a valer.
    func escutar(uid: String, aoReceber: @escaping @MainActor (Instantaneo) -> Void,
                 aoFalhar: @escaping @MainActor (String) -> Void) -> any Cancelavel
    /// Grava o documento inteiro com `_atualizado` do servidor. `concluir(nil)` quando o servidor confirma;
    /// `concluir(codigo)` no erro. Sem rede, só conclui quando a rede volta.
    func gravar(uid: String, blob: ValorJSON, concluir: @escaping @MainActor (String?) -> Void)
    /// Conclui quando tudo o que o SDK guardou subiu (inclusive gravações de antes desta sessão).
    func aguardarGravacoesPendentes(concluir: @escaping @MainActor (String?) -> Void)
}

@MainActor public protocol Relogio: AnyObject {
    var agoraMs: Int64 { get }
    func agendar(depois ms: Int, _ acao: @escaping @MainActor () -> Void) -> any Cancelavel
}

public struct ErroSinc: Error, Equatable, Sendable {
    public let codigo: String
    public init(codigo: String) { self.codigo = codigo }
}

/// Aviso para a tela, com o texto do site.
public enum AvisoSinc: Equatable, Sendable {
    case pertoDoLimite
    case naoSalvou(codigo: String, terminal: Bool)
    case naoLeu(codigo: String)

    public var mensagem: String {
        switch self {
        case .pertoDoLimite: return "Seus dados estão próximos do limite de armazenamento."
        case .naoSalvou("limite", _): return "Não salvou: limite de dados atingido. Reduza os dados e tente novamente."
        case .naoSalvou(_, true): return "Não salvou na nuvem. Confira sua conexão e conta; toque no aviso para tentar novamente."
        case .naoSalvou(_, false): return "Sem salvar na nuvem agora — vamos tentar de novo sozinhos."
        case .naoLeu(let codigo): return "Não consegui ler seus dados da nuvem agora (\(codigo))."
        }
    }

    /// Erro terminal e aviso de tamanho aparecem sempre; os outros, no máximo um a cada 30 s.
    var raro: Bool {
        switch self {
        case .pertoDoLimite, .naoSalvou(_, true): return false
        case .naoSalvou(_, false), .naoLeu: return true
        }
    }
}

/// O indicador de sincronização da tela; nil quando está tudo em dia (fica invisível).
public struct IndicadorSinc: Equatable, Sendable {
    public let rotulo: String
    public let girando: Bool
    public let erro: Bool
    public let dica: String
}

public func indicador(_ e: EstadoSinc) -> IndicadorSinc? {
    switch e {
    case .ocioso: return nil
    case .salvando, .repetindo: return IndicadorSinc(rotulo: "Salvando…", girando: true, erro: false, dica: "Salvando…")
    case .offline: return IndicadorSinc(rotulo: "Sem conexão", girando: false, erro: false, dica: "Sem conexão")
    case .erro(_, let origem):
        return IndicadorSinc(rotulo: origem == .leitura ? "Não sincronizou" : "Não salvou", girando: false, erro: true,
                             dica: "Não foi possível sincronizar. Toque para tentar de novo.")
    }
}

@MainActor @Observable
public final class Sincronizador {
    public private(set) var estadoSinc: EstadoSinc
    public private(set) var estado: Estado = .vazio
    /// Já chegou um snapshot em que dá para confiar: do servidor, ou do cache com o documento.
    /// Cache sem documento (app recém-instalado, sem rede) não conta: o servidor pode ter obras.
    /// Volta a falso se chegar um documento que o app não conseguiu ler inteiro.
    public private(set) var dadosCarregados = false

    @ObservationIgnored public var aoAvisar: ((AvisoSinc) -> Void)?
    /// Erro "unauthenticated" ao gravar e rede que voltou pedem para conferir a sessão.
    @ObservationIgnored public var aoPedirVerificacaoDeSessao: (() -> Void)?

    @ObservationIgnored private let transporte: TransporteDados
    @ObservationIgnored private let relogio: Relogio
    @ObservationIgnored private var uid: String?
    @ObservationIgnored private var online: Bool
    @ObservationIgnored private var pendente: ValorJSON?
    @ObservationIgnored private var sujo = false
    @ObservationIgnored private var tentativa = 0
    @ObservationIgnored private var emVoo = false
    @ObservationIgnored private var versaoEscrita = 0
    @ObservationIgnored private var esperas: [(String?) -> Void] = []
    @ObservationIgnored private var repeticao: (any Cancelavel)?
    @ObservationIgnored private var avisouTamanho = false
    @ObservationIgnored private var escuta: (any Cancelavel)?
    @ObservationIgnored private var revisaoLeitura = 0
    @ObservationIgnored private var erroLeitura: String?
    @ObservationIgnored private var pendenciaCache = false
    @ObservationIgnored private var ultimoAvisoRaro: Int64?

    public init(transporte: TransporteDados, relogio: Relogio, online: Bool = true) {
        self.transporte = transporte
        self.relogio = relogio
        self.online = online
        self.estadoSinc = online ? .ocioso : .offline
    }

    public var temPendencia: Bool { pendente != nil || emVoo || pendenciaCache }

    /* ---------- conta ---------- */

    /// Começa a escutar a conta. Troca de conta zera tudo antes.
    public func iniciar(uid novo: String) {
        parar()
        uid = novo
        abrirEscuta(novo)
    }

    /// Sai da conta: para a escuta, descarta a fila desta sessão (a do SDK fica com ele) e rejeita
    /// quem esperava confirmação com "cancelled".
    public func parar() {
        escuta?.cancelar(); escuta = nil
        revisaoLeitura += 1
        versaoEscrita += 1
        repeticao?.cancelar(); repeticao = nil
        pendente = nil; sujo = false; emVoo = false; tentativa = 0; pendenciaCache = false; erroLeitura = nil
        terminarEsperas("cancelled")
        uid = nil
        estado = .vazio
        dadosCarregados = false
        publicar(online ? .ocioso : .offline)
    }

    /* ---------- escrita ---------- */

    /// Troca o estado na hora e grava o documento inteiro. Volta quando o servidor confirma esta
    /// versão (ou uma mais nova); lança ErroSinc no erro terminal, se a conta saiu ("cancelled") ou
    /// se ainda não deu para ver os dados desta conta ("nao-carregado").
    public func salvar(_ novo: Estado) async throws {
        guard uid != nil else {
            avisar(.naoSalvou(codigo: "cancelled", terminal: true))
            throw ErroSinc(codigo: "cancelled")
        }
        guard dadosCarregados else { throw ErroSinc(codigo: "nao-carregado") }
        estado = novo
        let blob = novo.arvore
        let tamanho = tamanhoBlob(blob)
        if tamanho >= avisoBlob && tamanho <= limiteBlob && !avisouTamanho { avisouTamanho = true; avisar(.pertoDoLimite) }
        if tamanho < avisoBlob { avisouTamanho = false }
        try await withCheckedThrowingContinuation { (c: CheckedContinuation<Void, Error>) in
            esperas.append { codigo in
                if let codigo { c.resume(throwing: ErroSinc(codigo: codigo)) } else { c.resume() }
            }
            pendente = blob
            sujo = true
            if estadoSinc.ehErro { tentativa = 0 }
            repeticao?.cancelar(); repeticao = nil
            publicar(online ? .salvando : .offline)
            enviar()
        }
    }

    /// Toque no indicador de erro: reabre a leitura que falhou e reenvia o que está pendente.
    public func tentarDeNovo() {
        if erroLeitura != nil, let uid { abrirEscuta(uid) }
        guard pendente != nil || emVoo else { return }
        tentativa = 0
        repeticao?.cancelar(); repeticao = nil
        enviar()
    }

    /// Espera subir o que esta sessão gravou e o que o SDK guardou de antes; false se não subiu
    /// em `timeoutMs` ou se deu erro. Sair da conta só segue com true.
    public func aguardarFila(timeoutMs: Int = 5000) async -> Bool {
        await withCheckedContinuation { (c: CheckedContinuation<Bool, Never>) in
            let espera = EsperaUnica(c)
            espera.tempo = relogio.agendar(depois: timeoutMs) { espera.terminar(false) }
            if pendente != nil || emVoo {
                espera.faltam += 1
                esperas.append { codigo in codigo == nil ? espera.cumpriu() : espera.terminar(false) }
                tentarDeNovo()
            }
            espera.faltam += 1
            transporte.aguardarGravacoesPendentes { codigo in codigo == nil ? espera.cumpriu() : espera.terminar(false) }
        }
    }

    /// Rede voltou (tenta já o que estava pendente) ou caiu (indicador "Sem conexão").
    public func redeMudou(online agora: Bool) {
        online = agora
        if agora {
            aoPedirVerificacaoDeSessao?()
            if estadoSinc.ehErro { return }
            if pendente != nil { tentativa = 0; agendarRepeticao(0) }
            else { publicar(emVoo || pendenciaCache ? .salvando : .ocioso) }
        } else if !estadoSinc.ehErro {
            publicar(.offline)
        }
    }

    private func enviar() {
        guard let blob = pendente, let uid else { return }
        pendente = nil
        emVoo = true
        versaoEscrita += 1
        let versao = versaoEscrita
        publicar(!online ? .offline : tentativa > 0 ? .repetindo : .salvando)
        guard blobCabe(blob) else { falhou(versao: versao, blob: blob, codigo: "limite"); return }
        transporte.gravar(uid: uid, blob: blob) { [weak self] codigo in
            guard let self else { return }
            if let codigo { self.falhou(versao: versao, blob: blob, codigo: codigo) } else { self.confirmou(versao: versao) }
        }
    }

    private func confirmou(versao: Int) {
        guard versao == versaoEscrita else { return }
        emVoo = false
        tentativa = 0
        if pendente != nil { enviar(); return }
        sujo = false
        publicar(.ocioso)
        terminarEsperas(nil)
    }

    private func falhou(versao: Int, blob: ValorJSON, codigo: String) {
        guard versao == versaoEscrita else { return }
        emVoo = false
        if pendente == nil { pendente = blob }
        let terminal = codigo == "limite" || erroEhTerminal(codigo: codigo)
        if codigo == "unauthenticated" { aoPedirVerificacaoDeSessao?() }
        avisar(.naoSalvou(codigo: codigo, terminal: terminal))
        if terminal {
            tentativa = 0
            publicar(.erro(codigo: codigo, origem: .escrita))
            terminarEsperas(codigo)
            return
        }
        let ms = proximoBackoff(Double(tentativa))
        tentativa += 1
        publicar(online ? .repetindo : .offline)
        agendarRepeticao(ms)
    }

    private func agendarRepeticao(_ ms: Int) {
        repeticao?.cancelar()
        repeticao = relogio.agendar(depois: ms) { [weak self] in
            self?.repeticao = nil
            self?.enviar()
        }
    }

    private func terminarEsperas(_ codigo: String?) {
        let todas = esperas
        esperas = []
        todas.forEach { $0(codigo) }
    }

    /* ---------- leitura ---------- */

    private func abrirEscuta(_ uid: String) {
        escuta?.cancelar()
        revisaoLeitura += 1
        let revisao = revisaoLeitura
        escuta = transporte.escutar(uid: uid, aoReceber: { [weak self] instantaneo in
            guard let self, revisao == self.revisaoLeitura, self.uid == uid else { return }
            self.recebeu(instantaneo)
        }, aoFalhar: { [weak self] codigo in
            guard let self, revisao == self.revisaoLeitura, self.uid == uid else { return }
            self.erroLeitura = codigo
            if codigo == "formato-desconhecido" { self.dadosCarregados = false }   // quem não leu o documento inteiro não grava
            self.publicar(.erro(codigo: codigo, origem: .leitura))
            self.avisar(.naoLeu(codigo: codigo))
        })
    }

    private func recebeu(_ i: Instantaneo) {
        if !i.doCache {
            let recuperou = erroLeitura != nil
            erroLeitura = nil
            if recuperou && !sujo { publicar(online ? .ocioso : .offline) }
        }
        pendenciaCache = i.gravacaoPendente
        if !sujo && !estadoSinc.ehErro { publicar(!online ? .offline : pendenciaCache ? .salvando : .ocioso) }
        guard !sujo else { return }          // edição desta sessão ainda não confirmada vence o eco
        let novo = normaliza(i.dados)
        if !mesmoConteudo(novo, estado.arvore) { estado = Estado(normalizado: novo) }
        if !i.doCache || i.dados != nil { dadosCarregados = true }
    }

    /* ---------- estado e avisos ---------- */

    private func publicar(_ novo: EstadoSinc) {
        if !novo.ehErro, let erroLeitura { estadoSinc = .erro(codigo: erroLeitura, origem: .leitura); return }
        estadoSinc = novo
    }

    private func avisar(_ aviso: AvisoSinc) {
        if aviso.raro {
            let agora = relogio.agoraMs
            if let ultimo = ultimoAvisoRaro, agora - ultimo < 30_000 { return }
            ultimoAvisoRaro = agora
        }
        aoAvisar?(aviso)
    }
}

/// Junta várias esperas num resultado só: true quando todas cumprem, false no primeiro erro ou no tempo.
@MainActor private final class EsperaUnica {
    private let continuacao: CheckedContinuation<Bool, Never>
    private var terminou = false
    var faltam = 0
    var tempo: (any Cancelavel)?

    init(_ c: CheckedContinuation<Bool, Never>) { continuacao = c }

    func cumpriu() {
        faltam -= 1
        if faltam == 0 { terminar(true) }
    }

    func terminar(_ ok: Bool) {
        guard !terminou else { return }
        terminou = true
        tempo?.cancelar()
        continuacao.resume(returning: ok)
    }
}
```

- [ ] **Step 4: Rodar e ver passar**

Run: `swift test --package-path app-ios/CusttaNucleo --filter Sincronizador`
Expected: `Test run with 29 tests in 3 suites passed`. Rode também o pacote inteiro (`swift test --package-path app-ios/CusttaNucleo`): todos verdes.

- [ ] **Step 5: Commit**

```bash
git add app-ios/CusttaNucleo
git commit -m "feat: sincronização do documento no núcleo do app nativo" -m "Porte da fila de escrita do cloud.js e do eco do app.js: grava o documento inteiro na hora, só a confirmação da versão mais nova conta, erro terminal para e transitório tenta de novo de 1 s a 30 s, guarda de 700 e 900 mil bytes, snapshot com gravação local pendente não desfaz a edição e erro de leitura vira 'não sincronizou'. Como o site, só grava depois de ver os dados (snapshot do servidor ou cache com documento); a mais que o site, para de gravar se chegar um documento que não deu para ler inteiro, para uma edição não regravar o documento por cima do que o app não viu. Sem Firebase: transporte e relógio entram por protocolo e os 29 testes usam falsos; os da guarda esperam de forma limitada, para falharem na hora em vez de travar."
```

---

### Task 9: Modelo das telas com os serviços falsos

**Files:**
- Create: `app-ios/Custta/Dados/Sistema.swift` (relógio, rede e janela; era da antiga Tarefa 6)
- Create: `app-ios/Custta/Conta/ServicoConta.swift`
- Create: `app-ios/Custta/Falsos/ContaFalsa.swift`, `app-ios/Custta/Falsos/TransporteFalsoApp.swift`, `app-ios/Custta/Falsos/MontarFalso.swift`
- Create: `app-ios/Custta/Estado/ModeloApp.swift`, `app-ios/Custta/Composicao.swift`
- Create: `app-ios/CusttaTests/Auxiliares.swift`
- Test: `app-ios/CusttaTests/ModeloAppTests.swift`, `app-ios/CusttaTests/DadosDeExemploTests.swift`

**Interfaces:**
- Consumes: `Sincronizador`, `TransporteDados`, `Cancelavel`, `Relogio`, `Instantaneo` (Tarefa 8); `validarEntrada`, `emailParece`, `PerfilCadastro`, `mensagemErroSenha`, `mensagemErroSocial` (Tarefas 6 e 7); `aparadoJS`, `agoraEmMilissegundos`, `ValorJSON`, `Estado`, `dataLocalISO` (Parte A).
- Produces: `@MainActor final class RelogioDoSistema: Relogio`; `@MainActor @Observable final class MonitorDeRede { online: Bool; aoMudar: ((Bool) -> Void)?; init(forcarSemRede: Bool = false) }`; `@MainActor func controladorNoTopo() -> UIViewController?`; `struct Usuario { uid, email: String; emailVerificado: Bool; provedores: [String]; nomeExibicao: String; temSenha, contaSocial, contaApple, precisaConfirmarEmail: Bool }`; `struct CredencialApple { idToken, nonce: String; nomeCompleto: PersonNameComponents? }`; `struct ErroConta: Error, Equatable { codigo: String }`; `@MainActor protocol ServicoConta` (assinaturas no código abaixo); em Debug: `ContaFalsa(inicial: String)` (cenários `nenhuma`, `senha`, `senha-nao-confirmada`, `senha-confirma-ao-conferir`, `apple-sem-perfil`, `google-sem-perfil`, `google-perfil-concorrente`) com `static let senhaCerta = "Casa2026x"`, `TransporteFalsoApp(dados:semRede:falhaDeLeitura:)` com `gravacoes: Int`, `DadosDeExemplo.blob` e `DadosDeExemplo.vitrine(hoje:)`; `@MainActor @Observable final class ModeloApp { enum Fase: Equatable { carregando, entrada, faltaPouco(Usuario), principal(Usuario) }; static let sessaoExpirada, linkEnviado, linkReenviado, emailJaConfirmado: String; fase; mensagemEntrada: String?; aviso: String?; nome: String?; sincronizador; rede; conta; usuario: Usuario?; init(conta:sincronizador:rede:); entrar(email:senha:) async -> String?; entrarComApple(_:) async -> String?; entrarComGoogle() async -> String?; criarConta(email:senha:perfil:) async -> String?; redefinirSenha(email:) async -> String; completarPerfil(_:) async -> String?; sair() async -> String?; reenviarVerificacao() async -> String; conferirVerificacao() async -> String?; voltouParaFrente() async; tentarDeNovo(); avisar(_:) }`; `@MainActor enum Composicao { static func montar(ambiente:) -> ModeloApp?; static func montarFalso(_:) -> ModeloApp /* Debug */ }`. Nos testes: `ate(_:) async`, `Desfecho`, `Bandeira`, `ModeloApp.Fase.ehPrincipal`, `ehFaltaPouco`.

É o que as antigas Tarefas 6, 7 e 8 tinham sem o Firebase: o relógio, a rede e a janela do sistema, o protocolo da conta e os falsos, o modelo das telas e a composição com os falsos. O `Sincronizador` de verdade roda sobre o `TransporteFalsoApp`: as telas mostram os estados dele (salvando, sem conexão, não salvou, não sincronizou, erro de leitura) e a guarda de nunca gravar antes de ver os dados vale desde já. A composição de produção e a dos emuladores chegam na Tarefa 14; até lá, `Composicao.montar()` devolve os falsos em Debug (com ou sem `CUSTTA_SERVICOS=falsos`) e nil em Release. Três mudanças em relação ao código das tarefas antigas: o "Esqueci minha senha" segue o site e usa o e-mail do cartão de entrar (sem e-mail válido: "Digite seu e-mail no campo acima primeiro."); os textos que a tela mostra com ícone próprio viram constantes do `ModeloApp`; e os falsos ganham a `vitrine`, as três obras do mockup aprovado com as datas contadas de hoje, que é o padrão quando ninguém escolhe os dados (para o Giovani e o Verniz compararem o simulador com o mockup lado a lado). Os testes de tela continuam usando `exemplo`.

- [ ] **Step 1: Escrever os testes que falham**

`app-ios/CusttaTests/Auxiliares.swift`:

```swift
import Foundation
@testable import Custta

/// Deixa as tarefas da fila principal andarem até a condição valer (desiste em uns 4 s).
@MainActor func ate(_ condicao: @MainActor () -> Bool) async {
    for _ in 0..<200 where !condicao() { try? await Task.sleep(for: .milliseconds(20)) }
}

/// Roda a operação sem deixar o teste travar: o teste espera o fim com `ate` e, se ela não terminar,
/// falha em vez de esperar para sempre. O `.timeLimit` sozinho não basta: a espera de `salvar` não
/// responde a cancelamento, e o teste ficaria preso mesmo depois de registrar a falha.
@MainActor final class Desfecho {
    private(set) var terminou = false
    private(set) var erro: (any Error)?
    init(_ operacao: @escaping @MainActor () async throws -> Void) {
        Task { @MainActor in
            do { try await operacao() } catch { self.erro = error }
            self.terminou = true
        }
    }
}

extension ModeloApp.Fase {
    var ehPrincipal: Bool { if case .principal = self { return true }; return false }
    var ehFaltaPouco: Bool { if case .faltaPouco = self { return true }; return false }
}

/// Liga quando algo acontece (observação, uso do banco).
@MainActor final class Bandeira { var ligada = false }
```

`app-ios/CusttaTests/ModeloAppTests.swift`:

```swift
import Foundation
import Observation
import Testing
@testable import Custta
import CusttaNucleo

/// Os três jeitos de abrir o app; só o primeiro (sem rede e sem nada no aparelho) não deixa gravar.
struct Abertura: Sendable, CustomTestStringConvertible {
    let nome: String
    let semRede: Bool
    let comDados: Bool
    let carrega: Bool
    var testDescription: String { nome }
}

let aberturas = [
    Abertura(nome: "sem rede e sem dados no aparelho", semRede: true, comDados: false, carrega: false),
    Abertura(nome: "com rede e conta ainda sem documento", semRede: false, comDados: false, carrega: true),
    Abertura(nome: "sem rede e com o blob no cache", semRede: true, comDados: true, carrega: true),
]

/* O modelo das telas com a conta e o transporte falsos: quem decide a tela, a mensagem de sessão
   expirada, o "Falta pouco" e a saída que espera a fila. */
@MainActor
struct ModeloAppTests {
    struct Montagem {
        let modelo: ModeloApp
        let conta: ContaFalsa
        let transporte: TransporteFalsoApp
    }

    func montar(conta inicial: String = "nenhuma", semRede: Bool = false, dados: ValorJSON? = DadosDeExemplo.blob) -> Montagem {
        let conta = ContaFalsa(inicial: inicial)
        let transporte = TransporteFalsoApp(dados: dados, semRede: semRede)
        let sincronizador = Sincronizador(transporte: transporte, relogio: RelogioDoSistema(), online: !semRede)
        let modelo = ModeloApp(conta: conta, sincronizador: sincronizador, rede: MonitorDeRede(forcarSemRede: semRede))
        return Montagem(modelo: modelo, conta: conta, transporte: transporte)
    }

    @Test func semContaVaiParaAEntrada() async {
        let m = montar().modelo
        await ate { m.fase == .entrada }
        #expect(m.fase == .entrada)
        #expect(m.mensagemEntrada == nil)
    }

    @Test func entrarComSenhaCertaAbreOAppComOsDados() async {
        let m = montar().modelo
        await ate { m.fase == .entrada }
        #expect(await m.entrar(email: " giovani@exemplo.com ", senha: ContaFalsa.senhaCerta) == nil)
        await ate { m.fase.ehPrincipal && m.sincronizador.dadosCarregados }
        #expect(m.fase.ehPrincipal)
        #expect(m.sincronizador.estado.obras.count == 4)
        #expect(m.nome == "Giovani Stuchi")
    }

    @Test func mensagensDeEntrarSaoAsDoSite() async {
        let m = montar().modelo
        #expect(await m.entrar(email: "giovani", senha: "x") == "Digite seu e-mail.")
        #expect(await m.entrar(email: "giovani@exemplo.com", senha: "") == "Digite a senha.")
        #expect(await m.entrar(email: "giovani@exemplo.com", senha: "Errada123") == "E-mail ou senha incorretos.")
        #expect(await m.redefinirSenha(email: "x") == "Digite seu e-mail no campo acima primeiro.")
        #expect(await m.redefinirSenha(email: "giovani@exemplo.com") == "Enviamos um link de redefinição pro seu e-mail.")
    }

    @Test func contaSocialSemPerfilPassaPeloFaltaPouco() async {
        let m = montar(conta: "google-sem-perfil").modelo
        await ate { m.fase.ehFaltaPouco }
        #expect(m.fase.ehFaltaPouco)
        #expect(await m.completarPerfil(PerfilCadastro(nome: "Giovani", origem: "google")) == nil)
        #expect(m.fase.ehPrincipal)
    }

    @Test func perfilGravadoPorOutroAparelhoSegueParaOApp() async {
        let m = montar(conta: "google-perfil-concorrente").modelo
        await ate { m.fase.ehFaltaPouco }
        #expect(await m.completarPerfil(PerfilCadastro(nome: "Giovani", origem: "google")) == nil)
        #expect(m.fase.ehPrincipal)
    }

    @Test func sessaoQueCaiExplicaNaEntradaELimpaOsDados() async throws {
        let montagem = montar(conta: "senha")
        let m = montagem.modelo
        await ate { m.fase.ehPrincipal && m.sincronizador.dadosCarregados }
        try await montagem.conta.sair()                 // a sessão cai sem a pessoa apertar "Sair"
        await ate { m.fase == .entrada }
        #expect(m.mensagemEntrada == "Sua sessão expirou por segurança. Entre de novo pra continuar.")
        #expect(m.sincronizador.estado == .vazio)
    }

    @Test func sairDePropositoNaoFalaEmSessaoExpirada() async {
        let m = montar(conta: "senha").modelo
        await ate { m.fase.ehPrincipal }
        #expect(await m.sair() == nil)
        await ate { m.fase == .entrada }
        #expect(m.mensagemEntrada == nil)
    }

    @Test func sairSemRedePedeParaConectarEFicaNoApp() async {
        let m = montar(conta: "senha", semRede: true).modelo
        await ate { m.fase.ehPrincipal }
        #expect(await m.sair() == "Conecte à internet e aguarde a sincronização antes de sair.")
        #expect(m.fase.ehPrincipal)
    }

    @Test(.timeLimit(.minutes(1)), arguments: aberturas)       // espera limitada (Desfecho); o limite de tempo é a última trava
    func abrirOAppNaoGravaNada(_ a: Abertura) async {
        let montagem = montar(conta: "senha", semRede: a.semRede, dados: a.comDados ? DadosDeExemplo.blob : nil)
        let m = montagem.modelo
        await ate { m.fase.ehPrincipal }
        try? await Task.sleep(for: .milliseconds(400))
        #expect(montagem.transporte.gravacoes == 0, "carregar nunca regrava o documento")
        #expect(m.sincronizador.dadosCarregados == a.carrega)
        if !a.carrega {
            let d = Desfecho { try await m.sincronizador.salvar(.vazio) }
            await ate { d.terminou }
            #expect(d.erro as? ErroSinc == ErroSinc(codigo: "nao-carregado"), "sem ver os dados, salvar recusa na hora")
            #expect(montagem.transporte.gravacoes == 0, "sem ver os dados, nem uma edição sobe")
        }
    }

    @Test func confirmarOEmailAvisaATelaQueLeOUsuario() async {
        let m = montar(conta: "senha-confirma-ao-conferir").modelo
        await ate { m.fase.ehPrincipal }
        #expect(m.usuario?.precisaConfirmarEmail == true)
        let mudou = Bandeira()
        withObservationTracking { _ = m.usuario } onChange: { Task { @MainActor in mudou.ligada = true } }
        #expect(await m.conferirVerificacao() == nil)
        await ate { mudou.ligada && m.usuario?.precisaConfirmarEmail == false }
        #expect(mudou.ligada, "a tela que mostra o aviso de e-mail é avisada")
        #expect(m.usuario?.precisaConfirmarEmail == false)
    }

    @Test func sairEEntrarDeNovoVoltaAosDados() async {
        let m = montar(conta: "senha").modelo
        await ate { m.fase.ehPrincipal && m.sincronizador.dadosCarregados }
        #expect(await m.sair() == nil)
        await ate { m.fase == .entrada }
        #expect(m.sincronizador.estado == .vazio)
        #expect(await m.entrar(email: "giovani@exemplo.com", senha: ContaFalsa.senhaCerta) == nil)
        await ate { m.fase.ehPrincipal && m.sincronizador.dadosCarregados }
        #expect(m.sincronizador.estado.obras.count == 4, "a escuta volta para a conta que entrou")
    }

    @Test func avisoDoSincronizadorApareceNaTela() async {
        let m = montar(conta: "senha").modelo
        await ate { m.sincronizador.dadosCarregados }
        let grande = Estado.de(.objeto(["obras": .lista([]), "config": .objeto(["taxaMensal": .numero(1)]),
                                        "notas": .texto(String(repeating: "a", count: 900_000))]))
        _ = try? await m.sincronizador.salvar(grande)
        #expect(m.aviso == "Não salvou: limite de dados atingido. Reduza os dados e tente novamente.")
    }
}
```

`app-ios/CusttaTests/DadosDeExemploTests.swift`:

```swift
import Foundation
import Testing
@testable import Custta
import CusttaNucleo

/* A vitrine mostra os números do mockup aprovado em qualquer dia (as datas são contadas de hoje). */
struct DadosDeExemploTests {
    static let dias = ["2026-01-31", "2026-03-01", "2026-10-08", "2026-12-31", "2027-02-28", "2028-02-29"]

    @Test(arguments: dias)
    func vitrineComOsNumerosDoMockup(_ dia: String) throws {
        let fuso = TimeZone.current
        var calendario = Calendar(identifier: .gregorian)
        calendario.timeZone = fuso
        let partes = dia.split(separator: "-").map { Int($0)! }
        let hoje = try #require(calendario.date(from: DateComponents(year: partes[0], month: partes[1], day: partes[2], hour: 12)))
        let estado = Estado.de(DadosDeExemplo.vitrine(hoje: hoje))
        let iso = dataLocalISO(hoje, fuso: fuso)
        let obras = obrasOrdenadas(estado.obras)
        #expect(obras.map(\.nome) == ["Casa Alphaville", "Sobrado Granja Viana", "Casa Tamboré 4"])
        #expect(obras.map(\.fase.rotulo) == ["Em construção", "Pronta · à venda", "Vendida"])
        #expect(obras.map { fmtMeses(mesesDeObra($0, hoje: iso)) } == ["14 meses", "23 meses", "18 meses"])
        #expect(obras.map { moedaCurta(totalBruto($0)) } == ["R$ 842 mil", "R$ 1,38 mi", "R$ 976 mil"])
        #expect(obras.map { moedaCurta(totalCorrigido($0, taxa: 1, hoje: iso)) } == ["R$ 928 mil", "R$ 1,65 mi", "R$ 1,12 mi"])
        #expect(orcamentoObra(obras[0]).map(textoOrcamentoNaLista) == "70% do orçamento")
        #expect(orcamentoObra(obras[1]) == nil && orcamentoObra(obras[2]) == nil)
    }
}
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `xcodebuild test -project app-ios/Custta.xcodeproj -scheme Custta -destination "$(node scripts/simulador-ios.mjs)" -skipMacroValidation -skipPackagePluginValidation -onlyUsePackageVersionsFromResolvedFile CODE_SIGNING_ALLOWED=NO -only-testing:CusttaTests`
Expected: FAIL na compilação: `cannot find 'ModeloApp' in scope`.

- [ ] **Step 3: Relógio, rede e janela**

`app-ios/Custta/Dados/Sistema.swift`:

```swift
import Foundation
import Network
import Observation
import UIKit
import CusttaNucleo

/// O Relogio do Sincronizador com a fila principal.
@MainActor
final class RelogioDoSistema: Relogio {
    private final class Tarefa: Cancelavel {
        let item: DispatchWorkItem
        init(_ item: DispatchWorkItem) { self.item = item }
        func cancelar() { item.cancel() }
    }

    var agoraMs: Int64 { agoraEmMilissegundos() }

    func agendar(depois ms: Int, _ acao: @escaping @MainActor () -> Void) -> any Cancelavel {
        let item = DispatchWorkItem { MainActor.assumeIsolated { acao() } }
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(ms), execute: item)
        return Tarefa(item)
    }
}

/// Rede do aparelho (o navigator.onLine do site).
@MainActor @Observable
final class MonitorDeRede {
    private(set) var online: Bool
    @ObservationIgnored var aoMudar: ((Bool) -> Void)?
    @ObservationIgnored private let monitor = NWPathMonitor()

    /// `forcarSemRede`: só nos testes de tela, para abrir o app "em modo avião".
    init(forcarSemRede: Bool = false) {
        online = !forcarSemRede
        guard !forcarSemRede else { return }
        monitor.pathUpdateHandler = { [weak self] caminho in
            let ok = caminho.status == .satisfied
            Task { @MainActor in self?.atualizar(ok) }
        }
        monitor.start(queue: DispatchQueue(label: "br.com.custta.rede"))
    }

    private func atualizar(_ ok: Bool) {
        guard ok != online else { return }
        online = ok
        aoMudar?(ok)
    }
}

/// A janela do app, para quem precisa apresentar tela do sistema (login do Google).
@MainActor
func controladorNoTopo() -> UIViewController? {
    let janela = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        .flatMap(\.windows).first(where: \.isKeyWindow)
    var topo = janela?.rootViewController
    while let apresentado = topo?.presentedViewController { topo = apresentado }
    return topo
}
```

- [ ] **Step 4: A conta e os falsos**

`app-ios/Custta/Conta/ServicoConta.swift`:

```swift
import Foundation
import CusttaNucleo

/// A conta como o app a vê (o `currentUser` do cloud.js).
struct Usuario: Equatable, Sendable {
    let uid: String
    let email: String
    let emailVerificado: Bool
    /// "password", "google.com", "apple.com".
    let provedores: [String]
    let nomeExibicao: String

    /// Sem provedor (conta antiga) vale o fluxo com senha, como no site.
    var temSenha: Bool { provedores.isEmpty || provedores.contains("password") }
    var contaSocial: Bool { provedores.contains("google.com") || provedores.contains("apple.com") }
    var contaApple: Bool { provedores.contains("apple.com") }
    /// O aviso "Confirme seu e-mail" só vale para conta com senha.
    var precisaConfirmarEmail: Bool { temSenha && !emailVerificado }
}

/// O que o botão "Continuar com a Apple" devolve, já sem tipos da AuthenticationServices.
struct CredencialApple: Sendable {
    let idToken: String
    let nonce: String
    let nomeCompleto: PersonNameComponents?
}

/// Erro de conta com o código no formato do site ("auth/wrong-password", "offline", "pendente").
struct ErroConta: Error, Equatable {
    let codigo: String
}

/// Conta e perfil (Firebase Auth e `perfis/{uid}`). A implementação real é ContaFirebase; os testes usam ContaFalsa.
@MainActor
protocol ServicoConta: AnyObject {
    var usuario: Usuario? { get }
    /// Avisa a cada troca de usuário, inclusive a primeira leitura (conta restaurada ou nenhuma);
    /// quem se inscreve depois dela recebe o estado atual.
    func observar(_ aoMudar: @escaping @MainActor (Usuario?) -> Void)
    func entrar(email: String, senha: String) async throws
    func entrarComApple(_ credencial: CredencialApple) async throws
    func entrarComGoogle() async throws
    /// Cria a conta, grava `perfis/{uid}` e manda o e-mail de confirmação (falha no envio não desfaz a conta).
    func criarConta(email: String, senha: String, perfil: PerfilCadastro) async throws
    /// Conta Google ou Apple sem `perfis/{uid}`. Falha de rede responde false: travar quem está sem rede é pior.
    func perfilPendente() async -> Bool
    func completarPerfil(_ perfil: PerfilCadastro) async throws
    /// "Nome Sobrenome" de `perfis/{uid}`, ou nil.
    func lerNome() async -> String?
    func redefinirSenha(email: String) async throws
    /// false quando o e-mail já estava confirmado.
    func reenviarVerificacao() async throws -> Bool
    /// Relê a conta no servidor; nunca lança.
    func conferirVerificacao() async -> Bool
    /// Renova o token; sai da conta só se a sessão foi invalidada (nunca por falta de rede).
    func verificarSessao(forcar: Bool) async
    /// Sai da conta e limpa o cache local do banco. Quem chama já esperou a fila e parou a escuta.
    func sair() async throws
}
```

`app-ios/Custta/Falsos/ContaFalsa.swift`:

```swift
#if DEBUG
import Foundation
import CusttaNucleo

/* Conta falsa para os testes (só Debug). A inicial vem de CUSTTA_CONTA:
   nenhuma | senha | senha-nao-confirmada | senha-confirma-ao-conferir (o "Já confirmei" acha o
   e-mail confirmado) | apple-sem-perfil | google-sem-perfil |
   google-perfil-concorrente (outro aparelho grava o perfil no meio do "Falta pouco"). */
@MainActor
final class ContaFalsa: ServicoConta {
    static let senhaCerta = "Casa2026x"
    private(set) var usuario: Usuario?
    private var ouvintes: [@MainActor (Usuario?) -> Void] = []
    private var temPerfil: Bool
    private let perfilConcorrente: Bool
    private let confirmaAoConferir: Bool

    init(inicial: String) {
        perfilConcorrente = inicial == "google-perfil-concorrente"
        confirmaAoConferir = inicial == "senha-confirma-ao-conferir"
        temPerfil = !inicial.hasSuffix("sem-perfil") && !perfilConcorrente
        switch inicial {
        case "senha": usuario = Self.comSenha(email: "giovani@exemplo.com", verificado: true)
        case "senha-nao-confirmada", "senha-confirma-ao-conferir":
            usuario = Self.comSenha(email: "giovani@exemplo.com", verificado: false)
        case "apple-sem-perfil": usuario = Usuario(uid: "apple", email: "x@privaterelay.appleid.com", emailVerificado: true,
                                                   provedores: ["apple.com"], nomeExibicao: "Giovani Stuchi")
        case "google-sem-perfil", "google-perfil-concorrente":
            usuario = Usuario(uid: "google", email: "giovani@gmail.com", emailVerificado: true, provedores: ["google.com"], nomeExibicao: "Giovani Stuchi")
        default: usuario = nil
        }
    }

    static func comSenha(email: String, verificado: Bool) -> Usuario {
        Usuario(uid: "teste", email: email, emailVerificado: verificado, provedores: ["password"], nomeExibicao: "")
    }

    private func trocar(_ u: Usuario?) {
        usuario = u
        ouvintes.forEach { $0(u) }
    }

    func observar(_ aoMudar: @escaping @MainActor (Usuario?) -> Void) {
        ouvintes.append(aoMudar)
        let atual = usuario
        Task { @MainActor in aoMudar(atual) }      // o Firebase também avisa a conta restaurada logo depois
    }

    func entrar(email: String, senha: String) async throws {
        try await Task.sleep(for: .milliseconds(300))
        guard senha == Self.senhaCerta else { throw ErroConta(codigo: "auth/invalid-credential") }
        trocar(Self.comSenha(email: email, verificado: true))
    }

    func entrarComApple(_ credencial: CredencialApple) async throws {
        trocar(Usuario(uid: "apple", email: "x@privaterelay.appleid.com", emailVerificado: true, provedores: ["apple.com"], nomeExibicao: "Giovani Stuchi"))
    }

    func entrarComGoogle() async throws {
        trocar(Usuario(uid: "google", email: "giovani@gmail.com", emailVerificado: true, provedores: ["google.com"], nomeExibicao: "Giovani Stuchi"))
    }

    func criarConta(email: String, senha: String, perfil: PerfilCadastro) async throws {
        try await Task.sleep(for: .milliseconds(300))
        if email == "ja@existe.com" { throw ErroConta(codigo: "auth/email-already-in-use") }
        temPerfil = true
        trocar(Self.comSenha(email: email, verificado: false))
    }

    func perfilPendente() async -> Bool { usuario?.contaSocial == true && !temPerfil }

    func completarPerfil(_ perfil: PerfilCadastro) async throws {
        temPerfil = true
        if perfilConcorrente { throw ErroConta(codigo: "permission-denied") }    // as rules recusam o segundo perfil
    }

    func lerNome() async -> String? { usuario == nil ? nil : "Giovani Stuchi" }

    func redefinirSenha(email: String) async throws {
        if email == "ninguem@exemplo.com" { throw ErroConta(codigo: "auth/user-not-found") }
    }

    func reenviarVerificacao() async throws -> Bool { true }

    func conferirVerificacao() async -> Bool {
        guard confirmaAoConferir, let u = usuario else { return false }
        if !u.emailVerificado { trocar(Self.comSenha(email: u.email, verificado: true)) }
        return true
    }

    func verificarSessao(forcar: Bool) async {}

    func sair() async throws { trocar(nil) }
}
#endif
```

`app-ios/Custta/Falsos/TransporteFalsoApp.swift`:

```swift
#if DEBUG
import Foundation
import CusttaNucleo

/// Transporte falso dos testes (só Debug): entrega um blob fixo e confirma gravações depois de
/// 300 ms (nunca, sem rede). `falhaDeLeitura` faz a escuta falhar com esse código antes do primeiro
/// snapshot (CUSTTA_LEITURA=erro: permission-denied; formato: formato-desconhecido).
@MainActor
final class TransporteFalsoApp: TransporteDados {
    private final class Nada: Cancelavel { func cancelar() {} }
    private let dados: ValorJSON?
    private let semRede: Bool
    private let falhaDeLeitura: String?
    /// Quantas gravações chegaram (os testes conferem que abrir o app não grava nada).
    private(set) var gravacoes = 0

    init(dados: ValorJSON?, semRede: Bool, falhaDeLeitura: String? = nil) {
        self.dados = dados
        self.semRede = semRede
        self.falhaDeLeitura = falhaDeLeitura
    }

    func escutar(uid: String, aoReceber: @escaping @MainActor (Instantaneo) -> Void,
                 aoFalhar: @escaping @MainActor (String) -> Void) -> any Cancelavel {
        let dados = self.dados, semRede = self.semRede, falha = falhaDeLeitura
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(200))
            if let falha { aoFalhar(falha); return }
            aoReceber(Instantaneo(dados: dados, doCache: semRede, gravacaoPendente: false))
        }
        return Nada()
    }

    func gravar(uid: String, blob: ValorJSON, concluir: @escaping @MainActor (String?) -> Void) {
        gravacoes += 1
        guard !semRede else { return }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(300))
            concluir(nil)
        }
    }

    func aguardarGravacoesPendentes(concluir: @escaping @MainActor (String?) -> Void) {
        if !semRede { concluir(nil) }
    }
}

/// O blob de exemplo dos testes: obras com orçamento (uma passou), uma vendida, uma sem gasto e
/// uma de nome longo e total alto (a lista não pode cortar nada no maior tamanho de letra).
enum DadosDeExemplo {
    static let blob: ValorJSON = .objeto([
        "obras": .lista([
            .objeto(["id": .texto("o1"), "nome": .texto("Casa Alphaville"), "dataInicio": .texto("2025-03-10"), "fase": .texto("construcao"),
                     "orcamento": .objeto(["modo": .texto("total"), "total": .numero(400_000)]),
                     "gastos": .lista([
                        .objeto(["id": .texto("g1"), "valor": .numero(98_000), "topico": .texto("fundacao"), "descricao": .texto("Sapatas"), "data": .texto("2025-03-20"), "pagamento": .texto("pix")]),
                        .objeto(["id": .texto("g2"), "valor": .numero(231_000), "topico": .texto("estrutura"), "descricao": .texto("Laje"), "data": .texto("2025-06-02"), "pagamento": .texto("pix")]),
                     ])]),
            .objeto(["id": .texto("o2"), "nome": .texto("Sobrado Centro"), "dataInicio": .texto("2024-01-15"), "fase": .texto("vendida"),
                     "venda": .objeto(["valor": .numero(980_000), "data": .texto("2025-02-10")]),
                     "orcamento": .objeto(["modo": .texto("total"), "total": .numero(500_000)]),
                     "gastos": .lista([
                        .objeto(["id": .texto("h1"), "valor": .numero(559_500.75), "topico": .texto("alvenaria"), "descricao": .texto("Blocos"), "data": .texto("2024-05-31"), "pagamento": .texto("pix")]),
                     ])]),
            .objeto(["id": .texto("o3"), "nome": .texto("Terreno novo"), "dataInicio": .texto("2026-10-01"), "fase": .texto("construcao"), "gastos": .lista([])]),
            .objeto(["id": .texto("o4"), "nome": .texto("Residencial Jardim das Acácias, Bloco B, Casa 12"), "dataInicio": .texto("2023-05-20"),
                     "fase": .texto("construcao"),
                     "gastos": .lista([
                        .objeto(["id": .texto("j1"), "valor": .numero(123_456_789), "topico": .texto("estrutura"), "descricao": .texto("Estrutura"), "data": .texto("2023-06-01"), "pagamento": .texto("pix")]),
                     ])]),
        ]),
        "config": .objeto(["taxaMensal": .numero(1), "topicosCustom": .lista([])]),
    ])

    /// As três obras do mockup aprovado (Casa Alphaville, Sobrado Granja Viana e Casa Tamboré 4), com as
    /// datas contadas a partir de hoje: a lista mostra sempre os números do mockup (14 meses, R$ 842 mil,
    /// R$ 928 mil corrigido, 70% do orçamento…), para comparar o simulador com ele lado a lado.
    static func vitrine(hoje: Date = .now) -> ValorJSON {
        let calendario = Calendar(identifier: .gregorian)
        func data(_ mesesAtras: Int) -> ValorJSON {
            .texto(dataLocalISO(calendario.date(byAdding: .month, value: -mesesAtras, to: hoje) ?? hoje, fuso: .current))
        }
        func obra(_ id: String, _ nome: String, _ fase: String, inicio: Int, gastos: [(Int, Double)],
                  extra: [String: ValorJSON] = [:]) -> ValorJSON {
            var campos: [String: ValorJSON] = [
                "id": .texto(id), "nome": .texto(nome), "fase": .texto(fase), "dataInicio": data(inicio),
                "gastos": .lista(gastos.enumerated().map { i, g in
                    .objeto(["id": .texto("\(id)g\(i)"), "valor": .numero(g.1), "topico": .texto("outros"),
                             "descricao": .texto("Etapa \(i + 1)"), "data": data(g.0), "pagamento": .texto("pix")])
                }),
            ]
            campos.merge(extra) { _, novo in novo }
            return .objeto(campos)
        }
        return .objeto([
            "obras": .lista([
                obra("v1", "Casa Alphaville", "construcao", inicio: 14,
                     gastos: [(14, 92_000), (13, 150_000), (11, 230_000), (8, 190_000), (5, 180_000)],
                     extra: ["orcamento": .objeto(["modo": .texto("total"), "total": .numero(1_200_000)])]),
                obra("v2", "Sobrado Granja Viana", "pronta", inicio: 23,
                     gastos: [(23, 250_000), (21, 330_000), (18, 310_000), (15, 280_000), (12, 210_000)]),
                obra("v3", "Casa Tamboré 4", "vendida", inicio: 20,
                     gastos: [(20, 210_000), (18, 260_000), (15, 250_000), (12, 256_000)],
                     extra: ["venda": .objeto(["valor": .numero(1_450_000), "data": data(2)])]),
            ]),
            "config": .objeto(["taxaMensal": .numero(1), "topicosCustom": .lista([])]),
        ])
    }
}
#endif
```

- [ ] **Step 5: O modelo e a composição com os falsos**

`app-ios/Custta/Estado/ModeloApp.swift`:

```swift
import Foundation
import Observation
import CusttaNucleo

/* O estado das telas: qual tela aparece (entrada, falta pouco, app), a conta, a sincronização e
   os avisos. Porte do que auth.js e o boot do app.js fazem com a conta. */
@MainActor @Observable
final class ModeloApp {
    enum Fase: Equatable {
        case carregando
        case entrada
        case faltaPouco(Usuario)
        case principal(Usuario)
    }

    /// Textos que a tela de entrar mostra com ícone próprio (cadeado e ✓), os mesmos do site.
    static let sessaoExpirada = "Sua sessão expirou por segurança. Entre de novo pra continuar."
    static let linkEnviado = "Enviamos um link de redefinição pro seu e-mail."
    static let linkReenviado = "Link reenviado. Confira também a caixa de spam."
    static let emailJaConfirmado = "E-mail já confirmado."

    private(set) var fase: Fase = .carregando
    /// Texto da tela de entrada: sessão expirada.
    var mensagemEntrada: String?
    /// Aviso curto no topo (o toast do site).
    private(set) var aviso: String?
    /// "Nome Sobrenome" de `perfis/{uid}`, para Ajustes.
    private(set) var nome: String?
    let sincronizador: Sincronizador
    let rede: MonitorDeRede

    @ObservationIgnored let conta: ServicoConta
    @ObservationIgnored private var uidAtivo: String?
    @ObservationIgnored private var jaEntrou = false
    @ObservationIgnored private var saindoDeProposito = false
    @ObservationIgnored private var checagem = 0
    @ObservationIgnored private var tarefaDoAviso: Task<Void, Never>?

    init(conta: ServicoConta, sincronizador: Sincronizador, rede: MonitorDeRede) {
        self.conta = conta
        self.sincronizador = sincronizador
        self.rede = rede
        sincronizador.aoAvisar = { [weak self] aviso in self?.avisar(aviso.mensagem) }
        sincronizador.aoPedirVerificacaoDeSessao = { [weak self] in
            Task { await self?.conta.verificarSessao(forcar: true) }
        }
        rede.aoMudar = { [weak sincronizador] online in sincronizador?.redeMudou(online: online) }
        conta.observar { [weak self] usuario in
            Task { await self?.usuarioMudou(usuario) }
        }
    }

    /// A conta da tela atual. Vem da `fase`, que é observável: a tela que lê `usuario` é avisada quando
    /// ele muda (o e-mail confirmado tira o aviso sem precisar reabrir o app).
    var usuario: Usuario? {
        switch fase {
        case .faltaPouco(let u), .principal(let u): return u
        case .carregando, .entrada: return nil
        }
    }

    /* ---------- conta ---------- */

    func usuarioMudou(_ u: Usuario?) async {
        checagem += 1
        let minha = checagem
        guard let u else {
            let expirou = jaEntrou && !saindoDeProposito
            jaEntrou = false
            saindoDeProposito = false
            uidAtivo = nil
            sincronizador.parar()
            nome = nil
            if expirou { mensagemEntrada = Self.sessaoExpirada }
            fase = .entrada
            return
        }
        jaEntrou = true
        mensagemEntrada = nil
        if uidAtivo != u.uid {
            uidAtivo = u.uid
            sincronizador.iniciar(uid: u.uid)
        }
        if u.contaSocial, await conta.perfilPendente() {
            if minha == checagem { fase = .faltaPouco(u) }
            return
        }
        guard minha == checagem else { return }
        fase = .principal(u)
        nome = await conta.lerNome()
    }

    /// Mensagem de erro para a tela de entrar, ou nil se entrou.
    func entrar(email: String, senha: String) async -> String? {
        if let erro = validarEntrada(email: email, senha: senha) { return erro }
        do { try await conta.entrar(email: aparadoJS(email), senha: senha); return nil }
        catch { return mensagemErroSenha(codigo: (error as? ErroConta)?.codigo, tela: "login") }
    }

    func entrarComApple(_ credencial: CredencialApple) async -> String? {
        do { try await conta.entrarComApple(credencial); return nil }
        catch { return mensagemOuNil(mensagemErroSocial(codigo: (error as? ErroConta)?.codigo, provedor: "apple.com")) }
    }

    func entrarComGoogle() async -> String? {
        do { try await conta.entrarComGoogle(); return nil }
        catch { return mensagemOuNil(mensagemErroSocial(codigo: (error as? ErroConta)?.codigo, provedor: "google.com")) }
    }

    private func mensagemOuNil(_ s: String) -> String? { s.isEmpty ? nil : s }

    func criarConta(email: String, senha: String, perfil: PerfilCadastro) async -> String? {
        do { try await conta.criarConta(email: aparadoJS(email), senha: senha, perfil: perfil); return nil }
        catch { return mensagemErroSenha(codigo: (error as? ErroConta)?.codigo, tela: "cadastro") }
    }

    /// "Esqueci minha senha", com o e-mail digitado no próprio cartão de entrar, como no site:
    /// o texto de sucesso ou de erro.
    func redefinirSenha(email: String) async -> String {
        let e = aparadoJS(email)
        guard emailParece(e) else { return "Digite seu e-mail no campo acima primeiro." }
        do { try await conta.redefinirSenha(email: e); return Self.linkEnviado }
        catch { return mensagemErroSenha(codigo: (error as? ErroConta)?.codigo, tela: "redefinir") }
    }

    /// "Falta pouco": grava o perfil e segue para o app. Outro aparelho pode ter gravado antes
    /// (as rules recusam o segundo): se o perfil já existe, não há nada pendente.
    func completarPerfil(_ perfil: PerfilCadastro) async -> String? {
        do {
            try await conta.completarPerfil(perfil)
        } catch let erro as ErroConta {
            if erro.codigo == "permission-denied", !(await conta.perfilPendente()) { await seguirParaOApp(); return nil }
            return erro.codigo == "offline" ? "Conecte à internet para continuar." : "Não deu certo salvar. Tente de novo."
        } catch { return "Não deu certo salvar. Tente de novo." }
        await seguirParaOApp()
        return nil
    }

    private func seguirParaOApp() async {
        guard let u = conta.usuario else { return }
        fase = .principal(u)
        nome = await conta.lerNome()
    }

    /// "Sair da conta" e "Usar outra conta", na ordem do cloud.js: espera a fila subir (sem rede, pede
    /// para conectar), confere que a conta é a mesma, para a escuta e só então sai.
    /// Mensagem de erro, ou nil se saiu.
    func sair() async -> String? {
        let semRede = "Conecte à internet e aguarde a sincronização antes de sair."
        guard rede.online, let uid = conta.usuario?.uid else { return semRede }
        guard await sincronizador.aguardarFila(timeoutMs: 5000) else { return semRede }
        guard conta.usuario?.uid == uid else { return "Não foi possível sair com segurança. Tente novamente." }
        saindoDeProposito = true
        sincronizador.parar()
        do { try await conta.sair(); return nil }
        catch {
            saindoDeProposito = false
            sincronizador.iniciar(uid: uid)          // não saiu: volta a escutar a conta
            return "Não foi possível sair com segurança. Tente novamente."
        }
    }

    /// Texto do aviso de e-mail depois de "Reenviar link".
    func reenviarVerificacao() async -> String {
        do {
            return try await conta.reenviarVerificacao() ? Self.linkReenviado : Self.emailJaConfirmado
        } catch let erro as ErroConta {
            switch erro.codigo {
            case "offline": return "Conecte à internet para reenviar."
            case "auth/too-many-requests": return "Muitos envios seguidos. Aguarde alguns minutos."
            default: return "Não foi possível reenviar agora. Tente novamente."
            }
        } catch { return "Não foi possível reenviar agora. Tente novamente." }
    }

    /// Texto do aviso de e-mail depois de "Já confirmei"; nil quando confirmou (o aviso some).
    func conferirVerificacao() async -> String? {
        if await conta.conferirVerificacao() { return nil }
        return rede.online ? "Ainda não recebemos a confirmação. Toque no link do e-mail e tente de novo."
                           : "Conecte à internet para conferir."
    }

    /// O app voltou para a frente: confere a sessão e, se faltar, a confirmação do e-mail.
    func voltouParaFrente() async {
        await conta.verificarSessao(forcar: false)
        if conta.usuario?.precisaConfirmarEmail == true { _ = await conta.conferirVerificacao() }
    }

    /* ---------- sincronização e avisos ---------- */

    func tentarDeNovo() {
        avisar("Tentando de novo…")
        sincronizador.tentarDeNovo()
    }

    func avisar(_ texto: String) {
        aviso = texto
        tarefaDoAviso?.cancel()
        tarefaDoAviso = Task { [weak self] in
            try? await Task.sleep(for: .seconds(4))
            guard !Task.isCancelled else { return }
            self?.aviso = nil
        }
    }
}
```

`app-ios/Custta/Composicao.swift`:

```swift
import Foundation
import CusttaNucleo

/* Monta o app. Por enquanto só com os serviços falsos (Debug), que as telas e os testes de tela
   usam; a composição de produção (Firebase) e a dos emuladores chegam com a camada Firebase.
   O build Release, até lá, abre só a abertura. */
@MainActor
enum Composicao {
    /// O modelo das telas, ou nil quando o build ainda não tem serviço (Release, antes da camada Firebase).
    static func montar(ambiente: [String: String] = ProcessInfo.processInfo.environment) -> ModeloApp? {
        #if DEBUG
        return montarFalso(ambiente)
        #else
        return nil
        #endif
    }
}
```

`app-ios/Custta/Falsos/MontarFalso.swift`:

```swift
#if DEBUG
import Foundation
import CusttaNucleo

/* Monta o app com os serviços falsos (CUSTTA_SERVICOS=falsos), para os testes de tela. Só Debug.
   Variáveis que o teste passa ao abrir o app:
   CUSTTA_CONTA   conta inicial da ContaFalsa (nenhuma, senha, senha-nao-confirmada, apple-sem-perfil,
                  google-sem-perfil, google-perfil-concorrente)
   CUSTTA_DADOS   vitrine (padrão: as obras do mockup) | exemplo (as dos testes) | vazio
   CUSTTA_REDE    offline (abre "em modo avião": dados do cache e indicador "Sem conexão")
   CUSTTA_LEITURA erro (a escuta falha com permission-denied) | formato (documento que o app não lê) */
extension Composicao {
    static func montarFalso(_ ambiente: [String: String]) -> ModeloApp {
        let semRede = ambiente["CUSTTA_REDE"] == "offline"
        let conta = ContaFalsa(inicial: ambiente["CUSTTA_CONTA"] ?? "nenhuma")
        let falha: String? = switch ambiente["CUSTTA_LEITURA"] {
        case "erro": "permission-denied"
        case "formato": "formato-desconhecido"
        default: nil
        }
        let dados: ValorJSON? = switch ambiente["CUSTTA_DADOS"] {
        case "vazio": nil
        case "exemplo": DadosDeExemplo.blob
        default: DadosDeExemplo.vitrine()
        }
        let transporte = TransporteFalsoApp(dados: dados, semRede: semRede, falhaDeLeitura: falha)
        let rede = MonitorDeRede(forcarSemRede: semRede)
        let sincronizador = Sincronizador(transporte: transporte, relogio: RelogioDoSistema(), online: !semRede)
        return ModeloApp(conta: conta, sincronizador: sincronizador, rede: rede)
    }
}
#endif
```

- [ ] **Step 6: Rodar e ver passar**

Run: o `xcodebuild test` do Step 2.
Expected: `ModeloAppTests` com 13 testes verdes (a abertura sem gravar roda nos três cenários), `DadosDeExemploTests` nos seis dias (fins de mês e o 29 de fevereiro) e os testes das Tarefas 3 a 5 verdes.

- [ ] **Step 7: Commit**

```bash
git add app-ios/Custta/Dados/Sistema.swift app-ios/Custta/Conta app-ios/Custta/Falsos app-ios/Custta/Estado app-ios/Custta/Composicao.swift app-ios/CusttaTests/Auxiliares.swift app-ios/CusttaTests/ModeloAppTests.swift app-ios/CusttaTests/DadosDeExemploTests.swift
git commit -m "feat: modelo das telas do app nativo com os serviços falsos" -m "O ModeloApp decide a tela pela conta (entrada, falta pouco ou app), explica a sessão expirada só quando a pessoa não saiu de propósito, segue para o app quando outro aparelho já gravou o perfil e só sai depois que a fila sobe, pedindo internet quando falta. O Sincronizador de verdade roda sobre o transporte falso, então as telas já mostram os estados da sincronização e nunca gravam antes de ver os dados. A composição monta os falsos em Debug; a de produção chega com a camada Firebase. Os dados da vitrine são as três obras do mockup aprovado, com as datas contadas de hoje, para comparar o simulador com ele."
```

---

### Task 10: Telas da etapa 1 com a cara do mockup

**Files:**
- Create: `app-ios/Custta/Identidade/Componentes.swift`, `app-ios/Custta/Identidade/CapsulaDeAbas.swift`
- Create: `app-ios/Custta/Fontes/Roboto-Medium.ttf` e `app-ios/Custta/Fontes/OFL-Roboto.txt` (baixados, travados por SHA-256)
- Create: `app-ios/Custta/Assets.xcassets/LogoGoogle.imageset/Contents.json` e a cópia `app-ios/Custta/Assets.xcassets/LogoGoogle.imageset/google-g.svg` (do `google-g.svg` da raiz, o mesmo do botão do site)
- Modify: `app-ios/Custta/Info.plist` (`UIAppFonts`)
- Create: `app-ios/Custta/Telas/RaizView.swift`, `EntradaView.swift`, `PrincipalView.swift`, `ObrasView.swift`, `AjustesView.swift`
- Modify: `app-ios/Custta/CusttaApp.swift`
- Create: `app-ios/CusttaUITests/Abrir.swift`, `EntradaUITests.swift`, `CriarContaUITests.swift`, `FaltaPoucoUITests.swift`, `ObrasUITests.swift`, `AjustesUITests.swift`
- Delete: `app-ios/CusttaUITests/AberturaUITests.swift` (a abertura de verdade é a tela de entrar, coberta por `EntradaUITests`)
- Modify: `tests/app-ios.test.cjs` (teste no fim)

**Interfaces:**
- Consumes: `ModeloApp` e `Composicao.montar()` (Tarefa 9); `Paleta`, `Aparencia`, `VidroTokens`, `OpcoesDoAparelho`, `.superficie(_:em:)`, ícones `Icones/*` (Tarefa 3); `FundoAurora`, `Aurora`, `HaloDoTitulo`, `Globo`, `Rolagem`, `.pausaOFundoAoRolar()` (Tarefa 4); `LogoEscrito`, `AberturaView` (Tarefa 5); `CredencialApple`, `Usuario` (Tarefa 9); do núcleo, `Nonce`, `validarEntrada`, `validarCadastro`, `validaSenha`, `origens`, `normalizaPerfil`, `nomeDoGoogle`, `mensagemErroSocial`, `codigoDeErroDeConta`, `obrasOrdenadas`, `textoOrcamentoNaLista`, `comparativoEntreObras`, `Fase.rotulo`, `indicador`, `totalBruto`, `orcamentoObra`, `mesesDeObra`, `fmtMeses`, `moeda`, `moedaCurta`, `dataLocalISO`, `textoErroDeLeitura`, `aparadoJS`, `emailParece`.
- Produces: identificadores de acessibilidade que os testes usam — `email`, `senha`, `entrar`, `mensagemEntrada`, `esqueciSenha`, `entrarComApple`, `entrarComGoogle`, `irParaEntrar`, `irParaCriarConta`, `nome`, `sobrenome`, `emailCadastro`, `senhaCadastro`, `confirmacao`, `checklistSenha`, `origem`, `origemDetalhe`, `mensagemCadastro`, `criarConta`, `textoFaltaPouco`, `comecarAUsar`, `usarOutraConta`, `mensagemFaltaPouco`, `obra-<id>` (com o valor de acessibilidade da conferência cruzada), `comparativo`, `obrasVazio`, `obrasCarregando`, `obrasErroLeitura`, `tentarLerDeNovo`, `indicadorSincronizacao`, `sairTopo`, `avisoEmail`, `reenviarLink`, `jaConfirmei`, `mensagemAvisoEmail`, `nomeConta`, `emailConta`, `versao`, `sair`, `aba-obras`, `aba-ajustes`, `aviso`; nos testes de tela, `abrirApp(conta:dados:rede:leitura:argumentos:) -> XCUIApplication`, `XCUIApplication.elemento(_:)`, `XCUIApplication.abrirAba(_:)` e `XCUIApplication.digitar(_:em:seguro:)` (Tarefas 11 e 15).

As telas seguem o mockup aprovado tela a tela (seção "Resultado do portão de desenho"): **entrar** com o título escrito à mão e o halo sobre a aurora de hoje, a dica "Role para entrar", o segmentado de vidro fora do cartão e o cartão Fosco com Apple acima do Google, "ou", campos sólidos, mensagens com ícone (erro, ✓, cadeado), "Esqueci minha senha" com o e-mail do cartão e "Política de Privacidade"; **criar conta** no mesmo cartão, com o checklist da senha em duas colunas (uma na letra grande) e "Como conheceu o Custta?" no menu do sistema; **falta pouco** no mesmo cartão, com "Você entrou com a Apple." ou "Você entrou com o Google" e o e-mail; **obras** no vidro Transparente sobre a aurora funda, com o título grande do sistema, sincronização e sair na barra, aviso de e-mail, "N obras", um cartão por obra e o comparativo; **Ajustes** só com a Conta e a versão. A aurora assenta ao entrar e clareia ao sair. A cápsula de abas é própria e só a aba escolhida fica montada (ver "Decisões"). Os fluxos e os textos são os do esqueleto validado no plano anterior, com três mudanças que o mockup trouxe: o esqueci a senha dentro do cartão, a saída pelo alerta do sistema e a lista vazia com o texto provisório.

- [ ] **Step 1: Escrever os testes de tela que falham**

`app-ios/CusttaUITests/Abrir.swift`:

```swift
import XCTest

/// Abre o app com os serviços falsos (Custta/Falsos). Nada de rede nem de Firebase.
@MainActor
func abrirApp(conta: String = "nenhuma", dados: String = "exemplo", rede: String? = nil, leitura: String? = nil,
              argumentos: [String] = []) -> XCUIApplication {
    let app = XCUIApplication()
    var ambiente = ["CUSTTA_SERVICOS": "falsos", "CUSTTA_CONTA": conta, "CUSTTA_DADOS": dados]
    if let rede { ambiente["CUSTTA_REDE"] = rede }
    if let leitura { ambiente["CUSTTA_LEITURA"] = leitura }
    app.launchEnvironment = ambiente
    app.launchArguments += argumentos
    app.launch()
    return app
}

extension XCUIApplication {
    /// Elemento por identificador, de qualquer tipo (linha de lista, seção, texto).
    func elemento(_ id: String) -> XCUIElement { descendants(matching: .any).matching(identifier: id).firstMatch }

    /// Troca de aba pela cápsula de abas (aba-obras, aba-ajustes).
    func abrirAba(_ aba: String) {
        let botao = buttons["aba-\(aba)"]
        XCTAssertTrue(botao.waitForExistence(timeout: 10), "aba \(aba)")
        botao.tap()
    }

    func digitar(_ texto: String, em id: String, seguro: Bool = false) {
        let campo = seguro ? secureTextFields[id] : textFields[id]
        XCTAssertTrue(campo.waitForExistence(timeout: 10), "campo \(id)")
        campo.tap()
        campo.typeText(texto)
    }
}
```

`app-ios/CusttaUITests/EntradaUITests.swift`:

```swift
import XCTest

final class EntradaUITests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    @MainActor func testEntrarComEmailESenhaAbreAsObras() {
        let app = abrirApp()
        app.digitar("giovani@exemplo.com", em: "email")
        app.digitar("Casa2026x", em: "senha", seguro: true)
        app.buttons["entrar"].tap()
        XCTAssertTrue(app.elemento("obra-o3").waitForExistence(timeout: 10))
    }

    @MainActor func testMensagensDoFormulario() {
        let app = abrirApp()
        XCTAssertTrue(app.buttons["entrar"].waitForExistence(timeout: 10))
        app.buttons["entrar"].tap()
        XCTAssertEqual(app.staticTexts["mensagemEntrada"].label, "Digite seu e-mail.")
        app.digitar("giovani@exemplo.com", em: "email")
        app.buttons["entrar"].tap()
        XCTAssertEqual(app.staticTexts["mensagemEntrada"].label, "Digite a senha.")
        app.digitar("Errada123", em: "senha", seguro: true)
        app.buttons["entrar"].tap()
        let mensagem = app.staticTexts["mensagemEntrada"]
        XCTAssertTrue(mensagem.waitForExistence(timeout: 5))
        expectation(for: NSPredicate(format: "label == %@", "E-mail ou senha incorretos."), evaluatedWith: mensagem)
        waitForExpectations(timeout: 5)
    }

    /// Como no site: "Esqueci minha senha" usa o e-mail digitado no próprio cartão.
    @MainActor func testEsqueciASenha() {
        let app = abrirApp()
        XCTAssertTrue(app.buttons["esqueciSenha"].waitForExistence(timeout: 10))
        app.buttons["esqueciSenha"].tap()
        XCTAssertEqual(app.staticTexts["mensagemEntrada"].label, "Digite seu e-mail no campo acima primeiro.")
        app.digitar("ninguem@exemplo.com", em: "email")
        app.buttons["esqueciSenha"].tap()
        let mensagem = app.staticTexts["mensagemEntrada"]
        expectation(for: NSPredicate(format: "label == %@", "E-mail ou senha incorretos."), evaluatedWith: mensagem)
        waitForExpectations(timeout: 5)
        let campo = app.textFields["email"]
        campo.tap()
        campo.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 30) + "giovani@exemplo.com")
        app.buttons["esqueciSenha"].tap()
        expectation(for: NSPredicate(format: "label == %@", "Enviamos um link de redefinição pro seu e-mail."), evaluatedWith: mensagem)
        waitForExpectations(timeout: 5)
    }

    @MainActor func testAppleVemAntesDoGoogle() {
        let app = abrirApp()
        let apple = app.buttons["entrarComApple"], google = app.buttons["entrarComGoogle"]
        XCTAssertTrue(apple.waitForExistence(timeout: 10))
        XCTAssertTrue(google.exists)
        XCTAssertLessThan(apple.frame.minY, google.frame.minY, "Guideline 4.8: Apple acima do Google")
    }
}
```

`app-ios/CusttaUITests/CriarContaUITests.swift`:

```swift
import XCTest

final class CriarContaUITests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    @MainActor private func abrirCriarConta() -> XCUIApplication {
        let app = abrirApp()
        let link = app.buttons["irParaCriarConta"]
        XCTAssertTrue(link.waitForExistence(timeout: 10))
        link.tap()
        XCTAssertTrue(app.textFields["nome"].waitForExistence(timeout: 5))
        return app
    }

    @MainActor func testChecklistDaSenhaAcompanhaADigitacao() {
        let app = abrirCriarConta()
        let tamanho = app.staticTexts["8 caracteres ou mais: falta"]
        XCTAssertTrue(tamanho.waitForExistence(timeout: 5))
        app.digitar("Casa2026x", em: "senhaCadastro", seguro: true)
        XCTAssertTrue(app.staticTexts["8 caracteres ou mais: ok"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Um número: ok"].exists)
    }

    @MainActor func testValidacaoNaOrdemDoSiteECriacao() {
        let app = abrirCriarConta()
        app.buttons["criarConta"].tap()
        XCTAssertEqual(app.staticTexts["mensagemCadastro"].label, "Digite seu nome.")
        app.digitar("Giovani", em: "nome")
        app.digitar("novo@exemplo.com", em: "emailCadastro")
        app.digitar("Casa2026x", em: "senhaCadastro", seguro: true)
        app.digitar("Outra2026x", em: "confirmacao", seguro: true)
        app.buttons["criarConta"].tap()
        XCTAssertEqual(app.staticTexts["mensagemCadastro"].label, "As senhas não são iguais.")
        let confirmacao = app.secureTextFields["confirmacao"]
        confirmacao.tap()
        confirmacao.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 10) + "Casa2026x")
        app.buttons["criarConta"].tap()
        XCTAssertEqual(app.staticTexts["mensagemCadastro"].label, "Conte como conheceu o Custta.")
        app.buttons["origem"].tap()
        app.buttons["Pesquisa no Google"].tap()
        app.buttons["criarConta"].tap()
        XCTAssertTrue(app.elemento("avisoEmail").waitForExistence(timeout: 10), "conta nova entra no app com o aviso de e-mail")
    }
}
```

`app-ios/CusttaUITests/FaltaPoucoUITests.swift`:

```swift
import XCTest

final class FaltaPoucoUITests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    @MainActor func testContaAppleSoPedeAOrigem() {
        let app = abrirApp(conta: "apple-sem-perfil")
        XCTAssertTrue(app.staticTexts["Só falta contar como você conheceu o Custta."].waitForExistence(timeout: 10))
        XCTAssertFalse(app.textFields["nome"].exists, "a revisão da Apple reprova pedir o nome de novo")
        app.buttons["origem"].tap()
        app.buttons["Instagram"].tap()
        app.buttons["comecarAUsar"].tap()
        XCTAssertTrue(app.elemento("obra-o3").waitForExistence(timeout: 10))
    }

    @MainActor func testContaGoogleConfirmaONome() {
        let app = abrirApp(conta: "google-sem-perfil")
        XCTAssertTrue(app.staticTexts["Confirme seu nome e conte como conheceu o Custta."].waitForExistence(timeout: 10))
        XCTAssertEqual(app.textFields["nome"].value as? String, "Giovani")
        app.buttons["comecarAUsar"].tap()
        XCTAssertEqual(app.staticTexts["mensagemFaltaPouco"].label, "Conte como conheceu o Custta.")
    }
}
```

`app-ios/CusttaUITests/ObrasUITests.swift` (os valores esperados são os do `calc.js` para os `DadosDeExemplo`: Casa Alphaville gastou R$ 329.000,00 de R$ 400.000, 82%; o Sobrado gastou R$ 559.500,75 de R$ 500.000, 112%, passou R$ 60 mil):

```swift
import XCTest

final class ObrasUITests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    @MainActor func testListaNaOrdemDoSiteComOsTotaisDoNucleo() {
        let app = abrirApp(conta: "senha")
        let ids = ["obra-o3", "obra-o1", "obra-o4", "obra-o2"]
        XCTAssertTrue(app.elemento(ids[0]).waitForExistence(timeout: 10))
        XCTAssertTrue(app.elemento(ids[1]).exists)
        XCTAssertLessThan(app.elemento(ids[0]).frame.minY, app.elemento(ids[1]).frame.minY, "não vendidas, a mais recente primeiro")
        let casa = app.elemento("obra-o1")
        XCTAssertEqual(casa.label, "Casa Alphaville")
        let valor = casa.value as? String ?? ""
        XCTAssertTrue(valor.contains("Em construção · "), valor)
        XCTAssertTrue(valor.contains("total gasto R$\u{00A0}329.000,00"), valor)
        XCTAssertTrue(valor.contains("82% do orçamento"), valor)
        app.swipeUp()
        let vendida = app.elemento("obra-o2")
        XCTAssertTrue(vendida.waitForExistence(timeout: 5))
        XCTAssertTrue((vendida.value as? String ?? "").contains("112% · passou R$ 60 mil"))
        XCTAssertTrue(app.staticTexts["4 obras"].exists || app.otherElements["4 obras"].exists)
    }

    @MainActor func testComparativoComDuasObrasComGasto() {
        let app = abrirApp(conta: "senha")
        let painel = app.elemento("comparativo")
        for _ in 0..<6 where !painel.exists { app.swipeUp() }
        XCTAssertTrue(painel.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Comparativo entre obras"].exists)
        // Só as obras com gasto entram: a o3 (sem gasto) fica de fora.
        XCTAssertEqual(painel.descendants(matching: .any).matching(NSPredicate(format: "label == %@", "Terreno novo")).count, 0)
    }

    @MainActor func testSemObrasMostraOVazio() {
        let app = abrirApp(conta: "senha", dados: "vazio")
        XCTAssertTrue(app.elemento("obrasVazio").waitForExistence(timeout: 10))
    }

    @MainActor func testAbreSemInternetComTudoLa() {
        let app = abrirApp(conta: "senha", rede: "offline")
        XCTAssertTrue(app.elemento("obra-o1").waitForExistence(timeout: 10), "dados do cache sem rede")
        XCTAssertEqual(app.buttons["indicadorSincronizacao"].label, "Sem conexão")
    }

    @MainActor func testErroDeLeituraMostraNaoSincronizouETentaDeNovo() {
        let app = abrirApp(conta: "senha", leitura: "erro")
        let indicador = app.buttons["indicadorSincronizacao"]
        XCTAssertTrue(indicador.waitForExistence(timeout: 10))
        XCTAssertEqual(indicador.label, "Não sincronizou")
        XCTAssertTrue(app.elemento("obrasErroLeitura").exists, "a lista explica o erro em vez de carregar para sempre")
        indicador.tap()
        XCTAssertTrue(app.staticTexts["Tentando de novo…"].waitForExistence(timeout: 5))
    }

    @MainActor func testDocumentoIlegivelExplicaQueNadaMudou() {
        let app = abrirApp(conta: "senha", leitura: "formato")
        XCTAssertTrue(app.elemento("obrasErroLeitura").waitForExistence(timeout: 10), "nada de carregando para sempre")
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Nada foi alterado")).firstMatch.exists)
        XCTAssertTrue(app.buttons["tentarLerDeNovo"].exists)
    }

    @MainActor func testAvisoDeEmailNaoConfirmado() {
        let app = abrirApp(conta: "senha-nao-confirmada")
        XCTAssertTrue(app.elemento("avisoEmail").waitForExistence(timeout: 10))
        app.buttons["reenviarLink"].tap()
        XCTAssertTrue(app.staticTexts["Link reenviado. Confira também a caixa de spam."].waitForExistence(timeout: 5))
        app.buttons["jaConfirmei"].tap()
        XCTAssertTrue(app.staticTexts["Ainda não recebemos a confirmação. Toque no link do e-mail e tente de novo."].waitForExistence(timeout: 5))
    }
}
```

`app-ios/CusttaUITests/AjustesUITests.swift`:

```swift
import XCTest

final class AjustesUITests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    @MainActor private func abrirAjustes(rede: String? = nil) -> XCUIApplication {
        let app = abrirApp(conta: "senha", rede: rede)
        app.abrirAba("ajustes")
        XCTAssertTrue(app.buttons["sair"].waitForExistence(timeout: 5))
        return app
    }

    @MainActor func testContaESair() {
        let app = abrirAjustes()
        XCTAssertTrue(app.staticTexts["nomeConta"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["nomeConta"].label, "Giovani Stuchi")
        XCTAssertEqual(app.staticTexts["emailConta"].value as? String, "giovani@exemplo.com")
        XCTAssertEqual(app.staticTexts["versao"].label, "Versão 2.0 (1)")
        app.buttons["sair"].tap()
        XCTAssertTrue(app.alerts["Sair da conta?"].waitForExistence(timeout: 5), "confirmação pelo alerta do sistema")
        app.alerts.buttons["Sair"].tap()
        XCTAssertTrue(app.textFields["email"].waitForExistence(timeout: 10), "voltou para a tela de entrar")
    }

    @MainActor func testSairSemInternetPedeParaConectar() {
        let app = abrirAjustes(rede: "offline")
        app.buttons["sair"].tap()
        app.alerts.buttons["Sair"].tap()
        XCTAssertTrue(app.alerts["Conecte à internet e aguarde a sincronização antes de sair."].waitForExistence(timeout: 10))
        app.alerts.buttons["OK"].tap()
        XCTAssertTrue(app.buttons["sair"].exists, "continua em Ajustes")
    }

    @MainActor func testSairDoTopoPedeConfirmacaoECancelarFica() {
        let app = abrirApp(conta: "senha")
        let topo = app.buttons["sairTopo"]
        XCTAssertTrue(topo.waitForExistence(timeout: 10))
        topo.tap()
        XCTAssertTrue(app.alerts["Sair da conta?"].waitForExistence(timeout: 5))
        app.alerts.buttons["Cancelar"].tap()
        XCTAssertTrue(app.elemento("obra-o1").waitForExistence(timeout: 5), "continua em Obras")
    }

    @MainActor func testCapsulaDeAbasTrocaETemNomeEPosicao() {
        let app = abrirApp(conta: "senha")
        let obras = app.buttons["aba-obras"], ajustes = app.buttons["aba-ajustes"]
        XCTAssertTrue(obras.waitForExistence(timeout: 10))
        XCTAssertTrue(obras.isSelected)
        XCTAssertEqual(obras.label, "Obras")
        XCTAssertEqual(ajustes.value as? String, "2 de 2")
        ajustes.tap()
        XCTAssertTrue(app.buttons["sair"].waitForExistence(timeout: 5))
        XCTAssertTrue(ajustes.isSelected)
        XCTAssertFalse(app.elemento("obra-o1").exists, "só a aba escolhida fica na tela (e no VoiceOver)")
        obras.tap()
        XCTAssertTrue(app.elemento("obra-o1").waitForExistence(timeout: 5))
    }
}
```

No fim de `tests/app-ios.test.cjs`:

```js
test('fonte do botão do Google: Roboto Medium travada, registrada e com a licença', () => {
  const fonte = readFileSync(join(RAIZ, 'app-ios/Custta/Fontes/Roboto-Medium.ttf'));
  const hash = require('node:crypto').createHash('sha256').update(fonte).digest('hex');
  assert.equal(hash, '663bedb17df44144ea2ccf4c3a3c1853547bcfed2395ad29904502ea92c74bcb', 'Roboto v3.016 (unhinted/static) do googlefonts/roboto-3-classic');
  assert.match(ler('app-ios/Custta/Fontes/OFL-Roboto.txt'), /SIL Open Font License, Version 1\.1/);
  assert.match(ler('app-ios/Custta/Info.plist'), /<key>UIAppFonts<\/key>\s*<array>\s*<string>Roboto-Medium\.ttf<\/string>/);
});
```

Apague `app-ios/CusttaUITests/AberturaUITests.swift`.

- [ ] **Step 2: Rodar e ver falhar**

Run: `xcodebuild test -project app-ios/Custta.xcodeproj -scheme Custta -destination "$(node scripts/simulador-ios.mjs)" -skipMacroValidation -skipPackagePluginValidation -onlyUsePackageVersionsFromResolvedFile CODE_SIGNING_ALLOWED=NO -only-testing:CusttaUITests`
Expected: FAIL; os 19 testes falham esperando o primeiro elemento (`entrar`, `email`, `obra-o3`…), porque o app ainda mostra só a abertura.

Run: `node --test tests/app-ios.test.cjs`
Expected: FAIL em "fonte do botão do Google": `ENOENT … Roboto-Medium.ttf`.

- [ ] **Step 3: A fonte do botão do Google e o G oficial**

A Roboto Medium vem da release v3.016 do `googlefonts/roboto-3-classic` (licença OFL 1.1), conferida pelo SHA-256 do arquivo e do pacote:

```bash
mkdir -p "$TMPDIR/roboto" && curl -fsSL -o "$TMPDIR/roboto/Roboto_v3.016.zip" \
  https://github.com/googlefonts/roboto-3-classic/releases/download/v3.016/Roboto_v3.016.zip
echo "1653dbe12f248da8fb0b9920db7b9496cd677ed3981154f6f15285c8bd4e334f  $TMPDIR/roboto/Roboto_v3.016.zip" | shasum -a 256 -c
unzip -o -q "$TMPDIR/roboto/Roboto_v3.016.zip" 'unhinted/static/Roboto-Medium.ttf' -d "$TMPDIR/roboto"
mkdir -p app-ios/Custta/Fontes
cp "$TMPDIR/roboto/unhinted/static/Roboto-Medium.ttf" app-ios/Custta/Fontes/Roboto-Medium.ttf
curl -fsSL -o app-ios/Custta/Fontes/OFL-Roboto.txt https://raw.githubusercontent.com/googlefonts/roboto-3-classic/v3.016/OFL.txt
shasum -a 256 app-ios/Custta/Fontes/*
/usr/libexec/PlistBuddy -c "Add :UIAppFonts array" -c "Add :UIAppFonts:0 string Roboto-Medium.ttf" app-ios/Custta/Info.plist
mkdir -p app-ios/Custta/Assets.xcassets/LogoGoogle.imageset
cp google-g.svg app-ios/Custta/Assets.xcassets/LogoGoogle.imageset/google-g.svg
```

Expected: `OK` no `shasum -c`; `663bedb17df44144ea2ccf4c3a3c1853547bcfed2395ad29904502ea92c74bcb` para a fonte e `061402327a96aadb0bfb694a960ed289ecd38d383e396243831ab81feb109c41` para a licença; o `Info.plist` ganha só a chave `UIAppFonts` (confira com `git diff`).

`app-ios/Custta/Assets.xcassets/LogoGoogle.imageset/Contents.json`:

```json
{
  "images" : [ { "filename" : "google-g.svg", "idiom" : "universal" } ],
  "info" : { "author" : "xcode", "version" : 1 },
  "properties" : { "preserves-vector-representation" : true, "template-rendering-intent" : "original" }
}
```

- [ ] **Step 4: Os componentes**

`app-ios/Custta/Identidade/Componentes.swift`:

```swift
import SwiftUI
import AuthenticationServices
import CusttaNucleo

/* Peças das telas com a cara do PWA, escritas uma vez: campo sólido com rótulo, botões (principal,
   secundário, Apple e Google), mensagem com ícone, link sublinhado, divisor "ou", etiqueta de fase e
   barra de orçamento. Cores só por token; textos com Dynamic Type, menos os botões da Apple e do
   Google, que não crescem (decisão do mockup) e mostram o Visualizador de Conteúdo Grande. */

/// Campo sólido do cartão de entrada: rótulo em cima, exemplo na cor secundária, olho na senha.
struct CampoDeEntrada: View {
    let rotulo: String
    var opcional = false
    let exemplo: String
    @Binding var texto: String
    let identificador: String
    var senha = false
    var invalido = false
    var tipo: UITextContentType?
    var teclado: UIKeyboardType = .default
    var maiusculas: TextInputAutocapitalization = .sentences
    /// Foco compartilhado pela tela, pela chave do campo (a mesma da validação: "email", "senha"…).
    var foco: FocusState<String?>.Binding
    let chave: String
    @Environment(\.paleta) private var paleta
    @Environment(\.vidro) private var vidro
    @State private var mostrar = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            (Text(rotulo).foregroundStyle(paleta.cor(vidro.secundario))
             + Text(opcional ? " (opcional)" : "").foregroundStyle(paleta.cor(.textoTerciario)))
                .font(.footnote.weight(.medium))
                .accessibilityHidden(true)
            HStack(spacing: 8) {
                Group {
                    if senha && !mostrar {
                        SecureField(rotulo, text: $texto, prompt: Text(exemplo).foregroundStyle(paleta.cor(vidro.secundario)))
                    } else {
                        TextField(rotulo, text: $texto, prompt: Text(exemplo).foregroundStyle(paleta.cor(vidro.secundario)), axis: senha ? .horizontal : .vertical)
                    }
                }
                .textContentType(tipo)
                .keyboardType(teclado)
                .textInputAutocapitalization(maiusculas)
                .autocorrectionDisabled()
                .font(.body)
                .foregroundStyle(paleta.cor(.texto))
                .focused(foco, equals: chave)
                .accessibilityLabel(rotulo)
                .accessibilityIdentifier(identificador)
                if senha {
                    Button { mostrar.toggle() } label: {
                        Image(decorative: mostrar ? "Icones/olhoFechado" : "Icones/olho")
                            .resizable().frame(width: 20, height: 20)
                            .foregroundStyle(paleta.cor(vidro.secundario))
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel(mostrar ? "Esconder senha" : "Mostrar senha")
                }
            }
            .padding(.leading, 13)
            .padding(.trailing, senha ? 2 : 13)
            .padding(.vertical, senha ? 2 : 11)
            .frame(minHeight: 48)
            .background(paleta.cor(.campo), in: .rect(cornerRadius: 11))
            .overlay(RoundedRectangle(cornerRadius: 11).strokeBorder(paleta.cor(invalido ? .alerta : .campoBorda), lineWidth: 1))
        }
    }
}

/// Botão principal: sempre sólido, na cor da marca (como no site).
struct BotaoPrincipal: ButtonStyle {
    @Environment(\.paleta) private var paleta
    @Environment(\.opcoes) private var opcoes
    @Environment(\.isEnabled) private var habilitado

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .multilineTextAlignment(.center)
            .foregroundStyle(paleta.cor(.sobreMarca))
            .frame(maxWidth: .infinity, minHeight: 48)
            .padding(.horizontal, 16)
            .background(paleta.cor(.marca), in: .capsule)
            .opacity(habilitado ? 1 : 0.6)
            .scaleEffect(configuration.isPressed && !opcoes.reduzirMovimento ? 0.97 : 1)
            .animation(opcoes.reduzirMovimento ? nil : .spring(duration: 0.3), value: configuration.isPressed)
    }
}

/// Botão secundário do site ("ghost"): "Reenviar link", "Sair da conta".
struct BotaoSecundario: ButtonStyle {
    @Environment(\.paleta) private var paleta
    @Environment(\.opcoes) private var opcoes

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .multilineTextAlignment(.center)
            .foregroundStyle(paleta.cor(.fantasmaTexto))
            .frame(maxWidth: .infinity, minHeight: 48)
            .padding(.horizontal, 16)
            .background(paleta.cor(.fantasmaFundo), in: .capsule)
            .scaleEffect(configuration.isPressed && !opcoes.reduzirMovimento ? 0.97 : 1)
            .animation(opcoes.reduzirMovimento ? nil : .spring(duration: 0.3), value: configuration.isPressed)
    }
}

/// O botão oficial da Apple ("Continuar com a Apple"), branco no escuro e preto no claro, em cápsula.
struct BotaoApple: View {
    let pedir: (ASAuthorizationAppleIDRequest) -> Void
    let concluir: (Result<ASAuthorization, Error>) -> Void
    @Environment(\.colorScheme) private var esquema

    var body: some View {
        SignInWithAppleButton(.continue, onRequest: pedir, onCompletion: concluir)
            .signInWithAppleButtonStyle(esquema == .dark ? .white : .black)
            .frame(height: 44)
            .clipShape(.capsule)
            .accessibilityIdentifier("entrarComApple")
    }
}

/// O botão do Google pelas regras do Google: cores fixas, Roboto Medium 14/20 e o G oficial.
struct BotaoGoogle: View {
    let acao: () -> Void
    @Environment(\.paleta) private var paleta

    var body: some View {
        Button(action: acao) {
            HStack(spacing: 10) {
                Image(decorative: "LogoGoogle").resizable().frame(width: 18, height: 18)
                Text("Continuar com o Google")
                    .font(.custom("Roboto-Medium", fixedSize: 14))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .accessibilityHidden(true)
            }
            .foregroundStyle(paleta.cor(.googleTexto))
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(paleta.cor(.googleFundo), in: .capsule)
            .overlay(Capsule().strokeBorder(paleta.cor(.googleBorda), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Continuar com o Google")
        .accessibilityShowsLargeContentViewer { Label("Continuar com o Google", image: "LogoGoogle") }
        .accessibilityIdentifier("entrarComGoogle")
    }
}

/// Mensagem de um formulário: erro em vermelho, sucesso com ✓ na cor do link, sessão expirada com
/// cadeado neutro e atenção em âmbar (o site deixava sucesso e sessão expirada em vermelho).
struct Mensagem: View {
    enum Tipo { case erro, ok, cadeado, atencao }
    let tipo: Tipo
    let texto: String
    var identificador: String?
    @Environment(\.paleta) private var paleta
    @Environment(\.vidro) private var vidro

    var body: some View {
        Label {
            Text(texto).foregroundStyle(paleta.cor(tipo == .erro ? .erroNoVidro : vidro.secundario))
        } icon: {
            Image(systemName: icone).foregroundStyle(paleta.cor(corDoIcone))
        }
        .font(.footnote)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityLabel(texto)
        .accessibilityIdentifier(identificador ?? "")
        .onAppear { AccessibilityNotification.Announcement(texto).post() }
    }

    private var icone: String {
        switch tipo {
        case .erro: return "exclamationmark.circle.fill"
        case .ok: return "checkmark.circle.fill"
        case .cadeado: return "lock.fill"
        case .atencao: return "exclamationmark.circle.fill"
        }
    }

    private var corDoIcone: Token {
        switch tipo {
        case .erro: return .erroNoVidro
        case .ok: return .linkNoVidro
        case .cadeado: return vidro.secundario
        case .atencao: return .alerta
        }
    }
}

/// Link solto: sublinhado, na cor do link sobre o vidro (no Transparente, a do texto com o traço da marca).
struct LinkSublinhado: ButtonStyle {
    var neutro = false
    @Environment(\.paleta) private var paleta
    @Environment(\.vidro) private var vidro

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(vidro.nivel == .transparente && !neutro ? .semibold : .regular))
            .foregroundStyle(paleta.cor(neutro ? vidro.secundario : vidro.link))
            .underline(true, color: paleta.cor(neutro ? vidro.secundario : .linkNoVidro))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, minHeight: 44)
            .opacity(configuration.isPressed ? 0.6 : 1)
    }
}

/// O "ou" entre os botões sociais e o e-mail.
struct DivisorOu: View {
    @Environment(\.paleta) private var paleta
    @Environment(\.vidro) private var vidro

    var body: some View {
        HStack(spacing: 10) {
            Rectangle().fill(paleta.cor(.linha)).frame(height: 1)
            Text("ou").font(.footnote).foregroundStyle(paleta.cor(vidro.secundario))
            Rectangle().fill(paleta.cor(.linha)).frame(height: 1)
        }
        .accessibilityHidden(true)
    }
}

/// Etiqueta da fase da obra, nas cores do site (âmbar, azul e verde).
struct EtiquetaDeFase: View {
    let fase: Fase
    @Environment(\.paleta) private var paleta

    var body: some View {
        let (texto, fundo): (Token, Token) = switch fase {
        case .construcao: (.alerta, .alertaFundo)
        case .pronta: (.informacao, .informacaoFundo)
        case .vendida: (.positivo, .positivoFundo)
        }
        Text(fase.rotulo)
            .font(.caption.weight(.semibold))
            .foregroundStyle(paleta.cor(texto))
            .padding(.horizontal, 8)
            .padding(.vertical, 1)
            .background(paleta.cor(fundo), in: .capsule)
    }
}

/// Barra fina de progresso: degradê da marca, ou âmbar quando pede atenção.
struct BarraDeProgresso: View {
    let fracao: Double
    let atencao: Bool
    var altura: CGFloat = 6
    @Environment(\.paleta) private var paleta

    var body: some View {
        GeometryReader { geo in
            Capsule().fill(paleta.cor(.texto).opacity(0.12))
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(atencao ? AnyShapeStyle(paleta.cor(.alerta))
                                      : AnyShapeStyle(LinearGradient(colors: [paleta.cor(.marca), paleta.cor(.destaque)],
                                                                     startPoint: .leading, endPoint: .trailing)))
                        .frame(width: geo.size.width * min(1, max(0, fracao)))
                }
        }
        .frame(height: altura)
        .accessibilityHidden(true)
    }
}
```

`app-ios/Custta/Identidade/CapsulaDeAbas.swift`:

```swift
import SwiftUI

/* Cápsula de abas própria (decisão do mockup aprovado): a barra de vidro do PWA com a lente que
   desliza para a aba escolhida. O que a barra do sistema dava de graça vem à mão: VoiceOver lê o nome,
   "1 de 2" e "selecionada", alvo de 44 pt e o Visualizador de Conteúdo Grande no lugar de crescer com a
   letra. Na etapa 1, duas abas e nenhum +. */

enum Aba: String, CaseIterable, Identifiable, Sendable {
    case obras
    case ajustes

    var id: String { rawValue }
    var titulo: String { self == .obras ? "Obras" : "Ajustes" }
    var icone: String { self == .obras ? "Icones/predio" : "Icones/engrenagem" }
}

struct CapsulaDeAbas: View {
    @Binding var escolhida: Aba
    var abas: [Aba] = Aba.allCases
    @Environment(\.paleta) private var paleta
    @Environment(\.opcoes) private var opcoes
    @Namespace private var lente

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(abas.enumerated()), id: \.element) { indice, aba in
                let ativa = aba == escolhida
                Button {
                    guard !ativa else { return }
                    if opcoes.reduzirMovimento { escolhida = aba }
                    else { withAnimation(.spring(duration: 0.35, bounce: 0.15)) { escolhida = aba } }
                } label: {
                    VStack(spacing: 2) {
                        Image(decorative: aba.icone).resizable().frame(width: 26, height: 24)
                        Text(aba.titulo).font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(paleta.cor(ativa ? .linkNoVidro : .texto))
                    .frame(maxWidth: .infinity, minHeight: 54)
                    .background {
                        if ativa { Capsule().fill(paleta.cor(.lenteAba)).matchedGeometryEffect(id: "lente", in: lente) }
                    }
                    .contentShape(.capsule)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(aba.titulo)
                .accessibilityValue("\(indice + 1) de \(abas.count)")
                .accessibilityAddTraits(ativa ? [.isSelected] : [])
                .accessibilityIdentifier("aba-\(aba.rawValue)")
                .accessibilityShowsLargeContentViewer { Label(aba.titulo, image: aba.icone) }
            }
        }
        .padding(4)
        .frame(height: 62)
        .superficie(.navegacao, em: .capsule)
        .dynamicTypeSize(.large)
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }
}
```

- [ ] **Step 5: As telas**

`app-ios/Custta/CusttaApp.swift` (troque o da Tarefa 5; a `AberturaView` continua, para quando não há serviço):

```swift
import SwiftUI

@main
struct CusttaApp: App {
    /// Nos testes de unidade o app só hospeda o pacote de testes: não monta serviço nenhum.
    private static let hospedandoTestes = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    @State private var modelo: ModeloApp? = CusttaApp.hospedandoTestes ? nil : Composicao.montar()
    @Environment(\.scenePhase) private var fase

    var body: some Scene {
        WindowGroup {
            if let modelo {
                RaizView()
                    .environment(modelo)
                    .onChange(of: fase) { _, nova in
                        if nova == .active { Task { await modelo.voltouParaFrente() } }
                    }
            } else {
                // Sem serviço (Release antes da camada Firebase, ou hospedando os testes de unidade).
                AberturaView()
            }
        }
    }
}

/// A abertura: o fundo do Custta e o título se escrevendo, para quando o app ainda não tem serviço.
struct AberturaView: View {
    @Environment(\.accessibilityReduceMotion) private var reduzirMovimento

    var body: some View {
        ZStack {
            FundoAurora(intensidade: Aurora.intensidade(tela: .entrada, pele: .esmeralda, escuro: true), animada: !reduzirMovimento)
            Globo(animado: !reduzirMovimento)
            LogoEscrito(animado: !reduzirMovimento)
        }
        .preferredColorScheme(.dark)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Custta")
        .accessibilityIdentifier("abertura")
    }
}
```

`app-ios/Custta/Telas/RaizView.swift`:

```swift
import SwiftUI

/// Escolhe a tela pela fase da conta, desenha o fundo (aurora e globo) e aplica a aparência deste
/// aparelho, a dose de vidro da tela e as opções do iPhone.
struct RaizView: View {
    @Environment(ModeloApp.self) private var modelo
    @AppStorage(Aparencia.chaveTema) private var tema = "escuro"
    @AppStorage(Aparencia.chavePele) private var pele = "esmeralda"
    @AppStorage(Aparencia.chaveVidro) private var escolhaDeVidro = "transparente"
    @Environment(\.accessibilityReduceMotion) private var reduzirMovimento
    @Environment(\.accessibilityReduceTransparency) private var reduzirTransparencia
    @Environment(\.colorSchemeContrast) private var contraste
    @State private var poucaEnergia = ProcessInfo.processInfo.isLowPowerModeEnabled
    @State private var rolagem = Rolagem()
    #if DEBUG
    // Os testes de tela não mudam os ajustes do sistema: ligam cada opção por argumento.
    @AppStorage("custta.reduzirMovimento") private var forcarReduzirMovimento = false
    @AppStorage("custta.reduzirTransparencia") private var forcarReduzirTransparencia = false
    @AppStorage("custta.aumentarContraste") private var forcarAumentarContraste = false
    /// Quadro da deriva (s) em que a aurora fica parada nos testes de contraste; negativo = não força.
    @AppStorage("custta.quadroDaAurora") private var quadroDaAurora = -1.0
    #endif

    var body: some View {
        let paleta = Paleta(pele: Aparencia.pele(pele))
        let escuro = Aparencia.esquema(tema) == .dark
        let opcoes = opcoesDoAparelho
        let tela: TelaDoVidro = if case .principal = modelo.fase { .app } else { .entrada }
        let fundoAnda = opcoes.animaFundo && !rolagem.rolando
        ZStack {
            FundoAurora(intensidade: Aurora.intensidade(tela: tela, pele: paleta.pele, escuro: escuro), animada: fundoAnda,
                        deslocamento: quadroFixo)
                .animation(opcoes.reduzirMovimento ? nil : Aurora.transicao(paraOApp: tela == .app), value: tela)
            Globo(animado: fundoAnda)
            conteudo
                .transition(.opacity)
                .animation(opcoes.reduzirMovimento ? nil : .easeOut(duration: 0.25), value: tela)
        }
        // O aviso fica por cima de todas as telas; vem antes do .environment para receber a mesma paleta.
        .overlay(alignment: .top) { AvisoView() }
        .environment(\.paleta, paleta)
        .environment(\.opcoes, opcoes)
        .environment(\.vidro, VidroTokens.para(tela: tela, escolha: Aparencia.vidro(escolhaDeVidro), opcoes: opcoes))
        .environment(\.rolagem, rolagem)
        .tint(paleta.cor(.marca))
        .preferredColorScheme(Aparencia.esquema(tema))
        .onReceive(NotificationCenter.default.publisher(for: .NSProcessInfoPowerStateDidChange)) { _ in
            poucaEnergia = ProcessInfo.processInfo.isLowPowerModeEnabled
        }
    }

    private var opcoesDoAparelho: OpcoesDoAparelho {
        var o = OpcoesDoAparelho(reduzirMovimento: reduzirMovimento, reduzirTransparencia: reduzirTransparencia,
                                 aumentarContraste: contraste == .increased, poucaEnergia: poucaEnergia)
        #if DEBUG
        o.reduzirMovimento = o.reduzirMovimento || forcarReduzirMovimento
        o.reduzirTransparencia = o.reduzirTransparencia || forcarReduzirTransparencia
        o.aumentarContraste = o.aumentarContraste || forcarAumentarContraste
        #endif
        return o
    }

    private var quadroFixo: TimeInterval {
        #if DEBUG
        return max(0, quadroDaAurora)
        #else
        return 0
        #endif
    }

    @ViewBuilder private var conteudo: some View {
        switch modelo.fase {
        case .carregando:
            ProgressView()
                .accessibilityLabel("Carregando")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .entrada:
            EntradaView(faltaPouco: nil)
        case .faltaPouco(let usuario):
            EntradaView(faltaPouco: usuario)
        case .principal:
            PrincipalView()
        }
    }
}

/// O toast do site: texto curto no topo, em vidro, que some sozinho.
struct AvisoView: View {
    @Environment(ModeloApp.self) private var modelo
    @Environment(\.paleta) private var paleta

    var body: some View {
        if let aviso = modelo.aviso {
            Text(aviso)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(paleta.cor(.texto))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .superficie(.navegacao, em: .capsule)
                .padding(.horizontal, 16)
                .allowsHitTesting(false)                 // fica sobre a barra: não pode engolir o toque nela
                .accessibilityIdentifier("aviso")
                .accessibilityAddTraits(.updatesFrequently)
                .onAppear { AccessibilityNotification.Announcement(aviso).post() }
        }
    }
}
```

`app-ios/Custta/Telas/EntradaView.swift`:

```swift
import SwiftUI
import AuthenticationServices
import CusttaNucleo

/* Entrar, criar conta e falta pouco: a entrada do PWA, com o título escrito à mão sobre a aurora de
   hoje e o cartão de vidro Fosco. Ao rolar, o título sobe e esmaece, como no site (parado com Reduzir
   movimento). O cartão fica reto: o vidro do iOS não acompanha a inclinação 3D do cartão do PWA (decisão
   pendente do Giovani, ver o plano). Entrar e criar conta dividem o cartão, trocados pelo segmentado, que
   é vidro próprio fora do cartão; o falta pouco usa o mesmo cartão. */

enum AbaDaEntrada: String, CaseIterable, Identifiable {
    case entrar
    case criarConta

    var id: String { rawValue }
    var titulo: String { self == .entrar ? "Entrar" : "Criar conta" }
    var identificador: String { self == .entrar ? "irParaEntrar" : "irParaCriarConta" }
}

struct EntradaView: View {
    /// A conta Google ou Apple sem perfil (falta pouco); nil em entrar e criar conta.
    let faltaPouco: Usuario?
    @Environment(\.opcoes) private var opcoes
    @State private var aba = AbaDaEntrada.entrar
    @State private var rolado: CGFloat = 0
    @FocusState private var foco: String?

    var body: some View {
        GeometryReader { geo in
            // Meia tela de rolagem leva o título até o fim do movimento, como o auth.js.
            let p = opcoes.reduzirMovimento ? 0 : min(1, max(0, rolado / (geo.size.height * 0.5)))
            ScrollView {
                VStack(spacing: 0) {
                    TituloDaEntrada(progresso: p)
                        .padding(.bottom, 32)
                    VStack(spacing: 14) {
                        if faltaPouco == nil { SegmentadoDaEntrada(aba: $aba) }
                        VStack(spacing: 0) {
                            if let usuario = faltaPouco { FormFaltaPouco(usuario: usuario, foco: $foco) }
                            else if aba == .entrar { FormEntrar(foco: $foco) }
                            else { FormCriarConta(foco: $foco) }
                        }
                        .padding(EdgeInsets(top: 26, leading: 22, bottom: 20, trailing: 22))
                        .superficie(.cartaoEntrada, em: .rect(cornerRadius: 32))
                    }
                    Color.clear.frame(height: geo.size.height * 0.52)
                }
                .frame(maxWidth: 440)
                .padding(.horizontal, 18)
                .padding(.top, geo.size.height * 0.11)
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .onScrollGeometryChange(for: CGFloat.self) { $0.contentOffset.y + $0.contentInsets.top } action: { _, y in rolado = y }
            .pausaOFundoAoRolar()
        }
    }
}

/// "Controle os custos das suas obras com custta." e a dica de rolar, com o halo no escuro.
struct TituloDaEntrada: View {
    /// 0 no topo; 1 com o cartão reto (o título subiu 80 pt e esmaeceu).
    let progresso: CGFloat
    @Environment(\.paleta) private var paleta
    @Environment(\.opcoes) private var opcoes
    @Environment(\.dynamicTypeSize) private var tamanho
    /// Largura que quebra o título como no mockup ("Controle os custos / das suas obras com").
    @ScaledMetric(relativeTo: .title2) private var larguraDoTitulo = 212

    var body: some View {
        VStack(spacing: 0) {
            Text("Controle os custos das suas obras com")
                .font(.title2.weight(.semibold))
                .multilineTextAlignment(.center)
                // Quebra equilibrada como a do mockup ("Controle os custos / das suas obras com"); na letra
                // grande o texto usa a largura toda.
                .frame(maxWidth: tamanho.isAccessibilitySize ? .infinity : larguraDoTitulo)
                .foregroundStyle(paleta.cor(.texto))
                .shadow(color: paleta.cor(.sombraDoTexto), radius: 4, y: 1)
            LogoEscrito(animado: opcoes.animaFundo)
                .padding(.top, 15)
                .padding(.bottom, 9)
            HStack(spacing: 4) {
                Text("Role para entrar")
                Image(decorative: "Icones/setaBaixo").resizable().frame(width: 13, height: 13)
            }
            .font(.footnote)
            .foregroundStyle(paleta.cor(.texto))
            .shadow(color: paleta.cor(.sombraDoTexto), radius: 4, y: 1)
            .padding(.top, 5)
            .opacity(max(0, 1 - 1.6 * progresso))
            .accessibilityHidden(true)
        }
        .padding(.horizontal, 12)
        .background { HaloDoTitulo(grande: tamanho.isAccessibilitySize) }
        .offset(y: -80 * progresso)
        .opacity(1 - 0.35 * progresso)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Controle os custos das suas obras com Custta")
        .accessibilityAddTraits(.isHeader)
    }
}

/// "Entrar | Criar conta": cápsula de vidro própria, fora do cartão.
struct SegmentadoDaEntrada: View {
    @Binding var aba: AbaDaEntrada
    @Environment(\.paleta) private var paleta

    var body: some View {
        HStack(spacing: 6) {
            ForEach(AbaDaEntrada.allCases) { item in
                let ativa = item == aba
                Button { aba = item } label: {
                    Text(item.titulo)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(paleta.cor(ativa ? .sobreTinta : .texto))
                        .frame(maxWidth: .infinity, minHeight: 44)
                        // Sólido: a 90% do mockup, o branco sobre a tinta fica em 4,4:1 no claro.
                        .background { if ativa { Capsule().fill(paleta.cor(.tinta)) } }
                        .contentShape(.capsule)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(ativa ? [.isSelected] : [])
                .accessibilityIdentifier(item.identificador)
            }
        }
        .padding(4)
        .superficie(.segmentado, em: .capsule)
    }
}

/// Apple acima do Google (Guideline 4.8), um login por vez.
struct BotoesSociais: View {
    let ocupado: Bool
    /// Mensagem de erro do login social (vazia quando a pessoa desistiu).
    let aoFalhar: (String?) -> Void
    let rodar: (@escaping @MainActor () async -> String?) async -> Void
    @Environment(ModeloApp.self) private var modelo
    @State private var nonce = ""

    var body: some View {
        VStack(spacing: 10) {
            BotaoApple { pedido in
                nonce = Nonce.gerar()
                pedido.requestedScopes = [.fullName, .email]
                pedido.nonce = Nonce.sha256(nonce)
            } concluir: { resultado in
                Task { await terminarApple(resultado) }
            }
            BotaoGoogle { Task { await rodar { await modelo.entrarComGoogle() } } }
        }
        .disabled(ocupado)
    }

    private func terminarApple(_ resultado: Result<ASAuthorization, Error>) async {
        switch resultado {
        case .success(let autorizacao):
            guard let c = autorizacao.credential as? ASAuthorizationAppleIDCredential,
                  let dados = c.identityToken, let token = String(data: dados, encoding: .utf8) else {
                aoFalhar(mensagemErroSocial(codigo: "auth/invalid-credential", provedor: "apple.com"))
                return
            }
            let credencial = CredencialApple(idToken: token, nonce: nonce, nomeCompleto: c.fullName)
            await rodar { await modelo.entrarComApple(credencial) }
        case .failure(let erro):
            let n = erro as NSError
            let texto = mensagemErroSocial(codigo: codigoDeErroDeConta(dominio: n.domain, codigo: n.code), provedor: "apple.com")
            aoFalhar(texto.isEmpty ? nil : texto)
        }
    }
}

/// Entrar com e-mail e senha; "Esqueci minha senha" usa o e-mail do próprio cartão, como no site.
struct FormEntrar: View {
    var foco: FocusState<String?>.Binding
    @Environment(ModeloApp.self) private var modelo
    @State private var email = ""
    @State private var senha = ""
    @State private var mensagem: (texto: String, tipo: Mensagem.Tipo)?
    @State private var invalido: String?
    @State private var entrando = false

    var body: some View {
        VStack(spacing: 0) {
            BotoesSociais(ocupado: entrando, aoFalhar: { texto in mensagem = texto.map { ($0, .erro) } }, rodar: rodar)
            DivisorOu().padding(.top, 14).padding(.bottom, 10)
            CampoDeEntrada(rotulo: "E-mail", exemplo: "voce@email.com", texto: $email, identificador: "email",
                           invalido: invalido == "email", tipo: .username, teclado: .emailAddress, maiusculas: .never,
                           foco: foco, chave: "email")
                .padding(.bottom, 13)
            CampoDeEntrada(rotulo: "Senha", exemplo: "Sua senha", texto: $senha, identificador: "senha", senha: true,
                           invalido: invalido == "senha", tipo: .password, foco: foco, chave: "senha")
                .padding(.bottom, 12)
            if let mensagem {
                Mensagem(tipo: mensagem.tipo, texto: mensagem.texto, identificador: "mensagemEntrada").padding(.bottom, 12)
            }
            Button { Task { await entrar() } } label: {
                HStack(spacing: 8) {
                    if entrando { ProgressView().controlSize(.small) }
                    Text(entrando ? "Entrando…" : "Entrar")
                }
            }
            .buttonStyle(BotaoPrincipal())
            .disabled(entrando)
            .accessibilityIdentifier("entrar")
            Button("Esqueci minha senha") { Task { await esqueci() } }
                .buttonStyle(LinkSublinhado())
                .disabled(entrando)
                .padding(.top, 6)
                .accessibilityIdentifier("esqueciSenha")
            LinkDaPolitica()
        }
        .onAppear {
            if let texto = modelo.mensagemEntrada { mensagem = (texto, texto == ModeloApp.sessaoExpirada ? .cadeado : .erro) }
        }
    }

    /// Um login por vez: os botões travam até o atual voltar.
    private func rodar(_ acao: @escaping @MainActor () async -> String?) async {
        entrando = true
        mensagem = nil
        invalido = nil
        if let erro = await acao() { mensagem = (erro, .erro) }
        entrando = false
    }

    private func entrar() async {
        if let erro = validarEntrada(email: email, senha: senha) {
            invalido = emailParece(aparadoJS(email)) ? "senha" : "email"
            foco.wrappedValue = invalido
            mensagem = (erro, .erro)
            return
        }
        await rodar { await modelo.entrar(email: email, senha: senha) }
    }

    private func esqueci() async {
        invalido = nil
        let texto = await modelo.redefinirSenha(email: email)
        let enviado = texto == ModeloApp.linkEnviado
        mensagem = (texto, enviado ? .ok : .erro)
        if !enviado && !emailParece(aparadoJS(email)) {
            invalido = "email"
            foco.wrappedValue = "email"
        }
    }
}

/// Criar conta: nome, sobrenome, e-mail, senha com o checklist, confirmação e "como conheceu o Custta".
struct FormCriarConta: View {
    var foco: FocusState<String?>.Binding
    @Environment(ModeloApp.self) private var modelo
    @State private var nome = ""
    @State private var sobrenome = ""
    @State private var email = ""
    @State private var senha = ""
    @State private var confirmacao = ""
    @State private var origem: String?
    @State private var detalhe = ""
    @State private var erro: (campo: String, texto: String)?
    @State private var criando = false

    var body: some View {
        VStack(spacing: 0) {
            BotoesSociais(ocupado: criando, aoFalhar: { texto in erro = texto.map { ("", $0) } }, rodar: rodar)
            DivisorOu().padding(.top, 14).padding(.bottom, 10)
            VStack(spacing: 13) {
                CampoDeEntrada(rotulo: "Nome", exemplo: "Seu nome", texto: $nome, identificador: "nome",
                               invalido: erro?.campo == "nome", tipo: .givenName, maiusculas: .words, foco: foco, chave: "nome")
                CampoDeEntrada(rotulo: "Sobrenome", opcional: true, exemplo: "Seu sobrenome", texto: $sobrenome, identificador: "sobrenome",
                               invalido: erro?.campo == "sobrenome", tipo: .familyName, maiusculas: .words, foco: foco, chave: "sobrenome")
                CampoDeEntrada(rotulo: "E-mail", exemplo: "voce@email.com", texto: $email, identificador: "emailCadastro",
                               invalido: erro?.campo == "email", tipo: .emailAddress, teclado: .emailAddress, maiusculas: .never,
                               foco: foco, chave: "email")
                VStack(alignment: .leading, spacing: 8) {
                    CampoDeEntrada(rotulo: "Senha", exemplo: "Crie uma senha", texto: $senha, identificador: "senhaCadastro", senha: true,
                                   invalido: erro?.campo == "senha", tipo: .newPassword, foco: foco, chave: "senha")
                    ChecklistSenha(senha: senha, email: email)
                }
                CampoDeEntrada(rotulo: "Confirmar senha", exemplo: "Repita a senha", texto: $confirmacao, identificador: "confirmacao",
                               senha: true, invalido: erro?.campo == "confirmacao", tipo: .newPassword, foco: foco, chave: "confirmacao")
                CampoOrigem(origem: $origem, detalhe: $detalhe, invalido: erro?.campo, foco: foco)
            }
            .padding(.bottom, 12)
            if let erro { Mensagem(tipo: .erro, texto: erro.texto, identificador: "mensagemCadastro").padding(.bottom, 12) }
            Button { Task { await criar() } } label: {
                HStack(spacing: 8) {
                    if criando { ProgressView().controlSize(.small) }
                    Text(criando ? "Criando conta…" : "Criar conta")
                }
            }
            .buttonStyle(BotaoPrincipal())
            .disabled(criando)
            .accessibilityIdentifier("criarConta")
            LinkDaPolitica()
        }
    }

    private func rodar(_ acao: @escaping @MainActor () async -> String?) async {
        criando = true
        erro = nil
        if let texto = await acao() { erro = ("", texto) }
        criando = false
    }

    private func criar() async {
        erro = nil
        switch validarCadastro(nome: nome, sobrenome: sobrenome, email: email, senha: senha, confirmacao: confirmacao,
                               origem: origem, origemDetalhe: detalhe) {
        case .falhou(let campo, let texto):
            erro = (campo, texto)
            foco.wrappedValue = campo
        case .ok(let perfil):
            await rodar { await modelo.criarConta(email: email, senha: senha, perfil: perfil) }
        }
    }
}

/// "Falta pouco": conta Google ou Apple sem perfil. A Apple manda o nome, então só pede a origem (a
/// revisão reprova pedir de novo); o Google confirma o nome.
struct FormFaltaPouco: View {
    let usuario: Usuario
    var foco: FocusState<String?>.Binding
    @Environment(ModeloApp.self) private var modelo
    @Environment(\.paleta) private var paleta
    @Environment(\.vidro) private var vidro
    @State private var nome = ""
    @State private var sobrenome = ""
    @State private var origem: String?
    @State private var detalhe = ""
    @State private var mensagem: String?
    @State private var invalido: String?
    @State private var salvando = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(usuario.contaApple ? "Só falta contar como você conheceu o Custta." : "Confirme seu nome e conte como conheceu o Custta.")
                .font(.subheadline)
                .foregroundStyle(paleta.cor(vidro.secundario))
                .padding(.bottom, 14)
                .accessibilityIdentifier("textoFaltaPouco")
            HStack(spacing: 10) {
                Group {
                    if usuario.contaApple { Image(systemName: "apple.logo").font(.body).foregroundStyle(paleta.cor(.texto)) }
                    else { Image(decorative: "LogoGoogle").resizable().frame(width: 18, height: 18) }
                }
                .frame(width: 32, height: 32)
                .background(paleta.cor(.campo), in: .circle)
                .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 0) {
                    Text(usuario.contaApple ? "Você entrou com a Apple." : "Você entrou com o Google")
                        .foregroundStyle(paleta.cor(vidro.secundario))
                    if !usuario.contaApple && !usuario.email.isEmpty {
                        Text(usuario.email).fontWeight(.semibold).foregroundStyle(paleta.cor(.texto))
                    }
                }
                .font(.footnote)
            }
            .padding(.bottom, 14)
            .accessibilityElement(children: .combine)
            VStack(spacing: 13) {
                if !usuario.contaApple {
                    CampoDeEntrada(rotulo: "Nome", exemplo: "Seu nome", texto: $nome, identificador: "nome",
                                   invalido: invalido == "nome", tipo: .givenName, maiusculas: .words, foco: foco, chave: "nome")
                    CampoDeEntrada(rotulo: "Sobrenome", opcional: true, exemplo: "Seu sobrenome", texto: $sobrenome, identificador: "sobrenome",
                                   invalido: invalido == "sobrenome", tipo: .familyName, maiusculas: .words, foco: foco, chave: "sobrenome")
                }
                CampoOrigem(origem: $origem, detalhe: $detalhe, invalido: invalido, foco: foco)
            }
            .padding(.bottom, 12)
            if let mensagem { Mensagem(tipo: .erro, texto: mensagem, identificador: "mensagemFaltaPouco").padding(.bottom, 12) }
            Button { Task { await salvar() } } label: {
                HStack(spacing: 8) {
                    if salvando { ProgressView().controlSize(.small) }
                    Text(salvando ? "Salvando…" : "Começar a usar")
                }
            }
            .buttonStyle(BotaoPrincipal())
            .disabled(salvando)
            .accessibilityIdentifier("comecarAUsar")
            Button("Usar outra conta") {
                Task { mensagem = await modelo.sair() == nil ? nil : "Não foi possível trocar de conta agora. Tente de novo." }
            }
            .buttonStyle(LinkSublinhado())
            .padding(.top, 6)
            .accessibilityIdentifier("usarOutraConta")
            LinkDaPolitica()
        }
        .onAppear {
            let n = nomeDoGoogle(usuario.nomeExibicao)
            nome = n.nome
            sobrenome = n.sobrenome
        }
    }

    private func salvar() async {
        mensagem = nil
        invalido = nil
        let nomes = usuario.contaApple ? nomeDoGoogle(usuario.nomeExibicao) : (nome, sobrenome)
        let r = normalizaPerfil(nome: nomes.0, sobrenome: nomes.1, origem: origem, origemDetalhe: detalhe, nomeOpcional: usuario.contaApple)
        guard r.ok, let perfil = r.perfil else {
            mensagem = r.erro
            invalido = r.campo
            foco.wrappedValue = r.campo
            return
        }
        salvando = true
        mensagem = await modelo.completarPerfil(perfil)
        salvando = false
    }
}

/// O checklist de senha do site, com as cinco regras do cadastro.js; uma coluna na letra grande.
struct ChecklistSenha: View {
    let senha: String
    let email: String
    @Environment(\.paleta) private var paleta
    @Environment(\.vidro) private var vidro
    @Environment(\.dynamicTypeSize) private var tamanho

    var body: some View {
        let colunas = tamanho.isAccessibilitySize ? [GridItem(.flexible(), alignment: .leading)]
                                                  : [GridItem(.flexible(), alignment: .leading), GridItem(.flexible(), alignment: .leading)]
        LazyVGrid(columns: colunas, alignment: .leading, spacing: 4) {
            ForEach(validaSenha(senha, email: email).regras, id: \.id) { regra in
                Label {
                    Text(regra.texto).foregroundStyle(paleta.cor(regra.ok ? .texto : vidro.secundario))
                } icon: {
                    Image(systemName: regra.ok ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(paleta.cor(regra.ok ? .linkNoVidro : .textoTerciario))
                }
                .font(.footnote)
                .accessibilityLabel("\(regra.texto): \(regra.ok ? "ok" : "falta")")
            }
        }
        .padding(.horizontal, 2)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("checklistSenha")
    }
}

/// "Como conheceu o Custta?": abre o menu do sistema; indicação e outro pedem o detalhe (opcional).
struct CampoOrigem: View {
    @Binding var origem: String?
    @Binding var detalhe: String
    let invalido: String?
    var foco: FocusState<String?>.Binding
    @Environment(\.paleta) private var paleta
    @Environment(\.vidro) private var vidro

    var body: some View {
        let escolhida = origens.first { $0.id == origem }
        VStack(alignment: .leading, spacing: 13) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Como conheceu o Custta?")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(paleta.cor(vidro.secundario))
                    .accessibilityHidden(true)
                Menu {
                    Picker("Como conheceu o Custta?", selection: $origem) {
                        ForEach(origens, id: \.id) { o in Text(o.nome).tag(Optional(o.id)) }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text(escolhida?.nome ?? "Escolha uma opção")
                            .foregroundStyle(paleta.cor(escolhida == nil ? vidro.secundario : .texto))
                            .multilineTextAlignment(.leading)
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(paleta.cor(vidro.secundario))
                    }
                    .font(.body)
                    .padding(.horizontal, 13)
                    .padding(.vertical, 11)
                    .frame(minHeight: 48)
                    .background(paleta.cor(.campo), in: .rect(cornerRadius: 11))
                    .overlay(RoundedRectangle(cornerRadius: 11)
                        .strokeBorder(paleta.cor(invalido == "origem" ? .alerta : .campoBorda), lineWidth: 1))
                }
                .accessibilityLabel("Como conheceu o Custta?")
                .accessibilityValue(escolhida?.nome ?? "Escolha uma opção")
                .accessibilityIdentifier("origem")
            }
            if let rotulo = escolhida?.detalhe {
                CampoDeEntrada(rotulo: rotulo, exemplo: "", texto: $detalhe, identificador: "origemDetalhe",
                               invalido: invalido == "origemDetalhe", maiusculas: .words, foco: foco, chave: "origemDetalhe")
            }
        }
        .onChange(of: origem) { _, nova in
            if origens.first(where: { $0.id == nova })?.detalhe == nil { detalhe = "" }
        }
    }
}

/// "Política de Privacidade", o link neutro do fim do cartão.
struct LinkDaPolitica: View {
    var body: some View {
        Link("Política de Privacidade", destination: URL(string: "https://custta.com.br/privacidade.html")!)
            .buttonStyle(LinkSublinhado(neutro: true))
    }
}
```

`app-ios/Custta/Telas/PrincipalView.swift`:

```swift
import SwiftUI
import CusttaNucleo

/* O app por dentro: as abas da etapa 1 (Obras e Ajustes; "Vale a pena?" chega na etapa 4 e o + na 2)
   com a cápsula de abas própria, e a barra de cada tela com a sincronização e o sair do topo, em vidro,
   como no site. Sair pede confirmação pelo alerta do sistema (decisão do Giovani). Só a aba escolhida
   fica montada: o TabView do sistema pinta um fundo opaco por trás das abas no iOS 26 (esconderia a
   aurora), e uma aba só escondida continuaria na árvore do VoiceOver pela barra de navegação. O que
   precisar sobreviver à troca de aba (o caminho dentro de Obras, na etapa 2) mora aqui, no PrincipalView. */
struct PrincipalView: View {
    @State private var aba = Aba.obras

    var body: some View {
        Group {
            switch aba {
            case .obras: ObrasView()
            case .ajustes: AjustesView()
            }
        }
        // Barra própria com o efeito de borda do sistema: o que rola por baixo esmaece, como sob a barra de abas.
        .safeAreaBar(edge: .bottom, spacing: 0) { CapsulaDeAbas(escolhida: $aba) }
    }
}

/// Sincronização e sair, no canto da barra de Obras e de Ajustes.
struct BarraDoApp: ToolbarContent {
    @Binding var confirmarSaida: Bool

    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) { IndicadorDeSincronizacao() }
            .sharedBackgroundVisibility(.hidden)
        ToolbarItem(placement: .topBarTrailing) { BotaoSairDoTopo(confirmar: $confirmarSaida) }
            .sharedBackgroundVisibility(.hidden)
    }
}

/// O indicador de sincronização do site: some em dia; tocar no erro tenta de novo. Nos erros, o rótulo
/// fica na cor do texto e só o ponto em vermelho (no site o vermelho não fechava o contraste).
struct IndicadorDeSincronizacao: View {
    @Environment(ModeloApp.self) private var modelo
    @Environment(\.paleta) private var paleta

    var body: some View {
        if let i = indicador(modelo.sincronizador.estadoSinc) {
            Button {
                if i.erro { modelo.tentarDeNovo() }
            } label: {
                HStack(spacing: 7) {
                    if i.girando { ProgressView().controlSize(.mini) }
                    else { Circle().fill(paleta.cor(i.erro ? .erroNoVidro : .texto)).frame(width: 8, height: 8).opacity(i.erro ? 1 : 0.75) }
                    Text(i.rotulo).font(.footnote.weight(.semibold)).lineLimit(1)
                }
                .foregroundStyle(paleta.cor(.texto))
                .padding(.horizontal, 14)
                .frame(minHeight: 44)
                .superficie(.navegacao, em: .capsule)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(i.rotulo)
            .accessibilityHint(i.dica)
            .accessibilityIdentifier("indicadorSincronizacao")
        }
    }
}

/// O sair do topo, mantido como no site: círculo de vidro com o ícone de saída.
struct BotaoSairDoTopo: View {
    @Binding var confirmar: Bool
    @Environment(\.paleta) private var paleta
    @Environment(\.colorScheme) private var esquema

    var body: some View {
        Button { confirmar = true } label: {
            Image(decorative: "Icones/sair")
                .resizable()
                .frame(width: 22, height: 22)
                .foregroundStyle(paleta.cor(esquema == .dark ? .texto : .marca))
                .frame(width: 44, height: 44)
                .superficie(.navegacao, em: .circle)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Sair da conta")
        .accessibilityIdentifier("sairTopo")
    }
}

extension View {
    /// "Sair da conta?" pelo alerta do sistema; sem rede (ou se não der), explica num segundo alerta.
    func confirmaSaida(_ confirmar: Binding<Bool>) -> some View { modifier(ConfirmacaoDeSaida(confirmar: confirmar)) }
}

private struct ConfirmacaoDeSaida: ViewModifier {
    @Binding var confirmar: Bool
    @Environment(ModeloApp.self) private var modelo
    @State private var erro: String?

    func body(content: Content) -> some View {
        content
            .alert("Sair da conta?", isPresented: $confirmar) {
                Button("Cancelar", role: .cancel) {}
                Button("Sair", role: .destructive) {
                    Task { erro = await modelo.sair() }
                }
            }
            .alert(erro ?? "", isPresented: Binding(get: { erro != nil }, set: { if !$0 { erro = nil } })) {
                Button("OK", role: .cancel) {}
            }
    }
}
```

`app-ios/Custta/Telas/ObrasView.swift`:

```swift
import SwiftUI
import CusttaNucleo

/* Obras, só leitura na etapa 1: aviso de e-mail não confirmado, "N obras", um cartão de vidro por obra
   (fase, meses, orçamento e total gasto, na ordem e com os totais do site) e o comparativo entre obras.
   Antes de carregar: carregando, ou o erro de leitura explicando que nada foi alterado. */
struct ObrasView: View {
    @Environment(ModeloApp.self) private var modelo
    @State private var confirmarSaida = false

    var body: some View {
        let sinc = modelo.sincronizador
        let obras = obrasOrdenadas(sinc.estado.obras)
        let hoje = dataLocalISO(.now, fuso: .current)
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    if let usuario = modelo.usuario, usuario.precisaConfirmarEmail {
                        AvisoDeEmail(email: usuario.email).padding(.bottom, 4)
                    }
                    if !sinc.dadosCarregados, case .erro(let codigo, .leitura) = sinc.estadoSinc {
                        // Nada de carregando para sempre: diz o que houve e que nada foi alterado.
                        CartaoDeEstado(titulo: "Não deu para ler suas obras", texto: textoErroDeLeitura(codigo),
                                       identificador: "obrasErroLeitura") {
                            Button("Tentar de novo") { modelo.tentarDeNovo() }
                                .buttonStyle(BotaoSecundario())
                                .accessibilityIdentifier("tentarLerDeNovo")
                        }
                    } else if !sinc.dadosCarregados {
                        CartaoDeEstado(titulo: "Carregando suas obras…", texto: nil, identificador: "obrasCarregando") {
                            ProgressView()
                        }
                    } else if obras.isEmpty {
                        CartaoDeEstado(titulo: "Nenhuma obra ainda.",
                                       texto: "Nesta versão de teste, crie as obras pelo site. Elas aparecem aqui sozinhas.",
                                       identificador: "obrasVazio") { EmptyView() }
                    } else {
                        ContagemDeObras(quantidade: obras.count)
                        ForEach(obras, id: \.id) { obra in CartaoDeObra(obra: obra, hoje: hoje) }
                        let comparativo = comparativoEntreObras(obras, taxa: sinc.estado.config.taxaMensal, hoje: hoje)
                        if !comparativo.isEmpty { PainelComparativo(linhas: comparativo).padding(.top, 2) }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .pausaOFundoAoRolar()
            .containerBackground(.clear, for: .navigation)
            .navigationTitle("Obras")
            .toolbar { BarraDoApp(confirmarSaida: $confirmarSaida) }
            .confirmaSaida($confirmarSaida)
        }
    }
}

/// "3 obras": pílula de vidro no Transparente; texto no Fosco e com superfícies sólidas.
struct ContagemDeObras: View {
    let quantidade: Int
    @Environment(\.paleta) private var paleta
    @Environment(\.vidro) private var vidro

    var body: some View {
        let texto = Text(quantidade == 1 ? "1 obra" : "\(quantidade) obras")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(paleta.cor(.texto))
        if vidro.nivel == .transparente {
            texto.padding(.horizontal, 14).padding(.vertical, 6).superficie(.conteudo, em: .capsule)
        } else {
            texto.shadow(color: paleta.cor(.sombraDoTexto), radius: 4, y: 1).padding(.horizontal, 4)
        }
    }
}

/// Uma obra: ícone da fase, nome, etiqueta, meses, orçamento e total gasto. O valor de acessibilidade
/// ("Em construção · 14 meses, total gasto R$ …, 70% do orçamento") é contrato com a conferência cruzada.
struct CartaoDeObra: View {
    let obra: Obra
    let hoje: String
    @Environment(\.paleta) private var paleta
    @Environment(\.vidro) private var vidro
    @Environment(\.dynamicTypeSize) private var tamanho

    var body: some View {
        let total = totalBruto(obra)
        let orcamento = orcamentoObra(obra)
        let meses = fmtMeses(mesesDeObra(obra, hoje: hoje))
        let fase = "\(obra.fase.rotulo) · \(meses)"
        Group {
            if tamanho.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .top) {
                        nome
                        Spacer(minLength: 8)
                        chevron
                    }
                    EtiquetaDeFase(fase: obra.fase)
                    tempo(meses)
                    if let orcamento { linhaDoOrcamento(orcamento) }
                    Text(moedaCurta(total)).font(.title.weight(.bold)).foregroundStyle(paleta.cor(.texto))
                }
            } else {
                HStack(alignment: .center, spacing: 11) {
                    Image(decorative: icone)
                        .resizable().frame(width: 20, height: 20)
                        .foregroundStyle(paleta.cor(.marca))
                        .frame(width: 38, height: 38)
                        .background(paleta.cor(.fantasmaFundo), in: .rect(cornerRadius: 11))
                    VStack(alignment: .leading, spacing: 2) {
                        nome
                        ViewThatFits(in: .horizontal) {
                            HStack(spacing: 4) { EtiquetaDeFase(fase: obra.fase); tempo(meses) }
                            VStack(alignment: .leading, spacing: 2) { EtiquetaDeFase(fase: obra.fase); tempo(meses) }
                        }
                        if let orcamento { linhaDoOrcamento(orcamento).padding(.top, 4) }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Text(moedaCurta(total))
                        .font(.body.weight(.semibold))
                        .monospacedDigit()
                        .foregroundStyle(paleta.cor(.texto))
                    chevron
                }
            }
        }
        .padding(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 14))
        .frame(maxWidth: .infinity, alignment: .leading)
        .superficie(.conteudo, em: .rect(cornerRadius: 22))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(obra.nome)
        .accessibilityValue([fase, "total gasto \(moeda(total))", orcamento.map(textoOrcamentoNaLista)].compactMap { $0 }.joined(separator: ", "))
        .accessibilityIdentifier("obra-\(obra.id)")
    }

    private var nome: some View {
        Text(obra.nome).font(.body.weight(.semibold)).foregroundStyle(paleta.cor(.texto))
    }

    private var chevron: some View {
        Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(paleta.cor(vidro.secundario))
    }

    private func tempo(_ meses: String) -> some View {
        Text("· \(meses)").font(.footnote).foregroundStyle(paleta.cor(vidro.secundario))
    }

    private func linhaDoOrcamento(_ r: ResumoOrcamento) -> some View {
        HStack(spacing: 8) {
            BarraDeProgresso(fracao: r.geral.pct / 100, atencao: r.geral.nivel != .ok).frame(width: 56)
            Text(textoOrcamentoNaLista(r))
                .font(.footnote)
                .foregroundStyle(paleta.cor(r.geral.nivel == .passou ? .alerta : vidro.secundario))
        }
    }

    private var icone: String {
        switch obra.fase {
        case .construcao: return "Icones/guindaste"
        case .pronta: return "Icones/casa"
        case .vendida: return "Icones/check"
        }
    }
}

/// "Comparativo entre obras": gasto e corrigido pela taxa, em barras do maior corrigido.
struct PainelComparativo: View {
    let linhas: [LinhaComparativo]
    @Environment(\.paleta) private var paleta
    @Environment(\.vidro) private var vidro

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Comparativo entre obras")
                .font(.title3.weight(.semibold))
                .foregroundStyle(paleta.cor(.texto))
                .accessibilityAddTraits(.isHeader)
            ForEach(linhas) { linha in
                VStack(alignment: .leading, spacing: 6) {
                    Text(linha.nome).font(.subheadline.weight(.semibold)).foregroundStyle(paleta.cor(.texto))
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(paleta.cor(.texto).opacity(0.10))
                            Capsule().fill(paleta.cor(.marca).opacity(0.34)).frame(width: geo.size.width * linha.fracaoCorrigido)
                            Capsule().fill(paleta.cor(.marca)).frame(width: geo.size.width * linha.fracaoBruto)
                        }
                    }
                    .frame(height: 14)
                    Text("\(moedaCurta(linha.bruto)) gasto · \(moedaCurta(linha.corrigido)) corrigido")
                        .font(.footnote)
                        .foregroundStyle(paleta.cor(vidro.secundario))
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(linha.nome)
                .accessibilityValue("\(moedaCurta(linha.bruto)) gasto, \(moedaCurta(linha.corrigido)) corrigido")
            }
            HStack(spacing: 18) {
                Label { Text("Gasto") } icon: { RoundedRectangle(cornerRadius: 3).fill(paleta.cor(.marca)).frame(width: 10, height: 10) }
                Label { Text("Corrigido") } icon: { RoundedRectangle(cornerRadius: 3).fill(paleta.cor(.marca).opacity(0.34)).frame(width: 10, height: 10) }
            }
            .font(.footnote)
            .foregroundStyle(paleta.cor(vidro.secundario))
            .frame(maxWidth: .infinity)
            .accessibilityHidden(true)
        }
        .padding(EdgeInsets(top: 18, leading: 16, bottom: 16, trailing: 16))
        .frame(maxWidth: .infinity, alignment: .leading)
        .superficie(.conteudo, em: .rect(cornerRadius: 24))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("comparativo")
    }
}

/// Aviso de e-mail não confirmado: o uso não é bloqueado.
struct AvisoDeEmail: View {
    let email: String
    @Environment(ModeloApp.self) private var modelo
    @Environment(\.paleta) private var paleta
    @Environment(\.vidro) private var vidro
    @State private var mensagem: (texto: String, tipo: Mensagem.Tipo)?
    @State private var ocupado = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Confirme seu e-mail").font(.body.weight(.semibold)).foregroundStyle(paleta.cor(.texto))
            Text("Enviamos um link para \(email). Abra o e-mail e toque no link para proteger sua conta.")
                .font(.footnote)
                .foregroundStyle(paleta.cor(vidro.secundario))
                .padding(.top, 6)
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) { reenviar; jaConfirmei }
                VStack(spacing: 10) { reenviar; jaConfirmei }
            }
            .padding(.top, 12)
            if let mensagem {
                Mensagem(tipo: mensagem.tipo, texto: mensagem.texto, identificador: "mensagemAvisoEmail").padding(.top, 12)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .superficie(.conteudo, em: .rect(cornerRadius: 22))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("avisoEmail")
    }

    private var reenviar: some View {
        Button("Reenviar link") {
            Task {
                ocupado = true
                let texto = await modelo.reenviarVerificacao()
                mensagem = (texto, texto == ModeloApp.linkReenviado || texto == ModeloApp.emailJaConfirmado ? .ok : .atencao)
                ocupado = false
            }
        }
        .buttonStyle(BotaoSecundario())
        .disabled(ocupado)
        .accessibilityIdentifier("reenviarLink")
    }

    private var jaConfirmei: some View {
        Button("Já confirmei") {
            Task {
                ocupado = true
                mensagem = await modelo.conferirVerificacao().map { ($0, .atencao) }
                ocupado = false
            }
        }
        .buttonStyle(BotaoPrincipal())
        .disabled(ocupado)
        .accessibilityIdentifier("jaConfirmei")
    }
}

/// Cartão de estado da lista (vazia, carregando, erro de leitura): ícone, título, texto e ação.
struct CartaoDeEstado<Acao: View>: View {
    let titulo: String
    let texto: String?
    let identificador: String
    @ViewBuilder let acao: () -> Acao
    @Environment(\.paleta) private var paleta
    @Environment(\.vidro) private var vidro

    var body: some View {
        VStack(spacing: 8) {
            Image(decorative: "Icones/guindaste")
                .resizable().frame(width: 36, height: 36)
                .foregroundStyle(paleta.cor(.texto))
                .accessibilityHidden(true)
            Text(titulo)
                .font(.body.weight(.semibold))
                .foregroundStyle(paleta.cor(.texto))
                .accessibilityIdentifier(identificador)
            if let texto {
                Text(texto).font(.subheadline).foregroundStyle(paleta.cor(vidro.secundario))
            }
            acao().padding(.top, 4)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 20)
        .padding(.vertical, 28)
        .frame(maxWidth: .infinity)
        .superficie(.conteudo, em: .rect(cornerRadius: 22))
    }
}
```

`app-ios/Custta/Telas/AjustesView.swift`:

```swift
import SwiftUI

/* Ajustes da etapa 1: só a conta (nome, e-mail, confirmação pendente e sair) e a versão. Aparência,
   notificações, exportar, trocar senha e apagar conta chegam na etapa 5. */
struct AjustesView: View {
    @Environment(ModeloApp.self) private var modelo
    @Environment(\.paleta) private var paleta
    @Environment(\.vidro) private var vidro
    @State private var confirmarSaida = false
    @State private var mensagemVerificacao: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Conta")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(paleta.cor(.texto))
                            .accessibilityAddTraits(.isHeader)
                            .padding(.bottom, 10)
                        if let nome = modelo.nome {
                            Text(nome)
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(paleta.cor(.texto))
                                .accessibilityIdentifier("nomeConta")
                        }
                        Text(modelo.usuario?.email ?? "")
                            .font(.subheadline)
                            .foregroundStyle(paleta.cor(vidro.secundario))
                            .padding(.bottom, 14)
                            .accessibilityLabel("E-mail")
                            .accessibilityValue(modelo.usuario?.email ?? "")
                            .accessibilityIdentifier("emailConta")
                        if modelo.usuario?.precisaConfirmarEmail == true {
                            Text("Confirme seu e-mail para manter acesso à conta. Você pode continuar usando o app.")
                                .font(.footnote)
                                .foregroundStyle(paleta.cor(vidro.secundario))
                                .padding(.bottom, 10)
                            Button("Enviar confirmação de e-mail") {
                                Task { mensagemVerificacao = await modelo.reenviarVerificacao() }
                            }
                            .buttonStyle(BotaoSecundario())
                            if let mensagemVerificacao {
                                Mensagem(tipo: .ok, texto: mensagemVerificacao).padding(.top, 10)
                            }
                            Spacer().frame(height: 10)
                        }
                        Button { confirmarSaida = true } label: {
                            Label { Text("Sair da conta") } icon: { Image(decorative: "Icones/sair").resizable().frame(width: 18, height: 18) }
                        }
                        .buttonStyle(BotaoSecundario())
                        .accessibilityIdentifier("sair")
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .superficie(.conteudo, em: .rect(cornerRadius: 24))
                    Text(Self.versao)
                        .font(.footnote)
                        .foregroundStyle(paleta.cor(.texto))
                        .shadow(color: paleta.cor(.sombraDoTexto), radius: 4, y: 1)
                        .accessibilityIdentifier("versao")
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .pausaOFundoAoRolar()
            .containerBackground(.clear, for: .navigation)
            .navigationTitle("Ajustes")
            .toolbar { BarraDoApp(confirmarSaida: $confirmarSaida) }
            .confirmaSaida($confirmarSaida)
        }
    }

    /// "Versão 2.0 (1)": a versão e o build do pacote.
    static var versao: String {
        let info = Bundle.main.infoDictionary
        return "Versão \(info?["CFBundleShortVersionString"] as? String ?? "?") (\(info?["CFBundleVersion"] as? String ?? "?"))"
    }
}
```

- [ ] **Step 6: Rodar e ver passar**

Run: `xcodebuild test -project app-ios/Custta.xcodeproj -scheme Custta -destination "$(node scripts/simulador-ios.mjs)" -skipMacroValidation -skipPackagePluginValidation -onlyUsePackageVersionsFromResolvedFile CODE_SIGNING_ALLOWED=NO`
Expected: `** TEST SUCCEEDED **`, com os 19 testes de tela desta tarefa e os de unidade verdes.

Run: `node --test tests/app-ios.test.cjs`
Expected: verde, inclusive "cores só por tokens" com as telas novas e "fonte do botão do Google".

Conferência visual (Verniz, no simulador, lado a lado com os prints `final-*.png`): abra o app sem variável nenhuma (conta deslogada; qualquer e-mail com a senha `Casa2026x` entra e mostra a vitrine) e com `SIMCTL_CHILD_CUSTTA_CONTA=senha`, `senha-nao-confirmada`, `apple-sem-perfil` e `google-sem-perfil`; nos quatro combos (`-custta.tema claro`, `-custta.pele azul`), no maior tamanho de letra (`-UIPreferredContentSizeCategoryName UICTContentSizeCategoryAccessibilityXXXL`), com `-custta.reduzirTransparencia YES` e `-custta.aumentarContraste YES`, e com o VoiceOver lendo a lista de obras. Diferença que não se resolve pelo token vai para o Orquestrador, não para o código à mão.

**Ponto de controle (Orquestrador):** prints das telas ao Giovani, lado a lado com o mockup, nos quatro combos.

- [ ] **Step 7: Commit**

```bash
git add app-ios/Custta app-ios/CusttaUITests tests/app-ios.test.cjs
git commit -m "feat: telas da etapa 1 do app nativo com a cara do mockup" -m "Entrar com o título escrito à mão e o halo sobre a aurora, o segmentado de vidro e o cartão Fosco (Apple acima do Google, campos sólidos, esqueci a senha com o e-mail do cartão, como no site), criar conta com o checklist e a origem no menu do sistema, falta pouco que não pede de novo o nome que a Apple mandou, obras no vidro Transparente com a sincronização e o sair na barra, o aviso de e-mail, um cartão por obra com os totais do núcleo e o comparativo entre obras, e Ajustes com a conta, a versão e a saída pelo alerta do sistema. A cápsula de abas é própria e a aurora assenta ao entrar. O botão do Google segue as regras do Google, com a Roboto Medium travada. Os testes de tela abrem o app com os serviços falsos: entrar, criar conta, falta pouco, sem internet, erro de leitura, comparativo, abas e sair."
```

---

### Task 11: Acessibilidade verificada

**Files:**
- Test: `app-ios/CusttaUITests/AuditoriaUITests.swift`

**Interfaces:**
- Consumes: `abrirApp(conta:dados:rede:leitura:argumentos:)`, `XCUIApplication.elemento(_:)` e `abrirAba(_:)` (Tarefa 10); identificadores `email`, `irParaCriarConta`, `nome`, `avisoEmail`, `sair`, `aba-obras`, `aba-ajustes`, `entrarComGoogle`; argumentos `-custta.tema`, `-custta.pele`, `-custta.reduzirMovimento`, `-custta.reduzirTransparencia`, `-custta.aumentarContraste` e `-custta.quadroDaAurora` lidos pela `RaizView` (Tarefa 10); obra o4 dos `DadosDeExemplo` (Tarefa 9).
- Produces: nada novo; fixa os requisitos da seção 8 do spec como teste para as próximas etapas.

As auditorias do esqueleto antigo continuam (maior tamanho de letra em entrar, criar conta, obras e Ajustes; contraste nos quatro combos), com o que a cara do PWA trouxe: o fundo parado durante a auditoria (Reduzir movimento: aurora no quadro inicial, globo parado, logo pronto); a aurora congelada nos extremos da deriva para medir o título e a dica; a cápsula de abas e o botão do Google fora da auditoria de tipo dinâmico (não crescem por decisão do mockup e têm o Visualizador de Conteúdo Grande); e o contraste medido com superfícies sólidas, porque a auditoria do Xcode não lê fundo de vidro. Isso foi medido no simulador do iOS 27: a auditoria reprova sobre o vidro o mesmo punhado de textos com a tinta do mockup (6%) e com 50%, no claro e no escuro, e até texto escuro sobre a pílula sólida do segmentado, enquanto com superfícies sólidas eles passam. A leitura sobre o vidro roda mesmo assim, como falha esperada que não reprova o teste, e a medida que vale é a do aparelho (checklist da Tarefa 17).

- [ ] **Step 1: Escrever as auditorias**

`app-ios/CusttaUITests/AuditoriaUITests.swift`:

```swift
import XCTest

/* Requisitos verificáveis do spec, seção 8, com a cara do PWA: no maior tamanho de letra de
   acessibilidade nada corta, todo controle tem rótulo e alvo de 44 pt; o contraste das cores passa nos
   quatro combos e sobre a aurora parada (no quadro inicial e nos extremos da deriva). Não crescem com a
   letra, por decisão do mockup, a cápsula de abas e o botão do Google: os dois mostram o Visualizador de
   Conteúdo Grande, e a auditoria de tipo dinâmico os deixa de fora.

   Contraste: a auditoria do Xcode não lê fundo de vidro (no simulador do iOS 27 ela reprova até texto
   escuro sobre a pílula sólida do segmentado, e os mesmos textos com tinta de 6% ou de 50%). As cores são
   conferidas com "Reduzir transparência" (superfícies sólidas, sem o vidro na frente da aurora); a
   leitura sobre o vidro roda também, como falha esperada, e a medida que vale é a do aparelho (checklist
   da Tarefa 18). */
final class AuditoriaUITests: XCTestCase {
    private let maiorLetra = ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
    private let tiposDeAuditoria: XCUIAccessibilityAuditType = [.dynamicType, .textClipped, .sufficientElementDescription, .hitRegion]
    /// Fundo parado: aurora no quadro inicial, globo no ângulo de partida, logo pronto.
    private let parado = ["-custta.reduzirMovimento", "YES"]
    private let solido = ["-custta.reduzirTransparencia", "YES"]
    private let quatroCombos = [("escuro", "esmeralda"), ("claro", "esmeralda"), ("escuro", "azul"), ("claro", "azul")]

    /// Deixa fora o que não cresce de propósito (dinâmico: a cápsula de abas e o texto do botão do Google,
    /// pelo rótulo, porque a auditoria rola a tela sozinha) e o conteúdo que passa por baixo da barra de
    /// navegação, da cápsula ou do indicador de início (contraste: ele é auditado quando está à vista).
    @MainActor private func auditar(_ app: XCUIApplication, _ tipos: XCUIAccessibilityAuditType) throws {
        let abas = ["aba-obras", "aba-ajustes"].map { app.buttons[$0] }.filter(\.exists).map(\.frame)
        let fundoDaTela = abas.map(\.minY).min() ?? app.frame.maxY
        let barra = app.navigationBars.firstMatch
        let topoDoConteudo = barra.exists ? barra.frame.maxY : 0
        let daBarra = barra.exists ? barra.descendants(matching: .any).allElementsBoundByIndex.map(\.frame) : []
        try app.performAccessibilityAudit(for: tipos) { achado in
            guard let elemento = achado.element else { return false }
            switch achado.auditType {
            case .dynamicType:
                return elemento.label == "Continuar com o Google"
                    || abas.contains { $0.contains(CGPoint(x: elemento.frame.midX, y: elemento.frame.midY)) }
            case .contrast:
                let sobABarra = elemento.frame.minY < topoDoConteudo && !daBarra.contains(elemento.frame)
                return sobABarra || elemento.frame.maxY > fundoDaTela
            default:
                return false
            }
        }
    }

    /// Rola e espera a rolagem parar antes de auditar.
    @MainActor private func rolar(_ app: XCUIApplication) {
        app.swipeUp()
        app.swipeUp()
        Thread.sleep(forTimeInterval: 1.5)
    }

    @MainActor func testEntrarNoMaiorTamanho() throws {
        let app = abrirApp(argumentos: maiorLetra + parado)
        XCTAssertTrue(app.textFields["email"].waitForExistence(timeout: 10))
        try auditar(app, tiposDeAuditoria)
        rolar(app)
        try auditar(app, tiposDeAuditoria)
    }

    @MainActor func testCriarContaNoMaiorTamanho() throws {
        let app = abrirApp(argumentos: maiorLetra + parado)
        let segmento = app.buttons["irParaCriarConta"]
        for _ in 0..<6 where !(segmento.exists && segmento.isHittable) { app.swipeUp() }
        segmento.tap()
        XCTAssertTrue(app.textFields["nome"].waitForExistence(timeout: 10))
        try auditar(app, tiposDeAuditoria)
        rolar(app)
        try auditar(app, tiposDeAuditoria)
    }

    @MainActor func testObrasNoMaiorTamanho() throws {
        let app = abrirApp(conta: "senha-nao-confirmada", argumentos: maiorLetra + parado)
        XCTAssertTrue(app.elemento("avisoEmail").waitForExistence(timeout: 10))
        try auditar(app, tiposDeAuditoria)
        rolar(app)
        try auditar(app, tiposDeAuditoria)
    }

    @MainActor func testAjustesNoMaiorTamanho() throws {
        let app = abrirApp(conta: "senha-nao-confirmada", argumentos: maiorLetra + parado)
        app.abrirAba("ajustes")
        XCTAssertTrue(app.buttons["sair"].waitForExistence(timeout: 5))
        try auditar(app, tiposDeAuditoria)
    }

    /// Obras (com o aviso de e-mail, antes e depois de rolar) e entrar.
    @MainActor private func contraste(_ argumentos: [String]) throws {
        let app = abrirApp(conta: "senha-nao-confirmada", argumentos: argumentos)
        XCTAssertTrue(app.elemento("avisoEmail").waitForExistence(timeout: 10))
        try auditar(app, [.contrast])
        rolar(app)
        try auditar(app, [.contrast])
        app.terminate()
        let entrar = abrirApp(argumentos: argumentos)
        XCTAssertTrue(entrar.textFields["email"].waitForExistence(timeout: 10))
        try auditar(entrar, [.contrast])
        entrar.terminate()
    }

    @MainActor func testContrasteNosQuatroCombos() throws {
        for (tema, pele) in quatroCombos {
            try contraste(["-custta.tema", tema, "-custta.pele", pele] + solido + parado)
        }
    }

    /// A deriva move os brilhos da aurora: o título e a dica da entrada são medidos também com a aurora
    /// congelada nos quadros de 13 s e 26 s (os extremos da deriva), no escuro, onde ela é mais clara.
    @MainActor func testContrasteDoTituloComAAuroraEmMovimento() throws {
        for pele in ["esmeralda", "azul"] {
            for quadro in ["13", "26"] {
                let app = abrirApp(argumentos: ["-custta.pele", pele, "-custta.quadroDaAurora", quadro] + solido + parado)
                XCTAssertTrue(app.textFields["email"].waitForExistence(timeout: 10))
                try auditar(app, [.contrast])
                app.terminate()
            }
        }
    }

    /// O vidro de verdade (o padrão e o "Aumentar contraste"): a auditoria roda e registra o que achou,
    /// como falha esperada (ver o comentário do topo).
    @MainActor func testContrasteSobreOVidro() throws {
        let opcoes = XCTExpectedFailure.Options()
        opcoes.isStrict = false
        XCTExpectFailure("A auditoria de contraste do Xcode não lê fundo de vidro; a medida sobre o vidro é a do aparelho.",
                         options: opcoes)
        for (tema, pele) in quatroCombos {
            try contraste(["-custta.tema", tema, "-custta.pele", pele] + parado)
        }
        try contraste(["-custta.aumentarContraste", "YES"] + parado)
    }
}
```

- [ ] **Step 2: Provar que a auditoria pega regressão**

Em `scripts/cores-app-ios.mjs`, troque temporariamente o `SobreMarca` da Esmeralda escura de `'#04100C'` para `'#EAFFF6'` (texto claro sobre a marca, como estava no protótipo antigo) e rode `node scripts/cores-app-ios.mjs`.

Run: `xcodebuild test -project app-ios/Custta.xcodeproj -scheme Custta -destination "$(node scripts/simulador-ios.mjs)" -skipMacroValidation -skipPackagePluginValidation -onlyUsePackageVersionsFromResolvedFile CODE_SIGNING_ALLOWED=NO -only-testing:CusttaUITests/AuditoriaUITests/testContrasteNosQuatroCombos`
Expected: FAIL com achados de contraste no escuro esmeralda (o texto claro sobre a marca fica em cerca de 2,6:1; na validação deste plano foram 2 achados). Desfaça a troca (`git checkout scripts/cores-app-ios.mjs app-ios/Custta/Assets.xcassets`).

- [ ] **Step 3: Rodar e ver passar**

Run: `xcodebuild test -project app-ios/Custta.xcodeproj -scheme Custta -destination "$(node scripts/simulador-ios.mjs)" -skipMacroValidation -skipPackagePluginValidation -onlyUsePackageVersionsFromResolvedFile CODE_SIGNING_ALLOWED=NO -only-testing:CusttaUITests/AuditoriaUITests`
Expected: os 7 testes verdes: entrar, criar conta, obras (com a obra o4, de nome longo e R$ 123,5 mi) e Ajustes no maior tamanho de letra; o contraste nos quatro combos; o título com a aurora nos extremos da deriva; e o contraste sobre o vidro (verde com as falhas esperadas registradas no relatório do teste).

Se uma auditoria estrita achar algo: contraste se resolve no valor do token (`scripts/cores-app-ios.mjs`), nunca com cor solta; texto cortado se resolve deixando o texto crescer (sem `lineLimit` fixo) ou mudando a disposição na letra grande, como a `CartaoDeObra` faz.

- [ ] **Step 4: Commit**

```bash
git add app-ios/CusttaUITests/AuditoriaUITests.swift
git commit -m "test: auditorias de acessibilidade do app nativo" -m "Os requisitos da seção 8 do spec viram teste com a cara do PWA: no maior tamanho de letra de acessibilidade nada corta e todo controle tem rótulo e alvo suficiente em entrar, criar conta, obras e Ajustes; o contraste das cores passa nos quatro combos e com a aurora congelada nos extremos da deriva. A cápsula de abas e o botão do Google, que não crescem por decisão do mockup, ficam fora da auditoria de tipo dinâmico. Como a auditoria do Xcode não lê fundo de vidro, o contraste é conferido com superfícies sólidas e a leitura sobre o vidro fica registrada como falha esperada até a medida no aparelho."
```

---

### Task 12: Camada Firebase do estado e testes contra os emuladores

**Files:**
- Create: `app-ios/Custta/Dados/BancoFirebase.swift`, `app-ios/Custta/Dados/TransporteFirebase.swift`
- Create: `app-ios/CusttaTests/Emulador.swift`, `app-ios/CusttaTests/TransporteFirebaseTests.swift`, `app-ios/CusttaTests/BancoFirebaseTests.swift`
- Modify: `package.json` (script `test:app-ios:emuladores`), `tests/app-ios.test.cjs` (teste no fim)

**Interfaces:**
- Consumes: `TransporteDados`, `Cancelavel`, `Relogio`, `Instantaneo`, `ValorJSON.paraFoundation`, `ValorJSON(foundation:)`, `codigoDeErroFirestore`, `agoraEmMilissegundos` (núcleo); `RelogioDoSistema` e, nos testes, `Bandeira` (Tarefa 9); `scripts/simulador-ios.mjs` (Tarefa 2).
- Produces: `@MainActor final class BancoFirebase { static let chaveLimpeza; init(app: FirebaseApp, emulador: (host: String, porta: Int)?, preferencias: UserDefaults = .standard); func quandoPronto(_ uso: @escaping @MainActor (Firestore) -> Void); func aguardarPronto() async; func firestore() -> Firestore; var limpezaPendente: Bool; func marcarLimpeza(); func desmarcarLimpeza(); func limparCache() async throws }`; `@MainActor final class TransporteFirebase: TransporteDados { init(banco:); nonisolated static func valor(_: [String: Any]) -> ValorJSON?; nonisolated static func codigo(_: Error) -> String }` (documento com tipo fora do JSON chega como `aoFalhar("formato-desconhecido")`); Nos testes: `let comEmuladores: Bool`, `struct NoEmulador` (suíte-mãe em série das suítes que dividem o `Emulador.banco`), `enum Emulador { static let projeto: String; static let app: FirebaseApp; static let banco: BancoFirebase; static func novaConta() async throws -> User }`.

É a antiga Tarefa 6 sem o `Sistema.swift` (relógio, rede e janela), que entrou na Tarefa 9 junto com o `Bandeira` dos testes (`Auxiliares.swift`).

- [ ] **Step 1: Escrever os testes que falham**

`app-ios/CusttaTests/Emulador.swift`:

```swift
import Foundation
import Testing
import FirebaseCore
import FirebaseAuth
@testable import Custta

/* Contra os emuladores do Firebase (npm run test:app-ios:emuladores). Fora deles, os testes que
   usam isto pulam. Projeto e portas do firebase.test.json; um FirebaseApp com nome próprio, para
   nunca encostar no de produção. */
let comEmuladores = ProcessInfo.processInfo.environment["CUSTTA_EMULADORES"] == "1"

/// Suíte-mãe das suítes que dividem o `Emulador.banco`: tudo em série, porque `sair()` encerra a
/// instância que a outra suíte estaria usando. Fora dos emuladores, todas pulam.
@MainActor
@Suite(.serialized, .enabled(if: comEmuladores))
struct NoEmulador {}

@MainActor
enum Emulador {
    /// Projeto dos emuladores, o mesmo do firebase.test.json e dos testes do site.
    static let projeto = "demo-custta-phase2"
    static let app: FirebaseApp = {
        if let app = FirebaseApp.app(name: "emulador") { return app }
        let caminho = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist")!
        let opcoes = FirebaseOptions(contentsOfFile: caminho)!
        opcoes.projectID = projeto
        FirebaseApp.configure(name: "emulador", options: opcoes)
        let app = FirebaseApp.app(name: "emulador")!
        Auth.auth(app: app).useEmulator(withHost: "127.0.0.1", port: 9099)
        return app
    }()
    static let banco = BancoFirebase(app: app, emulador: ("127.0.0.1", 8080))

    static func novaConta() async throws -> User {
        let email = "teste-\(UUID().uuidString.prefix(8).lowercased())@example.com"
        return try await Auth.auth(app: app).createUser(withEmail: email, password: "Casa2026x").user
    }
}
```

`app-ios/CusttaTests/TransporteFirebaseTests.swift`:

```swift
import Foundation
import Testing
import FirebaseFirestore
@testable import Custta
import CusttaNucleo

extension NoEmulador {
    @MainActor
    @Suite struct TransporteFirebaseTests {
        @Test func gravaELeODocumentoInteiroSemPerderCampoDoSite() async throws {
            let u = try await Emulador.novaConta()
            let transporte = TransporteFirebase(banco: Emulador.banco)
            let blob = ValorJSON.objeto([
                "obras": .lista([.objeto(["id": .texto("o1"), "nome": .texto("Casa"), "dataInicio": .texto("2026-01-01"), "campoDoSite": .texto("fica"),
                                          "gastos": .lista([.objeto(["id": .texto("g"), "valor": .numero(1500), "data": .texto("2026-01-02"), "nota": .numero(1500.5)])])])]),
                "config": .objeto(["taxaMensal": .numero(1), "topicosCustom": .lista([])]),
            ])
            let codigo: String? = await withCheckedContinuation { c in transporte.gravar(uid: u.uid, blob: blob) { c.resume(returning: $0) } }
            #expect(codigo == nil)

            var recebido: Instantaneo?
            let escuta = transporte.escutar(uid: u.uid, aoReceber: { if !$0.doCache { recebido = $0 } }, aoFalhar: { Issue.record("leitura falhou: \($0)") })
            for _ in 0..<100 where recebido == nil { try await Task.sleep(for: .milliseconds(50)) }
            escuta.cancelar()
            let dados = try #require(recebido?.dados)
            #expect(canonico(dados) == canonico(blob), "volta igual, sem _atualizado e com o campo que só o site conhece")

            let bruto = try await Emulador.banco.firestore().collection("dados").document(u.uid).getDocument(source: .server).data()
            #expect(bruto?["_atualizado"] is Timestamp, "_atualizado é a hora do servidor")
            let gasto = ((bruto?["obras"] as? [[String: Any]])?.first?["gastos"] as? [[String: Any]])?.first
            #expect((gasto?["valor"] as? NSNumber).map { CFNumberIsFloatType($0) } == false, "1500 vai como inteiro, como o JavaScript grava")
        }

        @Test func rulesRecusamChaveNovaNoBlob() async throws {
            let u = try await Emulador.novaConta()
            let transporte = TransporteFirebase(banco: Emulador.banco)
            let blob = ValorJSON.objeto(["obras": .lista([]), "config": .objeto(["taxaMensal": .numero(1), "topicosCustom": .lista([]), "nova": .numero(1)])])
            let codigo: String? = await withCheckedContinuation { c in transporte.gravar(uid: u.uid, blob: blob) { c.resume(returning: $0) } }
            #expect(codigo == "permission-denied")
            #expect(erroEhTerminal(codigo: codigo))
        }
    }
}

/* Conversão do documento, sem emulador (roda na CI). */
struct ConversaoDoDocumentoTests {
    @Test func atualizadoSaiETipoForaDoJSONRecusaOBlob() {
        let simples: [String: Any] = ["obras": [Any](), "_atualizado": Timestamp(date: Date())]
        #expect(TransporteFirebase.valor(simples) == .objeto(["obras": .lista([])]))
        let comData: [String: Any] = ["obras": [["id": "o1", "quando": Timestamp(date: Date())]]]
        #expect(TransporteFirebase.valor(comData) == nil,
                "Timestamp dentro do blob: recusa ler em vez de virar null e sumir na próxima gravação")
    }
}
```

`app-ios/CusttaTests/BancoFirebaseTests.swift` (sem emulador: apagar o cache é local, então roda na CI):

```swift
import Foundation
import Testing
import FirebaseCore
import FirebaseFirestore
@testable import Custta

/* A limpeza do cache interrompida (o app fechou no meio de um "sair") termina na abertura seguinte,
   antes de qualquer leitura. Sem rede e sem emulador: apagar o cache é local (roda na CI). */

@MainActor
struct BancoFirebaseTests {
    @Test func limpezaInterrompidaTerminaAntesDaPrimeiraLeitura() async throws {
        let nome = "limpeza-\(UUID().uuidString.prefix(8).lowercased())"
        let caminho = try #require(Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"))
        let opcoes = try #require(FirebaseOptions(contentsOfFile: caminho))
        opcoes.projectID = Emulador.projeto
        FirebaseApp.configure(name: nome, options: opcoes)
        let preferencias = try #require(UserDefaults(suiteName: nome))
        preferencias.set(true, forKey: BancoFirebase.chaveLimpeza)
        let banco = BancoFirebase(app: try #require(FirebaseApp.app(name: nome)), emulador: ("127.0.0.1", 8080), preferencias: preferencias)

        let usou = Bandeira()
        banco.quandoPronto { _ in usou.ligada = true }
        #expect(!usou.ligada, "ninguém lê antes de a limpeza terminar")
        await banco.aguardarPronto()
        #expect(usou.ligada)
        #expect(!banco.limpezaPendente, "a abertura terminou a limpeza e tirou a marca")
    }
}
```

No `package.json`, acrescente aos scripts:

```json
    "test:app-ios:emuladores": "firebase emulators:exec --config firebase.test.json --project demo-custta-phase2 --only firestore,auth \"node scripts/simulador-ios.mjs --testar CusttaTests --emuladores\"",
```

No fim de `tests/app-ios.test.cjs`:

```js
test('script dos testes do app contra os emuladores', () => {
  const s = JSON.parse(ler('package.json')).scripts;
  assert.match(s['test:app-ios:emuladores'] || '', /firebase emulators:exec --config firebase\.test\.json --project demo-custta-phase2 --only firestore,auth/);
  assert.match(s['test:app-ios:emuladores'], /scripts\/simulador-ios\.mjs --testar CusttaTests --emuladores/);
});
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `npm run test:app-ios:emuladores`
Expected: FAIL na compilação: `cannot find 'BancoFirebase' in scope`.

- [ ] **Step 3: Implementar**

`app-ios/Custta/Dados/BancoFirebase.swift`:

```swift
import Foundation
import os
import FirebaseCore
import FirebaseFirestore

/// Diagnóstico no registro do sistema (Console do Mac, sysdiagnose): a marca de limpeza que sobra fica anotada.
private let registro = Logger(subsystem: "br.com.custta.app", category: "banco")

/* Acesso ao Firestore do app. Sair da conta encerra a instância para limpar o cache, e o SDK
   devolve uma instância nova na próxima chamada; por isso ninguém guarda a instância: todo mundo
   pede aqui, e cada instância nova recebe as configurações antes do primeiro uso.

   A limpeza segue o cloud.js: a marca persistida (`chaveLimpeza`) é gravada antes do signOut e só
   sai quando o cache foi apagado. Se o app fechar no meio, a próxima abertura termina a limpeza
   antes de qualquer leitura. Durante uma limpeza, quem vai ler ou gravar espera na fila de
   `quandoPronto`, na ordem de chegada. */
@MainActor
final class BancoFirebase {
    static let chaveLimpeza = "custta-limpar-cache"

    private let app: FirebaseApp
    private let emulador: (host: String, porta: Int)?
    private let preferencias: UserDefaults
    private weak var configurada: Firestore?
    /// Limpeza em andamento (a retomada na abertura ou a de um "sair").
    private var ocupado = false
    private var esperando: [@MainActor (Firestore) -> Void] = []

    init(app: FirebaseApp, emulador: (host: String, porta: Int)? = nil, preferencias: UserDefaults = .standard) {
        self.app = app
        self.emulador = emulador
        self.preferencias = preferencias
        if preferencias.bool(forKey: Self.chaveLimpeza) {
            ocupado = true
            Task { [weak self] in await self?.terminarLimpezaInterrompida() }
        }
    }

    var limpezaPendente: Bool { preferencias.bool(forKey: Self.chaveLimpeza) }

    /// Roda `uso` com o Firestore pronto: na hora, se não há limpeza; senão, logo que ela termina,
    /// na ordem de chegada (gravações saem na mesma ordem em que o Sincronizador mandou).
    func quandoPronto(_ uso: @escaping @MainActor (Firestore) -> Void) {
        if ocupado { esperando.append(uso) } else { uso(firestore()) }
    }

    /// Espera uma limpeza em andamento terminar (para quem usa o Firestore com async/await).
    func aguardarPronto() async {
        guard ocupado else { return }
        await withCheckedContinuation { (c: CheckedContinuation<Void, Never>) in
            esperando.append { _ in c.resume() }
        }
    }

    /// A instância atual, configurada antes do primeiro uso. Instância já configurada nunca é
    /// reconfigurada: mudar `settings` de uma instância em uso (ou em encerramento) derruba o app.
    func firestore() -> Firestore {
        let db = Firestore.firestore(app: app)
        if configurada !== db {
            let ajustes = db.settings
            ajustes.cacheSettings = PersistentCacheSettings()
            ajustes.dispatchQueue = .main
            if let emulador {
                ajustes.host = "\(emulador.host):\(emulador.porta)"
                ajustes.isSSLEnabled = false
            }
            db.settings = ajustes
            configurada = db
        }
        return db
    }

    /// Antes do signOut: se o app fechar daqui até o fim da limpeza, a próxima abertura termina.
    func marcarLimpeza() { preferencias.set(true, forKey: Self.chaveLimpeza) }
    func desmarcarLimpeza() { preferencias.removeObject(forKey: Self.chaveLimpeza) }

    /// Encerra a instância e apaga o cache persistente (o IndexedDB do site); tira a marca no fim.
    /// Falhou no meio: a marca fica e a próxima abertura termina a limpeza.
    func limparCache() async throws {
        ocupado = true
        defer { liberar() }
        do {
            let db = firestore()
            try await db.terminate()
            try await db.clearPersistence()
            desmarcarLimpeza()
        } catch {
            registro.error("limpeza do cache falhou; a marca fica para a próxima abertura: \(String(describing: error), privacy: .public)")
            throw error
        }
    }

    private func terminarLimpezaInterrompida() async {
        registro.notice("limpeza do cache interrompida encontrada na abertura; terminando antes de ler")
        defer { liberar() }
        do {
            try await firestore().clearPersistence()      // instância nova, ainda sem uso
            desmarcarLimpeza()
        } catch {
            registro.error("limpeza retomada falhou; a marca fica para a próxima abertura: \(String(describing: error), privacy: .public)")
        }
    }

    private func liberar() {
        ocupado = false
        let fila = esperando
        esperando = []
        guard !fila.isEmpty else { return }
        let db = firestore()
        fila.forEach { $0(db) }
    }
}
```

`app-ios/Custta/Dados/TransporteFirebase.swift`:

```swift
import Foundation
import FirebaseFirestore
import CusttaNucleo

/* O TransporteDados do Sincronizador sobre o Firestore: fino de propósito. A regra mora no
   núcleo; aqui só a conversão de tipos e de códigos de erro. Os retornos chegam na fila
   principal (BancoFirebase põe dispatchQueue = .main), e leitura e gravação passam por
   `banco.quandoPronto`, que segura tudo enquanto o cache está sendo limpo. */
@MainActor
final class TransporteFirebase: TransporteDados {
    private let banco: BancoFirebase

    init(banco: BancoFirebase) { self.banco = banco }

    /// A escuta começa quando o banco está pronto; cancelada antes disso, nem começa.
    private final class Escuta: Cancelavel {
        var registro: ListenerRegistration?
        var cancelada = false
        func cancelar() {
            cancelada = true
            registro?.remove()
            registro = nil
        }
    }

    func escutar(uid: String, aoReceber: @escaping @MainActor (Instantaneo) -> Void,
                 aoFalhar: @escaping @MainActor (String) -> Void) -> any Cancelavel {
        let escuta = Escuta()
        banco.quandoPronto { db in
            guard !escuta.cancelada else { return }
            let documento = db.collection("dados").document(uid)
            escuta.registro = documento.addSnapshotListener(includeMetadataChanges: true) { snap, erro in
                MainActor.assumeIsolated {
                    if let erro { aoFalhar(Self.codigo(erro)); return }
                    guard let snap else { return }
                    let doCache = snap.metadata.isFromCache, pendente = snap.metadata.hasPendingWrites
                    guard let bruto = snap.data() else {
                        aoReceber(Instantaneo(dados: nil, doCache: doCache, gravacaoPendente: pendente))
                        return
                    }
                    guard let dados = Self.valor(bruto) else { aoFalhar("formato-desconhecido"); return }
                    aoReceber(Instantaneo(dados: dados, doCache: doCache, gravacaoPendente: pendente))
                }
            }
        }
        return escuta
    }

    func gravar(uid: String, blob: ValorJSON, concluir: @escaping @MainActor (String?) -> Void) {
        banco.quandoPronto { db in
            guard var dados = blob.paraFoundation as? [String: Any] else { concluir("invalid-argument"); return }
            dados["_atualizado"] = FieldValue.serverTimestamp()
            db.collection("dados").document(uid).setData(dados) { erro in
                MainActor.assumeIsolated { concluir(erro.map(Self.codigo)) }
            }
        }
    }

    func aguardarGravacoesPendentes(concluir: @escaping @MainActor (String?) -> Void) {
        banco.quandoPronto { db in
            db.waitForPendingWrites { erro in
                MainActor.assumeIsolated { concluir(erro.map(Self.codigo)) }
            }
        }
    }

    /// O documento como o site o lê: sem `_atualizado` (cloud.js apaga). nil se houver tipo que o
    /// JSON não tem (data, referência, bytes): a leitura falha com "formato-desconhecido" e nada é
    /// gravado por cima. Nenhum dos dois apps grava esses tipos em `dados/{uid}`.
    nonisolated static func valor(_ dados: [String: Any]) -> ValorJSON? {
        var dados = dados
        dados.removeValue(forKey: "_atualizado")
        return ValorJSON(foundation: dados)
    }

    nonisolated static func codigo(_ erro: Error) -> String {
        let n = erro as NSError
        return codigoDeErroFirestore(dominio: n.domain, codigo: n.code)
    }
}
```

- [ ] **Step 4: Rodar e ver passar**

Run: `npm run test:app-ios:emuladores && node --test tests/app-ios.test.cjs`
Expected: os 2 testes de `TransporteFirebaseTests` verdes (o log do Firestore mostra o `Permission denied` esperado do segundo), mais `ConversaoDoDocumentoTests` e `BancoFirebaseTests`, e as guardas verdes. Sem os emuladores (`xcodebuild test` comum, como na CI) os de `TransporteFirebaseTests` aparecem como pulados e os outros dois rodam.

- [ ] **Step 5: Commit**

```bash
git add app-ios/Custta/Dados app-ios/CusttaTests package.json tests/app-ios.test.cjs
git commit -m "feat: camada do Firestore do app nativo" -m "Transporte fino do Sincronizador sobre o Firestore: escuta com metadados de cache e gravação pendente, gravação do documento inteiro com _atualizado do servidor e espera da fila do SDK, retornos na fila principal. O teste contra o emulador prova que o documento volta igual, com o campo que só o site conhece, que 1500 vai como inteiro como no JavaScript e que as rules recusam chave nova. Documento com tipo que o JSON não tem falha a leitura em vez de virar null. A limpeza do cache segue o cloud.js: marca persistida, nada lê ou grava durante a limpeza e a próxima abertura termina uma limpeza interrompida; a marca que sobra fica anotada no registro do sistema."
```

---

### Task 13: Conta no Firebase

**Files:**
- Create: `app-ios/Custta/Dados/ContaFirebase.swift`
- Test: `app-ios/CusttaTests/ContaFirebaseTests.swift`, `app-ios/CusttaTests/ErrosDoSDKTests.swift`

**Interfaces:**
- Consumes: `BancoFirebase` (`aguardarPronto`, `firestore`, `marcarLimpeza`, `desmarcarLimpeza`, `limparCache`, `limpezaPendente`), `TransporteFirebase`, `Emulador`, `NoEmulador` (Tarefa 12); `ServicoConta`, `Usuario`, `CredencialApple`, `ErroConta`, `controladorNoTopo` (Tarefa 9); do núcleo `PerfilCadastro`, `ValorJSON`, `codigoDeErroDeConta`, `codigoDeErroFirestore`, `dominioAuth`, `dominioFirestore`, `dominioApple`, `dominioGoogle`, `sessaoInvalida`, `mensagemErroSenha`; dos SDKs `Auth`, `User`, `OAuthProvider`, `GoogleAuthProvider`, `AuthErrorCode`, `FirestoreErrorCode`, `GIDSignIn`, `GIDSignInError` e `ASAuthorizationError`.
- Produces: `@MainActor final class ContaFirebase: ServicoConta { init(app:banco:online:); nonisolated static func erro(_:) -> ErroConta }`.

É a antiga Tarefa 7 sem o que já entrou na Tarefa 9 (o protocolo `ServicoConta`, o `Usuario`, a `CredencialApple`, o `ErroConta`, a conta e o transporte falsos): a implementação de verdade do protocolo que as telas já usam. O código é o validado no plano anterior.

- [ ] **Step 1: Escrever os testes que falham**

`app-ios/CusttaTests/ContaFirebaseTests.swift`:

```swift
import Foundation
import Testing
import FirebaseAuth
import FirebaseFirestore
@testable import Custta
import CusttaNucleo

/* ContaFirebase contra os emuladores (npm run test:app-ios:emuladores). Fora deles, pulam. */
extension NoEmulador {
    @MainActor
    @Suite struct ContaFirebaseTests {
        func conta() -> ContaFirebase { ContaFirebase(app: Emulador.app, banco: Emulador.banco, online: { true }) }

        @Test func criarContaGravaPerfilAceitoPelasRules() async throws {
            let c = conta()
            let email = "cadastro-\(UUID().uuidString.prefix(8).lowercased())@example.com"
            try await c.criarConta(email: email, senha: "Casa2026x", perfil: PerfilCadastro(nome: "Ana", sobrenome: "Lima", origem: "indicacao", origemDetalhe: "Pedro"))
            let uid = try #require(Auth.auth(app: Emulador.app).currentUser?.uid)
            let dados = try #require(try await Emulador.banco.firestore().collection("perfis").document(uid).getDocument(source: .server).data())
            #expect(Set(dados.keys) == ["email", "criado", "tz", "nome", "sobrenome", "origem", "origemDetalhe"])
            #expect(dados["email"] as? String == email)
            #expect((dados["criado"] as? String)?.count == 24, "ISO com milissegundos, como o toISOString do site")
            #expect(await c.lerNome() == "Ana Lima")
            try await c.sair()
        }

        @Test func senhaErradaViraAMensagemDoSite() async throws {
            let c = conta()
            let u = try await Emulador.novaConta()
            try Auth.auth(app: Emulador.app).signOut()
            await #expect(throws: ErroConta.self) { try await c.entrar(email: u.email!, senha: "Errada123") }
            do { try await c.entrar(email: u.email!, senha: "Errada123") }
            catch let e as ErroConta { #expect(mensagemErroSenha(codigo: e.codigo, tela: "login") == "E-mail ou senha incorretos.") }
        }

        @Test func contaGoogleSemPerfilFicaPendenteAteCompletar() async throws {
            let c = conta()
            let sub = UUID().uuidString.lowercased()
            // O emulador do Auth aceita um token "falso" em JSON para os provedores federados.
            let tokenFalso = #"{"sub":"\#(sub)","email":"\#(sub.prefix(8))@example.com","email_verified":true}"#
            _ = try await Auth.auth(app: Emulador.app).signIn(with: GoogleAuthProvider.credential(withIDToken: tokenFalso, accessToken: "x"))
            for _ in 0..<100 where c.usuario?.contaSocial != true { try await Task.sleep(for: .milliseconds(20)) }
            #expect(await c.perfilPendente())
            try await c.completarPerfil(PerfilCadastro(nome: "Gi", origem: "google"))
            #expect(await c.perfilPendente() == false)
            try await c.sair()
        }

        private func gravar(_ t: TransporteFirebase, _ uid: String, _ blob: ValorJSON) async -> String? {
            await withCheckedContinuation { c in t.gravar(uid: uid, blob: blob) { c.resume(returning: $0) } }
        }

        @Test func sairLimpaOCacheEOutraContaUsaOMesmoBanco() async throws {
            let c = conta()
            let transporte = TransporteFirebase(banco: Emulador.banco)
            let config = ValorJSON.objeto(["taxaMensal": .numero(1), "topicosCustom": .lista([])])
            let u = try await Emulador.novaConta()
            #expect(await gravar(transporte, u.uid, .objeto(["obras": .lista([]), "config": config])) == nil)
            _ = try await Emulador.banco.firestore().collection("dados").document(u.uid).getDocument(source: .cache)
            try await c.sair()
            #expect(!Emulador.banco.limpezaPendente, "a marca sai quando o cache foi apagado")

            // Outra conta no mesmo BancoFirebase: instância nova depois do terminate, com settings e host do emulador.
            let outra = try await Emulador.novaConta()
            let blob = ValorJSON.objeto(["obras": .lista([.objeto(["id": .texto("o9"), "nome": .texto("Da outra conta"),
                                                                    "dataInicio": .texto("2026-01-01"), "gastos": .lista([])])]), "config": config])
            #expect(await gravar(transporte, outra.uid, blob) == nil)
            let lido = try await Emulador.banco.firestore().collection("dados").document(outra.uid).getDocument(source: .server).data()
            #expect(TransporteFirebase.valor(try #require(lido)).map(canonico) == canonico(blob), "a outra conta grava e lê do servidor pelo mesmo banco")
            // Com a instância viva (provado acima), a conta que saiu não está no cache: foi apagada, não só encerrada.
            await #expect(throws: (any Error).self, "o documento da conta que saiu não fica no aparelho") {
                _ = try await Emulador.banco.firestore().collection("dados").document(u.uid).getDocument(source: .cache)
            }
        }

        @Test func esqueciASenhaAceitaNoEmulador() async throws {
            let u = try await Emulador.novaConta()
            try await conta().redefinirSenha(email: u.email!)
            try Auth.auth(app: Emulador.app).signOut()
        }
    }
}
```

`app-ios/CusttaTests/ErrosDoSDKTests.swift` (sem emulador; confere as tabelas do núcleo contra as constantes dos SDKs travados):

```swift
import Testing
import AuthenticationServices
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn
@testable import Custta
import CusttaNucleo

/* As tabelas do núcleo (ErrosFirebase.swift) usam números para não depender dos SDKs. Aqui elas são
   conferidas contra as constantes dos próprios SDKs travados no projeto (roda na CI, sem rede). */
struct ErrosDoSDKTests {
    @Test func dominiosIguaisAosDosSDKs() {
        #expect(dominioAuth == AuthErrorDomain)
        #expect(dominioFirestore == FirestoreErrorDomain)
        #expect(dominioApple == ASAuthorizationError.errorDomain)
        #expect(dominioGoogle == kGIDSignInErrorDomain)
    }

    @Test func codigosDoAuthIguaisAosDoSDK() {
        let pares: [(AuthErrorCode, String)] = [
            (.invalidCredential, "auth/invalid-credential"), (.userDisabled, "auth/user-disabled"),
            (.operationNotAllowed, "auth/operation-not-allowed"), (.emailAlreadyInUse, "auth/email-already-in-use"),
            (.invalidEmail, "auth/invalid-email"), (.wrongPassword, "auth/wrong-password"),
            (.tooManyRequests, "auth/too-many-requests"), (.userNotFound, "auth/user-not-found"),
            (.accountExistsWithDifferentCredential, "auth/account-exists-with-different-credential"),
            (.requiresRecentLogin, "auth/requires-recent-login"), (.invalidUserToken, "auth/invalid-user-token"),
            (.networkError, "auth/network-request-failed"), (.userTokenExpired, "auth/user-token-expired"),
            (.weakPassword, "auth/weak-password"), (.missingEmail, "auth/missing-email"), (.quotaExceeded, "auth/quota-exceeded"),
        ]
        for (codigo, esperado) in pares {
            #expect(codigoDeErroDeConta(dominio: AuthErrorDomain, codigo: codigo.rawValue) == esperado, "\(codigo)")
        }
    }

    @Test func desistenciaNaAppleENoGoogleNaoViraMensagem() {
        #expect(codigoDeErroDeConta(dominio: ASAuthorizationError.errorDomain, codigo: ASAuthorizationError.Code.canceled.rawValue) == "auth/user-cancelled")
        #expect(codigoDeErroDeConta(dominio: ASAuthorizationError.errorDomain, codigo: ASAuthorizationError.Code.unknown.rawValue) == "1000")
        #expect(codigoDeErroDeConta(dominio: kGIDSignInErrorDomain, codigo: GIDSignInError.Code.canceled.rawValue) == "auth/user-cancelled")
    }

    @Test func codigosDoFirestoreIguaisAosDoSDK() {
        let pares: [(FirestoreErrorCode.Code, String)] = [
            (.cancelled, "cancelled"), (.invalidArgument, "invalid-argument"), (.notFound, "not-found"),
            (.permissionDenied, "permission-denied"), (.resourceExhausted, "resource-exhausted"),
            (.failedPrecondition, "failed-precondition"), (.unavailable, "unavailable"), (.unauthenticated, "unauthenticated"),
        ]
        for (codigo, esperado) in pares {
            #expect(codigoDeErroFirestore(dominio: FirestoreErrorDomain, codigo: codigo.rawValue) == esperado, "\(codigo)")
        }
    }
}
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `npm run test:app-ios:emuladores`
Expected: FAIL na compilação: `cannot find 'ContaFirebase' in scope`.

- [ ] **Step 3: Implementar**

`app-ios/Custta/Dados/ContaFirebase.swift`:

```swift
import Foundation
import UIKit
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn
import CusttaNucleo

/* Conta no Firebase Auth e perfil em `perfis/{uid}`, porte do cloud.js. Os campos e limites do
   perfil são os das firestore.rules (a validação mora no núcleo, cadastro.js portado). Leitura e
   gravação do perfil esperam o banco ficar pronto (limpeza de cache em andamento). */
@MainActor
final class ContaFirebase: ServicoConta {
    private let app: FirebaseApp
    private let banco: BancoFirebase
    private let online: @MainActor () -> Bool
    private var auth: Auth { Auth.auth(app: app) }
    private var alca: AuthStateDidChangeListenerHandle?
    private var ouvintes: [@MainActor (Usuario?) -> Void] = []
    private var ultimaVerificacao: Date?
    private var verificando = false
    /// O Firebase já disse quem está na conta (ou que ninguém está).
    private var estadoConhecido = false
    private(set) var usuario: Usuario?

    init(app: FirebaseApp, banco: BancoFirebase, online: @escaping @MainActor () -> Bool) {
        self.app = app
        self.banco = banco
        self.online = online
        auth.languageCode = "pt-BR"
        alca = auth.addStateDidChangeListener { [weak self] _, user in
            MainActor.assumeIsolated { self?.publicar(user) }
        }
    }

    /// Quem se inscreve depois da primeira leitura do Firebase recebe o estado atual logo em seguida.
    func observar(_ aoMudar: @escaping @MainActor (Usuario?) -> Void) {
        ouvintes.append(aoMudar)
        guard estadoConhecido else { return }
        let atual = usuario
        Task { @MainActor in aoMudar(atual) }
    }

    private func publicar(_ user: User?) {
        if user?.uid != usuario?.uid { ultimaVerificacao = nil }    // a espera de 60 s é por conta (cloud.js)
        estadoConhecido = true
        usuario = user.map(Self.usuario(de:))
        ouvintes.forEach { $0(usuario) }
    }

    static func usuario(de u: User) -> Usuario {
        Usuario(uid: u.uid, email: u.email ?? "", emailVerificado: u.isEmailVerified,
                provedores: u.providerData.map(\.providerID), nomeExibicao: u.displayName ?? "")
    }

    /// Código do site para qualquer erro dos SDKs (Auth, Firestore, Apple, Google, rede).
    nonisolated static func erro(_ e: Error) -> ErroConta {
        if let conta = e as? ErroConta { return conta }
        let n = e as NSError
        if n.domain == dominioFirestore { return ErroConta(codigo: codigoDeErroFirestore(dominio: n.domain, codigo: n.code)) }
        return ErroConta(codigo: codigoDeErroDeConta(dominio: n.domain, codigo: n.code))
    }

    private func exigirRede() throws -> User {
        guard online() else { throw ErroConta(codigo: "offline") }
        guard let u = auth.currentUser else { throw ErroConta(codigo: "cancelled") }
        return u
    }

    /* O User do SDK não é Sendable: os métodos assíncronos dele (reload, sendEmailVerification) o
       mandariam para fora da fila principal. A versão com completion fica aqui e só o resultado viaja. */
    private func esperar(_ chamada: (@escaping @Sendable (Error?) -> Void) -> Void) async throws {
        try await withCheckedThrowingContinuation { (c: CheckedContinuation<Void, Error>) in
            chamada { erro in
                if let erro { c.resume(throwing: erro) } else { c.resume() }
            }
        }
    }

    private static func agoraISO() -> String {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f.string(from: Date())
    }

    /// `{email, criado, tz, ...perfil}`, como o cloud.js grava.
    private func gravarPerfil(_ u: User, emailDigitado: String?, _ perfil: PerfilCadastro) async throws {
        var dados = perfil.campos.mapValues(\.paraFoundation)
        dados["email"] = u.email ?? emailDigitado ?? ""
        dados["criado"] = Self.agoraISO()
        dados["tz"] = TimeZone.current.identifier
        await banco.aguardarPronto()
        try await banco.firestore().collection("perfis").document(u.uid).setData(dados)
    }

    func entrar(email: String, senha: String) async throws {
        do { _ = try await auth.signIn(withEmail: email, password: senha) } catch { throw Self.erro(error) }
    }

    func entrarComApple(_ credencial: CredencialApple) async throws {
        do {
            let c = OAuthProvider.appleCredential(withIDToken: credencial.idToken, rawNonce: credencial.nonce,
                                                  fullName: credencial.nomeCompleto)
            let r = try await auth.signIn(with: c)
            /* A Apple só manda o nome no primeiro login: guardado no displayName, chega ao
               "Falta pouco" sem a tela pedir de novo. Melhor esforço, como no site. */
            let nome = [credencial.nomeCompleto?.givenName, credencial.nomeCompleto?.familyName]
                .compactMap { $0 }.joined(separator: " ").trimmingCharacters(in: .whitespaces)
            if (r.user.displayName ?? "").isEmpty && !nome.isEmpty {
                let pedido = r.user.createProfileChangeRequest()
                pedido.displayName = nome
                try? await pedido.commitChanges()
                publicar(auth.currentUser)
            }
        } catch { throw Self.erro(error) }
    }

    func entrarComGoogle() async throws {
        guard let tela = controladorNoTopo() else { throw ErroConta(codigo: "auth/erro-sem-tela") }
        do {
            let r = try await GIDSignIn.sharedInstance.signIn(withPresenting: tela)
            guard let idToken = r.user.idToken?.tokenString else { throw ErroConta(codigo: "auth/invalid-credential") }
            let c = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: r.user.accessToken.tokenString)
            _ = try await auth.signIn(with: c)
        } catch { throw Self.erro(error) }
    }

    func criarConta(email: String, senha: String, perfil: PerfilCadastro) async throws {
        do {
            let r = try await auth.createUser(withEmail: email, password: senha)
            try await gravarPerfil(r.user, emailDigitado: email, perfil)
            let novo = r.user
            try? await esperar { novo.sendEmailVerification(completion: $0) }
        } catch { throw Self.erro(error) }
    }

    func perfilPendente() async -> Bool {
        guard let u = auth.currentUser, usuario?.contaSocial == true else { return false }
        await banco.aguardarPronto()
        let ref = banco.firestore().collection("perfis").document(u.uid)
        if let doc = try? await ref.getDocument(source: .cache), doc.exists { return false }
        do { return !(try await ref.getDocument(source: .server)).exists } catch { return false }
    }

    func completarPerfil(_ perfil: PerfilCadastro) async throws {
        let u = try exigirRede()
        do { try await gravarPerfil(u, emailDigitado: nil, perfil) } catch { throw Self.erro(error) }
    }

    func lerNome() async -> String? {
        guard let u = auth.currentUser else { return nil }
        await banco.aguardarPronto()
        guard let dados = try? await banco.firestore().collection("perfis").document(u.uid).getDocument().data() else { return nil }
        let nome = [dados["nome"] as? String, dados["sobrenome"] as? String].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " ")
        return nome.isEmpty ? nil : nome
    }

    func redefinirSenha(email: String) async throws {
        do { try await auth.sendPasswordReset(withEmail: email) } catch { throw Self.erro(error) }
    }

    func reenviarVerificacao() async throws -> Bool {
        let u = try exigirRede()
        do {
            try await esperar { u.reload(completion: $0) }
            guard auth.currentUser?.uid == u.uid else { throw ErroConta(codigo: "cancelled") }   // trocou de conta no meio
            if u.isEmailVerified { publicar(auth.currentUser); return false }
            try await esperar { u.sendEmailVerification(completion: $0) }
            return true
        } catch { throw Self.erro(error) }
    }

    func conferirVerificacao() async -> Bool {
        guard let u = try? exigirRede() else { return false }
        do {
            try await esperar { u.reload(completion: $0) }
            guard auth.currentUser?.uid == u.uid, usuario != nil else { return false }            // trocou de conta no meio
            if u.isEmailVerified && usuario?.emailVerificado == false { publicar(auth.currentUser) }
            return u.isEmailVerified
        } catch { return false }
    }

    func verificarSessao(forcar: Bool) async {
        guard let u = auth.currentUser, online(), !verificando else { return }
        if !forcar, let ultima = ultimaVerificacao, Date().timeIntervalSince(ultima) < 60 { return }
        ultimaVerificacao = Date()
        verificando = true
        defer { verificando = false }
        do { _ = try await u.getIDTokenResult(forcingRefresh: true) }
        catch {
            if sessaoInvalida(Self.erro(error).codigo) && auth.currentUser?.uid == u.uid { try? auth.signOut() }
        }
    }

    /// Na ordem do cloud.js: marca a limpeza, sai, esquece o Google e apaga o cache. Se a limpeza
    /// falhar (ou o app fechar no meio), a marca fica e a próxima abertura termina antes de ler.
    func sair() async throws {
        banco.marcarLimpeza()
        do { try auth.signOut() } catch { banco.desmarcarLimpeza(); throw Self.erro(error) }
        GIDSignIn.sharedInstance.signOut()
        try? await banco.limparCache()
    }
}
```

- [ ] **Step 4: Rodar e ver passar**

Run: `npm run test:app-ios:emuladores`
Expected: `TransporteFirebaseTests` (2) e `ContaFirebaseTests` (5, inclusive sair, entrar com outra conta e gravar e ler do servidor pelo mesmo `BancoFirebase`) verdes, e `ErrosDoSDKTests` (4), que também roda sem emulador. Rode também `xcodebuild test -project app-ios/Custta.xcodeproj -scheme Custta -destination "$(node scripts/simulador-ios.mjs)" -skipMacroValidation -skipPackagePluginValidation -onlyUsePackageVersionsFromResolvedFile CODE_SIGNING_ALLOWED=NO -only-testing:CusttaTests`: compila e os de emulador aparecem pulados.

- [ ] **Step 5: Commit**

```bash
git add app-ios/Custta/Dados/ContaFirebase.swift app-ios/CusttaTests/ContaFirebaseTests.swift app-ios/CusttaTests/ErrosDoSDKTests.swift
git commit -m "feat: conta do app nativo no Firebase Auth" -m "E-mail e senha, Apple com nonce, Google com o client iOS, criar conta com o perfil que as rules aceitam, falta pouco para conta social sem perfil, esqueci a senha, confirmação de e-mail com a conta conferida depois do reload, verificação de sessão que nunca desloga por falta de rede (e recomeça a contar na troca de conta) e saída na ordem do cloud.js: marca a limpeza, sai, esquece o Google e apaga o cache. Erros chegam com os códigos do site; as tabelas do núcleo são conferidas contra as constantes dos SDKs. Contra o emulador, o cadastro grava o perfil aceito pelas rules e o login Google sem perfil fica pendente até completar."
```

---

### Task 14: Composição de produção e dos emuladores

**Files:**
- Modify: `app-ios/Custta/Composicao.swift` (produção e emuladores; os falsos continuam em Debug com `CUSTTA_SERVICOS=falsos`)
- Modify: `app-ios/Custta/Telas/RaizView.swift` (o retorno do login do Google)
- Modify: `app-ios/CusttaTests/Emulador.swift` (o projeto dos emuladores passa a vir do `Composicao`)
- Modify: `app-ios/Custta/CusttaApp.swift` (comentário: sem serviço só hospedando os testes)
- Test: `app-ios/CusttaTests/ComposicaoTests.swift`

**Interfaces:**
- Consumes: `BancoFirebase`, `TransporteFirebase`, `Emulador` (Tarefa 12); `ContaFirebase` (Tarefa 13); `ModeloApp`, `Composicao.montarFalso(_:)`, `RelogioDoSistema`, `MonitorDeRede` (Tarefa 9); `Sincronizador` (Tarefa 8).
- Produces: `@MainActor enum Composicao { static let projetoDosEmuladores: String; static func montar(ambiente:) -> ModeloApp; static func configurarFirebase(emuladores:) -> FirebaseApp; static func montarFalso(_:) -> ModeloApp /* Debug */ }`; em Debug, `CUSTTA_EMULADORES=1` e `CUSTTA_SAIR_AO_ABRIR=1` (Tarefa 15).

Fecha o que a antiga Tarefa 8 tinha com o Firebase: a composição monta o Firebase de produção pelo `GoogleService-Info.plist` e, só em Debug, os emuladores locais ou os serviços falsos. Muda o que o Debug abre sem variável nenhuma: até aqui eram os falsos; daqui em diante é o Firebase de verdade, e os falsos pedem `CUSTTA_SERVICOS=falsos` (os testes de tela já passam a variável). O `montar` deixa de devolver opcional e o Release ganha serviço: a abertura sem modelo fica só para quando o app hospeda os testes de unidade.

- [ ] **Step 1: Escrever o teste que falha**

`app-ios/CusttaTests/ComposicaoTests.swift`:

```swift
import Testing
@testable import Custta

/* A composição: com CUSTTA_SERVICOS=falsos (os testes de tela) nada encosta no Firebase. Sem a variável,
   o Debug monta o Firebase de produção (ou os emuladores, com CUSTTA_EMULADORES=1). */
@MainActor
struct ComposicaoTests {
    @Test func falsosSoComAVariavel() {
        let modelo = Composicao.montar(ambiente: ["CUSTTA_SERVICOS": "falsos", "CUSTTA_CONTA": "senha"])
        #expect(modelo.conta is ContaFalsa)
        #expect(Composicao.projetoDosEmuladores == "demo-custta-phase2", "o mesmo projeto do firebase.test.json")
    }
}
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `xcodebuild test -project app-ios/Custta.xcodeproj -scheme Custta -destination "$(node scripts/simulador-ios.mjs)" -skipMacroValidation -skipPackagePluginValidation -onlyUsePackageVersionsFromResolvedFile CODE_SIGNING_ALLOWED=NO -only-testing:CusttaTests/ComposicaoTests`
Expected: FAIL na compilação: `type 'Composicao' has no member 'projetoDosEmuladores'`.

- [ ] **Step 3: Implementar**

`app-ios/Custta/Composicao.swift` (troque o da Tarefa 9):

```swift
import Foundation
import FirebaseCore
import FirebaseAuth
import CusttaNucleo

/* Monta o app com os serviços de verdade (Firebase de produção) ou, só em Debug, com os
   emuladores locais (CUSTTA_EMULADORES=1) ou com serviços falsos (CUSTTA_SERVICOS=falsos)
   para os testes de tela. O build Release (TestFlight) não tem os dois atalhos. */
@MainActor
enum Composicao {
    /// Projeto dos emuladores, o mesmo do firebase.test.json e dos testes do site.
    static let projetoDosEmuladores = "demo-custta-phase2"

    static func montar(ambiente: [String: String] = ProcessInfo.processInfo.environment) -> ModeloApp {
        #if DEBUG
        if ambiente["CUSTTA_SERVICOS"] == "falsos" { return montarFalso(ambiente) }
        let emuladores = ambiente["CUSTTA_EMULADORES"] == "1"
        #else
        let emuladores = false
        #endif
        let app = configurarFirebase(emuladores: emuladores)
        let banco = BancoFirebase(app: app, emulador: emuladores ? ("127.0.0.1", 8080) : nil)
        if emuladores { Auth.auth(app: app).useEmulator(withHost: "127.0.0.1", port: 9099) }
        #if DEBUG
        // Teste de tela que precisa começar na tela de entrar (a conta fica no keychain do simulador).
        if ambiente["CUSTTA_SAIR_AO_ABRIR"] == "1" { try? Auth.auth(app: app).signOut() }
        #endif
        let rede = MonitorDeRede()
        let conta = ContaFirebase(app: app, banco: banco, online: { rede.online })
        let sincronizador = Sincronizador(transporte: TransporteFirebase(banco: banco), relogio: RelogioDoSistema(), online: rede.online)
        return ModeloApp(conta: conta, sincronizador: sincronizador, rede: rede)
    }

    /// Firebase de produção pelo GoogleService-Info.plist; nos emuladores, o mesmo arquivo com o projeto de teste.
    static func configurarFirebase(emuladores: Bool) -> FirebaseApp {
        if let app = FirebaseApp.app() { return app }
        guard emuladores else {
            FirebaseApp.configure()
            return FirebaseApp.app()!
        }
        let caminho = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist")!
        let opcoes = FirebaseOptions(contentsOfFile: caminho)!
        opcoes.projectID = projetoDosEmuladores
        FirebaseApp.configure(options: opcoes)
        return FirebaseApp.app()!
    }
}
```

Em `app-ios/Custta/Telas/RaizView.swift`, o login do Google volta ao app pelo esquema de URL: acrescente `import GoogleSignIn` depois de `import SwiftUI` e, logo depois da linha `.preferredColorScheme(Aparencia.esquema(tema))`, a linha:

```swift
        .onOpenURL { url in GIDSignIn.sharedInstance.handle(url) }
```

Em `app-ios/CusttaTests/Emulador.swift`, troque a linha `static let projeto = "demo-custta-phase2"` por `static let projeto = Composicao.projetoDosEmuladores` (um lugar só para o projeto dos emuladores).

Em `app-ios/Custta/CusttaApp.swift`, o `if let modelo` continua igual (o `Composicao.montar()` agora devolve sempre um modelo, e o `nil` fica só para quando o app hospeda os testes de unidade): troque o comentário `// Sem serviço (Release antes da camada Firebase, ou hospedando os testes de unidade).` por `// Sem serviço: o app só hospeda os testes de unidade.`

- [ ] **Step 4: Rodar e ver passar**

Run: `xcodebuild test -project app-ios/Custta.xcodeproj -scheme Custta -destination "$(node scripts/simulador-ios.mjs)" -skipMacroValidation -skipPackagePluginValidation -onlyUsePackageVersionsFromResolvedFile CODE_SIGNING_ALLOWED=NO`
Expected: `** TEST SUCCEEDED **`: `ComposicaoTests`, os de unidade das Tarefas 3 a 13 e os de tela (com os falsos) verdes; os de emulador pulados.

Run: `npm run test:app-ios:emuladores`
Expected: os mesmos, mais `TransporteFirebaseTests` (2) e `ContaFirebaseTests` (5), todos verdes.

Conferência manual: abra o app no simulador sem variável nenhuma e confira que a tela de entrar fala com o Firebase de produção (senha errada numa conta real responde "E-mail ou senha incorretos.").

- [ ] **Step 5: Commit**

```bash
git add app-ios/Custta/Composicao.swift app-ios/Custta/Telas/RaizView.swift app-ios/Custta/CusttaApp.swift app-ios/CusttaTests/Emulador.swift app-ios/CusttaTests/ComposicaoTests.swift
git commit -m "feat: app nativo ligado ao Firebase" -m "A composição monta o Firebase de produção pelo GoogleService-Info.plist e, só em Debug, os emuladores locais (CUSTTA_EMULADORES=1) ou os serviços falsos dos testes de tela (CUSTTA_SERVICOS=falsos); o Release deixa de abrir só a abertura. O login do Google volta ao app pelo esquema de URL, e o projeto dos emuladores fica num lugar só."
```

---

### Task 15: Conferência cruzada site ↔ app

**Files:**
- Create: `tests/app-ios/cruzado.mjs`
- Create: `app-ios/CusttaUITests/CruzadoUITests.swift`, `app-ios/CusttaTests/CruzadoTests.swift`
- Modify: `package.json` (script `test:app-ios:cruzado`), `tests/app-ios.test.cjs` (o teste de scripts da Tarefa 12 passa a cobrir os dois)

**Interfaces:**
- Consumes: `testarNoSimulador(alvos, env)` (Tarefa 2); `Sincronizador` (Tarefa 8); `RelogioDoSistema` (Tarefa 9); `TransporteFirebase`, `Emulador` (Tarefa 12); `Composicao` com `CUSTTA_EMULADORES` e `CUSTTA_SAIR_AO_ABRIR` (Tarefa 14); `Gasto` e `ValorJSON` (Parte A); identificadores `email`, `senha`, `entrar`, `obra-<id>` e o valor de acessibilidade da linha de obra ("total gasto R$ …" e a linha do orçamento) (Tarefa 10); no site, `C.money`, `C.moneyCurto`, `C.totalBruto`, `C.orcamentoObra`, `C.parcelamentoCartao`, `C.canon` (`calc.js`), `D.normaliza` (`dados.js`) e o SDK JavaScript `firebase` 12.18.0.
- Produces: `npm run test:app-ios:cruzado` (portão local antes de cada build do TestFlight, Tarefa 17).

O teste 5 da seção "Testes e validação" do spec: na mesma conta, contra os emuladores, o site grava e o app mostra os totais e os orçamentos que o `calc.js` calculou (obra com orçamento total, obra vendida com orçamento por tópico estourado e obra com compra parcelada no cartão com juros, cujo total é diferente do valor da compra); o site muda e o app vê sozinho; o app lança um gasto e o site soma esse gasto, sem perder nada que só o site conhece. O roteiro falha se qualquer um dos dois testes for pulado: exige o pedido de mudança que só o teste de tela faz e que o `_atualizado` avance depois do teste do app. O documento final é comparado sem normalizar, para a forma que o app gravou aparecer.

- [ ] **Step 1: Escrever as metades do app e a guarda**

`app-ios/CusttaUITests/CruzadoUITests.swift`:

```swift
import XCTest

/* Metade tela da conferência cruzada (tests/app-ios/cruzado.mjs): entra pelo formulário na
   conta que o "site" criou, confere o total e o orçamento que o site calculou e pede ao roteiro
   uma mudança feita como o site faz; ela tem de aparecer sozinha na lista. Os elementos são
   achados pelo identificador, de qualquer tipo: o visual pode mudar sem quebrar o teste. */
final class CruzadoUITests: XCTestCase {
    private let ambiente = ProcessInfo.processInfo.environment

    private struct Esperado: Decodable {
        let id: String
        let nome: String
        let total: String
        let orcamento: String?
    }

    override func setUpWithError() throws {
        try XCTSkipUnless(ambiente["CUSTTA_CRUZADO"] == "1", "só na conferência cruzada: npm run test:app-ios:cruzado")
        continueAfterFailure = false
    }

    @MainActor func testMudancaNoSiteChegaAoApp() async throws {
        let v1 = try JSONDecoder().decode([Esperado].self, from: Data(ambiente["CUSTTA_ESPERADO_V1"]!.utf8))
        let v2 = try JSONDecoder().decode([Esperado].self, from: Data(ambiente["CUSTTA_ESPERADO_V2"]!.utf8))
        let app = XCUIApplication()
        app.launchEnvironment = ["CUSTTA_EMULADORES": "1", "CUSTTA_SAIR_AO_ABRIR": "1"]
        app.launch()
        let elemento = { (id: String) in app.descendants(matching: .any).matching(identifier: id).firstMatch }

        let email = elemento("email")
        XCTAssertTrue(email.waitForExistence(timeout: 30))
        email.tap()
        email.typeText(ambiente["CUSTTA_EMAIL"]!)
        let senha = elemento("senha")
        senha.tap()
        senha.typeText(ambiente["CUSTTA_SENHA"]!)
        elemento("entrar").tap()

        for obra in v1 { await confere(app, obra) }

        var pedido = URLRequest(url: URL(string: "http://127.0.0.1:8124/site/mudar")!)
        pedido.httpMethod = "POST"
        let (_, resposta) = try await URLSession.shared.data(for: pedido)
        XCTAssertEqual((resposta as? HTTPURLResponse)?.statusCode, 200)

        for obra in v2 { await confere(app, obra) }
    }

    /// A linha da obra traz no valor de acessibilidade o total completo e a linha do orçamento.
    @MainActor private func confere(_ app: XCUIApplication, _ obra: Esperado) async {
        let linha = app.descendants(matching: .any).matching(identifier: "obra-\(obra.id)").firstMatch
        XCTAssertTrue(linha.waitForExistence(timeout: 30), "a obra \(obra.nome) não apareceu")
        for trecho in [obra.total] + (obra.orcamento.map { [$0] } ?? []) {
            let chegou = expectation(for: NSPredicate(format: "value CONTAINS %@", trecho), evaluatedWith: linha)
            await fulfillment(of: [chegou], timeout: 30)
        }
        XCTAssertEqual(linha.label, obra.nome)
    }
}
```

`app-ios/CusttaTests/CruzadoTests.swift`:

```swift
import Foundation
import Testing
import FirebaseAuth
@testable import Custta
import CusttaNucleo

/* Metade app da conferência cruzada (tests/app-ios/cruzado.mjs): entra na conta que o "site"
   criou, carrega o documento, lança um gasto (o que o roteiro mandou) e grava pelo Sincronizador,
   como uma edição da etapa 2 fará. O roteiro confere depois, com o SDK JavaScript, que o gasto
   chegou e que nada do site se perdeu. */
@MainActor
@Suite(.enabled(if: ProcessInfo.processInfo.environment["CUSTTA_CRUZADO"] == "1"))
struct CruzadoTests {
    @Test func appLancaGastoQueOSiteVe() async throws {
        let ambiente = ProcessInfo.processInfo.environment
        let u = try await Auth.auth(app: Emulador.app).signIn(withEmail: ambiente["CUSTTA_EMAIL"]!, password: ambiente["CUSTTA_SENHA"]!).user
        let s = Sincronizador(transporte: TransporteFirebase(banco: Emulador.banco), relogio: RelogioDoSistema())
        s.iniciar(uid: u.uid)
        for _ in 0..<200 where !s.dadosCarregados { try await Task.sleep(for: .milliseconds(50)) }
        try #require(s.dadosCarregados, "o app não carregou o documento que o site gravou")
        let gasto = try JSONDecoder().decode(ValorJSON.self, from: Data(try #require(ambiente["CUSTTA_GASTO_DO_APP"]).utf8))
        var estado = s.estado
        let i = try #require(estado.obras.firstIndex { $0.id == ambiente["CUSTTA_OBRA_DO_APP"] }, "a obra do roteiro não está no documento")
        estado.obras[i].gastos.append(Gasto(campos: try #require(gasto.comoObjeto)))
        try await s.salvar(estado)
        s.parar()
    }
}
```

Em `tests/app-ios.test.cjs`, troque o teste `'script dos testes do app contra os emuladores'` (Tarefa 12) por:

```js
test('scripts dos testes locais do app: emuladores e conferência cruzada', () => {
  const s = JSON.parse(ler('package.json')).scripts;
  for(const nome of ['test:app-ios:emuladores', 'test:app-ios:cruzado']){
    assert.match(s[nome] || '', /firebase emulators:exec --config firebase\.test\.json --project demo-custta-phase2 --only firestore,auth/, nome);
  }
  assert.match(s['test:app-ios:emuladores'], /scripts\/simulador-ios\.mjs --testar CusttaTests --emuladores/);
  assert.match(s['test:app-ios:cruzado'], /tests\/app-ios\/cruzado\.mjs/);
});
```

Run: `node --test tests/app-ios.test.cjs`
Expected: FAIL em "scripts dos testes locais do app" (`test:app-ios:cruzado` não existe).

- [ ] **Step 2: Escrever o roteiro**

`tests/app-ios/cruzado.mjs`:

```js
/* Conferência cruzada site ↔ app nativo na mesma conta, contra os emuladores do Firebase.
   Só local (precisa de simulador, Java e dos emuladores): npm run test:app-ios:cruzado.

   O "site" aqui é o SDK JavaScript do Firebase gravando como o cloud.js grava (documento
   inteiro com _atualizado do servidor), com as regras de verdade do site (dados.js, calc.js).
   O app é o build Debug no simulador:
     1. o site cria a conta e grava a v1 (obra com orçamento, obra vendida com orçamento por
        tópico estourado, obra com compra parcelada no cartão com juros e campos que só o site conhece);
     2. CruzadoUITests entra pelo formulário e confere o total e o orçamento que o calc.js calculou;
     3. o teste pede a v2 (POST no auxiliar abaixo) e espera ver os números novos sozinhos;
     4. CruzadoTests lança um gasto no app e grava pelo Sincronizador;
     5. este roteiro confere que o documento final foi gravado pelo app (o _atualizado avançou),
        que é exatamente a v2 normalizada com o gasto do app e que o site soma esse gasto.
   Teste pulado não passa: sem o pedido de mudança ou sem a gravação do app, o roteiro falha. */
import assert from 'node:assert/strict';
import { createServer } from 'node:http';
import { createRequire } from 'node:module';
import { initializeApp } from 'firebase/app';
import { getAuth, connectAuthEmulator, createUserWithEmailAndPassword } from 'firebase/auth';
import { initializeFirestore, connectFirestoreEmulator, doc, setDoc, getDocFromServer, serverTimestamp, Timestamp, terminate } from 'firebase/firestore';
import { testarNoSimulador } from '../../scripts/simulador-ios.mjs';

const require = createRequire(import.meta.url);
const C = require('../../calc.js');
const D = require('../../dados.js');

const app = initializeApp({ apiKey: 'chave-dos-emuladores', projectId: 'demo-custta-phase2', appId: '1:111188093030:web:cruzado' });
const auth = getAuth(app);
connectAuthEmulator(auth, 'http://127.0.0.1:9099', { disableWarnings: true });
const db = initializeFirestore(app, {});
connectFirestoreEmulator(db, '127.0.0.1', 8080);

const email = `cruzado-${Date.now()}@example.com`;
const senha = 'Casa2026x';
const { user } = await createUserWithEmailAndPassword(auth, email, senha);
const documento = doc(db, 'dados', user.uid);
const gravarComoOSite = blob => setDoc(documento, { ...blob, _atualizado: serverTimestamp() });

/* Compra no cartão com juros, montada pelo próprio calc.js: o total da obra (a soma das parcelas,
   com juros) é diferente do valor da compra. */
const compra = C.parcelamentoCartao(3000, 3, 2.5, '2026-03-10');
const { parcelas: vencimentos, ...jurosCartao } = compra;
const parcelasComJuros = vencimentos.map((p, i) => ({ id: `z${i + 1}`, grupoId: 'gz', parcela: { n: i + 1, de: compra.nParcelas },
  valor: p.valor, topico: 'eletrica', descricao: 'Fios e disjuntores', data: p.data, pagamento: 'cartao', jurosCartao }));
assert.notEqual(C.totalBruto({ gastos: parcelasComJuros }), compra.valorCompra, 'as parcelas têm juros');
const v1 = {
  obras: [
    { id: 'c1', nome: 'Casa do teste cruzado', dataInicio: '2026-01-10', fase: 'construcao', campoSoDoSite: { versao: 7 },
      orcamento: { modo: 'total', total: 50000 },
      gastos: [{ id: 'x1', valor: 12345.67, topico: 'fundacao', descricao: 'Sapatas', data: '2026-02-01', pagamento: 'pix', notaSoDoSite: 'fica' }] },
    { id: 'c2', nome: 'Sobrado vendido', dataInicio: '2025-03-01', fase: 'vendida', venda: { valor: 480000, data: '2025-12-20' },
      orcamento: { modo: 'topicos', topicos: { estrutura: 100000, acabamento: 50000 } },
      gastos: [
        { id: 'y1', valor: 120000, topico: 'estrutura', descricao: 'Laje', data: '2025-04-10', pagamento: 'pix' },
        { id: 'y2', valor: 61000.5, topico: 'acabamento', descricao: 'Porcelanato', data: '2025-09-02', pagamento: 'pix' },
        { id: 'y3', valor: 2500, topico: 'outros', descricao: 'Limpeza', data: '2025-12-01', pagamento: 'pix' },
      ] },
    { id: 'c3', nome: 'Reforma com compra parcelada', dataInicio: '2026-02-15', fase: 'construcao', gastos: parcelasComJuros },
  ],
  config: { taxaMensal: 1, topicosCustom: [] },
};
const v2 = structuredClone(v1);
v2.obras[0].gastos.push({ id: 'x2', valor: 40000, topico: 'estrutura', descricao: 'Laje', data: '2026-03-01', pagamento: 'pix' });
const gastoDoApp = { id: 'w1app', valor: 999.99, topico: 'pintura', descricao: 'Tinta lançada no app', data: '2026-04-01', pagamento: 'pix' };

/* O que a lista de obras do site mostra (app.js, renderInicio): total curto na tela, completo para o
   leitor de tela, e a linha do orçamento. */
const textoOrcamento = o => {
  const orc = C.orcamentoObra(o);
  if(!orc) return null;
  return orc.nivel === 'passou' ? `${orc.pct}% · passou ${C.moneyCurto(-orc.sobra)}` : `${orc.pct}% do orçamento`;
};
const esperado = blob => D.normaliza(blob).obras.map(o => ({ id: o.id, nome: o.nome, total: C.money(C.totalBruto(o)), orcamento: textoOrcamento(o) }));

await gravarComoOSite(v1);

let siteMudou = false;
const auxiliar = createServer(async (req, res) => {
  if(req.method === 'POST' && req.url === '/site/mudar'){ await gravarComoOSite(v2); siteMudou = true; res.end('ok'); return; }
  res.statusCode = 404; res.end();
});
await new Promise(r => auxiliar.listen(8124, '127.0.0.1', r));

const env = { CUSTTA_CRUZADO: '1', CUSTTA_EMULADORES: '1', CUSTTA_EMAIL: email, CUSTTA_SENHA: senha,
  CUSTTA_ESPERADO_V1: JSON.stringify(esperado(v1)), CUSTTA_ESPERADO_V2: JSON.stringify(esperado(v2)),
  CUSTTA_OBRA_DO_APP: 'c1', CUSTTA_GASTO_DO_APP: JSON.stringify(gastoDoApp) };
let antesDoApp;
try{
  await testarNoSimulador(['CusttaUITests/CruzadoUITests'], env);
  assert.ok(siteMudou, 'o teste de tela não pediu a mudança do site: foi pulado (o ambiente chegou até ele?)');
  antesDoApp = (await getDocFromServer(documento)).data()._atualizado;
  await testarNoSimulador(['CusttaTests/CruzadoTests'], env);
}finally{ auxiliar.close(); }

const final = (await getDocFromServer(documento)).data();
assert.ok(final._atualizado instanceof Timestamp, 'a gravação do app leva _atualizado do servidor');
assert.ok(final._atualizado.toMillis() > antesDoApp.toMillis(), 'o documento não foi regravado depois do teste do app: ele foi pulado ou não gravou');
delete final._atualizado;
const v3 = structuredClone(v2);
v3.obras[0].gastos.push(gastoDoApp);
assert.equal(C.canon(final), C.canon(D.normaliza(v3)), 'o app gravou a v2 normalizada com o gasto lançado nele, sem tirar nem pôr nada');
assert.deepEqual(final.obras[0].campoSoDoSite, { versao: 7 }, 'campo de obra que só o site conhece');
assert.equal(final.obras[0].gastos[0].notaSoDoSite, 'fica', 'campo de gasto que só o site conhece');
assert.equal(C.money(C.totalBruto(D.normaliza(final).obras[0])), C.money(12345.67 + 40000 + 999.99), 'o site soma o gasto lançado no app');
await terminate(db);
console.log('ok - site e app na mesma conta: totais e orçamentos iguais, mudança do site chegou ao app, gasto lançado no app chegou ao site sem perder nada');
process.exit(0);
```

No `package.json`, acrescente aos scripts:

```json
    "test:app-ios:cruzado": "firebase emulators:exec --config firebase.test.json --project demo-custta-phase2 --only firestore,auth \"node tests/app-ios/cruzado.mjs\"",
```

- [ ] **Step 3: Rodar e ver passar**

Run: `node --test tests/app-ios.test.cjs && npm run test:app-ios:cruzado`
Expected: guardas verdes; no roteiro, `CruzadoUITests` e `CruzadoTests` com `** TEST SUCCEEDED **` e a linha final `ok - site e app na mesma conta: totais e orçamentos iguais, mudança do site chegou ao app, gasto lançado no app chegou ao site sem perder nada`. Só no Mac (Java, emuladores e assinatura de simulador); a porta 8124 precisa estar livre.

- [ ] **Step 4: Provar que a conferência pega regressão**

Três mutações, uma de cada vez, desfazendo cada uma depois:

1. Em `app-ios/Custta/Telas/PrincipalView.swift`, troque `let total = totalBruto(obra)` por `let total = totalBruto(obra) + 0.01`. Run: `npm run test:app-ios:cruzado`. Expected: FAIL em `CruzadoUITests` (o valor da linha não contém o total que o `calc.js` calculou).
2. Em `app-ios/Custta/Dados/TransporteFirebase.swift`, comente a linha `dados["_atualizado"] = FieldValue.serverTimestamp()`. Expected: FAIL com `a gravação do app leva _atualizado do servidor`.
3. Rode o roteiro com `CUSTTA_CRUZADO` desligado no `env` do `cruzado.mjs` (troque `'1'` por `'0'`). Expected: FAIL com `o teste de tela não pediu a mudança do site: foi pulado`.

- [ ] **Step 5: Commit**

```bash
git add tests/app-ios/cruzado.mjs app-ios/CusttaUITests/CruzadoUITests.swift app-ios/CusttaTests/CruzadoTests.swift package.json tests/app-ios.test.cjs
git commit -m "test: conferência cruzada entre o site e o app nativo" -m "Na mesma conta, contra os emuladores: o SDK JavaScript grava como o cloud.js, o app entra pelo formulário e mostra os totais e orçamentos que o calc.js calculou (obra vendida, parcelada com juros e com orçamento estourado), uma mudança do site chega sozinha à lista e um gasto lançado no app chega ao site sem perder campo que só o site conhece. Teste pulado não passa: o roteiro exige o pedido de mudança do teste de tela e que o _atualizado avance depois do teste do app. Roda só no Mac (npm run test:app-ios:cruzado), antes de cada build do TestFlight."
```

---

### Task 16: Envio ao TestFlight como 2.0

**Files:**
- Create: `.github/workflows/app-ios-testflight.yml`
- Create (cópia): `app-ios/ExportOptions.plist` (de `ios/App/ExportOptions.plist`)
- Modify: `tests/workflow.test.cjs` (bloco do envio, depois do bloco do `app-ios.yml`)

**Interfaces:**
- Consumes: a configuração Release da Tarefa 1 (assinatura manual, perfil "Custta App Store", identidade "Apple Distribution", time 4S7JKDKN27); os secrets que o `ios-testflight.yml` já usa: `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8`, `APPLE_TEAM_ID`, `DIST_CERT_P12`, `DIST_CERT_SENHA`, `PERFIL_APP_STORE`.
- Produces: workflow `app-ios-testflight`, só no botão; build `2.0 (run_number.run_attempt)` no TestFlight do cadastro `br.com.custta.app`.

O `ios-testflight.yml` (Capacitor) não muda e continua podendo enviar o app de hoje até a remoção.

- [ ] **Step 1: Escrever a guarda que falha**

Em `tests/workflow.test.cjs`, logo depois da última linha do bloco do app nativo (a do `-onlyUsePackageVersionsFromResolvedFile`) e antes do `console.log` final:

```js
const appIosTf = readFileSync(join(dir, 'app-ios-testflight.yml'), 'utf8');
const appIosTfSemComentario = appIosTf.split('\n').filter(l => !/^\s*#/.test(l)).join('\n');
assert.match(appIosTf, /runs-on:\s*macos-26/);
assert.match(appIosTf, /^on:\n\s+workflow_dispatch:\s*\n(?!\s{2}\S)/m, 'o envio do app nativo é só no botão');
assert.match(appIosTf, /cancel-in-progress:\s*false/, 'cancelar no meio pode matar um upload');
assert.match(appIosTfSemComentario, /-project app-ios\/Custta\.xcodeproj/);
assert.match(appIosTfSemComentario, /-onlyUsePackageVersionsFromResolvedFile/);
assert.match(appIosTf, /CURRENT_PROJECT_VERSION="\$\{\{ github\.run_number \}\}\.\$\{\{ github\.run_attempt \}\}"/);
assert.match(appIosTf, /-exportOptionsPlist app-ios\/ExportOptions\.plist/);
assert.match(appIosTf, /if:\s*always\(\)[\s\S]*delete-keychain/, 'keychain temporária precisa sumir mesmo com falha');
for(const s of ['ASC_KEY_ID', 'ASC_ISSUER_ID', 'ASC_KEY_P8', 'APPLE_TEAM_ID', 'DIST_CERT_P12', 'DIST_CERT_SENHA', 'PERFIL_APP_STORE'])
  assert.match(appIosTf, new RegExp(`secrets\\.${s}\\b`), `envio do app nativo não lê o secret ${s}`);
assert.ok(!/-----BEGIN/.test(appIosTf), 'chave literal no workflow — repositório é público');
assert.equal(readFileSync(join(__dirname, '..', 'app-ios', 'ExportOptions.plist'), 'utf8'),
  readFileSync(join(__dirname, '..', 'ios', 'App', 'ExportOptions.plist'), 'utf8'), 'o envio do app nativo usa as mesmas opções do de hoje');
assert.match(appIosTf, /DEVELOPER_DIR:\s*\/Applications\/Xcode_26\.6\.app\/Contents\/Developer/, 'o envio usa o mesmo Xcode fixo da CI');
assert.match(appIosTf, /AppleWWDRCAG3\.cer/, 'sem o intermediário WWDR G3 a identidade não é válida para assinar');
assert.match(appIosTf, /TeamIdentifier/, 'perfil precisa ter o TeamIdentifier conferido');
assert.match(appIosTf, /!=\s*"Custta App Store"/, 'perfil precisa ter o Name conferido contra "Custta App Store"');
assert.match(appIosTf, /TEAM"\s*!=\s*"\$APPLE_TEAM_ID"/, 'perfil precisa comparar o time do perfil com APPLE_TEAM_ID');
assert.match(appIosTf, /ExpirationDate[\s\S]*-lt 30/, 'sem o aviso de perfil vencendo em menos de 30 dias');
```

Run: `node tests/workflow.test.cjs`
Expected: FAIL com `ENOENT: no such file or directory, open '…/.github/workflows/app-ios-testflight.yml'`.

- [ ] **Step 2: Escrever o workflow**

```bash
cp ios/App/ExportOptions.plist app-ios/ExportOptions.plist
```

`.github/workflows/app-ios-testflight.yml`:

```yaml
name: app-ios-testflight
# Arquiva, assina e envia o app nativo (app-ios/) ao TestFlight como versão 2.0, no mesmo cadastro
# do App Store Connect (br.com.custta.app), com os mesmos secrets e a mesma assinatura manual do
# ios-testflight.yml, que continua enviando o app Capacitor até a remoção.
#
# Só no botão: cada execução é um build de verdade na Apple. Antes de apertar, no Mac:
# npm run test:app-ios:emuladores e npm run test:app-ios:cruzado (a CI não roda os emuladores).
#
# Build number: run_number.run_attempt deste workflow. A Apple exige número único dentro da mesma
# versão (2.0); o run_attempt muda num "Re-run" que falhou no upload.
on:
  workflow_dispatch:

permissions:
  contents: read

# Mesmo Xcode do workflow app-ios: o padrão do runner muda sem aviso.
env:
  DEVELOPER_DIR: /Applications/Xcode_26.6.app/Contents/Developer

# Um envio por vez: cancelar no meio pode deixar upload pela metade.
concurrency:
  group: app-ios-testflight
  cancel-in-progress: false

jobs:
  enviar:
    runs-on: macos-26
    timeout-minutes: 60
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1

      - name: Versão do Xcode
        run: xcodebuild -version

      - name: Os secrets de assinatura existem
        env:
          ASC_KEY_ID: ${{ secrets.ASC_KEY_ID }}
          ASC_ISSUER_ID: ${{ secrets.ASC_ISSUER_ID }}
          ASC_KEY_P8: ${{ secrets.ASC_KEY_P8 }}
          APPLE_TEAM_ID: ${{ secrets.APPLE_TEAM_ID }}
          DIST_CERT_P12: ${{ secrets.DIST_CERT_P12 }}
          DIST_CERT_SENHA: ${{ secrets.DIST_CERT_SENHA }}
          PERFIL_APP_STORE: ${{ secrets.PERFIL_APP_STORE }}
        run: |
          falta=0
          for v in ASC_KEY_ID ASC_ISSUER_ID ASC_KEY_P8 APPLE_TEAM_ID DIST_CERT_P12 DIST_CERT_SENHA PERFIL_APP_STORE; do
            [ -z "${!v}" ] && { echo "::error::secret $v ausente"; falta=1; }
          done
          exit $falta

      # Keychain só deste job, criada e destruída na mesma execução (passo "Limpar").
      - name: Keychain temporária
        env:
          DIST_CERT_P12: ${{ secrets.DIST_CERT_P12 }}
          DIST_CERT_SENHA: ${{ secrets.DIST_CERT_SENHA }}
        run: |
          umask 077
          set -o pipefail
          KEYCHAIN="$RUNNER_TEMP/assinatura.keychain-db"
          SENHA="$(openssl rand -base64 32)"
          security create-keychain -p "$SENHA" "$KEYCHAIN"
          security set-keychain-settings -lut 21600 "$KEYCHAIN"
          security unlock-keychain -p "$SENHA" "$KEYCHAIN"
          echo "$DIST_CERT_P12" | base64 --decode > "$RUNNER_TEMP/dist.p12"
          security import "$RUNNER_TEMP/dist.p12" -P "$DIST_CERT_SENHA" -A -t cert -f pkcs12 -k "$KEYCHAIN"
          security set-key-partition-list -S apple-tool:,apple: -k "$SENHA" "$KEYCHAIN"
          security list-keychains -d user -s "$KEYCHAIN" $(security list-keychains -d user | tr -d '"')
          rm -f "$RUNNER_TEMP/dist.p12"
          # Sem o intermediário WWDR G3 a identidade importa mas fica inválida para assinar.
          curl -fsSL -o "$RUNNER_TEMP/AppleWWDRCAG3.cer" https://www.apple.com/certificateauthority/AppleWWDRCAG3.cer
          security import "$RUNNER_TEMP/AppleWWDRCAG3.cer" -k "$KEYCHAIN" || true
          IDENTIDADES="$(security find-identity -v -p codesigning "$KEYCHAIN")"
          echo "$IDENTIDADES"
          if ! grep -q 'Apple Distribution' <<< "$IDENTIDADES"; then
            echo "::error::nenhuma identidade Apple Distribution válida na keychain"
            exit 1
          fi
          echo "KEYCHAIN=$KEYCHAIN" >> "$GITHUB_ENV"

      # Mesmo perfil do app de hoje: o App ID é o mesmo (br.com.custta.app, push e Sign in with Apple).
      - name: Perfil de provisionamento
        env:
          PERFIL_APP_STORE: ${{ secrets.PERFIL_APP_STORE }}
          APPLE_TEAM_ID: ${{ secrets.APPLE_TEAM_ID }}
        run: |
          umask 077
          set -o pipefail
          PERFIL="$RUNNER_TEMP/perfil.mobileprovision"
          echo "$PERFIL_APP_STORE" | base64 --decode > "$PERFIL"
          security cms -D -i "$PERFIL" > "$RUNNER_TEMP/perfil.plist"
          UUID="$(plutil -extract UUID raw -o - "$RUNNER_TEMP/perfil.plist")"
          NOME="$(plutil -extract Name raw -o - "$RUNNER_TEMP/perfil.plist")"
          TEAM="$(plutil -extract TeamIdentifier.0 raw -o - "$RUNNER_TEMP/perfil.plist")"
          EXPIRA="$(plutil -extract ExpirationDate raw -o - "$RUNNER_TEMP/perfil.plist")"
          if [ "$NOME" != "Custta App Store" ] || [ "$TEAM" != "$APPLE_TEAM_ID" ]; then
            echo "::error::perfil errado — Name=\"$NOME\" TeamIdentifier=\"$TEAM\""
            exit 1
          fi
          # Aviso, não erro: o perfil ainda assina agora, mas perto do vencimento um envio pode
          # começar a falhar sem que ninguém tenha visto a tempo de renovar (como no ios-testflight.yml).
          AGORA="$(date -u +%s)"
          VENCE="$(date -j -u -f "%Y-%m-%dT%H:%M:%SZ" "$EXPIRA" +%s)"
          DIAS=$(( (VENCE - AGORA) / 86400 ))
          if [ "$DIAS" -lt 30 ]; then
            echo "::warning::perfil \"Custta App Store\" vence em $DIAS dias ($EXPIRA) — renovar"
          fi
          mkdir -p "$HOME/Library/MobileDevice/Provisioning Profiles" "$HOME/Library/Developer/Xcode/UserData/Provisioning Profiles"
          cp "$PERFIL" "$HOME/Library/MobileDevice/Provisioning Profiles/$UUID.mobileprovision"
          cp "$PERFIL" "$HOME/Library/Developer/Xcode/UserData/Provisioning Profiles/$UUID.mobileprovision"
          echo "PERFIL_UUID=$UUID" >> "$GITHUB_ENV"

      - name: Chave da API do App Store Connect
        env:
          ASC_KEY_ID: ${{ secrets.ASC_KEY_ID }}
          ASC_KEY_P8: ${{ secrets.ASC_KEY_P8 }}
        run: |
          umask 077
          mkdir -p "$RUNNER_TEMP/asc"
          printf '%s\n' "$ASC_KEY_P8" > "$RUNNER_TEMP/asc/AuthKey_$ASC_KEY_ID.p8"
          echo "ASC_KEY_PATH=$RUNNER_TEMP/asc/AuthKey_$ASC_KEY_ID.p8" >> "$GITHUB_ENV"

      # Sem override de assinatura na linha de comando: valeria para os pacotes de recurso do
      # Firebase, que não podem ter assinatura de distribuição. A Release do project.pbxproj já
      # aponta o perfil e a identidade.
      - name: Arquivar (Release, assinado)
        run: |
          set -o pipefail
          xcodebuild \
            -project app-ios/Custta.xcodeproj \
            -scheme Custta \
            -configuration Release \
            -destination 'generic/platform=iOS' \
            -archivePath "$RUNNER_TEMP/CusttaNativo.xcarchive" \
            -derivedDataPath app-ios/build \
            -skipMacroValidation \
            -skipPackagePluginValidation \
            -onlyUsePackageVersionsFromResolvedFile \
            CURRENT_PROJECT_VERSION="${{ github.run_number }}.${{ github.run_attempt }}" \
            archive

      - name: Enviar ao TestFlight
        env:
          ASC_KEY_ID: ${{ secrets.ASC_KEY_ID }}
          ASC_ISSUER_ID: ${{ secrets.ASC_ISSUER_ID }}
        run: |
          set -o pipefail
          xcodebuild -exportArchive \
            -archivePath "$RUNNER_TEMP/CusttaNativo.xcarchive" \
            -exportOptionsPlist app-ios/ExportOptions.plist \
            -exportPath "$RUNNER_TEMP/export" \
            -authenticationKeyPath "$ASC_KEY_PATH" \
            -authenticationKeyID "$ASC_KEY_ID" \
            -authenticationKeyIssuerID "$ASC_ISSUER_ID"

      - name: Resumo
        run: |
          echo "App nativo 2.0, build \`${{ github.run_number }}.${{ github.run_attempt }}\`, enviado ao TestFlight (branch \`${GITHUB_REF_NAME}\`, commit \`${GITHUB_SHA::7}\`)." >> "$GITHUB_STEP_SUMMARY"

      - name: Limpar
        if: always()
        run: |
          security delete-keychain "${KEYCHAIN:-$RUNNER_TEMP/assinatura.keychain-db}" || true
          rm -rf "$RUNNER_TEMP/asc" "$RUNNER_TEMP/dist.p12" "$RUNNER_TEMP/perfil.mobileprovision" "$RUNNER_TEMP/perfil.plist"
          if [ -n "${PERFIL_UUID:-}" ]; then
            rm -f "$HOME/Library/MobileDevice/Provisioning Profiles/$PERFIL_UUID.mobileprovision"
            rm -f "$HOME/Library/Developer/Xcode/UserData/Provisioning Profiles/$PERFIL_UUID.mobileprovision"
          fi
```

- [ ] **Step 3: Rodar e ver passar**

Run: `node tests/workflow.test.cjs && npm run test:unit`
Expected: `ok - Actions com SHA imutável…` e tudo verde.

Run (prova local de que a Release arquiva, sem assinatura): `xcodebuild -project app-ios/Custta.xcodeproj -scheme Custta -configuration Release -destination 'generic/platform=iOS' -archivePath "$TMPDIR/CusttaNativo.xcarchive" -skipMacroValidation -skipPackagePluginValidation -onlyUsePackageVersionsFromResolvedFile CODE_SIGNING_ALLOWED=NO archive`
Expected: `** ARCHIVE SUCCEEDED **`. O arquivamento assinado e o envio só acontecem no workflow (Tarefa 17, Step 6).

- [ ] **Step 4: Commit**

```bash
git add .github/workflows/app-ios-testflight.yml app-ios/ExportOptions.plist tests/workflow.test.cjs
git commit -m "ci: envio do app nativo ao TestFlight como 2.0" -m "Workflow só no botão que arquiva a Release assinada com o mesmo perfil, certificado e chave do App Store Connect do app de hoje e envia ao TestFlight como versão 2.0, com o build number run_number.run_attempt. A keychain é temporária e some mesmo com falha, o perfil é conferido (nome, time e aviso de vencimento em menos de 30 dias) e o Xcode é o mesmo fixo da CI; as opções de exportação são as mesmas do envio do Capacitor, que continua igual."
```

---

### Task 17: Documentação, portão local e build no TestFlight

**Files:**
- Modify: `CLAUDE.md` (bloco "Comandos" e seção nova "App nativo (app-ios/)", depois de "App iOS (Capacitor)")
- Create: `docs/plans/2026-10-06-app-nativo-etapa1-checklist-aparelho.md`

**Interfaces:**
- Consumes: tudo das Tarefas 1 a 16.
- Produces: instrução do app nativo para os próximos agentes; o checklist que o Giovani roda no iPhone; o primeiro build 2.0 no TestFlight.

- [ ] **Step 1: Documentar no CLAUDE.md**

No bloco de "Comandos", logo depois da linha do `npm run test:nucleo`:

```bash
npm run test:app-ios:emuladores  # testes do app nativo contra os emuladores do Firebase (Mac, Java)
npm run test:app-ios:cruzado     # conferência cruzada site ↔ app nativo nos emuladores (Mac, Java)
node scripts/cores-app-ios.mjs   # grava no catálogo do app nativo as cores da tabela de tokens
node scripts/icones-app-ios.mjs  # grava no catálogo do app nativo os ícones do icons.js que as telas usam
```

Depois da seção "### App iOS (Capacitor)", a seção nova:

```markdown
### App nativo (app-ios/)

App em SwiftUI que vai substituir o Capacitor (spec `docs/specs/2026-10-06-app-nativo-design.md`, planos `docs/plans/2026-10-06-app-nativo-*`, mockup aprovado da etapa 1 em `~/Documents/custta-mockups/nativo/etapa1/final.html`). O `app-ios/Custta.xcodeproj` é escrito à mão no formato do Xcode 16 (pastas sincronizadas): arquivo novo dentro de `Custta/`, `CusttaTests/` ou `CusttaUITests/` entra no alvo sozinho; não deixe o Xcode subir o `objectVersion` (77), porque a CI usa o Xcode 26 (`tests/app-ios.test.cjs` barra). As regras moram no pacote `app-ios/CusttaNucleo`, puro e conferido contra os vetores do site; o app tem a identidade em `Custta/Identidade/` (tokens de cor e de vidro, aurora, globo, título escrito à mão, superfícies de vidro e cápsula de abas, escritos uma vez e reusados), as telas, o `ModeloApp` e a camada fina do Firebase em `Custta/Dados/`. A cara é a do PWA: cores só por tokens (`scripts/cores-app-ios.mjs`; rode o script depois de mudar), ícones do `icons.js` (`scripts/icones-app-ios.mjs`), logo e globo iguais aos do site (as guardas comparam), toda superfície por `.superficie(_:em:)` com a dose de vidro da tela (`VidroTokens`), nunca vidro dentro de vidro, e animação própria só olhando o Reduzir movimento. O vidro do iOS não acompanha escala nem transformação 3D, e a auditoria de contraste do Xcode não lê vidro: as cores são auditadas com superfícies sólidas e a leitura sobre o vidro se confere no aparelho. Pacotes Swift: só firebase-ios-sdk e GoogleSignIn-iOS, em versão exata, com o `Package.resolved` versionado (para atualizar, botão "resolver de novo" do workflow `app-ios`); a Roboto Medium do botão do Google é a única fonte embutida, travada por SHA-256. Em Debug o app aceita `CUSTTA_SERVICOS=falsos` (telas e testes de tela; dados `vitrine` por padrão, as obras do mockup, e `exemplo` nos testes) e `CUSTTA_EMULADORES=1` (emuladores); o Release não tem nenhum dos dois. A CI (`app-ios.yml`) roda o núcleo, o build Release sem assinatura e os testes no simulador com os serviços falsos; os testes contra os emuladores e a conferência cruzada rodam no Mac e são obrigatórios antes de cada envio. O app nunca grava antes de ver os dados da conta (`Sincronizador`, erro `nao-carregado`). Sair segue o `cloud.js`: para a escuta, grava a marca `custta-limpar-cache` (`UserDefaults`), sai e apaga o cache; a abertura seguinte termina uma limpeza interrompida. Os identificadores de acessibilidade são contrato com os testes, inclusive a conferência cruzada. O Xcode da CI é fixo (`DEVELOPER_DIR` do 26.6). O `PrivacyInfo.xcprivacy` acompanha a política de privacidade do site: dado novo coletado entra nos dois. Envio: workflow `app-ios-testflight`, no botão, versão 2.0 no mesmo cadastro (`br.com.custta.app`). Pendências de aparelho: `docs/plans/2026-10-06-app-nativo-etapa1-checklist-aparelho.md`.
```

- [ ] **Step 2: Escrever o checklist do aparelho**

`docs/plans/2026-10-06-app-nativo-etapa1-checklist-aparelho.md`:

```markdown
# App nativo, etapa 1: checklist no iPhone

O Giovani roda no iPhone, pelo TestFlight, com o build 2.0 da etapa 1. Cada item que falhar vira tarefa para o Forja, com o passo, o que apareceu e uma captura de tela.

## Antes de instalar

- [ ] O build 2.0 substitui o app de hoje no iPhone. Para voltar, abra o TestFlight, toque no Custta, "Builds anteriores" e instale o 17.1 (vale até 90 dias depois de 04/10/2026). Os dados estão na nuvem; no máximo é preciso entrar de novo.
- [ ] Tenha o site aberto no computador (custta.com.br) na mesma conta.

## Entrar

- [ ] Entrar com e-mail e senha: a lista de obras aparece.
- [ ] Ajustes > Sair da conta > Sair: volta para a tela de entrar.
- [ ] Continuar com a Apple: a folha da Apple abre, entra e mostra as obras da mesma conta de antes.
- [ ] Sair e Continuar com Google: a tela do Google abre, entra e mostra as obras da mesma conta de antes.
- [ ] Senha errada: aparece "E-mail ou senha incorretos.".

## Conta que já existe no site

- [ ] Entrar com a conta Google que já usa no site: abre as mesmas obras do site, sem passar pelo "Falta pouco".
- [ ] Entrar com a conta Apple que já usa no site ou no app de hoje: abre as mesmas obras, sem "Falta pouco".

## Cadastro e Falta pouco

- [ ] Criar conta com um e-mail novo: o checklist da senha acompanha a digitação e a conta abre a lista (vazia) com o aviso "Confirme seu e-mail".
- [ ] Confirmar pelo link do e-mail, voltar ao app e tocar em "Já confirmei": o aviso some sem fechar o app.
- [ ] Conta Apple nova (sem cadastro no Custta): aparece "Falta pouco" pedindo só como conheceu o Custta, sem pedir o nome de novo.
- [ ] Conta Google nova: aparece "Falta pouco" com o nome já preenchido para confirmar.

## Totais iguais aos do site

- [ ] Para cada obra, o total na lista é o mesmo da lista de obras do site (os dois mostram o valor curto, como "R$ 329 mil"; com o VoiceOver ligado, o app lê o valor completo).
- [ ] Obra com orçamento: a porcentagem é a mesma do site; obra que passou do orçamento mostra "passou R$ …" igual ao site.
- [ ] A ordem é a do site: não vendidas primeiro, a mais recente em cima.

## Mudança no site chega ao iPhone

- [ ] Com o app aberto na lista, lance um gasto numa obra pelo site. Sem tocar no iPhone, o total daquela obra muda em poucos segundos.
- [ ] Apague o gasto pelo site: o total volta.

## Sem internet

- [ ] Ligue o modo avião, feche o app (arraste para cima no seletor de apps) e abra de novo: as obras estão lá e aparece "Sem conexão" no topo da lista.
- [ ] Ajustes > Sair da conta > Sair, ainda em modo avião: aparece "Conecte à internet e aguarde a sincronização antes de sair." e o app continua aberto.
- [ ] Desligue o modo avião: "Sem conexão" some sozinho.

## Leitura confortável

- [ ] Ajustes do iPhone > Acessibilidade > Tela e Tamanho do Texto > Texto Maior, no máximo: nas telas de entrar, criar conta, obras e Ajustes nada fica cortado nem sobreposto.
- [ ] VoiceOver ligado: na lista, cada obra é lida com nome, fase, meses, total gasto e orçamento.
- [ ] O app abre escuro, sem clarão branco na abertura.

## Visual (a cara do mockup aprovado)

O app abre no escuro esmeralda, o padrão (claro e azul chegam com a Aparência, na etapa 5; o time confere os quatro combos no simulador). Compare com os prints do mockup (`~/Documents/custta-mockups/nativo/etapa1/prints-com-refracao/final-*.png`).

- [ ] Ao abrir, a aurora e o globo aparecem, o "custta." se escreve e o ponto carimba com uma vibração leve.
- [ ] Entrar, criar conta, falta pouco, obras e Ajustes batem com o mockup (cartão de vidro, campos, botões da Apple e do Google, lista em cartões, comparativo, cápsula de abas).
- [ ] Ao entrar, a aurora escurece devagar (menos de um segundo); ao sair da conta, clareia de volta.
- [ ] Rolar a lista de obras rápido, para cima e para baixo: nada engasga, e a aurora e o globo param enquanto a lista rola.
- [ ] Dez minutos de uso, entrando e saindo das telas: o iPhone não esquenta.
- [ ] Ajustes do iPhone > Acessibilidade > Movimento > Reduzir movimento: a aurora e o globo ficam parados, o "custta." já aparece pronto e o título da entrada não se mexe ao rolar.
- [ ] Modo de Pouca Energia ligado: a aurora e o globo ficam parados.
- [ ] Ajustes do iPhone > Acessibilidade > Tela e Tamanho do Texto > Reduzir transparência: cartões e barras viram superfícies sólidas e legíveis; a aurora continua.
- [ ] Ajustes do iPhone > Acessibilidade > Tela e Tamanho do Texto > Aumentar contraste: o vidro fica mais firme, com contorno.
- [ ] Texto Maior no máximo: nada cortado sobre o vidro; a cápsula de abas não cresce e, segurando uma aba, aparece o nome ampliado.
- [ ] Leitura sobre o vidro: os textos dos cartões de obra, do aviso de e-mail e do "Entrar | Criar conta" se leem bem sobre a aurora (a auditoria do Xcode não mede vidro; aqui vale o olho, e um print vai ao Croqui medir).
- [ ] Vidro claro: compare a lista de obras com o app Tempo do iPhone, no claro e no escuro (calibração pendente do mockup).
```

- [ ] **Step 3: Rodar e ver passar**

Run: `npm run test:unit`
Expected: verde (o `docs.test.mjs` confere os links da documentação viva).

- [ ] **Step 4: Commit**

```bash
git add CLAUDE.md docs/plans/2026-10-06-app-nativo-etapa1-checklist-aparelho.md
git commit -m "docs: app nativo no CLAUDE.md e checklist do aparelho da etapa 1" -m "O CLAUDE.md ganha a seção do app nativo (projeto escrito à mão, núcleo puro, identidade escrita uma vez, pacotes travados, cores e ícones por tokens, serviços falsos e emuladores só em Debug, o que roda na CI e o que roda no Mac antes de cada envio) e os comandos novos. O checklist é o roteiro do Giovani no iPhone: entrar pelos três caminhos, totais iguais aos do site, mudança do site chegando sozinha, uso em modo avião e a cara do mockup no aparelho (movimento, bateria, transparência, contraste e letra grande sobre o vidro)."
```

- [ ] **Step 5: Portão local na main**

Depois do merge do PR 4, num worktree limpo da `origin/main`:

Run: `npm test && npm run test:nucleo && npm run test:app-ios:emuladores && npm run test:app-ios:cruzado`
Expected: tudo verde, terminando em `ok - site e app na mesma conta: totais e orçamentos iguais, mudança do site chegou ao app, gasto lançado no app chegou ao site sem perder nada`. Sem isso, o envio não sai.

- [ ] **Step 6: Enviar ao TestFlight (só com o OK do Giovani)**

O envio publica um build na Apple; o Orquestrador pede o OK ao Giovani antes.

Run (dispara e acompanha a execução pelo id, sem o seletor interativo do `gh run watch`):

```bash
ANTES=$(gh run list --workflow app-ios-testflight.yml --limit 1 --json databaseId -q '.[0].databaseId // 0')
gh workflow run app-ios-testflight.yml --ref main
until ID=$(gh run list --workflow app-ios-testflight.yml --limit 1 --json databaseId -q '.[0].databaseId') && [ "$ID" != "$ANTES" ]; do sleep 5; done
gh run watch "$ID" --exit-status
```

Expected: execução verde e, no resumo, `App nativo 2.0, build N.1, enviado ao TestFlight`. O build aparece no App Store Connect > TestFlight depois do processamento da Apple (de 15 a 30 minutos). Se a Apple pedir conformidade de exportação, ela já vem respondida (`ITSAppUsesNonExemptEncryption = NO`).

- [ ] **Step 7: Checklist no iPhone**

O Giovani roda `docs/plans/2026-10-06-app-nativo-etapa1-checklist-aparelho.md`. A etapa 1 fecha quando os itens de entrar, conta que já existe no site, cadastro, totais, mudança do site, modo avião e visual passarem; o que falhar volta como tarefa para o Forja.
