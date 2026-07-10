# Graph Report - C:\Users\User\OneDrive\Documentos\dashboard_finance  (2026-07-08)

## Corpus Check
- Corpus is ~41,559 words - fits in a single context window. You may not need a graph.

## Summary
- 221 nodes · 437 edges · 22 communities (11 shown, 11 thin omitted)
- Extraction: 93% EXTRACTED · 7% INFERRED · 0% AMBIGUOUS · INFERRED: 29 edges (avg confidence: 0.82)
- Token cost: 462,388 input · 0 output

## Community Hubs (Navigation)
- UI do App (app.js)
- Calculos Puros (calc.js)
- Nuvem Firebase (cloud.js)
- Planos e Conceitos do Produto
- Manifest PWA e Icones
- Tela de Login (auth.js)
- Globo de Fundo (globe.js)
- Boot e Sincronizacao
- Identidade Visual (marca)
- Icone e Splash iPhone X
- Icone 192 e Manifest
- Splash iOS (XR e 14 Pro)
- Splash de Abertura (splash.js)
- Polimento iOS PWA
- Splash iPhone Pro Max
- Splash iPhone 12-14
- Service Worker
- Regra Caveman (Cline)
- Regra Caveman (Copilot)
- Regra Caveman (OpenCode)
- Regra Caveman (Windsurf)
- Regra Caveman (AGENTS.md)

## God Nodes (most connected - your core abstractions)
1. `renderObra()` - 26 edges
2. `$()` - 20 edges
3. `gastoRow()` - 15 edges
4. `escapeHtml()` - 14 edges
5. `renderAll()` - 14 edges
6. `formGasto()` - 14 edges
7. `renderRelatorio()` - 13 edges
8. `renderGraficos()` - 12 edges
9. `obraById()` - 11 edges
10. `renderInicio()` - 11 edges

## Surprising Connections (you probably didn't know these)
- `Ícones minimalistas + máscara de moeda` --references--> `maskMoney()`  [EXTRACTED]
  docs/superpowers/specs/2026-07-06-icones-mascara-moeda-design.md → app.js
- `renderAfazeres()` --implements--> `Checklist afazeres por obra ({id, texto, feito})`  [EXTRACTED]
  app.js → docs/superpowers/specs/2026-07-08-afazeres-obra-design.md
- `evoChartHtml()` --implements--> `Gráfico Evolução da obra (bruto vs corrigido acumulados)`  [EXTRACTED]
  app.js → docs/superpowers/specs/2026-07-06-grafico-evolucao-busca-design.md
- `View Gráficos da obra (donut grande + evolução grande + PDF)` --calls--> `evoChartHtml()`  [EXTRACTED]
  docs/superpowers/specs/2026-07-06-tela-graficos-design.md → app.js
- `renderGraficos()` --implements--> `View Gráficos da obra (donut grande + evolução grande + PDF)`  [EXTRACTED]
  app.js → docs/superpowers/specs/2026-07-06-tela-graficos-design.md

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Regra caveman replicada para todos os agentes de IDE** — _clinerules_caveman_caveman_mode, _github_copilot_instructions_caveman_mode, _opencode_agents_caveman_mode, _windsurf_rules_caveman_caveman_mode, agents_caveman_mode [EXTRACTED 1.00]
- **Modulo calc.js: funcoes puras testaveis em Node (TDD)** — docs_superpowers_plans_2026_07_04_minhas_obras_obra_calc, docs_superpowers_plans_2026_07_04_minhas_obras_correcao_composta, docs_superpowers_plans_2026_07_05_parcelas_cartao_gerar_parcelas, docs_superpowers_plans_2026_07_06_grafico_evolucao_busca_serie_evolucao, docs_superpowers_plans_2026_07_06_grafico_evolucao_busca_filtra_gastos, docs_superpowers_plans_2026_07_06_dashboard_inicio_serie_evolucao_agregada, docs_superpowers_plans_2026_07_06_dashboard_inicio_preco_por_m2, docs_superpowers_plans_2026_07_06_relatorio_simulador_resumo_venda, docs_superpowers_plans_2026_07_06_icones_mascara_moeda_mascara_moeda [EXTRACTED 1.00]
- **Padrao: bump do cache do service worker (obras-vN) a cada release** — docs_superpowers_plans_2026_07_04_minhas_obras_plano, docs_superpowers_plans_2026_07_05_banco_nuvem_firebase_plano, docs_superpowers_plans_2026_07_06_icones_mascara_moeda_plano, docs_superpowers_plans_2026_07_06_relatorio_simulador_plano, docs_superpowers_plans_2026_07_06_grafico_evolucao_busca_plano, docs_superpowers_plans_2026_07_06_ios_pwa_plano, docs_superpowers_plans_2026_07_06_tela_graficos_plano, docs_superpowers_plans_2026_07_06_dashboard_inicio_plano [EXTRACTED 1.00]
- **Fluxo de persistência e sincronização na nuvem** — docs_superpowers_specs_2026_07_05_banco_nuvem_firebase_design_documento_dados_uid, cloud_savedados, cloud_watchdados, docs_superpowers_specs_2026_07_05_banco_nuvem_firebase_design_sincronizacao_tempo_real, docs_superpowers_specs_2026_07_05_banco_nuvem_firebase_design_persistencia_offline_firestore [EXTRACTED 1.00]
- **Família de funções puras testadas em calc.js** — calc_serieevolucao, calc_serieevolucaoagregada, calc_apagar, calc_gastosrecentes, calc_precoporm2, calc_filtragastos, calc_resumovenda, calc_taxaequivalentemensal [INFERRED 0.85]
- **Padrão bruto × corrigido pelo banco em toda a UI** — docs_superpowers_specs_2026_07_04_obras_design_valor_corrigido, docs_superpowers_specs_2026_07_06_grafico_evolucao_busca_design_grafico_evolucao_da_obra, docs_superpowers_specs_2026_07_06_relatorio_simulador_design_relatorio_da_simulacao, docs_superpowers_specs_2026_07_06_kpis_na_obra_design_kpis_da_obra [INFERRED 0.85]

