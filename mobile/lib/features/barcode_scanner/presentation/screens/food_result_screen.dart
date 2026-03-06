import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/achievement_toast_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../community/data/models/achievement_model.dart';
import '../../data/models/food_lookup_model.dart';
import '../providers/barcode_provider.dart';
import '../widgets/macro_info_row.dart';
import 'barcode_scan_screen.dart';

/// Displays the food product returned by a barcode lookup.
///
/// Shows macro breakdown, allows serving adjustment, and provides an
/// "Add to Log" action that persists the entry via the confirm-and-save
/// endpoint.
class FoodResultScreen extends ConsumerStatefulWidget {
  final String barcode;

  const FoodResultScreen({super.key, required this.barcode});

  @override
  ConsumerState<FoodResultScreen> createState() => _FoodResultScreenState();
}

class _FoodResultScreenState extends ConsumerState<FoodResultScreen> {
  double _servings = 1.0;
  bool _isSaving = false;

  void _incrementServings() {
    setState(() => _servings = (_servings + 0.5).clamp(0.5, 20.0));
  }

  void _decrementServings() {
    setState(() => _servings = (_servings - 0.5).clamp(0.5, 20.0));
  }

  Future<void> _addToLog(FoodLookupModel food) async {
    setState(() => _isSaving = true);

    final repository = ref.read(barcodeRepositoryProvider);
    final result = await repository.confirmAndSaveFood(
      food: food,
      servings: _servings,
    );

    if (!mounted) return;

    setState(() => _isSaving = false);

    if (result['success'] == true) {
      // Show achievement celebrations for any newly earned badges.
      final responseData = result['data'];
      if (responseData is Map) {
        final rawAchievements =
            responseData['new_achievements'] as List<dynamic>?;
        if (rawAchievements != null && rawAchievements.isNotEmpty) {
          try {
            final achievements = rawAchievements
                .whereType<Map<String, dynamic>>()
                .map((json) => NewAchievementModel.fromJson(json))
                .toList();
            if (achievements.isNotEmpty) {
              AchievementToastService.instance.showAchievements(achievements);
            }
          } catch (_) {
            // Malformed data — skip.
          }
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Food added to your log'),
          backgroundColor: AppTheme.primary,
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error']?.toString() ?? 'Failed to save'),
          backgroundColor: AppTheme.destructive,
        ),
      );
    }
  }

