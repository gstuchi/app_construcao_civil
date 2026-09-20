/* Os dados sintéticos do Custta: 3 obras plausíveis de construção civil no
   Brasil, usadas nos dois lugares que precisam do app cheio em vez de vazio —
   as capturas da App Store (scripts/screenshots-loja.mjs) e a conta de
   demonstração que a revisão da Apple exige (scripts/conta-demo.mjs).

   Vive num módulo próprio porque o script das capturas importa o Playwright e
   o da conta demo fala com o Firebase: nenhum dos dois deve carregar a
   dependência do outro só para chegar nestes dados.

   Tudo aqui é função pura, coberta por tests/screenshots.test.mjs. O retorno
   tem o formato do documento `dados/{uid}` no Firestore, menos `_atualizado`. */
'use strict';


/* Divide um total em `n` parcelas mensais iguais (a última absorve o resto dos
   centavos), gerando os N gastos irmãos de uma compra parcelada no cartão. */
function gerarParcelas({ obraId, topico, descricao, valorTotal, primeiraData, n }) {
  const grupoId = 'grp_' + obraId + '_' + descricao.toLowerCase().replace(/[^a-z0-9]+/g, '');
  const base = Math.floor((valorTotal / n) * 100) / 100;
  const valores = Array.from({ length: n }, () => base);
  valores[n - 1] = Math.round((valorTotal - base * (n - 1)) * 100) / 100;
  const [ano, mes, dia] = primeiraData.split('-').map(Number);
  return valores.map((valor, i) => {
    const totalMes = mes - 1 + i;
    const d = new Date(Date.UTC(ano + Math.floor(totalMes / 12), totalMes % 12, dia));
    const data = d.toISOString().slice(0, 10);
    return {
      id: `${grupoId}_${i + 1}`, valor, topico, descricao, data, pagamento: 'cartao',
      grupoId, parcela: { n: i + 1, de: n },
      jurosCartao: { taxaMensal: 2.5, valorCompra: valorTotal, nParcelas: n, totalCompra: Math.round(valores.reduce((s, v) => s + v, 0) * 100) / 100, jurosCompra: 0 },
    };
  });
}

function gasto(id, data, topico, descricao, valor, pagamento = 'pix') {
  return { id, valor, topico, descricao, data, pagamento };
}

function afazer(id, texto, feito = false) {
  return { id, texto, feito };
}

/* 3 obras plausíveis de construção civil no Brasil, em fases diferentes,
   com dezenas de gastos espalhados por tópico/mês, algumas compras parceladas
   no cartão (grupoId + parcela) e alguns afazeres — pra preencher todas as
   telas capturadas com dados realistas. Nada de lorem ipsum ou pessoa real. */
