import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/store_settings.dart';
import '../../../core/providers/repository_providers.dart';

final storeSettingsStreamProvider = StreamProvider<StoreSettings>((ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return repo.watchStoreSettings();
});

final staffMembersStreamProvider = StreamProvider<List<StaffMember>>((ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return repo.watchStaffMembers();
});
