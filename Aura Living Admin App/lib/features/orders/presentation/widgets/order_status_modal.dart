import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/order.dart';
import '../../domain/order_status.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../auth/presentation/auth_controller.dart';

class OrderStatusModal extends ConsumerStatefulWidget {
  final Order order;
  final VoidCallback onTransitionCompleted;

  const OrderStatusModal({
    super.key,
    required this.order,
    required this.onTransitionCompleted,
  });

  @override
  ConsumerState<OrderStatusModal> createState() => _OrderStatusModalState();
}

class _OrderStatusModalState extends ConsumerState<OrderStatusModal> {
  final _formKey = GlobalKey<FormState>();
  OrderStatus? _selectedTargetStatus;
  final _trackingController = TextEditingController();
  final _courierController = TextEditingController(text: 'DHL Express');
  final _noteController = TextEditingController();

  String _selectedCancellationReason = 'Customer Request';
  final List<String> _cancellationReasons = const [
    'Customer Request',
    'Stock Discrepancy',
    'Payment Failure',
    'Fraud Suspected',
    'Other Operational Reason',
  ];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Default to the first valid forward transition if available
    final available = widget.order.status.allowedNextStatuses;
    if (available.isNotEmpty) {
      _selectedTargetStatus = available.first;
    }
  }

  @override
  void dispose() {
    _trackingController.dispose();
    _courierController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submitTransition() async {
    if (_selectedTargetStatus == null) return;

    if (_selectedTargetStatus == OrderStatus.shipped) {
      if (_trackingController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tracking Reference number is mandatory when marking order as Shipped.'),
            backgroundColor: AppColors.danger,
          ),
        );
        return;
      }
    }

    if (_formKey.currentState != null && !_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = ref.read(authControllerProvider).user;
      final staffIdentifier = user != null ? '${user.name} (${user.role.label})' : 'Admin Staff';

      final repo = ref.read(orderRepositoryProvider);
      await repo.transitionOrderStatus(
        orderId: widget.order.id,
        newStatus: _selectedTargetStatus!,
        trackingNumber: _selectedTargetStatus == OrderStatus.shipped ? _trackingController.text.trim() : null,
        courierPartner: _selectedTargetStatus == OrderStatus.shipped ? _courierController.text.trim() : null,
        cancellationReason: _selectedTargetStatus == OrderStatus.cancelled ? _selectedCancellationReason : null,
        note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
        staffIdentifier: staffIdentifier,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onTransitionCompleted();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order #${widget.order.id} moved to ${_selectedTargetStatus!.label}.'),
            backgroundColor: AppColors.primaryOlive,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final allowedStatuses = widget.order.status.allowedNextStatuses;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Update Order #${widget.order.id}',
                          style: AppTypography.sectionHeader,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Current Status: ${widget.order.status.label}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (allowedStatuses.isEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      'Order is in terminal state (${widget.order.status.label}). No further status transitions allowed.',
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ),
                ] else ...[
                  const Text(
                    'Select Target Status',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Status choice pills
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: allowedStatuses.map((target) {
                      final isSelected = _selectedTargetStatus == target;
                      final isDestructive = target == OrderStatus.cancelled;

                      return ChoiceChip(
                        label: Text(target.label),
                        selected: isSelected,
                        selectedColor: isDestructive ? AppColors.danger : AppColors.primaryOlive,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : (isDestructive ? AppColors.danger : AppColors.textPrimary),
                        ),
                        backgroundColor: isDestructive
                            ? AppColors.dangerBg
                            : AppColors.surfaceSecondary,
                        side: BorderSide(
                          color: isDestructive ? AppColors.danger.withOpacity(0.4) : AppColors.border,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedTargetStatus = target);
                          }
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  // Special inputs for 'Shipped' status: tracking and courier
                  if (_selectedTargetStatus == OrderStatus.shipped) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSecondary,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.local_shipping_outlined, size: 16, color: AppColors.primaryOlive),
                              SizedBox(width: 6),
                              Text(
                                'Shipping Information (Mandatory)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryOlive,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Quick Select Courier Partner:',
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: BangladeshCourierPartners.all.take(4).map((courier) {
                              final isSelected = _courierController.text == courier;
                              return ChoiceChip(
                                label: Text(courier, style: const TextStyle(fontSize: 11)),
                                selected: isSelected,
                                selectedColor: AppColors.primaryOlive,
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.white : AppColors.textPrimary,
                                ),
                                onSelected: (sel) {
                                  if (sel) {
                                    setState(() {
                                      _courierController.text = courier;
                                      if (courier.contains('Steadfast')) {
                                        _trackingController.text = 'SF-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
                                      } else if (courier.contains('Pathao')) {
                                        _trackingController.text = 'PTH-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
                                      }
                                    });
                                  }
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 10),
                          AppTextField(
                            label: 'Courier Partner',
                            controller: _courierController,
                            hintText: 'e.g., Steadfast Courier, Pathao Courier',
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Courier partner is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),
                          AppTextField(
                            label: 'Tracking / Consignment ID *',
                            controller: _trackingController,
                            hintText: 'e.g., SF-8924102 or PTH-401924',
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Tracking number is required to mark Handed to Courier';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Special inputs for 'Cancelled' status: cancellation reason
                  if (_selectedTargetStatus == OrderStatus.cancelled) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.dangerBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.danger.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.danger),
                              SizedBox(width: 6),
                              Text(
                                'Cancellation Reason (Mandatory)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.danger,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Cancelling this order will automatically trigger inventory restock and refund settlement.',
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            value: _selectedCancellationReason,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppColors.surface,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: AppColors.border),
                              ),
                            ),
                            items: _cancellationReasons.map((reason) {
                              return DropdownMenuItem(
                                value: reason,
                                child: Text(reason, style: const TextStyle(fontSize: 13)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedCancellationReason = val);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Audit note input
                  AppTextField(
                    label: 'Audit Log Note (Optional)',
                    controller: _noteController,
                    hintText: 'e.g., Packed in Bay 3, dispatched per customer request',
                    maxLines: 2,
                  ),
                  const SizedBox(height: 20),

                  AppButton(
                    text: _selectedTargetStatus == OrderStatus.cancelled
                        ? 'Confirm Cancellation & Restock'
                        : 'Confirm Transition to ${_selectedTargetStatus?.label ?? ""}',
                    variant: _selectedTargetStatus == OrderStatus.cancelled
                        ? ButtonVariant.destructive
                        : ButtonVariant.primary,
                    isLoading: _isLoading,
                    onPressed: _submitTransition,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
