import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'chat_page.dart';

class ChatHomePage extends StatefulWidget {
  const ChatHomePage({super.key});

  @override
  State<ChatHomePage> createState() => _ChatHomePageState();
}

class _ChatHomePageState extends State<ChatHomePage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  List<Map<String, dynamic>> _allUsers = [];
  bool _isLoading = true;
  String _filterType = 'all';

  @override
  void initState() {
    super.initState();
    _fetchAllUsers();
  }

  Future<void> _fetchAllUsers() async {
    if (currentUser == null) return;
    setState(() => _isLoading = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();
      final users = snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .where((user) => user['id'] != currentUser!.uid)
          .toList();
      if (mounted) setState(() => _allUsers = users);
    } catch (e) {
      if (mounted) _showSnackBar('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter(color: Colors.white)),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _navigateToChat(Map<String, dynamic> otherUser) {
    if (currentUser == null) return;
    List<String> ids = [currentUser!.uid, otherUser['id']]..sort();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(
          chatRoomId: ids.join('_'),
          otherUser: otherUser,
          isGroup: false,
        ),
      ),
    );
  }

  Future<void> _archiveChat(String chatId, {bool unarchive = false}) async {
    if (currentUser == null) return;
    await FirebaseFirestore.instance.collection('chats').doc(chatId).update({
      'archivedBy.${currentUser!.uid}': !unarchive,
    });

    if (!unarchive && mounted) {
      _showSnackBar('Chat archived.');
    }
  }

  Future<bool> _confirmDeleteChat(
    String chatId,
    bool isGroup,
    String? createdBy,
    String chatName,
  ) async {
    if (isGroup && createdBy != currentUser!.uid) {
      _showSnackBar('Only group creator can delete', isError: true);
      return false;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.delete_outline,
                color: Colors.red,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isGroup ? 'Delete Group?' : 'Delete Chat?',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          isGroup
              ? 'This will permanently delete the group for all members.'
              : 'Are you sure you want to permanently delete this conversation?',
          style: GoogleFonts.inter(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final msgs = await FirebaseFirestore.instance
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .get();
        for (var doc in msgs.docs) {
          await doc.reference.delete();
        }
        await FirebaseFirestore.instance
            .collection('chats')
            .doc(chatId)
            .delete();
        if (mounted) _showSnackBar(isGroup ? 'Group deleted' : 'Chat deleted');
        return true;
      } catch (e) {
        if (mounted) _showSnackBar('Error: $e', isError: true);
        return false;
      }
    }
    return false;
  }

  void _navigateToGroupChat() {
    final groupNameController = TextEditingController();
    final memberSearchController = TextEditingController();
    final List<String> selectedMembers = [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final filteredUsers = memberSearchController.text.isEmpty
              ? _allUsers
              : _allUsers.where((user) {
                  final query = memberSearchController.text.toLowerCase();
                  return (user['name'] as String? ?? '').toLowerCase().contains(
                        query,
                      ) ||
                      (user['email'] as String? ?? '').toLowerCase().contains(
                        query,
                      );
                }).toList();

          return AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.group_add,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Create Group',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: groupNameController,
                    style: GoogleFonts.inter(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Enter group name',
                      hintStyle: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.5),
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      prefixIcon: Icon(
                        Icons.people,
                        color: Colors.white.withOpacity(0.7),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: memberSearchController,
                    style: GoogleFonts.inter(color: Colors.white),
                    onChanged: (v) => setDialogState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search members...',
                      hintStyle: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.5),
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.white.withOpacity(0.7),
                      ),
                      suffixIcon: memberSearchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear,
                                color: Colors.white.withOpacity(0.7),
                              ),
                              onPressed: () {
                                memberSearchController.clear();
                                setDialogState(() {});
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (selectedMembers.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.people,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${selectedMembers.length} member${selectedMembers.length > 1 ? 's' : ''} selected',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 300),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            )
                          : filteredUsers.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.people_outline,
                                      size: 48,
                                      color: Colors.white.withOpacity(0.5),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No members found',
                                      style: GoogleFonts.inter(
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: filteredUsers.length,
                              itemBuilder: (context, index) {
                                final user = filteredUsers[index];
                                final isSelected = selectedMembers.contains(
                                  user['id'],
                                );
                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.white.withOpacity(0.1)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: CheckboxListTile(
                                    value: isSelected,
                                    onChanged: (v) => setDialogState(() {
                                      if (v == true) {
                                        selectedMembers.add(user['id']);
                                      } else {
                                        selectedMembers.remove(user['id']);
                                      }
                                    }),
                                    title: Text(
                                      user['name'] ?? 'No Name',
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    subtitle: Text(
                                      user['email'] ?? '',
                                      style: GoogleFonts.inter(
                                        color: Colors.white.withOpacity(0.6),
                                        fontSize: 12,
                                      ),
                                    ),
                                    secondary: CircleAvatar(
                                      backgroundColor: Colors.white.withOpacity(
                                        0.2,
                                      ),
                                      backgroundImage: user['photoUrl'] != null
                                          ? NetworkImage(user['photoUrl'])
                                          : null,
                                      child: user['photoUrl'] == null
                                          ? Text(
                                              (user['name'] ?? 'U')[0]
                                                  .toUpperCase(),
                                              style: GoogleFonts.inter(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            )
                                          : null,
                                    ),
                                    activeColor: Colors.white,
                                    checkColor: Colors.black,
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.inter(
                    color: Colors.white.withOpacity(0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (groupNameController.text.trim().isEmpty) {
                    _showSnackBar('Enter group name', isError: true);
                    return;
                  }
                  if (selectedMembers.isEmpty) {
                    _showSnackBar('Select at least one member', isError: true);
                    return;
                  }
                  Navigator.pop(context);
                  await _createGroup(
                    groupNameController.text.trim(),
                    selectedMembers,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  'Create',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _createGroup(String groupName, List<String> memberIds) async {
    if (currentUser == null) return;
    try {
      await FirebaseFirestore.instance.collection('chats').add({
        'groupName': groupName,
        'participants': [currentUser!.uid, ...memberIds],
        'isGroup': true,
        'createdBy': currentUser!.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': 'Group created',
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
        'lastMessageSenderId': currentUser!.uid,
      });
      if (mounted) _showSnackBar('Group "$groupName" created!');
    } catch (e) {
      if (mounted) _showSnackBar('Error: $e', isError: true);
    }
  }

  void _navigateToGroupChatPage(
    String groupId,
    String groupName,
    List<dynamic> participants,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(
          chatRoomId: groupId,
          otherUser: {
            'id': groupId,
            'name': groupName,
            'isGroup': true,
            'participants': participants,
          },
          isGroup: true,
        ),
      ),
    );
  }

  Widget _buildChatsList({required Function(Map<String, dynamic>) onUserTap}) {
    if (currentUser == null) {
      return Center(
        child: Text(
          "Please log in.",
          style: GoogleFonts.inter(color: Colors.white.withOpacity(0.6)),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: currentUser!.uid)
          .orderBy('lastMessageTimestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 80,
                  color: Colors.white.withOpacity(0.3),
                ),
                const SizedBox(height: 24),
                Text(
                  "No conversations yet",
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Start a conversation or create a group",
                  style: GoogleFonts.inter(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        final docsFromStream = snapshot.data!.docs;

        final filteredDocs = docsFromStream.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final isArchived =
              (data['archivedBy']
                  as Map<String, dynamic>?)?[currentUser!.uid] ??
              false;
          if (isArchived) return false;

          final bool isGroup = data['isGroup'] ?? false;
          switch (_filterType) {
            case 'all':
              return true;
            case 'unread':
              return ((data['unreadCount']
                          as Map<String, dynamic>?)?[currentUser!.uid] ??
                      0) >
                  0;
            case 'groups':
              return isGroup;
            case 'personal':
              return !isGroup;
            default:
              return true;
          }
        }).toList();

        if (filteredDocs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.filter_list_off,
                  size: 64,
                  color: Colors.white.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  "No chats in this filter",
                  style: GoogleFonts.inter(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 8.0, bottom: 80.0),
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) => _ChatListItem(
            key: ValueKey(filteredDocs[index].id),
            chatDoc: filteredDocs[index],
            currentUser: currentUser!,
            onUserTap: onUserTap,
            onGroupTap: _navigateToGroupChatPage,
            onConfirmDelete: _confirmDeleteChat,
            onArchive: _archiveChat,
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterType == value;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) setState(() => _filterType = value);
        },
        labelStyle: GoogleFonts.inter(
          color: isSelected ? Colors.black : Colors.white.withOpacity(0.8),
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        backgroundColor: const Color(0xFF2A2A2A),
        selectedColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        showCheckmark: false,
        elevation: isSelected ? 2 : 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        shape: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.2))),
        // MODIFICATION: Added a leading back button
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          "Messages",
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 24, // Adjusted font size for better balance
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black, Color(0xFF111111), Colors.black],
          ),
        ),
        child: Column(
          children: [
            // MODIFICATION: Added padding for spacing
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Container(
                height: 60,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildFilterChip('All', 'all'),
                    _buildFilterChip('Unread', 'unread'),
                    _buildFilterChip('Personal', 'personal'),
                    _buildFilterChip('Groups', 'groups'),
                  ],
                ),
              ),
            ),
            Expanded(child: _buildChatsList(onUserTap: _navigateToChat)),
          ],
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withOpacity(0.25)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: _navigateToGroupChat,
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}

class _ChatListItem extends StatelessWidget {
  final DocumentSnapshot chatDoc;
  final User currentUser;
  final Function(Map<String, dynamic>) onUserTap;
  final Function(String, String, List<dynamic>) onGroupTap;
  final Future<bool> Function(String, bool, String?, String) onConfirmDelete;
  final Function(String) onArchive;

  const _ChatListItem({
    super.key,
    required this.chatDoc,
    required this.currentUser,
    required this.onUserTap,
    required this.onGroupTap,
    required this.onConfirmDelete,
    required this.onArchive,
  });

  @override
  Widget build(BuildContext context) {
    final chatData = chatDoc.data() as Map<String, dynamic>;
    final bool isGroup = chatData['isGroup'] ?? false;
    final int unreadCount =
        (chatData['unreadCount'] as Map<String, dynamic>?)?[currentUser.uid] ??
        0;

    final otherUserId = !isGroup && chatData['participants'] != null
        ? (chatData['participants'] as List).firstWhere(
            (id) => id != currentUser.uid,
            orElse: () => '',
          )
        : '';

    if (!isGroup && otherUserId.isEmpty) return const SizedBox.shrink();

    return FutureBuilder<String>(
      future: _getChatName(isGroup, chatData, otherUserId),
      builder: (context, snapshot) {
        final chatName = snapshot.data ?? (isGroup ? 'Group' : 'Chat');

        // MODIFICATION: Increased vertical padding for more spacing
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Dismissible(
              key: key!,
              background: Container(
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: 20),
                child: const Icon(Icons.archive, color: Colors.white),
              ),
              secondaryBackground: Container(
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              confirmDismiss: (direction) async {
                if (direction == DismissDirection.endToStart) {
                  final createdBy = chatData['createdBy'] as String?;
                  return await onConfirmDelete(
                    chatDoc.id,
                    isGroup,
                    createdBy,
                    chatName,
                  );
                } else {
                  return true;
                }
              },
              onDismissed: (direction) {
                if (direction == DismissDirection.startToEnd) {
                  onArchive(chatDoc.id);
                }
              },
              child: _buildContent(
                context,
                chatData,
                isGroup,
                otherUserId,
                unreadCount,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    Map<String, dynamic> chatData,
    bool isGroup,
    String otherUserId,
    int unreadCount,
  ) {
    final String subtitle = chatData['lastMessage'] ?? '';
    final Timestamp? timestamp = chatData['lastMessageTimestamp'];

    return Container(
      decoration: BoxDecoration(
        color: unreadCount > 0
            ? Colors.white.withOpacity(0.15)
            : const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: _buildAvatar(isGroup, otherUserId, unreadCount),
        title: StreamBuilder<String>(
          stream: _getChatNameStream(isGroup, chatData, otherUserId),
          builder: (context, snapshot) => Text(
            snapshot.data ?? (isGroup ? "Group" : "Chat"),
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.w600,
              fontSize: 16,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: unreadCount > 0
                  ? Colors.white.withOpacity(0.8)
                  : Colors.white.withOpacity(0.6),
              fontSize: 14,
              fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (timestamp != null)
              Text(
                _formatTimestamp(timestamp),
                style: GoogleFonts.inter(
                  color: unreadCount > 0
                      ? Colors.white
                      : Colors.white.withOpacity(0.5),
                  fontSize: 12,
                  fontWeight: unreadCount > 0
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
          ],
        ),
        onTap: () {
          if (isGroup) {
            onGroupTap(
              chatDoc.id,
              chatData['groupName'] ?? 'Group',
              chatData['participants'],
            );
          } else {
            FirebaseFirestore.instance
                .collection('users')
                .doc(otherUserId)
                .get()
                .then((doc) {
                  if (doc.exists) {
                    onUserTap({'id': otherUserId, ...doc.data()!});
                  }
                });
          }
        },
      ),
    );
  }

  Widget _buildAvatar(bool isGroup, String otherUserId, int unreadCount) {
    Widget avatar;
    if (isGroup) {
      avatar = CircleAvatar(
        radius: 28,
        backgroundColor: Colors.green,
        child: const Icon(Icons.group, color: Colors.white, size: 28),
      );
    } else {
      avatar = StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(otherUserId)
            .snapshots(),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData || userSnapshot.data?.data() == null) {
            return CircleAvatar(
              radius: 28,
              backgroundColor: Colors.white.withOpacity(0.1),
            );
          }
          final otherUserData =
              userSnapshot.data!.data() as Map<String, dynamic>;
          final photoUrl = otherUserData['photoUrl'];
          final name =
              otherUserData['name'] ?? otherUserData['username'] ?? 'U';

          return CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withOpacity(0.2),
            backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
            child: photoUrl == null
                ? Text(
                    name[0].toUpperCase(),
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  )
                : null,
          );
        },
      );
    }

    return Stack(
      children: [
        avatar,
        if (unreadCount > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 2),
              ),
              constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
              child: Center(
                child: Text(
                  unreadCount.toString(),
                  style: GoogleFonts.inter(
                    color: Colors.black,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final now = DateTime.now();
    final date = timestamp.toDate();
    final difference = now.difference(date);

    if (difference.inDays == 0) return DateFormat('h:mm a').format(date);
    if (difference.inDays == 1) return 'Yesterday';
    return DateFormat('MM/dd/yy').format(date);
  }

  Future<String> _getChatName(
    bool isGroup,
    Map<String, dynamic> chatData,
    String userId,
  ) async {
    if (isGroup) return chatData['groupName'] ?? 'Unnamed Group';
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (!doc.exists) return 'Unknown User';
      final data = doc.data();
      return data?['name'] ?? data?['username'] ?? 'Unknown User';
    } catch (e) {
      return 'Unknown User';
    }
  }

  Stream<String> _getChatNameStream(
    bool isGroup,
    Map<String, dynamic> chatData,
    String userId,
  ) {
    if (isGroup) return Stream.value(chatData['groupName'] ?? 'Unnamed Group');
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return 'Unknown User';
          final data = doc.data();
          return data?['name'] ?? data?['username'] ?? 'Unknown User';
        });
  }
}