## Communities (22 total, 11 thin omitted)

### Community 0 - "UI do App (app.js)"
Cohesion: 0.16
Nodes (52): afazerRow(), backdrop, bindEvoChart(), BRL, byTopico(), closeSheet(), db, donutComLegendaHtml() (+44 more)

### Community 1 - "Calculos Puros (calc.js)"
Cohesion: 0.10
Nodes (35): addMesesClampado(), aPagar(), corrigido(), diasEntre(), filtraGastos(), fimCorrecao(), fmtCompleto(), fmtDigitado() (+27 more)

### Community 2 - "Nuvem Firebase (cloud.js)"
Cohesion: 0.07
Nodes (32): app, auth, authCbs, db, firebaseConfig, flushSave(), ready, saveDados() (+24 more)

### Community 3 - "Planos e Conceitos do Produto"
Cohesion: 0.08
Nodes (35): Chave localStorage por usuario (obras_data_v1::CPF), Correcao composta pro-rata dia, OBRA_CALC (calc.js, modulo puro), Plano: Minhas Obras (pivo do app), Topicos de gasto (terreno, fundacao, ...), window.CLOUD (cloud.js), Documento Firestore dados/{uid} (blob unico), Migracao de dados locais (importarSeVazio) (+27 more)

### Community 4 - "Manifest PWA e Icones"
Cohesion: 0.14
Nodes (13): App Icon 512px (Trending-Up Chart), background_color, description, display, icons, lang, name, orientation (+5 more)

### Community 6 - "Globo de Fundo (globe.js)"
Cohesion: 0.47
Nodes (3): draw(), drawSet(), loop()

### Community 7 - "Boot e Sincronizacao"
Cohesion: 0.67
Nodes (4): bootCloud(), canon(), empty(), normaliza()

### Community 8 - "Identidade Visual (marca)"
Cohesion: 1.00
Nodes (3): Apple Touch Icon (upward trend chart on blue-purple gradient), Financial Growth Motif (trending-up arrow), Minhas Obras PWA Branding

### Community 9 - "Icone e Splash iPhone X"
Cohesion: 0.67
Nodes (3): App Icon (Line Chart with Upward Arrow), Minhas Obras PWA, iOS Splash Screen 1125x2436 (iPhone X/XS) - Minhas Obras PWA

### Community 10 - "Icone 192 e Manifest"
Cohesion: 0.67
Nodes (3): App Icon 192px (Minhas Obras PWA), Projeto Minhas Obras, PWA Manifest

### Community 11 - "Splash iOS (XR e 14 Pro)"
Cohesion: 0.67
Nodes (3): Minhas Obras PWA Branding (trending-chart icon, dark theme), iOS PWA Splash Screen 1179x2556 - dark navy background with centered app icon (indigo-violet gradient rounded square, white upward trending line chart with arrow and data dot), iPhone 14/15 Pro launch image for Minhas Obras, iOS Splash Screen 828x1792 (iPhone XR/11)

## Knowledge Gaps
- **52 isolated node(s):** `TOPICOS`, `PIE`, `FASES`, `db`, `MESAB` (+47 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **11 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Checklist afazeres por obra ({id, texto, feito})` connect `Nuvem Firebase (cloud.js)` to `UI do App (app.js)`, `Calculos Puros (calc.js)`?**
  _High betweenness centrality (0.077) - this node is a cross-community bridge._
- **Why does `renderAfazeres()` connect `UI do App (app.js)` to `Nuvem Firebase (cloud.js)`?**
  _High betweenness centrality (0.054) - this node is a cross-community bridge._
- **What connects `TOPICOS`, `PIE`, `FASES` to the rest of the system?**
  _57 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Calculos Puros (calc.js)` be split into smaller, more focused modules?**
  _Cohesion score 0.0960960960960961 - nodes in this community are weakly interconnected._
- **Should `Nuvem Firebase (cloud.js)` be split into smaller, more focused modules?**
  _Cohesion score 0.06606606606606606 - nodes in this community are weakly interconnected._
- **Should `Planos e Conceitos do Produto` be split into smaller, more focused modules?**
  _Cohesion score 0.07899159663865546 - nodes in this community are weakly interconnected._
- **Should `Manifest PWA e Icones` be split into smaller, more focused modules?**
  _Cohesion score 0.14285714285714285 - nodes in this community are weakly interconnected._