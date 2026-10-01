# SDKs congelados — Fase 4

Data: 2026-09-16. Base da política de privacidade e dos App Privacy labels da Fase 5.
Mudou algo aqui? Revisar `privacidade.html` e os labels **antes** de publicar.

| SDK | Versão | Onde roda | Dados que coleta ou transmite | Finalidade |
| --- | --- | --- | --- | --- |
| firebase 12.18.0 (Auth) | 12.18.0 | web + iOS (JS) | e-mail, uid, token de sessão | conta |
| firebase 12.18.0 (Firestore) | 12.18.0 | web + iOS (JS) | obras, gastos, afazeres, fuso horário | funcionalidade |
| @sentry/browser | 10.74.0 | web + iOS (JS) | diagnóstico sanitizado (sem mensagem livre, conta ou dado de obra) | diagnóstico |
| @capacitor-firebase/messaging | 8.5.1 | iOS (nativo) | token de dispositivo FCM/APNs | notificações |
| @capawesome/capacitor-apple-sign-in | 0.1.4 | iOS (nativo) | token de identidade e código de autorização da Apple; nome e e-mail no 1º login (repassados ao Firebase Auth) | conta |
| @capawesome/capacitor-google-sign-in | 0.1.4 | iOS (nativo) | token de identidade do Google; e-mail e nome da conta Google (repassados ao Firebase Auth). O SDK GoogleSignIn-iOS 8 declara no manifesto próprio também telefone, localização aproximada, ID de usuário, ID de dispositivo e dados de uso — ver "App Privacy labels" em `docs/app-store-metadados.md` | conta |
| @capacitor/core, @capacitor/cli, @capacitor/ios | 8.5.2 | iOS | nenhum dado próprio | ponte nativa |
| @capacitor/app | 8.1.1 | iOS | nenhum | estado do app |
| @capacitor/share, @capacitor/filesystem | 8.0.2, 8.1.3 | iOS | arquivo exportado, só no aparelho | exportação |
| @capacitor/haptics, @capacitor/status-bar, @capacitor/splash-screen | 8.0.2, 8.0.3, 8.0.2 | iOS | nenhum | interface |
| web-push, firebase-admin | 3.6.7, 14.4.0 | servidor (cron) | lê push/{uid}, dados/{uid}, perfis/{uid}.tz | resumo diário |

**Atenção ao atualizar o `@capacitor-firebase/messaging`:** o plugin do Google prende o GoogleSignIn-iOS 8, que exige app-check 11 e gtm-session-fetcher < 4. O Firebase iOS 13 exige app-check 12 e gtm-session-fetcher ≥ 4: com os dois, o SPM não resolve as dependências até o plugin do Google subir de versão. O `ios-build.yml` acusa isso no PR.
