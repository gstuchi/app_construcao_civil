# Polimento iOS do PWA — design

Data: 2026-07-06 · Aprovado por Giovani ("manda bala"). Objetivo: instalado no
iPhone via "Adicionar à Tela de Início", o app fica indistinguível de nativo
(ícone certo, tela cheia, splash escura) — sem App Store.

## Problema hoje

- `apple-touch-icon` aponta pro `icon.svg` — iOS não aceita SVG: ícone da tela
  de início sai em branco/screenshot.
- Sem metas iOS: abre com barra do Safari (cara de site).
- Sem imagens de splash: abertura pisca tela branca.

## Mudanças

1. **Ícones PNG** (gerados do `icon.svg` atual, desenho intocado; versão
   full-bleed sem cantos arredondados — iOS/maskable arredondam sozinhos):
   - `apple-touch-icon.png` 180×180 (link no head)
   - `icon-192.png` e `icon-512.png` (manifest, `purpose: "any maskable"`,
     mantém o SVG na lista)
2. **Metas iOS no `<head>`**: `apple-mobile-web-app-capable=yes`,
   `apple-mobile-web-app-status-bar-style=black-translucent`,
   `apple-mobile-web-app-title=Minhas Obras`.
3. **Splash escura**: PNGs `#070c18` com o ícone centrado (256px), um por
   resolução comum de iPhone, com `<link rel="apple-touch-startup-image">` +
   media queries: 1170×2532, 1179×2556, 1290×2796, 1125×2436, 828×1792.
   Pasta `splash/`.
4. Geração: script descartável com puppeteer-core + Edge headless (screenshot
   de HTML com o SVG) — nada de dependência nova no repo; PNGs commitados.
5. `sw.js`: bump `obras-v8` (index.html mudou).

## Teste

- Local: head contém os links/metas; PNGs existem nos tamanhos certos
  (conferir bytes/dimensões); e2e de regressão continua verde.
- Real: Giovani instala no iPhone dele (Safari → Compartilhar → Adicionar à
  Tela de Início) e confere ícone + tela cheia + splash antes de pôr no
  celular do pai.

## Fora de escopo

App Store/TestFlight (US$ 99/ano — só se o PWA não convencer); redesenho do
ícone (desenho atual mantido).
