# Compasso · Organizador de estudos

Aplicativo individual em Flutter Web para cadastrar disciplinas, tarefas e provas,
acompanhar prazos e marcar atividades como concluídas. Visual roxo e branco.

## Onde está cada código

| Pasta | Conteúdo |
|---|---|
| `lib/app/pages` | Telas e formulários |
| `lib/app` | Navegação, menu e estado dos dados |
| `lib/features` | Modelos e acesso à API de disciplinas e atividades |
| `lib/shared` | Tema, componentes reutilizáveis e cliente HTTP |
| `api/src` | Servidor e banco de dados SQLite |
| `web` | Página que carrega o Flutter no navegador |
| `test` e `api/test` | Testes do aplicativo e da API |
| `scripts` | Servidor para visualizar os arquivos web compilados |

`lib/main.dart` inicia o aplicativo. `pubspec.yaml` lista os pacotes Flutter;
`api/package.json` lista os pacotes do servidor. Arquivos gerados e configurações
auxiliares estão ocultos no explorador do VS Code, mas continuam no disco.

## Como funciona

A tela chama o `StudyStore`, que chama a API da funcionalidade. O servidor valida
os dados e salva em SQLite. Provider compartilha o estado; go_router gerencia as
rotas; http faz requisições; intl formata datas. O prazo vale até o fim do dia local.
Código de interface, regras e acesso a dados ficam separados.

Telas: `/`, `/atividades`, `/atividades/nova`, `/atividades/:id`,
`/atividades/:id/editar`, `/disciplinas`, `/disciplinas/nova` e
`/disciplinas/:id/editar`. Filtros ficam na URL após `?`; o navegador usa `/#/`.

API: GET lista ou busca; POST cadastra; PUT edita; DELETE exclui em `/disciplinas`
e `/atividades`. Operações sobre um item recebem `/:id`. PATCH `/atividades/:id`
recebe `{ "concluida": true }` ou false. `/health` informa se a API está ativa.
Disciplina tem nome, professor e cor; atividade tem título, disciplinaId, tipo,
prazo (`YYYY-MM-DD`) e descrição. Erros retornam `{ erro, campos }`.
Sucesso: 200/201/204; validação: 400; inexistente: 404; conflito: 409.

O banco pessoal fica em `api/data/compasso.sqlite`, fora do Git. A demonstração
usa um banco separado e avisa na tela que os dados são fictícios. Não há login
nesta versão local. SQLite foi escolhido pela simplicidade; confirmar banco
obrigatório com o professor, pois a Aula 06 também exemplifica MySQL/PostgreSQL.

## Executar

Abra `C:\dev\organizador_estudos` no VS Code. É um atalho para a pasta original,
sem duplicação, que evita problemas do Flutter com acentos no caminho.
Requisitos instalados: Flutter 3.47.6, Dart 3.13.5 e Node.js 24.

Terminal 1:
```powershell
cd C:\dev\organizador_estudos\api
npm ci
npm start
```

Terminal 2:
```powershell
cd C:\dev\organizador_estudos
flutter pub get
flutter run -d chrome --web-port 5173
```

App: http://127.0.0.1:5173. API: http://127.0.0.1:3001. Ctrl+C encerra cada processo.
Para visualizar arquivos web já gerados, use `node scripts/serve-web.mjs` no
segundo terminal. A prévia atual contém exemplos fictícios.

## Estado e verificação

`flutter analyze` passou sem erros; `npm test` em `api/` passou nos 3 testes.
Cadastro, validação, conclusão, persistência após recarregar e filtro de concluídas
foram testados no navegador; a lista também foi conferida em tela estreita.
Git é local; ainda não existe repositório no GitHub.

**Pendência do ambiente:** o Windows bloqueou o `impellerc.exe` do Flutter na etapa
de shaders. Por isso, `flutter build web`, `flutter run` e os testes Flutter ainda
não estão validados integralmente. A prévia abre os arquivos emitidos antes da
falha, mas não é uma build final aprovada. Não foi alterada a segurança do Windows.
Após solucionar essa compatibilidade de forma autorizada, repetir `flutter test`
e `flutter build web`.

Na apresentação, demonstre criar disciplina e atividade, filtrar, concluir e
recarregar para comprovar persistência. Explique o caminho tela → estado → API → banco.
