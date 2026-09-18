# ObraControl: de PWA a app público na App Store

> Atualização em 2026-09-08: Fase 1 auditada; critérios, testes e decisões finais em
> [Fase 1 — fechamento](plans/2026-09-08-fase1-fechamento.md).
> O texto abaixo preserva o planejamento original. Sentry permanece na Fase 3.

## Contexto

O ObraControl hoje é um PWA vanilla em produção na Vercel, usado por uma pessoa (o pai do Giovani). O objetivo é publicá-lo na App Store como app baixável por qualquer construtor, gratuito na v1, seguro para usuários reais.

Três agentes de exploração mapearam o estado atual. O app está funcionalmente maduro — 26 specs implementadas, empty states bons, erros de login bem tratados, assets 100% relativos. Mas ele foi construído com a premissa de um único usuário conhecido, e essa premissa aparece em três lugares que impedem o lançamento público:

1. **A fronteira de segurança não existe no repositório.** Não há `firestore.rules`, `firebase.json` nem `.firebaserc` — nem no histórico do git. As regras vivem apenas no console do Firebase, não versionadas e não verificáveis.
2. **Falhas de escrita são invisíveis.** [app.js:777](../app.js#L777) exibe "Gasto lançado com sucesso" antes de saber se o dado foi gravado, e uma falha trava a sincronização remota em silêncio.
3. **Faltam os requisitos obrigatórios da Apple** — exclusão de conta in-app, política de privacidade, e defesa contra a Guideline 4.2 (app que é "só um site empacotado").

**Decisões já tomadas:** Capacitor (sem reescrita), push migrando para APNs via FCM, CPF removido por completo, grátis na v1 com espaço arquitetural para cobrar depois, ritmo "sem pressa, bem feito".

**Resultado esperado:** app aprovado e listado publicamente na App Store, com dados isolados por usuário de forma verificável, sem perda silenciosa de lançamentos, e em conformidade com LGPD e com as regras da Apple.

---

## ⚠️ Duas ações manuais urgentes (antes de qualquer código)

1. **Verificar as rules no console do Firebase** → Firestore → Regras. Se estiver `allow read, write: if true`, os dados de todos os usuários estão abertos agora.
2. **Apagar a conta de teste** `ux.qa.minhasobras@gmail.com` no Firebase Auth. A senha está em texto puro em [docs/ux-review-2026-07-08.md:8](ux-review-2026-07-08.md#L8), num repositório público. Apagar o usuário, não só trocar a senha.

---

## Fase 0 — Fronteira de segurança + iniciar o relógio da Apple

**Trilha administrativa (começa já, roda semanas em paralelo):**

- Decidir **pessoa física vs. empresa**. Pessoa física publica o nome legal na página da loja; empresa exige CNPJ + D-U-N-S e adiciona semanas.
- Matricular no Apple Developer Program (US$ 99/ano).
- Criar o registro no App Store Connect, **reservar o nome "ObraControl"** (é por ordem de chegada) e registrar o bundle ID `com.<seu>.obracontrol`.
- A chave APNs (`.p8`) que a Fase 4 precisa só pode ser gerada com a conta matriculada. **A Fase 4 está travada nesta matrícula.**

**Trilha de código:**

| Item | Arquivos |
|---|---|
| Criar `firestore.rules`, `firebase.json`, `.firebaserc` e fazer deploy | novos na raiz |
| Testes das rules com `@firebase/rules-unit-testing` + emulador | novo `tests/rules.test.mjs` + `package.json` na raiz |
| Redigir a linha da credencial vazada | [docs/ux-review-2026-07-08.md:8](ux-review-2026-07-08.md#L8) |
| Endurecer `.gitignore`: `*serviceAccount*.json`, `.env*`, `*.p8`, `*.p12`, `*.pem`, `*.mobileprovision`, `.superpowers/`, `ios/`, `node_modules/`, `www/` | [.gitignore](../.gitignore) |
| Rodar `gitleaks detect` no histórico completo | — |
| **Apagar a migração de localStorage legado** — vazamento entre contas: varre `obras_data_v1*` de *qualquer* usuário anterior do navegador e importa pra conta logada agora. Código morto além de inseguro. | [app.js:1259-1273](../app.js#L1259-L1273) |
| Chamar `desativaPush()` no logout — hoje a inscrição sobrevive à troca de conta, e o usuário B recebe notificações geradas com os dados do usuário A | [app.js:1046-1052](../app.js#L1046-L1052), [auth.js:38](../auth.js#L38) |

**As rules:**

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    function meu(uid) { return request.auth != null && request.auth.uid == uid; }

    match /dados/{uid} {
      allow get: if meu(uid);
      allow list: if false;
      allow create, update: if meu(uid) && blobOk();
      allow delete: if meu(uid);
      function blobOk() {
        let d = request.resource.data;
        return d.keys().hasOnly(['obras','config','_atualizado'])
            && d.obras is list && d.obras.size() <= 300
            && d.config is map
            && d.config.keys().hasOnly(['taxaMensal','topicosCustom'])
            && d.config.taxaMensal is number
            && d.config.taxaMensal > 0 && d.config.taxaMensal <= 20
            && d.config.topicosCustom is list
            && d.config.topicosCustom.size() <= 50;
      }
    }

    // 'plano' é deliberadamente não-gravável pelo cliente — só o Admin SDK escreve.
    // É isso que deixa espaço pra cobrar depois sem migração dolorosa.
    match /perfis/{uid} {
      allow get: if meu(uid);
      allow list: if false;
      allow create: if meu(uid)
                    && request.resource.data.keys().hasOnly(['email','criado','tz'])
                    && request.resource.data.email == request.auth.token.email;
      allow update: if meu(uid)
                    && request.resource.data.diff(resource.data)
                         .affectedKeys().hasOnly(['email','tz']);
      allow delete: if meu(uid);
    }

    match /push/{uid} {
      allow get: if meu(uid);
      allow list: if false;
      allow write: if meu(uid)
                   && request.resource.data.keys().hasOnly(['subs','tokens'])
                   && (!('tokens' in request.resource.data)
                       || request.resource.data.tokens.size() <= 10)
                   && (!('subs' in request.resource.data)
                       || request.resource.data.subs.size() <= 10);
      allow delete: if meu(uid);
    }

    match /{document=**} { allow read, write: if false; }
  }
}
```

O `hasOnly(['email','criado','tz'])` em `perfis` faz as próprias rules rejeitarem o CPF — a remoção da Fase 2 passa a ser estruturalmente garantida.

**Fora desta fase: App Check.** Ele usa reCAPTCHA no SDK JS, que é atrelado a domínio. Dentro do Capacitor o código roda em `capacitor://localhost`, que não é domínio registrável — ativar em enforce agora significa descobrir na Fase 4 que o build iOS toma `permission-denied` em 100% das operações. Não é exigência da Apple. Fica opcional na Fase 4, com atestação nativa.

**Pronto quando:** as rules estão no git e em produção; o teste no emulador prova que o usuário A não lê nem escreve `dados` do B, não grava `cpf` em `perfis`, não grava `plano`, e não faz `list` de coleção nenhuma; a conta vazada não existe mais; `gitleaks` limpo.

**Verificar (tudo no Windows):** `firebase emulators:exec --only firestore "node --test tests/rules.test.mjs"`. Depois, no app em produção, tentar pelo devtools `setDoc(doc(db,'dados','uid-alheio'), {})` → precisa dar `permission-denied`.

---

## Fase 1 — Confiabilidade dos dados

**A fase de maior severidade do plano.** Trava a Fase 2 (exclusão de conta precisa de escritas confiáveis e erros visíveis).

1. **Destravar o deadlock do `dirty`.** [cloud.js:46](../cloud.js#L46) engole a falha e não agenda nada; `dirty` fica `true` pra sempre; [app.js:1276](../app.js#L1276) então retorna cedo em todo snapshot seguinte. Uma escrita falha congela a sincronização remota até um save posterior dar certo por acaso. Corrigir com retry em backoff exponencial (1s, 2s, 4s… teto 30s) e limpar `dirty` em falha terminal, depois de mostrá-la.
2. **`saveDados` retorna promise.** [cloud.js:74-79](../cloud.js#L74-L79) é fire-and-forget. Precisa resolver quando gravou e rejeitar quando falhou de vez.
3. **Toast depois da promise.** [app.js:777](../app.js#L777) e os demais pontos de `save()`: [app.js:647](../app.js#L647), [:654](../app.js#L654), [:1116](../app.js#L1116), [:1131](../app.js#L1131), [:1143](../app.js#L1143).
4. **Callback de erro no `onSnapshot`** — [cloud.js:65-72](../cloud.js#L65-L72) não tem. Sem ele, as rules novas da Fase 0 poderiam quebrar o app sem ninguém ver.
5. **Indicador de sincronização** — salvo / salvando / sem conexão. [cloud.js:69](../cloud.js#L69) já passa `fromCache` e [app.js:1276](../app.js#L1276) nunca lê. Somar listeners de `navigator.onLine`.
6. **Expiração de sessão** — o token dura 1h; a renovação falha offline ou com conta revogada. Tratar `onAuthStateChanged(null)` no meio da sessão com mensagem real.
7. **Corrigir `logout()`** ([cloud.js:60](../cloud.js#L60)) — hoje faz `pendingBlob = null` antes do `signOut`, destruindo trabalho não salvo em silêncio. Precisa aguardar o flush.
8. **Captura global de erro** — `window.onerror` + `unhandledrejection`. E os catches vazios em [index.html:786](../index.html#L786) e [app.js:1266-1269](../app.js#L1266-L1269).
9. **Guarda de tamanho do documento** — avisar acima de ~700KB serializados. Rules do Firestore não conseguem medir bytes; o limite de 1MB não tem proteção server-side. A ~150 bytes por gasto isso dá ~6.500 gastos — anos de uso, mas é um precipício sem grade.
10. **Decidir monitoramento de erro agora**, não depois — é insumo da política de privacidade e dos App Privacy labels. Recomendação: Sentry browser SDK servido da própria origem (sem CDN), amostrado.

**Pronto quando:** com o devtools offline, lançar um gasto mostra "salvando", não "sucesso"; ao voltar a rede o dado sobe e *aí* aparece o sucesso; matar a rede no meio da escrita e restaurar depois faz o dado chegar sem reload; após um `permission-denied` forçado o app mostra erro em vez de congelar.

**Verificar:** estender o procedimento Playwright de .claude/skills/verify/SKILL.md com alternância offline/online via CDP. É o primeiro teste e2e real e vira o molde da Fase 3.

---

## Fase 2 — Conformidade

**Concluída em 2026-09-09**, conforme testes locais e validação de produção relatada pelo usuário. Contato: suportecustta@gmail.com. Confirmação do responsável e revisão definitiva da política seguem para Fase 4, após congelamento dos SDKs.

**Exigências da Apple:** exclusão de conta in-app (Guideline 5.1.1(v)) e política de privacidade em URL viva. **Escolhas de qualidade:** verificação de e-mail, exportação de dados, texto de consentimento.

Termos de uso **não** entram — a EULA padrão da Apple já se aplica a apps gratuitos. Só a política de privacidade é obrigatória.

| Item | Arquivos |
|---|---|
| Reautenticação (`reauthenticateWithCredential`) — pré-requisito rígido da exclusão | [auth.js](../auth.js), novo `ui-confirm.js` |
| Troca de senha in-app | [auth.js](../auth.js) |
| **Exclusão de conta** em Ajustes | [app.js:1054-1147](../app.js#L1054-L1147), [cloud.js](../cloud.js) |
| Remover CPF: campo, máscara, validador | [auth.js:8-26](../auth.js#L8-L26), [:75-76](../auth.js#L75-L76), [:131-133](../auth.js#L131-L133), `#cCpf` em [index.html](../index.html) |
| Remover `cpf` da escrita de perfil | [cloud.js:56-57](../cloud.js#L56-L57) |
| **Expurgar os CPFs já gravados** — script Admin SDK avulso | novo `notificacoes/scripts/purga-cpf.mjs` |
| Gravar `tz` por usuário em `perfis` — hoje o cron é fixo em `America/Sao_Paulo` | [notificacoes/envia.js:22](../notificacoes/envia.js#L22), [cloud.js](../cloud.js) |
| Exportação de dados (CSV de gastos + JSON de backup) atrás de um adaptador `share.js` | novo `share.js`, Ajustes em [app.js](../app.js) |
| Verificação de e-mail: `sendEmailVerification` + banner suave + reenvio | [auth.js](../auth.js) |
| Página de privacidade em pt-BR na Vercel + link em Ajustes | novo `privacidade.html` |

**Verificação de e-mail fica como aviso, nunca bloqueio.** E **não** colocar `email_verified` nas rules na v1 — o usuário real é uma pessoa de 60 e poucos anos, não técnica, que ficaria trancada fora dos próprios dados de obra por causa de um filtro de spam.

**A política de privacidade é rascunhada aqui, mas congelada só na Fase 4**, quando a lista de SDKs estiver fechada (FCM coleta token de dispositivo; Sentry coleta diagnóstico). Os App Privacy labels da Fase 5 saem dessa mesma lista congelada. Inverter essa ordem produz labels que não batem com o binário — o que é reprovação e pode virar remoção depois.

### A ordem da exclusão de conta — errar aqui é o modo mais comum de quebrar isso

1. Confirmar com texto digitado, não com um toque só.
2. Reautenticar.
3. **Bloquear se estiver offline** — os deletes ficariam na fila, o token morreria, nada chegaria.
4. Apagar `dados/{uid}`, `perfis/{uid}`, `push/{uid}` — **com o token ainda válido.**
5. Cancelar push / apagar o token FCM.
6. **Só então** chamar `deleteUser()`.
7. `terminate()` + `clearIndexedDbPersistence()` + reload.

Chamar `deleteUser()` antes faz o cliente perder na hora a permissão de apagar os próprios documentos — eles ficam órfãos no Firestore pra sempre, sem forma de limpar a não ser por script administrativo.

**Pronto quando:** uma conta descartável é criada, populada, exportada e apagada de ponta a ponta; depois disso o console do Firebase não mostra nenhum usuário nem documento `dados`/`perfis`/`push`; o cadastro não tem campo de CPF; o script de expurgo rodou e `perfis` tem zero campos `cpf`.

---

## Fase 3 — Endurecimento e prontidão para nativo

**Concluída em 2026-09-09.** Implementação publicada (cache v38), testes locais e [GitHub Actions](https://github.com/gstuchi/app_construcao_civil/actions/runs/34426925894) passaram. Produção abriu com SDK local e CSP sem violações. Detalhes em [execução da Fase 3](plans/2026-09-09-fase3.md). Itens abaixo preservam diagnóstico e roteiro originais; referências de linhas são históricas.

**Porta de entrada da Fase 4.** A ordem interna importa — CSP por último.

1. **Escapar os pontos de XSS.** `escapeHtml()` existe em [app.js:74](../app.js#L74) e é usado em ~14 lugares, mas **não** em [app.js:380](../app.js#L380), [:567](../app.js#L567), [:724](../app.js#L724), [:864](../app.js#L864) — exatamente onde caem os nomes de `topicosCustom`, que são texto livre sem sanitização nem limite ([app.js:1139-1141](../app.js#L1139-L1141)). Hoje é só auto-XSS, mas a severidade **sobe** quando empacotado: é execução de código dentro de um WKWebView com acesso à ponte do Capacitor.
2. **Limites de tamanho e trim:** nome da obra ([app.js:638-641](../app.js#L638-L641)), descrição do gasto ([:759](../app.js#L759), [:765](../app.js#L765)), tópico customizado. No DOM (`maxlength`) *e* no JS.
3. **Endurecer `normaliza()`** ([app.js:40-44](../app.js#L40-L44)) — hoje é um spread raso sem checagem de tipo. Validar, coagir, descartar elementos malformados, e **preservar chaves desconhecidas**. Isso vira crítico: web e iOS vão conviver em versões diferentes escrevendo no mesmo documento, permanentemente.
4. **Corrigir o clamp silencioso da taxa** em [app.js:1112-1117](../app.js#L1112-L1117) — valores acima de 20 viram 1 sem mensagem.
5. **Empacotar o SDK do Firebase localmente.** [cloud.js:4-12](../cloud.js#L4-L12) busca três módulos ESM do `gstatic.com` em runtime. Em app nativo isso significa: primeira abertura sem rede = app morto. E a revisão da Apple costuma acontecer em rede limitada. **Porta rígida da Fase 4.**
6. **Extrair o CSS inline** ([index.html:34-534](../index.html#L34-L534)) para `styles.css` e os três `<script>` inline ([:20](../index.html#L20), [:575](../index.html#L575), [:777](../index.html#L777)) para arquivos. Movimentação pura, sem mudança de lógica. Atualizar `ASSETS` e o `CACHE` de [sw.js](../sw.js).
7. **CSP**, só depois do item 6:
   ```
   default-src 'none'; script-src 'self'; style-src 'self';
   img-src 'self' data:; font-src 'self';
   connect-src 'self' https://*.googleapis.com https://*.firebaseio.com
               wss://*.firebaseio.com https://firestore.googleapis.com
               https://identitytoolkit.googleapis.com https://securetoken.googleapis.com;
   base-uri 'none'; form-action 'none'; frame-ancestors 'none';
   ```
8. **`package.json` na raiz + CI.** Ligar os 5 testes `.cjs` existentes ao `node --test`, somar Playwright cobrindo: login, criar obra, lançar gasto, escrita offline + flush ao reconectar, exclusão de conta. GitHub Actions no push. **Registrar no README que isso introduz npm como ferramenta, não como build — o app continua sem build**, conforme o princípio 5 do PRODUCT.md.
9. Atualizar a documentação defasada: [PRODUCT.md:13](../PRODUCT.md#L13) ainda diz localStorage + login por CPF; o comentário de cabeçalho em [app.js:1](../app.js#L1) idem.

**Pronto quando:** CSP ativa sem `unsafe-inline` em lugar nenhum e zero violações no console; o app abre e funciona por completo com `gstatic.com` bloqueado no devtools; um tópico chamado `<img src=x onerror=alert(1)>` aparece como texto literal em todas as telas; CI verde.

---

## Fase 4 — Empacotamento com Capacitor

**Código concluído em 2026-09-16** na branch `feat/fase4` (spec em `docs/specs/` e plano em `docs/plans/`). Build, TestFlight e push real dependem da matrícula Apple — ver [checklist de aparelho](plans/2026-09-16-fase4-checklist-aparelho.md).

**Travada por:** Fase 0 (bundle ID, chave APNs, conta) e Fase 3 (SDK local, CSP).

### 4a — Esqueleto do projeto (tudo possível no Windows)

`npx cap init` com o bundle ID reservado. Um `scripts/build-www.mjs` de ~30 linhas copia os arquivos web para `www/` — mantém o `webDir` limpo sem introduzir bundler. `npx cap add ios` funciona no Windows (só materializa o projeto Xcode; `pod install` e `xcodebuild` não). **Commitar `ios/`** — sem Mac, as edições de `Info.plist` precisam estar versionadas.

No `Info.plist`: `ITSAppUsesNonExemptEncryption = false` (só usa HTTPS, é isento — pula a pergunta de conformidade a cada build), orientação retrato, `TARGETED_DEVICE_FAMILY = 1` (só iPhone — corta pela metade o conjunto de screenshots exigido).

### 4b — O que precisa sumir ou ser condicionado no nativo

| O quê | Onde | Ação |
|---|---|---|
| Banner "instalar PWA" (`beforeinstallprompt`) | [app.js:1244-1251](../app.js#L1244-L1251) | Esconder |
| Texto "abra no Safari… Adicionar à Tela de Início" | [app.js:1081-1083](../app.js#L1081-L1083) | Trocar por texto de notificação nativa — essa frase dentro de um binário da App Store é sinalização instantânea pro revisor |
| Registro do SW + reload por `controllerchange` | [index.html:777-788](../index.html#L777-L788) | Pular no nativo |
| `window.print()` | [app.js:837](../app.js#L837), [:904](../app.js#L904) | Vira PDF pro share sheet, ou some — impressão não funciona em WKWebView e falha em silêncio |
| `confirm()` / `alert()` | [app.js:321](../app.js#L321), [:576](../app.js#L576), [:651](../app.js#L651), [:1128](../app.js#L1128), [:1129](../app.js#L1129); [auth.js:38](../auth.js#L38) | `ui-confirm.js` — **obrigatório**, viram no-op silencioso sem `WKUIDelegate` |
| `user-scalable=no` | [index.html:5](../index.html#L5) | **Remover.** O Safari ignora desde o iOS 10, mas o WKWebView **obedece** — empacotar desativaria o pinch-zoom pra um usuário que o PRODUCT.md descreve usando óculos de leitura |
| `persistentMultipleTabManager` | [cloud.js:26](../cloud.js#L26) | → `persistentSingleTabManager` |
| Gambiarra de teclado com `visualViewport` | [app.js:1152-1166](../app.js#L1152-L1166) | Retestar contra `@capacitor/keyboard` — pode ter virado redundante ou conflitante |

### 4c — Push para FCM/APNs

Exige a chave `.p8` da Fase 0, subida no console do Firebase. `@capacitor/push-notifications` + `@capacitor-firebase/messaging`; extrair [app.js:1005-1052](../app.js#L1005-L1052) para `push.js` com implementação web e nativa atrás de uma interface.

`push/{uid}` fica bi-formato: `subs` (web push, PWA existente) e `tokens` (FCM) — as rules da Fase 0 já aceitam ambos. [notificacoes/envia.js](../notificacoes/envia.js) envia pelos dois caminhos. Ligar `pushNotificationActionPerformed` → `openObra(id)`.

**Migrar o cron do GitHub Actions para Vercel Cron.** O próprio [notificacoes/README.md:48](../notificacoes/README.md#L48) registra que o GitHub desativa cron após 60 dias de inatividade do repositório — num app público, as notificações simplesmente parariam um dia.

### 4d — Adições nativas que respondem à Guideline 4.2

Este é o maior risco de reprovação e nenhum item dele é código de fachada: `@capacitor/share` (exportação pelo share sheet nativo), `@capacitor/haptics` na confirmação de gasto, `@capacitor/status-bar` sincronizado ao tema ([app.js:983-1002](../app.js#L983-L1002)), `@capacitor/splash-screen` no lugar de [splash.js](../splash.js) no nativo, `@capacitor/app` para descarregar escritas pendentes ao ir pra segundo plano.

### 4e — Riscos que só aparecem no aparelho

- **Persistência da sessão.** O SDK JS guarda a sessão em IndexedDB, e o iOS pode despejar dados do WKWebView sob pressão de armazenamento. Se o usuário for deslogado do nada, o plano B é `@capacitor-firebase/authentication` (SDK nativo) — o que é reescrever `cloud.js`. Testar: instalar, logar, matar o app, deixar uma semana, reabrir.
- **Restauração de estado.** O iOS mata apps em segundo plano com frequência, e ao voltar o WKWebView recarrega do zero e cai no Início. **Não precisa de router** — 15 linhas persistindo `{tab, obraAberta}` em `localStorage` dentro de `showView()` ([app.js:102](../app.js#L102)) e `openObra()` ([app.js:115](../app.js#L115)), restaurando em `bootCloud()` depois do primeiro snapshot, com a guarda que já existe em [app.js:1281](../app.js#L1281).
- **Congelar a lista de SDKs e publicar a política de privacidade aqui.**

**Atualização do app: só por release da App Store.** Sem OTA na v1 — Appflow é pago, e OTA self-hosted acrescenta superfície de assinatura, rollback e versionamento pra operar, além de permitir mandar código não testado pra um aparelho que você não consegue depurar. Com um usuário real, 24-48h de revisão é aceitável. Somar ~20 linhas: constante `APP_VERSAO` no build, um `versao.json` na Vercel, e um banner dispensável em Ajustes com link `itms-apps://` quando houver versão nova.

**Pronto quando:** um build TestFlight instala no seu iPhone; um push chega com o app fechado e abre a obra certa; abrir em modo avião funciona; a exclusão de conta funciona a partir do binário; nenhum `confirm()` some em silêncio; o pinch-zoom funciona.

---

## Fase 5 — Máquina de build e submissão

**Você não precisa comprar um Mac.** O ciclo inteiro roda em **GitHub Actions com runner `macos-latest`**:

- Gerar o CSR com `openssl` no Windows → subir no portal da Apple → baixar o `.cer` → converter em `.p12` com `openssl`. Nenhum Mac envolvido nos certificados.
- Criar uma API key do App Store Connect (`.p8`) pela web.
- Workflow em `macos-latest`: `npm ci` → `build-www` → `npx cap sync ios` → `pod install` → `xcodebuild archive` → `-exportArchive` → upload via `notarytool` ou fastlane `pilot`.
- Guardar `.p12`, senha, API key, issuer ID e key ID como secrets do GitHub. Keychain temporária no CI.
- Repositório privado dá 2.000 minutos/mês, com multiplicador **10x para macOS** = ~200 minutos de macOS. Um build Capacitor leva 8-12 min → 15-20 builds/mês de graça. Suficiente pro ritmo "sem pressa".
- **O TestFlight é o seu laço de teste em aparelho.** O CI sobe o build, você instala no seu iPhone pelo app do TestFlight, e testa tudo da 4e em hardware real.

Comprar um Mac mini só se você bater numa parede que o log do CI não resolve — na prática, o Safari Web Inspector, que precisa de Mac pra anexar num WKWebView. Mitigação: o Sentry da Fase 1 te dá visibilidade remota de erro no lugar disso.

**Trilha de metadados — fazer no Windows, em paralelo com a Fase 4:**

- **Screenshots:** 6.7"/6.9" de iPhone. Renderizar em 1290×2796 no devtools do Chrome contra o app real com dados de obra realistas.
- Descrição, palavras-chave, subtítulo, texto promocional — tudo em pt-BR.
- URL de suporte + URL da política de privacidade, ambas vivas na Vercel.
- Questionário de classificação etária; "Feito para crianças" = não.
- **App Privacy labels** derivados da lista de SDKs congelada: e-mail (vinculado à identidade, funcionalidade do app), conteúdo do usuário (os dados de obra), identificador de dispositivo (o token FCM), e diagnóstico se o Sentry entrar. Não chutar — labels que não batem com o binário derrubam o app depois de aprovado.
- **Conta de demonstração para a revisão (Guideline 2.1) — obrigatória**, já que o app inteiro fica atrás de login. Criar uma conta nova (não a que foi rotacionada na Fase 0) e **populá-la com 2-3 obras realistas e algumas dezenas de gastos**, pra que o revisor veja um produto funcionando em vez dos seus (ótimos) empty states.
- **Notas de revisão em inglês**, cobrindo: o app é só em português e voltado ao Brasil; é baseado em conta porque os dados sincronizam entre dispositivos do usuário; a exclusão de conta fica em Ajustes → Apagar conta; o push entrega um resumo diário de custos; e funciona por completo offline — convidando o revisor a testar em modo avião. Essa última linha é a resposta direta a um questionamento de Guideline 4.2.

**Não se aplica, não gaste tempo:** a Guideline 4.8 (Sign in with Apple) só dispara com login social de terceiros (Google, Facebook). E-mail + senha do Firebase é sistema de conta próprio.

---

## Fase 6 — Pós-lançamento

Acompanhar o Sentry na primeira semana. Ter o caminho de hotfix ensaiado (CI → pedido de revisão expedita). Confirmar que o cron do FCM dispara no agendador novo. Manter o PWA da Vercel e o binário iOS em versões travadas uma na outra, já que compartilham um único documento no Firestore. Só depois de tudo isso: considerar StoreKit contra a flag `plano` construída na Fase 0.

---

## Decisões deliberadas de escopo

**Não quebrar `app.js` em módulos.** 1288 linhas não é monolito pro que importa aqui: o Capacitor não analisa o seu JS, a Apple não lê o seu código, e não há bundler pra otimizar. Refatorar um arquivo de 61KB com **zero cobertura de teste** é troca ruim — você entrega um app funcionando em produção por uma caça a regressões sem instrumentação. Quatro extrações pequenas acontecem porque o trabalho as força, não por estética: `push.js` (a 4c reescreve isso de qualquer jeito), `ui-confirm.js` (~40 linhas, obrigatório), `styles.css` (movimentação pura, exigida pela CSP), e o crescimento de `cloud.js`. **As funções de render não se tocam.**

**Sem router e sem deep-link.** Botão físico de voltar é Android; o gesto de swipe-back do WKWebView fica desligado por padrão e assim deve continuar; abrir a obra certa pelo push é uma chamada de função (`openObra(id)`), não uma URL; e não há compartilhamento nem funil web. O único problema real é restauração de estado, resolvido em 15 linhas na 4e.

**Sem criptografia dos dados em repouso.** No iOS o contêiner do app — incluindo o IndexedDB do WKWebView — já recebe `NSFileProtectionCompleteUntilFirstUserAuthentication` por padrão, com chave derivada do código do aparelho. É a mesma proteção que o SQLite de qualquer app nativo tem. Depois de remover o CPF, o dado é custo de obra do próprio usuário: sem dado de saúde, sem credencial de pagamento, sem documento. E nem seria implementável — o `persistentLocalCache` do SDK JS não expõe gancho de criptografia.

**O problema real ali é vazamento entre contas, não criptografia.** O Firestore nomeia o cache por `projectId`, não por uid — o `dados/{uidA}` fica no mesmo IndexedDB depois que A sai e B entra. O app não *exibe*, mas é trivialmente recuperável. Resolvido pela sequência de logout da Fase 2 (flush → signOut → terminate → clear → reload), com o `desativaPush()` da Fase 0 fechando o vazamento pior, que está vivo em produção agora.

---

## Grafo de dependências

```
matrícula Apple ──────────► chave APNs ──► Fase 4c (push)
       └──► bundle ID ─────────────────┬──► Fase 4a
                                       └──► Fase 5

Fase 0 rules ──► Fase 1 erros visíveis (rules agora podem quebrar o app em silêncio)
Fase 1 ────────► Fase 2 exclusão (precisa de escrita confiável e falha visível)
Fase 1 ────────► Fase 2 limpeza no logout (flush antes de apagar o IndexedDB)
Fase 2 reauth ─► Fase 2 exclusão (deleteUser exige login recente)
Fase 3 SDK local ──────► Fase 4 (PORTA RÍGIDA: SDK de CDN = app morto offline)
Fase 3 extração CSS/JS ► Fase 3 CSP ──► Fase 4 (origens do Capacitor)
Fase 3 normaliza() ────► Fase 4 (defasagem permanente entre web e iOS)
Fase 4 lista de SDKs congelada ──► política publicada ──► Fase 5 labels
Fase 2 export web ─────► Fase 4d (ramo nativo do share)
```

**Três armadilhas de ordem, releia antes de começar:**
1. Documentos do Firestore são apagados **antes** do `deleteUser()`, nunca depois.
2. Escritas pendentes são descarregadas **antes** do `clearIndexedDbPersistence()`.
3. Política de privacidade e App Privacy labels são escritos **depois** que a lista de SDKs congela, não na Fase 2.

---

## Como verificar o conjunto

| Fase | Verificação |
|---|---|
| 0 | `firebase emulators:exec --only firestore "node --test tests/rules.test.mjs"` — usuário A não alcança dados do B, `cpf` e `plano` rejeitados, `list` negado em toda coleção. `gitleaks detect` limpo no histórico. |
| 1 | Playwright com CDP alternando offline/online: lançar gasto offline mostra "salvando"; reconectar sobe o dado e mostra sucesso; `permission-denied` forçado exibe erro em vez de congelar. |
| 2 | Ciclo completo numa conta descartável contra o Firebase de produção: criar → popular → exportar → apagar. Console mostra zero usuário e zero documento nas três coleções. |
| 3 | CSP ativa sem `unsafe-inline` e sem violação no console; app funciona com `gstatic.com` bloqueado; tópico `<img src=x onerror=alert(1)>` renderiza como texto; CI verde. |
| 4 | Build TestFlight no iPhone real: push com app fechado abre a obra certa; modo avião funciona; exclusão de conta funciona no binário; pinch-zoom funciona; nenhum `confirm()` some. |
| 5 | Build no App Store Connect, metadados completos, conta de demonstração populada, notas de revisão em inglês, submetido. |

**Cada fase vira sua própria spec + plano de implementação** antes de virar código, seguindo o fluxo que o projeto já usa em `docs/specs/` e `docs/plans/`.
