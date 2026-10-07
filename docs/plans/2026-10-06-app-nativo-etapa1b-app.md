# App base nativo (etapa 1B do app nativo) — plano de implementação

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> Neste time: o Forja implementa uma tarefa por vez, o Lupa revisa cada uma antes da próxima. A Tarefa 9 é do Croqui e do Giovani, sem código. Ninguém faz commit, push ou PR sem o Orquestrador pedir; quando pedir, valem os comandos de commit de cada tarefa.

**Goal:** Primeiro build 2.0 do app nativo no TestFlight: o Giovani entra na conta (e-mail e senha, Apple ou Google), vê as obras com os totais iguais aos do site, vê chegar ao iPhone uma mudança feita no site e abre o app em modo avião com tudo lá.

**Architecture:** Projeto Xcode `app-ios/Custta.xcodeproj` escrito à mão no formato do Xcode 16+ (pastas sincronizadas), com o app `Custta`, os testes de unidade `CusttaTests` (hospedados no app) e os de tela `CusttaUITests`. O app usa o pacote local `CusttaNucleo` (Parte A) e só dois pacotes de terceiros, travados: firebase-ios-sdk 12.19.2 e GoogleSignIn-iOS 8.0.0. Três camadas: o núcleo ganha as regras do cadastro, as regras das telas, a tradução dos erros do Firebase e o `Sincronizador` (porte da fila do `cloud.js` e do eco do `app.js`, puro, testado com transporte e relógio falsos); a camada de dados é fina sobre o SDK (`TransporteFirebase`, `ContaFirebase`); as telas são SwiftUI com um `ModeloApp` observável, que é o `db` e o `auth.js` do site. Em Debug o app aceita serviços falsos (testes de tela, sem rede) e os emuladores do Firebase (integração e conferência cruzada com o site).

**Visual (decisão revista em 06/10, commits `70bd128` e `0b5bec0` do spec):** o app terá a cara do PWA de hoje, escrita em código nativo e com ainda mais Liquid Glass (spec, "Decisões > Visual" e seção 2). Este plano foi escrito antes da mudança. As Tarefas 10, 11 e 12 (PR 4) são um **esqueleto funcional validado**, com componentes do sistema: provam fluxos, acessibilidade e sincronização, e **serão refeitas com o mockup aprovado** no portão (Tarefa 9). Depois do portão, o PR 4 ganha tarefas próprias para os componentes de identidade, escritos uma vez e reusados: fundo com aurora nas cores do skin e globo; superfície de vidro (cartões, painéis e barras); cápsula de abas com o botão +; título do login escrito à mão. Os PRs 1, 2, 3 e 5 não dependem do visual.

**Tech Stack:** Xcode 26.6 na CI (`macos-26`) e Xcode 27 no Mac do Giovani; Swift 6 com concorrência estrita; SwiftUI (iOS 26), Observation, Swift Testing, XCTest e XCUITest; FirebaseAuth e FirebaseFirestore 12.19.2; GoogleSignIn 8.0.0; AuthenticationServices, CryptoKit e Network do sistema. No Node: firebase-tools (emuladores) e o SDK JavaScript `firebase` 12.18.0 que já está nas devDependencies, só no roteiro da conferência cruzada.

**Spec:** `docs/specs/2026-10-06-app-nativo-design.md` (Decisões; Desenho 1 a 8; Etapas, linha 1; Testes e validação 2, 4, 5, 6 e 7). Depende da Parte A (`docs/plans/2026-10-06-app-nativo-etapa1a-nucleo.md`) já na `main`. Inventário do site, com arquivo e linha: `docs/plans/2026-10-06-app-nativo-inventario.md` (seções 5 e 6).

**Validação deste plano:** o Prumo extraiu o código das Partes A e B do texto dos dois planos para uma cópia limpa do worktree e rodou tudo com Xcode 27 e o simulador do iOS 27: `npm run test:unit` (340 testes, inclusive as guardas novas); o núcleo (111 testes em 22 suítes, 45 desta parte); o app com os serviços falsos (28 testes de unidade e 21 de tela, inclusive as auditorias de acessibilidade no maior tamanho de letra e o contraste nos quatro combos); os testes contra os emuladores (inclusive o login com Google pelo token falso do emulador, a recusa das rules a chave nova e a saída que limpa o cache e deixa outra conta gravar e ler do servidor pelo mesmo banco); a conferência cruzada site ↔ app de ponta a ponta, que agora falha se um dos testes for pulado; e o arquivamento da Release sem assinatura. O projeto escrito à mão resolveu os pacotes com os pins do app Capacitor de hoje e continuou idêntico ao texto do plano depois de todos os builds. Os trechos vêm de um protótipo cujas auditorias acharam, e o plano já corrige: texto branco sobre a cor da marca no tema escuro (contraste 2,6:1), cabeçalho de seção com a cor do sistema, placeholder longo cortando e e-mail sem rótulo legível. Não validado: a CI com o Xcode 26.6 (a primeira prova é o PR 1, aberto como rascunho), o envio assinado ao TestFlight (Tarefa 15) e o login de verdade com Apple e Google no aparelho (checklist da Tarefa 15).

## Global Constraints

- **Padrão profissional (regra do Giovani, 06/10):** "Quero tudo o mais profissional possível; se precisar de referência, me diga que a gente procura junto." Faltou referência para uma decisão de desenho, código, teste ou texto: ninguém improvisa; a falta vai ao Orquestrador, que procura com o Giovani. O portão de desenho (Tarefa 9) leva a lista "Referências que faltam".
- Projeto `app-ios/Custta.xcodeproj`, `objectVersion = 77`, pastas sincronizadas; bundle `br.com.custta.app`; `MARKETING_VERSION = 2.0`; `IPHONEOS_DEPLOYMENT_TARGET = 26.0`; `TARGETED_DEVICE_FAMILY = 1`; só retrato. Não abra e salve o projeto num Xcode que suba o formato: `tests/app-ios.test.cjs` barra.
- Pacotes de terceiros: só `firebase-ios-sdk` (produtos FirebaseAuth e FirebaseFirestore) e `GoogleSignIn-iOS` (produto GoogleSignIn), com `kind = exactVersion`, `Package.resolved` versionado e `-onlyUsePackageVersionsFromResolvedFile` em todo `xcodebuild` da CI. Sem Sentry. Nenhum pacote npm no app.
- Reaproveitar de `ios/App/App/`: `GoogleService-Info.plist` e `App.entitlements` (push e Sign in with Apple) copiados sem mudança, e o esquema de URL `REVERSED_CLIENT_ID` com `GIDClientID` no `Info.plist`.
- Nenhuma chave nova no blob; `firestore.rules` não muda; `perfis/{uid}` com os mesmos campos e limites (`email`, `criado`, `tz`, `nome`, `sobrenome`, `origem`, `origemDetalhe`).
- Nenhuma tela escreve em `dados/{uid}` nesta etapa; a escrita existe e é testada no `Sincronizador`, no transporte e na conferência cruzada.
- Requisitos da seção 8 do spec: legível e sem corte até o maior tamanho de letra de acessibilidade (`UICTContentSizeCategoryAccessibilityXXXL`), todo controle com rótulo para o VoiceOver, alvos de toque de 44 pt ou mais, cores só por tokens (Esmeralda e Azul, claro e escuro), escuro por padrão; animação própria respeita Reduzir movimento e para fora da tela e durante a rolagem.
- O app nunca grava antes de ver os dados da conta (snapshot do servidor, ou do cache com o documento): `Sincronizador.salvar` recusa com `nao-carregado`. Vale para toda tela que gravar, desta etapa em diante.
- Os identificadores de acessibilidade das telas e o valor de acessibilidade da linha de obra ("total gasto R$ …", "X% do orçamento" ou "X% · passou R$ …") são contrato com os testes, inclusive a conferência cruzada: a reescrita visual do PR 4 mantém os mesmos.
- Todo `xcodebuild` e `swift` da CI roda com o `DEVELOPER_DIR` do Xcode 26.6 (decisão "Xcode da CI" da Parte A).
- Os workflows do Capacitor (`ios-build.yml`, `ios-testflight.yml`) não mudam.
- Mockups em `~/Documents/custta-mockups/`, nunca no repositório.
- Testes contra os emuladores: projeto `demo-custta-phase2`, portas 8080 (Firestore) e 9099 (Auth), como o `firebase.test.json`. Rodam com a assinatura de simulador do Xcode (sem `CODE_SIGNING_ALLOWED=NO`): sem ela o app não tem entitlements e o Firebase Auth falha no keychain (erro −34018).
- Identificadores, comentários, textos de tela e commits em português. Textos de tela iguais aos do site, salvo onde o portão de desenho (Tarefa 9) decidir outra coisa.
- Commits: um por mudança lógica, `tipo: descrição` em minúsculas com acento, corpo em prosa quando não é trivial, autor Giovani Stuchi, **sem linha de coautoria**. Branch + PR, nunca direto na `main`. Um worktree por entrega em `.claude/worktrees/<nome>`, criado da `origin/main`: cada linha da tabela "Como entregar" é uma tarefa do Orquestrador, com branch, worktree e PR próprios.
- Escapes de caractere nos trechos de código usam a forma `\u{a0}` (vale em JavaScript e Swift). Copie exatamente.

## Decisões

