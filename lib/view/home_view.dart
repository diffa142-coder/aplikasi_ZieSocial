import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../card/post_card.dart';
import '../core/constants.dart';
import '../core/smart_image.dart';
import '../model/notification_model.dart';
import '../model/post_model.dart';
import '../viewmodel/chat_viewmodel.dart';
import '../viewmodel/login_viewmodel.dart';
import '../viewmodel/notification_viewmodel.dart';
import '../viewmodel/post_viewmodel.dart';
import '../viewmodel/story_viewmodel.dart';
import '../widget/instagram_stories_tray.dart';
import 'chat_list_view.dart';
import 'chat_room_view.dart';
import 'create_post_view.dart';
import 'create_story_view.dart';
import 'login_view.dart';
import 'notifications_view.dart';
import 'profile_view.dart';
import 'search_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  static const Color _bgColor = Color(0xFFFFFFFF);
  static const Color _primaryColor = Color(0xFF4D41DF);
  static const Color _primaryContainer = Color(0xFF675DF9);
  static const Color _primaryFixed = Color(0xFFE3DFFF);
  static const Color _onSurface = Color(0xFF1A1B1E);
  static const Color _onSurfaceVariant = Color(0xFF464555);
  static const Color _outline = Color(0xFF777587);
  static const Color _surfaceLow = Color(0xFFF4F3F7);
  static const Color _surfaceContainer = Color(0xFFEFEDF1);
  static const Color _surfaceHighest = Color(0xFFE3E2E6);
  static const Color _errorColor = Color(0xFFBA1A1A);

  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshFeed();
    });
  }

  void _refreshFeed() {
    final currentUserId = context.read<LoginViewModel>().activeUserId;
    context.read<PostViewModel>().fetchPosts(currentUserId: currentUserId);
    context.read<ChatViewModel>().bindUser(currentUserId);
    context.read<NotificationViewModel>().bindUser(currentUserId);
    context.read<StoryViewModel>().bindStories();
  }

  Future<void> _navigateToCreatePost() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreatePostView()),
    );

    if (result == true && mounted) {
      _refreshFeed();
      setState(() => _currentTabIndex = 0);
    }
  }

  Future<void> _navigateToCreateStory() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateStoryView()),
    );
  }

  Future<void> _showCreateChooserSheet() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: _bgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: _surfaceHighest,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Text(
                  'Buat di ZieSocial',
                  style: TextStyle(
                    color: _onSurface,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: instagramStoryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.history_edu_outlined,
                      color: Colors.white,
                    ),
                  ),
                  title: const Text(
                    'Cerita (Story)',
                    style: TextStyle(
                      color: _onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Text(
                    'Bagikan foto cerita terpisah dari feed',
                    style: TextStyle(color: _outline, fontSize: 12.5),
                  ),
                  onTap: () => Navigator.pop(ctx, 'story'),
                ),
                const SizedBox(height: 6),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _primaryFixed,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.add_photo_alternate_outlined,
                      color: _primaryColor,
                    ),
                  ),
                  title: const Text(
                    'Postingan Foto',
                    style: TextStyle(
                      color: _onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Text(
                    'Bagikan foto dan postingan ke Beranda',
                    style: TextStyle(color: _outline, fontSize: 12.5),
                  ),
                  onTap: () => Navigator.pop(ctx, 'post'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || choice == null) return;
    if (choice == 'story') {
      await _navigateToCreateStory();
    } else if (choice == 'post') {
      await _navigateToCreatePost();
    }
  }

  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsView()),
    );
  }

  void _openBannerNotification(AppNotificationModel item) {
    final notifVm = context.read<NotificationViewModel>();
    notifVm.dismissBanner();
    notifVm.markAsRead(item.id);

    final fallback = AuthorModel(
      id: item.actorId,
      username: item.actorUsername,
      name: item.actorName,
      avatar: item.actorAvatar,
    );
    final resolved = context.read<ChatViewModel>().resolveUserInfo(
      item.actorId,
      fallback: fallback,
    );

    final isChat = item.type == 'message' ||
        item.type == 'reply' ||
        item.type == 'mention' ||
        item.type == 'reaction';

    if (isChat) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ChatRoomView(partner: resolved)),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileView(
          userId: resolved.id,
          initialAuthor: resolved,
        ),
      ),
    );
  }

  Widget _buildLiveNotificationBanner(AppNotificationModel item) {
    final hasAvatar = item.actorAvatar != null && item.actorAvatar!.isNotEmpty;
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 14,
      right: 14,
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: () => _openBannerNotification(item),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: _onSurface,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: _primaryFixed,
                  backgroundImage: resolveSmartImageProvider(item.actorAvatar),
                  child: !hasAvatar
                      ? Text(
                          item.actorName.isNotEmpty
                              ? item.actorName[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            color: _primaryColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${item.actorName} (@${item.actorUsername})',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        item.body,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Colors.white60,
                    size: 18,
                  ),
                  onPressed: () =>
                      context.read<NotificationViewModel>().dismissBanner(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Keluar dari Akun?',
          style: TextStyle(color: _onSurface, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Apakah Anda yakin ingin keluar (logout) dari ZieSocial?',
          style: TextStyle(color: _onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: _outline)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _errorColor),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<NotificationViewModel>().clear();
      context.read<LoginViewModel>().logout();
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginView()),
        (route) => false,
      );
    }
  }

  Widget _buildNavIconItem({
    required IconData activeIcon,
    required IconData inactiveIcon,
    required bool isActive,
    required String tooltip,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                isActive ? activeIcon : inactiveIcon,
                color: isActive ? _primaryColor : _outline,
                size: 26,
              ),
              if (badgeCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1.5,
                    ),
                    decoration: BoxDecoration(
                      color: _primaryColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _bgColor, width: 1.5),
                    ),
                    constraints: const BoxConstraints(minWidth: 16),
                    child: Text(
                      badgeCount > 9 ? '9+' : '$badgeCount',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              if (isActive)
                Positioned(
                  bottom: 4,
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: _primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBrandLogo() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: const LinearGradient(
          colors: [_primaryColor, _primaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withValues(alpha: 0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: const Text(
        'Z',
        style: TextStyle(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildInstagramFeedTab(
    BuildContext context,
    int currentUserId,
    String currentName,
    String currentAvatarUrl,
  ) {
    final unreadChatCount =
        context.watch<ChatViewModel>().getTotalUnreadCount(currentUserId);

    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Sticky Header Matching HTML Home Feed
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: _bgColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _buildBrandLogo(),
                  const SizedBox(width: 10),
                  const Text(
                    'ZieSocial',
                    style: TextStyle(
                      color: _onSurface,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.35,
                    ),
                  ),
                  const Spacer(),
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.favorite_outline_rounded,
                          color: _onSurface,
                          size: 24,
                        ),
                        tooltip: 'Notifikasi',
                        onPressed: _openNotifications,
                      ),
                      if (context.watch<NotificationViewModel>().unreadCount >
                          0)
                        Positioned(
                          top: 7,
                          right: 7,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: _errorColor,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: _bgColor, width: 1.4),
                            ),
                            child: Text(
                              context
                                          .watch<NotificationViewModel>()
                                          .unreadCount >
                                      99
                                  ? '99+'
                                  : '${context.watch<NotificationViewModel>().unreadCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.near_me_outlined,
                          color: _onSurface,
                          size: 24,
                        ),
                        tooltip: 'Pesan Langsung',
                        onPressed: () {
                          context.read<ChatViewModel>().refreshFromStorage();
                          setState(() => _currentTabIndex = 2);
                        },
                      ),
                      if (unreadChatCount > 0)
                        Positioned(
                          top: 9,
                          right: 9,
                          child: Container(
                            width: 9,
                            height: 9,
                            decoration: BoxDecoration(
                              color: _primaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: _bgColor, width: 1.5),
                            ),
                          ),
                        ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.logout_rounded,
                      color: _errorColor,
                      size: 22,
                    ),
                    tooltip: 'Keluar',
                    onPressed: () => _confirmLogout(context),
                  ),
                  const SizedBox(width: 2),
                  GestureDetector(
                    onTap: () => setState(() => _currentTabIndex = 3),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _primaryColor.withValues(alpha: 0.25),
                          width: 1.5,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 15,
                        backgroundColor: _surfaceContainer,
                        backgroundImage:
                            resolveSmartImageProvider(currentAvatarUrl),
                        child: currentAvatarUrl.isEmpty
                            ? Text(
                                currentName.isNotEmpty
                                    ? currentName[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  color: _primaryColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Feed Content
            Expanded(
              child: Consumer<PostViewModel>(
                builder: (context, viewModel, child) {
                  if (viewModel.isLoading && viewModel.posts.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _primaryColor,
                      ),
                    );
                  }

                  if (viewModel.errorMessage != null &&
                      viewModel.posts.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              size: 56,
                              color: _errorColor,
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'Gagal Memuat Feed',
                              style: TextStyle(
                                color: _onSurface,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              viewModel.errorMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: _outline),
                            ),
                            const SizedBox(height: 18),
                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: _primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: _refreshFeed,
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Coba Lagi'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (viewModel.posts.isEmpty) {
                    return RefreshIndicator(
                      color: _primaryColor,
                      backgroundColor: _bgColor,
                      onRefresh: () async => _refreshFeed(),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          InstagramStoriesTray(currentUserId: currentUserId),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.55,
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: const BoxDecoration(
                                        color: _primaryFixed,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.photo_library_outlined,
                                        size: 40,
                                        color: _primaryColor,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Belum Ada Postingan',
                                      style: TextStyle(
                                        color: _onSurface,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    const Text(
                                      'Mulai bagikan momen pertama Anda sekarang!',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: _outline),
                                    ),
                                    const SizedBox(height: 20),
                                    FilledButton.icon(
                                      style: FilledButton.styleFrom(
                                        backgroundColor: _primaryColor,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                      ),
                                      onPressed: _navigateToCreatePost,
                                      icon: const Icon(Icons.add_a_photo),
                                      label: const Text('Buat Postingan Baru'),
                                    ),
                                    const SizedBox(height: 10),
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: _primaryColor,
                                        side: const BorderSide(
                                          color: _primaryFixed,
                                          width: 1.5,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 11,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                      ),
                                      onPressed: _navigateToCreateStory,
                                      icon: const Icon(
                                        Icons.history_edu_outlined,
                                      ),
                                      label: const Text('Buat Cerita (Story)'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    color: _primaryColor,
                    backgroundColor: _bgColor,
                    onRefresh: () async => _refreshFeed(),
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemCount: viewModel.posts.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return InstagramStoriesTray(
                            currentUserId: currentUserId,
                          );
                        }
                        final post = viewModel.posts[index - 1];
                        return PostCard(
                          post: post,
                          currentUserId: currentUserId,
                          onLikePressed: () =>
                              viewModel.toggleLike(post.id, currentUserId),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loginVm = context.watch<LoginViewModel>();
    final currentUserId = loginVm.activeUserId;
    final currentName = loginVm.name;
    final currentAvatarUrl = ApiConstants.getImageUrl(loginVm.avatar);
    final unreadChatCount =
        context.watch<ChatViewModel>().getTotalUnreadCount(currentUserId);
    final activeBanner = context.watch<NotificationViewModel>().activeBanner;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: _bgColor),
      child: Scaffold(
        backgroundColor: _bgColor,
        body: Stack(
          children: [
            IndexedStack(
              index: _currentTabIndex,
              children: [
                _buildInstagramFeedTab(
                  context,
                  currentUserId,
                  currentName,
                  currentAvatarUrl,
                ),
                const SearchView(),
                const ChatListView(),
                ProfileView(
                  key: ValueKey(currentUserId),
                  userId: currentUserId,
                ),
              ],
            ),
            if (activeBanner != null) _buildLiveNotificationBanner(activeBanner),
          ],
        ),

        // Modern Light Bottom Navigation Bar Matching HTML Style
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: _bgColor,
            boxShadow: [
              BoxShadow(
                color: _primaryColor.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 62,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 1. Home
                    _buildNavIconItem(
                      activeIcon: Icons.home_rounded,
                      inactiveIcon: Icons.home_outlined,
                      isActive: _currentTabIndex == 0,
                      tooltip: 'Home',
                      onTap: () => setState(() => _currentTabIndex = 0),
                    ),

                    // 2. Search
                    _buildNavIconItem(
                      activeIcon: Icons.search_rounded,
                      inactiveIcon: Icons.search_rounded,
                      isActive: _currentTabIndex == 1,
                      tooltip: 'Search',
                      onTap: () => setState(() => _currentTabIndex = 1),
                    ),

                    // 3. Center Indigo Create Post/Story (+) Button
                    Tooltip(
                      message: 'Buat Postingan / Cerita',
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: _showCreateChooserSheet,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _primaryColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: _primaryColor.withValues(alpha: 0.28),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                      ),
                    ),

                    // 4. Messages
                    _buildNavIconItem(
                      activeIcon: Icons.chat_bubble_rounded,
                      inactiveIcon: Icons.chat_bubble_outline_rounded,
                      isActive: _currentTabIndex == 2,
                      tooltip: 'Messages',
                      badgeCount: unreadChatCount,
                      onTap: () {
                        context.read<ChatViewModel>().refreshFromStorage();
                        setState(() => _currentTabIndex = 2);
                      },
                    ),

                    // 5. Profile Avatar
                    Tooltip(
                      message: 'Profile',
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => setState(() => _currentTabIndex = 3),
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(1.8),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _currentTabIndex == 3
                                      ? _primaryColor
                                      : Colors.transparent,
                                ),
                                child: CircleAvatar(
                                  radius: 13,
                                  backgroundColor: _surfaceLow,
                                  backgroundImage: resolveSmartImageProvider(
                                    currentAvatarUrl,
                                  ),
                                  child: currentAvatarUrl.isEmpty
                                      ? Text(
                                          currentName.isNotEmpty
                                              ? currentName[0].toUpperCase()
                                              : 'U',
                                          style: const TextStyle(
                                            color: _primaryColor,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 11,
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                              if (_currentTabIndex == 3)
                                Positioned(
                                  bottom: 4,
                                  child: Container(
                                    width: 4,
                                    height: 4,
                                    decoration: const BoxDecoration(
                                      color: _primaryColor,
                                      shape: BoxShape.circle,
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
            ),
          ),
        ),
      ),
    );
  }
}
