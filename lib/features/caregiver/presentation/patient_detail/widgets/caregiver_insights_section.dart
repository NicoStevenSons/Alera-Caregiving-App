import 'package:flutter/material.dart';

import '../../../../../../design_system/alera_colors.dart';
import '../../../../../design_system/alera_typography.dart';
import '../../../../../design_system/widgets/alera_card.dart';
import '../../../../data/api/caregiver_insight_api_data_source.dart';
import '../../../data/api/dto/caregiver_insight_dto.dart';

class CaregiverInsightsSection extends StatefulWidget {
  final String patientId;
  final CaregiverInsightDataSource? dataSource;

  const CaregiverInsightsSection({
    super.key,
    required this.patientId,
    this.dataSource,
  });

  @override
  State<CaregiverInsightsSection> createState() =>
      _CaregiverInsightsSectionState();
}

class _CaregiverInsightsSectionState extends State<CaregiverInsightsSection> {
  late final CaregiverInsightDataSource _dataSource;
  Future<CaregiverInsightResponseDto>? _request;

  @override
  void initState() {
    super.initState();
    _dataSource = widget.dataSource ?? CaregiverInsightApiDataSource();
    _load();
  }

  @override
  void didUpdateWidget(covariant CaregiverInsightsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.patientId != widget.patientId) _load();
  }

  void _load() {
    setState(() {
      _request = _dataSource.fetchInsights(widget.patientId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AleraCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome_outlined,
                color: AleraColors.primary,
                size: 21,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Caregiver insights',
                  style: AleraTypography.sectionTitle,
                ),
              ),
              const Text('Past 7 days', style: AleraTypography.micro),
            ],
          ),
          const SizedBox(height: 12),
          FutureBuilder<CaregiverInsightResponseDto>(
            future: _request,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              }

              if (snapshot.hasError) {
                final error = snapshot.error;
                final message = error is CaregiverInsightApiFailure
                    ? error.message
                    : 'Unable to load caregiver insights.';
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        message,
                        style: AleraTypography.micro.copyWith(
                          color: AleraColors.textPrimary,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _load,
                      child: const Text('Retry'),
                    ),
                  ],
                );
              }

              final response = snapshot.data;
              if (response == null) {
                return const Text(
                  'No insight data is available yet.',
                  style: AleraTypography.micro,
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    response.summary,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 10),
                  if (response.items.isEmpty)
                    const Text(
                      'No notable changes were found in this period.',
                      style: AleraTypography.micro,
                    )
                  else
                    for (int index = 0; index < response.items.length; index++)
                      _InsightItem(
                        item: response.items[index],
                        showDivider: index > 0,
                      ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        response.source == CaregiverInsightSource.aiRanked
                            ? Icons.auto_awesome
                            : Icons.rule_outlined,
                        size: 14,
                        color: AleraColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        response.source == CaregiverInsightSource.aiRanked
                            ? 'AI-ranked'
                            : 'Rule-based',
                        style: AleraTypography.micro,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    response.disclaimer,
                    style: AleraTypography.micro.copyWith(
                      color: AleraColors.textSecondary,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _InsightItem extends StatelessWidget {
  final CaregiverInsightItemDto item;
  final bool showDivider;

  const _InsightItem({required this.item, required this.showDivider});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (item.priority) {
      CaregiverInsightPriority.critical => (
        Icons.error_outline,
        const Color(0xFFB3261E),
      ),
      CaregiverInsightPriority.warning => (
        Icons.warning_amber_rounded,
        const Color(0xFF9A6700),
      ),
      CaregiverInsightPriority.informational => (
        Icons.info_outline,
        AleraColors.primary,
      ),
      CaregiverInsightPriority.positive => (
        Icons.check_circle_outline,
        const Color(0xFF2E7D32),
      ),
      CaregiverInsightPriority.unknown => (
        Icons.circle_outlined,
        AleraColors.textSecondary,
      ),
    };

    return Padding(
      padding: EdgeInsets.only(top: showDivider ? 10 : 0, bottom: 10),
      child: Column(
        children: [
          if (showDivider) const Divider(height: 1),
          if (showDivider) const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, style: AleraTypography.label),
                    const SizedBox(height: 3),
                    Text(
                      item.message,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
