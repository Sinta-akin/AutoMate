import 'package:flutter/material.dart';
import 'package:automate/core/theme/app_theme.dart';
import 'package:automate/core/widgets/common_widgets.dart';
import 'package:automate/features/vehicles/domain/vehicle.dart';
import 'package:automate/features/vehicles/presentation/widgets/availability_calendar.dart';

/// Feature 3: vehicle details page.
///
/// Open with: Navigator.pushNamed(context, AppConstants.vehicleDetails,
///     arguments: vehicle);
class VehicleDetailsScreen extends StatefulWidget {
  final Vehicle vehicle;

  const VehicleDetailsScreen({super.key, required this.vehicle});

  @override
  State<VehicleDetailsScreen> createState() => _VehicleDetailsScreenState();
}

class _VehicleDetailsScreenState extends State<VehicleDetailsScreen> {
  final _pageController = PageController();
  int _imageIndex = 0;
  DateTime? _start;
  DateTime? _end;

  Vehicle get v => widget.vehicle;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onDayTap(DateTime day) {
    setState(() {
      if (_start == null || _end != null || day.isBefore(_start!)) {
        _start = day;
        _end = null;
        return;
      }
      // Reject ranges that cross a booked day.
      var d = _start!;
      while (!d.isAfter(day)) {
        if (v.unavailableDates.contains(d)) {
          _start = day;
          _end = null;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Selected dates include a booked day'),
            ),
          );
          return;
        }
        d = DateTime(d.year, d.month, d.day + 1);
      }
      _end = day;
    });
  }

  int get _days {
    if (_start == null) return 0;
    final end = _end ?? _start!;
    return end.difference(_start!).inDays + 1;
  }

  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';

  void _requestBooking() {
    if (_start == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your rental dates')),
      );
      return;
    }
    final end = _end ?? _start!;
    final total = _days * v.dailyPrice;

    // TODO: when the database is ready, create a booking document here.
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Booking request sent'),
        content: Text(
          '${v.title}\n${_fmt(_start!)} - ${_fmt(end)} '
              '($_days day${_days == 1 ? '' : 's'})\n'
              'Estimated total: Rs. $total\n\n'
              '${v.ownerName} will review your request.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _gallery() {
    return SizedBox(
      height: 260,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: v.images.length,
            onPageChanged: (i) => setState(() => _imageIndex = i),
            itemBuilder: (_, i) => _VehicleImage(path: v.images[i]),
          ),
          Positioned(
            right: AppTheme.spacingMd,
            top: AppTheme.spacingMd,
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
              child: Text(
                '${_imageIndex + 1}/${v.images.length}',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
          Positioned(
            bottom: AppTheme.spacingMd,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(v.images.length, (i) {
                final active = i == _imageIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: active ? Colors.white : Colors.white54,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.primaryBlue),
          const SizedBox(width: 6),
          Text(text,
              style: const TextStyle(color: Colors.white, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSm),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.accentOrange, size: 22),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTheme.labelMedium),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: const AppHeader(title: 'Vehicle Details'),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _gallery(),
                    Padding(
                      padding: const EdgeInsets.all(AppTheme.spacingLg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(v.title, style: AppTheme.headline2),
                          const SizedBox(height: 4),
                          Text(v.model, style: AppTheme.bodyLarge),
                          const SizedBox(height: AppTheme.spacingMd),
                          Wrap(
                            spacing: AppTheme.spacingSm,
                            runSpacing: AppTheme.spacingSm,
                            children: [
                              _infoChip(Icons.category_outlined, v.categoryName),
                              _infoChip(Icons.event_seat_outlined,
                                  '${v.seats} seats'),
                            ],
                          ),
                          const SizedBox(height: AppTheme.spacingLg),
                          const Text('Description',
                              style: AppTheme.sectionHeading),
                          const SizedBox(height: AppTheme.spacingSm),
                          Text(v.description, style: AppTheme.bodyMedium),
                          const SizedBox(height: AppTheme.spacingMd),
                          const Divider(color: AppTheme.border),
                          _detailRow(Icons.location_on_outlined,
                              'Pickup location', v.pickupLocation),
                          _detailRow(
                              Icons.person_outline, 'Owner', v.ownerName),
                          const Divider(color: AppTheme.border),
                          const SizedBox(height: AppTheme.spacingMd),
                          const Text('Availability',
                              style: AppTheme.sectionHeading),
                          const SizedBox(height: 2),
                          const Text('Tap a start date, then an end date',
                              style: AppTheme.bodyMedium),
                          const SizedBox(height: AppTheme.spacingSm),
                          AvailabilityCalendar(
                            unavailable: v.unavailableDates,
                            start: _start,
                            end: _end,
                            onDayTap: _onDayTap,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _bottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _bottomBar() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Rs. ${v.dailyPrice}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700)),
              const Text('per day', style: AppTheme.labelMedium),
            ],
          ),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: PrimaryButton(
              text: 'Request Booking',
              onPressed: _requestBooking,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows an asset or network image with a graceful fallback.
class _VehicleImage extends StatelessWidget {
  final String path;

  const _VehicleImage({required this.path});

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      color: AppTheme.surface,
      alignment: Alignment.center,
      child: const Icon(Icons.directions_car,
          size: 64, color: AppTheme.textSecondary),
    );
    final isNetwork = path.startsWith('http');
    return isNetwork
        ? Image.network(path,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (_, __, ___) => fallback)
        : Image.asset(path,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (_, __, ___) => fallback);
  }
}