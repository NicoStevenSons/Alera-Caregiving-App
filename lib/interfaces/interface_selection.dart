import 'package:flutter/material.dart';

import '../features/caregiver/data/mock/mock_caregiver_repository.dart';
import '../features/caregiver/presentation/auth/caregiver_auth_gate.dart';

/// App entry: both interfaces require the household-first authentication flow.
class InterfaceSelection extends StatelessWidget {
  const InterfaceSelection({super.key});

  @override
  Widget build(BuildContext context) {
    return const CaregiverAuthGate(repository: MockCaregiverRepository());
  }
}
