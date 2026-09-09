# Fase 2 — Conta e privacidade

Implementar no PWA vanilla, preservando uso offline e acesso sem verificar e-mail.
A Fase 1 foi validada localmente; publicação de v33 ainda não confirmada.

## Fluxos

- Ajustes oferece exportação JSON (estado completo, versão e data) e CSV de gastos.
  Exporta estado atual, inclusive alterações locais; CSV protege contra fórmulas.
  Adaptador web usa compartilhamento de arquivos quando disponível ou download.
- Conta mostra e-mail e aviso não bloqueante de verificação, com reenvio explícito.
  Trocar senha pede senha atual e nova senha. Nunca persistir senhas nem diagnosticá-las.
- Apagar conta pede senha e texto APAGAR. Reautentica online, sincroniza fila,
  interrompe novas edições e apaga dados/perfis/push em batch antes de deleteUser.
  Falha após apagar documentos é explicitada e permite repetir exclusão.
- Logout sincroniza antes de signOut, terminate, clearIndexedDbPersistence e reload.
  Marcador local permite retomar limpeza após interrupção; falha de cache impede
  novo login e orienta fechar outras abas antes de repetir limpeza.
- Web Locks mantém trava compartilhada por aba e exige exclusividade durante
  logout/exclusão. Outra aba aberta impede a operação antes de qualquer delete.
  Navegador sem essa API recebe orientação de atualização. Não cobre outro aparelho.
- Cancelamento da inscrição push antecede o batch, pois a implementação web
  remove um campo com setDoc; executá-la depois recriaria o documento apagado.
- Novo cadastro grava fuso IANA. Cron usa fuso do perfil para data, mantendo horários
  existentes do agendador. Script de CPF é paginado, dry-run padrão, sem valores nos logs.
- Privacidade é rascunho nesta fase, com responsável e contato a confirmar; não
  declarar conformidade legal ou publicação antes de validação operacional.

A política já existia com contato pelo Instagram @custta.ai. Esse contato foi
preservado. Usuário criará e-mail próprio do Custta; lembrete agendado para 10/09,
9h de Brasília. Fuso é gravado nos novos cadastros; perfis antigos sem tz mantêm
fallback para Brasília, sem inferir localização de pessoas existentes.

## Verificação

Testes unitários de exportação e falhas/ordem da conta; browser com Auth/Firestore
emulados cobre senha incorreta, exportação, exclusão e ausência dos documentos.
Verificar mobile e desktop. Registrar pendências de produção sem tocar contas reais.

Referências: [Firebase Auth](https://firebase.google.com/docs/auth/web/manage-users),
[persistência](https://firebase.google.com/docs/reference/js/firestore#clearindexeddbpersistence),
[batch](https://firebase.google.com/docs/firestore/manage-data/transactions).
