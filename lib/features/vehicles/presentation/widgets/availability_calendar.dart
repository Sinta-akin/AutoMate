import 'package:flutter/material.dart';
import 'package:automate/core/theme/app_theme.dart';

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Month calendar showing booked days and letting the user pick a
/// start/end date. Selection state is owned by the parent.
class AvailabilityCalendar extends StatefulWidget {
  final Set<DateTime> unavailable;
  final DateTime? start;
  final DateTime? end;
  final ValueChanged<DateTime> onDayTap;

  const AvailabilityCalendar({
    super.key,
    required this.unavailable,
    required this.start,
    required this.end,
    required this.onDayTap,
  });

  @override
  State<AvailabilityCalendar> createState() => _AvailabilityCalendarState();
}

class _AvailabilityCalendarState extends State<AvailabilityCalendar> {
  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June', 'July',
    'August', 'September', 'October', 'November', 'December',
  ];
  static const _weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
  static const _maxMonthsAhead = 12;

  late final DateTime _today = dateOnly(DateTime.now());
  late DateTime _visibleMonth = DateTime(_today.year, _today.month);

  bool get _canGoBack =>
      _visibleMonth.isAfter(DateTime(_today.year, _today.month));
  bool get _canGoForward => _visibleMonth
      .isBefore(DateTime(_today.year, _today.month + _maxMonthsAhead));

  void _changeMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    });
  }

  bool _isBooked(DateTime d) => widget.unavailable.contains(d);

  bool _inRange(DateTime d) {
    final s = widget.start;
    final e = widget.end;
    if (s == null || e == null) return false;
    return !d.isBefore(s) && !d.isAfter(e);
  }

  @override
  Widget build(BuildContext context) {
    final first = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    final daysInMonth =
        DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
    final leading = first.weekday % 7; // Sunday = 0

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: _canGoBack ? () => _changeMonth(-1) : null,
                icon: const Icon(Icons.chevron_left),
                color: Colors.white,
                disabledColor: AppTheme.border,
              ),
              Text(
                '${_months[_visibleMonth.month - 1]} ${_visibleMonth.year}',
                style: AppTheme.sectionHeading,
              ),
              IconButton(
                onPressed: _canGoForward ? () => _changeMonth(1) : null,
                icon: const Icon(Icons.chevron_right),
                color: Colors.white,
                disabledColor: AppTheme.border,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Row(
            children: _weekdays
                .map((w) => Expanded(
              child: Center(
                child: Text(w, style: AppTheme.labelMedium),
              ),
            ))
                .toList(),
          ),
          const SizedBox(height: AppTheme.spacingXs),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: leading + daysInMonth,
            itemBuilder: (context, index) {
              if (index < leading) return const SizedBox.shrink();
              final day = DateTime(
                  _visibleMonth.year, _visibleMonth.month, index - leading + 1);
              return _buildDay(day);
            },
          ),
          const SizedBox(height: AppTheme.spacingMd),
          const Wrap(
            spacing: AppTheme.spacingMd,
            runSpacing: AppTheme.spacingXs,
            children: [
              _LegendItem(color: AppTheme.primaryBlue, label: 'Selected'),
              _LegendItem(color: AppTheme.errorRed, label: 'Booked'),
              _LegendItem(color: AppTheme.accentOrange, label: 'Today'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDay(DateTime day) {
    final isPast = day.isBefore(_today);
    final booked = _isBooked(day);
    final disabled = isPast || booked;
    final isEdge = day == widget.start || day == widget.end;
    final inRange = _inRange(day);
    final isToday = day == _today;

    Color? bg;
    Color textColor = Colors.white;
    if (isEdge) {
      bg = AppTheme.primaryBlue;
    } else if (inRange) {
      bg = AppTheme.primaryBlue.withValues(alpha: 0.3);
    } else if (booked && !isPast) {
      bg = AppTheme.errorRed.withValues(alpha: 0.2);
      textColor = AppTheme.errorRed;
    }
    if (isPast) textColor = AppTheme.border;

    return GestureDetector(
      onTap: disabled ? null : () => widget.onDayTap(day),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          border: isToday && !isEdge
              ? Border.all(color: AppTheme.accentOrange, width: 1.5)
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          '${day.day}',
          style: TextStyle(
            color: textColor,
            fontSize: 13,
            fontWeight: isEdge ? FontWeight.w700 : FontWeight.w500,
            decoration: booked && !isPast ? TextDecoration.lineThrough : null,
          ),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppTheme.labelMedium),
      ],
    );
  }
}