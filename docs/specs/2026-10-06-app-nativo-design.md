# Custta nativo no iPhone (SwiftUI)

Data: 2026-10-06. Decisão do Giovani antes de enviar o app à revisão da Apple: "não quero que seja um site dentro de uma casca".

## Por que

O app que está no TestFlight (build 17.1) é o site empacotado com Capacitor. Isso traz dois problemas:

- **Risco de recusa pela Guideline 4.2** (app que é só um site numa casca). É o maior risco da revisão hoje.
- **Teto de qualidade.** Barras, sheets, vidro, gestos e teclado de valor foram recriados à mão em CSS e JavaScript para imitar o iOS. No app nativo eles vêm do sistema.

O objetivo é um app de iPhone feito com a linguagem e os componentes da Apple, que vá para a loja **completo**, com tudo o que o site faz hoje.

## Decisões (tomadas com o Giovani em 06/10/2026)

- **Plataformas:** app nativo no iPhone **e** o site. O site (`custta.com.br`, PWA) continua como está, para computador e para quem não tem iPhone.
- **Tecnologia:** SwiftUI puro. React Native e Flutter foram descartados: trazem centenas de pacotes de terceiros ou desenham a própria interface, e o Android não está no plano.
- **Visual:** iOS de verdade com a marca Custta. Componentes padrão do sistema (abas, listas, sheets, Liquid Glass da Apple) com as cores, o logo tt., os números grandes e o tema escuro do Custta. Aurora, globo e vidro próprio do site não são recriados.
- **Paridade de funções, não de visual.** O app nativo precisa fazer tudo o que o site faz. O desenho de cada tela pode ser repensado (o Giovani quer rever, por exemplo, os gráficos). A decisão de desenho acontece no começo de cada etapa, quando o Croqui mostrar as opções.
- **Lançamento completo.** Só vai para a revisão da Apple quando tiver todas as telas do site. Qualidade vem antes de prazo.
- **Construção em etapas pelo TestFlight.** Cada etapa termina num build que o Giovani testa no iPhone. A etapa só fecha com o ok dele.
- **iOS mínimo: 26.** É onde existe o Liquid Glass do sistema. Roda do iPhone 11 em diante; o pai usa um iPhone 16 Pro com iOS 27. Quem tiver aparelho mais antigo usa o site.
- **Só iPhone, só em pé**, como hoje (`TARGETED_DEVICE_FAMILY = 1`).

## O que não muda

- **O banco.** Mesmo projeto Firebase, mesma conta, mesmos documentos: `dados/{uid}`, `perfis/{uid}` e `push/{uid}`. O que se lança no iPhone aparece no site e vice-versa.
- **`firestore.rules`.** Nenhuma chave nova no estado. Se uma etapa precisar mudar o formato, vale a regra do `CLAUDE.md`: rules, teste, `rules:deploy` e sonda, antes do código.
- **O cron do push** (`notificacoes/`). O app registra o aparelho no mesmo lugar e formato.
- **O site.** Só ganha os vetores de teste compartilhados (abaixo) e as correções dos três achados da seção "Achados no site".
- **O cadastro na loja.** Mesmo bundle ID (`br.com.custta.app`), mesmo app no App Store Connect, mesmas chaves e secrets.

## Desenho

### 1. Onde o código mora

Pasta nova `app-ios/` na raiz do repositório, com um projeto Xcode próprio. `ios/` (Capacitor) e `www/` continuam intactos durante toda a construção.

- `app-ios/` entra no `.vercelignore` (`tests/vercel.test.cjs` confere).
- Identificadores, comentários e textos em português, como no resto do repositório (`obra`, `gasto`, `topico`, `fase`, `corrigido`, `afazer`).
- A remoção do Capacitor (`ios/`, `build:www`, `cap:sync`, plugins, os ramos nativos de `nativo.js` e `push.js`) é um PR separado, **depois** que a Apple aprovar o app nativo. Fica fora deste spec.

### 2. Três camadas

Cada camada tem um papel só e é testável sem as outras.

