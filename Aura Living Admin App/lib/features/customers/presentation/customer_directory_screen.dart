import 'dart:async';
import '../../../core/utils/input_sanitizer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/shimmer_loader.dart';
import '../domain/customer.dart';
import 'customers_controller.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/domain/admin_user.dart';

class CustomerDirectoryScreen extends ConsumerStatefulWidget {
  const CustomerDirectoryScreen({super.key});

  @override
  ConsumerState<CustomerDirectoryScreen> createState() => _CustomerDirectoryScreenState();
}

class _CustomerDirectoryScreenState extends ConsumerState<CustomerDirectoryScreen> {
  final _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersProvider);
    final user = ref.watch(authControllerProvider).user;
    final isStaff = user?.role == AdminRole.inventoryStaff;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Customer Directory'),
      ),
      body: Column(
        children: [
          // Search input
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, email or phone...',
                prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textMuted),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(customerSearchQueryProvider.notifier).state = '';
                        },
                      )
                    : null,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
              onChanged: (val) {
                _debounceTimer?.cancel();
                final sanitized = InputSanitizer.sanitizeSearchQuery(val);
                _debounceTimer = Timer(const Duration(milliseconds: 300), () {
                  if (mounted) {
                    ref.read(customerSearchQueryProvider.notifier).state = sanitized;
                  }
                });
              },
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // PII protection notice for staff role
          if (isStaff) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.surfaceSecondary,
              child: const Row(
                children: [
                  Icon(Icons.shield_outlined, size: 14, color: AppColors.textSecondary),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Privacy Protection: Customer PII redacted for Staff roles per Section 3.',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
          ],

          // Customers List
          Expanded(
            child: customersAsync.when(
              data: (customers) {
                if (customers.isEmpty) {
                  return const EmptyStateView(
                    title: 'No Customers Found',
                    subtitle: 'No customer accounts match your search query.',
                    icon: Icons.people_outline,
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: customers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final customer = customers[index];
                    return _CustomerCard(
                      customer: customer,
                      isStaff: isStaff,
                      onTap: () {
                        context.push('/settings/customers/detail/${customer.id}');
                      },
                    );
                  },
                );
              },
              loading: () => ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: 5,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, __) => const ShimmerCard(height: 80),
              ),
              error: (err, stack) => Center(
                child: Text('Error loading customers: $err'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  final Customer customer;
  final bool isStaff;
  final VoidCallback onTap;

  const _CustomerCard({
    required this.customer,
    required this.isStaff,
    required this.onTap,
  });

  String _redact(String val) {
    if (!isStaff) return val;
    if (val.contains('@')) {
      final parts = val.split('@');
      return '${parts[0].substring(0, 2)}***@${parts[1]}';
    }
    if (val.length > 6) {
      return '${val.substring(0, 3)}***${val.substring(val.length - 2)}';
    }
    return '***';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.primaryOlive.withOpacity(0.1),
              child: Text(
                customer.fullName.isNotEmpty ? customer.fullName[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryOlive,
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.fullName,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _redact(customer.email),
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${customer.totalOrdersCount} orders',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textMuted),
                      ),
                      const SizedBox(width: 6),
                      const Text('•', style: TextStyle(color: AppColors.textMuted)),
                      const SizedBox(width: 6),
                      Text(
                        'Total: ${AppFormatters.formatCurrency(customer.lifetimeSpend)}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primaryOlive),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
