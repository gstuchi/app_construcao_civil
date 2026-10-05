/* Imagens do app iOS a partir das do site, para as duas não se separarem:
   - ícone: o icon-512.png em 1024×1024 e sem canal alfa, que a App Store exige
     (ITMS-90717). O icon-512.png sai do icon.svg sangrando até a borda, sem
     contorno semitransparente: amplia inteiro.
   - abertura: o quadro final da abertura do site (#splash do index.html com o
     styles.css: grade, brilho e marca, sem barra de progresso nem decoração
     animada), no quadrado de 2732px que o iOS recorta com aspectFill. Renderizado
     em 874×874 px CSS, a altura de um iPhone em pontos: 1px CSS ≈ 1pt na tela,
     o mesmo tamanho da abertura do site.
   `node scripts/imagens-ios.mjs` regrava os dois; mudou o ícone ou a marca da
   abertura do site, rode de novo. */
import { chromium } from 'playwright';
import { readFile, writeFile } from 'node:fs/promises';
import { deflateSync } from 'node:zlib';
import { fileURLToPath, pathToFileURL } from 'node:url';
import path from 'node:path';

const raiz = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const ASSETS = path.join(raiz, 'ios/App/App/Assets.xcassets');
const ICONE = { origem: path.join(raiz, 'icon-512.png'), destino: path.join(ASSETS, 'AppIcon.appiconset/AppIcon-512@2x.png'), lado: 1024 };
const ABERTURA = {
  destinos: ['splash-2732x2732.png', 'splash-2732x2732-1.png', 'splash-2732x2732-2.png'].map(n => path.join(ASSETS, 'Splash.imageset', n)),
  lado: 2732, pontos: 874,
};

/* Desenha o PNG num canvas lado×lado (suavização alta) e devolve os pixels RGBA.
   `borda` recorta essa quantidade de pixels de cada lado da origem antes. */
async function rgbaDe(page, png, lado, borda = 0){
  const rgba = await page.evaluate(async ({ src, lado, borda }) => {
    const img = new Image(); img.src = src; await img.decode();
    const c = document.createElement('canvas'); c.width = lado; c.height = lado;
    const x = c.getContext('2d');
    x.imageSmoothingEnabled = true; x.imageSmoothingQuality = 'high';
    x.drawImage(img, borda, borda, img.width - 2 * borda, img.height - 2 * borda, 0, 0, lado, lado);
    return Array.from(x.getImageData(0, 0, lado, lado).data);
  }, { src: 'data:image/png;base64,' + png.toString('base64'), lado, borda });
  return Uint8Array.from(rgba);
}

/* Quadro parado da abertura do site: animações desligadas e cada peça no estado
   em que a animação termina. A marca vem do index.html, não de cópia. O print já
   sai no tamanho final (a abertura pode ter alfa; só o ícone não pode). */
async function fotografarAbertura(browser, { lado, pontos }){
  const html = await readFile(path.join(raiz, 'index.html'), 'utf8');
  const marca = html.match(/<div class="sp-logo">[\s\S]*?<\/div>\s*<\/div>/)?.[0];
  if(!marca) throw new Error('não achei .sp-logo no index.html');
  const page = await browser.newPage({ viewport: { width: pontos, height: pontos }, deviceScaleFactor: lado / pontos });
  // Origem file:// para o styles.css e a fonte locais carregarem.
  await page.goto(pathToFileURL(path.join(raiz, 'styles.css')).href);
  await page.setContent(`<!doctype html><html lang="pt-BR"><head><meta charset="utf-8">
    <base href="${pathToFileURL(raiz + '/').href}"><link rel="stylesheet" href="styles.css">
    <style>
      #splash *{animation:none!important}
      .sp-grid,.sp-grid::after,.sp-ic,.sp-nome,.sp-tag{opacity:1}
      .sp-ic,.sp-nome{transform:none}
      .sp-glow{opacity:.7;transform:translate(-50%,-50%) scale(1.08)}
    </style></head>
    <body><div id="splash"><div class="sp-grid"></div><div class="sp-glow"></div>${marca}</div></body></html>`);
  await page.evaluate(() => document.fonts.ready);
  const fonte = await page.evaluate(() => document.fonts.check('800 40px "Hanken Grotesk"'));
  if(!fonte) throw new Error('fonte Hanken Grotesk não carregou');
  const png = await page.screenshot({ type: 'png' });
  await page.close();
  return png;
}

/* PNG RGB de 8 bits (tipo de cor 2): sem alfa nenhum, nem opaco. */
const TABELA_CRC = Array.from({ length:256 }, (_, n) => {
  let c = n;
  for(let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
  return c >>> 0;
});
function crc32(buf){
  let c = 0xffffffff;
  for(const b of buf) c = TABELA_CRC[(c ^ b) & 255] ^ (c >>> 8);
  return (c ^ 0xffffffff) >>> 0;
}
function bloco(tipo, dados){
  const cab = Buffer.alloc(8); cab.writeUInt32BE(dados.length, 0); cab.write(tipo, 4, 'ascii');
  const crc = Buffer.alloc(4); crc.writeUInt32BE(crc32(Buffer.concat([cab.subarray(4), dados])), 0);
  return Buffer.concat([cab, dados, crc]);
}
function pngRGB(rgba, lado){
  const linhas = Buffer.alloc(lado * (1 + lado * 3));
  for(let y = 0; y < lado; y++){
    const o = y * (1 + lado * 3); // byte 0 da linha: filtro 0 (nenhum)
    for(let x = 0; x < lado; x++){
      const i = (y * lado + x) * 4, j = o + 1 + x * 3;
      linhas[j] = rgba[i]; linhas[j + 1] = rgba[i + 1]; linhas[j + 2] = rgba[i + 2];
    }
  }
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(lado, 0); ihdr.writeUInt32BE(lado, 4);
  ihdr[8] = 8; ihdr[9] = 2; // 8 bits, RGB
  return Buffer.concat([
    Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
    bloco('IHDR', ihdr), bloco('IDAT', deflateSync(linhas, { level:9 })), bloco('IEND', Buffer.alloc(0)),
  ]);
}

const browser = await chromium.launch();
try{
  const page = await browser.newPage();
  await writeFile(ICONE.destino, pngRGB(await rgbaDe(page, await readFile(ICONE.origem), ICONE.lado), ICONE.lado));
  console.log('ícone gravado em', path.relative(raiz, ICONE.destino));
  const abertura = await fotografarAbertura(browser, ABERTURA);
  for(const destino of ABERTURA.destinos) await writeFile(destino, abertura);
  console.log('abertura gravada em', path.relative(raiz, path.dirname(ABERTURA.destinos[0])));
}finally{ await browser.close(); }
