import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../tasks/presentation/task_controller.dart';
import '../domain/calendar_event.dart';
import 'calendar_controller.dart';

class EventEditorScreen extends ConsumerStatefulWidget {
  final CalendarEvent? initialEvent;

  const EventEditorScreen({super.key, this.initialEvent});

  @override
  ConsumerState<EventEditorScreen> createState() => _EventEditorScreenState();
}

class _EventEditorScreenState extends ConsumerState<EventEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late final TextEditingController _locationController;

  late DateTime _startDate;
  late TimeOfDay _startTime;
  late DateTime _endDate;
  late TimeOfDay _endTime;
  late bool _allDay;
  late String _color;
  String? _recurrenceRule;
  late bool _isTimeBlock;
  String? _linkedTaskId;
  bool _isLoading = false;

  final List<String> _colorOptions = [
    '#1976D2', // Biru
    '#388E3C', // Hijau
    '#D32F2F', // Merah
    '#F57C00', // Oranye
    '#7B1FA2', // Ungu
    '#00796B', // Teal
  ];

  @override
  void initState() {
    super.initState();
    final ev = widget.initialEvent;
    _titleController = TextEditingController(text: ev?.title ?? '');
    _descController = TextEditingController(text: ev?.description ?? '');
    _locationController = TextEditingController(text: ev?.location ?? '');

    final now = DateTime.now();
    _startDate = ev?.startsAt ?? now;
    _startTime = ev != null
        ? TimeOfDay(hour: ev.startsAt.hour, minute: ev.startsAt.minute)
        : TimeOfDay(hour: now.hour, minute: 0);

    _endDate = ev?.endsAt ?? now.add(const Duration(hours: 1));
    _endTime = ev != null
        ? TimeOfDay(hour: ev.endsAt.hour, minute: ev.endsAt.minute)
        : TimeOfDay(hour: (now.hour + 1) % 24, minute: 0);

    _allDay = ev?.allDay ?? false;
    _color = ev?.color ?? '#1976D2';
    _recurrenceRule = ev?.recurrenceRule;
    _isTimeBlock = ev?.isTimeBlock ?? false;
    _linkedTaskId = ev?.linkedTaskId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  DateTime _combineDateTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _pickDate(bool isStart) async {
    final initial = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2040),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _pickTime(bool isStart) async {
    final initial = isStart ? _startTime : _endTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final startsAt = _combineDateTime(_startDate, _startTime);
    final endsAt = _combineDateTime(_endDate, _endTime);

    if (endsAt.isBefore(startsAt)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Waktu selesai tidak boleh lebih awal dari waktu mulai'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now().toUtc();
      if (widget.initialEvent == null) {
        // Buat baru
        final newEvent = CalendarEvent(
          id: '',
          userId: '',
          title: _titleController.text.trim(),
          description: _descController.text.trim().isEmpty
              ? null
              : _descController.text.trim(),
          startsAt: startsAt.toUtc(),
          endsAt: endsAt.toUtc(),
          allDay: _allDay,
          location: _locationController.text.trim().isEmpty
              ? null
              : _locationController.text.trim(),
          color: _color,
          recurrenceRule: _recurrenceRule,
          isTimeBlock: _isTimeBlock,
          linkedTaskId: _isTimeBlock ? _linkedTaskId : null,
          createdAt: now,
          updatedAt: now,
        );
        await ref.read(calendarActionsProvider.notifier).createEvent(newEvent);
      } else {
        // Edit yang ada
        final updated = widget.initialEvent!.copyWith(
          title: _titleController.text.trim(),
          description: _descController.text.trim().isEmpty
              ? null
              : _descController.text.trim(),
          startsAt: startsAt.toUtc(),
          endsAt: endsAt.toUtc(),
          allDay: _allDay,
          location: _locationController.text.trim().isEmpty
              ? null
              : _locationController.text.trim(),
          color: _color,
          recurrenceRule: _recurrenceRule,
          isTimeBlock: _isTimeBlock,
          linkedTaskId: _isTimeBlock ? _linkedTaskId : null,
        );
        await ref.read(calendarActionsProvider.notifier).updateEvent(updated);
      }

      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.initialEvent != null;
    final tasksAsync = ref.watch(taskListProvider);
    final tasks = tasksAsync.value ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Acara / Waktu' : 'Acara Baru'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Hapus',
              onPressed: () async {
                final confirm = await ConfirmDialog.show(
                  context,
                  title: 'Hapus Acara',
                  message: 'Pindahkan acara ini ke tempat sampah?',
                  confirmLabel: 'Hapus',
                  isDestructive: true,
                );
                if (confirm && mounted) {
                  await ref
                      .read(calendarActionsProvider.notifier)
                      .deleteEvent(widget.initialEvent!.id);
                  if (mounted) context.pop();
                }
              },
            ),
          IconButton(
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            tooltip: 'Simpan',
            onPressed: _isLoading ? null : _save,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Judul
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Judul Acara / Blok Waktu *',
                hintText: 'Misal: Rapat Tim, Blok Fokus Belajar',
                prefixIcon: Icon(Icons.title),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Judul wajib diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Toggle Seharian & Blok Waktu
            SwitchListTile(
              title: const Text('Acara Seharian (All Day)'),
              value: _allDay,
              onChanged: (val) => setState(() => _allDay = val),
            ),
            SwitchListTile(
              title: const Text('Blok Waktu Tugas (Time Blocking)'),
              subtitle:
                  const Text('Tautkan ke tugas tertentu untuk fokus kerja'),
              value: _isTimeBlock,
              onChanged: (val) => setState(() => _isTimeBlock = val),
            ),

            // Pemilih Tautan Tugas bila Time Block aktif
            if (_isTimeBlock) ...[
              const SizedBox(height: 8),
              DropdownButtonFormField<String?>(
                initialValue: _linkedTaskId,
                decoration: const InputDecoration(
                  labelText: 'Tautkan dengan Tugas',
                  prefixIcon: Icon(Icons.check_circle_outline),
                ),
                items: [
                  const DropdownMenuItem(
                      value: null, child: Text('Tidak Ditautkan ke Tugas')),
                  ...tasks.map(
                    (t) => DropdownMenuItem(
                      value: t.id,
                      child: Text(
                        t.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                onChanged: (val) => setState(() => _linkedTaskId = val),
              ),
            ],
            const SizedBox(height: 16),

            // Waktu Mulai
            ListTile(
              title: const Text('Waktu Mulai'),
              subtitle: Text(
                _allDay
                    ? DateFormat('EEEE, d MMMM yyyy', 'id_ID')
                        .format(_startDate)
                    : '${DateFormat('EEEE, d MMM yyyy', 'id_ID').format(_startDate)} jam ${_startTime.format(context)}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.calendar_month),
                    onPressed: () => _pickDate(true),
                  ),
                  if (!_allDay)
                    IconButton(
                      icon: const Icon(Icons.access_time),
                      onPressed: () => _pickTime(true),
                    ),
                ],
              ),
            ),

            // Waktu Selesai
            ListTile(
              title: const Text('Waktu Selesai'),
              subtitle: Text(
                _allDay
                    ? DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(_endDate)
                    : '${DateFormat('EEEE, d MMM yyyy', 'id_ID').format(_endDate)} jam ${_endTime.format(context)}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.calendar_month),
                    onPressed: () => _pickDate(false),
                  ),
                  if (!_allDay)
                    IconButton(
                      icon: const Icon(Icons.access_time),
                      onPressed: () => _pickTime(false),
                    ),
                ],
              ),
            ),
            const Divider(),

            // Aturan Pengulangan (RRULE)
            DropdownButtonFormField<String?>(
              initialValue: _recurrenceRule,
              decoration: const InputDecoration(
                labelText: 'Pengulangan',
                prefixIcon: Icon(Icons.repeat),
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('Tidak Berulang')),
                DropdownMenuItem(
                  value: 'FREQ=DAILY;INTERVAL=1',
                  child: Text('Setiap Hari'),
                ),
                DropdownMenuItem(
                  value: 'FREQ=WEEKLY;INTERVAL=1',
                  child: Text('Setiap Minggu'),
                ),
                DropdownMenuItem(
                  value: 'FREQ=MONTHLY;INTERVAL=1',
                  child: Text('Setiap Bulan'),
                ),
                DropdownMenuItem(
                  value: 'FREQ=YEARLY;INTERVAL=1',
                  child: Text('Setiap Tahun'),
                ),
              ],
              onChanged: (val) => setState(() => _recurrenceRule = val),
            ),
            const SizedBox(height: 16),

            // Lokasi
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Lokasi / Tautan Pertemuan',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
            const SizedBox(height: 16),

            // Warna
            const Text(
              'Label Warna',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: _colorOptions.map((c) {
                final isSelected = _color == c;
                final col = Color(
                    int.parse(c.replaceAll('#', ''), radix: 16) + 0xFF000000);
                return GestureDetector(
                  onTap: () => setState(() => _color = c),
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: col,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(
                              color: theme.colorScheme.onSurface, width: 3)
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 20)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Deskripsi / Catatan
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Deskripsi / Catatan Tambahan',
                prefixIcon: Icon(Icons.notes_rounded),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
            ),
          ],
        ),
      ),
    );
  }
}
