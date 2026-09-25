# Metadados da App Store — Custta

Textos prontos para colar no App Store Connect. Limites da Apple entre parênteses; as contagens foram conferidas ao escrever. Idioma principal: **Português (Brasil)**. Não adicionar outros idiomas — o app é só em pt-BR.

## Identidade

| Campo | Valor | Limite |
| --- | --- | --- |
| Nome | `Custta` | 30 |
| Subtítulo | `Custo e lucro das suas obras` | 30 (29 usados) |
| Categoria principal | Finanças | — |
| Categoria secundária | Produtividade | — |
| Bundle ID | `br.com.custta.app` (registrado em 25/09/2026; não muda nunca) | — |
| SKU | `custta-ios` | — |

## Texto promocional (170)

Atualizável sem nova versão, aparece acima da descrição.

```
Lance o gasto no momento da compra e veja na hora quanto a obra já custou, quanto isso renderia no banco e qual o lucro real quando ela for vendida.
```

145 caracteres.

## Palavras-chave (100, separadas por vírgula, sem espaços)

```
obra,construcao,custos,gastos,reforma,orcamento,construtor,pedreiro,empreiteiro,planilha,lucro,imovel
```

99 caracteres. Não repita palavras que já estão no nome ou no subtítulo (a Apple já indexa as duas), nem use nome de concorrente.

## Descrição (4000)

```
O Custta mostra, em segundos, quanto cada obra já custou e quanto ela deu de lucro.

Feito para quem toca obra de verdade: você lança o gasto na hora de pagar o fornecedor e o app cuida do resto. Sem planilha, sem fórmula, sem depender do escritório.

CONTROLE POR OBRA
• Cada obra tem seus próprios gastos, separados por tópico: terreno, fundação, estrutura, acabamento e os tópicos que você mesmo criar.
• Três fases acompanham a vida da obra: em construção, pronta e vendida.
• Total gasto, valor por metro quadrado e prazo aparecem logo na abertura da obra.

VALOR CORRIGIDO E LUCRO REAL
• Além do total gasto, o app calcula quanto esse dinheiro teria rendido no banco, com a taxa mensal que você definir.
• Na venda, você vê o lucro bruto e o lucro acima do banco. É esse número que responde se a obra valeu a pena.
• O simulador "Será que vale a pena?" projeta o resultado antes de fechar o negócio.

LANÇAMENTO RÁPIDO
• Teclado próprio para digitar valor, pensado para o dedo e para quem usa óculos de leitura.
• Compra parcelada no cartão vira várias parcelas automaticamente, com juros mensais quando houver.
• O app sugere descrições que você já usou e avisa quando o lançamento parece repetido.

FUNCIONA SEM INTERNET
• Lance gastos no meio da obra, sem sinal. Quando a conexão volta, tudo sobe sozinho.
• Um aviso honesto mostra quando o dado ainda não subiu: nada de "salvo" que não salvou.

RELATÓRIOS E GRÁFICOS
• Gastos por tópico, evolução mês a mês e os vencimentos do mês.
• Selecione lançamentos e veja o subtotal na hora.
• Exporte tudo em CSV ou JSON, ou compartilhe a planilha de uma obra pelo próprio iPhone.

LEMBRETES DIÁRIOS
• Resumo de manhã e no fim do dia, com afazeres pendentes e parcelas que vencem no mês.
• Você liga e desliga quando quiser, em Ajustes.

SEUS DADOS SÃO SEUS
• Conta por e-mail e senha, com dados isolados por usuário.
• Exportação e exclusão total da conta dentro do próprio app.
• Sem anúncio, sem venda de dados, sem pedir CPF.

O Custta é gratuito. Todo o texto do app é em português do Brasil, feito para obra brasileira.

Dúvidas e suporte: suportecustta@gmail.com
```

2.084 caracteres. Não use emoji nem "melhor app de..."; a revisão da Apple reprova superlativo sem prova.

## URLs

| Campo | Valor |
| --- | --- |
| URL de marketing | `https://app-construcao-civil.vercel.app` |
| URL de suporte | `https://app-construcao-civil.vercel.app` (ou uma página de suporte dedicada, se você criar) |
| URL da política de privacidade | `https://app-construcao-civil.vercel.app/privacidade.html` |

As três precisam estar no ar no momento da submissão. As duas primeiras já estão.

## Classificação etária

Responda "Nenhum" para todas as perguntas do questionário (violência, conteúdo sexual, jogos, álcool, drogas, apostas, conteúdo gerado por usuário sem moderação). Resultado esperado: **4+**.

"Feito para crianças" (Kids Category) = **não**.

## App Privacy labels

Derivados de `docs/sdks-fase4.md`. Não chute: label que não bate com o binário derruba o app depois de aprovado.

