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

console.log('ok - GitHub Actions usa SHA imutável e permissão mínima');
