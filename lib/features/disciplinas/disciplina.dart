class Disciplina {
  final int id;
  final String nome, professor, cor;
  const Disciplina({
    required this.id,
    required this.nome,
    this.professor = '',
    this.cor = 'roxo',
  });
  factory Disciplina.fromJson(Map<String, dynamic> json) => Disciplina(
    id: json['id'] as int,
    nome: json['nome'] as String,
    professor: json['professor'] as String,
    cor: json['cor'] as String,
  );
}
