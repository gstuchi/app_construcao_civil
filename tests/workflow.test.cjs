'use strict';
const assert = require('assert');
const { readFileSync } = require('fs');
const { join } = require('path');

const workflow = readFileSync(join(__dirname, '..', '.github', 'workflows', 'push-diario.yml'), 'utf8');
const usos = [...workflow.matchAll(/uses:\s*([^\s#]+)/g)].map(m => m[1]);
assert.ok(usos.length > 0, 'workflow sem actions');
for(const uso of usos){
  const ref = uso.split('@')[1] || '';
  assert.match(ref, /^[0-9a-f]{40}$/, `action sem SHA imutável: ${uso}`);
}
assert.match(workflow, /permissions:\s*\n\s*contents:\s*read/);

const nodeVersion = Number(workflow.match(/node-version:\s*['"]?(\d+)/)?.[1]);
assert.ok(nodeVersion >= 22, `Firebase Admin 14 exige Node >=22; workflow usa ${nodeVersion}`);

// dois disparos por dia: 12:00 UTC = 9h e 21:00 UTC = 18h de Brasília.
// Quem mexer aqui tem que mexer no PERIODO junto — é o cron que o escolhe.
const crons = [...workflow.matchAll(/-\s*cron:\s*'([^']+)'/g)].map(m => m[1]);
assert.deepStrictEqual(crons, ['0 12 * * *', '0 21 * * *'], `crons inesperados: ${crons}`);
assert.match(workflow, /PERIODO:.*'0 12 \* \* \*'.*'manha'/,
  'o PERIODO precisa derivar do cron da manhã');

console.log('ok - GitHub Actions usa SHA imutável, permissão mínima e dois crons');