**Núcleo (`CusttaNucleo`, pacote Swift local, sem tela e sem Firebase).** Roda com `swift test` no Mac, sem simulador.

- **Cálculo:** todas as funções de `calc.js` reescritas em Swift: correção composta diária (`DIAS_MES = 30.44`), totais, lucro na venda, TIR por bisseção, séries dos gráficos, a pagar em 30 dias, parcelas e parcelamento Price, orçamento previsto × real, filtro de gastos, máscara e leitura de moeda.
- **Modelo:** obra, gasto, parcela, afazer, orçamento, tópicos (os 21 padrão e os próprios), configuração.
- **Normalização:** as regras de `dados.js` ao carregar (taxa fora da faixa vira 1, gasto sem id ou com data inválida é descartado, fase vendida sem venda volta para construção, e as demais).
- **Exportação:** JSON e CSV no mesmo formato de `share.js`.
- **Miudezas com formato fixo:** geração de id, chave do token de push (djb2 em base 36), comparação canônica de blobs, tamanho em bytes do blob.

**Dados (dentro do app, fala com o Firebase).**

- **Conta:** Firebase Auth com e-mail e senha, Sign in with Apple (AuthenticationServices, com nonce) e Google (GoogleSignIn). Cadastro, perfil, esqueci a senha, verificação de e-mail, trocar senha, sair, reautenticar e apagar conta com revogação do token da Apple.
- **Estado:** lê e escuta `dados/{uid}`; grava o documento inteiro com `_atualizado`.
- **Push:** Firebase Messaging; grava e remove o token em `push/{uid}.tokens`.

**Telas (SwiftUI).** Um estado observável único (`{obras, config}`), como o `db` do site. Toda mudança passa por ele: altera, grava, a tela reage.

- Navegação do sistema: `TabView` com as três abas (Obras, Vale a pena?, Ajustes) e `NavigationStack` para obra, relatório e gráficos.
- Sheets, diálogos de confirmação, arrastar para apagar, puxar o sheet e voltar pela borda são os do sistema. `gestos.js`, `teclado.js` e `ui-confirm.js` não têm equivalente a escrever.
- Gráficos com Swift Charts (rosca, linha e barras).
- Compartilhar e salvar PDF com a folha de compartilhamento do sistema.

### 3. Dados e sincronização

O contrato com o site é o documento `dados/{uid}`. Quatro regras protegem esse contrato:

1. **Campo desconhecido é preservado.** O modelo guarda a árvore JSON original de cada obra, gasto e configuração, e os tipos Swift leem e escrevem por cima dela. Se o site ganhar um campo novo antes do app, o iPhone grava de volta sem apagá-lo. É o mesmo comportamento que `dados.js` já tem.
2. **Grava o documento inteiro, como o site.** A última gravação vale. Não há merge por campo. O comportamento entre iPhone e site fica igual ao que hoje existe entre dois aparelhos.
3. **Números.** O Firestore devolve inteiro ou decimal conforme o valor gravado pelo JavaScript. A leitura aceita os dois (e número em texto, como a normalização do site).
4. **Guarda de tamanho.** Acima de 900.000 bytes não grava e avisa; entre 700.000 e 900.000 avisa uma vez. As rules não conseguem medir bytes, então a guarda mora no cliente, como hoje.

Sem internet, o cache persistente do SDK do Firestore no iOS mostra os dados e guarda a fila de gravações. Os estados visíveis são os mesmos do site: salvando, sem conexão, não salvou (toque para tentar de novo) e não sincronizou. O aviso de "gasto lançado" só aparece quando o servidor confirma; se demorar, aparece "aguardando sincronização".

O eco do próprio snapshot é ignorado: snapshot com gravação local pendente não troca o estado; os demais passam pela normalização e pela comparação canônica, e só trocam o estado se algo mudou. Se a obra aberta sumiu (apagada em outro aparelho), o app volta para a lista.

### 4. Erros previstos

