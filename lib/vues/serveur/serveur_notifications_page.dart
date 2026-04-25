import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:takapp/services/server_notification_service.dart';

class ServeurNotificationsPage extends StatelessWidget {
  final String serverId;

  const ServeurNotificationsPage({super.key, required this.serverId});

  String _formatDate(dynamic value) {
    if (value is Timestamp) {
      return DateFormat('dd/MM/yyyy HH:mm').format(value.toDate());
    }
    return '-';
  }

  @override
  Widget build(BuildContext context) {
    final service = ServerNotificationService();
    final isSmallScreen = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: service.streamNotificationsForServer(serverId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Erreur : ${snapshot.error}'));
            }

            final docs = snapshot.data?.docs ?? [];

            if (docs.isEmpty) {
              return const Center(child: Text('Aucune notification.'));
            }

            final notifications = [...docs];
            notifications.sort((a, b) {
              final aDate = a.data()['createdAt'];
              final bDate = b.data()['createdAt'];

              final aMillis = aDate is Timestamp
                  ? aDate.millisecondsSinceEpoch
                  : 0;
              final bMillis = bDate is Timestamp
                  ? bDate.millisecondsSinceEpoch
                  : 0;

              return bMillis.compareTo(aMillis);
            });

            return ListView.separated(
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final doc = notifications[index];
                final data = doc.data();

                final title =
                    data['title']?.toString() ??
                    data['type']?.toString() ??
                    'Notification';

                final message =
                    data['message']?.toString() ??
                    data['body']?.toString() ??
                    '';

                final isRead = data['isRead'] == true;
                final createdAt = data['createdAt'];

                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isRead
                          ? Colors.grey.shade300
                          : Colors.blue.withOpacity(0.15),
                      child: Icon(
                        Icons.notifications,
                        color: isRead ? Colors.grey : Colors.blue,
                      ),
                    ),
                    title: Text(
                      title,
                      style: TextStyle(
                        fontWeight: isRead
                            ? FontWeight.normal
                            : FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (message.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(message),
                        ],
                        const SizedBox(height: 6),
                        Text(
                          _formatDate(createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    isThreeLine: message.isNotEmpty,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
