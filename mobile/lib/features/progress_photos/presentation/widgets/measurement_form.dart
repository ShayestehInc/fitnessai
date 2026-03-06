import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/l10n/l10n_extension.dart';

/// A form widget for entering body measurements (waist, chest, arms, hips,
/// thighs) in centimeters.
class MeasurementForm extends StatelessWidget {
  final TextEditingController waistController;
  final TextEditingController chestController;
  final TextEditingController armsController;
  final TextEditingController hipsController;
  final TextEditingController thighsController;

  const MeasurementForm({
    super.key,
    required this.waistController,
    required this.chestController,
    required this.armsController,
    required this.hipsController,
    required this.thighsController,
  });

  /// Collects all non-empty measurements into a map.
  Map<String, double> collectMeasurements() {
    final result = <String, double>{};

    void tryAdd(String key, TextEditingController controller) {
      final value = double.tryParse(controller.text.trim());
      if (value != null && value > 0) {
        result[key] = value;
      }
    }

    tryAdd('waist', waistController);
    tryAdd('chest', chestController);
    tryAdd('arms', armsController);
    tryAdd('hips', hipsController);
    tryAdd('thighs', thighsController);

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Body Measurements (cm)',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          'Optional. Track changes over time.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MeasurementField(
                controller: waistController,
                label: context.l10n.photosWaist,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MeasurementField(
                controller: chestController,
                label: context.l10n.photosChest,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MeasurementField(
                controller: armsController,
                label: context.l10n.photosArms,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MeasurementField(
                controller: hipsController,
                label: context.l10n.photosHips,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MeasurementField(
                controller: thighsController,
                label: context.l10n.photosThighs,
              ),
            ),
            const Expanded(child: SizedBox.shrink()),
          ],
        ),
      ],
    );
  }
}

class _MeasurementField extends StatelessWidget {
  final TextEditingController controller;
  final String label;

  const _MeasurementField({
    required this.controller,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      decoration: InputDecoration(
        labelText: label,
        suffixText: 'cm',
        filled: true,
        fillColor: theme.cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.dividerColor),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}