export function dadosDemo() {
  const sobrado = {
    id: 'o1', nome: 'Sobrado Vila Nova', fase: 'construcao', dataInicio: '2026-01-15',
    areaM2: 180, valorEstimadoVenda: 950000,
    gastos: [
      gasto('g101', '2026-01-20', 'terreno', 'Escritura e ITBI do lote', 42000),
      gasto('g102', '2026-01-28', 'projeto', 'Projeto arquitetônico e ART', 8500),
      gasto('g103', '2026-02-03', 'projeto', 'Alvará de construção', 2100),
      gasto('g104', '2026-02-10', 'fundacao', 'Sondagem do solo', 1800),
      gasto('g105', '2026-02-18', 'fundacao', 'Escavação e radier', 15600),
      gasto('g106', '2026-02-25', 'matbasicos', 'Cimento e areia — 1ª carga', 9800),
      gasto('g107', '2026-03-05', 'ferragem', 'Vergalhão e arame recozido', 11200),
      gasto('g108', '2026-03-12', 'estrutura', 'Forma e concretagem dos pilares', 22400),
      gasto('g109', '2026-03-20', 'maoobra', 'Equipe de fundação — semana 1', 6400),
      gasto('g110', '2026-03-27', 'maoobra', 'Equipe de fundação — semana 2', 6400),
      gasto('g111', '2026-04-04', 'aluguelmaq', 'Aluguel de betoneira', 1300),
      gasto('g112', '2026-04-11', 'estrutura', 'Laje pré-moldada do térreo', 26800),
      gasto('g113', '2026-04-18', 'alvenaria', 'Blocos cerâmicos — térreo', 13500),
      gasto('g114', '2026-04-25', 'maoobra', 'Pedreiro — alvenaria térreo', 8900),
      gasto('g115', '2026-05-02', 'hidraulica', 'Tubulação hidráulica térreo', 7200),
      gasto('g116', '2026-05-09', 'eletrica', 'Passagem elétrica e quadro', 9600),
      gasto('g117', '2026-05-16', 'alvenaria', 'Blocos cerâmicos — 1º andar', 12800),
      gasto('g118', '2026-05-23', 'estrutura', 'Laje do 1º andar', 24100),
      gasto('g119', '2026-05-30', 'telhado', 'Madeiramento do telhado', 14300),
      gasto('g120', '2026-06-06', 'telhado', 'Telhas cerâmicas e cumeeira', 10700),
      gasto('g121', '2026-06-13', 'matextra', 'Aluguel de andaime', 2200),
      gasto('g122', '2026-06-20', 'maoobra', 'Pedreiro — 1º andar', 9100),
      gasto('g123', '2026-07-04', 'revest', 'Argamassa e rejunte', 3400),
      gasto('g124', '2026-07-18', 'pintura', 'Massa corrida e selador', 2600),
      gasto('g125', '2026-08-01', 'hidraulica', 'Louças e metais do banheiro social', 4800),
      gasto('g126', '2026-08-15', 'outros', 'Taxas de ligação de água e luz', 1650),
      gasto('g127', '2026-09-01', 'matbasicos', 'Cimento e areia — acabamento', 4200),
      gasto('g128', '2026-09-10', 'maoobra', 'Eletricista — instalação final', 3800),
      ...gerarParcelas({ obraId: 'o1', topico: 'esquadrias', descricao: 'Portas e janelas de alumínio', valorTotal: 18600, primeiraData: '2026-06-10', n: 3 }),
    ],
    afazeres: [
      afazer('a101', 'Pagar pedreiro da semana', false),
      afazer('a102', 'Comprar tinta para a fachada', false),
      afazer('a103', 'Agendar vistoria elétrica', false),
      afazer('a104', 'Aprovar planta do telhado com o engenheiro', true),
    ],
  };

  const reforma = {
    id: 'o2', nome: 'Reforma Apto 32', fase: 'pronta', dataInicio: '2026-02-01',
    areaM2: 68, valorEstimadoVenda: 420000,
    gastos: [
      gasto('g201', '2026-02-05', 'projeto', 'Projeto de interiores', 3200),
      gasto('g202', '2026-02-12', 'matbasicos', 'Demolição e remoção de entulho', 4100),
      gasto('g203', '2026-02-20', 'hidraulica', 'Troca de tubulação do banheiro', 5600),
      gasto('g204', '2026-02-27', 'eletrica', 'Fiação nova e quadro de disjuntores', 6800),
      gasto('g205', '2026-03-06', 'hidraulica', 'Louças e metais da cozinha', 3900),
      gasto('g206', '2026-03-13', 'revest', 'Porcelanato do banheiro', 4400),
      gasto('g207', '2026-03-20', 'acabamento', 'Gesso e sanca do living', 5200),
      gasto('g208', '2026-03-27', 'maoobra', 'Pedreiro e ajudante — semana 1', 5800),
      gasto('g209', '2026-04-03', 'maoobra', 'Pedreiro e ajudante — semana 2', 5800),
      gasto('g210', '2026-04-10', 'esquadrias', 'Portas internas de madeira', 6900),
      gasto('g211', '2026-04-17', 'pintura', 'Pintura geral do apartamento', 5100),
      gasto('g212', '2026-04-24', 'acabamento', 'Marcenaria — armários planejados', 22000, 'cartao'),
      gasto('g213', '2026-05-08', 'extras', 'Persianas e cortinas', 3300),
      gasto('g214', '2026-05-15', 'eletrica', 'Luminárias e spots', 2800),
      gasto('g215', '2026-05-22', 'revest', 'Rodapé e soleiras', 1900),
      gasto('g216', '2026-06-05', 'outros', 'Limpeza pós-obra', 950),
      gasto('g217', '2026-06-19', 'extras', 'Ar-condicionado split', 4600),
      ...gerarParcelas({ obraId: 'o2', topico: 'revest', descricao: 'Piso porcelanato sala e quartos', valorTotal: 13600, primeiraData: '2026-03-15', n: 4 }),
    ],
    afazeres: [
      afazer('a201', 'Instalar luminárias da cozinha', false),
      afazer('a202', 'Levar a chave extra para o corretor', false),
      afazer('a203', 'Assinar contrato de pintura', true),
    ],
  };

  const jardimSul = {
    id: 'o3', nome: 'Casa Jardim Sul', fase: 'vendida', dataInicio: '2026-01-01',
    areaM2: 140, valorEstimadoVenda: 760000, venda: { data: '2026-08-20', valor: 780000 },
    gastos: [
      gasto('g301', '2026-01-05', 'terreno', 'Compra do terreno', 180000),
      gasto('g302', '2026-01-15', 'projeto', 'Projeto e aprovação na prefeitura', 7200),
      gasto('g303', '2026-01-25', 'fundacao', 'Fundação em radier', 19800),
      gasto('g304', '2026-02-05', 'estrutura', 'Estrutura de concreto armado', 34500),
      gasto('g305', '2026-02-20', 'alvenaria', 'Alvenaria completa', 21300),
      gasto('g306', '2026-03-05', 'telhado', 'Estrutura e telhas do telhado', 16700),
      gasto('g307', '2026-03-20', 'eletrica', 'Instalação elétrica completa', 12400),
      gasto('g308', '2026-04-03', 'hidraulica', 'Instalação hidráulica completa', 10900),
      gasto('g309', '2026-04-17', 'revest', 'Revestimentos e porcelanato', 15600),
      gasto('g310', '2026-05-01', 'pintura', 'Pintura interna e externa', 8200),
      gasto('g311', '2026-05-15', 'maoobra', 'Mão de obra geral — acabamento', 18400),
      gasto('g312', '2026-06-01', 'piscina', 'Piscina de fibra e filtro', 32000),
      gasto('g313', '2026-06-15', 'paisagismo', 'Jardim e grama sintética', 9600),
      gasto('g314', '2026-07-01', 'esquadrias', 'Janelas e portas de alumínio', 14200),
      gasto('g315', '2026-07-15', 'outros', 'Documentação e habite-se', 3400),
      ...gerarParcelas({ obraId: 'o3', topico: 'extras', descricao: 'Portão eletrônico e cerca elétrica', valorTotal: 9800, primeiraData: '2026-05-10', n: 2 }),
    ],
    afazeres: [
      afazer('a301', 'Entregar as chaves ao comprador', true),
      afazer('a302', 'Cancelar seguro da obra', true),
    ],
  };

  return { config: { taxaMensal: 1, topicosCustom: [] }, obras: [sobrado, reforma, jardimSul] };
}
