/* Violações de CSP que não são do app e que as suítes não contam. Hoje, uma só.
   O gapi, que o Firebase Auth baixa do apis.google.com quando abre o popup do Google ou
   da Apple na web, sorteia 1% das cargas para mandar telemetria a apis.google.com/js/gen_204
   (gen204logger com rate 0.01, na config do api.js). O connect-src do app barra o ping de
   propósito, e o login segue igual; contar essa violação deixava google.cjs e apple.cjs
   vermelhos ao acaso. Sai só ela: diretiva connect-src e esse endereço, com ou sem consulta.
   As violações chegam como as suítes registram: "diretiva: endereço barrado". */
const PING_DO_GAPI=/^connect-src: https:\/\/apis\.google\.com\/js\/gen_204(\?.*)?$/;
const pingDoGapi=v=>PING_DO_GAPI.test(v);
module.exports={pingDoGapi,violacoesDoApp:lista=>lista.filter(v=>!pingDoGapi(v))};
