import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../dashboard/domain/dashboard_metrics.dart';
import '../../../core/providers/repository_providers.dart';

final dashboardMetricsProvider = FutureProvider.autoDispose<DashboardMetrics>((ref) async {
  final repo = ref.watch(metricsRepositoryProvider);
  return repo.getMetrics();
});
