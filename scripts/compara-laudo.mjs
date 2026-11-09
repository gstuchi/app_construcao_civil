// Compara o laudo de leitura de dois commits, palavra por palavra (spec da etapa 4, "A comparação").
//
// uso: node scripts/compara-laudo.mjs <antes> <depois> <pasta de saída> [--detalhe]
//
// <antes> e <depois> são os xcresult do laudo (o script exporta só as tabelas, *.txt, para <saída>/antes e
// <saída>/depois) ou pastas já exportadas, com o manifest.json. As palavras de cada cena casam pela caixa
// (x, y, largura e altura). Por cena, o script conta as idênticas (cor, nota e pior iguais), as mudadas (a mesma
// caixa com cor ou nota diferente), as deslocadas (a mesma palavra, que andou até 6 pt na horizontal) e as sem
// par dos dois lados, e confere as palavras de depois contra o portão de 4,5. Só as cenas com diferença saem.
import { execFileSync } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';

const PORTAO = 4.5;
const LINHA = /^(#[0-9A-Fa-f]{6,8})\s+(-?\d+),\s*(-?\d+)\s+(\d+)×\s*(\d+) pt\s+nota\s+([\d.]+)\s+pior\s+([\d.]+)/;

function exportar(origem, destino) {
  let pasta = origem;
  if (origem.replace(/\/+$/, '').endsWith('.xcresult')) {
    pasta = destino;
    fs.rmSync(destino, { recursive: true, force: true });   // sempre do xcresult de agora, nunca de uma rodada velha
    fs.mkdirSync(destino, { recursive: true });
    execFileSync('xcrun', ['xcresulttool', 'export', 'attachments', '--path', origem, '--output-path', destino,
      '--filter', '*.txt'], { stdio: 'pipe' });
  }
  const manifesto = JSON.parse(fs.readFileSync(path.join(pasta, 'manifest.json'), 'utf8'));
  const cenas = new Map();
  for (const teste of manifesto) {
    for (const anexo of teste.attachments ?? []) {
      const m = /^leitura — (.*) \(tabela\)/.exec(anexo.suggestedHumanReadableName ?? '');
      if (!m) continue;
      if (cenas.has(m[1])) throw new Error(`cena repetida no laudo: ${m[1]}`);
      const palavras = [];
      for (const linha of fs.readFileSync(path.join(pasta, anexo.exportedFileName), 'utf8').split('\n')) {
        const p = LINHA.exec(linha.trim());
        if (p) palavras.push({ cor: p[1].toUpperCase(), x: +p[2], y: +p[3], w: +p[4], h: +p[5], nota: +p[6], pior: +p[7] });
      }
      cenas.set(m[1], palavras);
    }
  }
  return cenas;
}

const caixa = p => `${p.x},${p.y},${p.w},${p.h}`;
const igual = (a, b) => caixa(a) === caixa(b) && a.cor === b.cor && a.nota === b.nota && a.pior === b.pior;
const n2 = v => v.toFixed(2);

function main() {
  const [antesX, depoisX, saida] = process.argv.slice(2, 5);
  const detalhe = process.argv.includes('--detalhe');
  const antes = exportar(antesX, path.join(saida, 'antes'));
  const depois = exportar(depoisX, path.join(saida, 'depois'));
  const total = { cenas: 0, palavras: 0, iguais: 0, mudadas: 0, semPar: 0, deslocadas: 0, abaixo: 0 };
  for (const cena of [...new Set([...antes.keys(), ...depois.keys()])].sort()) {
    const a = antes.get(cena);
    const d = depois.get(cena);
    if (!a || !d) {
      console.log(`SÓ ${a ? 'ANTES' : 'DEPOIS'}: ${cena}`);
      continue;
    }
    const porCaixaA = new Map();
    for (const p of a) {
      if (!porCaixaA.has(caixa(p))) porCaixaA.set(caixa(p), []);
      porCaixaA.get(caixa(p)).push(p);
    }
    let iguais = 0;
    const mudadas = [];
    const semParD = [];
    for (const p of d) {
      const lista = porCaixaA.get(caixa(p));
      if (lista && lista.length) {
        const q = lista.shift();
        if (igual(q, p)) iguais += 1;
        else mudadas.push([q, p]);
      } else {
        semParD.push(p);
      }
    }
    const semParA = [...porCaixaA.values()].flat();
    // Segunda passada: a mesma palavra deslocada na horizontal (mesma cor, y, largura e altura; |Δx| ≤ 6 pt).
    const deslocadas = [];
    for (const p of [...semParD]) {
      const q = semParA.find(q => q.cor === p.cor && q.y === p.y && q.w === p.w && q.h === p.h && Math.abs(q.x - p.x) <= 6);
      if (q) {
        semParA.splice(semParA.indexOf(q), 1);
        semParD.splice(semParD.indexOf(p), 1);
        deslocadas.push([q, p]);
      }
    }
    const abaixo = d.filter(p => p.nota < PORTAO);
    total.cenas += 1;
    total.palavras += d.length;
    total.iguais += iguais;
    total.mudadas += mudadas.length;
    total.semPar += semParA.length + semParD.length;
    total.deslocadas += deslocadas.length;
    total.abaixo += abaixo.length;
    if (mudadas.length || semParA.length || semParD.length || abaixo.length || deslocadas.length) {
      console.log(`${cena}: ${d.length} palavras, ${iguais} idênticas, ${mudadas.length} mudadas, ${deslocadas.length} deslocadas, ` +
        `${semParA.length} só antes, ${semParD.length} só depois, ${abaixo.length} abaixo de ${PORTAO}`);
      if (detalhe) {
        for (const [q, p] of mudadas) {
          console.log(`   mudou ${q.x},${q.y} ${q.w}×${q.h}: ${q.cor} ${n2(q.nota)} (pior ${n2(q.pior)}) → ${p.cor} ${n2(p.nota)} (pior ${n2(p.pior)})`);
        }
        for (const [q, p] of deslocadas) {
          if (q.cor !== p.cor || q.nota !== p.nota || q.pior !== p.pior) {
            console.log(`   deslocada ${q.x}→${p.x},${p.y} ${p.w}×${p.h}: ${q.cor} ${n2(q.nota)} (pior ${n2(q.pior)}) → ${p.cor} ${n2(p.nota)} (pior ${n2(p.pior)})`);
          }
        }
        for (const p of semParA) console.log(`   só antes  ${p.cor} ${p.x},${p.y} ${p.w}×${p.h} nota ${n2(p.nota)} pior ${n2(p.pior)}`);
        for (const p of semParD) console.log(`   só depois ${p.cor} ${p.x},${p.y} ${p.w}×${p.h} nota ${n2(p.nota)} pior ${n2(p.pior)}`);
        for (const p of abaixo) console.log(`   ABAIXO ${p.cor} ${p.x},${p.y} ${p.w}×${p.h} nota ${n2(p.nota)}`);
      }
    }
  }
  console.log(`TOTAL: ${total.cenas} cenas, ${total.palavras} palavras, ${total.iguais} idênticas, ${total.mudadas} mudadas, ` +
    `${total.deslocadas} deslocadas, ${total.semPar} sem par, ${total.abaixo} abaixo de ${PORTAO}`);
}

main();
