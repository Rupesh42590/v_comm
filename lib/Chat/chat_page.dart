import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

// Common Emojis
const List<String> kCommonEmojis = [
  '😀',
  '😃',
  '😄',
  '😁',
  '😆',
  '😅',
  '😂',
  '🤣',
  '🙂',
  '🙃',
  '😉',
  '😊',
  '😇',
  '🥰',
  '😍',
  '🤩',
  '😘',
  '😗',
  '😚',
  '😙',
  '😋',
  '😛',
  '😜',
  '🤪',
  '🤨',
  '🧐',
  '🤓',
  '😎',
  '🥸',
  '🥳',
  '🤠',
  '🤡',
  '😏',
  '😒',
  '😞',
  '😔',
  '😟',
  '😕',
  '🙁',
  '☹️',
  '😣',
  '😖',
  '😫',
  '😩',
  '🥺',
  '😢',
  '😭',
  '😤',
  '😠',
  '😡',
  '🤬',
  '🤯',
  '😳',
  '🥵',
  '🥶',
  '😱',
  '😨',
  '😰',
  '😥',
  '😓',
  '🤗',
  '🤔',
  '🤭',
  '🤫',
  '🤥',
  '😶',
  '😐',
  '😑',
  '😬',
  '🙄',
  '😯',
  '😦',
  '😧',
  '😮',
  '😲',
  '🥱',
  '😴',
  '🤤',
  '😪',
  '😵',
  '🤐',
  '🥴',
  '🤢',
  '🤮',
  '🤧',
  '😷',
  '🤒',
  '🤕',
  '🤑',
  '🤠',
  '😈',
  '👿',
  '👹',
  '👺',
  '🤡',
  '💩',
  '👍',
  '👎',
  '👌',
  '✌️',
  '🤞',
  '🤟',
  '🤘',
  '🤙',
  '👈',
  '👉',
  '👆',
  '👇',
  '☝️',
  '✊',
  '🤛',
  '🤜',
  '❤️',
  '🧡',
  '💛',
  '💚',
  '💙',
  '💜',
  '🖤',
  '🤍',
  '💔',
  '❣️',
  '💕',
  '💞',
  '💓',
  '💗',
  '💖',
  '🔥',
  '💯',
  '✨',
  '🌟',
  '💫',
  '💥',
  '🌈',
  '☀️',
  '🌙',
  '⚡️',
];

// Message Model - UPDATED with sender name for groups
class Message {
  final String id;
  final String text;
  final DateTime timestamp;
  final bool isSentByMe;
  final String? imageUrl;
  final bool isPinned;
  final bool isStarred;
  final bool isDeleted;
  final String? deletedBy;
  final bool isEdited;
  final DateTime? editedTimestamp;
  final List<String> reactions;
  final String? replyToId;
  final String? replyToText;
  final bool isForwarded;
  final String? forwardedFrom;
  final String? senderId;
  final String? forwardedBy;
  final String? forwardedByName;
  final String? senderName; // NEW: For displaying sender name in groups

  Message({
    required this.id,
    required this.text,
    required this.timestamp,
    required this.isSentByMe,
    this.imageUrl,
    this.isPinned = false,
    this.isStarred = false,
    this.isDeleted = false,
    this.deletedBy,
    this.isEdited = false,
    this.editedTimestamp,
    this.reactions = const [],
    this.replyToId,
    this.replyToText,
    this.isForwarded = false,
    this.forwardedFrom,
    this.senderId,
    this.forwardedBy,
    this.forwardedByName,
    this.senderName,
  });

  factory Message.fromMap(
    String id,
    Map<String, dynamic> data,
    String currentUserId,
  ) {
    List<String> reactionsList = [];
    if (data['reactions'] != null) {
      try {
        if (data['reactions'] is List) {
          reactionsList = List<String>.from(data['reactions']);
        }
      } catch (e) {
        debugPrint('Error parsing reactions: $e');
      }
    }

    return Message(
      id: id,
      text: data['text']?.toString() ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isSentByMe: data['senderId'] == currentUserId,
      imageUrl: data['imageUrl']?.toString(),
      isPinned: data['isPinned'] == true,
      isStarred: data['isStarred'] == true,
      isDeleted: data['isDeleted'] == true,
      deletedBy: data['deletedBy']?.toString(),
      isEdited: data['isEdited'] == true,
      editedTimestamp: (data['editedTimestamp'] as Timestamp?)?.toDate(),
      reactions: reactionsList,
      replyToId: data['replyToId']?.toString(),
      replyToText: data['replyToText']?.toString(),
      isForwarded: data['isForwarded'] == true,
      forwardedFrom: data['forwardedFrom']?.toString(),
      senderId: data['senderId']?.toString(),
      forwardedBy: data['forwardedBy']?.toString(),
      forwardedByName: data['forwardedByName']?.toString(),
      senderName: data['senderName']?.toString(), // NEW
    );
  }
}

class ChatPage extends StatefulWidget {
  final String chatRoomId;
  final Map<String, dynamic> otherUser;
  final bool isGroup;

  const ChatPage({
    super.key,
    required this.chatRoomId,
    required this.otherUser,
    this.isGroup = false,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final ImagePicker _picker = ImagePicker();

  bool _showSendButton = false;
  bool _showEmojiPicker = false;
  bool _isUploading = false;
  bool _showSearchBar = false;
  String _searchQuery = '';
  Message? _replyingTo;
  final Set<String> _selectedMessages = {};
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_onMessageTextChanged);
    // Update online status
    if (currentUser != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .update({'isOnline': true, 'lastSeen': FieldValue.serverTimestamp()});
    }
  }

  @override
  void dispose() {
    _messageController.removeListener(_onMessageTextChanged);
    _messageController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    // Update offline status
    if (currentUser != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .update({
            'isOnline': false,
            'lastSeen': FieldValue.serverTimestamp(),
          });
    }
    super.dispose();
  }

  void _onMessageTextChanged() {
    final hasText = _messageController.text.trim().isNotEmpty;
    if (_showSendButton != hasText) {
      setState(() => _showSendButton = hasText);
    }
  }

  // UPDATED: Now includes sender name for groups
  Future<void> _sendMessage({String? imageUrl}) async {
    if (currentUser == null) return;

    final text = _messageController.text.trim();
    if (text.isEmpty && imageUrl == null) return;

    final chatRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatRoomId);

    _messageController.clear();
    setState(() {
      _showSendButton = false;
      if (_replyingTo != null) {
        _replyingTo = null;
      }
    });

