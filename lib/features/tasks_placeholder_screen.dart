import 'package:flutter/material.dart';
import '../shared/widgets/empty_view.dart';

class TasksPlaceholderScreen extends StatelessWidget {
  const TasksPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tugas')),
      body: const EmptyView(
        icon: Icons.check_circle_outline_rounded,
        title: 'Modul Tugas & Proyek',
        subtitle:
            'Direncanakan pada Fase 4 sesuai master blueprint.\n(Tenggat, prioritas, subtugas, matriks Eisenhower).',
      ),
    );
  }
}
