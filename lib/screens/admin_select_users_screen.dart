import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../services/supabase_service.dart';
import '../models/user_profile.dart';

class AdminSelectUsersScreen extends StatefulWidget {
  const AdminSelectUsersScreen({super.key});

  @override
  State<AdminSelectUsersScreen> createState() => _AdminSelectUsersScreenState();
}

class _AdminSelectUsersScreenState extends State<AdminSelectUsersScreen> {
  final List<String> _selectedUserIds = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<UserProfile> _allUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      final supabaseService = Get.find<SupabaseService>();
      final response = await supabaseService.client!
          .from('profiles')
          .select()
          .order('full_name', ascending: true);

      final users = (response as List)
          .map((e) => UserProfile.fromMap(e))
          .toList();

      setState(() {
        _allUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching users: $e');
      setState(() {
        _isLoading = false;
      });
      Get.snackbar('Error', 'Gagal memuat daftar user');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<UserProfile> get _filteredUsers {
    if (_searchQuery.isEmpty) {
      return _allUsers;
    }
    return _allUsers.where((user) {
      final query = _searchQuery.toLowerCase();
      final name = user.fullName.isNotEmpty
          ? user.fullName
          : (user.email ?? '');
      return name.toLowerCase().contains(query) ||
          (user.email ?? '').toLowerCase().contains(query);
    }).toList();
  }

  void _toggleUserSelection(String userId) {
    setState(() {
      if (_selectedUserIds.contains(userId)) {
        _selectedUserIds.remove(userId);
      } else {
        _selectedUserIds.add(userId);
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selectedUserIds.clear();
      _selectedUserIds.addAll(_filteredUsers.map((u) => u.id));
    });
  }

  void _clearAll() {
    setState(() {
      _selectedUserIds.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih User'),
        actions: [
          if (_selectedUserIds.isNotEmpty)
            TextButton(
              onPressed: () => Get.back(result: _selectedUserIds),
              child: Text(
                'Selesai (${_selectedUserIds.length})',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari user...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _selectAll,
                    icon: const Icon(Icons.check_box, size: 18),
                    label: const Text('Pilih Semua'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _clearAll,
                    icon: const Icon(Icons.clear, size: 18),
                    label: const Text('Hapus Semua'),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Selected count
          if (_selectedUserIds.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Text(
                    '${_selectedUserIds.length} user terpilih',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // User list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'User tidak ditemukan',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = _filteredUsers[index];
                      final isSelected = _selectedUserIds.contains(user.id);
                      final displayName = user.fullName.isNotEmpty
                          ? user.fullName
                          : (user.email ?? 'User');

                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (value) => _toggleUserSelection(user.id),
                        title: Text(
                          displayName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(user.email ?? '-'),
                        secondary: CircleAvatar(
                          backgroundColor: isSelected
                              ? theme.colorScheme.primary
                              : Colors.grey[300],
                          backgroundImage: user.avatarUrl != null
                              ? NetworkImage(user.avatarUrl!)
                              : null,
                          child: user.avatarUrl == null
                              ? Text(
                                  displayName.isNotEmpty
                                      ? displayName[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black87,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        activeColor: theme.colorScheme.primary,
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: _selectedUserIds.isNotEmpty
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: ElevatedButton(
                  onPressed: () => Get.back(result: _selectedUserIds),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: theme.colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Konfirmasi (${_selectedUserIds.length} user)',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}
