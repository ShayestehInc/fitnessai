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
      setState(() => _branding = result.branding);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Branding updated successfully'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } else {
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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Failed to remove logo'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Branding'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState(theme)
              : _buildContent(theme),
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
    return StaggeredListItem(
      index: 4,
      delay: const Duration(milliseconds: 30),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isSaving ? null : _saveBranding,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Save Branding'),
        ),
      ),
    );
  }
}
