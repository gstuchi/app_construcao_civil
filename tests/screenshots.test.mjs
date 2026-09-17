/* Cobre só a parte pura de scripts/screenshots-loja.mjs (dados sintéticos e
   leitura do cabeçalho PNG). A captura em si (Playwright + servidor) é lenta e
   fica de fora do test:unit — valide rodando `npm run screenshots`. */
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { dadosDemo, tamanhoPng } from '../scripts/screenshots-loja.mjs';

test('dadosDemo: 3 obras com as fases esperadas', () => {
  const { obras } = dadosDemo();
  assert.equal(obras.length, 3);
  assert.deepEqual(obras.map(o => o.fase), ['construcao', 'pronta', 'vendida']);
  assert.equal(new Set(obras.map(o => o.id)).size, 3, 'ids únicos');
  assert.equal(new Set(obras.map(o => o.nome)).size, 3, 'nomes únicos');
  const vendida = obras.find(o => o.fase === 'vendida');
  assert.ok(vendida.venda && vendida.venda.valor > 0 && /^\d{4}-\d{2}-\d{2}$/.test(vendida.venda.data),
    'obra vendida precisa de venda válida (regra de dados.js)');
});

test('dadosDemo: obras têm dado plausível de construção civil no Brasil', () => {
  const { obras } = dadosDemo();
  obras.forEach(o => {
    assert.match(o.nome, /^[A-Za-zÀ-ú0-9 ]+$/, 'sem lorem ipsum / caracteres estranhos no nome');
    assert.doesNotMatch(o.nome.toLowerCase(), /lorem|ipsum/);
    assert.ok(o.areaM2 > 0);
    assert.ok(o.valorEstimadoVenda > 0);
    assert.match(o.dataInicio, /^2026-\d{2}-\d{2}$/);
    assert.ok(o.gastos.length >= 10, 'obra precisa de várias dezenas de gastos no total do conjunto');
  });
});

test('dadosDemo: todos os gastos têm tópico/data/valor válidos', () => {
  const { obras } = dadosDemo();
  const DATA_RE = /^2026-\d{2}-\d{2}$/;
  obras.forEach(o => {
    o.gastos.forEach(g => {
      assert.ok(g.id, `gasto sem id em ${o.nome}`);
      assert.match(g.data, DATA_RE, `data inválida em ${o.nome}/${g.id}`);
      assert.ok(typeof g.valor === 'number' && g.valor > 0, `valor inválido em ${o.nome}/${g.id}`);
      assert.ok(typeof g.topico === 'string' && g.topico.length > 0, `tópico ausente em ${o.nome}/${g.id}`);
      assert.ok(['pix', 'cartao'].includes(g.pagamento), `pagamento inválido em ${o.nome}/${g.id}`);
      if (g.grupoId || g.parcela) {
        assert.ok(Number.isInteger(g.parcela.n) && g.parcela.n > 0);
        assert.ok(Number.isInteger(g.parcela.de) && g.parcela.de >= g.parcela.n);
        assert.equal(g.pagamento, 'cartao', 'parcela sempre no cartão');
      }
    });
  });
});

test('dadosDemo: gastos cobrem vários tópicos e meses, com parceladas e afazeres pendentes', () => {
  const { obras } = dadosDemo();
  const totalGastos = obras.reduce((s, o) => s + o.gastos.length, 0);
  assert.ok(totalGastos >= 40, `esperava algumas dezenas de gastos no total, achei ${totalGastos}`);

  const topicos = new Set(obras.flatMap(o => o.gastos.map(g => g.topico)));
  assert.ok(topicos.size >= 8, 'gastos precisam cobrir vários tópicos diferentes');

  const meses = new Set(obras.flatMap(o => o.gastos.map(g => g.data.slice(0, 7))));
  assert.ok(meses.size >= 6, 'gastos precisam cobrir vários meses diferentes');

  const parceladas = obras.flatMap(o => o.gastos.filter(g => g.grupoId));
  assert.ok(parceladas.length >= 4, 'precisa de gastos parcelados no cartão (grupoId + parcela)');
  const grupos = new Set(parceladas.map(g => g.grupoId));
  grupos.forEach(gid => {
    const irmas = parceladas.filter(g => g.grupoId === gid).sort((a, b) => a.parcela.n - b.parcela.n);
    irmas.forEach((g, i) => assert.equal(g.parcela.n, i + 1, `parcelas de ${gid} fora de ordem`));
    assert.ok(irmas.every(g => g.parcela.de === irmas.length), `grupo ${gid} com "de" inconsistente`);
  });

  const afazeresPendentes = obras.flatMap(o => o.afazeres || []).filter(a => !a.feito);
  assert.ok(afazeresPendentes.length >= 1, 'precisa de ao menos um afazer pendente');
});

test('dadosDemo: soma dos gastos de cada obra bate com a soma manual dos valores', () => {
  const { obras } = dadosDemo();
  obras.forEach(o => {
    const soma = o.gastos.reduce((s, g) => s + g.valor, 0);
    assert.ok(soma > 0);
    // soma das parcelas de um grupo deve reconstituir o valor total da compra
    const porGrupo = {};
    o.gastos.forEach(g => { if (g.grupoId) (porGrupo[g.grupoId] ||= []).push(g); });
    Object.values(porGrupo).forEach(irmas => {
      const totalGrupo = irmas.reduce((s, g) => s + g.valor, 0);
      const totalCompra = irmas[0].jurosCartao.totalCompra;
      assert.ok(Math.abs(totalGrupo - totalCompra) < 0.01, 'parcelas precisam somar o total da compra');
    });
  });
});

test('tamanhoPng: lê largura/altura de um PNG mínimo válido', () => {
  // assinatura PNG + chunk IHDR com width=1290, height=2796 (valores reais do app store)
  const buf = Buffer.alloc(24);
  buf.set([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a], 0); // assinatura
  buf.writeUInt32BE(13, 8);                 // tamanho do chunk IHDR
  buf.write('IHDR', 12, 'latin1');
  buf.writeUInt32BE(1290, 16);              // width
  buf.writeUInt32BE(2796, 20);              // height
  assert.deepEqual(tamanhoPng(buf), { width: 1290, height: 2796 });
});

test('tamanhoPng: rejeita bytes que não são PNG', () => {
  assert.throws(() => tamanhoPng(Buffer.from('nao é um png, só um texto qualquer')));
  assert.throws(() => tamanhoPng(Buffer.alloc(4)));
});