| Situação | O que o app faz |
| --- | --- |
| Sem internet | Abre, mostra tudo, aceita lançamento, envia quando o sinal volta |
| Falha transitória ao gravar | Tenta de novo sozinho; aviso discreto, no máximo um a cada 30 s |
| Falha definitiva ao gravar (permissão, limite) | Estado "não salvou" com toque para tentar de novo e mensagem clara |
| Documento perto ou acima do limite | Avisos da guarda de tamanho |
| Sessão expirada ou conta apagada em outro aparelho | Sai da conta, limpa o estado local e explica na tela de entrada |
| E-mail não confirmado | Aviso com "reenviar" e "já confirmei"; o uso não é bloqueado |
| Falta de rede ao verificar a sessão | Nunca desloga |
| Sair com gravação pendente | Espera a fila; sem internet, pede para conectar antes de sair |

### 5. Notificações

- Pedido de permissão do iOS e convite depois do login (uma resposta encerra o convite para aquela conta naquele aparelho); a chave continua em Ajustes.
- Token do FCM gravado em `push/{uid}.tokens.{chave}` como `{token, plataforma: 'ios', criado}`, com a mesma chave (djb2 do token em base 36). O cron não muda.
- A cada login o token é conferido: se mudou, grava o novo e apaga o antigo. Desativar ou sair apaga só o token do aparelho.
- Tocar na notificação abre a obra indicada em `obraId`; se ela não existir mais, abre a lista.

### 6. Pacotes de terceiros

Só o que não tem substituto do sistema, via Swift Package Manager, com `Package.resolved` versionado e resolução travada na CI (a mesma política de hoje):

- **Firebase iOS SDK:** Auth, Firestore e Messaging.
- **GoogleSignIn-iOS.**

Nenhum pacote npm entra no app. Gráficos, PDF, compartilhamento, vibração, login com Apple e teclado são do sistema.

**Relatório de falhas:** o app nativo **não** leva o Sentry. Falhas chegam pelos relatórios da própria Apple (TestFlight e Xcode Organizer), que não exigem SDK. É um pacote de terceiro a menos e um item a menos na declaração de privacidade. O Sentry continua no site.

**Risco conhecido:** `docs/sdks-fase4.md` registra um conflito de versões entre o GoogleSignIn-iOS 8 e o Firebase iOS 13 (app-check e gtm-session-fetcher). A primeira tarefa da etapa 1 é fixar um par de versões que resolve e registrar o `Package.resolved`.

### 7. Paridade com o site

O app nativo sai com todas as funções abaixo. O inventário detalhado (campos, limites, mensagens e casos de borda) foi levantado do código em 06/10/2026 e vai para o plano de implementação, etapa por etapa.

**Entrar e conta**
- Entrar com e-mail e senha, Apple (acima do Google, Guideline 4.8) e Google.
- Criar conta: nome, sobrenome, e-mail, senha com as mesmas regras (8+ caracteres, letra, número, diferente do e-mail, não óbvia, até 128) e "como conheceu o Custta".
- "Falta pouco" para conta social sem perfil (Apple pede só a origem; Google confirma o nome).
- Esqueci a senha, aviso de e-mail não confirmado, trocar senha, editar nome, sair.
- Apagar conta: reautenticar, digitar APAGAR, apagar `dados`, `perfis` e `push`, revogar o token da Apple e apagar a conta (Guideline 5.1.1(v)).

**Obras**
- Lista ordenada (não vendidas primeiro, depois a mais recente), com fase, meses de obra, total gasto e barra de orçamento.
- Comparativo entre obras (bruto × corrigido) com duas ou mais obras com gasto.
- Criar, editar e apagar obra. Fases: em construção, pronta, vendida. Registrar e desfazer venda.

**Dentro da obra**
- Indicadores: total gasto, corrigido pelo banco, a pagar em 30 dias e venda (real ou estimada, com R$/m² e margem).
- Orçamento previsto × real, por total ou por tópico, com os três níveis (dentro, perto, passou) e "fora do orçamento".
- Afazeres: adicionar, marcar como feito, apagar.
- Gastos por tópico, evolução bruto × corrigido e gasto por mês.
- Lançamentos com busca sem acento e filtro por mês.
- Lançar, editar e apagar gasto: valor, obra, tópico, Pix ou cartão, parcelas de 1 a 36 com juros ao mês, descrição com sugestões, data, aviso de gasto duplicado.
- Compra parcelada: N gastos irmãos com `grupoId`, `parcela {n, de}` e `jurosCartao`; apagar só a parcela ou a compra toda.
- Detalhe do tópico e lista "a pagar em 30 dias".

