import 'package:flutter/material.dart';

/// A reusable multi-step form page with progress indicator.
///
/// Use this for forms that need multiple steps with a progress bar.
/// Each step is a widget that will be displayed one at a time.
class StepFormPage extends StatefulWidget {
  final String title;
  final List<FormStep> steps;
  final VoidCallback? onComplete;
  final VoidCallback? onCancel;
  final String completeButtonText;
  final String? subtitle;

  const StepFormPage({
    super.key,
    required this.title,
    required this.steps,
    this.onComplete,
    this.onCancel,
    this.completeButtonText = 'Complete',
    this.subtitle,
  });

  @override
  State<StepFormPage> createState() => _StepFormPageState();
}

class _StepFormPageState extends State<StepFormPage> {
  int _currentStep = 0;
  final PageController _pageController = PageController();

  bool get _isFirstStep => _currentStep == 0;
  bool get _isLastStep => _currentStep == widget.steps.length - 1;
  double get _progress => ((_currentStep + 1) / widget.steps.length);

  void _nextStep() {
    final currentFormStep = widget.steps[_currentStep];

    // Validate current step if validator is provided
    if (currentFormStep.validator != null && !currentFormStep.validator!()) {
      return;
    }

    if (_isLastStep) {
      widget.onComplete?.call();
    } else {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_isFirstStep) {
      widget.onCancel?.call();
      Navigator.of(context).pop();
    } else {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentFormStep = widget.steps[_currentStep];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            widget.onCancel?.call();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Column(
        children: [
          // Progress indicator
          _buildProgressSection(theme),

          // Step content
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.steps.length,
              itemBuilder: (context, index) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: widget.steps[index].content,
                );
              },
            ),
          ),

          // Navigation buttons
          _buildNavigationButtons(theme, currentFormStep),
        ],
      ),
    );
  }

  Widget _buildProgressSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step indicator text
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Step ${_currentStep + 1} of ${widget.steps.length}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                widget.steps[_currentStep].title,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 6,
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(ThemeData theme, FormStep currentFormStep) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button
          Expanded(
            child: OutlinedButton(
              onPressed: _previousStep,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(_isFirstStep ? 'Cancel' : 'Back'),
            ),
          ),
          const SizedBox(width: 16),
          // Next/Complete button
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: currentFormStep.canProceed ?? true ? _nextStep : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(_isLastStep ? widget.completeButtonText : 'Continue'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Represents a single step in a multi-step form.
class FormStep {
  final String title;
  final Widget content;
  final bool? canProceed;
  final bool Function()? validator;

  const FormStep({
    required this.title,
    required this.content,
    this.canProceed,
    this.validator,
  });
}
