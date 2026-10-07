import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../Services/upload_queue_service.dart';
import '../../../features/elderly/presentation/widgets/clear_pending_queue_button.dart';
import '../../../features/elderly/presentation/widgets/elderly_widgets.dart';

class SpO2HistoryPage extends StatefulWidget {
  final UploadQueueService uploadQueueService;

  const SpO2HistoryPage({super.key, required this.uploadQueueService});

  @override
  State<SpO2HistoryPage> createState() => _SpO2HistoryPageState();
}

class _SpO2HistoryPageState extends State<SpO2HistoryPage> {
  List<_Reading> readings = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final List<Map<String, dynamic>> pending = await widget.uploadQueueService
        .getAllPending();

    final List<_Reading> loaded = pending
        .where((item) => item['metric_type'] == 'SPO2')
        .map((item) {
          final Map<String, dynamic> payload = jsonDecode(item['payload_json']);
          final num? value = num.tryParse('${payload['numeric_value']}');
          return _Reading(
            value: value,
            recordedAt: DateTime.tryParse('${payload['recorded_at']}'),
          );
        })
        .toList();

    loaded.sort((a, b) {
      final DateTime? x = a.recordedAt;
      final DateTime? y = b.recordedAt;
      if (x == null || y == null) return 0;
      return y.compareTo(x);
    });

    if (!mounted) return;

    setState(() {
      readings = loaded;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final _Reading? latest = readings.isEmpty ? null : readings.first;

    return Scaffold(
      appBar: AppBar(title: const Text('SpO₂')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            ElderlyVitalTile(
              height: 180,
              backgroundAsset: ElderlyVitalTile.spo2Background,
              iconAsset: ElderlyVitalTile.spo2Icon,
              title: 'SpO₂',
              value: latest?.value == null ? '--' : '${latest!.value!.round()}',
              unit: '%',
              caption: latest == null
                  ? 'No readings yet'
                  : 'Latest · ${elderlyFriendlyDateTime(latest.recordedAt)}',
              textColor: ElderlyVitalTile.spo2Color,
            ),
            const SizedBox(height: 24),
            const ElderlySectionTitle('Recent readings'),
            const SizedBox(height: 12),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (readings.isEmpty)
              const ElderlyStateMessage(
                icon: Icons.water_drop,
                title: 'No readings yet',
                message: 'New readings will appear here once your watch sends them.',
              )
            else
              for (final _Reading reading in readings)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ElderlyReadingRow(
                    icon: Icons.water_drop,
                    color: ElderlyVitalTile.spo2Color,
                    value: reading.value == null
                        ? '--'
                        : '${reading.value!.round()} %',
                    caption: elderlyFriendlyDateTime(reading.recordedAt),
                  ),
                ),
            if (readings.isNotEmpty) ...[
              const SizedBox(height: 16),
              Center(
                child: ClearPendingQueueButton(
                  uploadQueueService: widget.uploadQueueService,
                  metricType: 'SPO2',
                  onCleared: _load,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Reading {
  const _Reading({required this.value, required this.recordedAt});

  final num? value;
  final DateTime? recordedAt;
}
