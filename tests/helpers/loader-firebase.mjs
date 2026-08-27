/* Desvia os imports do gstatic pro duplê local — o cloud.js importa o SDK por
   URL, e teste não fala com a rede. */
export async function resolve(especificador, contexto, proximo){
  if(especificador.startsWith('https://www.gstatic.com/firebasejs/'))
    return proximo(new URL('./firebase-stub.mjs', import.meta.url).href, contexto);
  return proximo(especificador, contexto);
}
