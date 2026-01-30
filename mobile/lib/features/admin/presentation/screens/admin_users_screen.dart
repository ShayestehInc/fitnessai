import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/repositories/admin_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Model for admin/trainer user
class AdminUser {
  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final String role;
  final bool isActive;
  final String createdAt;
  final int traineeCount;

  AdminUser({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.isActive,
    required this.createdAt,
    required this.traineeCount,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'],
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      role: json['role'] ?? 'TRAINER',
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] ?? '',
      traineeCount: json['trainee_count'] ?? 0,
    );
  }

  String get displayName {
    final name = '$firstName $lastName'.trim();
    return name.isEmpty ? email.split('@').first : name;
  }
}

/// Screen to list and manage Admin/Trainer users
class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  List<AdminUser> _users = [];
  bool _isLoading = true;
  String? _error;
  String _selectedRole = 'ALL';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final apiClient = ref.read(apiClientProvider);
    final adminRepo = AdminRepository(apiClient);

    final result = await adminRepo.getUsers(
      role: _selectedRole == 'ALL' ? null : _selectedRole,
      search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
    );

    if (!mounted) return;

    if (result['success'] == true) {
      final data = result['data'] as List;
      setState(() {
        _users = data.map((u) => AdminUser.fromJson(u)).toList();
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = result['error'];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'Create User',
            onPressed: () async {
              final result = await context.push('/admin/users/create');
              if (result == true) _loadUsers();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and filter bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              border: Border(
                bottom: BorderSide(color: theme.dividerColor),
              ),
            ),
            child: Column(
              children: [
                // Search field
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by name or email...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: theme.cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onSubmitted: (_) => _loadUsers(),
                ),
                const SizedBox(height: 12),
                // Role filter chips
                Row(
                  children: [
                    _buildFilterChip('ALL', 'All'),
                    const SizedBox(width: 8),
                    _buildFilterChip('ADMIN', 'Admins'),
                    const SizedBox(width: 8),
                    _buildFilterChip('TRAINER', 'Trainers'),
                  ],
                ),
              ],
            ),
          ),
          // Users list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, size: 48, color: Colors.red),
                              const SizedBox(height: 16),
                              Text(_error!, textAlign: TextAlign.center),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadUsers,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _users.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.people_outline, size: 64, color: theme.hintColor),
                                const SizedBox(height: 16),
                                Text(
                                  'No users found',
                                  style: TextStyle(color: theme.hintColor, fontSize: 16),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadUsers,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _users.length,
                              itemBuilder: (context, index) => _buildUserCard(_users[index]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final theme = Theme.of(context);
    final isSelected = _selectedRole == value;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedRole = value);
        _loadUsers();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(AdminUser user) {
    final theme = Theme.of(context);
    final isAdmin = user.role == 'ADMIN';
    final roleColor = isAdmin ? Colors.purple : Colors.blue;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: InkWell(
        onTap: () async {
          final result = await context.push('/admin/users/${user.id}/edit');
          if (result == true) _loadUsers();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: roleColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isAdmin ? Icons.admin_panel_settings : Icons.fitness_center,
                  color: roleColor,
                ),
              ),
              const SizedBox(width: 16),
              // User info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            user.displayName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: roleColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isAdmin ? 'Admin' : 'Trainer',
                            style: TextStyle(
                              color: roleColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                      ),
                    ),
                    if (!isAdmin && user.traineeCount > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${user.traineeCount} trainee${user.traineeCount == 1 ? '' : 's'}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Status indicator
              if (!user.isActive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Inactive',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: theme.hintColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
