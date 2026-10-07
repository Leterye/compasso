// Inicia ou reutiliza a API e a previa web, sem tentar recompilar o Flutter.
import { spawn } from 'node:child_process';
import { existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';

const root = fileURLToPath(new URL('../', import.meta.url));
const children = [];
let stopping = false;

function stop() {
  if (stopping) return;
  stopping = true;
  for (const child of children) child.kill();
}
process.on('SIGINT', stop);
process.on('SIGTERM', stop);

async function inspect(url, accepts) {
  try {
    const response = await fetch(url, { signal: AbortSignal.timeout(1500) });
    if (!response.ok || !await accepts(response)) throw new Error(`Outro servico esta usando ${url}. Libere a porta antes de iniciar.`);
    return true;
  } catch (error) {
    if (error.cause?.code === 'ECONNREFUSED') return false;
    throw error;
  }
}

async function ensure(label, script, url, accepts) {
  if (await inspect(url, accepts)) {
    console.log(`${label}: ja esta em execucao.`);
    return;
  }
  const child = spawn(process.execPath, [script], { cwd: root, stdio: 'inherit', windowsHide: true });
  children.push(child);
  child.on('error', error => { console.error(error.message); stop(); process.exitCode = 1; });
  child.on('exit', code => {
    if (!stopping) { console.error(`${label} encerrou (codigo ${code}).`); stop(); process.exitCode = 1; }
  });
  for (let attempt = 0; attempt < 30; attempt++) {
    if (stopping) throw new Error(`Nao foi possivel iniciar ${label}.`);
    await new Promise(resolve => setTimeout(resolve, 200));
    if (await inspect(url, accepts)) return;
  }
  throw new Error(`${label} nao ficou disponivel a tempo.`);
}

try {
  if (!existsSync(`${root}/api/node_modules/express`)) throw new Error('Execute npm ci na pasta api antes de iniciar.');
  if (!existsSync(`${root}/build/web/main.dart.js`)) throw new Error('Os arquivos da previa nao foram encontrados. A build Flutter precisa ser gerada primeiro.');
  await ensure('API', 'api/src/server.js', 'http://127.0.0.1:3001/health', async response => {
    const data = await response.json();
    return data.status === 'ok' && typeof data.demo === 'boolean';
  });
  await ensure('Frontend', 'scripts/serve-web.mjs', 'http://127.0.0.1:5173', async response => (await response.text()).includes('<title>Compasso'));
  console.log('\nAbra no Chrome: http://127.0.0.1:5173/');
  console.log('Esta e a previa dos arquivos ja gerados, nao uma nova compilacao Flutter.');
  if (children.length) console.log('Mantenha este terminal aberto. Ctrl+C encerra apenas os servidores iniciados aqui.');
} catch (error) {
  console.error(`\n${error.message}`);
  stop();
  process.exitCode = 1;
}
