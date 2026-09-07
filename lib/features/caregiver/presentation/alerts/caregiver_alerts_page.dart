import 'package:flutter/material.dart';

import '../../../../design_system/alera_colors.dart';
import '../../../../design_system/alera_typography.dart';
import '../../../../design_system/widgets/alera_pill.dart';
import '../../../../design_system/widgets/alera_refresh_indicator.dart';
import '../../../../design_system/widgets/alera_svg_icon.dart';
import '../../domain/models/care_recipient.dart';
import '../../domain/models/caregiver_alert.dart';
import '../../data/api/caregiver_alert_api_data_source.dart';
import '../../data/alerts/caregiver_alert_controller.dart';
import '../widgets/caregiver_alert_card.dart';
import '../widgets/caregiver_page_app_bar.dart';

enum AlertFilter { warning, critical, heartRate, spo2, unacknowledged }

class CaregiverAlertsPage extends StatefulWidget {
  final List<CaregiverAlert> alerts;
  final List<CareRecipient> careRecipients;
  final ValueChanged<CaregiverAlert>? onAlertTap;
  final CaregiverAlertDataSource? alertDataSource;
  final CaregiverAlertController? controller;

  const CaregiverAlertsPage({
    super.key,
    required this.alerts,
    required this.careRecipients,
    this.onAlertTap,
    this.alertDataSource,
    this.controller,
  });

  @override
  State<CaregiverAlertsPage> createState() => _CaregiverAlertsPageState();
}

