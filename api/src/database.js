import { DatabaseSync } from 'node:sqlite';
import { mkdirSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

export const defaultPath = fileURLToPath(new URL('../data/compasso.sqlite', import.meta.url));

export function openDatabase(path = process.env.DB_PATH || defaultPath) {
  if (path !== ':memory:') mkdirSync(dirname(resolve(path)), { recursive: true });
  const db = new DatabaseSync(path);
  db.exec(`
    PRAGMA foreign_keys = ON;
    PRAGMA journal_mode = WAL;
    CREATE TABLE IF NOT EXISTS disciplinas (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      nome TEXT NOT NULL,
      professor TEXT NOT NULL DEFAULT '',
      cor TEXT NOT NULL DEFAULT 'roxo',
      criadoEm TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
    );
    CREATE TABLE IF NOT EXISTS atividades (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      titulo TEXT NOT NULL,
      descricao TEXT NOT NULL DEFAULT '',
      disciplinaId INTEGER NOT NULL REFERENCES disciplinas(id) ON DELETE RESTRICT,
      tipo TEXT NOT NULL CHECK(tipo IN ('tarefa', 'prova')),
      prazo TEXT NOT NULL,
      concluida INTEGER NOT NULL DEFAULT 0 CHECK(concluida IN (0, 1)),
      criadoEm TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
    );
    CREATE INDEX IF NOT EXISTS atividades_prazo ON atividades(prazo);
  `);
  return db;
}
