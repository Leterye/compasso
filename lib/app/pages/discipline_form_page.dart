import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../shared/api_client.dart';
import '../../shared/theme.dart';
import '../../shared/widgets.dart';
import '../study_store.dart';

class DisciplineFormPage extends StatefulWidget {
  final int? id;
  const DisciplineFormPage({this.id, super.key});
  @override
  State<DisciplineFormPage> createState() => _DisciplineFormPageState();
}

class _DisciplineFormPageState extends State<DisciplineFormPage> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(), teacher = TextEditingController();
  final nameFocus = FocusNode();
  String color = 'roxo';
  String? error;
  Map<String, String> fields = {};
  bool initialized = false, saving = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (initialized) return;
    initialized = true;
    final d = context.read<StudyStore>().discipline(widget.id ?? -1);
    if (d != null) {
      name.text = d.nome;
      teacher.text = d.professor;
      color = d.cor;
    }
  }

  @override
  void dispose() {
    name.dispose();
    teacher.dispose();
    nameFocus.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (saving) return;
    setState(() {
      fields = {};
      error = null;
    });
    if (!form.currentState!.validate()) {
      nameFocus.requestFocus();
      return;
    }
    setState(() => saving = true);
    try {
      await context.read<StudyStore>().saveDiscipline({
        'nome': name.text.trim(),
        'professor': teacher.text.trim(),
        'cor': color,
      }, id: widget.id);
      if (mounted) {
        showMessage(
          context,
          widget.id == null
              ? 'Disciplina cadastrada.'
              : 'Disciplina atualizada.',
        );
        context.go('/disciplinas');
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
    if (widget.id != null &&
        context.read<StudyStore>().discipline(widget.id!) == null) {
      return const EmptyState(
        title: 'Disciplina não encontrada',
        message: 'Volte à lista para escolher uma disciplina.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: saving ? null : () => context.go('/disciplinas'),
          icon: const Icon(Icons.arrow_back, size: 18),
          label: const Text('Disciplinas'),
        ),
        const SizedBox(height: 16),
        PageHeading(
          widget.id == null ? 'Nova disciplina' : 'Editar disciplina',
          'Dê um nome e uma cor para organizar seus estudos.',
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Surface(
            child: Form(
              key: form,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (error != null) ErrorNotice(error!),
                  TextFormField(
                    controller: name,
                    focusNode: nameFocus,
                    autofocus: true,
                    maxLength: 80,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Nome da disciplina',
                      hintText: 'Ex.: Frameworks Web',
                      errorText: fields['nome'],
                    ),
                    validator: (value) => (value?.trim().length ?? 0) < 2
                        ? 'Informe pelo menos 2 caracteres.'
                        : null,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: teacher,
                    maxLength: 80,
                    decoration: InputDecoration(
                      labelText: 'Professor ou professora (opcional)',
                      errorText: fields['professor'],
                    ),
                    onFieldSubmitted: (_) => save(),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Cor da disciplina',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final c in {
                        'roxo': 'Roxo',
                        'azul': 'Azul',
                        'verde': 'Verde',
                        'laranja': 'Laranja',
                        'rosa': 'Rosa',
                      }.entries)
                        ChoiceChip(
                          selected: color == c.key,
                          label: Text(c.value),
                          avatar: Icon(
                            Icons.circle,
                            color: AppColors.subject(c.key),
                            size: 16,
                          ),
                          onSelected: saving
                              ? null
                              : (_) => setState(() => color = c.key),
                        ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton(
                        onPressed: saving ? null : save,
                        child: Text(saving ? 'Salvando…' : 'Salvar disciplina'),
                      ),
                      TextButton(
                        onPressed: saving
                            ? null
                            : () => context.go('/disciplinas'),
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
