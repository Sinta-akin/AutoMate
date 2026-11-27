import 'package:flutter/material.dart';
import 'package:automate/core/constants/app_constants.dart';
import 'package:automate/core/theme/app_theme.dart';
import 'package:automate/core/widgets/common_widgets.dart';
import 'package:automate/features/preferences/data/preferences_repository.dart';
import 'package:automate/features/vehicles/data/vehicle_data.dart';

/// Feature 1: budget + vehicle type/use questionnaire.
class VehicleQuestionnaireScreen extends StatefulWidget {
  const VehicleQuestionnaireScreen({super.key});

  @override
  State<VehicleQuestionnaireScreen> createState() =>
      _VehicleQuestionnaireScreenState();
}

class _VehicleQuestionnaireScreenState
    extends State<VehicleQuestionnaireScreen> {
  final _formKey = GlobalKey<FormState>();
  final _minController = TextEditingController();
  final _maxController = TextEditingController();

  String? _vehicleType;
  String? _primaryUse;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _typeError = false;

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  /// Prefill any previously saved answers.
  Future<void> _loadSaved() async {
    final saved = await PreferencesRepository.instance.load();
    if (!mounted) return;
    setState(() {
      if (saved.minBudget != null) _minController.text = '${saved.minBudget}';
      if (saved.maxBudget != null) _maxController.text = '${saved.maxBudget}';
      _vehicleType = saved.vehicleType;
      _primaryUse = saved.primaryUse;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  String? _validateMin(String? value) {
    if (value == null || value.trim().isEmpty) return AppConstants.requiredField;
    final n = int.tryParse(value.trim());
    if (n == null) return 'Enter a valid whole number';
    if (n < 0) return 'Budget cannot be negative';
    return null;
  }

  String? _validateMax(String? value) {
    if (value == null || value.trim().isEmpty) return AppConstants.requiredField;
    final n = int.tryParse(value.trim());
    if (n == null) return 'Enter a valid whole number';
    final min = int.tryParse(_minController.text.trim());
    if (min != null && n <= min) return 'Must be greater than minimum budget';
    return null;
  }

  Future<void> _save() async {
    final formOk = _formKey.currentState!.validate();
    setState(() => _typeError = _vehicleType == null);
    if (!formOk || _vehicleType == null) return;

    setState(() => _isSaving = true);
    final repo = PreferencesRepository.instance;
    final current = await repo.load();
    await repo.save(current.copyWith(
      minBudget: int.parse(_minController.text.trim()),
      maxBudget: int.parse(_maxController.text.trim()),
      vehicleType: _vehicleType,
      primaryUse: _primaryUse,
      questionnaireCompleted: true,
    ));
    if (!mounted) return;
    setState(() => _isSaving = false);
    _goNext();
  }

  void _goNext() {
    Navigator.pushReplacementNamed(context, AppConstants.categorySelection);
  }

  Widget _sectionTitle(String text, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text, style: AppTheme.sectionHeading),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle, style: AppTheme.bodyMedium),
          ],
        ],
      ),
    );
  }

  Widget _chips({
    required List<String> options,
    required String? selected,
    required ValueChanged<String?> onChanged,
  }) {
    return Wrap(
      spacing: AppTheme.spacingSm,
      runSpacing: AppTheme.spacingSm,
      children: options.map((o) {
        final isSelected = o == selected;
        return ChoiceChip(
          label: Text(o),
          selected: isSelected,
          showCheckmark: false,
          onSelected: (_) => onChanged(isSelected ? null : o),
          selectedColor: AppTheme.primaryBlue,
          backgroundColor: AppTheme.surface,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
          side: BorderSide(
            color: isSelected ? AppTheme.primaryBlue : AppTheme.border,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppHeader(
        title: 'Your Preferences',
        showBack: Navigator.of(context).canPop(),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tell us what you need',
                    style: AppTheme.headline2),
                const SizedBox(height: AppTheme.spacingSm),
                const Text(
                  'Answer a few quick questions and we will suggest '
                      'vehicles that fit you. You can skip this anytime.',
                  style: AppTheme.bodyMedium,
                ),
                const SizedBox(height: AppTheme.spacingLg),
                _sectionTitle('Daily budget (Rs.)',
                    subtitle: 'Minimum and maximum you want to pay per day'),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: 'Minimum',
                        hint: 'e.g. 2000',
                        controller: _minController,
                        keyboardType: TextInputType.number,
                        prefixIcon: Icons.payments_outlined,
                        validator: _validateMin,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingMd),
                    Expanded(
                      child: AppTextField(
                        label: 'Maximum',
                        hint: 'e.g. 8000',
                        controller: _maxController,
                        keyboardType: TextInputType.number,
                        prefixIcon: Icons.payments,
                        validator: _validateMax,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingLg),
                _sectionTitle('Preferred vehicle type'),
                _chips(
                  options: VehicleData.vehicleTypes,
                  selected: _vehicleType,
                  onChanged: (v) => setState(() {
                    _vehicleType = v;
                    _typeError = false;
                  }),
                ),
                if (_typeError)
                  const Padding(
                    padding: EdgeInsets.only(top: AppTheme.spacingSm),
                    child: Text(
                      'Please choose a vehicle type',
                      style: TextStyle(
                          color: AppTheme.errorRed, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: AppTheme.spacingLg),
                _sectionTitle('What will you use it for?',
                    subtitle: 'Optional'),
                _chips(
                  options: VehicleData.primaryUses,
                  selected: _primaryUse,
                  onChanged: (v) => setState(() => _primaryUse = v),
                ),
                const SizedBox(height: AppTheme.spacingXl),
                PrimaryButton(
                  text: 'Save & Continue',
                  trailingArrow: true,
                  isLoading: _isSaving,
                  onPressed: _save,
                ),
                const SizedBox(height: AppTheme.spacingSm),
                Center(child: SkipLink(onTap: _goNext)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
