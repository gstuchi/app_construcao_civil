/* Ícone do app iOS a partir do ícone do site (icon-512.png): o mesmo desenho,
   em 1024×1024 e sem canal alfa, que a App Store exige (ITMS-90717).
   `node scripts/icone-ios.mjs` regrava o AppIcon do Xcode; mudou o ícone do
   site, rode de novo. O PNG original tem 1px de borda semitransparente
   (antialiasing do recorte): sai antes de ampliar, senão vira contorno. */
import { chromium } from 'playwright';
import { readFile, writeFile } from 'node:fs/promises';
import { deflateSync } from 'node:zlib';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const raiz = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const ORIGEM = path.join(raiz, 'icon-512.png');
const DESTINO = path.join(raiz, 'ios/App/App/Assets.xcassets/AppIcon.appiconset/AppIcon-512@2x.png');
const LADO = 1024;

/* Amplia no canvas do Chromium (suavização alta) e devolve os pixels RGBA. */
async function ampliar(png){
  const browser = await chromium.launch();
  try{
    const page = await browser.newPage();
    const rgba = await page.evaluate(async ({ src, lado }) => {
      const img = new Image(); img.src = src; await img.decode();
      const c = document.createElement('canvas'); c.width = lado; c.height = lado;
      const x = c.getContext('2d');
      x.imageSmoothingEnabled = true; x.imageSmoothingQuality = 'high';
      x.drawImage(img, 1, 1, img.width - 2, img.height - 2, 0, 0, lado, lado);
      return Array.from(x.getImageData(0, 0, lado, lado).data);
    }, { src: 'data:image/png;base64,' + png.toString('base64'), lado: LADO });
    return Uint8Array.from(rgba);
  }finally{ await browser.close(); }
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

const rgba = await ampliar(await readFile(ORIGEM));
await writeFile(DESTINO, pngRGB(rgba, LADO));
console.log('ícone do app gravado em', path.relative(raiz, DESTINO));
