# Identidade Custta — troca de nome e marca

**Data:** 2026-08-24
**Estado:** decidido e aplicado no código; registro de marca pendente.

## Por que trocar

O nome anterior, **ObraControl**, não era defensável:

- É a marca de um app concorrente já publicado nas duas lojas — título de loja "Controle de Obras e Construção" (Def Aplicativos / Deusdete Filho), pacote Android `com.obracontrol.app`, com funcionalidade sobreposta (gastos por categoria, orçamento, margem).
- "Obra Controle" (RBTech, obracontrole.com.br) é foneticamente idêntico e atua no mesmo mercado.
- "Obra" + "controle" descreve a categoria, então o INPI concede marca fraca ou indefere. Não havia como defender.
- Nove apps brasileiros disputam a palavra "Obra" no nome (appOBRA, Minha Obra da TOTVS, Facilite Obra, Diário de Obra, Obrafit, entre outros). O nome enterrava o produto no meio deles.

## Posicionamento que orientou a escolha

Decidido em brainstorm antes de gerar nomes:

- **Público:** quem constrói para vender — investidor-construtor, o perfil do usuário original. Não é gestão de canteiro, não é empreiteiro com cliente.
- **Promessa:** *o custo real, na ponta do lápis*. O lucro é consequência.
- **Registro do nome:** mundo do construtor, palavra concreta — não jargão financeiro nem termo abstrato.

O diferencial que nenhum concorrente tem é o **custo de oportunidade**: `totalCorrigido`, `lucroVenda.vsBanco` e `taxaEquivalenteMensal` em [calc.js](../../../calc.js) tratam a obra como aplicação financeira. Toda a comunicação sai daí.

## Nomes descartados

Verificados contra lojas, empresas e domínios e reprovados: Alicerce (5+ apps), Canteiro (Canteiro Digital, mesmo nicho), Prumo (Prumo Logística S.A., Prumo Engenharia, Prumo Tecnologia), Trena (4+ apps), Cerne (app + CERNE ERP), Aprumo (aprumo.app é BI ativo), Baliza (Baliza App), Lastro (Lastro Gestão), Caderneta (4 apps, inclusive "Caderneta de Obras" no pacote `app.caderneta`), Chave (Chaves na Mão), Eixo (Instituto Eixo), Cota (`.app.br` tomado), Tijolo, Régua, Esquadro, Sarrafo, Baldrame, Obrium.

**Obrium** chegou perto e foi reprovado por conflito de setor: [obrium.app](https://www.obrium.app/es/) é um SaaS espanhol ativo para profissionais de campo, e existem duas construtoras espanholas homônimas em Badajoz.

## Verificação do nome escolhido

Feita em 2026-08-24:

| Fonte | Resultado |
| --- | --- |
| App Store BR (API de busca da Apple) | zero resultados |
| App Store US | zero exatos |
| Google Play | zero |
| Empresa comercial homônima | nenhuma no mundo |
| `custta.com.br` | livre |
| `custta.app` | não registrado |
| `custta.app.br` | livre |
| `custta.com` | Calgary United Sports Table Tennis Association (associação sem fins lucrativos canadense, desde 2005) |
| `@custta` no Instagram | ocupado |

**Não verificado:** INPI, EUIPO e USPTO — todas exigem sessão e captcha. Uma marca depositada e ainda não lançada não deixa rastro na web, então nenhuma varredura feita aqui a detectaria.

## Decisões de marca

**Logotipo em caixa baixa: `custta`.** Os dois `t` minúsculos têm haste alta e travessão — são duas colunas cortadas por uma viga. O pórtico da marca aparece dentro da própria palavra. Em caixa alta o efeito some no peso do bloco; em capitular o C maiúsculo puxa o olho para o começo, quando o interesse está no fim.

**O duplo T em esmeralda é a marca inteira.** Sem ele sobra uma palavra qualquer. O logotipo nunca aparece em caixa alta — vale travar `text-transform: none` na classe do logotipo quando o tratamento visual entrar no código.

**Símbolo: pórtico.** Três traços — duas verticais e uma viga — que são simultaneamente o "tt" e uma estrutura. Sobrevive a 60px, que é o tamanho do ícone na Tela de Início.

**Paleta inalterada.** O esmeralda-teal (`#14B39A`, `#3AD17E`, `#04100C`) segue em produção, incluindo a skin Azul dos Ajustes. A troca de nome não justifica descartar um sistema aprovado.

**Tipografia: em aberto.** O app usa `system-ui` hoje. Candidatas avaliadas: Hanken Grotesk (recomendada — altura-x grande, algarismos abertos), Familjen Grotesk, Archivo e Manrope. Critério: legibilidade de algarismo para um usuário de óculos de leitura, não estética.

**Assinaturas:** `custta` puro para ícone, cabeçalho e registro. `custta.app` para campanha, já que o domínio está livre. `custta.` com ponto para peças. **`custta.ai` foi descartado** — o app não tem inteligência artificial, e prometer isso na marca é propaganda enganosa.

## O que mudou no código

Troca de texto em 9 arquivos, 17 ocorrências de "ObraControl" mais 4 de "Minhas Obras" (o nome anterior ao anterior, ainda vivo no título da notificação push):

- [index.html](../../../index.html) — `<title>`, `apple-mobile-web-app-title`, título da tela de login, logo da sidebar, logo do cabeçalho
- [manifest.json](../../../manifest.json) — `name` e `short_name`
- [sw.js](../../../sw.js) — título padrão do push; `CACHE` de `obras-v25` para `obras-v26`
- [notificacoes/resumo.js](../../../notificacoes/resumo.js) — título do resumo diário
- [tests/resumo.test.cjs](../../../tests/resumo.test.cjs) — asserção do título
- [package.json](../../../package.json), `package-lock.json` — campo `name` para `custta`
- [tests/rules.test.mjs](../../../tests/rules.test.mjs) — `projectId` do emulador para `custta-rules-test`
- [app.js](../../../app.js), [firestore.rules](../../../firestore.rules), [README.md](../../../README.md), [notificacoes/README.md](../../../notificacoes/README.md) — comentários e documentação

O `projectId` do Firebase (`app-construcao-civil`) **não muda** — é identificador de infraestrutura, não marca.

## Pendências

1. **Consultar o INPI** (busca.inpi.gov.br, classes 9 e 42): marca "CUSTTA" e radical "CUST". É o único bloqueio possível restante. Se aparecer marca registrada, este rename volta atrás — o custo de reverter é baixo por ser só texto.
2. **Registrar `custta.com.br` e `custta.app`** no mesmo dia da decisão.
3. **Ícone e splash** ainda são os da marca anterior (casa isométrica). Gerar `icon.svg`, `icon-192.png`, `icon-512.png`, `apple-touch-icon.png` e as 5 splashes com o pórtico.
4. **Domínio `obracontrolapp.com.br`** continua apontando para a Vercel — decidir se redireciona ou expira.
5. **Tratamento do logotipo** (caixa baixa com o `tt` destacado) ainda não foi aplicado ao HTML; hoje o cabeçalho mostra "Custta" em texto simples.
