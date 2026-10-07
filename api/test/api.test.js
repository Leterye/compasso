import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { openDatabase } from '../src/database.js';
import { createApp } from '../src/app.js';

async function fixture(t, path = ':memory:') {
  const db = openDatabase(path);
  const server = createApp(db).listen(0, '127.0.0.1');
  await new Promise(resolve => server.once('listening', resolve));
  t.after(async () => { await new Promise(resolve => server.close(resolve)); db.close(); });
  return async (method, path, body, origin) => {
    const response = await fetch(`http://127.0.0.1:${server.address().port}${path}`, {
      method, headers: { 'Content-Type': 'application/json', ...(origin ? { Origin: origin } : {}) },
      body: body === undefined ? undefined : JSON.stringify(body),
    });
    return { status: response.status, headers: response.headers, data: response.status === 204 ? null : await response.json() };
  };
}

test('fluxo completo: validação, cadastro, edição, conclusão, integridade e exclusão', async t => {
  const request = await fixture(t);
  assert.deepEqual((await request('GET', '/disciplinas')).data, []);
  assert.equal((await request('POST', '/disciplinas', { nome: '' })).status, 400);
  const created = await request('POST', '/disciplinas', { nome: '  Cálculo  ', cor: 'roxo' });
  assert.equal(created.status, 201);
  assert.equal(created.data.nome, 'Cálculo');
  const d = created.data.id;
  assert.equal((await request('POST', '/disciplinas', { nome: 'cálculo' })).status, 409);
  const invalid = await request('POST', '/atividades', { titulo: 'a', disciplinaId: 999, prazo: '2026-02-30', tipo: 'outro' });
  assert.equal(invalid.status, 400);
  assert.deepEqual(Object.keys(invalid.data.campos).sort(), ['disciplinaId', 'prazo', 'tipo', 'titulo']);
  const payload = { titulo: 'Estudar integrais', disciplinaId: d, prazo: '2026-10-07', tipo: 'prova', descricao: 'Capítulo 2' };
  const task = await request('POST', '/atividades', payload);
  assert.equal(task.status, 201);
  assert.equal(task.data.concluida, false);
  const id = task.data.id;
  assert.equal((await request('GET', `/atividades/${id}`)).data.descricao, 'Capítulo 2');
  assert.equal((await request('PUT', `/atividades/${id}`, { ...payload, titulo: 'Revisar integrais' })).data.titulo, 'Revisar integrais');
  assert.equal((await request('PATCH', `/atividades/${id}`, { concluida: 'false' })).status, 400);
  assert.equal((await request('PATCH', `/atividades/${id}`, { concluida: true })).data.concluida, true);
  assert.equal((await request('PATCH', `/atividades/${id}`, { concluida: false })).data.concluida, false);
  assert.equal((await request('DELETE', `/disciplinas/${d}`)).status, 409);
  assert.equal((await request('DELETE', `/atividades/${id}`)).status, 204);
  assert.equal((await request('GET', `/atividades/${id}`)).status, 404);
  assert.equal((await request('DELETE', `/disciplinas/${d}`)).status, 204);
});

test('rejeita campos inválidos, limita CORS e responde a rotas inexistentes', async t => {
  const request = await fixture(t);
  assert.equal((await request('GET', '/disciplinas/abc')).status, 400);
  assert.equal((await request('GET', '/disciplinas/999')).status, 404);
  assert.equal((await request('GET', '/inexistente')).status, 404);
  const valid = await request('GET', '/health', undefined, 'http://localhost:5173');
  assert.equal(valid.headers.get('access-control-allow-origin'), 'http://localhost:5173');
  const blocked = await request('GET', '/health', undefined, 'https://example.com');
  assert.equal(blocked.headers.get('access-control-allow-origin'), null);
  assert.equal((await request('POST', '/disciplinas', { nome: 'Teste', cor: 'invalida' })).status, 400);
  assert.equal((await request('PUT', '/atividades/999', {})).status, 404);
});

test('dados permanecem após fechar e reabrir o banco', () => {
  const directory = mkdtempSync(join(tmpdir(), 'compasso-test-'));
  const path = join(directory, 'test.sqlite');
  let db;
  try {
    db = openDatabase(path);
    db.prepare('INSERT INTO disciplinas (nome) VALUES (?)').run('Persistência');
    db.close();
    db = openDatabase(path);
    assert.equal(db.prepare('SELECT nome FROM disciplinas').get().nome, 'Persistência');
  } finally { db?.close(); rmSync(directory, { recursive: true, force: true }); }
});
