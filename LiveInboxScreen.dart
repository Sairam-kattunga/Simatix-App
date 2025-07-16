import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LiveInboxScreen extends StatefulWidget {
  const LiveInboxScreen({super.key});

  @override
  State<LiveInboxScreen> createState() => _LiveInboxScreenState();
}

class _LiveInboxScreenState extends State<LiveInboxScreen> {
  final TextEditingController _messageController = TextEditingController();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  bool _isSending = false;

  final List<String> _emojiOptions = ['👍', '❤️', '😂', '😮', '😢', '👏'];

  @override
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showUsageAlert());
    _messageController.addListener(() {
      setState(() {});  // triggers rebuild on text changes
    });
  }


  Future<void> _showUsageAlert() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Important Notice'),
        content: const Text(
          'Live Inbox is for sharing real-time campus updates only. Misuse may lead to restrictions. '
              'Messages auto-expire after 24 hours.',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    setState(() => _isSending = true);

    try {
      final doc = await _firestore.collection('students').doc(user.uid).get();
      final name = doc.exists && doc.data()?['name'] != null
          ? doc['name'] as String
          : 'Anonymous';
      final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';

      await _firestore.collection('live_inbox').add({
        'uid': user.uid,
        'initial': initial,
        'message': messageText,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'sent',
        'reactions': <String, dynamic>{},
      });

      _messageController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Send failed: $e')));
    } finally {
      setState(() => _isSending = false);
    }
  }

  Future<void> _toggleReaction(DocumentSnapshot doc, String emoji, String uid) async {
    final data = doc.data() as Map<String, dynamic>;
    final reactions = Map<String, dynamic>.from(data['reactions'] ?? {});
    final currentList = (reactions[emoji] as List<dynamic>?)?.cast<String>() ?? [];

    if (currentList.contains(uid)) {
      currentList.remove(uid);
    } else {
      currentList.add(uid);
    }

    if (currentList.isEmpty) {
      reactions.remove(emoji);
    } else {
      reactions[emoji] = currentList;
    }

    await doc.reference.update({'reactions': reactions});
  }

  Widget _buildStatusTicks(String status) {
    switch (status) {
      case 'sent':
        return const Icon(Icons.check, size: 16, color: Colors.grey);
      case 'delivered':
        return const Icon(Icons.done_all, size: 16, color: Colors.grey);
      case 'read':
        return const Icon(Icons.done_all, size: 16, color: Colors.blue);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildReactions(Map<String, dynamic>? reactions) {
    if (reactions == null || reactions.isEmpty) return const SizedBox.shrink();

    List<Widget> reactionWidgets = [];
    reactions.forEach((emoji, userList) {
      final count = (userList as List<dynamic>).length;
      if (count > 0) {
        reactionWidgets.add(
          Container(
            margin: const EdgeInsets.only(right: 6),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(
                  count.toString(),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        );
      }
    });

    return Padding(
      padding: const EdgeInsets.only(top: 4, left: 6),
      child: Wrap(children: reactionWidgets),
    );
  }

  Future<void> _deleteMessage(DocumentSnapshot doc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Message?'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await doc.reference.delete();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Message deleted')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
      }
    }
  }

  Future<void> _clearChat() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Chat'),
        content: const Text('Are you sure you want to delete ALL messages? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Clear All')),
        ],
      ),
    );

    if (confirm == true) {
      final batch = _firestore.batch();

      final snapshot = await _firestore.collection('live_inbox').get();

      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      try {
        await batch.commit();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All messages deleted')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Clear chat failed: $e')));
      }
    }
  }

  Widget _buildMessage(DocumentSnapshot doc, Map<String, dynamic> data, bool isMe) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = data['message'] as String?;
    final time = (data['timestamp'] as Timestamp?)?.toDate();
    final formattedTime = time != null ? TimeOfDay.fromDateTime(time).format(context) : '';
    final status = data['status'] as String? ?? 'sent';
    final reactions = data['reactions'] as Map<String, dynamic>?;

    final bubbleColor = isMe
        ? Colors.indigo.shade600
        : isDark
        ? Colors.grey.shade800
        : Colors.grey.shade300;

    final textColor = isDark || isMe ? Colors.white : Colors.black87;

    return GestureDetector(
      onLongPress: () {
        if (isMe) {
          _deleteMessage(doc);
        } else {
          final uid = _auth.currentUser?.uid;
          if (uid != null) {
            _showReactionPicker(doc);
          }
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!isMe)
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.indigo.shade700,
                    child: Text(
                      data['initial'] ?? '?',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                if (!isMe) const SizedBox(width: 10),
                Flexible(
                  child: Container(
                    decoration: BoxDecoration(
                      color: bubbleColor,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(isMe ? 18 : 4),
                        topRight: Radius.circular(isMe ? 4 : 18),
                        bottomLeft: const Radius.circular(18),
                        bottomRight: const Radius.circular(18),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    child: Text(
                      text ?? '',
                      style: TextStyle(color: textColor, fontSize: 16, height: 1.3),
                    ),
                  ),
                ),
                if (isMe) const SizedBox(width: 10),
                if (isMe)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: _buildStatusTicks(status),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                Text(
                  formattedTime,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
            _buildReactions(reactions),
          ],
        ),
      ),
    );
  }

  void _showReactionPicker(DocumentSnapshot doc) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _emojiOptions.map((emoji) {
              return GestureDetector(
                onTap: () {
                  Navigator.of(ctx).pop();
                  _toggleReaction(doc, emoji, uid);
                },
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 32),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Inbox'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Clear All Messages',
            onPressed: _clearChat,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('live_inbox')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (ctx, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('No messages yet.\nStart the conversation!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey)),
                  );
                }
                final docs = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.only(top: 10, bottom: 10),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final isMe = data['uid'] == user?.uid;
                    return _buildMessage(doc, data, isMe);
                  },
                );
              },
            ),
          ),
          // Input bar container moved inside Column children
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade900 : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black54 : Colors.grey.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    textCapitalization: TextCapitalization.sentences,
                    autocorrect: true,
                    enableSuggestions: true,
                    decoration: InputDecoration(
                      hintText: 'Type a message',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                      ),
                      filled: true,
                      fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                      contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 16,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 12),
                _isSending
                    ? const SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(strokeWidth: 3),
                )
                    : IconButton(
                  icon: Icon(
                    Icons.send,
                    color: _messageController.text.trim().isEmpty
                        ? Colors.grey
                        : Colors.green,
                  ),
                  onPressed: _messageController.text.trim().isEmpty ? null : _sendMessage,
                ),
              ],
            ),
          ),
          const SizedBox(height: 6), // small padding below input bar
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}