**Análise**
- Gráficos da obra em tela própria, com salvar em PDF.
- Relatório por tópico com bruto, corrigido e correção, seleção de gastos com soma, linhas de venda ou de margem estimada, salvar em PDF.
- Simulador "Vale a pena?": obra, preço de venda, daqui a quantos meses; veredito, TIR ao mês, comparação com o banco e a tabela pelo bruto e pelo corrigido.

**Ajustes**
- Taxa ao mês (maior que 0 e até 20%).
- Tópicos próprios (até 50, até 80 caracteres; não remove tópico com gasto ou em orçamento).
- Aparência por aparelho: escuro (padrão) ou claro; cor esmeralda (padrão) ou azul.
- Notificações diárias.
- Exportar JSON completo e planilha CSV.
- Aviso de versão nova (`versao.json`), política de privacidade.

**Transversal**
- Entrada de valor em centavos, com teto de R$ 99.999.999,99.
- Moeda, datas e abreviações no padrão pt-BR do site ("R$ 1,23 mi", "dd/mm/aa", "jan/26").
- Lembrar a tela e a obra abertas ao reabrir; a notificação tocada vence essa lembrança.
- Vibração leve quando o servidor confirma um gasto.
- Textos de tela vazia, um por lista.

### 8. Princípios de desenho que valem no nativo

Os do `PRODUCT.md` continuam: saldo em 5 segundos, um número importante por vez, letra generosa, escuro como padrão, offline é sagrado. No nativo eles viram requisitos verificáveis:

- **Letra grande do sistema (Dynamic Type):** todas as telas legíveis e sem corte até o maior tamanho de acessibilidade. O pai usa óculos de leitura.
- **VoiceOver:** todo controle com rótulo; gráficos com descrição em texto.
- **Reduzir movimento e aumentar contraste** respeitados.
- **Alvos de toque de 44 pt ou mais.**
- **Cores só por tokens** (asset catalog com as variantes claro/escuro e esmeralda/azul); nenhuma cor solta na tela.

Cada etapa começa pelo desenho das telas feito pelo Croqui e **aprovado pelo Giovani antes do código**. Os mockups ficam em `~/Documents/custta-mockups/`, nunca na raiz do repositório.

## Etapas

Cada etapa tem spec curto de telas (quando houver decisão de desenho), plano, código em TDD, revisão e um build no TestFlight.

| Etapa | Entrega no TestFlight |
| --- | --- |
| 1. Base | Projeto, pacotes travados, núcleo de cálculo com vetores, entrar (e-mail, Apple, Google), cadastro, sincronização e uso sem internet |
| 2. Obras e gastos | Lista de obras, obra com indicadores, lançar/editar/apagar gasto, fases e venda |
| 3. Dentro da obra | Parcelas no cartão, afazeres, orçamento previsto × real, busca e filtro, detalhe do tópico, a pagar |
| 4. Análise | Gráficos, relatório, simulador "Vale a pena?", PDF |
| 5. Conta e avisos | Ajustes, notificações, exportar, trocar senha, apagar conta, aparência |
| 6. Acabamento | Acessibilidade completa, tela de abertura e ícone, capturas novas, pré-revisão das regras da Apple |

Estimativa: 4 a 6 semanas de calendário até o envio à revisão, ditadas pelos testes no aparelho ao fim de cada etapa.

### Como testar sem perder o app de hoje

O app nativo entra no TestFlight como **versão 2.0**, no mesmo cadastro. Instalar um build 2.0 substitui o app atual no iPhone do Giovani; o TestFlight permite voltar ao build 17.1 enquanto ele não expirar (90 dias a partir de 04/10/2026), e o PWA continua completo. Os dados ficam na nuvem; na troca, no máximo é preciso entrar na conta de novo. O pai usa o PWA pelo Safari e não é afetado até o app novo estar pronto.

