import express from 'express';
import cors from 'cors';

const colors = ['roxo', 'azul', 'verde', 'laranja', 'rosa'];
const asActivity = row => row ? { ...row, concluida: Boolean(row.concluida) } : null;
const error = (res, status, erro, campos = {}) => res.status(status).json({ erro, campos });
const validDate = value => {
  if (typeof value !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(value)) return false;
  const date = new Date(`${value}T12:00:00Z`);
  return !Number.isNaN(date.valueOf()) && date.toISOString().slice(0, 10) === value
    && value >= '2000-01-01' && value <= '2100-12-31';
};
const clean = value => typeof value === 'string' ? value.trim() : '';

export function createApp(db, { demo = false, origins = ['http://localhost:5173', 'http://127.0.0.1:5173'] } = {}) {
  const app = express();
  app.disable('x-powered-by');
  app.use(cors({ origin: origins, methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'] }));
  app.use(express.json({ limit: '32kb' }));
  app.get('/health', (_req, res) => res.json({ status: 'ok', demo }));

  app.param('id', (req, res, next, value) => {
    if (!/^[1-9]\d*$/.test(value) || !Number.isSafeInteger(Number(value))) {
      return error(res, 400, 'Identificador inválido.');
    }
    req.entityId = Number(value);
    next();
  });

  const discipline = id => db.prepare('SELECT * FROM disciplinas WHERE id = ?').get(id);
  const activity = id => asActivity(db.prepare('SELECT * FROM atividades WHERE id = ?').get(id));

  app.get('/disciplinas', (_req, res) => res.json(db.prepare('SELECT * FROM disciplinas ORDER BY nome COLLATE NOCASE').all()));
  app.get('/disciplinas/:id', (req, res) => {
    const row = discipline(req.entityId);
    return row ? res.json(row) : error(res, 404, 'Disciplina não encontrada.');
  });

  function saveDiscipline(req, res, update) {
    if (update && !discipline(req.entityId)) return error(res, 404, 'Disciplina não encontrada.');
    const nome = clean(req.body?.nome);
    const professor = clean(req.body?.professor);
    const cor = req.body?.cor || 'roxo';
    const campos = {};
    if (nome.length < 2 || nome.length > 80) campos.nome = 'Informe um nome entre 2 e 80 caracteres.';
    if (professor.length > 80) campos.professor = 'Use até 80 caracteres.';
    if (!colors.includes(cor)) campos.cor = 'Escolha uma das cores disponíveis.';
    if (Object.keys(campos).length) return error(res, 400, 'Confira os campos destacados.', campos);
    const duplicate = db.prepare('SELECT id, nome FROM disciplinas').all()
      .some(row => row.id !== (update ? req.entityId : 0)
        && row.nome.toLocaleLowerCase('pt-BR') === nome.toLocaleLowerCase('pt-BR'));
    if (duplicate) return error(res, 409, 'Essa disciplina já está cadastrada.', { nome: 'Escolha outro nome.' });
    let id = req.entityId;
    if (update) db.prepare('UPDATE disciplinas SET nome=?, professor=?, cor=? WHERE id=?').run(nome, professor, cor, id);
    else id = Number(db.prepare('INSERT INTO disciplinas (nome, professor, cor) VALUES (?, ?, ?)').run(nome, professor, cor).lastInsertRowid);
    return res.status(update ? 200 : 201).json(discipline(id));
  }
  app.post('/disciplinas', (req, res) => saveDiscipline(req, res, false));
  app.put('/disciplinas/:id', (req, res) => saveDiscipline(req, res, true));
  app.delete('/disciplinas/:id', (req, res) => {
    if (!discipline(req.entityId)) return error(res, 404, 'Disciplina não encontrada.');
    if (db.prepare('SELECT id FROM atividades WHERE disciplinaId=? LIMIT 1').get(req.entityId)) {
      return error(res, 409, 'Esta disciplina tem atividades. Exclua ou transfira as atividades antes de removê-la.');
    }
    db.prepare('DELETE FROM disciplinas WHERE id=?').run(req.entityId);
    return res.sendStatus(204);
  });

  app.get('/atividades', (_req, res) => res.json(db.prepare('SELECT * FROM atividades ORDER BY prazo, id').all().map(asActivity)));
  app.get('/atividades/:id', (req, res) => {
    const row = activity(req.entityId);
    return row ? res.json(row) : error(res, 404, 'Atividade não encontrada.');
  });
  function saveActivity(req, res, update) {
    if (update && !activity(req.entityId)) return error(res, 404, 'Atividade não encontrada.');
    const { disciplinaId, tipo, prazo } = req.body || {};
    const titulo = clean(req.body?.titulo);
    const descricao = clean(req.body?.descricao);
    const campos = {};
    if (titulo.length < 3 || titulo.length > 120) campos.titulo = 'Informe um título entre 3 e 120 caracteres.';
    if (descricao.length > 2000) campos.descricao = 'Use até 2.000 caracteres nas anotações.';
    if (!Number.isSafeInteger(disciplinaId) || !discipline(disciplinaId)) campos.disciplinaId = 'Escolha uma disciplina cadastrada.';
    if (!['tarefa', 'prova'].includes(tipo)) campos.tipo = 'Escolha tarefa ou prova.';
    if (!validDate(prazo)) campos.prazo = 'Informe uma data válida entre 2000 e 2100.';
    if (Object.keys(campos).length) return error(res, 400, 'Confira os campos destacados.', campos);
    let id = req.entityId;
    if (update) db.prepare('UPDATE atividades SET titulo=?, descricao=?, disciplinaId=?, tipo=?, prazo=? WHERE id=?')
      .run(titulo, descricao, disciplinaId, tipo, prazo, id);
    else id = Number(db.prepare('INSERT INTO atividades (titulo, descricao, disciplinaId, tipo, prazo) VALUES (?, ?, ?, ?, ?)')
      .run(titulo, descricao, disciplinaId, tipo, prazo).lastInsertRowid);
    return res.status(update ? 200 : 201).json(activity(id));
  }
  app.post('/atividades', (req, res) => saveActivity(req, res, false));
  app.put('/atividades/:id', (req, res) => saveActivity(req, res, true));
  app.patch('/atividades/:id', (req, res) => {
    if (!activity(req.entityId)) return error(res, 404, 'Atividade não encontrada.');
    if (typeof req.body?.concluida !== 'boolean') return error(res, 400, 'Informe a situação da atividade.', { concluida: 'Use verdadeiro ou falso.' });
    db.prepare('UPDATE atividades SET concluida=? WHERE id=?').run(Number(req.body.concluida), req.entityId);
    return res.json(activity(req.entityId));
  });
  app.delete('/atividades/:id', (req, res) => {
    if (!activity(req.entityId)) return error(res, 404, 'Atividade não encontrada.');
    db.prepare('DELETE FROM atividades WHERE id=?').run(req.entityId);
    return res.sendStatus(204);
  });

  app.use((_req, res) => error(res, 404, 'Rota não encontrada.'));
  app.use((err, _req, res, _next) => {
    if (err.type === 'entity.parse.failed') return error(res, 400, 'O corpo da requisição deve ser um JSON válido.');
    if (err.type === 'entity.too.large') return error(res, 413, 'O conteúdo enviado é muito grande.');
    console.error(err);
    return error(res, 500, 'Não foi possível concluir a operação. Tente novamente.');
  });
  return app;
}
