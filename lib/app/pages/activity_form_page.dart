import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../shared/api_client.dart';
import '../../shared/widgets.dart';
import '../study_store.dart';

class ActivityFormPage extends StatefulWidget {
  final int? id;
  const ActivityFormPage({this.id, super.key});
  @override
  State<ActivityFormPage> createState() => _ActivityFormPageState();
}

class _ActivityFormPageState extends State<ActivityFormPage> {
  final form = GlobalKey<FormState>();
  final title = TextEditingController(),
      notes = TextEditingController(),
      date = TextEditingController();
  final titleFocus = FocusNode(),
      dateFocus = FocusNode(),
      disciplineFocus = FocusNode();
  int? disciplineId;
  String type = 'tarefa';
  bool initialized = false, saving = false;
  String? error;
  Map<String, String> fields = {};

  DateTime? parseDate() {
    try {
      final value = DateFormat('dd/MM/yyyy').parseStrict(date.text);
      return value.year < 2000 || value.year > 2100 ? null : value;
    } on FormatException {
      return null;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (initialized) return;
    initialized = true;
    final store = context.read<StudyStore>();
    final activity = store.activity(widget.id ?? -1);
    if (activity != null) {
      title.text = activity.titulo;
      notes.text = activity.descricao;
      type = activity.tipo;
      disciplineId = activity.disciplinaId;
      date.text = DateFormat('dd/MM/yyyy').format(activity.prazo);
    } else if (store.disciplinas.length == 1) {
      disciplineId = store.disciplinas.first.id;
    }
  }

  @override
  void dispose() {
    title.dispose();
    notes.dispose();
    date.dispose();
    titleFocus.dispose();
    dateFocus.dispose();
    disciplineFocus.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (saving) return;
    setState(() {
      fields = {};
      error = null;
    });
    if (!form.currentState!.validate()) {
      if (title.text.trim().length < 3) {
        titleFocus.requestFocus();
      } else if (disciplineId == null) {
        disciplineFocus.requestFocus();
      } else if (parseDate() == null) {
        dateFocus.requestFocus();
      }
      return;
    }
    setState(() => saving = true);
    try {
      await context.read<StudyStore>().saveActivity({
        'titulo': title.text.trim(),
        'descricao': notes.text.trim(),
        'disciplinaId': disciplineId,
        'tipo': type,
        'prazo': DateFormat('yyyy-MM-dd').format(parseDate()!),
      }, id: widget.id);
      if (mounted) {
        showMessage(
          context,
          widget.id == null ? 'Atividade cadastrada.' : 'Atividade atualizada.',
        );
        context.go('/atividades');
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          error = e.message;
          fields = e.fields;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => error = 'Não foi possível salvar. Tente novamente.');
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<StudyStore>();
    if (widget.id != null && store.activity(widget.id!) == null) {
      return const EmptyState(
        title: 'Atividade não encontrada',
        message: 'Volte à lista para escolher outra atividade.',
      );
    }
    if (store.disciplinas.isEmpty) {
      return Surface(
        child: EmptyState(
          icon: Icons.menu_book_outlined,
          title: 'Primeiro, uma disciplina',
          message: 'Toda tarefa ou prova pertence a uma disciplina. Cadastre a primeira para continuar.',
          action: FilledButton(
            onPressed: () => context.go('/disciplinas/nova'),
            child: const Text('Cadastrar disciplina'),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: saving ? null : () => context.go('/atividades'),
          icon: const Icon(Icons.arrow_back, size: 18),
          label: const Text('Atividades'),
        ),
        const SizedBox(height: 16),
        PageHeading(
          widget.id == null ? 'Nova atividade' : 'Editar atividade',
          'Anote o que precisa fazer e quando precisa entregar.',
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Surface(
            child: Form(
              key: form,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (error != null) ErrorNotice(error!),
                  const Text(
                    'O que você vai organizar?',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'tarefa',
                        label: Text('Tarefa'),
                        icon: Icon(Icons.checklist_rounded),
                      ),
                      ButtonSegment(
                        value: 'prova',
                        label: Text('Prova'),
                        icon: Icon(Icons.edit_note_rounded),
                      ),
                    ],
                    selected: {type},
                    onSelectionChanged: saving
                        ? null
                        : (value) => setState(() => type = value.first),
                  ),
                  const SizedBox(height: 28),
                  TextFormField(
                    controller: title,
                    focusNode: titleFocus,
                    autofocus: true,
                    maxLength: 120,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Título da atividade',
                      hintText: 'Ex.: Revisar o conteúdo da prova',
                      errorText: fields['titulo'],
                    ),
                    validator: (value) => (value?.trim().length ?? 0) < 3
                        ? 'Informe pelo menos 3 caracteres.'
                        : null,
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<int>(
                    initialValue: disciplineId,
                    focusNode: disciplineFocus,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Disciplina',
                      errorText: fields['disciplinaId'],
                    ),
                    items: [
                      for (final d in store.disciplinas)
                        DropdownMenuItem(
                          value: d.id,
                          child: Text(d.nome, overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: saving
                        ? null
                        : (value) => setState(() => disciplineId = value),
                    validator: (value) =>
                        value == null ? 'Escolha uma disciplina.' : null,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: date,
                    focusNode: dateFocus,
                    keyboardType: TextInputType.datetime,
                    maxLength: 10,
                    decoration: InputDecoration(
                      labelText: 'Prazo',
                      hintText: 'dd/mm/aaaa',
                      helperText: 'A atividade vence ao final deste dia.',
                      errorText: fields['prazo'],
                      suffixIcon: IconButton(
                        tooltip: 'Escolher data no calendário',
                        onPressed: saving
                            ? null
                            : () async {
                                final chosen = await showDatePicker(
                                  context: context,
                                  initialDate: parseDate() ?? DateTime.now(),
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100, 12, 31),
                                );
                                if (chosen != null) {
                                  date.text = DateFormat('dd/MM/yyyy')
                                      .format(chosen);
                                }
                              },
                        icon: const Icon(
                          Icons.calendar_today_outlined,
                          size: 20,
                        ),
                      ),
                    ),
                    validator: (_) => parseDate() == null
                        ? 'Use uma data válida no formato dd/mm/aaaa (2000 a 2100).'
                        : null,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: notes,
                    minLines: 3,
                    maxLines: 6,
                    maxLength: 2000,
                    decoration: InputDecoration(
                      labelText: 'Anotações (opcional)',
                      alignLabelWithHint: true,
                      hintText: 'Conteúdo, orientações ou o que você não quer esquecer.',
                      errorText: fields['descricao'],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton(
                        onPressed: saving ? null : save,
                        child: Text(saving ? 'Salvando…' : 'Salvar atividade'),
                      ),
                      TextButton(
                        onPressed: saving
                            ? null
                            : () => context.go('/atividades'),
                        child: const Text('Cancelar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
