import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../card/post_card.dart';
import '../core/smart_image.dart';
import '../model/post_model.dart';
import '../model/story_model.dart';
import '../model/user_profile_model.dart';
import '../viewmodel/login_viewmodel.dart';
import '../viewmodel/post_viewmodel.dart';
import '../viewmodel/profile_viewmodel.dart';
import '../viewmodel/story_viewmodel.dart';
import 'chat_room_view.dart';
import 'create_story_view.dart';
import 'follow_list_view.dart';
import 'login_view.dart';

class ProfileView extends StatefulWidget {
  final int userId;
  final AuthorModel? initialAuthor;

  const ProfileView({
    super.key,
    required this.userId,
    this.initialAuthor,
  });

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  static const Color _bgColor = Color(0xFFFFFFFF);
  static const Color _primaryColor = Color(0xFF4D41DF);
  static const Color _primaryContainer = Color(0xFF675DF9);
  static const Color _primaryFixed = Color(0xFFE3DFFF);
  static const Color _secondaryColor = Color(0xFF564CC6);
  static const Color _tertiaryColor = Color(0xFF9C00BB);
  static const Color _onSurface = Color(0xFF1A1B1E);
  static const Color _onSurfaceVariant = Color(0xFF464555);
  static const Color _outline = Color(0xFF777587);
  static const Color _surfaceLow = Color(0xFFF4F3F7);
  static const Color _surfaceContainer = Color(0xFFEFEDF1);
  static const Color _surfaceHighest = Color(0xFFE3E2E6);
  static const Color _errorColor = Color(0xFFBA1A1A);

