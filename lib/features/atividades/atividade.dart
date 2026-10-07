class Atividade {
  final int id, disciplinaId;
  final String titulo, descricao, tipo;
  final DateTime prazo;
  final bool concluida;
  const Atividade({
    required this.id,
    required this.disciplinaId,
    required this.titulo,
    required this.descricao,
    required this.tipo,
    required this.prazo,
    required this.concluida,
  });
  factory Atividade.fromJson(Map<String, dynamic> json) => Atividade(
    id: json['id'] as int,
    disciplinaId: json['disciplinaId'] as int,
    titulo: json['titulo'] as String,
    descricao: json['descricao'] as String,
    tipo: json['tipo'] as String,
    prazo: DateTime.parse(json['prazo'] as String),
    concluida: json['concluida'] as bool,
  );
  bool overdue(DateTime today) =>
      !concluida &&
      prazo.isBefore(DateTime(today.year, today.month, today.day));
}