  void _scanAgain() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => const BarcodeScanScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncFood = ref.watch(barcodeLookupProvider(widget.barcode));

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: const Text('Scan Result'),
        centerTitle: true,
      ),
      body: asyncFood.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
        error: (error, _) => _ErrorBody(
          message: error.toString(),
          onScanAgain: _scanAgain,
        ),
        data: (food) {
          if (!food.found) {
            return _NotFoundBody(
              barcode: widget.barcode,
              onScanAgain: _scanAgain,
            );
          }
          return _FoundBody(
            food: food,
            servings: _servings,
            isSaving: _isSaving,
            onIncrement: _incrementServings,
            onDecrement: _decrementServings,
            onAddToLog: () => _addToLog(food),
            onScanAgain: _scanAgain,
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets (kept under 150 lines each)
// ---------------------------------------------------------------------------

class _FoundBody extends StatelessWidget {
  final FoodLookupModel food;
  final double servings;
  final bool isSaving;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onAddToLog;
  final VoidCallback onScanAgain;

  const _FoundBody({
    required this.food,
    required this.servings,
    required this.isSaving,
    required this.onIncrement,
    required this.onDecrement,
    required this.onAddToLog,
    required this.onScanAgain,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product header
          _ProductHeader(food: food),
          const SizedBox(height: 24),

          // Serving selector
          _ServingSelector(
            servingSize: food.servingSize,
            servings: servings,
            onIncrement: onIncrement,
            onDecrement: onDecrement,
          ),
          const SizedBox(height: 24),

          // Calorie highlight
          _CalorieCard(calories: food.calories * servings),
          const SizedBox(height: 20),

          // Macro breakdown
          const Text(
            'Macros',
            style: TextStyle(
              color: AppTheme.foreground,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          MacroInfoRow(
            label: 'Protein',
            value: food.protein * servings,
            color: const Color(0xFF60A5FA),
            maxValue: 100,
          ),
          MacroInfoRow(
            label: 'Carbs',
            value: food.carbs * servings,
            color: const Color(0xFF34D399),
            maxValue: 200,
          ),
          MacroInfoRow(
            label: 'Fat',
            value: food.fat * servings,
            color: const Color(0xFFFBBF24),
            maxValue: 100,
          ),
          MacroInfoRow(
            label: 'Fiber',
            value: food.fiber * servings,
            color: const Color(0xFFA78BFA),
            maxValue: 50,
          ),
          MacroInfoRow(
            label: 'Sugar',
            value: food.sugar * servings,
            color: const Color(0xFFF472B6),
            maxValue: 80,
          ),
          const SizedBox(height: 32),

          // Add to log button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: isSaving ? null : onAddToLog,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: AppTheme.primaryForeground,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                disabledBackgroundColor: AppTheme.primary.withOpacity(0.5),
              ),
              child: isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Add to Log',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),

          // Scan again (secondary)
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: onScanAgain,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.foreground,
                side: const BorderSide(color: AppTheme.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Scan Another'),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _ProductHeader extends StatelessWidget {
  final FoodLookupModel food;

  const _ProductHeader({required this.food});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product image
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: food.imageUrl.isNotEmpty
              ? Image.network(
                  food.imageUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const _PlaceholderImage(),
                )
              : const _PlaceholderImage(),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                food.productName,
                style: const TextStyle(
                  color: AppTheme.foreground,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (food.brand.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  food.brand,
                  style: const TextStyle(
                    color: AppTheme.zinc400,
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PlaceholderImage extends StatelessWidget {
  const _PlaceholderImage();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: AppTheme.zinc800,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.fastfood_outlined,
        color: AppTheme.zinc500,
        size: 36,
      ),
    );
  }
}

class _ServingSelector extends StatelessWidget {
  final String servingSize;
  final double servings;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _ServingSelector({
    required this.servingSize,
    required this.servings,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Serving Size',
                  style: TextStyle(color: AppTheme.zinc400, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  servingSize,
                  style: const TextStyle(
                    color: AppTheme.foreground,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          _RoundButton(icon: Icons.remove, onPressed: onDecrement),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              servings % 1 == 0
                  ? servings.toInt().toString()
                  : servings.toStringAsFixed(1),
              style: const TextStyle(
                color: AppTheme.foreground,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _RoundButton(icon: Icons.add, onPressed: onIncrement),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _RoundButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.zinc800,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: AppTheme.foreground, size: 20),
        ),
      ),
    );
  }
}

class _CalorieCard extends StatelessWidget {
  final double calories;

  const _CalorieCard({required this.calories});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Text(
            calories.round().toString(),
            style: const TextStyle(
              color: AppTheme.primary,
              fontSize: 36,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Text(
            'Calories',
            style: TextStyle(color: AppTheme.zinc400, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _NotFoundBody extends StatelessWidget {
  final String barcode;
  final VoidCallback onScanAgain;

  const _NotFoundBody({required this.barcode, required this.onScanAgain});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 72,
              color: AppTheme.zinc500,
            ),
            const SizedBox(height: 20),
            const Text(
              'Product Not Found',
              style: TextStyle(
                color: AppTheme.foreground,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We could not find a product matching barcode\n$barcode',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.zinc400,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: onScanAgain,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: AppTheme.primaryForeground,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Scan Again',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.foreground,
                  side: const BorderSide(color: AppTheme.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  final String message;
  final VoidCallback onScanAgain;

  const _ErrorBody({required this.message, required this.onScanAgain});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 72,
              color: AppTheme.destructive,
            ),
            const SizedBox(height: 20),
            const Text(
              'Something Went Wrong',
              style: TextStyle(
                color: AppTheme.foreground,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.zinc400,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: onScanAgain,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: AppTheme.primaryForeground,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Try Again',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
