import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/smart_image.dart';
import '../viewmodel/chat_viewmodel.dart';
import '../viewmodel/login_viewmodel.dart';
import '../viewmodel/profile_viewmodel.dart';
import 'profile_view.dart';

class FollowListView extends StatefulWidget {
  final int userId;
  final String username;
  final int initialTabIndex; // 0 = Followers, 1 = Following

  const FollowListView({
    super.key,
    required this.userId,
    required this.username,
    this.initialTabIndex = 0,
  });

  @override
  State<FollowListView> createState() => _FollowListViewState();
}

class _FollowListViewState extends State<FollowListView>
    with SingleTickerProviderStateMixin {
  static const Color _bgColor = Color(0xFFFFFFFF);
  static const Color _primaryColor = Color(0xFF4D41DF);
  static const Color _onSurface = Color(0xFF1A1B1E);
  static const Color _onSurfaceVariant = Color(0xFF464555);
  static const Color _outline = Color(0xFF777587);
  static const Color _surfaceLow = Color(0xFFF4F3F7);
  static const Color _surfaceContainer = Color(0xFFEFEDF1);

  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 1),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    final currentUserId = context.read<LoginViewModel>().activeUserId;
    await context.read<ProfileViewModel>().fetchFollowConnections(
      targetUserId: widget.userId,
      currentUserId: currentUserId,
    );
  }

  List<FollowConnectionUser> _filter(
    List<FollowConnectionUser> items,
    ChatViewModel chatVm,
  ) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return items;
    return items.where((item) {
      final resolved = chatVm.resolveUserInfo(
        item.author.id,
        fallback: item.author,
      );
      return resolved.username.toLowerCase().contains(q) ||
          resolved.name.toLowerCase().contains(q);
    }).toList();
  }

  Widget _buildUserList({
    required List<FollowConnectionUser> items,
    required bool isLoading,
    required String emptyTitle,
    required String emptySubtitle,
    required int currentUserId,
  }) {
    final chatVm = context.watch<ChatViewModel>();
    final filtered = _filter(items, chatVm);

    if (isLoading && items.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: _primaryColor),
      );
    }

    if (filtered.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadData,
        color: _primaryColor,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 80),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: _surfaceLow,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.people_outline_rounded,
                        size: 34,
                        color: _primaryColor,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _query.trim().isNotEmpty
                          ? 'Pengguna tidak ditemukan'
                          : emptyTitle,
                      style: const TextStyle(
                        color: _onSurface,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _query.trim().isNotEmpty
                          ? 'Coba kata kunci username atau nama lain.'
                          : emptySubtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _onSurfaceVariant,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: _primaryColor,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 6),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final item = filtered[index];
          final resolved = chatVm.resolveUserInfo(
            item.author.id,
            fallback: item.author,
          );
          final isMe = resolved.id == currentUserId;
          final hasAvatar =
              resolved.avatar != null && resolved.avatar!.isNotEmpty;

          return ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfileView(
                    userId: resolved.id,
                    initialAuthor: resolved,
                  ),
                ),
              ).then((_) => _loadData());
            },
            leading: CircleAvatar(
              radius: 23,
              backgroundColor: _surfaceContainer,
              backgroundImage: resolveSmartImageProvider(resolved.avatar),
              child: !hasAvatar
                  ? Text(
                      resolved.name.isNotEmpty
                          ? resolved.name[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        color: _primaryColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    )
                  : null,
            ),
            title: Row(
              children: [
                Flexible(
                  child: Text(
                    resolved.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (resolved.isVerified) ...[
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.verified_rounded,
                    color: _primaryColor,
                    size: 14,
                  ),
                ],
              ],
            ),
            subtitle: Text(
              '@${resolved.username}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _outline,
                fontSize: 12.5,
              ),
            ),
            trailing: isMe
                ? null
                : SizedBox(
                    height: 34,
                    child: FilledButton(
                      onPressed: () async {
                        await context.read<ProfileViewModel>().toggleFollow(
                          followerId: currentUserId,
                          followingId: resolved.id,
                        );
                        _loadData();
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: item.isFollowing
                            ? _surfaceContainer
                            : _primaryColor,
                        foregroundColor: item.isFollowing
                            ? _onSurfaceVariant
                            : Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        item.isFollowing ? 'Following' : 'Follow',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.watch<LoginViewModel>().activeUserId;
    final profileVm = context.watch<ProfileViewModel>();
    final connections = profileVm.connectionsFor(widget.userId);
    final isLoading = profileVm.isLoadingFollowList(widget.userId);

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '@${widget.username}',
          style: const TextStyle(
            color: _onSurface,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: _primaryColor,
          unselectedLabelColor: _outline,
          indicatorColor: _primaryColor,
          indicatorWeight: 2.5,
          labelStyle: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
          ),
          tabs: [
            Tab(text: 'Followers (${connections.followers.length})'),
            Tab(text: 'Following (${connections.following.length})'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _query = val),
              style: const TextStyle(color: _onSurface, fontSize: 13.5),
              decoration: InputDecoration(
                hintText: 'Cari nama atau username...',
                hintStyle: const TextStyle(color: _outline, fontSize: 13.5),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: _outline,
                  size: 20,
                ),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: _outline,
                          size: 18,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: _surfaceLow,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildUserList(
                  items: connections.followers,
                  isLoading: isLoading,
                  emptyTitle: 'Belum ada Followers',
                  emptySubtitle:
                      'Pengguna yang mengikuti @${widget.username} akan tampil di sini.',
                  currentUserId: currentUserId,
                ),
                _buildUserList(
                  items: connections.following,
                  isLoading: isLoading,
                  emptyTitle: 'Belum mengikuti siapa pun',
                  emptySubtitle:
                      'Akun yang diikuti oleh @${widget.username} akan tampil di sini.',
                  currentUserId: currentUserId,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
