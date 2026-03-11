import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/session_controller.dart';
import '../controllers/probe_controller.dart';

class SessionsScreen extends StatelessWidget {
  const SessionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SessionController()..init(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Sessions'),
        ),
        body: Consumer<SessionController>(
          builder: (context, sessionController, child) {
            if (sessionController.sessions.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No sessions saved',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Start a new session to save your cook',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              itemCount: sessionController.sessions.length,
              itemBuilder: (context, index) {
                final session = sessionController.sessions[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    leading: Icon(
                      session.isActive
                          ? Icons.radio_button_checked
                          : Icons.history,
                      color: session.isActive
                          ? const Color(0xFFFF9F0A)
                          : Colors.grey,
                    ),
                    title: Text(session.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Started: ${_formatDateTime(session.startTime)}',
                        ),
                        if (!session.isActive)
                          Text(
                            'Duration: ${_formatDuration(session.duration)}',
                          ),
                        Text(
                          'Probes: ${session.probeHistories.length}',
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton(
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'export',
                          child: Row(
                            children: [
                              Icon(Icons.share),
                              SizedBox(width: 8),
                              Text('Export CSV'),
                            ],
                          ),
                        ),
                        if (session.isActive)
                          const PopupMenuItem(
                            value: 'end',
                            child: Row(
                              children: [
                                Icon(Icons.stop),
                                SizedBox(width: 8),
                                Text('End Session'),
                              ],
                            ),
                          ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) {
                        switch (value) {
                          case 'export':
                            sessionController.exportSessionToCsv(session);
                            break;
                          case 'end':
                            sessionController.endSession(session.id);
                            break;
                          case 'delete':
                            _showDeleteConfirmation(
                              context,
                              sessionController,
                              session.id,
                            );
                            break;
                        }
                      },
                    ),
                  ),
                );
              },
            );
          },
        ),
        floatingActionButton: Consumer2<SessionController, ProbeController>(
          builder: (context, sessionController, probeController, child) {
            return FloatingActionButton.extended(
              onPressed: () => _showNewSessionDialog(
                context,
                sessionController,
                probeController,
              ),
              icon: const Icon(Icons.add),
              label: const Text('New Session'),
            );
          },
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  void _showNewSessionDialog(
    BuildContext context,
    SessionController sessionController,
    ProbeController probeController,
  ) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Cook Session'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Session Name',
                hintText: 'e.g., Brisket Cook',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            Text(
              'This will save data from ${probeController.probes.length} active probe(s)',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                sessionController.startSession(
                  nameController.text,
                  probeController.probes,
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    SessionController controller,
    String sessionId,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Session'),
        content: const Text('Are you sure you want to delete this session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.deleteSession(sessionId);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