## Testes e validação

1. **Vetores compartilhados de cálculo.** `scripts/vetores-calc.mjs` gera `tests/vetores/calc.json` a partir do `calc.js` e do `dados.js` (casos de entrada e saída por função). Um teste de unidade do site confere que o arquivo está em dia com o código; os testes do núcleo Swift leem o mesmo arquivo. Valores em dinheiro batem no centavo; valores contínuos (taxas, TIR) com tolerância relativa de 1e-9. Se as duas cópias das regras divergirem, um dos lados falha.
2. **Contrato de dados.** O núcleo lê blobs reais do formato do site (incluindo campos desconhecidos, dados antigos e parcelas), grava de volta, e o resultado tem de ser canonicamente idêntico. O formato gravado é conferido contra as `firestore.rules` no emulador, como já faz `tests/conta-demo.test.mjs`.
3. **Formatos fixos.** Chave do token de push, CSV e JSON de exportação comparados byte a byte com a saída do site.
4. **Telas.** Testes automáticos no simulador para os caminhos principais: entrar, lançar gasto, parcelar, editar e apagar, usar sem internet e voltar a sincronizar, apagar conta. Conferência visual pelo time no simulador (escuro e claro, esmeralda e azul, letra padrão e a maior de acessibilidade, VoiceOver).
5. **Site e app juntos.** Na mesma conta de teste, contra os emuladores: lançar no app e ver no site, lançar no site e ver no app, inclusive um campo que só o site conhece.
6. **CI.** Workflow novo que roda `swift test` do núcleo e os testes do app no simulador, com os pacotes travados. O envio ao TestFlight do app nativo é um workflow à parte, disparado à mão. Os workflows do Capacitor continuam até a remoção.
7. **Aparelho.** O Giovani testa cada etapa no iPhone pelo TestFlight. Antes do envio à loja, o pai usa o app nativo no dia a dia.

## Achados no site durante o inventário

Três comportamentos do site que não devem ser copiados como estão. Cada um é corrigido no site num PR próprio, antes de entrar nos vetores, para as duas cópias nascerem iguais e certas:

- **`aPagar` calcula o limite de 30 dias em UTC** (`toISOString`), enquanto o resto usa hora local. Perto da meia-noite pode errar um dia.
- **O CSV exporta o id do tópico padrão** (por exemplo `maoobra`) em vez do nome; só os tópicos próprios saem com o nome.
- **O limite de 300 obras não tem aviso na tela.** A gravação é recusada pelas rules e aparece como "não salvou" sem explicar o motivo.

## Loja (depois da etapa 6)

- Pré-revisão do app contra as App Store Review Guidelines.
- Capturas novas, tiradas do app nativo.
- `docs/app-store-metadados.md`: notas de revisão reescritas para o app nativo, links de marketing e suporte em `custta.com.br`, tabela de privacidade refeita a partir dos pacotes do app nativo. O item de diagnóstico do Sentry sai. Os tipos de dado que o manifesto do GoogleSignIn declara (telefone, localização aproximada, IDs e uso) continuam sendo a decisão pendente do Giovani; a recomendação registrada é declarar como o SDK declara.
- `PrivacyInfo.xcprivacy` novo, coerente com a tabela.
- Conta de demonstração criada em produção com senha nova (`npm run conta:demo:producao`).
- Envio com liberação manual.

## Fora do escopo

- Android e iPad (o app continua só de iPhone).
- Funcionalidade nova que o site não tem, widgets, Apple Watch, atalhos da Siri.
- Mudança no desenho do site.
- Remoção do Capacitor (PR próprio, depois da aprovação).
- **Blindagem 4 (App Check, corte de gasto e alerta de consumo),** marcada para 02/11/2026. Tem spec próprio. Recomendação registrada: ligar o App Check no app nativo antes do envio à loja, para não precisar de uma segunda revisão só por isso; a decisão continua com o Giovani.
