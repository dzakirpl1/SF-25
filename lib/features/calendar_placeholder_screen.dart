import 'package:flutter/material.dart';
import '../shared/widgets/empty_view.dart';

class CalendarPlaceholderScreen extends StatelessWidget {
  const CalendarPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kalender')),
      body: const EmptyView(
        icon: Icons.calendar_month_outlined,
        title: 'Modul Kalender',
        subtitle: 'Direncanakan pada Fase 6 sesuai master blueprint.\n(Tampilan bulan/minggu/hari, agenda, dan blok waktu).',
      ),
    );
  }
}
