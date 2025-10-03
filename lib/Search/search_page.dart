import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:v_comm/Search/user_details_popup.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchController = TextEditingController();

  bool _isLoading = true;
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _searchResults = [];
  List<String> _recentSearchQueries = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _searchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterUsers);
    _searchController.dispose();
    super.dispose();
  }

  // --- DATA FETCHING & MANAGEMENT ---
  Future<void> _loadInitialData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    await Future.wait([_fetchAllUsers(), _fetchRecentSearchQueries()]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchAllUsers() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();
      _allUsers = snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      print("Error fetching all users: $e");
    }
  }

  Future<void> _fetchRecentSearchQueries() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      if (doc.exists && doc.data()!.containsKey('searchHistory')) {
        _recentSearchQueries = List<String>.from(doc.data()!['searchHistory']);
      }
    } catch (e) {
      print("Error fetching search history: $e");
    }
  }

  void _filterUsers() {
    setState(() {
      final query = _searchController.text.toLowerCase();
      if (query.isEmpty) {
        _searchResults = [];
      } else {
        _searchResults = _allUsers.where((user) {
          final name = (user['name'] as String? ?? '').toLowerCase();
          final dept = (user['dept'] as String? ?? '').toLowerCase();
          final customId = (user['customId'] as String? ?? '').toLowerCase();
          return name.contains(query) ||
              dept.contains(query) ||
              customId.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _saveSearchQuery(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return;
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    setState(() {
      _recentSearchQueries.remove(trimmedQuery);
      _recentSearchQueries.insert(0, trimmedQuery);
      if (_recentSearchQueries.length > 15) {
        _recentSearchQueries = _recentSearchQueries.sublist(0, 15);
      }
    });

    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .set({'searchHistory': _recentSearchQueries}, SetOptions(merge: true));
  }

  Future<void> _removeSearchQuery(String query) async {
    setState(() {
      _recentSearchQueries.remove(query);
    });
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .update({'searchHistory': _recentSearchQueries});
  }

  Future<void> _clearSearchHistory() async {
    setState(() => _recentSearchQueries = []);
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .update({'searchHistory': []});
  }

  void _showUserDetailsPopup(Map<String, dynamic> userData) {
    _saveSearchQuery(_searchController.text);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => UserDetailsPopup(userData: userData),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasSearchQuery = _searchController.text.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        shape: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.2))),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Search",
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 22,
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
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
                decoration: InputDecoration(
                  hintText: "Search by name, department, or ID...",
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  suffixIcon: hasSearchQuery
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white70),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.5),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : hasSearchQuery
                  ? _buildSearchResults()
                  : _buildSearchHistory(),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildSearchResults() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Search Results",
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                "${_searchResults.length} found",
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: _searchResults.isEmpty
              ? Center(
                  child: Text(
                    "No users found.",
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 16,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchAllUsers,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) =>
                        _buildUserListTile(_searchResults[index]),
                  ),
                ),
        ),
      ],
    );
  }

  // MODIFICATION: This widget is completely redesigned to be a list
  Widget _buildSearchHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Recent Searches",
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (_recentSearchQueries.isNotEmpty)
                TextButton(
                  onPressed: _clearSearchHistory,
                  child: Text(
                    "Clear",
                    style: GoogleFonts.inter(
                      color: Colors.red.shade300,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: _recentSearchQueries.isEmpty
              ? Center(
                  child: Text(
                    "Your search history is empty.",
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _recentSearchQueries.length,
                  itemBuilder: (context, index) {
                    final query = _recentSearchQueries[index];
                    return ListTile(
                      dense: true,
                      leading: Icon(
                        Icons.history,
                        color: Colors.white.withOpacity(0.6),
                      ),
                      title: Text(
                        query,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          Icons.close,
                          color: Colors.white.withOpacity(0.6),
                          size: 20,
                        ),
                        onPressed: () => _removeSearchQuery(query),
                      ),
                      onTap: () {
                        _searchController.text = query;
                        _searchController.selection =
                            TextSelection.fromPosition(
                              TextPosition(offset: query.length),
                            );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildUserListTile(Map<String, dynamic> user) {
    return Card(
      color: Colors.white.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        splashColor: Colors.white.withOpacity(0.1),
        onTap: () => _showUserDetailsPopup(user),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: Colors.white.withOpacity(0.1),
                backgroundImage: user['photoUrl'] != null
                    ? NetworkImage(user['photoUrl'])
                    : null,
                child: user['photoUrl'] == null
                    ? const Icon(Icons.person, color: Colors.white54)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user['name'] ?? 'No Name',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${user['dept'] ?? 'N/A'} • ID: ${user['customId'] ?? 'N/A'}",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.white.withOpacity(0.5),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