| Tipo de dado | Coletado | Vinculado à identidade | Rastreamento | Finalidade |
| --- | --- | --- | --- | --- |
| Endereço de e-mail | Sim | Sim | Não | Funcionalidade do app (conta e login) |
| Conteúdo do usuário (obras, gastos, afazeres) | Sim | Sim | Não | Funcionalidade do app |
| Identificadores — ID de dispositivo (token FCM) | Sim | Sim | Não | Funcionalidade do app (notificações) |
| Diagnóstico — dados de falha | Sim | Não | Não | Diagnóstico (Sentry, sem mensagem livre, sem dado de obra, IP substituído por 0.0.0.0) |

Nada é usado para publicidade ou rastreamento entre apps, então a resposta sobre App Tracking Transparency é **não**.

## Conta de demonstração (Guideline 2.1) — obrigatória

O app inteiro fica atrás de login, então a revisão precisa de uma conta pronta.

Os passos 1 e 2 são feitos por `scripts/conta-demo.mjs`, que cria o usuário e grava as mesmas 3 obras e 69 gastos das capturas da loja — o revisor precisa ver o app cheio, não a tela vazia.

```bash
npm run conta:demo             # ensaio no emulador, não toca em nada real

# para valer — a senha vem de fora, nunca do código:
FIREBASE_SERVICE_ACCOUNT="$(cat chave.json)" \
CONTA_DEMO_SENHA='escolha uma senha forte aqui' \
  npm run conta:demo:producao
```

O script é idempotente: rodar de novo repõe os dados e a senha na mesma conta. Ele recusa `--producao` sem credencial, sem senha, ou se `FIRESTORE_EMULATOR_HOST` estiver sobrando no ambiente — o que gravaria no emulador em silêncio e deixaria o revisor sem conta.

1. E-mail padrão: `revisao.custta@gmail.com` (troque com `--email`). **A senha não tem padrão e não pode ser escrita em lugar nenhum do repositório** — ele é público, e uma senha commitada entrega a conta que a Apple está revisando para qualquer um. Guarde-a no seu gerenciador de senhas e cole no App Store Connect.
2. O formato gravado é conferido por `tests/conta-demo.test.mjs` contra as `firestore.rules` — o Admin SDK passa por cima das regras, então a conferência precisa morar no teste.
3. Preencha e-mail e senha em App Store Connect → Informações da versão → Login obrigatório.
4. Não apague nem troque a senha dessa conta enquanto a revisão estiver em andamento.

## Notas de revisão (em inglês)

```
Custta is a construction cost tracker for individual builders in Brazil. The entire interface is in Brazilian Portuguese, on purpose: the target user is a Brazilian builder.

Demo account: <e-mail> / <senha>
The account is already populated with construction projects and expenses, so you can see the app in use.

A few notes that may help the review:

1. Account-based by design. Every user's projects and expenses sync across their own devices (iPhone and web), so the app requires an account. Sign-in is email and password through Firebase Authentication. There is no third-party or social login, so Guideline 4.8 does not apply.

2. Account deletion is available in the app: Ajustes (Settings) > Apagar conta (Delete account). It asks for the current password, requires typing APAGAR to confirm, deletes the user's documents and then the authentication account.

3. Data export is available in Ajustes > Seus dados, in CSV or JSON.

4. Push notifications deliver a daily summary of pending tasks and installments due this month. They are off by default and the user turns them on in Ajustes.

5. The app works completely offline. Please try it in airplane mode: you can open the app, browse projects and add an expense; the entry is queued and uploads when the connection returns. This is a core part of the product, since the app is used on construction sites with poor signal.

Support: suportecustta@gmail.com
```

Substitua `<e-mail>` e `<senha>` pelos dados reais da conta de demonstração.

## O que sobe junto

- **Screenshots:** 5 capturas em 1290×2796, geradas por `npm run screenshots` (ver `scripts/screenshots-loja.mjs`). Só iPhone: o projeto é `TARGETED_DEVICE_FAMILY = 1`.
- **Ícone:** 1024×1024 sem transparência e sem cantos arredondados (a Apple arredonda).
- **Copyright:** `2026 Giovani Stuchi`.
- **Informações de contato:** seu nome, telefone e e-mail; não aparecem na loja, são só para a Apple.

## Ordem de preenchimento

1. Reservar o nome e criar o app com o bundle ID.
2. Colar nome, subtítulo, palavras-chave, descrição e texto promocional.
3. Subir screenshots e ícone.
4. Responder o questionário de classificação etária.
5. Preencher os App Privacy labels da tabela acima.
6. Criar e popular a conta de demonstração, e preencher o login obrigatório.
7. Colar as notas de revisão com os dados reais da conta.
8. Só então enviar o build (Fase 5).
