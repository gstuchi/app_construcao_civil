// Portões por superfície do app nativo (spec da etapa 4, "Portões por superfície"): lê os arquivos que o PR muda e escolhe
// o nível da CI do app-ios.yml. Na dúvida, roda tudo.
//
// uso: node scripts/portoes-app-ios.mjs              o diff do PR, lido do git (HEAD é o commit de merge do PR)
//      node scripts/portoes-app-ios.mjs --nivel <n>  o botão (workflow_dispatch): o nível pedido; sem ele, ou errado, tudo
//
// | nível  | quando                                                           | o que roda                            |
// | nucleo | o PR só mexe no CusttaNucleo, no site e nos vetores               | nucleo e unidade                      |
// | telas  | além disso, só em Custta/Analise e nos testes dela (…/Analise/)  | o nível nucleo e os jobs da etapa 4   |
// | tudo   | qualquer outro arquivo que dispara o workflow, ou qualquer dúvida | todos os jobs                         |
//
// O arquivo que não dispara o app-ios.yml (um plano, o checklist, o CSS do site) não muda o nível: sozinho, nem roda o
// workflow. Imprime o nível e o porquê; grava `nivel=<nível>` no GITHUB_OUTPUT e o resumo no GITHUB_STEP_SUMMARY.
import { execFileSync } from 'node:child_process';
import fs from 'node:fs';
import { fileURLToPath } from 'node:url';

export const NIVEIS = ['nucleo', 'telas', 'tudo'];

/** Os caminhos que disparam o app-ios.yml (`on.pull_request.paths`); o tests/workflow.test.cjs confere que são os mesmos. */
export const DISPARAM = ['app-ios/**', 'calc.js', 'dados.js', 'push.js', 'cadastro.js', 'teclado.js',
  'scripts/vetores-calc.mjs', 'scripts/simulador-ios.mjs', 'tests/vetores/**', '.github/workflows/app-ios.yml'];

const dispara = arquivo => DISPARAM.some(c => c.endsWith('/**') ? arquivo.startsWith(c.slice(0, -2)) : arquivo === c);

/** O núcleo, o site e os vetores: as regras e o que as confere. */
const NUCLEO = [/^app-ios\/CusttaNucleo\//, /^(calc|dados|push|cadastro|teclado)\.js$/, /^scripts\/vetores-calc\.mjs$/, /^tests\/vetores\//];
/** As telas da análise e os testes delas, cada um na pasta `Analise` do alvo dele. */
const TELAS = [/^app-ios\/Custta\/Analise\//, /^app-ios\/CusttaTests\/Analise\//, /^app-ios\/CusttaUITests\/Analise\//];

/** A superfície de um arquivo do diff: 'fora' (não dispara o workflow), 'nucleo', 'telas' ou 'tudo'. */
export function superficie(arquivo) {
  // Um caminho que o git devolveu entre aspas (nome com acento, sem o -z) não casa com regra nenhuma: é dúvida.
  if (!arquivo || arquivo.startsWith('"')) return 'tudo';
  if (!dispara(arquivo)) return 'fora';
  if (NUCLEO.some(r => r.test(arquivo))) return 'nucleo';
  if (TELAS.some(r => r.test(arquivo))) return 'telas';
  return 'tudo';
}

/** O nível do PR pelos arquivos do diff, com os arquivos que o decidiram (até 5). */
export function nivelDosPortoes(arquivos) {
  const porSuperficie = { fora: [], nucleo: [], telas: [], tudo: [] };
  for (const arquivo of arquivos) porSuperficie[superficie(arquivo)].push(arquivo);
  const nivel = [...NIVEIS].reverse().find(n => porSuperficie[n].length > 0);
  // Nada do diff dispara o workflow, e ele rodou mesmo assim: o diff não é o do PR. Dúvida.
  if (!nivel) return { nivel: 'tudo', porque: ['nenhum arquivo do diff dispara o app-ios.yml'] };
  return { nivel, porque: porSuperficie[nivel].slice(0, 5), mais: Math.max(0, porSuperficie[nivel].length - 5) };
}

/** Os arquivos que o PR muda: o diff do commit de merge do PR (HEAD) contra o 1º pai, a ponta da base. Sem as
    renomeações juntas, para o arquivo que sai de uma pasta contar pelas duas; com -z, para o nome com acento vir inteiro. */
export function arquivosDoPR(cwd = process.cwd()) {
  const git = (...args) => execFileSync('git', args, { cwd, encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] });
  git('rev-parse', '--verify', '--quiet', 'HEAD^2');       // não é um merge: falha, e quem chama roda tudo
  return git('diff', '--name-only', '--no-renames', '-z', 'HEAD^1', 'HEAD').split('\0').filter(Boolean);
}

/** O nível da rodada: o pedido no botão, ou o do diff do PR; qualquer erro é dúvida. */
export function escolher(args, cwd) {
  const i = args.indexOf('--nivel');
  if (i >= 0) {
    const pedido = args[i + 1];
    return NIVEIS.includes(pedido) ? { nivel: pedido, porque: ['pedido no botão'] }
                                   : { nivel: 'tudo', porque: [`nível pedido no botão não existe: ${pedido ?? '(vazio)'}`] };
  }
  try {
    return nivelDosPortoes(arquivosDoPR(cwd));
  } catch (erro) {
    return { nivel: 'tudo', porque: [`o diff do PR não pôde ser lido: ${String(erro.message).split('\n')[0]}`] };
  }
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  const { nivel, porque, mais } = escolher(process.argv.slice(2));
  const motivo = porque.join(', ') + (mais ? ` e mais ${mais}` : '');
  console.log(`portões: ${nivel} (${motivo})`);
  if (process.env.GITHUB_OUTPUT) fs.appendFileSync(process.env.GITHUB_OUTPUT, `nivel=${nivel}\n`);
  if (process.env.GITHUB_STEP_SUMMARY) fs.appendFileSync(process.env.GITHUB_STEP_SUMMARY, `### Portões do app nativo: ${nivel}\n\n${motivo}\n`);
}
