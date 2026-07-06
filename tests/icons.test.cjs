'use strict';
const assert = require('assert');
const { ICON, ICONES } = require('../icons.js');

let n = 0;
function t(nome, fn){ fn(); n++; console.log('ok -', nome); }

t('ICON devolve svg com viewBox e stroke', () => {
  const s = ICON('casa');
  assert.ok(s.startsWith('<svg'));
  assert.ok(s.includes('viewBox="0 0 24 24"'));
  assert.ok(s.includes('stroke="currentColor"'));
});

t('ICON aceita classe extra', () => {
  assert.ok(ICON('casa','k-ic').includes('class="ico k-ic"'));
});

t('nome desconhecido cai na etiqueta', () => {
  assert.strictEqual(ICON('naoexiste'), ICON('etiqueta'));
});

t('todos os ícones necessários existem', () => {
  const precisa = ['guindaste','predio','casa','check','balanca','engrenagem','sair',
    'moedas','notas','banco','alvo','acordo','setaCima','setaBaixo','calculadora',
    'mapa','regua','pa','tijolos','raio','gota','porta','camadas','rolo','arvore',
    'capacete','caixa','etiqueta','cartao','lapis','documento','impressora','voltar',
    'recibo','calendario','alerta','instalar','olho','olhoFechado'];
  precisa.forEach(k => assert.ok(ICONES[k], 'falta ícone: ' + k));
});

console.log(`\n${n} testes passaram ✔`);
