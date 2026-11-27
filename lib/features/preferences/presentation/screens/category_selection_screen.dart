import 'package:flutter/material.dart';
import 'package:automate/core/constants/app_constants.dart';
import 'package:automate/core/theme/app_theme.dart';
import 'package:automate/core/widgets/common_widgets.dart';
import 'package:automate/features/preferences/data/preferences_repository.dart';
import 'package:automate/features/vehicles/data/vehicle_data.dart';
import 'package:automate/features/vehicles/domain/vehicle.dart';

/// Feature 2: multi-select preferred vehicle categories.
class CategorySelectionScreen extends StatefulWidget {
  const CategorySelectionScreen({super.key});

  @override
  State<CategorySelectionScreen> createState() =>
      _CategorySelectionScreenState();
}

class _CategorySelectionScreenState extends State<CategorySelectionScreen> {
  final Set<String> _selected = {};
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  /// Restore previously saved selections.
  Future<void> _loadSaved() async {
    final saved = await PreferencesRepository.instance.load();
    if (!mounted) return;
    setState(() {
      _selected
        ..clear()
        ..addAll(saved.categoryIds);
      _isLoading = false;
    });
  }

  void _toggle(String id) {
    setState(() {
      if (!_selected.remove(id)) _selected.add(id);
    });
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final repo = PreferencesRepository.instance;
    final current = await repo.load();
    await repo.save(current.copyWith(categoryIds: Set.of(_selected)));
    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preferences saved')),
    );
    _finish();
  }

  void _finish() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppConstants.landing,
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = VehicleData.categories;
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppHeader(
        title: 'Vehicle Categories',
        showBack: Navigator.of(context).canPop(),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(
                AppTheme.spacingLg,
                AppTheme.spacingSm,
                AppTheme.spacingLg,
                AppTheme.spacingMd,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Pick every category you are interested in. Tap again '
                      'to remove it.',
                  style: AppTheme.bodyMedium,
                ),
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingLg),
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: AppTheme.spacingMd,
                  crossAxisSpacing: AppTheme.spacingMd,
                  childAspectRatio: 0.95,
                ),
                itemCount: categories.length,
                itemBuilder: (context, i) {
                  final c = categories[i];
                  return _CategoryCard(
                    category: c,
                    selected: _selected.contains(c.id),
                    onTap: () => _toggle(c.id),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PrimaryButton(
                    text: _selected.isEmpty
                        ? 'Select at least one'
                        : 'Save (${_selected.length} selected)',
                    isLoading: _isSaving,
                    onPressed: _selected.isEmpty ? null : _save,
                  ),
                  const SizedBox(height: AppTheme.spacingXs),
                  SkipLink(onTap: _finish),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final VehicleCategory category;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: category.name,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.primaryBlue.withValues(alpha: 0.15)
                : AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(
              color: selected ? AppTheme.primaryBlue : AppTheme.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: selected ? AppTheme.primaryBlue : AppTheme.border,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(category.icon, color: Colors.white),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  Text(category.name, style: AppTheme.sectionHeading),
                  const SizedBox(height: AppTheme.spacingXs),
                  Text(
                    category.description,
                    style: AppTheme.labelMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              Positioned(
                top: 0,
                right: 0,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: selected ? 1 : 0,
                  child: const Icon(
                    Icons.check_circle,
                    color: AppTheme.primaryBlue,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}