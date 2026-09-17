# Fase 4 — o que só valida com Apple, Xcode e iPhone

Código pronto em `feat/fase4`. Itens abaixo dependem de matrícula Apple, Xcode ou aparelho.

## Antes do primeiro build
- [ ] Matricular no Apple Developer Program; trocar `com.gstuchi.custta` pelo bundle ID reservado em `capacitor.config.json` e rodar `npm run cap:sync`.
- [ ] Firebase → adicionar app iOS com o bundle ID → baixar `GoogleService-Info.plist` → arrastar para `ios/App/App/` no Xcode (target App). Sem ele o app fecha ao abrir.
- [ ] Gerar chave APNs `.p8` e subir em Firebase → Cloud Messaging → Apple app configuration.
- [ ] Xcode → Signing & Capabilities: Team, "Push Notifications" e "Background Modes › Remote notifications".
- [ ] Preencher `versao.json` → `loja` com `itms-apps://apps.apple.com/app/id<ID>` depois de criar o app no App Store Connect.
- [ ] Google Cloud Console → Credenciais → checar se a API key web do Firebase tem restrição de HTTP referrer/app. Se tiver, `capacitor://localhost` falha Auth/Firestore no app nativo — liberar esse esquema ou remover a restrição.

## No iPhone (TestFlight)
- [ ] Instalar, logar, matar o app, reabrir: continua logado e na mesma tela/obra.
- [ ] Modo avião na primeira abertura após instalar: app abre e lista obras do cache.
- [ ] Lançar gasto: vibra ao confirmar; teclado numérico e folhas não ficam atrás do teclado do iOS (gambiarra `visualViewport`).
- [ ] Pinch-zoom funciona.
- [ ] Excluir gasto, apagar obra, remover tópico, sair: diálogo aparece (nada some calado).
- [ ] Relatório → "Compartilhar planilha" abre o share sheet.
- [ ] Tema claro/escuro troca a cor do texto da barra de status.
- [ ] Ativar notificações → token aparece em `push/{uid}.tokens` no console.
- [ ] GitHub Actions → push-diario → Run workflow: notificação chega com o app fechado e abre a obra certa quando o resumo é de uma obra só.
- [ ] Ativar notificações, desligar a rede (modo avião), tentar Sair e Apagar conta: cada ação deve concluir ou falhar com mensagem de conexão — nunca travar por causa do token do FCM.
- [ ] Apagar conta pelo app: `dados`, `perfis`, `push` somem no console.
- [ ] Deixar uma semana sem abrir e reabrir: sessão persiste (se não, plano B: `@capacitor-firebase/authentication`).
- [ ] Na primeira preview da Vercel, aba Functions: confirmar que `api/push-diario` foi empacotada.

## Validado nesta máquina (2026-09-17)
- Testes unitários (76/76), rules no emulador (34/34) e browser (Playwright, incluindo `tests/browser/nativo.cjs` com Capacitor simulado) — todos verdes. `npm run cap:sync` concluído (sem Xcode instalado: nenhum build nativo).
- agent-browser (v0.38.1): web em 390×844 e 1280×800 — meta viewport sem `user-scalable`, tela de login renderiza nos dois tamanhos, `console`/`errors` sem violação de CSP nem erro.
- Diferente do que o plano original previa, `agent-browser open --init-script <arquivo>` **consegue** injetar `window.Capacitor` e `window.CLOUD` falsos antes do primeiro carregamento (via `--init-script`, registrado antes da navegação). Com isso, validado também nesta máquina em modo nativo simulado: app abre em "modo nativo" (`Capacitor.getPlatform() === 'ios'`), lista a obra vinda do `CLOUD` falso, o botão de Relatório mostra "Compartilhar planilha" e o "×" de um lançamento abre o diálogo `OBRA_CONFIRM` ("Excluir este gasto?" com Cancelar/Excluir) em vez de um `confirm()` nativo do navegador. A cobertura automatizada de regressão desses fluxos continua sendo `tests/browser/nativo.cjs` (roda no CI via `npm run test:browser`); a checagem com agent-browser aqui foi exploratória/manual, não uma suíte nova.