| Ponto | Decisão | Por quê |
| --- | --- | --- |
| Como o projeto Xcode nasce | `project.pbxproj` escrito à mão, formato do Xcode 16+ (`objectVersion = 77`) com pastas sincronizadas; sem XcodeGen nem Tuist. | Ferramenta geradora seria mais uma dependência fora da política de pacotes revisados, instalada por Homebrew no Mac e na CI. Com pastas sincronizadas, arquivo novo numa pasta entra no alvo sem tocar no `project.pbxproj`, que quase não muda depois da Tarefa 1. O arquivo deste plano foi aberto, resolvido e compilado pelo Xcode 27 sem ser reescrito. A guarda de `objectVersion` impede que um Xcode mais novo suba o formato e quebre a CI (Xcode 26). |
| Par de versões dos SDKs | firebase-ios-sdk **12.19.2** e GoogleSignIn-iOS **8.0.0**, `exactVersion`. | É o par que já resolve no `Package.resolved` do app Capacitor (app-check 11.3.2, gtm-session-fetcher 3.5.0); o Firebase 13 não fecha com o GoogleSignIn 8 (`docs/sdks-fase4.md`). Versão exata porque a subida é decisão: muda o `project.pbxproj` e o `Package.resolved` juntos, pelo botão "resolver de novo". FirebaseMessaging entra na etapa 5, do mesmo pacote, sem mudar os pins. |
| Client do Google | O client **iOS** do `GoogleService-Info.plist` (`GIDClientID` no `Info.plist`), não o client web que o plugin do Capacitor usava. | É o caminho padrão do SDK nativo do Google com o Firebase iOS. A conta Google é a mesma (o Firebase reconhece pelo `sub`), então o uid é o mesmo do site e do app de hoje. |
| Login com a Apple | `SignInWithAppleButton` do SwiftUI com nonce (32 bytes aleatórios; a Apple recebe o SHA-256) e `OAuthProvider.appleCredential(withIDToken:rawNonce:fullName:)`. O nome do primeiro login vai para o `displayName`. | Botão e fluxo do sistema, sem `ASAuthorizationController` à mão. Gravar o nome repete o `gravaNome` do `cloud.js`: o "Falta pouco" não pede o nome de novo (a revisão da Apple reprova). |
| Estado e sincronização | `Sincronizador` no núcleo, `@MainActor @Observable`, com `TransporteDados` e `Relogio` injetados; `TransporteFirebase` só converte tipos e códigos. Retornos do Firestore na fila principal (`dispatchQueue = .main`). | A regra da fila, do backoff, da guarda de tamanho, do eco e de só gravar depois de ver os dados fica testável sem simulador (29 testes com falsos). O transporte fino é coberto pelos testes contra o emulador. |
| Sair da conta | Na ordem do `cloud.js`: espera a fila (o que a sessão gravou e o que o SDK guardou), 5 s no máximo, e sem rede pede para conectar e não sai; confere que a conta é a mesma, para a escuta, grava a marca de limpeza, faz `signOut` e `GIDSignIn.signOut()`, encerra o Firestore e apaga o cache (`terminate` + `clearPersistence`) e só então tira a marca. Se o app fechar no meio, a próxima abertura termina a limpeza antes de ler. Sessão que cai sozinha não limpa o cache. | Igual ao `logout` do `cloud.js` (`cloud.js:263-292` e `572-592`), que marca a limpeza antes do `signOut` e a retoma na abertura. Durante a limpeza nada lê nem grava (`BancoFirebase.quandoPronto`): mexer numa instância em encerramento derruba o app. Na queda de sessão a fila persistente do SDK é da conta e sobe quando ela entra de novo. |
| Nome do Google ou da Apple no limite (`nomeDoGoogle`) | Corta em unidades UTF-16 como o site, mas sem partir um emoji ao meio (`prefixoUTF16`). | O `slice` do site pode deixar meia letra (surrogate solto) num emoji exatamente no limite de 60 ou 80; a `String` do Swift não representa isso. Os vetores não têm emoji no limite; a diferença é de um caractere num caso raríssimo. |
| Abas | Só **Obras** e **Ajustes** nesta etapa. | "Vale a pena?" chega na etapa 4; aba vazia é pior que aba ausente. O botão + da cápsula de abas entra com a escrita (etapa 2); o portão decide como a cápsula aparece sem ele. |
| Lista sem obras | "Nenhuma obra ainda" e "Por enquanto, crie a primeira obra pelo site custta.com.br." | O texto do site manda tocar no "+", que não existe na etapa 1. A Tarefa 9 confirma ou troca. |
| Cores | 11 tokens × 2 peles × claro/escuro, com valores de partida do `styles.css` (inclusive `SobreMarca` = `--btn-ink`), gerados por `scripts/cores-app-ios.mjs`. | Tokens com nome estável no código; o portão de desenho troca valores na tabela do script, não no código. `SobreMarca` resolve o contraste do texto dos botões principais nos quatro combos (achado da auditoria). Com a decisão de visual nova, o portão define também os tokens de vidro e da aurora (os `--vidro*` e as cores do `#aurora` do `styles.css`). |
| Serviços falsos | `ContaFalsa`, `TransporteFalsoApp` e `DadosDeExemplo` dentro do app, só em Debug, ligados por `CUSTTA_SERVICOS=falsos`. | Os testes de tela abrem o app de verdade; o falso precisa estar no binário. O Release (TestFlight) não leva nada disso. |
| Build number do TestFlight | `run_number.run_attempt` do workflow novo, na versão 2.0. | A Apple exige número único dentro da mesma versão; 2.0 é uma versão nova no mesmo cadastro. |
| Visual da etapa 1 | Esqueleto funcional com componentes do sistema nas Tarefas 10 a 12; a identidade do PWA (aurora, globo, vidro, cápsula de abas, título escrito à mão) entra depois do portão, em tarefas próprias do PR 4. | O spec trocou "iOS de verdade com a marca" por "a cara do PWA em código nativo" depois que este plano estava escrito e validado. O esqueleto continua valendo: fluxos, sincronização e acessibilidade foram provados com ele, e os testes de fluxo e de acessibilidade sobrevivem à troca de visual. |
| Lista de obras só leitura | Entra na etapa 1 por decisão do Orquestrador; no spec ela abre a etapa 2. | É o que torna a sincronização testável no aparelho: sem lista, o build da etapa 1 não mostraria os totais nem a mudança chegando do site. |
| Gravar só depois de ver os dados | `Sincronizador.salvar` recusa (`nao-carregado`) até chegar um snapshot do servidor ou um do cache com o documento; cache sem documento não conta. | Sem a guarda, quem entrasse, perdesse a rede antes do primeiro snapshot do servidor e criasse uma obra (etapa 2) regravaria o documento inteiro por cima das obras que só o servidor tem. O site tinha esse risco e ganhou a mesma guarda no #52: `saveDados` recusa com `nao-carregado` e `dadosCarregados` só vale com snapshot do servidor ou do cache com o documento. As duas cópias seguem a mesma regra. |
| Guarda de gravação: pendências obrigatórias da etapa 2 | Antes da primeira tela que grava: (1) uma marca por conta "o servidor já respondeu", apagada junto com o cache, entrando na condição da guarda; (2) uma mensagem própria para `nao-carregado` na tela que grava. | Hoje a guarda é conservadora: a conta nova que já viu "não existe" no servidor, fechou o app sem gravar e reabriu sem rede fica sem gravar até a rede voltar (o site tem a mesma limitação desde o #52). Na etapa 1 nenhuma tela grava; a lista já explica o erro de leitura antes de carregar. |
| Documento com tipo que o JSON não tem | A leitura falha com `formato-desconhecido` e o app para de gravar, antes ou depois de já ter carregado (`dadosCarregados` volta a falso); a lista diz que os dados não puderam ser lidos e que nada foi alterado, com "Tentar de novo", em vez de carregar para sempre. | Converter para null apagaria o dado na próxima gravação, que reescreve o documento inteiro: quem não leu o documento inteiro não grava. Nenhum dos dois apps grava esses tipos; só um documento editado à mão chega aqui. |
| `Package.resolved` | Semeado do `Package.resolved` do app de hoje (`ios/`), sem os dois pins do Capacitor; o Xcode só recalcula o `originHash`. | As 14 dependências transitivas ficam nas versões que já estão em produção e revisadas, em vez de "a mais nova do dia" em que alguém resolveu. Atualizar continua sendo pelo botão "resolver de novo". |
| Manifesto de privacidade | `PrivacyInfo.xcprivacy` mínimo já na etapa 1: sem rastreamento, `UserDefaults` pelo motivo CA92.1 e os dados coletados da política de privacidade do site (e-mail, nome, id da conta, conteúdo do usuário, "como conheceu"). | Sem o manifesto a Apple manda o aviso ITMS-91053 a cada envio. Os SDKs do Firebase e do Google trazem os deles; o token do FCM entra na etapa 5, com as notificações. |
| Esqueci a senha | Mesma resposta do site: e-mail sem conta mostra "E-mail ou senha incorretos." | Paridade. Não revelar se o e-mail existe é decisão de produto e do console do Firebase (proteção contra enumeração), não desta etapa. |
| Reduzir movimento e aumentar contraste | Etapa 1 sem animação própria (só as do sistema, que já respeitam o ajuste), com guarda para as próximas etapas; tokens sem variante de alto contraste por enquanto. | Todos os tokens passam na auditoria de contraste do Xcode nos quatro combos. Variante de alto contraste é decisão de desenho: o portão (Tarefa 9) decide se entra agora ou na etapa 6, a de acessibilidade completa (recomendação: etapa 6). |

## O que roda na CI e o que roda só no Mac

| Testes | Onde | Por quê |
| --- | --- | --- |
| Núcleo (`swift test`, ~100 testes) | CI, job `nucleo`, e `npm run test:nucleo` | Rápido, sem simulador, pega divergência com o site a cada PR que mexe nas regras. |
| Unidade do app com falsos e sem rede (`ModeloAppTests`, `CoresTests`, `FumacaTests`, `ConversaoDoDocumentoTests`, `BancoFirebaseTests`, `ErrosDoSDKTests`) | CI, job `app` | Sem rede e sem keychain; roda com `CODE_SIGNING_ALLOWED=NO`. |
| Tela com falsos e auditorias de acessibilidade (`CusttaUITests`) | CI, job `app` | Determinístico (sem rede) e é onde os requisitos da seção 8 viram teste. |
| Integração contra os emuladores (`TransporteFirebaseTests`, `ContaFirebaseTests`) | Mac: `npm run test:app-ios:emuladores` | Precisa de Java, dos emuladores e da assinatura de simulador (keychain do Auth). A camada é fina e muda pouco; rodar no Mac antes de cada envio ao TestFlight basta. |
| Conferência cruzada site ↔ app (`tests/app-ios/cruzado.mjs`) | Mac: `npm run test:app-ios:cruzado` | Mesmo motivo, mais o auxiliar HTTP que o teste de tela chama para "mudar no site". Portão obrigatório antes de cada build do TestFlight (Tarefa 15). |

## Referências que faltam

Com a decisão nova, a referência de visual é o PWA de hoje (o print ao lado de cada tela do mockup) e a de comportamento são os apps da Apple e a HIG. O que ainda falta de verdade, para o Croqui levar ao Giovani no portão (Tarefa 9):

1. **Liquid Glass nativo para calibrar a dose:** como os apps da Apple no iOS 26 usam o material de verdade (Música, Fotos, Tempo, Mapas): vidro só na navegação ou também no conteúdo, e onde ele para. O PWA imita vidro com `backdrop-filter`; o nativo usa `glassEffect`, que reage à luz e ao movimento e se comporta diferente sobre a aurora.
2. **Fundo animado que não pesa:** um app nativo com fundo vivo que rola liso e não esquenta (o Tempo da Apple é o exemplo mais próximo), para decidir como a aurora e o globo são feitos (desenho do SwiftUI, shader de Metal ou vídeo) e como param na rolagem e fora da tela.
3. **Identidade forte no maior tamanho de letra:** como apps com visual próprio (Carteira, Saúde) mantêm a cara no maior tamanho de acessibilidade: o que vira coluna, o que some e onde a cápsula de abas fica.
4. **Legibilidade sobre vidro e aurora:** a HIG de materiais e de Liquid Glass, e um método combinado para medir o contraste no pior ponto da aurora (o quadro mais claro sob o texto), com o mínimo de 4,5:1 do spec.
5. **Comportamento do sistema que o PWA imita e o nativo não deve imitar:** barra de abas que encolhe na rolagem do iOS 26, folhas e diálogos do sistema, teclado com preenchimento automático de senha, voltar pela borda. A referência são os apps da Apple; a lista final sai do portão ("onde o nativo não pode ou não deve ficar igual ao PWA").
6. **Título escrito à mão:** o SVG do logo do site já existe (`tests/logo-escrito.test.cjs` o protege); falta referência de animação de traço em app nativo de qualidade e de como ela aparece com Reduzir movimento (pronta, sem traço).

## Review Focus

1. **Primeiro uso sem internet** (app recém-instalado ou cache vazio, em modo avião): esperado é a tela de entrar ou a lista esperando a conexão ("Sem conexão"), e nunca gravar: nem um documento vazio, nem uma edição por cima das obras do servidor. Testes: `salvarSoDepoisDeVerOsDados` nos três cenários (Tarefa 5) e `abrirOAppNaoGravaNada` nos mesmos três (Tarefa 8).
2. **Falta de rede ao conferir a sessão:** nunca desloga. Teste: `sessaoQueEncerraAConta` (Tarefa 4) e `ContaFirebase.verificarSessao`, que só sai por código de sessão inválida (Tarefa 7).
3. **Conta Google ou Apple cujo perfil outro aparelho gravou no meio do "Falta pouco":** as rules recusam o segundo perfil e o app tem de seguir para a lista. Teste: `perfilGravadoPorOutroAparelhoSegueParaOApp` (Tarefa 8).
4. **Mudança do site chegando enquanto há gravação local pendente:** o eco não pode desfazer a edição local. Teste: `ecoComGravacaoLocalPendenteEIgnorado` (Tarefa 5) e a conferência cruzada (Tarefa 13).
5. **Maior tamanho de letra com nome de obra longo e valor alto** ("Residencial Jardim das Acácias, Bloco B, Casa 12", R$ 123,5 mi): nada corta. Teste: `testObrasNoMaiorTamanho` (Tarefa 12), que audita a lista com a obra o4 dos dados de exemplo antes e depois de rolar.

## Riscos

**Componentes de identidade (PR 4, depois do portão).** São o maior custo novo da etapa 1 e o maior risco técnico:

- **Desempenho da aurora e do globo na rolagem:** fundo animado atrás de uma lista com vidro pode derrubar quadros. O spec exige rolagem lisa e animação parada durante a rolagem e fora da tela.
- **Bateria e aquecimento:** animação contínua gasta mesmo com a tela parada; com Modo de Pouca Energia ou Reduzir movimento, a aurora fica parada e o globo não gira.
- **Contraste sobre o vidro no pior ponto da aurora:** a auditoria do Xcode mede o quadro do instante; o pior caso (a parte mais clara da aurora atrás de um texto) precisa de medição combinada no portão e de um teste que congele a aurora nesse quadro.
- **Letra grande:** a cápsula de abas, os cartões de vidro e os números grandes do PWA foram desenhados para letra fixa; no maior tamanho de acessibilidade, alguma coisa vai ter de virar coluna ou rolar.
- **Vidro dentro de vidro e transparência reduzida:** o spec proíbe vidro dentro de vidro; com Reduzir transparência ligado, o vidro tem de virar superfície sólida e legível.

**O que a etapa 1 tem de provar no aparelho** (checklist da Tarefa 15): rolar a lista com aurora e globo sem engasgar no iPhone do Giovani (e, antes da loja, no iPhone 16 Pro do pai); dez minutos de uso sem esquentar; com Reduzir movimento, aurora e globo parados; com Reduzir transparência, vidro sólido e legível; no maior tamanho de letra, nada cortado sobre o vidro.

**Outros riscos abertos:** a CI com o Xcode 26.6 ainda não rodou (o PR 1 abre como rascunho para descobrir cedo); o primeiro envio assinado ao TestFlight depende dos secrets e do perfil "Custta App Store" de hoje (mesmo App ID); o login de verdade com Apple e Google só se prova no aparelho; o portão pode mudar a estrutura das telas e pedir revisão das Tarefas 11 e 12.

## Como entregar

| PR | Branch e worktree | Tarefas | Estimativa (dias de trabalho do time) |
| --- | --- | --- | --- |
| 1 | `feat/app-nativo-projeto` em `.claude/worktrees/app-nativo-projeto` | 1 e 2 | 1 a 1,5 |
| 2 | `feat/app-nativo-regras` em `.claude/worktrees/app-nativo-regras` | 3, 4 e 5 | 2 a 3 |
| 3 | `feat/app-nativo-dados` em `.claude/worktrees/app-nativo-dados` | 6, 7 e 8 | 3 a 4 |
| — | portão de desenho (sem código) | 9 | Croqui e Giovani, em paralelo aos PRs 2 e 3 |
| 4 | `feat/app-nativo-telas` em `.claude/worktrees/app-nativo-telas` | 10, 11 e 12, mais as tarefas de identidade | estimado depois do mockup aprovado |
| 5 | `feat/app-nativo-testflight` em `.claude/worktrees/app-nativo-testflight` | 13, 14 e 15 | 1,5 a 2 |

A estimativa conta implementação, revisão do Lupa, correções e a primeira passada na CI, com o código já escrito e validado neste plano. O PR 4 só pode ser estimado depois do mockup aprovado: os componentes de identidade (aurora e globo nativos, superfície de vidro, cápsula de abas, título escrito à mão) são a maior parte do trabalho novo da etapa 1, e o esqueleto das Tarefas 10 a 12 já está validado. Fica fora da conta do time o tempo do Giovani: aprovar o mockup no portão, aprovar os PRs, rodar o checklist do iPhone (cerca de 1 hora) e o vaivém das correções que ele pedir.

```bash
# na raiz do repositório principal; de dentro de um worktree, a linha abaixo sobe até ela
cd "$(git rev-parse --path-format=absolute --git-common-dir)/.."
git fetch origin
git worktree add .claude/worktrees/app-nativo-projeto -b feat/app-nativo-projeto origin/main
cd .claude/worktrees/app-nativo-projeto && npm ci
```

Ordem: cada PR começa depois que o anterior entrou na `main` (o worktree nasce da `origin/main` atualizada). O portão de desenho (Tarefa 9) não tem código e corre em paralelo com os PRs 2 e 3; o PR 4 espera por ele.

**Na entrega de cada PR:** descrição em prosa (contexto, o que muda, decisão técnica), o link da prévia da Vercel conferido e o "como testar". Nenhum PR desta parte muda o que vai para a Vercel (`app-ios/` está no `.vercelignore`): a prévia confirma que o site continua igual, e o "como testar" diz qual comando prova o que mudou (`npm run test:nucleo`, o `xcodebuild test` do simulador, `npm run test:app-ios:emuladores` ou `npm run test:app-ios:cruzado`).

**PR aberto cedo:** o Orquestrador abre cada PR desta parte como rascunho logo depois do primeiro commit, para a CI do app rodar com o Xcode da CI desde a primeira tarefa (no PR 1, é a primeira vez que o projeto compila no Xcode 26.6).

Todos os comandos rodam na raiz do worktree. `DESTINO` nos comandos de teste é a saída de `node scripts/simulador-ios.mjs` (Tarefa 2); antes dela, use `-destination 'platform=iOS Simulator,name=<um iPhone de xcrun simctl list devices available>'`.

## Mapa de arquivos

| Arquivo | Responsabilidade |
| --- | --- |
| `app-ios/Custta.xcodeproj/` (project.pbxproj, workspace, Package.resolved, scheme) | projeto, alvos, pacotes travados |
| `app-ios/Custta/CusttaApp.swift` | entrada do app; não monta nada quando hospeda testes de unidade |
| `app-ios/Custta/Composicao.swift` | monta os serviços: produção, emuladores (Debug) ou falsos (Debug) |
| `app-ios/Custta/Conta/ServicoConta.swift` | protocolo da conta, `Usuario`, `CredencialApple`, `ErroConta` |
| `app-ios/Custta/Dados/BancoFirebase.swift`, `TransporteFirebase.swift`, `ContaFirebase.swift`, `Sistema.swift` | Firestore, transporte do estado, conta no Firebase Auth, relógio, rede e janela |
| `app-ios/Custta/Estado/ModeloApp.swift` | fase da tela, conta, sincronização e avisos |
| `app-ios/Custta/Falsos/*.swift` | conta, transporte e dados falsos (só Debug) |
| `app-ios/Custta/Telas/*.swift` | paleta, raiz, entrar, criar conta, falta pouco, obras, ajustes |
| `app-ios/Custta/Assets.xcassets`, `Info.plist`, `Custta.entitlements`, `GoogleService-Info.plist` | ícone, cores, configuração |
| `app-ios/Custta/PrivacyInfo.xcprivacy` | manifesto de privacidade |
| `app-ios/CusttaNucleo/Sources/CusttaNucleo/Cadastro.swift`, `Telas.swift`, `ErrosFirebase.swift`, `Sincronizador.swift` | regras do cadastro, das telas, códigos de erro e sincronização |
| `app-ios/CusttaTests/*.swift`, `app-ios/CusttaUITests/*.swift` | testes de unidade, de integração (emuladores) e de tela |
| `app-ios/ExportOptions.plist` | opções do envio ao TestFlight |
| `scripts/simulador-ios.mjs`, `scripts/cores-app-ios.mjs`, `tests/app-ios/cruzado.mjs` | simulador para os testes, catálogo de cores, conferência cruzada |
| `tests/app-ios.test.cjs`, `tests/workflow.test.cjs`, `tests/vetores.test.mjs` | guardas em Node |
| `.github/workflows/app-ios.yml`, `.github/workflows/app-ios-testflight.yml` | CI e envio ao TestFlight |
| `scripts/vetores-calc.mjs`, `tests/vetores/calc.json` | vetores do `cadastro.js` (Tarefa 3) |
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

`tests/app-ios.test.cjs` (as Tarefas 6, 10 e 13 acrescentam testes no fim deste arquivo):

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

`app-ios/Custta/CusttaApp.swift` (a Tarefa 11 troca este corpo pela tela de verdade):

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

`app-ios/Custta/Assets.xcassets/AccentColor.colorset/Contents.json` (a marca esmeralda; a tinta de verdade vem da `Paleta`, Tarefa 10):

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
- Produces: `destinoDoSimulador(): string` e `testarNoSimulador(alvos: string[], env?: Record<string,string>): Promise<void>` em `scripts/simulador-ios.mjs` (as Tarefas 6 e 13 usam); CLI `node scripts/simulador-ios.mjs` (imprime o destino) e `node scripts/simulador-ios.mjs --testar <alvo>... [--emuladores]`.

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

### Task 3: Regras do cadastro nos vetores e no núcleo

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
Expected: `tests/vetores/calc.json: 62 grupos, 636 casos` e 5 testes verdes.

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

### Task 4: Regras das telas e códigos de erro do Firebase

**Files:**
- Create: `app-ios/CusttaNucleo/Sources/CusttaNucleo/Telas.swift`
- Create: `app-ios/CusttaNucleo/Sources/CusttaNucleo/ErrosFirebase.swift`
- Test: `app-ios/CusttaNucleo/Tests/CusttaNucleoTests/TelasTests.swift`, `ErrosFirebaseTests.swift`

**Interfaces:**
- Consumes: `normalizaPerfil`, `validaSenha`, `PerfilCadastro`, `mensagemErroSocial`, `mensagemErroSenha` (Tarefa 3); `ordenadoEstavel`, `menorJS`, `moedaCurtaSemZero`, `numeroJS`, `orcamentoObra`, `Fase`, `Obra`, `erroEhTerminal` (Parte A).
- Produces: `public func emailParece(_:) -> Bool`; `public func validarEntrada(email:senha:) -> String?`; `public enum ResultadoCadastro { case ok(PerfilCadastro), falhou(campo: String, erro: String) }`; `public func validarCadastro(nome:sobrenome:email:senha:confirmacao:origem:origemDetalhe:) -> ResultadoCadastro`; `Fase.rotulo: String`; `public func obrasOrdenadas(_:) -> [Obra]`; `public func textoOrcamentoNaLista(_:) -> String`; `public func textoErroDeLeitura(_ codigo: String) -> String`; `public enum Nonce { static func gerar() -> String; static func sha256(_:) -> String }`; `public let dominioAuth, dominioFirestore, dominioApple, dominioGoogle: String`; `public func codigoDeErroDeConta(dominio:codigo:) -> String`; `public func codigoDeErroFirestore(dominio:codigo:) -> String`; `public func sessaoInvalida(_:) -> Bool`.

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
Expected: `Test run with 10 tests in 2 suites passed`. Os números das tabelas são conferidos contra as constantes dos próprios SDKs na Tarefa 7 (`ErrosDoSDKTests`), onde o Firebase e o GoogleSignIn já estão ligados.

- [ ] **Step 5: Commit**

```bash
git add app-ios/CusttaNucleo
git commit -m "feat: regras das telas de conta e códigos de erro do Firebase no núcleo" -m "Validação de entrar e de criar conta na ordem do auth.js, ordem e textos da lista de obras do app.js, nonce do login com a Apple e a tradução dos erros do Firebase iOS para os códigos do SDK JavaScript, para as mensagens e a fila serem as do site. Falta de rede nunca conta como sessão inválida."
```

---

### Task 5: Sincronizador

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

### Task 6: Camada Firebase do estado e testes contra os emuladores

**Files:**
- Create: `app-ios/Custta/Dados/BancoFirebase.swift`, `app-ios/Custta/Dados/TransporteFirebase.swift`, `app-ios/Custta/Dados/Sistema.swift`
- Create: `app-ios/CusttaTests/Emulador.swift`, `app-ios/CusttaTests/TransporteFirebaseTests.swift`, `app-ios/CusttaTests/BancoFirebaseTests.swift`
- Modify: `package.json` (script `test:app-ios:emuladores`), `tests/app-ios.test.cjs` (teste no fim)

**Interfaces:**
- Consumes: `TransporteDados`, `Cancelavel`, `Relogio`, `Instantaneo`, `ValorJSON.paraFoundation`, `ValorJSON(foundation:)`, `codigoDeErroFirestore`, `agoraEmMilissegundos` (núcleo); `scripts/simulador-ios.mjs` (Tarefa 2).
- Produces: `@MainActor final class BancoFirebase { static let chaveLimpeza; init(app: FirebaseApp, emulador: (host: String, porta: Int)?, preferencias: UserDefaults = .standard); func quandoPronto(_ uso: @escaping @MainActor (Firestore) -> Void); func aguardarPronto() async; func firestore() -> Firestore; var limpezaPendente: Bool; func marcarLimpeza(); func desmarcarLimpeza(); func limparCache() async throws }`; `@MainActor final class TransporteFirebase: TransporteDados { init(banco:); nonisolated static func valor(_: [String: Any]) -> ValorJSON?; nonisolated static func codigo(_: Error) -> String }` (documento com tipo fora do JSON chega como `aoFalhar("formato-desconhecido")`); `@MainActor final class RelogioDoSistema: Relogio`; `@MainActor @Observable final class MonitorDeRede { online: Bool; aoMudar: ((Bool) -> Void)?; init(forcarSemRede: Bool = false) }`; `@MainActor func controladorNoTopo() -> UIViewController?`. Nos testes: `let comEmuladores: Bool`, `struct NoEmulador` (suíte-mãe em série das suítes que dividem o `Emulador.banco`), `enum Emulador { static let projeto: String; static let app: FirebaseApp; static let banco: BancoFirebase; static func novaConta() async throws -> User }`, `@MainActor final class Bandeira { var ligada: Bool }`.

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
@MainActor final class Bandeira { var ligada = false }

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

- [ ] **Step 4: Rodar e ver passar**

Run: `npm run test:app-ios:emuladores && node --test tests/app-ios.test.cjs`
Expected: os 2 testes de `TransporteFirebaseTests` verdes (o log do Firestore mostra o `Permission denied` esperado do segundo), mais `ConversaoDoDocumentoTests` e `BancoFirebaseTests`, e as guardas verdes. Sem os emuladores (`xcodebuild test` comum, como na CI) os de `TransporteFirebaseTests` aparecem como pulados e os outros dois rodam.

- [ ] **Step 5: Commit**

```bash
git add app-ios/Custta/Dados app-ios/CusttaTests package.json tests/app-ios.test.cjs
git commit -m "feat: camada do Firestore do app nativo" -m "Transporte fino do Sincronizador sobre o Firestore: escuta com metadados de cache e gravação pendente, gravação do documento inteiro com _atualizado do servidor e espera da fila do SDK, retornos na fila principal. O teste contra o emulador prova que o documento volta igual, com o campo que só o site conhece, que 1500 vai como inteiro como no JavaScript e que as rules recusam chave nova. Documento com tipo que o JSON não tem falha a leitura em vez de virar null. A limpeza do cache segue o cloud.js: marca persistida, nada lê ou grava durante a limpeza e a próxima abertura termina uma limpeza interrompida; a marca que sobra fica anotada no registro do sistema. Relógio, rede e janela do sistema também entram aqui."
```

---

### Task 7: Serviço de conta

**Files:**
- Create: `app-ios/Custta/Conta/ServicoConta.swift`, `app-ios/Custta/Dados/ContaFirebase.swift`
- Create: `app-ios/Custta/Falsos/ContaFalsa.swift`, `app-ios/Custta/Falsos/TransporteFalsoApp.swift`
- Test: `app-ios/CusttaTests/ContaFirebaseTests.swift`, `app-ios/CusttaTests/ErrosDoSDKTests.swift`

**Interfaces:**
- Consumes: `BancoFirebase` (`aguardarPronto`, `firestore`, `marcarLimpeza`, `desmarcarLimpeza`, `limparCache`, `limpezaPendente`), `TransporteFirebase`, `controladorNoTopo`, `Emulador` (Tarefa 6); do núcleo `PerfilCadastro`, `ValorJSON`, `codigoDeErroDeConta`, `codigoDeErroFirestore`, `dominioAuth`, `dominioFirestore`, `dominioApple`, `dominioGoogle`, `sessaoInvalida`, `mensagemErroSenha`; dos SDKs `Auth`, `User`, `OAuthProvider`, `GoogleAuthProvider`, `AuthErrorCode`, `FirestoreErrorCode`, `GIDSignIn`, `GIDSignInError` e `ASAuthorizationError`.
- Produces: `struct Usuario { uid, email: String; emailVerificado: Bool; provedores: [String]; nomeExibicao: String; temSenha, contaSocial, contaApple, precisaConfirmarEmail: Bool }`; `struct CredencialApple { idToken, nonce: String; nomeCompleto: PersonNameComponents? }`; `struct ErroConta: Error, Equatable { codigo: String }`; `@MainActor protocol ServicoConta` (assinaturas no código abaixo); `@MainActor final class ContaFirebase: ServicoConta { init(app:banco:online:); nonisolated static func erro(_:) -> ErroConta }`; em Debug: `ContaFalsa(inicial: String)` (cenários `nenhuma`, `senha`, `senha-nao-confirmada`, `senha-confirma-ao-conferir`, `apple-sem-perfil`, `google-sem-perfil`, `google-perfil-concorrente`) com `static let senhaCerta = "Casa2026x"`, `TransporteFalsoApp(dados:semRede:falhaDeLeitura:)` com `gravacoes: Int`, `DadosDeExemplo.blob`.

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
}
#endif
```

- [ ] **Step 4: Rodar e ver passar**

Run: `npm run test:app-ios:emuladores`
Expected: `TransporteFirebaseTests` (2) e `ContaFirebaseTests` (5, inclusive sair, entrar com outra conta e gravar e ler do servidor pelo mesmo `BancoFirebase`) verdes, e `ErrosDoSDKTests` (4), que também roda sem emulador. Rode também `xcodebuild test -project app-ios/Custta.xcodeproj -scheme Custta -destination "$(node scripts/simulador-ios.mjs)" -skipMacroValidation -skipPackagePluginValidation -onlyUsePackageVersionsFromResolvedFile CODE_SIGNING_ALLOWED=NO -only-testing:CusttaTests`: compila e os de emulador aparecem pulados.

- [ ] **Step 5: Commit**

```bash
git add app-ios/Custta/Conta app-ios/Custta/Dados/ContaFirebase.swift app-ios/Custta/Falsos app-ios/CusttaTests/ContaFirebaseTests.swift
git commit -m "feat: conta do app nativo no Firebase Auth" -m "E-mail e senha, Apple com nonce, Google com o client iOS, criar conta com o perfil que as rules aceitam, falta pouco para conta social sem perfil, esqueci a senha, confirmação de e-mail com a conta conferida depois do reload, verificação de sessão que nunca desloga por falta de rede (e recomeça a contar na troca de conta) e saída na ordem do cloud.js: marca a limpeza, sai, esquece o Google e apaga o cache. Erros chegam com os códigos do site. Conta e transporte falsos (só Debug) servem aos testes; contra o emulador, o cadastro grava o perfil aceito pelas rules e o login Google sem perfil fica pendente até completar."
```

---

### Task 8: Modelo das telas e composição

**Files:**
- Create: `app-ios/Custta/Estado/ModeloApp.swift`, `app-ios/Custta/Composicao.swift`, `app-ios/Custta/Falsos/MontarFalso.swift`
- Create: `app-ios/CusttaTests/Auxiliares.swift`
- Modify: `app-ios/CusttaTests/Emulador.swift` (o projeto dos emuladores passa a vir do `Composicao`)
- Test: `app-ios/CusttaTests/ModeloAppTests.swift`

**Interfaces:**
- Consumes: `ServicoConta`, `ContaFirebase`, `ContaFalsa`, `TransporteFalsoApp`, `DadosDeExemplo` (Tarefa 7); `BancoFirebase`, `TransporteFirebase`, `RelogioDoSistema`, `MonitorDeRede` e, nos testes, `Bandeira` (Tarefa 6); `Sincronizador`, `validarEntrada`, `emailParece`, `aparadoJS`, `mensagemErroSenha`, `mensagemErroSocial`, `PerfilCadastro` (núcleo).
- Produces: `@MainActor @Observable final class ModeloApp { enum Fase: Equatable { carregando, entrada, faltaPouco(Usuario), principal(Usuario) }; fase; mensagemEntrada: String?; aviso: String?; nome: String?; sincronizador; rede; conta; usuario: Usuario? /* derivado da fase, observável */; init(conta:sincronizador:rede:); entrar(email:senha:) async -> String?; entrarComApple(_:) async -> String?; entrarComGoogle() async -> String?; criarConta(email:senha:perfil:) async -> String?; redefinirSenha(email:) async -> String; completarPerfil(_:) async -> String?; sair() async -> String? /* espera a fila, confere a conta, para a escuta e só então sai */; reenviarVerificacao() async -> String; conferirVerificacao() async -> String?; voltouParaFrente() async; tentarDeNovo(); avisar(_:) }`; `@MainActor enum Composicao { static let projetoDosEmuladores; static func montar(ambiente:) -> ModeloApp; static func configurarFirebase(emuladores:) -> FirebaseApp; static func montarFalso(_:) -> ModeloApp /* Debug */ }`. Nos testes: `ate(_:) async`, `Desfecho` (espera limitada de uma operação), `ModeloApp.Fase.ehPrincipal`, `ehFaltaPouco`.

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
        #expect(await m.redefinirSenha(email: "x") == "Digite seu e-mail.")
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

- [ ] **Step 2: Rodar e ver falhar**

Run: `xcodebuild test -project app-ios/Custta.xcodeproj -scheme Custta -destination "$(node scripts/simulador-ios.mjs)" -skipMacroValidation -skipPackagePluginValidation -onlyUsePackageVersionsFromResolvedFile CODE_SIGNING_ALLOWED=NO -only-testing:CusttaTests`
Expected: FAIL na compilação: `cannot find 'ModeloApp' in scope`.

- [ ] **Step 3: Implementar**

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
            if expirou { mensagemEntrada = "Sua sessão expirou por segurança. Entre de novo pra continuar." }
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

    /// Texto para a tela de esqueci a senha (sucesso ou erro).
    func redefinirSenha(email: String) async -> String {
        let e = aparadoJS(email)
        guard emailParece(e) else { return "Digite seu e-mail." }
        do { try await conta.redefinirSenha(email: e); return "Enviamos um link de redefinição pro seu e-mail." }
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
            return try await conta.reenviarVerificacao() ? "Link reenviado. Confira também a caixa de spam." : "E-mail já confirmado."
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

`app-ios/Custta/Falsos/MontarFalso.swift`:

```swift
#if DEBUG
import Foundation
import CusttaNucleo

