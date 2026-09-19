import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../Services/upload_queue_service.dart';
import '../../../features/elderly/presentation/widgets/clear_pending_queue_button.dart';

class SpO2HistoryPage extends StatefulWidget {
  final UploadQueueService uploadQueueService;

  const SpO2HistoryPage({super.key, required this.uploadQueueService});

  @override
  State<SpO2HistoryPage> createState() => _SpO2HistoryPageState();
}

class _SpO2HistoryPageState extends State<SpO2HistoryPage> {
  List<Map<String, dynamic>> spo2Queue = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSpO2Queue();
  }

  Future<void> _loadSpO2Queue() async {
    final List<Map<String, dynamic>> pending = await widget.uploadQueueService
        .getAllPending();

    final List<Map<String, dynamic>> spo2 = pending.where((item) {
      return item['metric_type'] == 'SPO2';
    }).toList();

    if (!mounted) return;

    setState(() {
      spo2Queue = spo2;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.purple,
        title: const Text('SpO2 Records'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadSpO2Queue,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Pending SpO2 Queue',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            Text('${spo2Queue.length} pending reading(s)'),

            const SizedBox(height: 16),

            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (spo2Queue.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No pending SpO2 readings.'),
                ),
              )
            else
              ...spo2Queue.map((item) {
                final Map<String, dynamic> payload = jsonDecode(
                  item['payload_json'],
                );

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const Icon(Icons.bloodtype, color: Colors.red),
                    title: Text('${payload['numeric_value']}%'),
                    subtitle: Text(
                      'Queue ID: ${item['id']}\n'
                      'Status: ${item['queue_status']}\n'
                      'Recorded: ${payload['recorded_at']}',
                    ),
                  ),
                );
              }),

            const SizedBox(height: 16),

            ClearPendingQueueButton(
              uploadQueueService: widget.uploadQueueService,
              metricType: 'SPO2',
            ),
          ],
        ),
      ),
    );
  }
}
