import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../shared/widgets/animated_widgets.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/branding_model.dart';
import '../../data/repositories/branding_repository.dart';
import '../widgets/branding_color_section.dart';
import '../widgets/branding_logo_section.dart';
import '../widgets/branding_preview_card.dart';

final _brandingRepositoryProvider = Provider<BrandingRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return BrandingRepository(apiClient);
});

class BrandingScreen extends ConsumerStatefulWidget {
  const BrandingScreen({super.key});

  @override
  ConsumerState<BrandingScreen> createState() => _BrandingScreenState();
}

class _BrandingScreenState extends ConsumerState<BrandingScreen> {
  final _appNameController = TextEditingController();
  BrandingModel? _branding;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingLogo = false;
  String? _error;

  Color _primaryColor = BrandingModel.defaultBranding.primaryColorValue;
  Color _secondaryColor = BrandingModel.defaultBranding.secondaryColorValue;

  /// Track the original values to detect unsaved changes.
  String _originalAppName = '';
  Color _originalPrimaryColor = BrandingModel.defaultBranding.primaryColorValue;
  Color _originalSecondaryColor = BrandingModel.defaultBranding.secondaryColorValue;

  /// Whether the user has made changes that differ from the saved state.
  bool get _hasUnsavedChanges {
    return _appNameController.text.trim() != _originalAppName ||
        _primaryColor != _originalPrimaryColor ||
        _secondaryColor != _originalSecondaryColor;
  }

  @override
  void initState() {
    super.initState();
    _fetchBranding();
  }

  @override
  void dispose() {
    _appNameController.dispose();
    super.dispose();
  }

  Future<void> _fetchBranding() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await ref.read(_brandingRepositoryProvider).getTrainerBranding();

    if (!mounted) return;

    if (result.success && result.branding != null) {
      final branding = result.branding!;
      setState(() {
        _branding = branding;
        _appNameController.text = branding.appName;
        _primaryColor = branding.primaryColorValue;
        _secondaryColor = branding.secondaryColorValue;
        // Store originals so we can detect changes
        _originalAppName = branding.appName;
        _originalPrimaryColor = branding.primaryColorValue;
        _originalSecondaryColor = branding.secondaryColorValue;
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = result.error;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveBranding() async {
    setState(() => _isSaving = true);

    final updatedBranding = BrandingModel(
      appName: _appNameController.text.trim(),
      primaryColor: BrandingModel.colorToHex(_primaryColor),
      secondaryColor: BrandingModel.colorToHex(_secondaryColor),
      logoUrl: _branding?.logoUrl,
    );

    final result = await ref.read(_brandingRepositoryProvider).updateTrainerBranding(updatedBranding);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (result.success && result.branding != null) {
      final saved = result.branding!;
      setState(() {
        _branding = saved;
        // Update originals so the save button disables again
        _originalAppName = saved.appName;
        _originalPrimaryColor = saved.primaryColorValue;
        _originalSecondaryColor = saved.secondaryColorValue;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Branding updated successfully'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Failed to save branding'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _pickAndUploadLogo() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );

    if (image == null) return;

    setState(() => _isUploadingLogo = true);

    final result = await ref.read(_brandingRepositoryProvider).uploadLogo(image.path);

    if (!mounted) return;
    setState(() => _isUploadingLogo = false);

    if (result.success && result.branding != null) {
      setState(() => _branding = result.branding);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logo uploaded successfully'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Failed to upload logo'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _removeLogo() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Logo'),
        content: const Text('Are you sure you want to remove your logo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isUploadingLogo = true);

    final result = await ref.read(_brandingRepositoryProvider).removeLogo();

    if (!mounted) return;
    setState(() => _isUploadingLogo = false);

    if (result.success && result.branding != null) {
      setState(() => _branding = result.branding);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logo removed'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Failed to remove logo'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _resetToDefaults() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Branding'),
        content: const Text(
          'This will reset your app name, colors, and remove your logo. '
          'Your trainees will see the default FitnessAI branding.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _appNameController.text = '';
      _primaryColor = BrandingModel.defaultBranding.primaryColorValue;
      _secondaryColor = BrandingModel.defaultBranding.secondaryColorValue;
    });

    // Save the defaults immediately
    await _saveBranding();

    // Remove logo if one exists
    if (_branding?.logoUrl != null && _branding!.logoUrl!.isNotEmpty) {
      await ref.read(_brandingRepositoryProvider).removeLogo();
      if (!mounted) return;
      setState(() {
        _branding = _branding?.copyWith(clearLogoUrl: true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldDiscard = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Unsaved Changes'),
            content: const Text(
              'You have unsaved branding changes. Discard them?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Keep Editing'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const Text('Discard'),
              ),
            ],
          ),
        );
        if (shouldDiscard == true && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Branding'),
          elevation: 0,
          actions: [
            if (!_isLoading && _error == null)
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'reset') {
                    _resetToDefaults();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem<String>(
                    value: 'reset',
                    child: Row(
                      children: [
                        Icon(
                          Icons.restart_alt,
                          size: 20,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Reset to Defaults',
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildErrorState(theme)
                : _buildContent(theme),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          Text(
            _error ?? 'Failed to load branding',
            style: TextStyle(color: theme.textTheme.bodySmall?.color),
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _fetchBranding, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        BrandingPreviewCard(
          appName: _appNameController.text.trim(),
          primaryColor: _primaryColor,
          secondaryColor: _secondaryColor,
          logoUrl: _branding?.logoUrl,
        ),
        const SizedBox(height: 24),
        _buildSectionHeader(theme, 'APP NAME'),
        const SizedBox(height: 8),
        _buildAppNameField(),
        const SizedBox(height: 24),
        _buildSectionHeader(theme, 'LOGO'),
        const SizedBox(height: 8),
        BrandingLogoSection(
          logoUrl: _branding?.logoUrl,
          isUploading: _isUploadingLogo,
          onPickLogo: _pickAndUploadLogo,
          onRemoveLogo: _removeLogo,
        ),
        const SizedBox(height: 24),
        _buildSectionHeader(theme, 'COLORS'),
        const SizedBox(height: 8),
        BrandingColorSection(
          primaryColor: _primaryColor,
          secondaryColor: _secondaryColor,
          onPrimaryChanged: (c) => setState(() => _primaryColor = c),
          onSecondaryChanged: (c) => setState(() => _secondaryColor = c),
        ),
        const SizedBox(height: 32),
        _buildSaveButton(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Text(
      title,
      style: TextStyle(
        color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildAppNameField() {
    return StaggeredListItem(
      index: 1,
      delay: const Duration(milliseconds: 30),
      child: TextField(
        controller: _appNameController,
        maxLength: 50,
        decoration: InputDecoration(
          hintText: 'FitnessAI',
          helperText: 'Your trainees will see this name instead of "FitnessAI"',
          counterText: '${_appNameController.text.length}/50',
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildSaveButton() {
    final canSave = _hasUnsavedChanges && !_isSaving;

    return StaggeredListItem(
      index: 4,
      delay: const Duration(milliseconds: 30),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: Semantics(
              button: true,
              enabled: canSave,
              label: 'Save branding changes',
              child: ElevatedButton(
                onPressed: canSave ? _saveBranding : null,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save Branding'),
              ),
            ),
          ),
          if (!_hasUnsavedChanges && !_isSaving)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'No unsaved changes',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