    // Get sender name for group messages
    String? senderName;
    if (widget.isGroup) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .get();
      senderName = userDoc.data()?['name'] ?? 'Unknown';
    }

    final messageData = {
      'text': text,
      'senderId': currentUser!.uid,
      'timestamp': FieldValue.serverTimestamp(),
      'isPinned': false,
      'isStarred': false,
      'isDeleted': false,
      'isEdited': false,
      'reactions': [],
      'isForwarded': false,
      if (widget.isGroup && senderName != null) 'senderName': senderName, // NEW
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (_replyingTo != null) ...{
        'replyToId': _replyingTo!.id,
        'replyToText': _replyingTo!.text,
      },
    };

    try {
      await chatRef.collection('messages').add(messageData);

      final chatDoc = await chatRef.get();
      if (!chatDoc.exists) return;
      final participants = List<String>.from(
        chatDoc.data()?['participants'] ?? [],
      );

      String lastMsg = text.isNotEmpty ? text : '📷 Photo';
      final Map<String, dynamic> updateData = {
        'lastMessage': lastMsg,
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
        'lastMessageSenderId': currentUser!.uid,
      };

      for (final participantId in participants) {
        if (participantId != currentUser!.uid) {
          updateData['unreadCount.$participantId'] = FieldValue.increment(1);
        }
      }

      await chatRef.update(updateData);
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error sending message: ${e.toString()}', isError: true);
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() => _isUploading = true);

      String fileName = 'img_${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('chat_images')
          .child(widget.chatRoomId)
          .child(fileName);

      final bytes = await pickedFile.readAsBytes();

      UploadTask uploadTask = storageRef.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      await _sendMessage(imageUrl: downloadUrl);

      if (mounted) {
        _showSnackBar('Image sent successfully');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error uploading image: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _toggleEmojiPicker() {
    setState(() => _showEmojiPicker = !_showEmojiPicker);
  }

  void _onEmojiSelected(String emoji) {
    final currentText = _messageController.text;
    final selection = _messageController.selection;
    final newText = currentText.replaceRange(
      selection.start,
      selection.end,
      emoji,
    );
    _messageController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: selection.start + emoji.length,
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _toggleSearch() {
    setState(() {
      _showSearchBar = !_showSearchBar;
      if (!_showSearchBar) {
        _searchController.clear();
        _searchQuery = '';
      }
    });
  }

  void _replyToMessage(Message message) {
    setState(() => _replyingTo = message);
  }

  void _cancelReply() {
    setState(() => _replyingTo = null);
  }

  void _toggleMessageSelection(String messageId) {
    setState(() {
      if (_selectedMessages.contains(messageId)) {
        _selectedMessages.remove(messageId);
        if (_selectedMessages.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedMessages.add(messageId);
        _isSelectionMode = true;
      }
    });
  }

  void _cancelSelection() {
    setState(() {
      _selectedMessages.clear();
      _isSelectionMode = false;
    });
  }

  void _forwardMessages() async {
    if (currentUser == null || !mounted || _selectedMessages.isEmpty) return;

    try {
      final groupsSnapshot = await FirebaseFirestore.instance
          .collection('chats')
          .where('isGroup', isEqualTo: true)
          .where('participants', arrayContains: currentUser!.uid)
          .get();

      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where(FieldPath.documentId, isNotEqualTo: currentUser!.uid)
          .limit(50)
          .get();

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        backgroundColor: const Color(0xFF1A1A1A),
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (modalContext) => DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Forward ${_selectedMessages.length} Message${_selectedMessages.length > 1 ? 's' : ''} To',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white24, height: 1),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    if (groupsSnapshot.docs.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text(
                          'GROUPS',
                          style: GoogleFonts.inter(
                            color: Colors.white54,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      ...groupsSnapshot.docs.map((groupDoc) {
                        final groupData = groupDoc.data();
                        final groupName =
                            groupData['groupName'] ?? 'Unnamed Group';
                        final participantCount =
                            (groupData['participants'] as List?)?.length ?? 0;
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF1565C0),
                            child: const Icon(
                              Icons.group,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            groupName,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            '$participantCount member${participantCount != 1 ? 's' : ''}',
                            style: GoogleFonts.inter(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                          onTap: () async {
                            Navigator.pop(modalContext);
                            await _forwardMessagesTo(
                              groupDoc.id,
                              groupName,
                              isGroup: true,
                            );
                          },
                        );
                      }).toList(),
                      const SizedBox(height: 8),
                    ],
                    if (usersSnapshot.docs.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: Text(
                          'CONTACTS',
                          style: GoogleFonts.inter(
                            color: Colors.white54,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      ...usersSnapshot.docs.map((userDoc) {
                        final userData = userDoc.data();
                        final userName = userData['name'] ?? 'Unknown User';
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey.shade700,
                            backgroundImage: userData['photoUrl'] != null
                                ? NetworkImage(userData['photoUrl'])
                                : null,
                            child: userData['photoUrl'] == null
                                ? const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 20,
                                  )
                                : null,
                          ),
                          title: Text(
                            userName,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            userData['email'] ?? '',
                            style: GoogleFonts.inter(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () async {
                            Navigator.pop(modalContext);
                            await _forwardMessagesTo(
                              userDoc.id,
                              userName,
                              isGroup: false,
                            );
                          },
                        );
                      }).toList(),
                    ],
                    if (usersSnapshot.docs.isEmpty &&
                        groupsSnapshot.docs.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 64,
                              color: Colors.white.withOpacity(0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No contacts or groups found',
                              style: GoogleFonts.inter(
                                color: Colors.white54,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error loading contacts: $e', isError: true);
      }
    }
  }

  Future<void> _forwardMessagesTo(
    String recipientId,
    String recipientName, {
    required bool isGroup,
  }) async {
    if (currentUser == null) return;

    try {
      final currentUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .get();
      final currentUserName = currentUserDoc.data()?['name'] ?? 'Someone';

      String chatRoomId;

      if (isGroup) {
        chatRoomId = recipientId;
      } else {
        List<String> ids = [currentUser!.uid, recipientId]..sort();
        chatRoomId = ids.join('_');

        final chatDoc = await FirebaseFirestore.instance
            .collection('chats')
            .doc(chatRoomId)
            .get();

        if (!chatDoc.exists) {
          await FirebaseFirestore.instance
              .collection('chats')
              .doc(chatRoomId)
              .set({
                'participants': [currentUser!.uid, recipientId],
                'isGroup': false,
                'createdAt': FieldValue.serverTimestamp(),
                'lastMessage': '',
                'lastMessageTimestamp': FieldValue.serverTimestamp(),
                'lastMessageSenderId': currentUser!.uid,
              });
        }
      }

      final selectedList = _selectedMessages.toList();
      final batchSize = 10;
      List<QueryDocumentSnapshot> allMessageDocs = [];

      for (int i = 0; i < selectedList.length; i += batchSize) {
        final batch = selectedList.skip(i).take(batchSize).toList();
        final messagesSnapshot = await FirebaseFirestore.instance
            .collection('chats')
            .doc(widget.chatRoomId)
            .collection('messages')
            .where(FieldPath.documentId, whereIn: batch)
            .get();
        allMessageDocs.addAll(messagesSnapshot.docs);
      }

      String lastMessageText = '';
      for (var doc in allMessageDocs) {
        final data = doc.data() as Map<String, dynamic>;
        final forwardedMessageData = {
          'text': data['text'] ?? '',
          'senderId': currentUser!.uid,
          'timestamp': FieldValue.serverTimestamp(),
          'isPinned': false,
          'isStarred': false,
          'isDeleted': false,
          'isEdited': false,
          'reactions': [],
          'isForwarded': true,
          'forwardedFrom':
              widget.otherUser['name'] ??
              (widget.isGroup ? widget.otherUser['groupName'] : 'Someone'),
          'forwardedBy': currentUser!.uid,
          'forwardedByName': currentUserName,
          if (isGroup)
            'senderName':
                currentUserName, // NEW: Add sender name for group forwards
          if (data['imageUrl'] != null) 'imageUrl': data['imageUrl'],
        };

        await FirebaseFirestore.instance
            .collection('chats')
            .doc(chatRoomId)
            .collection('messages')
            .add(forwardedMessageData);

        if (lastMessageText.isEmpty) {
          lastMessageText = (data['text'] as String?) ?? '📷 Media';
        }
      }

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatRoomId)
          .update({
            'lastMessage': lastMessageText,
            'lastMessageTimestamp': FieldValue.serverTimestamp(),
            'lastMessageSenderId': currentUser!.uid,
          });

      if (mounted) {
        final messageCount = _selectedMessages.length;
        setState(() {
          _selectedMessages.clear();
          _isSelectionMode = false;
        });
        _showSnackBar(
          '${messageCount > 1 ? "$messageCount messages" : "Message"} forwarded to $recipientName',
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to forward messages: $e', isError: true);
      }
    }
  }

  Future<void> _copyToClipboard(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      if (mounted) {
        _showSnackBar('Copied to clipboard');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to copy', isError: true);
      }
    }
  }

  void _addReaction(Message message, String emoji) async {
    try {
      final reactions = List<String>.from(message.reactions);

      if (reactions.contains(emoji)) {
        reactions.remove(emoji);
      } else {
        reactions.add(emoji);
      }

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatRoomId)
          .collection('messages')
          .doc(message.id)
          .update({'reactions': reactions});
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error: $e', isError: true);
      }
    }
  }

  void _showReactionPicker(Message message) {
    if (!mounted) return;

    const quickReactions = ['❤️', '👍', '😂', '😮', '😢', '🙏', '🔥', '👏'];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'React to Message',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: quickReactions.map((emoji) {
                  final isSelected = message.reactions.contains(emoji);
                  return InkWell(
                    onTap: () {
                      Navigator.pop(modalContext);
                      _addReaction(message, emoji);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF1565C0).withOpacity(0.3)
                            : Colors.white.withOpacity(0.05),
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(
                                color: const Color(0xFF1565C0),
                                width: 2,
                              )
                            : null,
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 32)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _togglePinMessage(String messageId, bool currentStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatRoomId)
          .collection('messages')
          .doc(messageId)
          .update({'isPinned': !currentStatus});

      if (mounted) {
        _showSnackBar(currentStatus ? 'Message unpinned' : 'Message pinned');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error: $e', isError: true);
      }
    }
  }

  Future<void> _toggleStarMessage(String messageId, bool currentStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatRoomId)
          .collection('messages')
          .doc(messageId)
          .update({'isStarred': !currentStatus});

      if (mounted) {
        _showSnackBar(currentStatus ? 'Message unstarred' : 'Message starred');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error: $e', isError: true);
      }
    }
  }

  Future<void> _deleteMessageForMe(String messageId) async {
    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatRoomId)
          .collection('messages')
          .doc(messageId)
          .delete();

      if (mounted) {
        _showSnackBar('Message deleted');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error: $e', isError: true);
      }
    }
  }

  Future<void> _deleteMessageForEveryone(String messageId) async {
    if (currentUser == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatRoomId)
          .collection('messages')
          .doc(messageId)
          .update({
            'isDeleted': true,
            'deletedBy': currentUser!.uid,
            'text': 'This message was deleted',
            'imageUrl': FieldValue.delete(),
          });

      if (mounted) {
        _showSnackBar('Message deleted for everyone');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error: $e', isError: true);
      }
    }
  }

  void _reportMessage(String messageId) async {
    if (currentUser == null) return;

    try {
      await FirebaseFirestore.instance.collection('reports').add({
        'messageId': messageId,
        'chatRoomId': widget.chatRoomId,
        'reportedBy': currentUser!.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        _showSnackBar('Message reported successfully');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error: $e', isError: true);
      }
    }
  }

  void _showEditMessageDialog(Message message) {
    if (!mounted) return;

    final TextEditingController editController = TextEditingController(
      text: message.text,
    );

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(
          'Edit Message',
          style: GoogleFonts.inter(color: Colors.white),
        ),
        content: TextField(
          controller: editController,
          style: GoogleFonts.inter(color: Colors.white),
          maxLines: null,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Edit your message',
            hintStyle: GoogleFonts.inter(color: Colors.white54),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF1565C0)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () async {
              final newText = editController.text.trim();
              if (newText.isNotEmpty && newText != message.text) {
                try {
                  await FirebaseFirestore.instance
                      .collection('chats')
                      .doc(widget.chatRoomId)
                      .collection('messages')
                      .doc(message.id)
                      .update({
                        'text': newText,
                        'isEdited': true,
                        'editedTimestamp': FieldValue.serverTimestamp(),
                      });
                  if (mounted) {
                    Navigator.pop(dialogContext);
                    _showSnackBar('Message edited successfully');
                  }
                } catch (e) {
                  if (mounted) {
                    _showSnackBar('Failed to edit message', isError: true);
                  }
                }
              } else {
                Navigator.pop(dialogContext);
              }
            },
            child: Text(
              'Save',
              style: GoogleFonts.inter(color: const Color(0xFF1565C0)),
            ),
          ),
        ],
      ),
    );
  }

  void _showStarredMessages() {
    if (currentUser == null || !mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StarredMessagesPage(
          chatRoomId: widget.chatRoomId,
          currentUserId: currentUser!.uid,
        ),
      ),
    );
  }

  void _showPinnedMessages() {
    if (currentUser == null || !mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PinnedMessagesPage(
          chatRoomId: widget.chatRoomId,
          currentUserId: currentUser!.uid,
        ),
      ),
    );
  }

  void _showMessageOptions(Message message) {
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Message Options',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white24, height: 1),
              _buildMenuItem(
                icon: Icons.reply,
                title: 'Reply',
                onTap: () {
                  Navigator.pop(modalContext);
                  _replyToMessage(message);
                },
              ),
              if (message.text.isNotEmpty && !message.isDeleted)
                _buildMenuItem(
                  icon: Icons.copy,
                  title: 'Copy',
                  onTap: () {
                    Navigator.pop(modalContext);
                    _copyToClipboard(message.text);
                  },
                ),
              _buildMenuItem(
                icon: Icons.add_reaction_outlined,
                title: 'React',
                onTap: () {
                  Navigator.pop(modalContext);
                  _showReactionPicker(message);
                },
              ),
              _buildMenuItem(
                icon: Icons.forward,
                title: 'Forward',
                onTap: () {
                  Navigator.pop(modalContext);
                  setState(() {
                    _selectedMessages.clear();
                    _selectedMessages.add(message.id);
                    _isSelectionMode = true;
                  });
                  _forwardMessages();
                },
              ),
              _buildMenuItem(
                icon: Icons.select_all,
                title: 'Select Multiple',
                onTap: () {
                  Navigator.pop(modalContext);
                  _toggleMessageSelection(message.id);
                },
              ),
              _buildMenuItem(
                icon: message.isPinned
                    ? Icons.push_pin_outlined
                    : Icons.push_pin,
                title: message.isPinned ? 'Unpin' : 'Pin',
                onTap: () {
                  Navigator.pop(modalContext);
                  _togglePinMessage(message.id, message.isPinned);
                },
              ),
              _buildMenuItem(
                icon: message.isStarred ? Icons.star : Icons.star_outline,
                title: message.isStarred ? 'Unstar' : 'Star',
                onTap: () {
                  Navigator.pop(modalContext);
                  _toggleStarMessage(message.id, message.isStarred);
                },
              ),
              const Divider(color: Colors.white24, height: 1),
              _buildMenuItem(
                icon: Icons.report_outlined,
                title: 'Report',
                color: Colors.red,
                onTap: () {
                  Navigator.pop(modalContext);
                  _showReportMessageDialog(message.id);
                },
              ),
              if (message.isSentByMe && !message.isDeleted)
                _buildMenuItem(
                  icon: Icons.edit,
                  title: 'Edit',
                  onTap: () {
                    Navigator.pop(modalContext);
                    _showEditMessageDialog(message);
                  },
                ),
              _buildMenuItem(
                icon: Icons.delete,
                title: 'Delete',
                color: Colors.red,
                onTap: () {
                  Navigator.pop(modalContext);
                  _showDeleteOptions(message);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: color == Colors.white ? Colors.white70 : color,
        size: 22,
      ),
      title: Text(title, style: GoogleFonts.inter(color: color, fontSize: 15)),
      onTap: onTap,
      visualDensity: VisualDensity.compact,
    );
  }

  void _showReportMessageDialog(String messageId) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(
          'Report Message?',
          style: GoogleFonts.inter(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to report this message?',
          style: GoogleFonts.inter(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _reportMessage(messageId);
            },
            child: Text('Report', style: GoogleFonts.inter(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showDeleteOptions(Message message) {
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Delete Message',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white24, height: 1),
            ListTile(
              leading: const Icon(
                Icons.delete_outline,
                color: Colors.red,
                size: 22,
              ),
              title: Text(
                'Delete for Me',
                style: GoogleFonts.inter(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(modalContext);
                _deleteMessageForMe(message.id);
              },
            ),
            if (message.isSentByMe)
              ListTile(
                leading: const Icon(
                  Icons.delete_sweep,
                  color: Colors.red,
                  size: 22,
                ),
                title: Text(
                  'Delete for Everyone',
                  style: GoogleFonts.inter(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(modalContext);
                  _showDeleteForEveryoneDialog(message.id);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showDeleteForEveryoneDialog(String messageId) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(
          'Delete for Everyone?',
          style: GoogleFonts.inter(color: Colors.white),
        ),
        content: Text(
          'This will remove the message for everyone in the chat.',
          style: GoogleFonts.inter(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _deleteMessageForEveryone(messageId);
            },
            child: Text('Delete', style: GoogleFonts.inter(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showContactInfo() {
    if (currentUser == null || !mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContactInfoPage(
          user: widget.otherUser,
          isGroup: widget.isGroup,
          chatRoomId: widget.chatRoomId,
          currentUserId: currentUser!.uid,
        ),
      ),
    );
  }

  void _showChatOptions() {
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Chat Options',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(modalContext),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white24, height: 1),
              _buildMenuItem(
                icon: Icons.info_outline,
                title: 'View Contact Info',
                onTap: () {
                  Navigator.pop(modalContext);
                  _showContactInfo();
                },
              ),
              _buildMenuItem(
                icon: Icons.push_pin,
                title: 'Pinned Messages',
                onTap: () {
                  Navigator.pop(modalContext);
                  _showPinnedMessages();
                },
              ),
              _buildMenuItem(
                icon: Icons.star,
                title: 'Starred Messages',
                onTap: () {
                  Navigator.pop(modalContext);
                  _showStarredMessages();
                },
              ),
              _buildMenuItem(
                icon: Icons.search,
                title: 'Search Messages',
                onTap: () {
                  Navigator.pop(modalContext);
                  _toggleSearch();
                },
              ),
              const Divider(color: Colors.white24, height: 1),
              _buildMenuItem(
                icon: Icons.report_outlined,
                title: 'Report ${widget.otherUser['name'] ?? 'User'}',
                color: Colors.red,
                onTap: () {
                  Navigator.pop(modalContext);
                  _showReportUserDialog();
                },
              ),
              _buildMenuItem(
                icon: Icons.block,
                title: 'Block ${widget.otherUser['name'] ?? 'User'}',
                color: Colors.red,
                onTap: () {
                  Navigator.pop(modalContext);
                  _showBlockUserDialog();
                },
              ),
              _buildMenuItem(
                icon: Icons.delete_outline,
                title: 'Delete chat',
                color: Colors.red,
                onTap: () {
                  Navigator.pop(modalContext);
                  _showDeleteChatDialog();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showReportUserDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(
          'Report ${widget.otherUser['name'] ?? 'User'}?',
          style: GoogleFonts.inter(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to report this user?',
          style: GoogleFonts.inter(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () async {
              if (currentUser == null) return;

              Navigator.pop(dialogContext);
              final otherUserId = widget.otherUser['id'];
              if (otherUserId == null) return;

              try {
                await FirebaseFirestore.instance.collection('reports').add({
                  'reportedUserId': otherUserId,
                  'reportedBy': currentUser!.uid,
                  'timestamp': FieldValue.serverTimestamp(),
                });
                if (mounted) {
                  _showSnackBar('User reported successfully');
                }
              } catch (e) {
                if (mounted) {
                  _showSnackBar('Failed to report user', isError: true);
                }
              }
            },
            child: Text('Report', style: GoogleFonts.inter(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showBlockUserDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(
          'Block ${widget.otherUser['name'] ?? 'User'}?',
          style: GoogleFonts.inter(color: Colors.white),
        ),
        content: Text(
          'Blocked users cannot send you messages.',
          style: GoogleFonts.inter(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () async {
              if (currentUser == null) return;

              Navigator.pop(dialogContext);
              final otherUserId = widget.otherUser['id'];
              if (otherUserId == null) return;

              try {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(currentUser!.uid)
                    .update({
                      'blockedUsers': FieldValue.arrayUnion([otherUserId]),
                    });
                if (mounted) {
                  _showSnackBar('User blocked successfully');
                }
              } catch (e) {
                if (mounted) {
                  _showSnackBar('Failed to block user', isError: true);
                }
              }
            },
            child: Text('Block', style: GoogleFonts.inter(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showDeleteChatDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(
          'Delete Chat?',
          style: GoogleFonts.inter(color: Colors.white),
        ),
        content: Text(
          'Delete chat history on your device only? The other person will still have the chat.',
          style: GoogleFonts.inter(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              if (currentUser == null) return;

              try {
                final messages = await FirebaseFirestore.instance
                    .collection('chats')
                    .doc(widget.chatRoomId)
                    .collection('messages')
                    .get();

                final batch = FirebaseFirestore.instance.batch();

                for (var doc in messages.docs) {
                  batch.update(doc.reference, {
                    'deletedFor': FieldValue.arrayUnion([currentUser!.uid]),
                  });
                }

                await batch.commit();

                await FirebaseFirestore.instance
                    .collection('chats')
                    .doc(widget.chatRoomId)
                    .update({
                      'deletedFor': FieldValue.arrayUnion([currentUser!.uid]),
                    });

                if (mounted) {
                  _showSnackBar('Chat deleted successfully');
                  Navigator.pop(context);
                }
              } catch (e) {
                if (mounted) {
                  _showSnackBar('Error: ${e.toString()}', isError: true);
                }
              }
            },
            child: Text('Delete', style: GoogleFonts.inter(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildChatAppBar(),
      body: GestureDetector(
        onTap: () {
          if (_showEmojiPicker) {
            setState(() => _showEmojiPicker = false);
          }
        },
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black, Color(0xFF0A0A0A), Colors.black],
            ),
          ),
          child: Column(
            children: [
              if (_showSearchBar) _buildSearchBar(),
              if (_isSelectionMode) _buildSelectionBar(),
              Expanded(child: _buildMessagesList()),
              if (_isUploading) _buildUploadingIndicator(),
              if (_replyingTo != null) _buildReplyBar(),
              _ChatInputBar(
                messageController: _messageController,
                onSendPressed: _sendMessage,
                showSendButton: _showSendButton,
                onEmojiPressed: _toggleEmojiPicker,
                showEmojiPicker: _showEmojiPicker,
              ),
              if (_showEmojiPicker) _buildEmojiPicker(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: _cancelSelection,
            splashRadius: 24,
          ),
          const SizedBox(width: 8),
          Text(
            '${_selectedMessages.length} selected',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.forward, color: Colors.white),
            onPressed: _forwardMessages,
            tooltip: 'Forward',
            splashRadius: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildReplyBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        border: Border(top: BorderSide(color: Colors.white24)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Replying to ${_replyingTo!.isSentByMe ? 'yourself' : widget.otherUser['name'] ?? 'User'}',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF1565C0),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _replyingTo!.text.length > 50
                      ? '${_replyingTo!.text.substring(0, 50)}...'
                      : _replyingTo!.text,
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white70),
            onPressed: _cancelReply,
            splashRadius: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.inter(color: Colors.white),
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'Search messages...',
          hintStyle: GoogleFonts.inter(color: Colors.white54),
          prefixIcon: const Icon(Icons.search, color: Colors.white70),
          suffixIcon: IconButton(
            icon: const Icon(Icons.close, color: Colors.white70),
            onPressed: _toggleSearch,
          ),
          filled: true,
          fillColor: const Color(0xFF2A2A2A),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        onChanged: (value) {
          setState(() => _searchQuery = value.toLowerCase());
        },
      ),
    );
  }

  Widget _buildMessagesList() {
    if (currentUser == null) {
      return const Center(
        child: Text(
          'Authentication error',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatRoomId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading messages',
              style: GoogleFonts.inter(color: Colors.red),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1565C0)),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 64,
                  color: Colors.white.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'Say hello! 👋',
                  style: GoogleFonts.inter(color: Colors.white54, fontSize: 18),
                ),
              ],
            ),
          );
        }

        var messages = snapshot.data!.docs;

        messages = messages.where((doc) {
          final data = doc.data() as Map<String, dynamic>?;
          final deletedFor = data?['deletedFor'];
          if (deletedFor != null && deletedFor is List) {
            return !deletedFor.contains(currentUser!.uid);
          }
          return true;
        }).toList();

        if (_searchQuery.isNotEmpty) {
          messages = messages.where((doc) {
            final data = doc.data() as Map<String, dynamic>?;
            return (data?['text']?.toString() ?? '').toLowerCase().contains(
              _searchQuery,
            );
          }).toList();

          if (messages.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off, size: 64, color: Colors.white54),
                  const SizedBox(height: 16),
                  Text(
                    'No messages found',
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }
        }

        return ListView.builder(
          controller: _scrollController,
          reverse: true,
          padding: const EdgeInsets.all(8),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final doc = messages[index];
            final data = doc.data() as Map<String, dynamic>?;

            if (data == null) return const SizedBox.shrink();

            final message = Message.fromMap(doc.id, data, currentUser!.uid);

            final bool showDateSeparator =
                index == messages.length - 1 ||
                (index < messages.length - 1 &&
                    _shouldShowDateSeparator(
                      message.timestamp,
                      (messages[index + 1].data()
                          as Map<String, dynamic>?)?['timestamp'],
                    ));

            final bool showNowSeparator =
                index == 0 &&
                DateTime.now().difference(message.timestamp).inMinutes < 1;

            return Column(
              children: [
                if (showNowSeparator)
                  _DateSeparator(date: message.timestamp, isNow: true)
                else if (showDateSeparator)
                  _DateSeparator(date: message.timestamp),

                // UPDATED: Pass isGroup flag to MessageBubble
                _MessageBubble(
                  key: ValueKey(message.id),
                  message: message,
                  isGroup: widget.isGroup, // NEW
                  onLongPress: () {
                    if (_isSelectionMode) {
                      _toggleMessageSelection(message.id);
                    } else {
                      _showMessageOptions(message);
                    }
                  },
                  onTap: () {
                    if (_isSelectionMode) {
                      _toggleMessageSelection(message.id);
                    } else {
                      _showMessageOptions(message);
                    }
                  },
                  isSelected: _selectedMessages.contains(message.id),
                  isSelectionMode: _isSelectionMode,
                ),
              ],
            );
          },
        );
      },
    );
  }

  bool _shouldShowDateSeparator(
    DateTime currentDate,
    dynamic previousTimestamp,
  ) {
    if (previousTimestamp == null) return true;

    try {
      final previousDate = (previousTimestamp as Timestamp).toDate();
      return currentDate.day != previousDate.day ||
          currentDate.month != previousDate.month ||
          currentDate.year != previousDate.year;
    } catch (e) {
      return false;
    }
  }

  Widget _buildUploadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1565C0)),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Uploading image...',
            style: GoogleFonts.inter(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildEmojiPicker() {
    return Container(
      height: 250,
      color: const Color(0xFF1A1A1A),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Emojis',
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () {
                    setState(() => _showEmojiPicker = false);
                  },
                  splashRadius: 24,
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: kCommonEmojis.length,
              itemBuilder: (context, index) {
                return InkWell(
                  onTap: () => _onEmojiSelected(kCommonEmojis[index]),
                  borderRadius: BorderRadius.circular(8),
                  child: Center(
                    child: Text(
                      kCommonEmojis[index],
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  AppBar _buildChatAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF1A1A1A),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new,
          color: Colors.white,
          size: 20,
        ),
        onPressed: () => Navigator.pop(context),
        splashRadius: 24,
      ),
      titleSpacing: 0,
      title: GestureDetector(
        onTap: _showContactInfo,
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white.withOpacity(0.1),
              backgroundImage: widget.otherUser['photoUrl'] != null
                  ? NetworkImage(widget.otherUser['photoUrl']!)
                  : null,
              child: widget.otherUser['photoUrl'] == null
                  ? Icon(
                      widget.isGroup ? Icons.group : Icons.person,
                      color: Colors.white54,
                      size: 20,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUser['name']?.toString() ??
                        widget.otherUser['groupName']?.toString() ??
                        'User',
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (!widget.isGroup)
                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(widget.otherUser['id'])
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || !snapshot.data!.exists) {
                          return Text(
                            "offline",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          );
                        }
                        final data =
                            snapshot.data!.data() as Map<String, dynamic>;
                        final isOnline = data['isOnline'] ?? false;
                        final lastSeen = data['lastSeen'] as Timestamp?;
                        if (isOnline) {
                          return Text(
                            "online",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.green,
                            ),
                          );
                        } else if (lastSeen != null) {
                          final lastSeenDate = lastSeen.toDate();
                          final now = DateTime.now();
                          final difference = now.difference(lastSeenDate);
                          String status;
                          if (difference.inMinutes < 1) {
                            status = 'online';
                          } else if (difference.inHours < 1) {
                            status = 'Last seen today';
                          } else if (difference.inDays < 1) {
                            status =
                                'Last seen ${DateFormat('h:mm a').format(lastSeenDate)}';
                          } else {
                            status =
                                'Last seen ${DateFormat('MMM d').format(lastSeenDate)}';
                          }
                          return Text(
                            status,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          );
                        } else {
                          return Text(
                            "offline",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          );
                        }
                      },
                    )
                  else
                    Text(
                      "group chat",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.white, size: 22),
          onPressed: _showChatOptions,
          splashRadius: 24,
        ),
      ],
    );
  }
}

// MESSAGE BUBBLE - UPDATED to show sender name in groups
class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool isGroup; // NEW
  final VoidCallback onLongPress;
  final VoidCallback onTap;
  final bool isSelected;
  final bool isSelectionMode;

  const _MessageBubble({
    super.key,
    required this.message,
    required this.isGroup, // NEW
    required this.onLongPress,
    required this.onTap,
    this.isSelected = false,
    this.isSelectionMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isMe = message.isSentByMe;

    if (message.isDeleted) {
      return Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.block, color: Colors.white54, size: 16),
              const SizedBox(width: 8),
              Text(
                'This message was deleted',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white54,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onLongPress: onLongPress,
      onTap: onTap,
      child: Column(
        children: [
          if (message.isPinned || message.isStarred)
            Padding(
              padding: const EdgeInsets.only(bottom: 4, left: 8, right: 8),
              child: Row(
                mainAxisAlignment: isMe
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.start,
                children: [
                  if (message.isPinned)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.amber.withOpacity(0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.push_pin,
                            size: 10,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Pinned',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              color: Colors.amber,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (message.isPinned && message.isStarred)
                    const SizedBox(width: 6),
                  if (message.isStarred)
                    const Icon(Icons.star, size: 14, color: Colors.amber),
                ],
              ),
            ),
          Align(
            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: Row(
              mainAxisAlignment: isMe
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (isSelectionMode)
                  Padding(
                    padding: const EdgeInsets.only(right: 8, left: 8),
                    child: Icon(
                      isSelected ? Icons.check_circle : Icons.circle_outlined,
                      color: isSelected
                          ? const Color(0xFF1565C0)
                          : Colors.white54,
                      size: 24,
                    ),
                  ),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 8,
                    ),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isMe
                          ? const Color(0xFF1565C0)
                          : const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: isMe
                            ? const Radius.circular(18)
                            : const Radius.circular(4),
                        bottomRight: isMe
                            ? const Radius.circular(4)
                            : const Radius.circular(18),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // NEW: Show sender name in group chats
                        if (isGroup && !isMe && message.senderName != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              message.senderName!,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF64B5F6),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        if (message.isForwarded)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.forward,
                                  size: 14,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  message.forwardedByName != null
                                      ? 'Forwarded by ${message.forwardedByName}'
                                      : 'Forwarded',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: Colors.white.withOpacity(0.7),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (message.replyToText != null)
                          Container(
                            padding: const EdgeInsets.all(8),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: const Border(
                                left: BorderSide(
                                  color: Color(0xFF1565C0),
                                  width: 3,
                                ),
                              ),
                            ),
                            child: Text(
                              message.replyToText!.length > 50
                                  ? '${message.replyToText!.substring(0, 50)}...'
                                  : message.replyToText!,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.white70,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        if (message.imageUrl != null)
                          Container(
                            constraints: const BoxConstraints(
                              maxWidth: 250,
                              maxHeight: 300,
                            ),
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                message.imageUrl!,
                                fit: BoxFit.cover,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        height: 150,
                                        color: Colors.white.withOpacity(0.1),
                                        child: const Center(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Color(0xFF1565C0),
                                          ),
                                        ),
                                      );
                                    },
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: 150,
                                    color: Colors.white.withOpacity(0.1),
                                    child: const Center(
                                      child: Icon(
                                        Icons.broken_image,
                                        color: Colors.white54,
                                        size: 48,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        if (message.text.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              message.text,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        if (message.reactions.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 4, bottom: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Wrap(
                              spacing: 4,
                              children: message.reactions
                                  .map(
                                    (emoji) => Text(
                                      emoji,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (message.isEdited) ...[
                              Text(
                                'Edited • ',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: Colors.white.withOpacity(0.5),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                            Text(
                              DateFormat('h:mm a').format(message.timestamp),
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// DATE SEPARATOR
class _DateSeparator extends StatelessWidget {
  final DateTime date;
  final bool isNow;

  const _DateSeparator({super.key, required this.date, this.isNow = false});

  String _getDisplayDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat.yMMMd().format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String displayDate = isNow ? 'Now' : _getDisplayDate(date);

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        margin: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Text(
          displayDate,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.white70,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// CHAT INPUT BAR
class _ChatInputBar extends StatelessWidget {
  final TextEditingController messageController;
  final VoidCallback onSendPressed;
  final bool showSendButton;
  final VoidCallback onEmojiPressed;
  final bool showEmojiPicker;

  const _ChatInputBar({
    required this.messageController,
    required this.onSendPressed,
    required this.showSendButton,
    required this.onEmojiPressed,
    required this.showEmojiPicker,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        showEmojiPicker
                            ? Icons.keyboard
                            : Icons.emoji_emotions_outlined,
                        color: Colors.white70,
                        size: 22,
                      ),
                      onPressed: onEmojiPressed,
                      splashRadius: 24,
                    ),
                    Expanded(
                      child: TextField(
                        controller: messageController,
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
                        onTap: () {
                          if (showEmojiPicker) onEmojiPressed();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 24,
              backgroundColor: showSendButton
                  ? const Color(0xFF1565C0)
                  : Colors.white.withOpacity(0.15),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: showSendButton ? onSendPressed : null,
                splashRadius: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// STARRED MESSAGES PAGE
class StarredMessagesPage extends StatelessWidget {
  final String chatRoomId;
  final String currentUserId;

  const StarredMessagesPage({
    super.key,
    required this.chatRoomId,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(
          'Starred Messages',
          style: GoogleFonts.inter(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
          onPressed: () => Navigator.pop(context),
          splashRadius: 24,
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .doc(chatRoomId)
            .collection('messages')
            .where('isStarred', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF1565C0)),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading starred messages',
                    style: GoogleFonts.inter(color: Colors.red, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.star_outline,
                    size: 64,
                    color: Colors.white54,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No starred messages',
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Star important messages to find them easily',
                    style: GoogleFonts.inter(
                      color: Colors.white38,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>?;

              if (data == null) return const SizedBox.shrink();

              final message = Message.fromMap(doc.id, data, currentUserId);

              return Card(
                color: const Color(0xFF1A1A1A),
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: const Icon(
                    Icons.star,
                    color: Colors.amber,
                    size: 24,
                  ),
                  title: Text(
                    message.text.isNotEmpty
                        ? message.text
                        : message.imageUrl != null
                        ? '📷 Photo'
                        : 'Message',
                    style: GoogleFonts.inter(color: Colors.white),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    DateFormat('MMM d, h:mm a').format(message.timestamp),
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white38,
                    size: 16,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// PINNED MESSAGES PAGE
class PinnedMessagesPage extends StatelessWidget {
  final String chatRoomId;
  final String currentUserId;

  const PinnedMessagesPage({
    super.key,
    required this.chatRoomId,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(
          'Pinned Messages',
          style: GoogleFonts.inter(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
          onPressed: () => Navigator.pop(context),
          splashRadius: 24,
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .doc(chatRoomId)
            .collection('messages')
            .where('isPinned', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF1565C0)),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading pinned messages',
                    style: GoogleFonts.inter(color: Colors.red, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.push_pin_outlined,
                    size: 64,
                    color: Colors.white54,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No pinned messages',
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pin important messages to find them easily',
                    style: GoogleFonts.inter(
                      color: Colors.white38,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>?;

              if (data == null) return const SizedBox.shrink();

              final message = Message.fromMap(doc.id, data, currentUserId);

              return Card(
                color: const Color(0xFF1A1A1A),
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: const Icon(
                    Icons.push_pin,
                    color: Colors.amber,
                    size: 24,
                  ),
                  title: Text(
                    message.text.isNotEmpty
                        ? message.text
                        : message.imageUrl != null
                        ? '📷 Photo'
                        : 'Message',
                    style: GoogleFonts.inter(color: Colors.white),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    DateFormat('MMM d, h:mm a').format(message.timestamp),
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white38,
                    size: 16,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// CONTACT INFO PAGE - EDIT ABOUT FOR BOTH PERSONAL AND GROUP
class ContactInfoPage extends StatefulWidget {
  final Map<String, dynamic> user;
  final bool isGroup;
  final String chatRoomId;
  final String currentUserId;

  const ContactInfoPage({
    super.key,
    required this.user,
    required this.isGroup,
    required this.chatRoomId,
    required this.currentUserId,
  });

  @override
  State<ContactInfoPage> createState() => _ContactInfoPageState();
}

class _ContactInfoPageState extends State<ContactInfoPage> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Edit group description
  Future<void> _editGroupAbout(String currentAbout) async {
    final TextEditingController aboutController = TextEditingController(
      text: currentAbout,
    );

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(
          'Edit About',
          style: GoogleFonts.inter(color: Colors.white),
        ),
        content: TextField(
          controller: aboutController,
          style: GoogleFonts.inter(color: Colors.white),
          maxLines: 3,
          maxLength: 200,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Enter group description',
            hintStyle: GoogleFonts.inter(color: Colors.white54),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF1565C0)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () async {
              final newAbout = aboutController.text.trim();
              if (newAbout.isNotEmpty && newAbout != currentAbout) {
                try {
                  await FirebaseFirestore.instance
                      .collection('chats')
                      .doc(widget.chatRoomId)
                      .update({'groupDescription': newAbout});

                  if (mounted) {
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('About updated successfully'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to update: $e'),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                }
              } else {
                Navigator.pop(dialogContext);
              }
            },
            child: Text(
              'Save',
              style: GoogleFonts.inter(color: const Color(0xFF1565C0)),
            ),
          ),
        ],
      ),
    );
  }

  // Edit personal about
  Future<void> _editPersonalAbout(String currentAbout) async {
    final TextEditingController aboutController = TextEditingController(
      text: currentAbout,
    );

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(
          'Edit About',
          style: GoogleFonts.inter(color: Colors.white),
        ),
        content: TextField(
          controller: aboutController,
          style: GoogleFonts.inter(color: Colors.white),
          maxLines: 3,
          maxLength: 200,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Enter your status',
            hintStyle: GoogleFonts.inter(color: Colors.white54),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF1565C0)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () async {
              final newAbout = aboutController.text.trim();
              if (newAbout.isNotEmpty && newAbout != currentAbout) {
                try {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(widget.currentUserId)
                      .update({'about': newAbout});

                  if (mounted) {
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('About updated successfully'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to update: $e'),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                }
              } else {
                Navigator.pop(dialogContext);
              }
            },
            child: Text(
              'Save',
              style: GoogleFonts.inter(color: const Color(0xFF1565C0)),
            ),
          ),
        ],
      ),
    );
  }

  // NEW: Add member function restored
  Future<void> _showAddMemberDialog(List<String> currentMembers) async {
    try {
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where(FieldPath.documentId, isNotEqualTo: widget.currentUserId)
          .get();

      final availableUsers = usersSnapshot.docs
          .where((doc) => !currentMembers.contains(doc.id))
          .toList();

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        backgroundColor: const Color(0xFF1A1A1A),
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (modalContext) => StatefulBuilder(
          builder: (context, setModalState) => DraggableScrollableSheet(
            initialChildSize: 0.75,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) => Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Add Members',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white24, height: 1),
                Expanded(
                  child: availableUsers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 64,
                                color: Colors.white.withOpacity(0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No users to add',
                                style: GoogleFonts.inter(color: Colors.white54),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: availableUsers.length,
                          itemBuilder: (context, index) {
                            final userDoc = availableUsers[index];
                            final userData = userDoc.data();
                            final userName = userData['name'] ?? 'Unknown';
                            final userEmail = userData['email'] ?? '';

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.grey.shade700,
                                backgroundImage: userData['photoUrl'] != null
                                    ? NetworkImage(userData['photoUrl'])
                                    : null,
                                child: userData['photoUrl'] == null
                                    ? const Icon(
                                        Icons.person,
                                        color: Colors.white,
                                        size: 20,
                                      )
                                    : null,
                              ),
                              title: Text(
                                userName,
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: Text(
                                userEmail,
                                style: GoogleFonts.inter(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () async {
                                Navigator.pop(modalContext);
                                await _addMemberToGroup(userDoc.id, userData);
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading users: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // NEW: Add member to group function
  Future<void> _addMemberToGroup(
    String userId,
    Map<String, dynamic> userData,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatRoomId)
          .update({
            'participants': FieldValue.arrayUnion([userId]),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${userData['name'] ?? 'User'} added to group'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add member: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(
          'Contact Info',
          style: GoogleFonts.inter(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
          onPressed: () => Navigator.pop(context),
          splashRadius: 24,
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 40),
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.grey.shade700,
              backgroundImage: widget.user['photoUrl'] != null
                  ? NetworkImage(widget.user['photoUrl'])
                  : null,
              child: widget.user['photoUrl'] == null
                  ? Icon(
                      widget.isGroup ? Icons.group : Icons.person,
                      size: 50,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(height: 20),
            Text(
              widget.user['name']?.toString() ??
                  widget.user['groupName']?.toString() ??
                  'Unknown',
              style: GoogleFonts.inter(
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.user['email']?.toString() ??
                  widget.user['phone']?.toString() ??
                  'No contact info',
              style: GoogleFonts.inter(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 40),
            const Divider(color: Colors.white24),

            // About section - EDIT FOR BOTH GROUPS AND PERSONAL
            if (widget.isGroup)
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('chats')
                    .doc(widget.chatRoomId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return ListTile(
                      leading: const Icon(
                        Icons.info_outline,
                        color: Colors.white70,
                        size: 22,
                      ),
                      title: Text(
                        'About',
                        style: GoogleFonts.inter(color: Colors.white),
                      ),
                      subtitle: Text(
                        'Loading...',
                        style: GoogleFonts.inter(color: Colors.white54),
                      ),
                    );
                  }

                  final data = snapshot.data!.data() as Map<String, dynamic>?;
                  final groupDescription =
                      data?['groupDescription'] ??
                      'Hey there! This is a group.';
                  final createdBy = data?['createdBy'] as String? ?? '';
                  final isAdmin = createdBy == widget.currentUserId;

                  return ListTile(
                    leading: const Icon(
                      Icons.info_outline,
                      color: Colors.white70,
                      size: 22,
                    ),
                    title: Text(
                      'About',
                      style: GoogleFonts.inter(color: Colors.white),
                    ),
                    subtitle: Text(
                      groupDescription,
                      style: GoogleFonts.inter(color: Colors.white54),
                    ),
                    trailing: isAdmin
                        ? IconButton(
                            icon: const Icon(
                              Icons.edit,
                              color: Colors.white70,
                              size: 20,
                            ),
                            onPressed: () => _editGroupAbout(groupDescription),
                            splashRadius: 24,
                          )
                        : null,
                  );
                },
              )
            else
              // Personal chat - Edit own about
              // Personal chat - Edit own about
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(widget.currentUserId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return ListTile(
                      leading: const Icon(
                        Icons.info_outline,
                        color: Colors.white70,
                        size: 22,
                      ),
                      title: Text(
                        'About',
                        style: GoogleFonts.inter(color: Colors.white),
                      ),
                      subtitle: Text(
                        'Loading...',
                        style: GoogleFonts.inter(color: Colors.white54),
                      ),
                    );
                  }

                  final currentUserData =
                      snapshot.data!.data() as Map<String, dynamic>?;
                  final currentUserAbout =
                      currentUserData?['about'] ??
                      'Hey there! I am using this app.';

                  return ListTile(
                    leading: const Icon(
                      Icons.info_outline,
                      color: Colors.white70,
                      size: 22,
                    ),
                    title: Text(
                      'About',
                      style: GoogleFonts.inter(color: Colors.white),
                    ),
                    subtitle: Text(
                      widget.user['about']?.toString() ??
                          'Hey there! I am using this app.',
                      style: GoogleFonts.inter(color: Colors.white54),
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.edit,
                        color: Colors.white70,
                        size: 20,
                      ),
                      onPressed: () => _editPersonalAbout(currentUserAbout),
                      splashRadius: 24,
                    ),
                  ); // <- This closing parenthesis was missing
                },
              ),
            if (!widget.isGroup) ...[
              const Divider(color: Colors.white24),
              ListTile(
                leading: const Icon(
                  Icons.phone,
                  color: Colors.white70,
                  size: 22,
                ),
                title: Text(
                  'Phone',
                  style: GoogleFonts.inter(color: Colors.white),
                ),
                subtitle: Text(
                  widget.user['phone']?.toString() ?? 'Not available',
                  style: GoogleFonts.inter(color: Colors.white54),
                ),
              ),
              ListTile(
                leading: const Icon(
                  Icons.email,
                  color: Colors.white70,
                  size: 22,
                ),
                title: Text(
                  'Email',
                  style: GoogleFonts.inter(color: Colors.white),
                ),
                subtitle: Text(
                  widget.user['email']?.toString() ?? 'Not available',
                  style: GoogleFonts.inter(color: Colors.white54),
                ),
              ),
            ],
            if (widget.isGroup) ...[
              const Divider(color: Colors.white24),
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('chats')
                    .doc(widget.chatRoomId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF1565C0),
                      ),
                    );
                  }

                  final data = snapshot.data!.data() as Map<String, dynamic>?;
                  if (data == null) return const SizedBox.shrink();

                  final participants =
                      (data['participants'] as List<dynamic>?)
                          ?.cast<String>() ??
                      [];
                  final createdBy = data['createdBy'] as String? ?? '';
                  final createdAt = data['createdAt'] as Timestamp?;
                  final isAdmin = createdBy == widget.currentUserId;

                  return Column(
                    children: [
                      if (createdBy.isNotEmpty)
                        FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('users')
                              .doc(createdBy)
                              .get(),
                          builder: (context, userSnapshot) {
                            String creatorName = 'Unknown';

                            if (userSnapshot.connectionState ==
                                ConnectionState.done) {
                              if (userSnapshot.hasData &&
                                  userSnapshot.data!.exists) {
                                final userData =
                                    userSnapshot.data!.data()
                                        as Map<String, dynamic>?;
                                creatorName = userData?['name'] ?? 'Unknown';
                              } else if (createdBy == widget.currentUserId) {
                                creatorName = 'You';
                              }
                            }

                            return ListTile(
                              leading: const Icon(
                                Icons.person_outline,
                                color: Colors.white70,
                                size: 22,
                              ),
                              title: Text(
                                'Created By',
                                style: GoogleFonts.inter(color: Colors.white),
                              ),
                              subtitle: Text(
                                creatorName,
                                style: GoogleFonts.inter(color: Colors.white54),
                              ),
                            );
                          },
                        ),
                      if (createdAt != null)
                        ListTile(
                          leading: const Icon(
                            Icons.calendar_today,
                            color: Colors.white70,
                            size: 22,
                          ),
                          title: Text(
                            'Created On',
                            style: GoogleFonts.inter(color: Colors.white),
                          ),
                          subtitle: Text(
                            DateFormat('MMMM d, y').format(createdAt.toDate()),
                            style: GoogleFonts.inter(color: Colors.white54),
                          ),
                        ),
                      const Divider(color: Colors.white24),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Members (${participants.length})',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (participants.length > 5)
                              IconButton(
                                icon: Icon(
                                  _searchQuery.isEmpty
                                      ? Icons.search
                                      : Icons.close,
                                  color: Colors.white70,
                                  size: 22,
                                ),
                                onPressed: () {
                                  setState(() {
                                    if (_searchQuery.isEmpty) {
                                      _searchQuery = ' ';
                                    } else {
                                      _searchQuery = '';
                                      _searchController.clear();
                                    }
                                  });
                                },
                                splashRadius: 24,
                              ),
                          ],
                        ),
                      ),
                      if (_searchQuery.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: TextField(
                            controller: _searchController,
                            style: GoogleFonts.inter(color: Colors.white),
                            autofocus: true,
                            decoration: InputDecoration(
                              hintText: 'Search members...',
                              hintStyle: GoogleFonts.inter(
                                color: Colors.white54,
                              ),
                              prefixIcon: const Icon(
                                Icons.search,
                                color: Colors.white70,
                              ),
                              filled: true,
                              fillColor: const Color(0xFF2A2A2A),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                            ),
                            onChanged: (value) {
                              setState(
                                () => _searchQuery = value.toLowerCase(),
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 8),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: participants.length,
                        itemBuilder: (context, index) {
                          final participantId = participants[index];
                          final isCurrentUser =
                              participantId == widget.currentUserId;

                          return FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('users')
                                .doc(participantId)
                                .get(),
                            builder: (context, userSnapshot) {
                              if (userSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.grey.shade700,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white54,
                                    ),
                                  ),
                                  title: Text(
                                    'Loading...',
                                    style: GoogleFonts.inter(
                                      color: Colors.white54,
                                    ),
                                  ),
                                );
                              }

                              if (!userSnapshot.hasData ||
                                  !userSnapshot.data!.exists) {
                                return const SizedBox.shrink();
                              }

                              final userData =
                                  userSnapshot.data!.data()
                                      as Map<String, dynamic>?;
                              if (userData == null) {
                                return const SizedBox.shrink();
                              }

                              final name = userData['name'] ?? 'Unknown';
                              final email = userData['email'] ?? '';

                              if (_searchQuery.isNotEmpty &&
                                  _searchQuery.trim().isNotEmpty) {
                                final query = _searchQuery.toLowerCase();
                                if (!name.toLowerCase().contains(query) &&
                                    !email.toLowerCase().contains(query)) {
                                  return const SizedBox.shrink();
                                }
                              }

                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.grey.shade700,
                                  backgroundImage: userData['photoUrl'] != null
                                      ? NetworkImage(userData['photoUrl'])
                                      : null,
                                  child: userData['photoUrl'] == null
                                      ? const Icon(
                                          Icons.person,
                                          color: Colors.white,
                                          size: 20,
                                        )
                                      : null,
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        isCurrentUser ? 'You' : name,
                                        style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontWeight: isCurrentUser
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                    if (participantId == createdBy)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFF1565C0,
                                          ).withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: const Color(0xFF1565C0),
                                          ),
                                        ),
                                        child: Text(
                                          'Admin',
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            color: const Color(0xFF1565C0),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                subtitle: Text(
                                  email,
                                  style: GoogleFonts.inter(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: isAdmin && !isCurrentUser
                                    ? PopupMenuButton<String>(
                                        icon: const Icon(
                                          Icons.more_vert,
                                          color: Colors.white70,
                                        ),
                                        color: const Color(0xFF1A1A1A),
                                        onSelected: (value) async {
                                          if (value == 'remove') {
                                            final confirm = await showDialog<bool>(
                                              context: context,
                                              builder: (dialogContext) =>
                                                  AlertDialog(
                                                    backgroundColor:
                                                        const Color(0xFF1A1A1A),
                                                    title: Text(
                                                      'Remove Member?',
                                                      style: GoogleFonts.inter(
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                    content: Text(
                                                      'Are you sure you want to remove $name from this group?',
                                                      style: GoogleFonts.inter(
                                                        color: Colors.white70,
                                                      ),
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                              dialogContext,
                                                              false,
                                                            ),
                                                        child: Text(
                                                          'Cancel',
                                                          style:
                                                              GoogleFonts.inter(
                                                                color: Colors
                                                                    .white70,
                                                              ),
                                                        ),
                                                      ),
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                              dialogContext,
                                                              true,
                                                            ),
                                                        child: Text(
                                                          'Remove',
                                                          style:
                                                              GoogleFonts.inter(
                                                                color:
                                                                    Colors.red,
                                                              ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                            );

                                            if (confirm == true) {
                                              try {
                                                await FirebaseFirestore.instance
                                                    .collection('chats')
                                                    .doc(widget.chatRoomId)
                                                    .update({
                                                      'participants':
                                                          FieldValue.arrayRemove(
                                                            [participantId],
                                                          ),
                                                    });

                                                if (mounted) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        '$name removed from group',
                                                      ),
                                                      backgroundColor:
                                                          Colors.green,
                                                      duration: const Duration(
                                                        seconds: 2,
                                                      ),
                                                    ),
                                                  );
                                                }
                                              } catch (e) {
                                                if (mounted) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        'Failed to remove member: $e',
                                                      ),
                                                      backgroundColor:
                                                          Colors.red,
                                                      duration: const Duration(
                                                        seconds: 2,
                                                      ),
                                                    ),
                                                  );
                                                }
                                              }
                                            }
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          PopupMenuItem(
                                            value: 'remove',
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.person_remove,
                                                  color: Colors.red,
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 12),
                                                Text(
                                                  'Remove from group',
                                                  style: GoogleFonts.inter(
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      )
                                    : null,
                              );
                            },
                          );
                        },
                      ),
                      if (isAdmin) ...[
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: ElevatedButton.icon(
                            onPressed: () {
                              _showAddMemberDialog(participants);
                            },
                            icon: const Icon(Icons.person_add),
                            label: Text(
                              'Add Members',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1565C0),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      if (!isAdmin)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (dialogContext) => AlertDialog(
                                  backgroundColor: const Color(0xFF1A1A1A),
                                  title: Text(
                                    'Leave Group?',
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                    ),
                                  ),
                                  content: Text(
                                    'Are you sure you want to leave this group?',
                                    style: GoogleFonts.inter(
                                      color: Colors.white70,
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(dialogContext, false),
                                      child: Text(
                                        'Cancel',
                                        style: GoogleFonts.inter(
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(dialogContext, true),
                                      child: Text(
                                        'Leave',
                                        style: GoogleFonts.inter(
                                          color: Colors.red,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                try {
                                  await FirebaseFirestore.instance
                                      .collection('chats')
                                      .doc(widget.chatRoomId)
                                      .update({
                                        'participants': FieldValue.arrayRemove([
                                          widget.currentUserId,
                                        ]),
                                      });

                                  if (mounted) {
                                    Navigator.pop(context);
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Left group successfully',
                                        ),
                                        backgroundColor: Colors.green,
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Failed to leave: $e'),
                                        backgroundColor: Colors.red,
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                            icon: const Icon(Icons.exit_to_app),
                            label: Text(
                              'Leave Group',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade700,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 32),
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
