import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../providers/app_provider.dart';
import '../../models/shift.dart';

class ShiftSchedulerWidget extends StatefulWidget {
  final String courierId;

  const ShiftSchedulerWidget({super.key, required this.courierId});

  @override
  State<ShiftSchedulerWidget> createState() => _ShiftSchedulerWidgetState();
}

class _ShiftSchedulerWidgetState extends State<ShiftSchedulerWidget> {
  final List<String> _daysOfWeek = [
    'Pazartesi',
    'Salı',
    'Çarşamba',
    'Perşembe',
    'Cuma',
    'Cumartesi',
    'Pazar'
  ];

  Map<String, Map<String, dynamic>> _schedule = {};
  String _weekStartDate = '';

  @override
  void initState() {
    super.initState();
    // Default next Monday as week start date
    final now = DateTime.now();
    final nextMonday = now.add(Duration(days: (8 - now.weekday) % 7));
    _weekStartDate = nextMonday.toIso8601String().split('T')[0];

    // Initialize schedule days
    for (var day in _daysOfWeek) {
      _schedule[day] = {
        'enabled': false,
        'start': '10:00',
        'end': '22:00',
      };
    }
  }

  void _submit(AppProvider provider) {
    provider.submitShift(widget.courierId, _weekStartDate, _schedule);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Vardiya planınız başarıyla şirkete gönderildi! 📅'),
        backgroundColor: const Color(0xFF4F46E5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    
    // Find active shift for this week
    final activeShift = provider.shifts.firstWhere(
      (s) => s.courierId == widget.courierId && s.weekStartDate == _weekStartDate,
      orElse: () => provider.shifts.isNotEmpty ? provider.shifts.first : _dummyShift(),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Hafta Başlangıcı: $_weekStartDate',
              style: const TextStyle(color: const Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.bold),
            ),
            if (activeShift.id.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: activeShift.status == 'approved'
                      ? Colors.green.withOpacity(0.2)
                      : activeShift.status == 'rejected'
                          ? Colors.red.withOpacity(0.2)
                          : Colors.amber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  activeShift.status.toUpperCase(),
                  style: TextStyle(
                    color: activeShift.status == 'approved'
                        ? Colors.green
                        : activeShift.status == 'rejected'
                            ? Colors.red
                            : Colors.amber,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              )
            ]
          ],
        ),
        const SizedBox(height: 20),
        
        // Days list editor
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _daysOfWeek.length,
          itemBuilder: (context, index) {
            final day = _daysOfWeek[index];
            final dayData = _schedule[day]!;
            final isEnabled = dayData['enabled'] as bool;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: isEnabled,
                    activeColor: const Color(0xFF6366F1),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _schedule[day]!['enabled'] = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      day,
                      style: const TextStyle(color: const Color(0xFF0F172A), fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (isEnabled) ...[
                    Row(
                      children: [
                        _buildTimeSelector(day, 'start'),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text('-', style: TextStyle(color: const Color(0xFF475569))),
                        ),
                        _buildTimeSelector(day, 'end'),
                      ],
                    )
                  ] else ...[
                    const Text('Tatil / Kapalı', style: TextStyle(color: const Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.bold))
                  ]
                ],
              ),
            );
          },
        ),

        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () => _submit(provider),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4F46E5),
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: const Text('Vardiyayı Kaydet & Gönder', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
        )
      ],
    );
  }

  Widget _buildTimeSelector(String day, String key) {
    final currentVal = _schedule[day]![key] as String;
    return InkWell(
      onTap: () async {
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(
            hour: int.parse(currentVal.split(':')[0]),
            minute: int.parse(currentVal.split(':')[1]),
          ),
        );
        if (time != null) {
          final hr = time.hour.toString().padLeft(2, '0');
          final min = time.minute.toString().padLeft(2, '0');
          setState(() {
            _schedule[day]![key] = '$hr:$min';
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          currentVal,
          style: const TextStyle(color: const Color(0xFF6366F1), fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Shift _dummyShift() {
    return Shift(
      id: '',
      courierId: '',
      weekStartDate: '',
      days: {},
      status: 'none',
      submittedAt: '',
      createdAt: '',
    );
  }
}
