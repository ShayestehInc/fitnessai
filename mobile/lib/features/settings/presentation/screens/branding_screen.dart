import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../shared/widgets/animated_widgets.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/branding_model.dart';
import '../../data/repositories/branding_repository.dart';

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

  Color _primaryColor = const Color(0xFF6366F1);
  Color _secondaryColor = const Color(0xFF818CF8);

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

    if (result['success'] == true) {
      final branding = result['branding'] as BrandingModel;
      setState(() {
        _branding = branding;
        _appNameController.text = branding.appName;
        _primaryColor = branding.primaryColorValue;
        _secondaryColor = branding.secondaryColorValue;
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = result['error'] as String?;
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

    if (result['success'] == true) {
      final saved = result['branding'] as BrandingModel;
      setState(() => _branding = saved);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Branding updated successfully'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] as String? ?? 'Failed to save branding'),
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

    if (result['success'] == true) {
      final updated = result['branding'] as BrandingModel;
      setState(() => _branding = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logo uploaded successfully'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] as String? ?? 'Failed to upload logo'),
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

    if (result['success'] == true) {
      final updated = result['branding'] as BrandingModel;
      setState(() => _branding = updated);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] as String? ?? 'Failed to remove logo'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _showColorPicker({required bool isPrimary}) {
    final currentColor = isPrimary ? _primaryColor : _secondaryColor;

    // Pre-defined color options based on existing AppColorScheme palette
    final presetColors = [
      const Color(0xFF6366F1), // Indigo
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFF3B82F6), // Blue
      const Color(0xFF10B981), // Emerald
      const Color(0xFFF43F5E), // Rose
      const Color(0xFFF59E0B), // Amber
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFFEC4899), // Pink
      const Color(0xFFEF4444), // Red
      const Color(0xFF14B8A6), // Teal
      const Color(0xFF8B5E3C), // Brown
      const Color(0xFF64748B), // Slate
    ];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isPrimary ? 'Primary Color' : 'Secondary Color'),
          content: SizedBox(
            width: 280,
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: presetColors.map((color) {
                final isSelected = color.value == currentColor.value;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isPrimary) {
                        _primaryColor = color;
                      } else {
                        _secondaryColor = color;
                      }
                    });
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.5),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 20)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
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
          Icon(
            Icons.error_outline,
            size: 48,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            _error ?? 'Failed to load branding',
            style: TextStyle(color: theme.textTheme.bodySmall?.color),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchBranding,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Preview Card
        _buildPreviewCard(theme),
        const SizedBox(height: 24),

        // App Name
        _buildSectionHeader(theme, 'APP NAME'),
        const SizedBox(height: 8),
        _buildAppNameField(theme),
        const SizedBox(height: 24),

        // Logo
        _buildSectionHeader(theme, 'LOGO'),
        const SizedBox(height: 8),
        _buildLogoSection(theme),
        const SizedBox(height: 24),

        // Colors
        _buildSectionHeader(theme, 'COLORS'),
        const SizedBox(height: 8),
        _buildColorPickers(theme),
        const SizedBox(height: 32),

        // Save Button
        _buildSaveButton(theme),
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

  Widget _buildPreviewCard(ThemeData theme) {
    final appName = _appNameController.text.trim().isNotEmpty
        ? _appNameController.text.trim()
        : 'FitnessAI';
    final logoUrl = _branding?.logoUrl;

    return StaggeredListItem(
      index: 0,
      delay: const Duration(milliseconds: 30),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _primaryColor.withValues(alpha: 0.15),
              _secondaryColor.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
        ),
        child: Column(
          children: [
            Text(
              'Preview',
              style: TextStyle(
                color: theme.textTheme.bodySmall?.color,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 16),
            // Mini logo
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_primaryColor, _primaryColor.withValues(alpha: 0.8)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: logoUrl != null && logoUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        logoUrl,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.fitness_center,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.fitness_center,
                      color: Colors.white,
                      size: 28,
                    ),
            ),
            const SizedBox(height: 12),
            Text(
              appName,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _primaryColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            // Mini sample buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: _primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Start Workout',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: _secondaryColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'View Plan',
                    style: TextStyle(color: _secondaryColor, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppNameField(ThemeData theme) {
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

  Widget _buildLogoSection(ThemeData theme) {
    final logoUrl = _branding?.logoUrl;
    final hasLogo = logoUrl != null && logoUrl.isNotEmpty;

    return StaggeredListItem(
      index: 2,
      delay: const Duration(milliseconds: 30),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
        ),
        child: Column(
          children: [
            if (_isUploadingLogo)
              const Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              )
            else if (hasLogo) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  logoUrl,
                  width: 96,
                  height: 96,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 96,
                    height: 96,
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    child: Icon(
                      Icons.broken_image,
                      color: theme.colorScheme.primary,
                      size: 32,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: _pickAndUploadLogo,
                    icon: const Icon(Icons.swap_horiz, size: 18),
                    label: const Text('Replace'),
                  ),
                  TextButton.icon(
                    onPressed: _removeLogo,
                    icon: Icon(Icons.delete_outline, size: 18, color: theme.colorScheme.error),
                    label: Text('Remove', style: TextStyle(color: theme.colorScheme.error)),
                  ),
                ],
              ),
            ] else ...[
              Icon(
                Icons.add_photo_alternate_outlined,
                size: 48,
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 8),
              Text(
                'Upload your logo',
                style: TextStyle(
                  color: theme.textTheme.bodySmall?.color,
                  fontSize: 14,
                ),
              ),
              Text(
                'JPEG, PNG, or WebP. Max 2MB. 128-1024px.',
                style: TextStyle(
                  color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _pickAndUploadLogo,
                icon: const Icon(Icons.upload, size: 18),
                label: const Text('Choose Image'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildColorPickers(ThemeData theme) {
    return StaggeredListItem(
      index: 3,
      delay: const Duration(milliseconds: 30),
      child: Column(
        children: [
          _buildColorRow(
            theme: theme,
            label: 'Primary Color',
            subtitle: 'Buttons, headers, accent elements',
            color: _primaryColor,
            onTap: () => _showColorPicker(isPrimary: true),
          ),
          const SizedBox(height: 8),
          _buildColorRow(
            theme: theme,
            label: 'Secondary Color',
            subtitle: 'Highlights, badges, secondary actions',
            color: _secondaryColor,
            onTap: () => _showColorPicker(isPrimary: false),
          ),
        ],
      ),
    );
  }

  Widget _buildColorRow({
    required ThemeData theme,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return AnimatedPress(
      onTap: onTap,
      scaleDown: 0.98,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: theme.dividerColor,
                  width: 1,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: theme.textTheme.bodyLarge?.color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: theme.textTheme.bodySmall?.color,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              BrandingModel.colorToHex(color),
              style: TextStyle(
                color: theme.textTheme.bodySmall?.color,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right,
              color: theme.textTheme.bodySmall?.color,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton(ThemeData theme) {
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
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Save Branding'),
        ),
      ),
    );
  }
}