  final ImagePicker _picker = ImagePicker();
  int _selectedTab = 0; // 0 = Grid, 1 = Feed List

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfile();
    });
  }

  @override
  void didUpdateWidget(covariant ProfileView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadProfile();
      });
    }
  }

  void _loadProfile() {
    if (!mounted) return;
    final currentUserId = context.read<LoginViewModel>().activeUserId;
    context.read<ProfileViewModel>().fetchProfile(
          targetUserId: widget.userId,
          currentUserId: currentUserId,
          initialAuthor: widget.initialAuthor,
        );
  }

  Future<void> _handleFollowToggle() async {
    final currentUserId = context.read<LoginViewModel>().activeUserId;
    final vm = context.read<ProfileViewModel>();
    await vm.toggleFollow(
      followerId: currentUserId,
      followingId: widget.userId,
    );
  }

  Future<String?> _pickImageAsDataUrl() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 400,
      maxHeight: 400,
      imageQuality: 75,
    );
    if (picked == null) return null;
    final Uint8List bytes = await picked.readAsBytes();
    final lowerName = picked.name.toLowerCase();
    final mime = lowerName.endsWith('.png') ? 'image/png' : 'image/jpeg';
    return 'data:$mime;base64,${base64Encode(bytes)}';
  }

  Future<void> _handleAvatarTap(UserProfileModel profile) async {
    final hasAvatar =
        profile.fullAvatarUrl != null && profile.fullAvatarUrl!.isNotEmpty;

    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: _bgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: _surfaceHighest,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Foto Profil',
                    style: TextStyle(
                      color: _onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.add_a_photo_outlined,
                    color: _primaryColor,
                  ),
                  title: Text(
                    hasAvatar ? 'Ganti Foto Profil' : 'Tambah Foto Profil',
                    style: const TextStyle(
                      color: _onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () => Navigator.pop(ctx, 'pick'),
                ),
                if (hasAvatar)
                  ListTile(
                    leading: const Icon(
                      Icons.delete_outline,
                      color: _errorColor,
                    ),
                    title: const Text(
                      'Hapus Foto Profil',
                      style: TextStyle(
                        color: _errorColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () => Navigator.pop(ctx, 'remove'),
                  ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || action == null) return;

    final profileVm = context.read<ProfileViewModel>();
    final loginVm = context.read<LoginViewModel>();
    final postVm = context.read<PostViewModel>();
    final storyVm = context.read<StoryViewModel>();

    if (action == 'pick') {
      final dataUrl = await _pickImageAsDataUrl();
      if (dataUrl == null || !mounted) return;

      await profileVm.updateAvatar(
        userId: widget.userId,
        avatarDataUrl: dataUrl,
      );
      loginVm.updateActiveUser(avatar: dataUrl, updateAvatar: true);
      postVm.syncAuthorProfile(
        userId: widget.userId,
        avatar: dataUrl,
        updateAvatar: true,
      );
      storyVm.syncAuthorProfile(
        userId: widget.userId,
        avatar: dataUrl,
        updateAvatar: true,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto profil berhasil diperbarui!')),
      );
    } else if (action == 'remove') {
      await profileVm.updateAvatar(
        userId: widget.userId,
        avatarDataUrl: null,
      );
      loginVm.updateActiveUser(avatar: null, updateAvatar: true);
      postVm.syncAuthorProfile(
        userId: widget.userId,
        avatar: null,
        updateAvatar: true,
      );
      storyVm.syncAuthorProfile(
        userId: widget.userId,
        avatar: null,
        updateAvatar: true,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto profil telah dihapus.')),
      );
    }
  }

  Future<void> _handleLogout() async {
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

    if (confirmed == true && mounted) {
      context.read<LoginViewModel>().logout();
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginView()),
        (route) => false,
      );
    }
  }

  Future<void> _showEditProfileDialog(UserProfileModel profile) async {
    final nameController = TextEditingController(text: profile.name);
    final bioController = TextEditingController(text: profile.bio ?? '');
    String? tempAvatarUrl = profile.avatar;
    bool avatarChanged = false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final previewUrl =
              (tempAvatarUrl != null && tempAvatarUrl!.isNotEmpty)
                  ? tempAvatarUrl
                  : null;

          return AlertDialog(
            backgroundColor: _bgColor,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text(
              'Edit Profile',
              style: TextStyle(color: _onSurface, fontWeight: FontWeight.w700),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final pickedDataUrl = await _pickImageAsDataUrl();
                      if (pickedDataUrl != null) {
                        setDialogState(() {
                          tempAvatarUrl = pickedDataUrl;
                          avatarChanged = true;
                        });
                      }
                    },
                    child: Column(
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            ClipOval(
                              child: Container(
                                width: 76,
                                height: 76,
                                color: _primaryFixed,
                                child: previewUrl != null
                                    ? buildSmartImage(
                                        previewUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Icon(
                                          Icons.person,
                                          size: 36,
                                          color: _primaryColor,
                                        ),
                                      )
                                    : Center(
                                        child: Text(
                                          profile.name.isNotEmpty
                                              ? profile.name[0].toUpperCase()
                                              : 'U',
                                          style: const TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                            color: _primaryColor,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: _primaryColor,
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: _bgColor, width: 2),
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Ubah Foto Profil',
                          style: TextStyle(
                            color: _primaryColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: _onSurface),
                    decoration: InputDecoration(
                      labelText: 'Nama Lengkap',
                      labelStyle: const TextStyle(color: _outline),
                      filled: true,
                      fillColor: _surfaceLow,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: bioController,
                    maxLines: 3,
                    style: const TextStyle(color: _onSurface),
                    decoration: InputDecoration(
                      labelText: 'Bio',
                      labelStyle: const TextStyle(color: _outline),
                      hintText: 'Tulis bio singkat tentang Anda...',
                      hintStyle: const TextStyle(color: _outline),
                      filled: true,
                      fillColor: _surfaceLow,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Batal', style: TextStyle(color: _outline)),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: _primaryColor),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed == true && mounted) {
      final newName = nameController.text.trim();
      final newBio = bioController.text.trim();
      if (newName.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nama tidak boleh kosong.')),
        );
        nameController.dispose();
        bioController.dispose();
        return;
      }

      final vm = context.read<ProfileViewModel>();
      final loginVm = context.read<LoginViewModel>();
      final postVm = context.read<PostViewModel>();
      final storyVm = context.read<StoryViewModel>();

      final success = await vm.updateProfile(
        userId: widget.userId,
        name: newName,
        bio: newBio,
        avatar: tempAvatarUrl,
        updateAvatar: avatarChanged,
      );

      loginVm.updateActiveUser(
        name: newName,
        bio: newBio,
        avatar: tempAvatarUrl,
        updateAvatar: avatarChanged,
      );
      postVm.syncAuthorProfile(
        userId: widget.userId,
        name: newName,
        avatar: tempAvatarUrl,
        updateAvatar: avatarChanged,
      );
      storyVm.syncAuthorProfile(
        userId: widget.userId,
        name: newName,
        avatar: tempAvatarUrl,
        updateAvatar: avatarChanged,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Profil berhasil diperbarui!'
                : (vm.errorMessage ?? 'Gagal memperbarui profil.'),
          ),
          backgroundColor: success ? null : _errorColor,
        ),
      );
    }

    nameController.dispose();
    bioController.dispose();
  }

  void _openPostModal(PostModel post, int currentUserId) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _bgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.88,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollCtrl) {
            return Consumer<PostViewModel>(
              builder: (context, postVm, child) {
                final livePost = postVm.posts.firstWhere(
                  (p) => p.id == post.id,
                  orElse: () => post,
                );
                return Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _surfaceHighest,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        controller: scrollCtrl,
                        children: [
                          PostCard(
                            post: livePost,
                            currentUserId: currentUserId,
                            onLikePressed: () =>
                                postVm.toggleLike(livePost.id, currentUserId),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildTopBar({
    required UserProfileModel profile,
    required bool isOwnProfile,
    required bool canPop,
  }) {
    return Container(
      height: 60,
      padding: EdgeInsets.only(left: canPop ? 6 : 16, right: 8),
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
          if (canPop)
            IconButton(
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: _onSurface,
                size: 24,
              ),
              onPressed: () => Navigator.pop(context),
            )
          else
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: const LinearGradient(
                  colors: [_primaryColor, _primaryContainer],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
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
            ),
          Expanded(
            child: Text(
              canPop
                  ? (profile.username.isNotEmpty
                      ? '@${profile.username}'
                      : profile.name)
                  : 'ZieSocial',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _onSurface,
                fontSize: 21,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
          ),
          IconButton(
            icon:
                const Icon(Icons.refresh_rounded, color: _onSurface, size: 22),
            tooltip: 'Segarkan',
            onPressed: _loadProfile,
          ),
          if (isOwnProfile)
            IconButton(
              icon: const Icon(
                Icons.logout_rounded,
                color: _errorColor,
                size: 22,
              ),
              tooltip: 'Keluar (Logout)',
              onPressed: _handleLogout,
            ),
        ],
      ),
    );
  }

  Widget _buildStoryHighlightsRow({
    required List<StoryModel> userStories,
    required bool isOwnProfile,
  }) {
    if (userStories.isEmpty && !isOwnProfile) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 8),
      child: SizedBox(
        height: 92,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          itemCount: userStories.length + (isOwnProfile ? 1 : 0),
          itemBuilder: (context, index) {
            if (isOwnProfile && index == userStories.length) {
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CreateStoryView()),
                  );
                },
                child: Container(
                  width: 68,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(
                          color: _surfaceLow,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          color: _outline,
                          size: 26,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'New',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _outline,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final story = userStories[index];
            return Container(
              width: 68,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    padding: const EdgeInsets.all(2.5),
                    decoration: const BoxDecoration(
                      color: _surfaceHighest,
                      shape: BoxShape.circle,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: _bgColor,
                        shape: BoxShape.circle,
                      ),
                      child: ClipOval(
                        child: buildSmartImage(
                          story.mediaUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            color: _surfaceLow,
                            child: const Icon(
                              Icons.auto_awesome,
                              color: _primaryColor,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    (story.caption != null && story.caption!.isNotEmpty)
                        ? story.caption!
                        : 'Story',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _onSurface,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _openFollowList({
    required UserProfileModel profile,
    required int initialTabIndex,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FollowListView(
          userId: profile.id,
          username: profile.username,
          initialTabIndex: initialTabIndex,
        ),
      ),
    ).then((_) => _loadProfile());
  }

  Widget _buildStatColumn({
    required int count,
    required String label,
    VoidCallback? onTap,
  }) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: _outline,
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return content;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: content,
    );
  }

  Widget _buildTabButton({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? _primaryColor : Colors.transparent,
                width: 2.2,
              ),
            ),
          ),
          child: Icon(
            icon,
            size: 24,
            color: isSelected ? _primaryColor : _outline,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.watch<LoginViewModel>().activeUserId;
    final isOwnProfile = widget.userId == currentUserId;
    final canPop = Navigator.canPop(context);
    final userStories =
        context.watch<StoryViewModel>().getStoriesForAuthor(widget.userId);

    return Consumer<ProfileViewModel>(
      builder: (context, vm, child) {
        final profile = vm.getProfileFor(
          targetUserId: widget.userId,
          currentUserId: currentUserId,
          initialAuthor: widget.initialAuthor,
        );
        final feedPosts = context
            .watch<PostViewModel>()
            .posts
            .where((p) => p.author?.id == widget.userId)
            .toList();
        final userPosts = profile.posts.isNotEmpty ? profile.posts : feedPosts;
        final avatarUrl = profile.fullAvatarUrl;
        final isVerified = profile.username.toLowerCase() == 'ziesocial' ||
            profile.username.toLowerCase() == 'ziesocial.id';

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: _bgColor),
          child: Scaffold(
            backgroundColor: _bgColor,
            body: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _buildTopBar(
                    profile: profile,
                    isOwnProfile: isOwnProfile,
                    canPop: canPop,
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      color: _primaryColor,
                      backgroundColor: _bgColor,
                      onRefresh: () async => _loadProfile(),
                      child: ListView(
                        padding: const EdgeInsets.only(bottom: 32),
                        children: [
                          // Profile Header Details
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Top Row: Gradient Avatar Ring & Metrics
                                Row(
                                  children: [
                                    GestureDetector(
                                      onTap: isOwnProfile
                                          ? () => _handleAvatarTap(profile)
                                          : null,
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          Container(
                                            width: 82,
                                            height: 82,
                                            padding: const EdgeInsets.all(2.5),
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              gradient: LinearGradient(
                                                colors: [
                                                  _primaryColor,
                                                  _secondaryColor,
                                                  _tertiaryColor,
                                                ],
                                                begin: Alignment.bottomLeft,
                                                end: Alignment.topRight,
                                              ),
                                            ),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.all(2.5),
                                              decoration: const BoxDecoration(
                                                color: _bgColor,
                                                shape: BoxShape.circle,
                                              ),
                                              child: ClipOval(
                                                child: Container(
                                                  color: _surfaceContainer,
                                                  child: (avatarUrl != null &&
                                                          avatarUrl.isNotEmpty)
                                                      ? buildSmartImage(
                                                          avatarUrl,
                                                          fit: BoxFit.cover,
                                                          errorBuilder:
                                                              (context, error,
                                                                      stackTrace) =>
                                                                  Center(
                                                            child: Text(
                                                              profile.name
                                                                      .isNotEmpty
                                                                  ? profile
                                                                      .name[0]
                                                                      .toUpperCase()
                                                                  : 'U',
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 28,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color:
                                                                    _primaryColor,
                                                              ),
                                                            ),
                                                          ),
                                                        )
                                                      : Center(
                                                          child: Text(
                                                            profile.name
                                                                    .isNotEmpty
                                                                ? profile
                                                                    .name[0]
                                                                    .toUpperCase()
                                                                : 'U',
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 28,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color:
                                                                  _primaryColor,
                                                            ),
                                                          ),
                                                        ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          if (isOwnProfile)
                                            Positioned(
                                              bottom: -2,
                                              right: -2,
                                              child: GestureDetector(
                                                onTap: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) =>
                                                          const CreateStoryView(),
                                                    ),
                                                  );
                                                },
                                                child: Container(
                                                  width: 26,
                                                  height: 26,
                                                  decoration: BoxDecoration(
                                                    color: _primaryColor,
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color: _bgColor,
                                                      width: 2,
                                                    ),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: _primaryColor
                                                            .withValues(
                                                          alpha: 0.3,
                                                        ),
                                                        blurRadius: 6,
                                                        offset:
                                                            const Offset(0, 2),
                                                      ),
                                                    ],
                                                  ),
                                                  child: const Icon(
                                                    Icons.add_rounded,
                                                    size: 16,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: [
                                          _buildStatColumn(
                                            count: userPosts.length,
                                            label: 'Posts',
                                          ),
                                          _buildStatColumn(
                                            count: profile.followersCount,
                                            label: 'Followers',
                                            onTap: () => _openFollowList(
                                              profile: profile,
                                              initialTabIndex: 0,
                                            ),
                                          ),
                                          _buildStatColumn(
                                            count: profile.followingCount,
                                            label: 'Following',
                                            onTap: () => _openFollowList(
                                              profile: profile,
                                              initialTabIndex: 1,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),

                                // Name & Verified Badge
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        profile.name,
                                        style: const TextStyle(
                                          color: _onSurface,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                    ),
                                    if (isVerified) ...[
                                      const SizedBox(width: 6),
                                      const Icon(
                                        Icons.verified_rounded,
                                        color: _primaryColor,
                                        size: 18,
                                      ),
                                    ],
                                  ],
                                ),

                                // Category / Handle Pill
                                if (profile.username.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          _primaryColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.alternate_email_rounded,
                                          size: 12,
                                          color: _primaryColor,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          profile.username,
                                          style: const TextStyle(
                                            color: _primaryColor,
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],

                                // Bio Text
                                if (profile.bio != null &&
                                    profile.bio!.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    profile.bio!,
                                    style: const TextStyle(
                                      color: _onSurfaceVariant,
                                      fontSize: 13.5,
                                      height: 1.45,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 14),

                                // Profile Action Bar
                                if (isOwnProfile)
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Material(
                                          color: _surfaceLow,
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          child: InkWell(
                                            borderRadius:
                                                BorderRadius.circular(14),
                                            onTap: () =>
                                                _showEditProfileDialog(profile),
                                            child: const Padding(
                                              padding: EdgeInsets.symmetric(
                                                vertical: 10,
                                              ),
                                              child: Text(
                                                'Edit Profile',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: _onSurface,
                                                  fontSize: 12.5,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Material(
                                          color: _surfaceLow,
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          child: InkWell(
                                            borderRadius:
                                                BorderRadius.circular(14),
                                            onTap: () {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Link profil @${profile.username} disalin!',
                                                  ),
                                                  duration: const Duration(
                                                    milliseconds: 1200,
                                                  ),
                                                ),
                                              );
                                            },
                                            child: const Padding(
                                              padding: EdgeInsets.symmetric(
                                                vertical: 10,
                                              ),
                                              child: Text(
                                                'Share Profile',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: _onSurface,
                                                  fontSize: 12.5,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Material(
                                        color: _surfaceLow,
                                        borderRadius: BorderRadius.circular(14),
                                        child: InkWell(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          onTap: () =>
                                              _handleAvatarTap(profile),
                                          child: const Padding(
                                            padding: EdgeInsets.all(10),
                                            child: Icon(
                                              Icons.photo_camera_outlined,
                                              size: 19,
                                              color: _onSurface,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                else
                                  Row(
                                    children: [
                                      Expanded(
                                        child: FilledButton(
                                          onPressed: _handleFollowToggle,
                                          style: FilledButton.styleFrom(
                                            backgroundColor: profile.isFollowing
                                                ? _surfaceContainer
                                                : _primaryColor,
                                            foregroundColor: profile.isFollowing
                                                ? _onSurfaceVariant
                                                : Colors.white,
                                            elevation: 0,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 10,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                          ),
                                          child: Text(
                                            profile.isFollowing
                                                ? 'Following'
                                                : 'Follow',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Material(
                                          color: _surfaceLow,
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          child: InkWell(
                                            borderRadius:
                                                BorderRadius.circular(14),
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => ChatRoomView(
                                                    partner: AuthorModel(
                                                      id: profile.id,
                                                      username:
                                                          profile.username,
                                                      name: profile.name,
                                                      avatar: profile.avatar,
                                                      isVerified: isVerified,
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                            child: const Padding(
                                              padding: EdgeInsets.symmetric(
                                                vertical: 10,
                                              ),
                                              child: Text(
                                                'Message',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: _onSurface,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),

                          // Story Highlights Strip
                          _buildStoryHighlightsRow(
                            userStories: userStories,
                            isOwnProfile: isOwnProfile,
                          ),

                          const Divider(color: _surfaceContainer, height: 1),

                          // Content Navigation Tabs (Grid vs Feed List)
                          Row(
                            children: [
                              _buildTabButton(
                                icon: Icons.grid_on_rounded,
                                isSelected: _selectedTab == 0,
                                onTap: () => setState(() => _selectedTab = 0),
                              ),
                              _buildTabButton(
                                icon: Icons.view_agenda_outlined,
                                isSelected: _selectedTab == 1,
                                onTap: () => setState(() => _selectedTab = 1),
                              ),
                            ],
                          ),
                          const Divider(color: _surfaceContainer, height: 1),

                          // Posts Content
                          if (userPosts.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 48),
                              child: Center(
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(18),
                                      decoration: const BoxDecoration(
                                        color: _surfaceLow,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.photo_library_outlined,
                                        size: 36,
                                        color: _outline,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'Belum ada postingan',
                                      style: TextStyle(
                                        color: _onSurface,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else if (_selectedTab == 0)
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(2),
                              itemCount: userPosts.length,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 2,
                                mainAxisSpacing: 2,
                              ),
                              itemBuilder: (context, index) {
                                final post = userPosts[index];
                                final img = post.fullImageUrl;
                                return GestureDetector(
                                  onTap: () =>
                                      _openPostModal(post, currentUserId),
                                  child: Container(
                                    color: _surfaceContainer,
                                    child: (img != null && img.isNotEmpty)
                                        ? buildSmartImage(
                                            img,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error,
                                                    stackTrace) =>
                                                const Center(
                                              child: Icon(
                                                Icons.broken_image_outlined,
                                                color: _outline,
                                              ),
                                            ),
                                          )
                                        : Container(
                                            color: _surfaceLow,
                                            padding: const EdgeInsets.all(8),
                                            alignment: Alignment.center,
                                            child: Text(
                                              post.caption,
                                              maxLines: 4,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                color: _onSurfaceVariant,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                  ),
                                );
                              },
                            )
                          else
                            ...userPosts.map((post) {
                              return PostCard(
                                post: post,
                                currentUserId: currentUserId,
                                onLikePressed: () {
                                  context
                                      .read<PostViewModel>()
                                      .toggleLike(post.id, currentUserId);
                                },
                              );
                            }),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
