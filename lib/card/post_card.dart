import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../core/smart_image.dart';
import '../model/post_model.dart';
import '../view/profile_view.dart';
import '../viewmodel/post_viewmodel.dart';
import '../viewmodel/profile_viewmodel.dart';
import '../widget/comments_sheet.dart';
import '../widget/instagram_stories_tray.dart';
import '../widget/like_button.dart';

class PostCard extends StatefulWidget {
  final PostModel post;
  final int currentUserId;
  final VoidCallback? onLikePressed;
  final VoidCallback? onCommentPressed;

  const PostCard({
    super.key,
    required this.post,
    this.currentUserId = 1,
    this.onLikePressed,
    this.onCommentPressed,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard>
    with SingleTickerProviderStateMixin {
  static const Color _bgColor = Color(0xFFFFFFFF);
  static const Color _primaryColor = Color(0xFF4D41DF);
  static const Color _onSurface = Color(0xFF1A1B1E);
  static const Color _onSurfaceVariant = Color(0xFF464555);
  static const Color _outline = Color(0xFF777587);
  static const Color _surfaceLow = Color(0xFFF4F3F7);
  static const Color _surfaceContainer = Color(0xFFEFEDF1);
  static const Color _errorColor = Color(0xFFBA1A1A);

  late AnimationController _doubleTapController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  bool _showDoubleTapHeart = false;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _doubleTapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.25)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.25, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.0),
        weight: 30,
      ),
    ]).animate(_doubleTapController);

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.0),
        weight: 65,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 35,
      ),
    ]).animate(_doubleTapController);

    _doubleTapController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _showDoubleTapHeart = false);
      }
    });
  }

  @override
  void dispose() {
    _doubleTapController.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    if (!widget.post.isLikedBy(widget.currentUserId)) {
      widget.onLikePressed?.call();
    }

    setState(() => _showDoubleTapHeart = true);
    _doubleTapController.reset();
    _doubleTapController.forward();
  }

  String _formatDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return 'Just now';
    try {
      final dateTime = DateTime.parse(rawDate);
      final difference = DateTime.now().difference(dateTime);

      if (difference.inMinutes < 1) return 'Just now';
      if (difference.inHours < 1) return '${difference.inMinutes}m ago';
      if (difference.inDays < 1) return '${difference.inHours} hours ago';
      if (difference.inDays < 7) return '${difference.inDays} days ago';
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (_) {
      return rawDate;
    }
  }

  void _navigateToProfile() {
    final author = widget.post.author;
    final authorId = author?.id;
    if (authorId != null && authorId > 0) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProfileView(
            userId: authorId,
            initialAuthor: author,
          ),
        ),
      );
    }
  }

  void _openComments() {
    if (widget.onCommentPressed != null) {
      widget.onCommentPressed!();
    } else {
      CommentsSheet.show(
        context,
        post: widget.post,
        currentUserId: widget.currentUserId,
      );
    }
  }

  Future<void> _showEditDialog() async {
    final textController = TextEditingController(text: widget.post.caption);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Edit Postingan',
          style: TextStyle(color: _onSurface, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: textController,
          maxLines: 4,
          style: const TextStyle(color: _onSurface),
          decoration: InputDecoration(
            labelText: 'Caption Postingan',
            labelStyle: const TextStyle(color: _outline),
            filled: true,
            fillColor: _surfaceLow,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
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
      ),
    );

    if (confirmed == true && mounted) {
      final newCaption = textController.text.trim();
      final vm = context.read<PostViewModel>();
      final success = await vm.editPost(
        postId: widget.post.id,
        userId: widget.currentUserId,
        newCaption: newCaption,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Postingan berhasil diperbarui!'
                : (vm.errorMessage ?? 'Gagal memperbarui postingan.'),
          ),
          backgroundColor: success ? null : _errorColor,
        ),
      );
    }
    textController.dispose();
  }

  Future<void> _showDeleteConfirmationDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Hapus Postingan?',
          style: TextStyle(color: _onSurface, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Apakah Anda yakin ingin menghapus postingan ini? Tindakan ini tidak dapat dibatalkan.',
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
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final vm = context.read<PostViewModel>();
      final success = await vm.deletePost(
        postId: widget.post.id,
        userId: widget.currentUserId,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Postingan berhasil dihapus.'
                : (vm.errorMessage ?? 'Gagal menghapus postingan.'),
          ),
          backgroundColor: success ? null : _errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final author = post.author;
    final name = author?.name.isNotEmpty == true ? author!.name : 'Pengguna';
    final username = author?.username.isNotEmpty == true
        ? author!.username
        : name.toLowerCase().replaceAll(' ', '_');
    final avatarUrl = author?.fullAvatarUrl;
    final imageUrl = post.fullImageUrl;
    final isPostOwner = author?.id == widget.currentUserId;

    return Container(
      color: _bgColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Post Header (Light Material 3 Style)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 10),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _navigateToProfile,
                  child: Container(
                    width: 38,
                    height: 38,
                    padding: const EdgeInsets.all(1.8),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: instagramStoryGradient,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(1.5),
                      decoration: const BoxDecoration(
                        color: _bgColor,
                        shape: BoxShape.circle,
                      ),
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: _surfaceContainer,
                        backgroundImage: resolveSmartImageProvider(avatarUrl),
                        child: (avatarUrl == null || avatarUrl.isEmpty)
                            ? Text(
                                name.isNotEmpty ? name[0].toUpperCase() : 'U',
                                style: const TextStyle(
                                  color: _primaryColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Username & Subtitle
                Expanded(
                  child: GestureDetector(
                    onTap: _navigateToProfile,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                username,
                                style: const TextStyle(
                                  color: _onSurface,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (author?.isVerified == true) ...[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.verified_rounded,
                                color: _primaryColor,
                                size: 15,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 1),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              color: _primaryColor,
                              size: 13,
                            ),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                name != username ? name : 'ZieSocial',
                                style: const TextStyle(
                                  color: _onSurfaceVariant,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Follow / Following Button (Biru -> Abu-abu saat sudah follow)
                if (!isPostOwner && (author?.id ?? 0) > 0) ...[
                  Builder(
                    builder: (ctx) {
                      final isFollowing = ctx
                          .watch<ProfileViewModel>()
                          .isFollowing(widget.currentUserId, author!.id);

                      return GestureDetector(
                        onTap: () async {
                          final profileVm = ctx.read<ProfileViewModel>();
                          await profileVm.toggleFollow(
                            followerId: widget.currentUserId,
                            followingId: author.id,
                          );
                          final nowFollowing = profileVm.isFollowing(
                            widget.currentUserId,
                            author.id,
                          );
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                content: Text(
                                  nowFollowing
                                      ? 'Berhasil mengikuti @$username'
                                      : 'Batal mengikuti @$username',
                                ),
                                duration: const Duration(milliseconds: 900),
                              ),
                            );
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isFollowing
                                ? _surfaceContainer
                                : _primaryColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isFollowing ? 'Following' : 'Follow',
                            style: TextStyle(
                              color: isFollowing
                                  ? _onSurfaceVariant
                                  : Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 2),
                ],

                // More Options Menu
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_horiz_rounded,
                    size: 21,
                    color: _onSurfaceVariant,
                  ),
                  color: _bgColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditDialog();
                    } else if (value == 'delete') {
                      _showDeleteConfirmationDialog();
                    } else if (value == 'share') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Tautan postingan berhasil disalin!'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    }
                  },
                  itemBuilder: (ctx) => [
                    if (isPostOwner) ...[
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined,
                                size: 18, color: _onSurface),
                            SizedBox(width: 10),
                            Text('Edit Postingan',
                                style: TextStyle(color: _onSurface)),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline,
                                size: 18, color: _errorColor),
                            SizedBox(width: 10),
                            Text('Hapus Postingan',
                                style: TextStyle(color: _errorColor)),
                          ],
                        ),
                      ),
                    ],
                    const PopupMenuItem(
                      value: 'share',
                      child: Row(
                        children: [
                          Icon(Icons.share_outlined,
                              size: 18, color: _onSurface),
                          SizedBox(width: 10),
                          Text('Salin Tautan',
                              style: TextStyle(color: _onSurface)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 2. Post Media Edge-to-Edge dengan Double Tap Like Animation
          if (imageUrl != null && imageUrl.isNotEmpty)
            GestureDetector(
              onDoubleTap: _handleDoubleTap,
              child: Container(
                width: double.infinity,
                constraints:
                    const BoxConstraints(minHeight: 260, maxHeight: 500),
                color: _surfaceContainer,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    buildSmartImage(
                      imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 300,
                          color: _surfaceLow,
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _primaryColor,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 220,
                          color: _surfaceLow,
                          alignment: Alignment.center,
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image_not_supported_outlined,
                                  size: 40, color: _outline),
                              SizedBox(height: 8),
                              Text('Gambar tidak dapat dimuat',
                                  style: TextStyle(
                                      color: _outline, fontSize: 13)),
                            ],
                          ),
                        );
                      },
                    ),
                    if (_showDoubleTapHeart)
                      IgnorePointer(
                        child: FadeTransition(
                          opacity: _opacityAnimation,
                          child: ScaleTransition(
                            scale: _scaleAnimation,
                            child: SizedBox(
                              width: 150,
                              height: 150,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Lottie.asset(
                                    'assets/animations/like_heart.json',
                                    width: 150,
                                    height: 150,
                                    fit: BoxFit.contain,
                                  ),
                                  const Icon(
                                    Icons.favorite_rounded,
                                    color: _errorColor,
                                    size: 72,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black38,
                                        blurRadius: 16,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

          // 3. Post Actions (Inline Counts Matching HTML Style)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 12, 4),
            child: Row(
              children: [
                LikeButton(
                  isLiked: post.isLikedBy(widget.currentUserId),
                  likeCount: post.likeCount,
                  showCount: true,
                  inactiveColor: _onSurface,
                  activeColor: _errorColor,
                  onTap: widget.onLikePressed,
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: _openComments,
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: _onSurface,
                        size: 23,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${post.commentCount}',
                        style: const TextStyle(
                          color: _onSurface,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Tautan postingan berhasil disalin!'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.send_outlined,
                      color: _onSurface,
                      size: 22,
                    ),
                  ),
                ),
                const Spacer(),
                InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () {
                    setState(() => _isSaved = !_isSaved);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(_isSaved
                            ? 'Disimpan ke koleksi Anda'
                            : 'Dihapus dari koleksi'),
                        duration: const Duration(milliseconds: 900),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      _isSaved
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      color: _isSaved ? _primaryColor : _onSurface,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 4. Caption, Comments & Timestamp
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (post.caption.isNotEmpty)
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '$username ',
                          style: const TextStyle(
                            color: _onSurface,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        TextSpan(
                          text: post.caption,
                          style: const TextStyle(
                            color: _onSurface,
                            fontSize: 13.5,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (post.commentCount > 0) ...[
                  const SizedBox(height: 5),
                  GestureDetector(
                    onTap: _openComments,
                    child: Text(
                      'View all ${post.commentCount} comments',
                      style: const TextStyle(
                        color: _onSurfaceVariant,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  _formatDate(post.createDate),
                  style: const TextStyle(
                    color: _outline,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Thin Soft Divider Between Posts
          const Divider(color: _surfaceContainer, height: 1, thickness: 1),
        ],
      ),
    );
  }
}
