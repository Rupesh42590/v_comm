import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart' hide Config;
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/foundation.dart' as foundation;

// ------------------- DATA MODEL -------------------
class Message {
  final String text;
  final DateTime timestamp;
  final bool isSentByMe;
  final bool isRead;

  Message({
    required this.text,
    required this.timestamp,
    required this.isSentByMe,
    this.isRead = false,
  });
}

// ------------------- MAIN CHAT PAGE -------------------
class ChatPage extends StatefulWidget {
  final String chatRoomId;
  final Map<String, dynamic> otherUser;

  const ChatPage({
    super.key,
    required this.chatRoomId,
    required this.otherUser,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  bool _showSendButton = false;
  bool _showEmojiPicker = false;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(() {
      setState(() => _showSendButton = _messageController.text.isNotEmpty);
    });

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        setState(() => _showEmojiPicker = false);
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _toggleEmojiPicker() {
    if (!_showEmojiPicker) _focusNode.unfocus();
    setState(() => _showEmojiPicker = !_showEmojiPicker);
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    final messageData = {
      'text': text,
      'senderId': currentUser!.uid,
      'timestamp': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatRoomId)
        .collection('messages')
        .add(messageData);

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatRoomId)
        .set({
          'lastMessage': text,
          'lastMessageTimestamp': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildChatAppBar(),
      body: Column(
        children: [
          // ------------------- MESSAGE LIST -------------------
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_showEmojiPicker) setState(() => _showEmojiPicker = false);
                _focusNode.unfocus();
              },
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black, Color(0xFF111111), Colors.black],
                  ),
                ),
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('chats')
                      .doc(widget.chatRoomId)
                      .collection('messages')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Text(
                          "Say hello!",
                          style: GoogleFonts.inter(color: Colors.white54),
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: const EdgeInsets.all(8),
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final doc = snapshot.data!.docs[index];
                        return _MessageBubble(
                          messageData: doc.data() as Map<String, dynamic>,
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),

          // ------------------- INPUT BAR -------------------
          _ChatInputBar(
            messageController: _messageController,
            focusNode: _focusNode,
            onSendPressed: _sendMessage,
            onEmojiPressed: _toggleEmojiPicker,
            showSendButton: _showSendButton,
          ),

          // ------------------- EMOJI PICKER -------------------
          Offstage(
            offstage: !_showEmojiPicker,
            child: SizedBox(
              height: 250,
              child: EmojiPicker(
                textEditingController: _messageController,
                onEmojiSelected: (category, emoji) {},
                onBackspacePressed: () {},
                config: Config(
                  height: 250,
                  checkPlatformCompatibility: true,

                  emojiViewConfig: EmojiViewConfig(
                    emojiSizeMax:
                        28 *
                        (foundation.defaultTargetPlatform == TargetPlatform.iOS
                            ? 1.30
                            : 1.0),
                  ),

                  categoryViewConfig: const CategoryViewConfig(
                    iconColor: Colors.grey,
                    iconColorSelected: Colors.blueAccent,
                    indicatorColor: Colors.blueAccent,
                  ),

                  bottomActionBarConfig: const BottomActionBarConfig(
                    backgroundColor: Color(0xFF1A1A1A),
                  ),

                  skinToneConfig: const SkinToneConfig(),
                  searchViewConfig: const SearchViewConfig(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------- APP BAR -------------------
  AppBar _buildChatAppBar() {
    final bool isGroup = widget.otherUser['isGroup'] ?? false;
    return AppBar(
      backgroundColor: const Color(0xFF1A1A1A),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.white.withOpacity(0.1),
            backgroundImage: widget.otherUser['photoUrl'] != null
                ? NetworkImage(widget.otherUser['photoUrl']!)
                : null,
            child: widget.otherUser['photoUrl'] == null
                ? Icon(
                    isGroup ? Icons.group : Icons.person,
                    color: Colors.white54,
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Text(
            widget.otherUser['name'] ?? 'Chat',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
      actions: [
        if (!isGroup)
          IconButton(
            icon: const Icon(Icons.call_outlined, color: Colors.white),
            onPressed: () {},
          ),
        IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onPressed: () {},
        ),
      ],
    );
  }
}

// ------------------- MESSAGE BUBBLE -------------------
class _MessageBubble extends StatelessWidget {
  final Map<String, dynamic> messageData;

  const _MessageBubble({required this.messageData});

  @override
  Widget build(BuildContext context) {
    final bool isMe =
        messageData['senderId'] == FirebaseAuth.instance.currentUser!.uid;
    final timestamp =
        (messageData['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Card(
        elevation: 1,
        color: isMe ? const Color(0xFF265D4E) : const Color(0xFF2A2A2A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe
                ? const Radius.circular(16)
                : const Radius.circular(4),
            bottomRight: isMe
                ? const Radius.circular(4)
                : const Radius.circular(16),
          ),
        ),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                messageData['text'] ?? '',
                style: GoogleFonts.inter(fontSize: 16, color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('h:mm a').format(timestamp),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------- CHAT INPUT BAR -------------------
class _ChatInputBar extends StatelessWidget {
  final TextEditingController messageController;
  final FocusNode focusNode;
  final VoidCallback onSendPressed;
  final VoidCallback onEmojiPressed;
  final bool showSendButton;

  const _ChatInputBar({
    required this.messageController,
    required this.focusNode,
    required this.onSendPressed,
    required this.onEmojiPressed,
    required this.showSendButton,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.emoji_emotions_outlined,
                        color: Colors.white70,
                      ),
                      onPressed: onEmojiPressed,
                    ),
                    Expanded(
                      child: TextField(
                        controller: messageController,
                        focusNode: focusNode,
                        maxLines: null,
                        style: GoogleFonts.inter(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "Message",
                          hintStyle: GoogleFonts.inter(color: Colors.white54),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.attach_file,
                        color: Colors.white70,
                      ),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.white.withOpacity(0.15),
              child: IconButton(
                icon: Icon(
                  showSendButton ? Icons.send : Icons.mic,
                  color: Colors.white,
                ),
                onPressed: showSendButton ? onSendPressed : () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}
