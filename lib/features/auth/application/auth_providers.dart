import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/approval_repository.dart';
import '../data/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(Supabase.instance.client);
});

final approvalRepositoryProvider = Provider<ApprovalRepository>((ref) {
  return ApprovalRepository(Supabase.instance.client);
});
