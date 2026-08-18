import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/admin_user.dart';
import '../viewmodel/admin_users_viewmodel.dart';

/// Admin-only user management: view every account, change roles, activate
/// or deactivate, and delete.
class AdminUsersView extends StatelessWidget {
  const AdminUsersView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AdminUsersViewModel>();
    final palette = context.palette;

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Users')),
      body: RefreshIndicator(
        color: palette.teal,
        onRefresh: viewModel.load,
        child: switch (viewModel.status) {
          AdminUsersStatus.loading => const Center(child: CircularProgressIndicator()),
          AdminUsersStatus.error => _UsersError(
            message: viewModel.errorMessage ?? 'Failed to load users',
            onRetry: viewModel.load,
          ),
          AdminUsersStatus.loaded => _UsersList(viewModel: viewModel),
        },
      ),
    );
  }
}

class _UsersList extends StatelessWidget {
  const _UsersList({required this.viewModel});

  final AdminUsersViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    if (viewModel.users.isEmpty) {
      return Center(
        child: Text('No users found', style: TextStyle(color: palette.hint)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: viewModel.users.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final user = viewModel.users[index];
        return _UserCard(
          user: user,
          isSelf: user.id == viewModel.currentUserId,
          isBusy: viewModel.busyUserId == user.id,
          onChangeRole: (role) async {
            final ok = await viewModel.changeRole(user, role);
            if (!ok && context.mounted) _showActionError(context, viewModel);
          },
          onToggleActive: () async {
            final ok = await viewModel.toggleActive(user);
            if (!ok && context.mounted) _showActionError(context, viewModel);
          },
          onDelete: () async {
            final confirmed = await _confirmDelete(context, user);
            if (confirmed != true) return;
            final ok = await viewModel.deleteUser(user);
            if (!ok && context.mounted) _showActionError(context, viewModel);
          },
        );
      },
    );
  }

  void _showActionError(BuildContext context, AdminUsersViewModel viewModel) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(viewModel.actionError ?? 'Action failed')),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context, AdminUser user) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete user?'),
        content: Text(
          'This permanently deletes ${user.fullName} (${user.email}) and all their analyses.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('Delete', style: TextStyle(color: dialogContext.palette.error)),
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.user,
    required this.isSelf,
    required this.isBusy,
    required this.onChangeRole,
    required this.onToggleActive,
    required this.onDelete,
  });

  final AdminUser user;
  final bool isSelf;
  final bool isBusy;
  final ValueChanged<String> onChangeRole;
  final VoidCallback onToggleActive;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: user.isAdmin ? palette.teal : palette.cyan,
                child: Icon(
                  user.isAdmin ? Icons.shield_outlined : Icons.person_outline,
                  color: palette.onAccent,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user.fullName,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: palette.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (isSelf) ...[
                          const SizedBox(width: 6),
                          Text(
                            '(you)',
                            style: TextStyle(color: palette.hint, fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      user.email,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: palette.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (isBusy)
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Chip(
                label: user.isActive ? 'Active' : 'Inactive',
                color: user.isActive ? palette.teal : palette.error,
              ),
              _Chip(
                label: '${user.examCount} analyses',
                color: palette.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: user.role,
                  isDense: true,
                  decoration: const InputDecoration(isDense: true, labelText: 'Role'),
                  items: const [
                    DropdownMenuItem(value: 'clinician', child: Text('Clinician')),
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  ],
                  onChanged: isBusy || isSelf
                      ? null
                      : (role) {
                          if (role != null && role != user.role) onChangeRole(role);
                        },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: user.isActive ? 'Deactivate' : 'Activate',
                onPressed: isBusy || isSelf ? null : onToggleActive,
                icon: Icon(
                  user.isActive ? Icons.block_outlined : Icons.check_circle_outline,
                  color: user.isActive ? palette.error : palette.teal,
                ),
              ),
              IconButton(
                tooltip: 'Delete',
                onPressed: isBusy || isSelf ? null : onDelete,
                icon: Icon(Icons.delete_outline, color: palette.error),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _UsersError extends StatelessWidget {
  const _UsersError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, size: 44, color: palette.hint),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: palette.textSecondary, fontSize: 13),
            ),
            TextButton.icon(
              onPressed: onRetry,
              icon: Icon(Icons.refresh, color: palette.teal, size: 18),
              label: Text('Retry', style: TextStyle(color: palette.teal)),
            ),
          ],
        ),
      ),
    );
  }
}
