import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:pioquinto_advmobprog/widgets/custom_text.dart';

import '../services/chat_service.dart';
import '../services/user_service.dart';

final ChatService chatService = ChatService();

class ChatDetailScreen extends StatefulWidget {
  final String currentUserEmail;
  final Map<String, dynamic> tappedUser;

  const ChatDetailScreen({
    Key? key,
    required this.currentUserEmail,
    required this.tappedUser,
  }) : super(key: key);

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  late final TextEditingController _msgCtrl = TextEditingController();
  late final FocusNode _msgFocus = FocusNode();
  late final ScrollController _scrollCtrl = ScrollController();

  final UserService _userService = UserService();
  late Future<String?> _currentUserIdFuture;
  bool _isSending = false;

  Timestamp? _sendingStartedAt;
  static const Duration _postSendDelay = Duration(milliseconds: 600);

  @override
  void initState() {
    super.initState();
    _currentUserIdFuture = _getCurrentUserId();
  }

  Future<String?> _getCurrentUserId() async {
    final userData = await _userService.getUserData();
    return userData['uid']?.toString();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _msgFocus.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send(String? currentUserId, String receiverId) async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _isSending || currentUserId == null) return;

    setState(() {
      _isSending = true;
      _sendingStartedAt = Timestamp.now();
    });

    try {
      await chatService.sendMessage(receiverId, text);
      _msgCtrl.clear();
      _msgFocus.requestFocus();
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          0.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
      await Future.delayed(_postSendDelay);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to send: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
          _sendingStartedAt = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tappedUserId = widget.tappedUser['uid']?.toString() ?? '';
    final tappedUserName =
        '${widget.tappedUser['firstName'] ?? ''} ${widget.tappedUser['lastName'] ?? ''}';

    return FutureBuilder<String?>(
      future: _currentUserIdFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snap.hasData || snap.data!.isEmpty) {
          return const Scaffold(
            body: Center(child: Text('Error loading user data')),
          );
        }

        final currentUserId = snap.data!;

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.grey),
              onPressed: () => Navigator.pop(context),
            ),
            title: CustomText(
              text: tappedUserName,
              fontSize: 18.sp,
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
            centerTitle: true,
            toolbarHeight: 70,
          ),
          body: Column(
            children: [
              // Messages
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: chatService.getMessage(currentUserId, tappedUserId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    List<QueryDocumentSnapshot> docs =
                        snapshot.data?.docs ?? [];

                    // Filter out messages sent after "sending" started
                    if (_sendingStartedAt != null) {
                      docs = docs.where((doc) {
                        final docData = doc.data() as Map<String, dynamic>;
                        final senderId = (docData['senderId'] ?? '').toString();
                        final ts = docData['timestamp'];
                        if (senderId != currentUserId) return true;
                        if (ts is Timestamp) {
                          return ts.compareTo(_sendingStartedAt!) < 0;
                        }
                        return true;
                      }).toList();
                    }

                    if (docs.isEmpty) {
                      return const Center(child: Text('No messages yet'));
                    }

                    return ListView.builder(
                      controller: _scrollCtrl,
                      reverse: true,
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final msgText = data['message'] ?? '';
                        final senderId = data['senderId'] ?? '';
                        final status = data['status']?.toString() ?? '';
                        final isMe = senderId == currentUserId;

                        final timestamp = data['timestamp'] is Timestamp
                            ? (data['timestamp'] as Timestamp).toDate()
                            : null;

                        return Column(
                          crossAxisAlignment: isMe
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            Align(
                              alignment: isMe
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (!isMe)
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(right: 6.0),
                                      child: CircleAvatar(
                                        radius: 14,
                                        backgroundColor: Colors.grey.shade400,
                                        child: CustomText(
                                          text: tappedUserName.isNotEmpty
                                              ? tappedUserName[0]
                                              : '?',
                                          fontSize: 14.sp,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  Flexible(
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 4),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10, horizontal: 14),
                                      constraints: BoxConstraints(
                                        maxWidth:
                                            MediaQuery.of(context).size.width *
                                                0.75,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isMe
                                            ? const Color(0xFF0A84FF)
                                            : Colors.grey.shade200,
                                        borderRadius: BorderRadius.only(
                                          topLeft: const Radius.circular(18),
                                          topRight: const Radius.circular(18),
                                          bottomLeft: Radius.circular(
                                              isMe ? 18 : 4),
                                          bottomRight: Radius.circular(
                                              isMe ? 4 : 18),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.05),
                                            offset: const Offset(0, 2),
                                            blurRadius: 2,
                                          ),
                                        ],
                                      ),
                                      child: CustomText(
                                        text: msgText.isNotEmpty
                                            ? msgText
                                            : '[empty]',
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.normal,
                                        color: isMe
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Timestamp 
                            Padding(
                              padding: EdgeInsets.only(
                                left: isMe ? 0 : 46,
                                right: isMe ? 12 : 0,
                                top: 2,
                                bottom: 6,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: isMe
                                    ? MainAxisAlignment.end
                                    : MainAxisAlignment.start,
                                children: [
                                  if (timestamp != null)
                                    CustomText(
                                      text: DateFormat('hh:mm a')
                                          .format(timestamp),
                                      fontSize: 11.sp,
                                      color: Colors.grey,
                                    ),
                                  if (isMe) ...[
                                    const SizedBox(width: 6),
                                    CustomText(
                                      text: status,
                                      fontSize: 11.sp,
                                      color: Colors.grey,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),

              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _msgCtrl,
                          focusNode: _msgFocus,
                          enabled: !_isSending,
                          textInputAction: TextInputAction.send,
                          minLines: 1,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Message',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: BorderSide.none,
                            ),
                            fillColor: Colors.grey.shade200,
                            filled: true,
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 15),
                            isDense: true,
                          ),
                          onSubmitted: (_) =>
                              _send(currentUserId, tappedUserId),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _isSending
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : IconButton(
                              icon: const Icon(Icons.send, color: Colors.blue),
                              onPressed: () =>
                                  _send(currentUserId, tappedUserId),
                            ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
