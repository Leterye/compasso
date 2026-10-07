import { openDatabase } from './database.js';

const db = openDatabase();
try {
  if (db.prepare('SELECT COUNT(*) AS total FROM disciplinas').get().total) {
    console.log('Banco já possui disciplinas. Nenhum dado foi alterado.');
  } else {
    db.exec('BEGIN');
    const insert = db.prepare('INSERT INTO disciplinas (nome, professor, cor) VALUES (?, ?, ?)');
    const framework = Number(insert.run('Frameworks Web', 'Prof. Wagner', 'roxo').lastInsertRowid);
    const database = Number(insert.run('Banco de Dados', '', 'azul').lastInsertRowid);
    const software = Number(insert.run('Engenharia de Software', '', 'verde').lastInsertRowid);
    const date = offset => {
      const d = new Date(); d.setDate(d.getDate() + offset);
      return `${d.getFullYear()}-${String(d.getMonth()+1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
    };
    const task = db.prepare('INSERT INTO atividades (titulo, descricao, disciplinaId, tipo, prazo, concluida) VALUES (?, ?, ?, ?, ?, ?)');
    task.run('Apresentar a primeira versão do projeto', 'Revisar a demonstração de cadastro e listagem de atividades.', framework, 'tarefa', date(1), 0);
    task.run('Revisar consultas SQL', 'Praticar JOIN, agrupamento e filtros.', database, 'tarefa', date(0), 0);
    task.run('Prova de modelagem de dados', 'Revisar entidades, relacionamentos e normalização.', database, 'prova', date(3), 0);
    task.run('Descrever os casos de uso', '', software, 'tarefa', date(5), 0);
    task.run('Organizar a estrutura do projeto', '', framework, 'tarefa', date(-1), 1);
    db.exec('COMMIT');
    console.log('Dados fictícios de demonstração adicionados.');
  }
} finally { db.close(); }
