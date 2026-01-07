import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:kyf/features/chat/conversation_screen.dart';
import 'package:kyf/models/chat_models.dart';
import 'package:kyf/services/storage_service.dart';
import 'package:kyf/services/user_service.dart';

/// Modern Chat Tab with Real Users
/// Features: Search bar, infinite scroll, online indicators

class ChatTab extends StatefulWidget {
  const ChatTab({super.key});

  @override
  State<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final UserService _userService = UserService();
  
  bool _isSearching = false;
  String _searchQuery = '';
  
  // Users state
  List<ChatUser> _users = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _error;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scrollController.addListener(_onScroll);
    _loadCurrentUser();
    _loadUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    final storage = await StorageService.getInstance();
    if (storage.hasProfile()) {
      final profile = storage.getProfile();
      if (profile != null) {
        setState(() {
          _currentUserId = profile['_id'] ?? profile['id'];
        });
      }
    }
  }

  Future<void> _loadUsers({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _hasMore = true;
        _users = [];
      });
    }

    setState(() {
      _isLoading = _users.isEmpty;
      _error = null;
    });

    try {
      final storage = await StorageService.getInstance();
      final token = storage.getToken();
      
      if (token == null) {
        setState(() {
          _error = 'Please login to view users';
          _isLoading = false;
        });
        return;
      }

      final response = await _userService.getAllUsers(
        token: token,
        page: _currentPage,
        limit: 20,
      );

      debugPrint('User response: ${response.data}');

      if (response.success && response.data != null) {
        try {
          // Parse the body - it could be a JSON string or already parsed
          Map<String, dynamic> bodyData;
          if (response.data['body'] is String) {
            bodyData = jsonDecode(response.data['body']);
          } else {
            bodyData = response.data['body'] ?? response.data;
          }

          // The users are inside bodyData['data']['users']
          final dataSection = bodyData['data'] as Map<String, dynamic>?;
          final usersList = dataSection?['users'] as List? ?? bodyData['users'] as List? ?? [];
          final pagination = dataSection?['pagination'] as Map<String, dynamic>? ?? 
                            bodyData['pagination'] as Map<String, dynamic>?;
          
          debugPrint('Found ${usersList.length} users');
          
          final newUsers = usersList
              .map((u) => ChatUser(
                    id: u['_id'] ?? '',
                    name: u['fullName'] ?? 'Unknown',
                    photoUrl: u['profilePhoto']?['thumbnail_url'] ?? u['profilePhoto']?['url'],
                    isOnline: u['isActive'] ?? false,
                  ))
              .where((u) => u.id != _currentUserId && u.id.isNotEmpty) // Filter out current user and empty IDs
              .toList();

          setState(() {
            _users.addAll(newUsers);
            _hasMore = pagination?['hasNextPage'] ?? false;
            _isLoading = false;
            _isLoadingMore = false;
          });
        } catch (parseError) {
          debugPrint('Error parsing users: $parseError');
          setState(() {
            _error = 'Error parsing user data';
            _isLoading = false;
            _isLoadingMore = false;
          });
        }
      } else {
        setState(() {
          _error = response.data?['message'] ?? 'Failed to load users';
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading users: $e');
      setState(() {
        _error = 'Network error: ${e.toString().split(':').last.trim()}';
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreUsers();
    }
  }

  Future<void> _loadMoreUsers() async {
    if (_isLoadingMore || !_hasMore) return;
    
    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });
    
    await _loadUsers();
  }

  List<ChatUser> get _filteredUsers {
    if (_searchQuery.isEmpty) return _users;
    return _users.where((user) =>
      user.name.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  void _openChat(ChatUser user) {
    // Create a temporary Chat object to open conversation
    final chat = Chat(
      id: '', // Will be created/fetched when conversation starts
      otherUser: user,
      updatedAt: DateTime.now(),
    );
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ConversationScreen(
          chat: chat,
          currentUserId: _currentUserId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? _buildSearchField(theme)
            : const Text('Messages'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search_rounded),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _searchQuery = '';
                }
              });
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.primary,
          indicatorWeight: 3,
          dividerColor: Colors.transparent,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
          labelStyle: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: 'Users'),
            Tab(text: 'Calls'),
            Tab(text: 'Settings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUsersTab(theme),
          _buildCallsTab(theme),
          _buildSettingsTab(theme),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton(
              onPressed: () => _loadUsers(refresh: true),
              child: const Icon(Icons.refresh_rounded),
            )
          : null,
    );
  }

  Widget _buildSearchField(ThemeData theme) {
    return TextField(
      controller: _searchController,
      autofocus: true,
      decoration: InputDecoration(
        hintText: 'Search users...',
        hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
        border: InputBorder.none,
      ),
      style: theme.textTheme.bodyLarge,
      onChanged: (value) {
        setState(() => _searchQuery = value);
      },
    );
  }

  Widget _buildUsersTab(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(_error!, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => _loadUsers(refresh: true),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final users = _filteredUsers;

    if (users.isEmpty) {
      return _buildEmptyState(
        theme,
        Icons.people_rounded,
        _searchQuery.isEmpty ? 'No Users Found' : 'No Results',
        _searchQuery.isEmpty
            ? 'Start connecting with people'
            : 'Try a different search term',
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadUsers(refresh: true),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: users.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == users.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }

          return _UserTile(
            user: users[index],
            onTap: () => _openChat(users[index]),
          );
        },
      ),
    );
  }

  Widget _buildCallsTab(ThemeData theme) {
    return _buildEmptyState(
      theme,
      Icons.call_rounded,
      'No Calls',
      'Your call history will appear here',
    );
  }

  Widget _buildSettingsTab(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        _SettingsTile(
          icon: Icons.account_circle_rounded,
          title: 'Account',
          subtitle: 'Privacy, security, change number',
        ),
        _SettingsTile(
          icon: Icons.lock_rounded,
          title: 'Privacy',
          subtitle: 'Block contacts, disappearing messages',
        ),
        _SettingsTile(
          icon: Icons.notifications_rounded,
          title: 'Notifications',
          subtitle: 'Message, group & call tones',
        ),
        _SettingsTile(
          icon: Icons.data_usage_rounded,
          title: 'Storage and Data',
          subtitle: 'Network usage, auto-download',
        ),
        _SettingsTile(
          icon: Icons.help_rounded,
          title: 'Help',
          subtitle: 'Help centre, contact us, privacy policy',
        ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme, IconData icon, String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 64,
              color: theme.colorScheme.primary.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

/// User Tile Widget
class _UserTile extends StatelessWidget {
  final ChatUser user;
  final VoidCallback onTap;

  const _UserTile({
    required this.user,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar with online indicator
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  backgroundImage: user.photoUrl != null
                      ? NetworkImage(user.photoUrl!)
                      : null,
                  child: user.photoUrl == null
                      ? Text(
                          user.initials,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                // Online indicator
                if (user.isOnline)
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.colorScheme.surface,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            // User info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.isOnline ? 'Online' : 'Tap to chat',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: user.isOnline
                          ? Colors.green
                          : theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            // Chat icon
            Icon(
              Icons.chat_bubble_outline_rounded,
              color: theme.colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}

/// Settings Tile Widget
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withOpacity(0.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: theme.colorScheme.primary),
      ),
      title: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: theme.colorScheme.onSurface.withOpacity(0.4),
      ),
      onTap: () {},
    );
  }
}