class _CaregiverAlertsPageState extends State<CaregiverAlertsPage> {
  final Set<AlertFilter> _filters = <AlertFilter>{};
  final Set<String> _expandedAlertIds = <String>{};
  late final CaregiverAlertDataSource _alertDataSource;
  late final CaregiverAlertController _controller;
  late final bool _ownsController;
  late List<CaregiverAlert> _displayedAlerts;
  bool _hasCompletedInitialLoad = false;
  bool _loadFailed = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _alertDataSource = widget.alertDataSource ?? CaregiverAlertApiDataSource();
    _ownsController = widget.controller == null;
    _controller =
        widget.controller ??
        CaregiverAlertController(
          loader: _alertDataSource,
          actions: _alertDataSource is CaregiverAlertActionDataSource
              ? _alertDataSource as CaregiverAlertActionDataSource
              : null,
          fallback: widget.alerts,
        );
    _controller.addListener(_syncController);
    _displayedAlerts = const [];
    _loadAlerts();
  }

  @override
  void dispose() {
    _controller.removeListener(_syncController);
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  void _syncController() {
    if (!mounted) return;
    setState(() {
      _displayedAlerts = _controller.alerts;
      _hasCompletedInitialLoad = _controller.hasLoaded;
      _loadFailed = _controller.showingFallback;
      _isLoading = _controller.loading;
    });
  }

  Future<void> _loadAlerts() async {
    await _controller.load();
  }

  void _toggleExpanded(String alertId) {
    setState(() {
      if (!_expandedAlertIds.add(alertId)) {
        _expandedAlertIds.remove(alertId);
      }
    });
  }

  void _toggleFilter(AlertFilter filter) {
    setState(() {
      if (!_filters.add(filter)) {
        _filters.remove(filter);
      }
    });
  }

  bool _matches(CaregiverAlert alert) {
    if (_filters.contains(AlertFilter.warning) &&
        alert.severity != CaregiverAlertSeverity.warning) {
      return false;
    }
    if (_filters.contains(AlertFilter.critical) &&
        alert.severity != CaregiverAlertSeverity.critical) {
      return false;
    }
    if (_filters.contains(AlertFilter.heartRate) &&
        alert.metric != CaregiverAlertMetric.heartRate) {
      return false;
    }
    if (_filters.contains(AlertFilter.spo2) &&
        alert.metric != CaregiverAlertMetric.spo2) {
      return false;
    }
    if (_filters.contains(AlertFilter.unacknowledged) &&
        alert.status != CaregiverAlertStatus.active) {
      return false;
    }
    return true;
  }

  CareRecipient? _recipientFor(String id) {
    for (final CareRecipient recipient in widget.careRecipients) {
      if (recipient.id == id) return recipient;
    }
    return null;
  }

  void _showDetailMessage(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Alert detail coming next'),
          duration: Duration(seconds: 2),
        ),
      );
  }

  void _handleAlertTap(BuildContext context, CaregiverAlert alert) {
    if (widget.onAlertTap != null) {
      widget.onAlertTap!(alert);
      return;
    }
    _showDetailMessage(context);
  }

  Future<void> _markAsSeen(BuildContext context, CaregiverAlert alert) async {
    if (_controller.isBusy(alert.id) ||
        alert.status != CaregiverAlertStatus.active) {
      return;
    }
    try {
      await _controller.acknowledge(alert.id);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('We couldn’t update this alert. Please try again.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<CaregiverAlert> filtered =
        _displayedAlerts.where(_matches).toList()
          ..sort((a, b) => b.detectedAt.compareTo(a.detectedAt));
    final List<CaregiverAlert> active = filtered
        .where((alert) => alert.status == CaregiverAlertStatus.active)
        .toList();
    final List<CaregiverAlert> history = filtered
        .where((alert) => alert.status != CaregiverAlertStatus.active)
        .toList();

    return Scaffold(
      appBar: CaregiverPageAppBar(
        title: 'Alerts',
        actions: [
          caregiverPageAction(
            tooltip: 'Filter alerts',
            onPressed: () => _showDetailMessage(context),
            icon: Icons.filter_list,
          ),
        ],
      ),
      body: Column(
        children: [
          // Change height from 58 to 66 (or higher depending on added padding)
          SizedBox(
            height: 66,
            child: ListView(
              scrollDirection: Axis.horizontal,
              // Add top padding here (e.g., top: 16)
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              children: [
                _FilterChip(
                  label: 'Warning',
                  filter: AlertFilter.warning,
                  assetPath:
                      'alera-figma-assets/assets/icons/status/warning.svg',
                  selected: _filters.contains(AlertFilter.warning),
                  onTap: _toggleFilter,
                ),
                _FilterChip(
                  label: 'Critical',
                  filter: AlertFilter.critical,
                  assetPath:
                      'alera-figma-assets/assets/icons/status/critical.svg',
                  selected: _filters.contains(AlertFilter.critical),
                  onTap: _toggleFilter,
                ),
                _FilterChip(
                  label: 'HR',
                  filter: AlertFilter.heartRate,
                  assetPath:
                      'alera-figma-assets/assets/icons/mini_status/heart_rate.svg',
                  selected: _filters.contains(AlertFilter.heartRate),
                  onTap: _toggleFilter,
                ),
                _FilterChip(
                  label: 'SpO2',
                  filter: AlertFilter.spo2,
                  assetPath:
                      'alera-figma-assets/assets/icons/mini_status/spo2.svg',
                  selected: _filters.contains(AlertFilter.spo2),
                  onTap: _toggleFilter,
                ),
                _FilterChip(
                  label: 'Unacknowledged',
                  filter: AlertFilter.unacknowledged,
                  assetPath: 'alera-figma-assets/assets/icons/status/info.svg',
                  selected: _filters.contains(AlertFilter.unacknowledged),
                  onTap: _toggleFilter,
                ),
              ],
            ),
          ),
          if (_loadFailed)
            Material(
              color: const Color(0xFFFFF4E5),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Live alerts unavailable. Showing fallback alerts.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                    TextButton(
                      onPressed: _isLoading ? null : _loadAlerts,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: !_hasCompletedInitialLoad
                ? const _AlertsLoadingSkeleton()
                : AleraRefreshIndicator(
                    onRefresh: _loadAlerts,
                    backgroundColor: Colors
                        .white, // Sets the circle bubble background to white
                    child: ListView(
                      key: const PageStorageKey<String>(
                        'caregiver-alerts-list',
                      ),
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      children: [
                        _SectionCard(
                          title: 'Active Alerts',
                          child: active.isEmpty
                              ? const _EmptyActiveAlerts()
                              : Column(
                                  children: active
                                      .map(
                                        (alert) => Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 8,
                                          ),
                                          child: CaregiverAlertCard(
                                            alert: alert,
                                            patientName:
                                                alert.patientDisplayName ??
                                                _recipientFor(
                                                  alert.careRecipientId,
                                                )?.name,
                                            showPatientName: true,
                                            unread:
                                                alert.status ==
                                                CaregiverAlertStatus.active,
                                            expanded: _expandedAlertIds
                                                .contains(alert.id),
                                            onToggleExpanded: () =>
                                                _toggleExpanded(alert.id),
                                            onViewMore: () =>
                                                _handleAlertTap(context, alert),
                                            onMarkAsSeen:
                                                _controller.supportsActions &&
                                                    !_controller.isBusy(
                                                      alert.id,
                                                    )
                                                ? () => _markAsSeen(
                                                    context,
                                                    alert,
                                                  )
                                                : null,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                        ),
                        const SizedBox(height: 12),
                        _SectionCard(
                          title: 'History',
                          child: history.isEmpty
                              ? const _EmptyHistory()
                              : _GroupedHistory(
                                  alerts: history,
                                  recipientFor: _recipientFor,
                                  expandedAlertIds: _expandedAlertIds,
                                  onToggleExpanded: _toggleExpanded,
                                  onMarkAsSeen: null,
                                  onAlertTap: (alert) =>
                                      _handleAlertTap(context, alert),
                                ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _AlertsLoadingSkeleton extends StatelessWidget {
  const _AlertsLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const Key('alerts-loading-skeleton'),
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: const [
        _SkeletonSection(
          title: 'Active Alerts',
          children: [
            _AlertCardSkeleton(),
            SizedBox(height: 8),
            _AlertCardSkeleton(),
          ],
        ),
        SizedBox(height: 12),
        _SkeletonSection(
          title: 'History',
          children: [_AlertCardSkeleton(compact: true)],
        ),
      ],
    );
  }
}

class _SkeletonSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SkeletonSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D5E477C),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AleraTypography.sectionTitle),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _AlertCardSkeleton extends StatelessWidget {
  final bool compact;

  const _AlertCardSkeleton({this.compact = false});

  @override
  Widget build(BuildContext context) {
    const Color placeholder = Color(0xFFE5DCF5);
    return Container(
      height: compact ? 64 : 76,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A5E477C),
            blurRadius: 7,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: placeholder,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SkeletonBar(widthFactor: .72),
                SizedBox(height: 8),
                _SkeletonBar(widthFactor: .45, height: 9),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonBar extends StatelessWidget {
  final double widthFactor;
  final double height;

  const _SkeletonBar({required this.widthFactor, this.height = 12});

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFE5DCF5),
          borderRadius: BorderRadius.circular(height / 2),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final AlertFilter filter;
  final String assetPath;
  final bool selected;
  final ValueChanged<AlertFilter> onTap;

  const _FilterChip({
    required this.label,
    required this.filter,
    required this.assetPath,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: AleraPill(
        label: label,
        leading: AleraSvgIcon(assetPath: assetPath, width: 20, height: 20),
        selected: selected,
        variant: AleraPillVariant.filter,
        onTap: () => onTap(filter),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AleraTypography.sectionTitle),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _EmptyActiveAlerts extends StatelessWidget {
  const _EmptyActiveAlerts();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 26),
      child: Center(
        child: Column(
          children: [
            AleraSvgIcon(
              assetPath: 'alera-figma-assets/assets/icons/status/stable.svg',
              width: 48,
              height: 48,
              semanticLabel: 'No active alerts',
            ),
            SizedBox(height: 10),
            Text(
              'No active alerts right now',
              style: TextStyle(
                color: Color(0xFFA69BD2),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'We’ll let you know if anything needs attention.',
              style: TextStyle(color: Color(0xFFB5AADB), fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Center(
        child: Text(
          'No alerts match the selected filters.',
          style: AleraTypography.label,
        ),
      ),
    );
  }
}

class _GroupedHistory extends StatelessWidget {
  final List<CaregiverAlert> alerts;
  final CareRecipient? Function(String id) recipientFor;
  final ValueChanged<CaregiverAlert> onAlertTap;
  final Set<String> expandedAlertIds;
  final ValueChanged<String> onToggleExpanded;
  final VoidCallback? onMarkAsSeen;

  const _GroupedHistory({
    required this.alerts,
    required this.recipientFor,
    required this.onAlertTap,
    required this.expandedAlertIds,
    required this.onToggleExpanded,
    required this.onMarkAsSeen,
  });

  @override
  Widget build(BuildContext context) {
    final Map<String, List<CaregiverAlert>> groups =
        <String, List<CaregiverAlert>>{};
    for (final CaregiverAlert alert in alerts) {
      final int days = DateTime.now().difference(alert.detectedAt).inDays;
      final String label = days <= 0
          ? 'Today'
          : days == 1
          ? 'Yesterday'
          : 'Earlier';
      groups.putIfAbsent(label, () => <CaregiverAlert>[]).add(alert);
    }
    const order = ['Today', 'Yesterday', 'Earlier'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final String label in order)
          if (groups[label] != null) ...[
            Text(
              label,
              style: const TextStyle(
                color: AleraColors.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 7),
            for (final CaregiverAlert alert in groups[label]!) ...[
              CaregiverAlertCard(
                alert: alert,
                patientName:
                    alert.patientDisplayName ??
                    recipientFor(alert.careRecipientId)?.name,
                showPatientName: true,
                unread: alert.status == CaregiverAlertStatus.active,
                expanded: expandedAlertIds.contains(alert.id),
                onToggleExpanded: () => onToggleExpanded(alert.id),
                onViewMore: () => onAlertTap(alert),
                onMarkAsSeen: onMarkAsSeen,
              ),
              const SizedBox(height: 8),
            ],
          ],
      ],
    );
  }
}

class AlertListCard extends StatelessWidget {
  final CaregiverAlert alert;
  final CareRecipient? recipient;
  final VoidCallback onTap;

  const AlertListCard({
    super.key,
    required this.alert,
    required this.recipient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool heartRate = alert.metric == CaregiverAlertMetric.heartRate;
    final bool spo2 = alert.metric == CaregiverAlertMetric.spo2;
    final Color stripe = alert.severity == CaregiverAlertSeverity.critical
        ? AleraColors.critical
        : AleraColors.warning;
    final String iconPath = heartRate
        ? 'alera-figma-assets/assets/icons/mini_status/heart_rate.svg'
        : spo2
        ? 'alera-figma-assets/assets/icons/mini_status/spo2.svg'
        : 'alera-figma-assets/assets/icons/mini_status/info.svg';
    final String identity = recipient?.name ?? 'Unknown patient';
    return Material(
      color: const Color(0xFFFCFBFF),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: stripe, width: 5)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              _InitialAvatar(name: identity),
              const SizedBox(width: 8),
              AleraSvgIcon(assetPath: iconPath, width: 28, height: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      identity,
                      style: const TextStyle(
                        color: AleraColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      alert.title,
                      style: AleraTypography.label.copyWith(
                        color: AleraColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${alert.reading.toStringAsFixed(0)} ${alert.unit} • ${_relativeTime(alert.detectedAt)}',
                      style: AleraTypography.body.copyWith(fontSize: 10),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.expand_more, color: Color(0xFFB7B2C3)),
            ],
          ),
        ),
      ),
    );
  }

  String _relativeTime(DateTime dateTime) {
    final int minutes = DateTime.now().difference(dateTime).inMinutes;
    if (minutes <= 1) return 'just now';
    if (minutes < 60) return '$minutes mins ago';
    final int hours = minutes ~/ 60;
    return '$hours hr${hours == 1 ? '' : 's'} ago';
  }
}

class _InitialAvatar extends StatelessWidget {
  final String name;

  const _InitialAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final String initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .take(2)
        .map((word) => word.characters.first.toUpperCase())
        .join();
    const colors = [Color(0xFF8165C7), Color(0xFF4D91A8), Color(0xFFB36B8D)];
    final int seed = name.codeUnits.fold(0, (sum, value) => sum + value);
    return CircleAvatar(
      radius: 20,
      backgroundColor: colors[seed % colors.length],
      child: Text(
        initials,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}