/* Monta o app com os serviços falsos (CUSTTA_SERVICOS=falsos), para os testes de tela. Só Debug.
   Variáveis que o teste passa ao abrir o app:
   CUSTTA_CONTA   conta inicial da ContaFalsa (nenhuma, senha, senha-nao-confirmada, apple-sem-perfil,
                  google-sem-perfil, google-perfil-concorrente)
   CUSTTA_DADOS   exemplo | vazio
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
        let transporte = TransporteFalsoApp(dados: ambiente["CUSTTA_DADOS"] == "vazio" ? nil : DadosDeExemplo.blob,
                                            semRede: semRede, falhaDeLeitura: falha)
        let rede = MonitorDeRede(forcarSemRede: semRede)
        let sincronizador = Sincronizador(transporte: transporte, relogio: RelogioDoSistema(), online: !semRede)
        return ModeloApp(conta: conta, sincronizador: sincronizador, rede: rede)
    }
}
#endif
```

Com o `Composicao` no lugar, troque no `app-ios/CusttaTests/Emulador.swift` a linha `static let projeto = "demo-custta-phase2"` por `static let projeto = Composicao.projetoDosEmuladores` (um lugar só para o projeto dos emuladores).

- [ ] **Step 4: Rodar e ver passar**

Run: `xcodebuild test -project app-ios/Custta.xcodeproj -scheme Custta -destination "$(node scripts/simulador-ios.mjs)" -skipMacroValidation -skipPackagePluginValidation -onlyUsePackageVersionsFromResolvedFile CODE_SIGNING_ALLOWED=NO -only-testing:CusttaTests`
Expected: `ModeloAppTests` com 12 testes verdes (a abertura sem gravar roda nos três cenários), `appEnxergaONucleo`, `ConversaoDoDocumentoTests`, `BancoFirebaseTests` e `ErrosDoSDKTests` verdes, e os de emulador pulados.

Run: `npm run test:app-ios:emuladores`
Expected: os mesmos, mais `TransporteFirebaseTests` (2) e `ContaFirebaseTests` (5), todos verdes.

- [ ] **Step 5: Commit**

```bash
git add app-ios/Custta/Estado app-ios/Custta/Composicao.swift app-ios/Custta/Falsos/MontarFalso.swift app-ios/CusttaTests
git commit -m "feat: modelo das telas e composição do app nativo" -m "O ModeloApp decide a tela pela conta (entrada, falta pouco ou app), explica a sessão expirada só quando a pessoa não saiu de propósito, segue para o app quando outro aparelho já gravou o perfil e só sai da conta depois que a fila sobe, pedindo internet quando falta; a escuta para antes do signOut, como no site. A conta da tela vem da fase, que é observável: o e-mail confirmado tira o aviso sem reabrir o app. A composição monta o Firebase de produção e, só em Debug, os emuladores ou os serviços falsos dos testes de tela."
```

---

### Task 9: Portão de desenho (Croqui e Giovani, sem código)

**Files:**
- Nenhum arquivo do repositório. Mockups em `~/Documents/custta-mockups/app-nativo-etapa1/` (fora do repositório, como manda a seção 8 do spec).
- Modify (só o registro, pelo Orquestrador): este plano, seção "Resultado do portão de desenho" no fim.

**Interfaces:**
- Consumes: o PWA de hoje (print de cada tela, nos dois temas e nas duas peles), o esqueleto das Tarefas 10 e 11 (fluxos e textos validados), a lista "Referências que faltam" do topo, `PRODUCT.md`, a decisão de visual e a seção 8 do spec.
- Produces: o registro aprovado pelo Giovani que a reescrita do PR 4 segue (Step 4).

Nenhum código de tela do PR 4 começa antes deste portão. As Tarefas 1 a 8 e 13 a 15 não dependem dele.

- [ ] **Step 1: Croqui levanta as referências que faltam**

Com o Giovani, buscar as seis referências da seção "Referências que faltam". Registrar no mockup de onde veio cada escolha.

- [ ] **Step 2: Croqui desenha as telas da etapa 1 ao lado do PWA**

Entrar (com o título escrito à mão), criar conta, falta pouco (Apple e Google), esqueci a senha, lista de obras (com obras, vazia, "sem conexão e sem nada no aparelho", "não sincronizou" e aviso de e-mail) e Ajustes. Cada tela ao lado do print do PWA, em escuro e claro, esmeralda e azul, no tamanho de letra padrão e no maior de acessibilidade, com a obra de nome longo e total alto (`DadosDeExemplo`, obra o4).

- [ ] **Step 3: Croqui mostra as três doses de vidro**

A tela de obras e a de entrar em três níveis: vidro do PWA, mais vidro e vidro no máximo (spec, "Decisões > Visual"), sempre com contraste de 4,5:1 medido no pior ponto da aurora, sem vidro dentro de vidro e com o número principal legível.

- [ ] **Step 4: Giovani aprova e o Orquestrador registra**

Pronto quando o Giovani aprovar por escrito (mensagem ao Orquestrador) e o Orquestrador acrescentar ao fim deste plano a seção "Resultado do portão de desenho" com:

1. o caminho dos mockups aprovados;
2. a fidelidade ao PWA, tela a tela: o que fica igual ao print e o que muda, com o motivo;
3. a dose de vidro escolhida;
4. a lista "onde o nativo não pode ou não deve ficar igual ao PWA": o comportamento do sistema que o PWA imita (barra de abas, folhas, teclado, voltar pela borda) e o que a letra grande obriga a mudar;
5. os tokens aprovados: cores (os valores de `CORES` em `scripts/cores-app-ios.mjs`), vidro e aurora;
6. os textos que mudam em relação ao esqueleto da Tarefa 11 e os ícones das fases;
7. como a cápsula de abas aparece na etapa 1, sem o botão + (que chega com a escrita, na etapa 2);
8. se a variante de alto contraste entra agora ou na etapa 6 (recomendação: etapa 6, a de acessibilidade completa).

Com o registro, o Prumo reescreve o PR 4: as Tarefas 10 a 12 com o mockup aprovado e as tarefas novas dos componentes de identidade (fundo com aurora e globo, superfície de vidro, cápsula de abas com o +, título escrito à mão), cada uma com teste de Reduzir movimento, tema claro, letra grande e da pausa na rolagem e fora da tela. Só então o Forja começa o PR 4.

---

### Task 10: Cores por tokens (esqueleto funcional validado, a refazer com o mockup aprovado)

> **Esqueleto.** Sobrevive à troca de visual: a mecânica dos tokens (tabela → catálogo gerado, `Paleta`, guardas de cor solta e de catálogo em dia, `CoresTests`). Muda com o mockup: os valores e a lista de tokens, que ganha os de vidro e os da aurora.

**Files:**
- Create: `scripts/cores-app-ios.mjs`
- Create (gerados): `app-ios/Custta/Assets.xcassets/Esmeralda/` e `app-ios/Custta/Assets.xcassets/Azul/` (um `Contents.json` de pasta e 11 color sets cada)
- Modify (gerados): `app-ios/Custta/Assets.xcassets/AccentColor.colorset/Contents.json`, `app-ios/Custta/Assets.xcassets/FundoAbertura.colorset/Contents.json`
- Create: `app-ios/Custta/Telas/Paleta.swift`
- Test: `app-ios/CusttaTests/CoresTests.swift`
- Modify: `tests/app-ios.test.cjs` (dois testes no fim)

**Interfaces:**
- Consumes: catálogo da Tarefa 1; valores aprovados no portão (Tarefa 9).
- Produces: em Swift, `enum Pele: String, CaseIterable { case esmeralda = "Esmeralda", azul = "Azul" }`; `enum Token: String, CaseIterable` com `fundo`, `superficie`, `linha`, `texto`, `textoSecundario`, `marca`, `destaque`, `positivo`, `alerta`, `negativo`, `sobreMarca`; `struct Paleta: Equatable { var pele: Pele; static func nome(_ token: Token, _ pele: Pele) -> String; func cor(_ token: Token) -> Color }`; `EnvironmentValues.paleta: Paleta`; `View.botaoPrincipal(_ paleta: Paleta) -> some View`; `enum Aparencia { static let chaveTema = "custta.tema"; static let chavePele = "custta.pele"; static func esquema(_:) -> ColorScheme; static func pele(_:) -> Pele }`. Em Node, `scripts/cores-app-ios.mjs` exporta `CORES`, `colorSet(valores)` e `arquivos()`.

- [ ] **Step 1: Escrever os testes que falham**

`app-ios/CusttaTests/CoresTests.swift`:

```swift
import Testing
import UIKit
@testable import Custta

/* Cores só por tokens: cada token existe nas duas peles, com variante clara e escura. */
@MainActor
struct CoresTests {
    @Test(arguments: Pele.allCases)
    func todoTokenExisteNaPele(_ pele: Pele) {
        for token in Token.allCases {
            let nome = Paleta.nome(token, pele)
            let cor = UIColor(named: nome, in: .main, compatibleWith: nil)
            let claro = cor?.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
            let escuro = cor?.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark))
            #expect(claro != nil && escuro != nil, "\(nome) sem cor no catálogo")
            #expect(claro != escuro, "\(nome) precisa de variante clara e escura")
        }
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
  const paleta = ler('app-ios/Custta/Telas/Paleta.swift');
  const enumToken = paleta.slice(paleta.indexOf('enum Token'), paleta.indexOf('}', paleta.indexOf('enum Token')));
  const tokens = [...enumToken.matchAll(/case \w+ = "(\w+)"/g)].map(m => m[1]).sort();
  const tabela = ler('scripts/cores-app-ios.mjs');
  for(const pele of ['Esmeralda', 'Azul']){
    const bloco = tabela.slice(tabela.indexOf(`${pele}: {`), tabela.indexOf('}', tabela.indexOf(`${pele}: {`)));
    assert.deepEqual([...bloco.matchAll(/^\s+(\w+): \['/gm)].map(m => m[1]).sort(), tokens, `tokens da pele ${pele}`);
  }
});
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `node --test tests/app-ios.test.cjs`
Expected: FAIL no teste do catálogo: `Cannot find module '…/scripts/cores-app-ios.mjs'`.

Run: `xcodebuild test -project app-ios/Custta.xcodeproj -scheme Custta -destination "$(node scripts/simulador-ios.mjs)" -skipMacroValidation -skipPackagePluginValidation -onlyUsePackageVersionsFromResolvedFile CODE_SIGNING_ALLOWED=NO -only-testing:CusttaTests/CoresTests`
Expected: FAIL na compilação: `cannot find type 'Pele' in scope`.

- [ ] **Step 3: Escrever o gerador e a paleta**

`scripts/cores-app-ios.mjs` (se o portão da Tarefa 9 aprovou outros valores, eles entram na tabela `CORES`; os nomes dos tokens não mudam):

```js
/* Cores do app nativo por token (spec, seção 8: "cores só por tokens"). A tabela abaixo é a
   fonte e o script grava os color sets do catálogo app-ios/Custta/Assets.xcassets: um por token
   e pele, com variante clara e escura, mais a cor de destaque do sistema e o fundo da abertura.
   Valores de partida: os do styles.css do site nos quatro combos (escuro e claro, esmeralda e
   azul); o portão de desenho de cada etapa troca os valores aqui, nunca no catálogo à mão.
   tests/app-ios.test.cjs roda --conferir.

   Uso: node scripts/cores-app-ios.mjs            grava o catálogo
        node scripts/cores-app-ios.mjs --conferir  só confere (sai com 1 se algo difere) */
import { mkdirSync, writeFileSync, readFileSync, existsSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const CATALOGO = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../app-ios/Custta/Assets.xcassets');

/* token: [escuro, claro], por pele. Origem no styles.css: :root, [data-theme="light"],
   [data-skin="azul"] e os dois juntos. */
export const CORES = {
  Esmeralda: {
    Fundo: ['#04100C', '#EDF5F1'],            // --bg
    Superficie: ['#0C241D', '#FFFFFF'],       // --surface-solid
    Linha: ['#1B3D33', '#C6DCD1'],            // --line
    Texto: ['#EAFFF6', '#13261E'],            // --text
    TextoSecundario: ['#86AA9A', '#4D685C'],  // --muted
    Marca: ['#14B39A', '#0B7A68'],            // --brand
    Destaque: ['#3AD17E', '#177A4A'],         // --accent
    Positivo: ['#35D68A', '#0E7A41'],         // --profit
    Alerta: ['#E0A83A', '#8A5A06'],           // --warn
    Negativo: ['#FB7185', '#C22E55'],         // --red
    SobreMarca: ['#04100C', '#FFFFFF'],       // --btn-ink
  },
  Azul: {
    Fundo: ['#070C18', '#EEF2F9'],
    Superficie: ['#111A2E', '#FFFFFF'],
    Linha: ['#243250', '#CDD8E8'],
    Texto: ['#EEF4FB', '#16233C'],
    TextoSecundario: ['#A3B4CA', '#556685'],
    Marca: ['#5B8CFF', '#3560CF'],
    Destaque: ['#A78BFA', '#6D4FC9'],
    Positivo: ['#4ADE80', '#0E7A41'],
    Alerta: ['#FBBF24', '#8A5A06'],
    Negativo: ['#FB7185', '#C22E55'],
    SobreMarca: ['#070C18', '#FFFFFF'],
  },
};

const info = { author: 'xcode', version: 1 };
const componente = hex => ({ 'color-space': 'srgb',
  components: { red: '0x' + hex.slice(1, 3), green: '0x' + hex.slice(3, 5), blue: '0x' + hex.slice(5, 7), alpha: '1.000' } });

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

Run: `node scripts/cores-app-ios.mjs`
Expected: `cores gravadas em app-ios/Custta/Assets.xcassets`; `git status` mostra as pastas `Esmeralda/` e `Azul/` novas e o `AccentColor` e o `FundoAbertura` reformatados (mesmos valores).

`app-ios/Custta/Telas/Paleta.swift`:

```swift
import SwiftUI

/* Cores só por tokens (spec, seção 8): cada token existe no Assets.xcassets para as duas peles
   (Esmeralda e Azul), com variante clara e escura, gerado por scripts/cores-app-ios.mjs.
   Nenhuma cor solta nas telas (componentes RGB ou cor nomeada do sistema): tests/app-ios.test.cjs confere. */

enum Pele: String, CaseIterable {
    case esmeralda = "Esmeralda"
    case azul = "Azul"
}

enum Token: String, CaseIterable {
    case fundo = "Fundo"
    case superficie = "Superficie"
    case linha = "Linha"
    case texto = "Texto"
    case textoSecundario = "TextoSecundario"
    case marca = "Marca"
    case destaque = "Destaque"
    case positivo = "Positivo"
    case alerta = "Alerta"
    case negativo = "Negativo"
    /// Texto sobre a cor da marca (o --btn-ink do site): escuro no tema escuro, branco no claro.
    case sobreMarca = "SobreMarca"
}

struct Paleta: Equatable {
    var pele: Pele = .esmeralda

    /// Nome no catálogo: "Esmeralda/Marca".
    static func nome(_ token: Token, _ pele: Pele) -> String { "\(pele.rawValue)/\(token.rawValue)" }

    func cor(_ token: Token) -> Color { Color(Self.nome(token, pele)) }
}

extension EnvironmentValues {
    @Entry var paleta = Paleta()
}

extension View {
    /// Botão principal: fundo da marca e texto com contraste nos quatro combos.
    func botaoPrincipal(_ paleta: Paleta) -> some View {
        buttonStyle(.borderedProminent).foregroundStyle(paleta.cor(.sobreMarca))
    }
}

/// Aparência deste aparelho: escuro e esmeralda por padrão (a tela de Ajustes da etapa 5 grava as duas chaves;
/// os testes de tela passam `-custta.tema claro -custta.pele azul`).
enum Aparencia {
    static let chaveTema = "custta.tema"
    static let chavePele = "custta.pele"
    static func esquema(_ tema: String) -> ColorScheme { tema == "claro" ? .light : .dark }
    static func pele(_ valor: String) -> Pele { valor == "azul" ? .azul : .esmeralda }
}
```

- [ ] **Step 4: Rodar e ver passar**

Run: `node --test tests/app-ios.test.cjs && node scripts/cores-app-ios.mjs --conferir`
Expected: todos os testes verdes e `ok - catálogo de cores em dia`.

Run: `xcodebuild test -project app-ios/Custta.xcodeproj -scheme Custta -destination "$(node scripts/simulador-ios.mjs)" -skipMacroValidation -skipPackagePluginValidation -onlyUsePackageVersionsFromResolvedFile CODE_SIGNING_ALLOWED=NO -only-testing:CusttaTests/CoresTests`
Expected: `todoTokenExisteNaPele` verde nos 2 casos (Esmeralda e Azul).

- [ ] **Step 5: Commit**

```bash
git add scripts/cores-app-ios.mjs app-ios/Custta/Assets.xcassets app-ios/Custta/Telas/Paleta.swift app-ios/CusttaTests/CoresTests.swift tests/app-ios.test.cjs
git commit -m "feat: cores do app nativo por tokens" -m "Onze tokens nas peles esmeralda e azul, com variante clara e escura, gerados por scripts/cores-app-ios.mjs a partir dos valores do styles.css (ou dos aprovados no portão de desenho). O texto dos botões principais usa o --btn-ink do site, que dá contraste nos quatro combos. A guarda em Node barra cor solta no código das telas e catálogo defasado em relação à tabela."
```

---

### Task 11: Telas da etapa 1 (esqueleto funcional validado, a refazer com o mockup aprovado)

> **Esqueleto.** Sobrevivem à troca de visual os testes de fluxo (`EntradaUITests`, `CriarContaUITests`, `FaltaPoucoUITests`, `ObrasUITests` e `AjustesUITests`) e os identificadores e valores de acessibilidade que eles usam, que a reescrita mantém. São do visual antigo: as telas montadas com `Form`, `List` e `TabView` do sistema; o texto "custta." no lugar do título escrito à mão; o cabeçalho "4 obras" que `testListaNaOrdemDoSiteComOsTotaisDoNucleo` procura; e a navegação pela barra de abas do sistema (`app.tabBars`) que `AjustesUITests` usa, que passa a ir por identificador quando a cápsula de abas entrar.

**Files:**
- Modify: `app-ios/Custta/CusttaApp.swift`
- Create: `app-ios/Custta/Telas/RaizView.swift`, `EntradaView.swift`, `CriarContaView.swift`, `FaltaPoucoView.swift`, `PrincipalView.swift`, `AjustesView.swift`
- Create: `app-ios/Custta/Assets.xcassets/LogoGoogle.imageset/Contents.json` e a cópia `app-ios/Custta/Assets.xcassets/LogoGoogle.imageset/google-g.svg` (do `google-g.svg` da raiz, o mesmo do botão do site)
- Create: `app-ios/CusttaUITests/Abrir.swift`, `EntradaUITests.swift`, `CriarContaUITests.swift`, `FaltaPoucoUITests.swift`, `ObrasUITests.swift`, `AjustesUITests.swift`
- Delete: `app-ios/CusttaUITests/AberturaUITests.swift` (a abertura de verdade é a tela de entrar, coberta por `EntradaUITests`)

**Interfaces:**
- Consumes: `ModeloApp` (`fase`, `mensagemEntrada`, `aviso`, `nome`, `usuario`, `sincronizador`, `entrar`, `entrarComApple`, `entrarComGoogle`, `criarConta`, `redefinirSenha`, `completarPerfil`, `sair`, `reenviarVerificacao`, `conferirVerificacao`, `voltouParaFrente`, `tentarDeNovo`, `avisar`) e `Composicao.montar()` (Tarefa 8); `Paleta`, `botaoPrincipal`, `Aparencia` (Tarefa 10); `ContaFirebase.erro` e `CredencialApple` (Tarefa 7); do núcleo, `Nonce`, `validarCadastro`, `validaSenha`, `origens`, `normalizaPerfil`, `nomeDoGoogle`, `mensagemErroSocial`, `obrasOrdenadas`, `textoOrcamentoNaLista`, `Fase.rotulo`, `indicador`, `totalBruto`, `orcamentoObra`, `mesesDeObra`, `fmtMeses`, `moeda`, `moedaCurta`, `dataLocalISO`, `textoErroDeLeitura`.
- Produces: identificadores de acessibilidade que os testes usam — `email`, `senha`, `entrar`, `mensagemEntrada`, `esqueciSenha`, `emailRedefinir`, `enviarLink`, `mensagemRedefinir`, `entrarComApple`, `entrarComGoogle`, `irParaCriarConta`, `nome`, `sobrenome`, `emailCadastro`, `senhaCadastro`, `confirmacao`, `checklistSenha`, `origem`, `origemDetalhe`, `mensagemCadastro`, `criarConta`, `textoFaltaPouco`, `comecarAUsar`, `usarOutraConta`, `mensagemFaltaPouco`, `obra-<id>`, `obrasVazio`, `obrasErroLeitura`, `tentarLerDeNovo`, `indicadorSincronizacao`, `avisoEmail`, `reenviarLink`, `jaConfirmei`, `mensagemAvisoEmail`, `nomeConta`, `emailConta`, `sair`, `aviso`; nos testes de tela, `abrirApp(conta:dados:rede:leitura:argumentos:) -> XCUIApplication`, `XCUIApplication.elemento(_:)` e `XCUIApplication.digitar(_:em:seguro:)` (Tarefas 12 e 13).

Textos e valores seguem o registro do portão (Tarefa 9); os trechos abaixo são o esqueleto validado no protótipo, com os textos do site.

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

    @MainActor func testEsqueciASenha() {
        let app = abrirApp()
        XCTAssertTrue(app.buttons["esqueciSenha"].waitForExistence(timeout: 10))
        app.buttons["esqueciSenha"].tap()
        app.digitar("ninguem@exemplo.com", em: "emailRedefinir")
        app.buttons["enviarLink"].tap()
        XCTAssertTrue(app.staticTexts["E-mail ou senha incorretos."].waitForExistence(timeout: 5))
        let campo = app.textFields["emailRedefinir"]
        campo.tap()
        campo.press(forDuration: 1.2)
        if app.menuItems["Selecionar Tudo"].waitForExistence(timeout: 2) { app.menuItems["Selecionar Tudo"].tap() }
        else if app.menuItems["Select All"].waitForExistence(timeout: 1) { app.menuItems["Select All"].tap() }
        campo.typeText("giovani@exemplo.com")
        app.buttons["enviarLink"].tap()
        XCTAssertTrue(app.staticTexts["Enviamos um link de redefinição pro seu e-mail."].waitForExistence(timeout: 5))
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
        let aba = app.tabBars.buttons["Ajustes"]
        XCTAssertTrue(aba.waitForExistence(timeout: 10))
        aba.tap()
        XCTAssertTrue(app.buttons["sair"].waitForExistence(timeout: 5))
        return app
    }

    @MainActor func testContaESair() {
        let app = abrirAjustes()
        XCTAssertTrue(app.staticTexts["nomeConta"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["nomeConta"].label, "Giovani Stuchi")
        XCTAssertEqual(app.staticTexts["emailConta"].value as? String, "giovani@exemplo.com")
        app.buttons["sair"].tap()
        app.buttons["Sair"].firstMatch.tap()
        XCTAssertTrue(app.textFields["email"].waitForExistence(timeout: 10), "voltou para a tela de entrar")
    }

    @MainActor func testSairSemInternetPedeParaConectar() {
        let app = abrirAjustes(rede: "offline")
        app.buttons["sair"].tap()
        app.buttons["Sair"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Conecte à internet e aguarde a sincronização antes de sair."].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["sair"].exists, "continua em Ajustes")
    }
}
```

Apague `app-ios/CusttaUITests/AberturaUITests.swift`.

- [ ] **Step 2: Rodar e ver falhar**

Run: `xcodebuild test -project app-ios/Custta.xcodeproj -scheme Custta -destination "$(node scripts/simulador-ios.mjs)" -skipMacroValidation -skipPackagePluginValidation -onlyUsePackageVersionsFromResolvedFile CODE_SIGNING_ALLOWED=NO -only-testing:CusttaUITests`
Expected: FAIL; os 16 testes falham esperando o primeiro elemento (`entrar`, `email`, `obra-o3`…), porque o app ainda mostra só o texto da Tarefa 1.

- [ ] **Step 3: Implementar as telas**

`app-ios/Custta/CusttaApp.swift` (troque o corpo da Tarefa 1):

```swift
import SwiftUI

@main
struct CusttaApp: App {
    /// Nos testes de unidade o app só hospeda o pacote de testes: nada de Firebase de produção.
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
            }
        }
    }
}
```

`app-ios/Custta/Telas/RaizView.swift`:

```swift
import SwiftUI
import GoogleSignIn

/// Escolhe a tela pela fase da conta e aplica a aparência deste aparelho.
struct RaizView: View {
    @Environment(ModeloApp.self) private var modelo
    @AppStorage(Aparencia.chaveTema) private var tema = "escuro"
    @AppStorage(Aparencia.chavePele) private var pele = "esmeralda"

    var body: some View {
        let paleta = Paleta(pele: Aparencia.pele(pele))
        Group {
            switch modelo.fase {
            case .carregando:
                ProgressView()
                    .accessibilityLabel("Carregando")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(paleta.cor(.fundo))
            case .entrada:
                EntradaView()
            case .faltaPouco(let usuario):
                FaltaPoucoView(usuario: usuario)
            case .principal:
                PrincipalView()
            }
        }
        // O aviso fica por cima de todas as telas; vem antes do .environment para receber a mesma paleta.
        .overlay(alignment: .top) { AvisoView() }
        .environment(\.paleta, paleta)
        .tint(paleta.cor(.marca))
        .preferredColorScheme(Aparencia.esquema(tema))
        .onOpenURL { url in GIDSignIn.sharedInstance.handle(url) }
    }
}

/// O toast do site: texto curto no topo, some sozinho.
struct AvisoView: View {
    @Environment(ModeloApp.self) private var modelo
    @Environment(\.paleta) private var paleta

    var body: some View {
        if let aviso = modelo.aviso {
            Text(aviso)
                .font(.subheadline)
                .foregroundStyle(paleta.cor(.texto))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .glassEffect()
                .padding(.horizontal, 16)
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

/// Tela de entrar: Apple acima do Google (Guideline 4.8), e-mail e senha, esqueci a senha e criar conta.
struct EntradaView: View {
    @Environment(ModeloApp.self) private var modelo
    @Environment(\.paleta) private var paleta
    @Environment(\.colorScheme) private var esquema
    @State private var email = ""
    @State private var senha = ""
    @State private var mensagem: String?
    @State private var entrando = false
    @State private var nonce = ""
    @State private var esqueciAberto = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("custta.")
                            .font(.largeTitle.weight(.heavy))
                            .foregroundStyle(paleta.cor(.marca))
                            .accessibilityLabel("Custta")
                            .accessibilityAddTraits(.isHeader)
                        Text("Controle os custos das suas obras")
                            .font(.title3)
                            .foregroundStyle(paleta.cor(.textoSecundario))
                    }
                    .listRowBackground(Color.clear)
                }

                Section {
                    SignInWithAppleButton(.continue) { pedido in
                        nonce = Nonce.gerar()
                        pedido.requestedScopes = [.fullName, .email]
                        pedido.nonce = Nonce.sha256(nonce)
                    } onCompletion: { resultado in
                        Task { await terminarApple(resultado) }
                    }
                    .signInWithAppleButtonStyle(esquema == .dark ? .white : .black)
                    .frame(minHeight: 50)
                    .disabled(entrando)
                    .accessibilityIdentifier("entrarComApple")

                    Button {
                        Task { await rodar { await modelo.entrarComGoogle() } }
                    } label: {
                        Label("Continuar com Google", image: "LogoGoogle")
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .disabled(entrando)
                    .accessibilityIdentifier("entrarComGoogle")
                }

                Section {
                    TextField("E-mail", text: $email)
                        .textContentType(.username)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .accessibilityIdentifier("email")
                    SecureField("Senha", text: $senha)
                        .textContentType(.password)
                        .accessibilityIdentifier("senha")
                } header: {
                    Text("Ou entre com e-mail").foregroundStyle(paleta.cor(.textoSecundario))
                }

                if let mensagem {
                    Section {
                        Text(mensagem)
                            .foregroundStyle(paleta.cor(.negativo))
                            .accessibilityIdentifier("mensagemEntrada")
                    }
                }

                Section {
                    Button {
                        Task { await rodar { await modelo.entrar(email: email, senha: senha) } }
                    } label: {
                        Text(entrando ? "Entrando…" : "Entrar")
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .botaoPrincipal(paleta)
                    .disabled(entrando)
                    .accessibilityIdentifier("entrar")

                    Button("Esqueci minha senha") { esqueciAberto = true }
                        .frame(minHeight: 44)
                        .accessibilityIdentifier("esqueciSenha")
                }

                Section {
                    NavigationLink("Criar conta") { CriarContaView() }
                        .frame(minHeight: 44)
                        .accessibilityIdentifier("irParaCriarConta")
                    Link("Política de Privacidade", destination: URL(string: "https://custta.com.br/privacidade.html")!)
                        .frame(minHeight: 44)
                }
            }
            .scrollContentBackground(.hidden)
            .background(paleta.cor(.fundo))
            .sheet(isPresented: $esqueciAberto) { EsqueciSenhaView(emailInicial: email) }
            .onAppear { mensagem = modelo.mensagemEntrada }
        }
    }

    /// Um login por vez: os botões travam até o atual voltar.
    private func rodar(_ acao: () async -> String?) async {
        entrando = true
        mensagem = nil
        mensagem = await acao()
        entrando = false
    }

    private func terminarApple(_ resultado: Result<ASAuthorization, Error>) async {
        switch resultado {
        case .success(let autorizacao):
            guard let c = autorizacao.credential as? ASAuthorizationAppleIDCredential,
                  let dados = c.identityToken, let token = String(data: dados, encoding: .utf8) else {
                mensagem = mensagemErroSocial(codigo: "auth/invalid-credential", provedor: "apple.com")
                return
            }
            await rodar { await modelo.entrarComApple(CredencialApple(idToken: token, nonce: nonce, nomeCompleto: c.fullName)) }
        case .failure(let erro):
            let codigo = ContaFirebase.erro(erro).codigo
            let texto = mensagemErroSocial(codigo: codigo, provedor: "apple.com")
            mensagem = texto.isEmpty ? nil : texto
        }
    }
}

/// Esqueci a senha: manda o link de redefinição para o e-mail digitado.
struct EsqueciSenhaView: View {
    @Environment(ModeloApp.self) private var modelo
    @Environment(\.paleta) private var paleta
    @Environment(\.dismiss) private var fechar
    @State var emailInicial: String
    @State private var mensagem: String?
    @State private var enviando = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("E-mail", text: $emailInicial)
                        .textContentType(.username)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .accessibilityIdentifier("emailRedefinir")
                } footer: {
                    Text("Enviamos um link para você criar uma senha nova.").foregroundStyle(paleta.cor(.textoSecundario))
                }
                if let mensagem {
                    Section { Text(mensagem).accessibilityIdentifier("mensagemRedefinir") }
                }
                Section {
                    Button {
                        Task {
                            enviando = true
                            mensagem = await modelo.redefinirSenha(email: emailInicial)
                            enviando = false
                        }
                    } label: {
                        Text(enviando ? "Enviando…" : "Enviar link").frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .botaoPrincipal(paleta)
                    .disabled(enviando)
                    .accessibilityIdentifier("enviarLink")
                }
            }
            .navigationTitle("Esqueci a senha")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Fechar") { fechar() } } }
        }
    }
}
```

`app-ios/Custta/Telas/CriarContaView.swift`:

```swift
import SwiftUI
import CusttaNucleo

/// Criar conta: nome, sobrenome, e-mail, senha com checklist, confirmação e "como conheceu o Custta".
struct CriarContaView: View {
    @Environment(ModeloApp.self) private var modelo
    @Environment(\.paleta) private var paleta
    @State private var nome = ""
    @State private var sobrenome = ""
    @State private var email = ""
    @State private var senha = ""
    @State private var confirmacao = ""
    @State private var origem: String?
    @State private var detalhe = ""
    @State private var erro: (campo: String, texto: String)?
    @State private var criando = false
    @FocusState private var foco: String?

    var body: some View {
        Form {
            Section {
                TextField("Nome", text: $nome)
                    .textContentType(.givenName)
                    .focused($foco, equals: "nome")
                    .accessibilityIdentifier("nome")
                TextField("Sobrenome (opcional)", text: $sobrenome, axis: .vertical)
                    .textContentType(.familyName)
                    .focused($foco, equals: "sobrenome")
                    .accessibilityIdentifier("sobrenome")
                TextField("E-mail", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($foco, equals: "email")
                    .accessibilityIdentifier("emailCadastro")
            }

            Section {
                SecureField("Senha", text: $senha)
                    .textContentType(.newPassword)
                    .focused($foco, equals: "senha")
                    .accessibilityIdentifier("senhaCadastro")
                SecureField("Confirmar senha", text: $confirmacao, prompt: Text("Repita"))
                    .textContentType(.newPassword)
                    .focused($foco, equals: "confirmacao")
                    .accessibilityIdentifier("confirmacao")
            } footer: {
                ChecklistSenha(senha: senha, email: email)
            }

            SecaoOrigem(origem: $origem, detalhe: $detalhe, foco: $foco)

            if let erro {
                Section {
                    Text(erro.texto)
                        .foregroundStyle(paleta.cor(.negativo))
                        .accessibilityIdentifier("mensagemCadastro")
                }
            }

            Section {
                Button {
                    Task { await criar() }
                } label: {
                    Text(criando ? "Criando conta…" : "Criar conta").frame(maxWidth: .infinity, minHeight: 44)
                }
                .botaoPrincipal(paleta)
                .disabled(criando)
                .accessibilityIdentifier("criarConta")
            }
        }
        .navigationTitle("Criar conta")
    }

    private func criar() async {
        erro = nil
        switch validarCadastro(nome: nome, sobrenome: sobrenome, email: email, senha: senha, confirmacao: confirmacao,
                               origem: origem, origemDetalhe: detalhe) {
        case .falhou(let campo, let texto):
            erro = (campo, texto)
            foco = campo
        case .ok(let perfil):
            criando = true
            if let texto = await modelo.criarConta(email: email, senha: senha, perfil: perfil) { erro = ("", texto) }
            criando = false
        }
    }
}

/// O checklist de senha do site, com as cinco regras do cadastro.js.
struct ChecklistSenha: View {
    let senha: String
    let email: String
    @Environment(\.paleta) private var paleta

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(validaSenha(senha, email: email).regras, id: \.id) { regra in
                Label(regra.texto, systemImage: regra.ok ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(regra.ok ? paleta.cor(.positivo) : paleta.cor(.textoSecundario))
                    .accessibilityLabel("\(regra.texto): \(regra.ok ? "ok" : "falta")")
            }
        }
        .font(.footnote)
        .accessibilityIdentifier("checklistSenha")
    }
}

/// "Como conheceu o Custta?" com o detalhe opcional de indicação e outro.
struct SecaoOrigem: View {
    @Binding var origem: String?
    @Binding var detalhe: String
    var foco: FocusState<String?>.Binding

    var body: some View {
        Section {
            Picker("Como conheceu o Custta?", selection: $origem) {
                Text("Escolha uma opção").tag(String?.none)
                ForEach(origens, id: \.id) { o in Text(o.nome).tag(Optional(o.id)) }
            }
            .accessibilityIdentifier("origem")
            if let rotulo = origens.first(where: { $0.id == origem })?.detalhe {
                TextField(rotulo, text: $detalhe, axis: .vertical)
                    .textInputAutocapitalization(.words)
                    .focused(foco, equals: "origemDetalhe")
                    .accessibilityIdentifier("origemDetalhe")
            }
        }
        .onChange(of: origem) { _, nova in
            if origens.first(where: { $0.id == nova })?.detalhe == nil { detalhe = "" }
        }
    }
}
```

`app-ios/Custta/Telas/FaltaPoucoView.swift`:

```swift
import SwiftUI
import CusttaNucleo

/// "Falta pouco": conta Google ou Apple sem perfil. A Apple manda o nome, então só pede a origem
/// (a revisão reprova pedir de novo); o Google confirma o nome.
struct FaltaPoucoView: View {
    let usuario: Usuario
    @Environment(ModeloApp.self) private var modelo
    @Environment(\.paleta) private var paleta
    @State private var nome = ""
    @State private var sobrenome = ""
    @State private var origem: String?
    @State private var detalhe = ""
    @State private var mensagem: String?
    @State private var salvando = false
    @FocusState private var foco: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(usuario.contaApple ? "Só falta contar como você conheceu o Custta." : "Confirme seu nome e conte como conheceu o Custta.")
                        .accessibilityIdentifier("textoFaltaPouco")
                }
                if !usuario.contaApple {
                    Section {
                        TextField("Nome", text: $nome)
                            .textContentType(.givenName)
                            .focused($foco, equals: "nome")
                            .accessibilityIdentifier("nome")
                        TextField("Sobrenome (opcional)", text: $sobrenome, axis: .vertical)
                            .textContentType(.familyName)
                            .focused($foco, equals: "sobrenome")
                            .accessibilityIdentifier("sobrenome")
                    }
                }
                SecaoOrigem(origem: $origem, detalhe: $detalhe, foco: $foco)
                if let mensagem {
                    Section { Text(mensagem).foregroundStyle(paleta.cor(.negativo)).accessibilityIdentifier("mensagemFaltaPouco") }
                }
                Section {
                    Button {
                        Task { await salvar() }
                    } label: {
                        Text(salvando ? "Salvando…" : "Começar a usar").frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .botaoPrincipal(paleta)
                    .disabled(salvando)
                    .accessibilityIdentifier("comecarAUsar")
                    Button("Usar outra conta") {
                        Task { mensagem = await modelo.sair() == nil ? nil : "Não foi possível trocar de conta agora. Tente de novo." }
                    }
                    .frame(minHeight: 44)
                    .accessibilityIdentifier("usarOutraConta")
                }
            }
            .navigationTitle("Falta pouco")
            .onAppear {
                let n = nomeDoGoogle(usuario.nomeExibicao)
                nome = n.nome
                sobrenome = n.sobrenome
            }
        }
    }

    private func salvar() async {
        mensagem = nil
        let nomes = usuario.contaApple ? nomeDoGoogle(usuario.nomeExibicao) : (nome, sobrenome)
        let r = normalizaPerfil(nome: nomes.0, sobrenome: nomes.1, origem: origem, origemDetalhe: detalhe, nomeOpcional: usuario.contaApple)
        guard r.ok, let perfil = r.perfil else {
            mensagem = r.erro
            foco = r.campo
            return
        }
        salvando = true
        mensagem = await modelo.completarPerfil(perfil)
        salvando = false
    }
}
```

`app-ios/Custta/Telas/PrincipalView.swift`:

```swift
import SwiftUI
import CusttaNucleo

/// As abas da etapa 1: Obras e Ajustes ("Vale a pena?" chega na etapa 4).
struct PrincipalView: View {
    var body: some View {
        TabView {
            Tab("Obras", systemImage: "building.2") { ObrasView() }
            Tab("Ajustes", systemImage: "gearshape") { AjustesView() }
        }
    }
}

/// Lista de obras, só leitura nesta etapa, com os totais do núcleo.
struct ObrasView: View {
    @Environment(ModeloApp.self) private var modelo
    @Environment(\.paleta) private var paleta

    var body: some View {
        let sinc = modelo.sincronizador
        let obras = obrasOrdenadas(sinc.estado.obras)
        NavigationStack {
            List {
                if let usuario = modelo.usuario, usuario.precisaConfirmarEmail {
                    AvisoEmailView(email: usuario.email)
                }
                if !obras.isEmpty {
                    Section {
                        ForEach(obras, id: \.id) { obra in LinhaObraView(obra: obra) }
                    } header: {
                        Text(obras.count == 1 ? "1 obra" : "\(obras.count) obras")
                            .foregroundStyle(paleta.cor(.textoSecundario))
                    }
                }
            }
            .overlay {
                if !sinc.dadosCarregados, case .erro(let codigo, .leitura) = sinc.estadoSinc {
                    // Nada de carregando para sempre: diz o que houve e que nada foi alterado.
                    ContentUnavailableView {
                        // O identificador fica no título: no contêiner inteiro, ele encobriria o do botão.
                        Label("Não deu para ler suas obras", systemImage: "exclamationmark.icloud")
                            .accessibilityIdentifier("obrasErroLeitura")
                    } description: {
                        Text(textoErroDeLeitura(codigo))
                    } actions: {
                        Button("Tentar de novo") { modelo.tentarDeNovo() }
                            .frame(minHeight: 44)
                            .accessibilityIdentifier("tentarLerDeNovo")
                    }
                } else if !sinc.dadosCarregados {
                    ProgressView("Carregando suas obras…")
                } else if obras.isEmpty {
                    ContentUnavailableView("Nenhuma obra ainda", systemImage: "building.2",
                                           description: Text("Por enquanto, crie a primeira obra pelo site custta.com.br."))
                        .accessibilityIdentifier("obrasVazio")
                }
            }
            .scrollContentBackground(.hidden)
            .background(paleta.cor(.fundo))
            .navigationTitle("Obras")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { IndicadorSincronizacaoView() }
            }
        }
    }
}

/// Uma obra na lista: fase, meses, total gasto e, se tiver, a linha do orçamento.
struct LinhaObraView: View {
    let obra: Obra
    @Environment(\.paleta) private var paleta
    @Environment(\.dynamicTypeSize) private var tamanho

    var body: some View {
        let hoje = dataLocalISO(Date(), fuso: .current)
        let total = totalBruto(obra)
        let orcamento = orcamentoObra(obra)
        let fase = "\(obra.fase.rotulo) · \(fmtMeses(mesesDeObra(obra, hoje: hoje)))"
        let disposicao = tamanho.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
                                                     : AnyLayout(HStackLayout(alignment: .center, spacing: 12))
        disposicao {
            Image(systemName: simbolo(obra.fase))
                .font(.title2)
                .foregroundStyle(paleta.cor(.marca))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(obra.nome).font(.headline).foregroundStyle(paleta.cor(.texto))
                Text(fase).font(.subheadline).foregroundStyle(paleta.cor(.textoSecundario))
                if let orcamento {
                    ProgressView(value: min(max(orcamento.geral.pct, 0), 100), total: 100)
                        .tint(orcamento.geral.nivel == .ok ? paleta.cor(.marca) : paleta.cor(.alerta))
                        .accessibilityHidden(true)
                    Text(textoOrcamentoNaLista(orcamento))
                        .font(.footnote)
                        .foregroundStyle(orcamento.geral.nivel == .passou ? paleta.cor(.alerta) : paleta.cor(.textoSecundario))
                }
            }
            Spacer(minLength: 0)
            Text(moedaCurta(total))
                .font(.title3.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(paleta.cor(.texto))
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(obra.nome)
        .accessibilityValue([fase, "total gasto \(moeda(total))", orcamento.map(textoOrcamentoNaLista)].compactMap { $0 }.joined(separator: ", "))
        .accessibilityIdentifier("obra-\(obra.id)")
    }

    private func simbolo(_ fase: Fase) -> String {
        switch fase {
        case .construcao: return "hammer"
        case .pronta: return "house"
        case .vendida: return "checkmark.seal"
        }
    }
}

/// O indicador de sincronização do site: invisível em dia; tocar no erro tenta de novo.
struct IndicadorSincronizacaoView: View {
    @Environment(ModeloApp.self) private var modelo
    @Environment(\.paleta) private var paleta

    var body: some View {
        if let i = indicador(modelo.sincronizador.estadoSinc) {
            Button {
                if i.erro { modelo.tentarDeNovo() }
            } label: {
                HStack(spacing: 6) {
                    if i.girando { ProgressView().controlSize(.small) }
                    else { Image(systemName: i.erro ? "exclamationmark.circle.fill" : "wifi.slash") }
                    Text(i.rotulo).font(.footnote.weight(.semibold))
                }
                .foregroundStyle(i.erro ? paleta.cor(.negativo) : paleta.cor(.textoSecundario))
                .frame(minHeight: 44)
            }
            .accessibilityLabel(i.rotulo)
            .accessibilityHint(i.dica)
            .accessibilityIdentifier("indicadorSincronizacao")
        }
    }
}

/// Aviso de e-mail não confirmado: o uso não é bloqueado.
struct AvisoEmailView: View {
    let email: String
    @Environment(ModeloApp.self) private var modelo
    @Environment(\.paleta) private var paleta
    @State private var mensagem: String?
    @State private var ocupado = false

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("Confirme seu e-mail").font(.headline)
                Text("Enviamos um link para \(email). Abra o e-mail e toque no link para proteger sua conta.")
                    .font(.subheadline)
                    .foregroundStyle(paleta.cor(.textoSecundario))
                if let mensagem { Text(mensagem).font(.footnote).accessibilityIdentifier("mensagemAvisoEmail") }
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("avisoEmail")
            Button("Reenviar link") {
                Task { ocupado = true; mensagem = await modelo.reenviarVerificacao(); ocupado = false }
            }
            .disabled(ocupado)
            .frame(minHeight: 44)
            .accessibilityIdentifier("reenviarLink")
            Button("Já confirmei") {
                Task { ocupado = true; mensagem = await modelo.conferirVerificacao(); ocupado = false }
            }
            .disabled(ocupado)
            .frame(minHeight: 44)
            .accessibilityIdentifier("jaConfirmei")
        }
    }
}
```

`app-ios/Custta/Telas/AjustesView.swift`:

```swift
import SwiftUI

/// Ajustes mínimo da etapa 1: a conta e "Sair da conta".
struct AjustesView: View {
    @Environment(ModeloApp.self) private var modelo
    @Environment(\.paleta) private var paleta
    @State private var confirmarSaida = false
    @State private var saindo = false
    @State private var mensagemVerificacao: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Conta") {
                    if let nome = modelo.nome {
                        Text(nome).font(.headline).accessibilityIdentifier("nomeConta")
                    }
                    Text(modelo.usuario?.email ?? "")
                        .foregroundStyle(paleta.cor(.textoSecundario))
                        .accessibilityLabel("E-mail")
                        .accessibilityValue(modelo.usuario?.email ?? "")
                        .accessibilityIdentifier("emailConta")
                    if modelo.usuario?.precisaConfirmarEmail == true {
                        Text("Confirme seu e-mail para manter acesso à conta. Você pode continuar usando o app.")
                            .font(.footnote)
                        Button("Enviar confirmação de e-mail") {
                            Task { mensagemVerificacao = await modelo.reenviarVerificacao() }
                        }
                        .frame(minHeight: 44)
                        if let mensagemVerificacao { Text(mensagemVerificacao).font(.footnote) }
                    }
                }
                Section {
                    Link("Política de privacidade", destination: URL(string: "https://custta.com.br/privacidade.html")!)
                        .frame(minHeight: 44)
                }
                Section {
                    Button(role: .destructive) {
                        confirmarSaida = true
                    } label: {
                        Label(saindo ? "Saindo…" : "Sair da conta", systemImage: "rectangle.portrait.and.arrow.right")
                            .frame(minHeight: 44)
                    }
                    .disabled(saindo)
                    .accessibilityIdentifier("sair")
                    .confirmationDialog("Sair da conta?", isPresented: $confirmarSaida, titleVisibility: .visible) {
                        Button("Sair", role: .destructive) {
                            Task {
                                saindo = true
                                if let erro = await modelo.sair() { modelo.avisar(erro) }
                                saindo = false
                            }
                        }
                        Button("Cancelar", role: .cancel) {}
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(paleta.cor(.fundo))
            .navigationTitle("Ajustes")
        }
    }
}
```

O logo do Google, o mesmo arquivo do botão do site:

```bash
mkdir -p app-ios/Custta/Assets.xcassets/LogoGoogle.imageset
cp google-g.svg app-ios/Custta/Assets.xcassets/LogoGoogle.imageset/google-g.svg
```

`app-ios/Custta/Assets.xcassets/LogoGoogle.imageset/Contents.json`:

```json
{
  "images" : [ { "filename" : "google-g.svg", "idiom" : "universal" } ],
  "info" : { "author" : "xcode", "version" : 1 },
  "properties" : { "preserves-vector-representation" : true, "template-rendering-intent" : "original" }
}
```

- [ ] **Step 4: Rodar e ver passar**

Run: `xcodebuild test -project app-ios/Custta.xcodeproj -scheme Custta -destination "$(node scripts/simulador-ios.mjs)" -skipMacroValidation -skipPackagePluginValidation -onlyUsePackageVersionsFromResolvedFile CODE_SIGNING_ALLOWED=NO`
Expected: `** TEST SUCCEEDED **`, com os 16 testes de tela desta tarefa e os de unidade verdes (os de emulador pulados).

Run: `node --test tests/app-ios.test.cjs`
Expected: verde, inclusive "cores só por tokens" com as telas novas.

Conferência visual (Verniz, no simulador): as telas em escuro e claro, esmeralda e azul (`-custta.tema claro -custta.pele azul` nos argumentos do scheme), no tamanho de letra padrão e no maior, com o VoiceOver lendo a lista de obras. Compare com os mockups aprovados na Tarefa 9.

- [ ] **Step 5: Commit**

```bash
git add app-ios/Custta app-ios/CusttaUITests
git commit -m "feat: telas da etapa 1 do app nativo" -m "Entrar (Apple acima do Google, e-mail e senha, esqueci a senha), criar conta com o checklist de senha e a origem, falta pouco que não pede de novo o nome que a Apple mandou, lista de obras só leitura na ordem e com os totais do site (e, se a leitura falhar antes de carregar, explicando que nada foi alterado), indicador de sincronização, aviso de e-mail não confirmado e Ajustes com sair da conta. Os testes de tela abrem o app com os serviços falsos: entrar, criar conta, sem internet, erro de leitura e sair sem rede."
```

---

### Task 12: Acessibilidade verificada (esqueleto funcional validado, a refazer com o mockup aprovado)

> **Esqueleto.** Sobrevivem à troca de visual as cinco auditorias (maior tamanho de letra em entrar, criar conta, obras e Ajustes; contraste nos quatro combos) e a guarda de Reduzir movimento, que fica mais importante com a aurora e o globo. Do visual antigo: o filtro que ignora o que passa sob a barra de abas de vidro do sistema (`auditarContraste`), que muda se a cápsula for própria. Entram auditorias novas: contraste com a aurora parada no quadro mais claro e Reduzir transparência.

**Files:**
- Test: `app-ios/CusttaUITests/AuditoriaUITests.swift`
- Modify: `tests/app-ios.test.cjs` (teste no fim)

**Interfaces:**
- Consumes: `abrirApp(conta:dados:rede:leitura:argumentos:)` e `XCUIApplication.elemento(_:)` (Tarefa 11); identificadores `email`, `irParaCriarConta`, `nome`, `avisoEmail`, `sair`, `emailConta`; argumentos `-custta.tema` e `-custta.pele` lidos pelo `@AppStorage` da `RaizView` (Tarefas 10 e 11); obra o4 dos `DadosDeExemplo` (Tarefa 7).
- Produces: nada novo; fixa os requisitos da seção 8 do spec como teste para as próximas etapas.

As correções que as auditorias pediram no protótipo já estão nos trechos da Tarefa 11 (cabeçalhos com `textoSecundario`, logo com rótulo "Custta", e-mail com rótulo legível, placeholders curtos e campos que crescem, texto dos botões principais com `SobreMarca`). Esta tarefa fixa as auditorias e prova que elas pegam regressão.

- [ ] **Step 1: Escrever as auditorias**

`app-ios/CusttaUITests/AuditoriaUITests.swift`:

```swift
import XCTest

/* Requisitos verificáveis do spec, seção 8: no maior tamanho de letra de acessibilidade nada
   corta, todo controle tem rótulo e alvo de 44 pt; o contraste passa nos quatro combos. */
final class AuditoriaUITests: XCTestCase {
    private let maiorLetra = ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
    private let tiposDeAuditoria: XCUIAccessibilityAuditType = [.dynamicType, .textClipped, .sufficientElementDescription, .hitRegion]

    @MainActor func testEntrarNoMaiorTamanho() throws {
        let app = abrirApp(argumentos: maiorLetra)
        XCTAssertTrue(app.textFields["email"].waitForExistence(timeout: 10))
        try app.performAccessibilityAudit(for: tiposDeAuditoria)
    }

    @MainActor func testCriarContaNoMaiorTamanho() throws {
        let app = abrirApp(argumentos: maiorLetra)
        XCTAssertTrue(app.textFields["email"].waitForExistence(timeout: 10))
        let link = app.buttons["irParaCriarConta"]
        // No maior tamanho o link fica bem abaixo, e a lista só cria a linha quando ela chega perto da tela.
        for _ in 0..<10 where !(link.exists && link.isHittable) { app.swipeUp() }
        link.tap()
        XCTAssertTrue(app.textFields["nome"].waitForExistence(timeout: 10))
        try app.performAccessibilityAudit(for: tiposDeAuditoria)
    }

    @MainActor func testObrasNoMaiorTamanho() throws {
        let app = abrirApp(conta: "senha-nao-confirmada", argumentos: maiorLetra)
        XCTAssertTrue(app.elemento("avisoEmail").waitForExistence(timeout: 10))
        try app.performAccessibilityAudit(for: tiposDeAuditoria)
        app.swipeUp(); app.swipeUp()
        try app.performAccessibilityAudit(for: tiposDeAuditoria)
    }

    @MainActor func testAjustesNoMaiorTamanho() throws {
        let app = abrirApp(conta: "senha-nao-confirmada", argumentos: maiorLetra)
        let aba = app.tabBars.buttons["Ajustes"]
        XCTAssertTrue(aba.waitForExistence(timeout: 10))
        aba.tap()
        XCTAssertTrue(app.buttons["sair"].waitForExistence(timeout: 5) || app.staticTexts["emailConta"].waitForExistence(timeout: 5))
        try app.performAccessibilityAudit(for: tiposDeAuditoria)
    }

    /// Contraste de tudo o que aparece, menos o que está atrás da barra de abas (o vidro do sistema
    /// escurece o que passa por baixo; o mesmo conteúdo é auditado quando sobe na tela).
    @MainActor private func auditarContraste(_ app: XCUIApplication) throws {
        let barra = app.tabBars.firstMatch.exists ? app.tabBars.firstMatch.frame : .null
        try app.performAccessibilityAudit(for: [.contrast]) { achado in
            guard let elemento = achado.element else { return false }
            return elemento.frame.intersects(barra)
        }
    }

    @MainActor func testContrasteNosQuatroCombos() throws {
        for (tema, pele) in [("escuro", "esmeralda"), ("claro", "esmeralda"), ("escuro", "azul"), ("claro", "azul")] {
            let app = abrirApp(conta: "senha-nao-confirmada", argumentos: ["-custta.tema", tema, "-custta.pele", pele])
            XCTAssertTrue(app.elemento("avisoEmail").waitForExistence(timeout: 10))
            try auditarContraste(app)
            app.terminate()
            let entrar = abrirApp(argumentos: ["-custta.tema", tema, "-custta.pele", pele])
            XCTAssertTrue(entrar.textFields["email"].waitForExistence(timeout: 10))
            try auditarContraste(entrar)
            entrar.terminate()
        }
    }
}
```

No fim de `tests/app-ios.test.cjs` (a etapa 1 não tem animação própria; a guarda vale para as próximas):

```js
test('animação própria respeita Reduzir movimento', () => {
  for(const f of arquivosSwift('app-ios/Custta')){
    const t = ler(f);
    if(/withAnimation|\.animation\(|\.transition\(/.test(t))
      assert.match(t, /accessibilityReduceMotion/, `${f}: anima sem olhar @Environment(\\.accessibilityReduceMotion)`);
  }
});
```

- [ ] **Step 2: Provar que a auditoria pega regressão**

No botão "Entrar" de `app-ios/Custta/Telas/EntradaView.swift`, troque temporariamente `.botaoPrincipal(paleta)` por `.buttonStyle(.borderedProminent)` (texto branco sobre a marca, como estava no protótipo).

Run: `xcodebuild test -project app-ios/Custta.xcodeproj -scheme Custta -destination "$(node scripts/simulador-ios.mjs)" -skipMacroValidation -skipPackagePluginValidation -onlyUsePackageVersionsFromResolvedFile CODE_SIGNING_ALLOWED=NO -only-testing:CusttaUITests/AuditoriaUITests/testContrasteNosQuatroCombos`
Expected: FAIL com um achado de contraste no botão "Entrar" (no protótipo, 2,6:1 no escuro esmeralda). Desfaça a troca.

- [ ] **Step 3: Rodar e ver passar**

Run: `xcodebuild test -project app-ios/Custta.xcodeproj -scheme Custta -destination "$(node scripts/simulador-ios.mjs)" -skipMacroValidation -skipPackagePluginValidation -onlyUsePackageVersionsFromResolvedFile CODE_SIGNING_ALLOWED=NO -only-testing:CusttaUITests/AuditoriaUITests`
Expected: os 5 testes verdes: entrar, criar conta, obras (com a obra o4, de nome longo e R$ 123,5 mi) e Ajustes no maior tamanho de letra, e o contraste nos quatro combos.

Run: `node --test tests/app-ios.test.cjs`
Expected: verde.

Se o portão de desenho tiver mudado cores ou disposição, é aqui que aparece: achado de contraste se resolve no valor do token (`scripts/cores-app-ios.mjs`), nunca com cor solta; texto cortado se resolve deixando o campo crescer (`axis: .vertical`) ou encurtando o placeholder.

- [ ] **Step 4: Commit**

```bash
git add app-ios/CusttaUITests/AuditoriaUITests.swift tests/app-ios.test.cjs
git commit -m "test: auditorias de acessibilidade do app nativo" -m "Os requisitos da seção 8 do spec viram teste: no maior tamanho de letra de acessibilidade nada corta e todo controle tem rótulo e alvo suficiente nas telas de entrar, criar conta, obras e Ajustes, e o contraste passa nos quatro combos de tema e pele. A guarda em Node prepara as próximas etapas: animação própria só olhando o Reduzir movimento."
```

---

### Task 13: Conferência cruzada site ↔ app

**Files:**
- Create: `tests/app-ios/cruzado.mjs`
- Create: `app-ios/CusttaUITests/CruzadoUITests.swift`, `app-ios/CusttaTests/CruzadoTests.swift`
- Modify: `package.json` (script `test:app-ios:cruzado`), `tests/app-ios.test.cjs` (o teste de scripts da Tarefa 6 passa a cobrir os dois)

**Interfaces:**
- Consumes: `testarNoSimulador(alvos, env)` (Tarefa 2); `Sincronizador` (Tarefa 5); `TransporteFirebase`, `RelogioDoSistema`, `Emulador` (Tarefa 6); `Composicao` com `CUSTTA_EMULADORES` e `CUSTTA_SAIR_AO_ABRIR` (Tarefa 8); `Gasto` e `ValorJSON` (Parte A); identificadores `email`, `senha`, `entrar`, `obra-<id>` e o valor de acessibilidade da linha de obra ("total gasto R$ …" e a linha do orçamento) (Tarefa 11); no site, `C.money`, `C.moneyCurto`, `C.totalBruto`, `C.orcamentoObra`, `C.parcelamentoCartao`, `C.canon` (`calc.js`), `D.normaliza` (`dados.js`) e o SDK JavaScript `firebase` 12.18.0.
- Produces: `npm run test:app-ios:cruzado` (portão local antes de cada build do TestFlight, Tarefa 15).

O teste 5 da seção "Testes e validação" do spec: na mesma conta, contra os emuladores, o site grava e o app mostra os totais e os orçamentos que o `calc.js` calculou (obra com orçamento total, obra vendida com orçamento por tópico estourado e obra com compra parcelada no cartão com juros, cujo total é diferente do valor da compra); o site muda e o app vê sozinho; o app lança um gasto e o site soma esse gasto, sem perder nada que só o site conhece. O roteiro falha se qualquer um dos dois testes for pulado: exige o pedido de mudança que só o teste de tela faz e que o `_atualizado` avance depois do teste do app. O documento final é comparado sem normalizar, para a forma que o app gravou aparecer.

- [ ] **Step 1: Escrever as metades do app e a guarda**

`app-ios/CusttaUITests/CruzadoUITests.swift`:

```swift
import XCTest

/* Metade tela da conferência cruzada (tests/app-ios/cruzado.mjs): entra pelo formulário na
   conta que o "site" criou, confere o total e o orçamento que o site calculou e pede ao roteiro
   uma mudança feita como o site faz; ela tem de aparecer sozinha na lista. Os elementos são
   achados pelo identificador, de qualquer tipo: a troca de visual do PR 4 não quebra o teste. */
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

Em `tests/app-ios.test.cjs`, troque o teste `'script dos testes do app contra os emuladores'` (Tarefa 6) por:

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

### Task 14: Envio ao TestFlight como 2.0

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
Expected: `** ARCHIVE SUCCEEDED **`. O arquivamento assinado e o envio só acontecem no workflow (Tarefa 15, Step 6).

- [ ] **Step 4: Commit**

```bash
git add .github/workflows/app-ios-testflight.yml app-ios/ExportOptions.plist tests/workflow.test.cjs
git commit -m "ci: envio do app nativo ao TestFlight como 2.0" -m "Workflow só no botão que arquiva a Release assinada com o mesmo perfil, certificado e chave do App Store Connect do app de hoje e envia ao TestFlight como versão 2.0, com o build number run_number.run_attempt. A keychain é temporária e some mesmo com falha, o perfil é conferido (nome, time e aviso de vencimento em menos de 30 dias) e o Xcode é o mesmo fixo da CI; as opções de exportação são as mesmas do envio do Capacitor, que continua igual."
```

---

### Task 15: Documentação, portão local e build no TestFlight

**Files:**
- Modify: `CLAUDE.md` (bloco "Comandos" e seção nova "App nativo (app-ios/)", depois de "App iOS (Capacitor)")
- Create: `docs/plans/2026-10-06-app-nativo-etapa1-checklist-aparelho.md`

**Interfaces:**
- Consumes: tudo das Tarefas 1 a 14.
- Produces: instrução do app nativo para os próximos agentes; o checklist que o Giovani roda no iPhone; o primeiro build 2.0 no TestFlight.

- [ ] **Step 1: Documentar no CLAUDE.md**

No bloco de "Comandos", logo depois da linha do `npm run test:nucleo`:

```bash
npm run test:app-ios:emuladores  # testes do app nativo contra os emuladores do Firebase (Mac, Java)
npm run test:app-ios:cruzado     # conferência cruzada site ↔ app nativo nos emuladores (Mac, Java)
node scripts/cores-app-ios.mjs   # grava no catálogo do app nativo as cores da tabela de tokens
```

Depois da seção "### App iOS (Capacitor)", a seção nova:

```markdown
### App nativo (app-ios/)

App em SwiftUI que vai substituir o Capacitor (spec `docs/specs/2026-10-06-app-nativo-design.md`, planos `docs/plans/2026-10-06-app-nativo-*`). O `app-ios/Custta.xcodeproj` é escrito à mão no formato do Xcode 16 (pastas sincronizadas): arquivo novo dentro de `Custta/`, `CusttaTests/` ou `CusttaUITests/` entra no alvo sozinho; não deixe o Xcode subir o `objectVersion` (77), porque a CI usa o Xcode 26 (`tests/app-ios.test.cjs` barra). As regras moram no pacote `app-ios/CusttaNucleo`, puro e conferido contra os vetores do site; o app tem as telas, o `ModeloApp` e a camada fina do Firebase em `Custta/Dados/`. Pacotes Swift: só firebase-ios-sdk e GoogleSignIn-iOS, em versão exata, com o `Package.resolved` versionado (para atualizar, botão "resolver de novo" do workflow `app-ios`). Cores só por tokens: os valores ficam em `scripts/cores-app-ios.mjs` (rode o script depois de mudar), nunca cor solta no código. Em Debug o app aceita `CUSTTA_SERVICOS=falsos` (testes de tela) e `CUSTTA_EMULADORES=1` (emuladores); o Release não tem nenhum dos dois. A CI (`app-ios.yml`) roda o núcleo, o build Release sem assinatura e os testes no simulador com os serviços falsos; os testes contra os emuladores e a conferência cruzada rodam no Mac e são obrigatórios antes de cada envio. O app nunca grava antes de ver os dados da conta (`Sincronizador`, erro `nao-carregado`). Sair segue o `cloud.js`: para a escuta, grava a marca `custta-limpar-cache` (`UserDefaults`), sai e apaga o cache; a abertura seguinte termina uma limpeza interrompida. Os identificadores de acessibilidade são contrato com os testes, inclusive a conferência cruzada. O Xcode da CI é fixo (`DEVELOPER_DIR` do 26.6). O `PrivacyInfo.xcprivacy` acompanha a política de privacidade do site: dado novo coletado entra nos dois. Envio: workflow `app-ios-testflight`, no botão, versão 2.0 no mesmo cadastro (`br.com.custta.app`). Pendências de aparelho: `docs/plans/2026-10-06-app-nativo-etapa1-checklist-aparelho.md`.
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

## Visual (depois do PR 4, com a aurora e o vidro)

- [ ] Rolar a lista de obras rápido, para cima e para baixo: a aurora e o globo não engasgam a rolagem.
- [ ] Dez minutos de uso, entrando e saindo das telas: o iPhone não esquenta.
- [ ] Ajustes do iPhone > Acessibilidade > Movimento > Reduzir movimento: a aurora e o globo ficam parados.
- [ ] Ajustes do iPhone > Acessibilidade > Tela e Tamanho do Texto > Reduzir transparência: o vidro vira superfície sólida e tudo continua legível.
- [ ] Texto Maior no máximo: nada cortado sobre o vidro, inclusive na cápsula de abas.
```

- [ ] **Step 3: Rodar e ver passar**

Run: `npm run test:unit`
Expected: verde (o `docs.test.mjs` confere os links da documentação viva).

- [ ] **Step 4: Commit**

```bash
git add CLAUDE.md docs/plans/2026-10-06-app-nativo-etapa1-checklist-aparelho.md
git commit -m "docs: app nativo no CLAUDE.md e checklist do aparelho da etapa 1" -m "O CLAUDE.md ganha a seção do app nativo (projeto escrito à mão, núcleo puro, pacotes travados, cores por tokens, serviços falsos e emuladores só em Debug, o que roda na CI e o que roda no Mac antes de cada envio) e os comandos novos. O checklist é o roteiro do Giovani no iPhone: entrar pelos três caminhos, totais iguais aos do site, mudança do site chegando sozinha e uso em modo avião."
```

- [ ] **Step 5: Portão local na main**

Depois do merge do PR 5, num worktree limpo da `origin/main`:

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
