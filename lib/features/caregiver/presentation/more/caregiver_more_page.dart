import 'package:flutter/material.dart';

import '../../../../design_system/alera_spacing.dart';
import '../../data/api/caregiver_help_request_api_data_source.dart';
import '../help_requests/caregiver_help_request_history_page.dart';
import '../widgets/caregiver_page_app_bar.dart';

class CaregiverMorePage extends StatelessWidget {
  const CaregiverMorePage({
    super.key,
    required this.helpRequestDataSource,
    this.onSignOut,
  });

  final CaregiverHelpRequestDataSource? helpRequestDataSource;
  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    final source = helpRequestDataSource;
    final CaregiverHelpRequestNotesDataSource? notesSource =
        source is CaregiverHelpRequestNotesDataSource
        ? source as CaregiverHelpRequestNotesDataSource
        : null;

    return Scaffold(
      appBar: const CaregiverPageAppBar(title: 'More'),
      body: ListView(
        padding: const EdgeInsets.all(AleraSpacing.large),
        children: [
          Card(
            child: ListTile(
              key: const Key('more-help-request-history'),
              enabled: source != null && notesSource != null,
              leading: const Icon(Icons.support_agent_outlined),
              title: const Text('Help request history'),
              subtitle: const Text(
                'Review active and resolved requests and caregiver notes.',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: source == null || notesSource == null
                  ? null
                  : () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => CaregiverHelpRequestHistoryPage(
                            dataSource: source,
                            notesDataSource: notesSource,
                          ),
                        ),
                      );
                    },
            ),
          ),
          if (onSignOut != null) ...[
            const SizedBox(height: AleraSpacing.medium),
            Card(
              child: ListTile(
                key: const Key('caregiver-sign-out'),
                leading: const Icon(Icons.logout),
                title: const Text('Sign out'),
                onTap: onSignOut,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
