import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../Services/upload_queue_service.dart';
import '../../../features/elderly/presentation/widgets/clear_pending_queue_button.dart';

class HeartRateHistoryPage extends StatefulWidget {
  final UploadQueueService uploadQueueService;

  const HeartRateHistoryPage({
    super.key,
    required this.uploadQueueService,
  });

  @override
  State<HeartRateHistoryPage> createState() =>
      _HeartRateHistoryPageState();
}

class _HeartRateHistoryPageState
    extends State<HeartRateHistoryPage> {

  List<Map<String, dynamic>> heartRateQueue = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    _loadHeartRateQueue();
  }

  Future<void> _loadHeartRateQueue() async {
    final List<Map<String, dynamic>> pending =
        await widget.uploadQueueService
            .getAllPending();

    final List<Map<String, dynamic>> heartRate =
        pending.where((item) {
      return item['metric_type'] ==
          'HEART_RATE';
    }).toList();

    if (!mounted) return;

    setState(() {
      heartRateQueue = heartRate;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.purple,
        title: const Text(
          'Heart Rate Records',
        ),
      ),

      body: RefreshIndicator(
        onRefresh: _loadHeartRateQueue,

        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Pending Heart Rate Queue',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              '${heartRateQueue.length} pending reading(s)',
            ),

            const SizedBox(height: 16),

            if (isLoading)
              const Center(
                child:
                    CircularProgressIndicator(),
              )
            else if (heartRateQueue.isEmpty)
              const Card(
                child: Padding(
                  padding:
                      EdgeInsets.all(16),
                  child: Text(
                    'No pending heart rate readings.',
                  ),
                ),
              )
            else
              ...heartRateQueue.map(
                (item) {
                  final Map<String, dynamic>
                      payload =
                      jsonDecode(
                    item['payload_json'],
                  );

                  return Card(
                    margin:
                        const EdgeInsets.only(
                      bottom: 12,
                    ),
                    child: ListTile(
                      leading: const Icon(
                        Icons.favorite,
                        color: Colors.red,
                      ),

                      title: Text(
                        '${payload['numeric_value']} BPM',
                      ),

                      subtitle: Text(
                        'Queue ID: ${item['id']}\n'
                        'Status: ${item['queue_status']}\n'
                        'Recorded: ${payload['recorded_at']}',
                      ),
                    ),
                  );
                },
              ),

            const SizedBox(height: 16),

            ClearPendingQueueButton(
              uploadQueueService:
                  widget.uploadQueueService,
                  metricType: 'HEART_RATE',
            ),
          ],
        ),
      ),
    );
  }
}