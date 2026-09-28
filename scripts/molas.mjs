/* Molas no padrão da Apple (amortecimento + resposta, WWDC "Designing Fluid Interfaces")
   viradas curvas CSS linear(). É a fonte dos tokens --mola* do styles.css: rode
   `node scripts/molas.mjs` e cole a saída no bloco @supports das molas;
   tests/molas.test.mjs falha se o CSS divergir do que sai daqui. */
export const MOLAS = {
  'mola':        { amortecimento: 1,   resposta: 0.35 }, // padrão: sem quique
  'mola-quique': { amortecimento: 0.8, resposta: 0.3 },  // só depois de gesto com impulso
};

/* posição de 0 a 1 no instante t (s), partindo do repouso */
export function posicao(t, { amortecimento: z, resposta }){
  const w0 = 2 * Math.PI / resposta;
  if(z >= 1) return 1 - (1 + w0 * t) * Math.exp(-w0 * t);
  const wd = w0 * Math.sqrt(1 - z * z);
  return 1 - Math.exp(-z * w0 * t) * (Math.cos(wd * t) + (z * w0 / wd) * Math.sin(wd * t));
}

/* primeiro instante (arredondado para cima em centésimos) a partir do qual a mola
   fica a menos de 0,1% do destino para sempre — vira a duração da transição */
export function acomodacao(m, tolerancia = 0.001){
  let ultimoFora = 0;
  for(let i = 0; i <= 5000; i++){
    const t = i / 1000;
    if(Math.abs(1 - posicao(t, m)) >= tolerancia) ultimoFora = t;
  }
  return Math.ceil((ultimoFora + 0.001) * 100) / 100;
}

export function curva(m, pontos = 32){
  const duracao = acomodacao(m);
  const vals = [];
  for(let i = 0; i <= pontos; i++) vals.push(i === pontos ? 1 : Number(posicao(duracao * i / pontos, m).toFixed(4)));
  return { duracao, linear: `linear(${vals.join(', ')})` };
}

export function tokensCss(){
  return Object.entries(MOLAS).map(([nome, m]) => {
    const { duracao, linear } = curva(m);
    return `--${nome}:${linear}; --${nome}-dur:${duracao}s;`;
  });
}

if(import.meta.url === `file://${process.argv[1]}`) console.log(tokensCss().join('\n'));
