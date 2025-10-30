import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';

// Color Scheme
const _backgroundColor = Color(0xFF000000);
const _cardColor = Color(0xFF1A1A1A);
const _surfaceColor = Color(0xFF2C2C2E);
const _primaryTextColor = Color(0xFFFFFFFF);
const _secondaryTextColor = Color(0xFF8A8A8E);
const _myMessageColor = Color(0xFF3A3A3C);
const _otherMessageColor = Color(0xFF2C2C2E);

// Common Emojis
const List<String> kCommonEmojis = [
  '😀',
  '😃',
  '😄',
  '😁',
  '😆',
  '😅',
  '🤣',
  '😂',
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
  '😝',
  '🤑',
  '🤗',
  '🤭',
  '🤫',
  '🤔',
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
  '🔥',
  '💘',
  '💝',
  '💟',
  '🎉',
  '🎊',
  '🎈',
  '🎁',
  '🏆',
  '⭐',
];

// Message Model
class Message {
  final String id;
  final String text;
  final DateTime timestamp;
  final bool isSentByMe;
  final bool isRead;
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

  Message({
    required this.id,
    required this.text,
    required this.timestamp,
    required this.isSentByMe,
    this.isRead = false,
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
      isRead: data['isRead'] == true,
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

  final ValueNotifier<bool> _showSendButtonNotifier = ValueNotifier<bool>(
    false,
  );
  bool _showEmojiPicker = false;
  bool _isUploading = false;
  bool _showSearchBar = false;
  String _searchQuery = '';
  Message? _replyingTo;

  // State for multi-select
  bool _isSelectionMode = false;
  List<Message> _selectedMessages = [];

  @override
  void initState() {
    super.initState();
    _messageController.addListener(() {
      _showSendButtonNotifier.value = _messageController.text.trim().isNotEmpty;
    });
    _markMessagesAsRead();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    _showSendButtonNotifier.dispose();
    super.dispose();
  }

  // --- Multi-Select Methods ---
  void _enableSelectionMode(Message message) {
    if (mounted) {
      setState(() {
        _isSelectionMode = true;
        _selectedMessages.add(message);
      });
    }
  }

  void _disableSelectionMode() {
    if (mounted) {
      setState(() {
        _isSelectionMode = false;
        _selectedMessages.clear();
      });
    }
  }

  void _toggleMessageSelection(Message message) {
    if (mounted) {
      setState(() {
        if (_selectedMessages.any((m) => m.id == message.id)) {
          _selectedMessages.removeWhere((m) => m.id == message.id);
          if (_selectedMessages.isEmpty) {
            _isSelectionMode = false;
          }
        } else {
          _selectedMessages.add(message);
        }
      });
    }
  }

  void _forwardSelectedMessages() {
    if (!mounted || _selectedMessages.isEmpty) return;

    // TODO: Implement navigation to a contact selection screen
    // For now, we'll just show a confirmation and clear the selection.
    final count = _selectedMessages.length;
    _showSnackBar('Forwarding $count message(s)... (Not Implemented)');
    _disableSelectionMode();
  }

  void _deleteSelectedMessages() {
    if (!mounted || _selectedMessages.isEmpty) return;

    // In a real app, you would show a confirmation dialog here.
    for (var message in _selectedMessages) {
      _deleteMessageForMe(message.id);
    }
    _showSnackBar('${_selectedMessages.length} messages deleted');
    _disableSelectionMode();
  }

  Future<void> _markMessagesAsRead() async {
    if (currentUser == null) return;
    try {
      final messages = await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatRoomId)
          .collection('messages')
          .where('isRead', isEqualTo: false)
          .get();

      final unreadMessages = messages.docs.where((doc) {
        final data = doc.data();
        return data['senderId'] != currentUser!.uid;
      }).toList();

      for (var doc in unreadMessages) {
        await doc.reference.update({'isRead': true});
      }
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  Future<void> _sendMessage({String? imageUrl}) async {
    if (currentUser == null) return;

    final text = _messageController.text.trim();
    if (text.isEmpty && imageUrl == null) return;

    _messageController.clear();
    // No longer need to manually set _showSendButton to false.
    // The listener on the controller handles it automatically.

    final messageData = {
      'text': text,
      'senderId': currentUser!.uid,
      'timestamp': FieldValue.serverTimestamp(),
      'isPinned': false,
      'isStarred': false,
      'isRead': false,
      'isDeleted': false,
      'isEdited': false,
      'reactions': [],
      'isForwarded': false,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (_replyingTo != null) ...{
        'replyToId': _replyingTo!.id,
        'replyToText': _replyingTo!.text,
      },
    };

    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatRoomId)
          .collection('messages')
          .add(messageData);

      String lastMsg = text.isNotEmpty
          ? text
          : imageUrl != null
          ? '📷 Photo'
          : '';

      final otherUserId = widget.otherUser['id'];
      if (otherUserId != null) {
        await FirebaseFirestore.instance
            .collection('chats')
            .doc(widget.chatRoomId)
            .set({
              'participants': [currentUser!.uid, otherUserId],
              'lastMessage': lastMsg,
              'lastMessageTimestamp': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
      }

      if (mounted) setState(() => _replyingTo = null);
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

      if (mounted) setState(() => _isUploading = true);

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

      if (mounted) _showSnackBar('Image sent successfully');
    } catch (e) {
      if (mounted) _showSnackBar('Error uploading image: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showImageSourceDialog() {
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: _cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Choose Photo Source',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (!foundation.kIsWeb) ...[
                ListTile(
                  leading: const Icon(
                    Icons.photo_library,
                    color: Colors.white70,
                    size: 28,
                  ),
                  title: Text(
                    'Gallery',
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
                  ),
                  onTap: () {
                    Navigator.pop(modalContext);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.camera_alt,
                    color: Colors.white70,
                    size: 28,
                  ),
                  title: Text(
                    'Camera',
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
                  ),
                  onTap: () {
                    Navigator.pop(modalContext);
                    _pickImage(ImageSource.camera);
                  },
                ),
              ] else ...[
                ListTile(
                  leading: const Icon(
                    Icons.photo_library,
                    color: Colors.white70,
                    size: 28,
                  ),
                  title: Text(
                    'Choose Image',
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
                  ),
                  onTap: () {
                    Navigator.pop(modalContext);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _toggleEmojiPicker() {
    if (mounted) setState(() => _showEmojiPicker = !_showEmojiPicker);
  }

  void _onEmojiSelected(String emoji) {
    _messageController.text += emoji;
    _messageController.selection = TextSelection.fromPosition(
      TextPosition(offset: _messageController.text.length),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : _surfaceColor,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _toggleSearch() {
    if (mounted) {
      setState(() {
        _showSearchBar = !_showSearchBar;
        if (!_showSearchBar) {
          _searchController.clear();
          _searchQuery = '';
        }
      });
    }
  }

  void _replyToMessage(Message message) {
    if (mounted) {
      setState(() => _replyingTo = message);
      FocusScope.of(context).requestFocus(FocusNode());
    }
  }

  void _cancelReply() {
    if (mounted) setState(() => _replyingTo = null);
  }

  Future<void> _copyToClipboard(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      if (mounted) _showSnackBar('Copied to clipboard');
    } catch (e) {
      if (mounted) _showSnackBar('Failed to copy', isError: true);
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
      if (mounted) _showSnackBar('Error: $e', isError: true);
    }
  }

  void _showReactionPicker(Message message) {
    if (!mounted) return;
    const quickReactions = ['❤️', '👍', '😂', '😮', '😢', '🙏', '🔥', '👏'];

    showModalBottomSheet(
      context: context,
      backgroundColor: _cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                            ? _secondaryTextColor.withOpacity(0.3)
                            : Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: _secondaryTextColor, width: 2)
                            : null,
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 32)),
                    ),
                  );
                }).toList(),
              ),
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
      if (mounted) _showSnackBar('Error: $e', isError: true);
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
      if (mounted) _showSnackBar('Error: $e', isError: true);
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
      // Don't show snackbar here if called from multi-delete
    } catch (e) {
      if (mounted) _showSnackBar('Error: $e', isError: true);
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
      if (mounted) _showSnackBar('Message deleted for everyone');
    } catch (e) {
      if (mounted) _showSnackBar('Error: $e', isError: true);
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
        backgroundColor: _cardColor,
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
              borderSide: BorderSide(color: _secondaryTextColor),
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
              style: GoogleFonts.inter(color: _secondaryTextColor),
            ),
          ),
        ],
      ),
    );
  }

  void _showMessageOptions(Message message) {
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: _cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'Message Options',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(color: Colors.white24),
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
                const Divider(color: Colors.white24),
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
              ],
            ),
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
    Widget? trailing,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: color == Colors.white ? Colors.white70 : color,
      ),
      title: Text(title, style: GoogleFonts.inter(color: color)),
      trailing: trailing,
      onTap: onTap,
    );
  }

  void _showDeleteOptions(Message message) {
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: _cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Delete Message',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: Text(
                  'Delete for Me',
                  style: GoogleFonts.inter(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(modalContext);
                  _deleteMessageForMe(message.id);
                  _showSnackBar('Message deleted');
                },
              ),
              if (message.isSentByMe)
                ListTile(
                  leading: const Icon(Icons.delete_sweep, color: Colors.red),
                  title: Text(
                    'Delete for Everyone',
                    style: GoogleFonts.inter(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(modalContext);
                    _showDeleteForEveryoneDialog(message.id);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteForEveryoneDialog(String messageId) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _cardColor,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _isSelectionMode ? _buildSelectionAppBar() : _buildChatAppBar(),
      body: GestureDetector(
        onTap: () {
          if (_showEmojiPicker && mounted) {
            setState(() => _showEmojiPicker = false);
          }
        },
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black, Color(0xFF111111), Colors.black],
            ),
          ),
          child: Column(
            children: [
              if (_showSearchBar) _buildSearchBar(),
              Expanded(child: _buildMessagesList()),
              if (_isUploading) _buildUploadingIndicator(),
              if (_replyingTo != null) _buildReplyBar(),
              _ChatInputBar(
                messageController: _messageController,
                onSendPressed: _sendMessage,
                showSendButtonNotifier: _showSendButtonNotifier,
                onEmojiPressed: _toggleEmojiPicker,
                onAttachPressed: _showImageSourceDialog,
                showEmojiPicker: _showEmojiPicker,
              ),
              if (_showEmojiPicker) _buildEmojiPicker(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReplyBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: _cardColor,
        border: Border(top: BorderSide(color: Colors.white24)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: _secondaryTextColor,
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
                    color: _secondaryTextColor,
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
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _cardColor,
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
          fillColor: _surfaceColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        onChanged: (value) {
          if (mounted) setState(() => _searchQuery = value.toLowerCase());
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
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
            final isSelected = _selectedMessages.any((m) => m.id == message.id);

            final bool showDateSeparator =
                index == messages.length - 1 ||
                (index < messages.length - 1 &&
                    _shouldShowDateSeparator(
                      message.timestamp,
                      (messages[index + 1].data()
                          as Map<String, dynamic>?)?['timestamp'],
                    ));

            return Column(
              children: [
                if (showDateSeparator) _DateSeparator(date: message.timestamp),
                _MessageBubble(
                  key: ValueKey(message.id),
                  message: message,
                  isSelected: isSelected,
                  onLongPress: () {
                    if (!_isSelectionMode) {
                      _enableSelectionMode(message);
                    }
                  },
                  onTap: () {
                    if (_isSelectionMode) {
                      _toggleMessageSelection(message);
                    } else {
                      _showMessageOptions(message);
                    }
                  },
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
        color: _cardColor,
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
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
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
      color: _cardColor,
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
                    if (mounted) setState(() => _showEmojiPicker = false);
                  },
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

  void _showChatOptionsMenu() {
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: _cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Chat Options',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(color: Colors.white24),
                _buildMenuItem(
                  icon: Icons.star_outline,
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
                _buildMenuItem(
                  icon: Icons.info_outline,
                  title: 'View Info',
                  onTap: () {
                    Navigator.pop(modalContext);
                    _showContactInfo();
                  },
                ),
                _buildMenuItem(
                  icon: Icons.delete_sweep_outlined,
                  title: 'Clear Chat',
                  color: Colors.red,
                  onTap: () {
                    Navigator.pop(modalContext);
                    _showClearChatDialog();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showStarredMessages() {
    if (!mounted) return;
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

  void _showContactInfo() {
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: _cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: _secondaryTextColor.withOpacity(0.2),
                backgroundImage: widget.otherUser['photoUrl'] != null
                    ? NetworkImage(widget.otherUser['photoUrl'])
                    : null,
                child: widget.otherUser['photoUrl'] == null
                    ? Icon(
                        widget.isGroup ? Icons.group : Icons.person,
                        size: 50,
                        color: _secondaryTextColor,
                      )
                    : null,
              ),
              const SizedBox(height: 16),
              Text(
                widget.otherUser['name']?.toString() ?? 'User',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              if (!widget.isGroup && widget.otherUser['email'] != null)
                Text(
                  widget.otherUser['email'],
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: _secondaryTextColor,
                  ),
                ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(modalContext),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryTextColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  'Close',
                  style: GoogleFonts.inter(
                    color: _backgroundColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showClearChatDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _cardColor,
        title: Text(
          'Clear Chat?',
          style: GoogleFonts.inter(color: Colors.white),
        ),
        content: Text(
          'This will delete all messages in this conversation.',
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
              try {
                final messages = await FirebaseFirestore.instance
                    .collection('chats')
                    .doc(widget.chatRoomId)
                    .collection('messages')
                    .get();
                for (var doc in messages.docs) {
                  await doc.reference.delete();
                }
                if (mounted) _showSnackBar('Chat cleared successfully');
              } catch (e) {
                if (mounted) {
                  _showSnackBar('Error: ${e.toString()}', isError: true);
                }
              }
            },
            child: Text('Clear', style: GoogleFonts.inter(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  AppBar _buildSelectionAppBar() {
    return AppBar(
      backgroundColor: _surfaceColor,
      elevation: 4,
      leading: IconButton(
        icon: const Icon(Icons.close, color: Colors.white),
        onPressed: _disableSelectionMode,
      ),
      title: Text(
        '${_selectedMessages.length} selected',
        style: GoogleFonts.inter(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(
            Icons.reply,
            color: _secondaryTextColor,
          ), // Using reply icon for forward
          tooltip: 'Forward',
          onPressed: _forwardSelectedMessages,
        ),
        IconButton(
          icon: const Icon(Icons.delete, color: _secondaryTextColor),
          tooltip: 'Delete',
          onPressed: _deleteSelectedMessages,
        ),
      ],
    );
  }

  AppBar _buildChatAppBar() {
    return AppBar(
      backgroundColor: _cardColor,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        onPressed: () {
          if (mounted) Navigator.pop(context);
        },
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
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUser['name']?.toString() ?? 'User',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    "online", // Placeholder
                    style: GoogleFonts.inter(
                      fontSize: 13,
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
          icon: const Icon(Icons.search, color: _secondaryTextColor),
          onPressed: _toggleSearch,
        ),
        IconButton(
          icon: const Icon(Icons.more_vert, color: _secondaryTextColor),
          onPressed: _showChatOptionsMenu,
        ),
      ],
    );
  }
}

// Starred Messages Page
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
        backgroundColor: _cardColor,
        title: Text(
          'Starred Messages',
          style: GoogleFonts.inter(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
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
              .doc(chatRoomId)
              .collection('messages')
              .where('isStarred', isEqualTo: true)
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }

            if (snapshot.hasError) {
              debugPrint('Starred messages error: ${snapshot.error}');
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading messages.',
                        style: GoogleFonts.inter(
                          color: Colors.red,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'This usually requires a Firestore index. Please check your debug console for a link to create it.',
                        style: GoogleFonts.inter(
                          color: Colors.white54,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
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
                      'Long press a message to star it\nand find it easily later.',
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
                  color: _cardColor,
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
      ),
    );
  }
}

// MESSAGE BUBBLE WIDGET
class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool isSelected;
  final VoidCallback onLongPress;
  final VoidCallback onTap;

  const _MessageBubble({
    super.key,
    required this.message,
    required this.isSelected,
    required this.onLongPress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isMe = message.isSentByMe;

    if (message.isDeleted) {
      return Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Card(
          elevation: 1,
          color: _surfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
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
        ),
      );
    }

    return GestureDetector(
      onLongPress: onLongPress,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        color: isSelected
            ? _secondaryTextColor.withOpacity(0.3)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          children: [
            if (message.isPinned || message.isStarred)
              Padding(
                padding: const EdgeInsets.only(bottom: 4, left: 16, right: 16),
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
                          color: _secondaryTextColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _secondaryTextColor.withOpacity(0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.push_pin,
                              size: 10,
                              color: _secondaryTextColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Pinned',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                color: _secondaryTextColor,
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
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                child: Card(
                  elevation: 2,
                  color: isMe ? _myMessageColor : _otherMessageColor,
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
                  margin: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 8,
                  ),
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 40, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
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
                                      'Forwarded',
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
                                      color: _secondaryTextColor,
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
                                          if (loadingProgress == null)
                                            return child;
                                          return Container(
                                            height: 150,
                                            color: Colors.white.withOpacity(
                                              0.1,
                                            ),
                                            child: const Center(
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
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
                                margin: const EdgeInsets.only(
                                  top: 4,
                                  bottom: 4,
                                ),
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
                                  DateFormat(
                                    'h:mm a',
                                  ).format(message.timestamp),
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: Colors.white.withOpacity(0.6),
                                  ),
                                ),
                                if (isMe) ...[
                                  const SizedBox(width: 4),
                                  Icon(
                                    message.isRead
                                        ? Icons.done_all
                                        : Icons.done,
                                    color: message.isRead
                                        ? Colors.blueAccent
                                        : Colors.white.withOpacity(0.6),
                                    size: 16,
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (!isSelected)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: InkWell(
                            onTap: onTap,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.keyboard_arrow_down,
                                color: Colors.white.withOpacity(0.7),
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// DATE SEPARATOR
class _DateSeparator extends StatelessWidget {
  final DateTime date;
  const _DateSeparator({required this.date});

  @override
  Widget build(BuildContext context) {
    String displayDate;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      displayDate = 'Today';
    } else if (messageDate == yesterday) {
      displayDate = 'Yesterday';
    } else {
      displayDate = DateFormat.yMMMd().format(date);
    }

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        margin: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: _cardColor,
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
  final ValueNotifier<bool> showSendButtonNotifier;
  final VoidCallback onEmojiPressed;
  final VoidCallback onAttachPressed;
  final bool showEmojiPicker;

  const _ChatInputBar({
    required this.messageController,
    required this.onSendPressed,
    required this.showSendButtonNotifier,
    required this.onEmojiPressed,
    required this.onAttachPressed,
    required this.showEmojiPicker,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _cardColor,
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
                  color: _surfaceColor,
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
                      ),
                      onPressed: onEmojiPressed,
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
                    IconButton(
                      icon: const Icon(
                        Icons.attach_file,
                        color: Colors.white70,
                      ),
                      onPressed: onAttachPressed,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            ValueListenableBuilder<bool>(
              valueListenable: showSendButtonNotifier,
              builder: (context, showSendButton, child) {
                return CircleAvatar(
                  radius: 24,
                  backgroundColor: showSendButton
                      ? _secondaryTextColor
                      : _surfaceColor,
                  child: IconButton(
                    icon: Icon(
                      Icons.send,
                      color: showSendButton ? Colors.white : Colors.white54,
                      size: 22,
                    ),
                    onPressed: showSendButton ? onSendPressed : null,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
