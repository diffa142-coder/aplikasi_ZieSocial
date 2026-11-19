import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/smart_image.dart';
import '../model/post_model.dart';
import '../model/story_model.dart';
import '../view/create_story_view.dart';
import '../viewmodel/login_viewmodel.dart';
import '../viewmodel/story_viewmodel.dart';

const LinearGradient instagramStoryGradient = LinearGradient(
  colors: [
    Color(0xFF4D41DF),
    Color(0xFFFF6584),
  ],
  begin: Alignment.bottomLeft,
  end: Alignment.topRight,
);

class InstagramStoriesTray extends StatelessWidget {
  final int currentUserId;

  const InstagramStoriesTray({
    super.key,
    required this.currentUserId,
  });

  static const Color _bgColor = Color(0xFFFFFFFF);
  static const Color _primaryColor = Color(0xFF4D41DF);
  static const Color _onSurface = Color(0xFF1A1B1E);
  static const Color _surfaceLow = Color(0xFFF4F3F7);
  static const Color _surfaceContainer = Color(0xFFEFEDF1);
  static const Color _surfaceHighest = Color(0xFFE3E2E6);

  @override
  Widget build(BuildContext context) {
    final storyVm = context.watch<StoryViewModel>();
    final loginVm = context.watch<LoginViewModel>();

    final myStories = storyVm.getStoriesForAuthor(currentUserId);
    final otherAuthors = storyVm
        .getAuthorsWithStories(currentUserId)
        .where((a) => a.id != currentUserId)
        .toList();

    final myAvatarUrl = loginVm.avatar ?? '';
    final myName = loginVm.name;

    return Container(
      height: 108,
      decoration: const BoxDecoration(
        color: _bgColor,
        border: Border(
          bottom: BorderSide(color: _surfaceContainer, width: 1),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        itemCount: 1 + otherAuthors.length,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildYourStoryItem(
              context,
              myStories: myStories,
              avatarUrl: myAvatarUrl,
              name: myName,
            );
          }

          final author = otherAuthors[index - 1];
          final hasUnviewed =
              storyVm.hasUnviewedStories(author.id, currentUserId);
          final stories = storyVm.getStoriesForAuthor(author.id);

          return _buildUserStoryItem(
            context,
            author: author,
            stories: stories,
            hasUnviewed: hasUnviewed,
          );
        },
      ),
    );
  }

  // 1. Lingkaran "Your Story"
  Widget _buildYourStoryItem(
    BuildContext context, {
    required List<StoryModel> myStories,
    required String avatarUrl,
    required String name,
  }) {
    final hasActiveStory = myStories.isNotEmpty;

    return GestureDetector(
      onTap: () async {
        if (hasActiveStory) {
          _openStoryViewer(context, myStories);
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateStoryView()),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        width: 70,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: hasActiveStory ? instagramStoryGradient : null,
                    color: hasActiveStory ? null : _surfaceLow,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: _bgColor,
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 27,
                      backgroundColor: _surfaceContainer,
                      backgroundImage: resolveSmartImageProvider(avatarUrl),
                      child: avatarUrl.isEmpty
                          ? Text(
                              name.isNotEmpty ? name[0].toUpperCase() : 'U',
                              style: const TextStyle(
                                color: _primaryColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 17,
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CreateStoryView(),
                        ),
                      );
                    },
                    child: Container(
                      width: 21,
                      height: 21,
                      decoration: BoxDecoration(
                        color: _primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: _bgColor, width: 2),
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            const Text(
              'Your Story',
              style: TextStyle(
                color: _onSurface,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // 2. Lingkaran Cerita Pengguna Lain
  Widget _buildUserStoryItem(
    BuildContext context, {
    required AuthorModel author,
    required List<StoryModel> stories,
    required bool hasUnviewed,
  }) {
    final avatarUrl = author.fullAvatarUrl ?? author.avatar ?? '';
    final username =
        author.username.isNotEmpty ? author.username : author.name;

    return GestureDetector(
      onTap: () {
        if (stories.isNotEmpty) {
          _openStoryViewer(context, stories);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        width: 70,
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: hasUnviewed ? instagramStoryGradient : null,
                color: hasUnviewed ? null : _surfaceHighest,
              ),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: _bgColor,
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 27,
                  backgroundColor: _surfaceContainer,
                  backgroundImage: resolveSmartImageProvider(avatarUrl),
                  child: avatarUrl.isEmpty
                      ? Text(
                          username.isNotEmpty ? username[0].toUpperCase() : 'U',
                          style: const TextStyle(
                            color: _primaryColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 17,
                          ),
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              username,
              style: const TextStyle(
                color: _onSurface,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _openStoryViewer(BuildContext context, List<StoryModel> stories) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'StoryViewer',
      barrierColor: Colors.black,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (ctx, anim1, anim2) {
        return _InstagramStoryViewerPage(
          stories: stories,
          currentUserId: currentUserId,
        );
      },
    );
  }
}

// Halaman Fullscreen Story Viewer Gaya Instagram Asli
class _InstagramStoryViewerPage extends StatefulWidget {
  final List<StoryModel> stories;
  final int currentUserId;

  const _InstagramStoryViewerPage({
    required this.stories,
    required this.currentUserId,
  });

  @override
  State<_InstagramStoryViewerPage> createState() =>
      _InstagramStoryViewerPageState();
}

class _InstagramStoryViewerPageState extends State<_InstagramStoryViewerPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _goToNextStory();
      }
    });

    _markCurrentStoryViewed();
    _progressController.forward();
  }

  void _markCurrentStoryViewed() {
    if (_currentIndex < widget.stories.length) {
      final story = widget.stories[_currentIndex];
      context.read<StoryViewModel>().markStoryViewed(story.id, widget.currentUserId);
    }
  }

  void _goToNextStory() {
    if (_currentIndex < widget.stories.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _markCurrentStoryViewed();
      _progressController.reset();
      _progressController.forward();
    } else {
      Navigator.pop(context);
    }
  }

  void _goToPreviousStory() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      _markCurrentStoryViewed();
      _progressController.reset();
      _progressController.forward();
    } else {
      _progressController.reset();
      _progressController.forward();
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  String _formatStoryTime(String rawDate) {
    try {
      final dt = DateTime.parse(rawDate);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Baru saja';
      if (diff.inHours < 1) return '${diff.inMinutes}m';
      return '${diff.inHours}j';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.stories.isEmpty) {
      return const Scaffold(backgroundColor: Colors.black);
    }

    final currentStory = widget.stories[_currentIndex];
    final author = currentStory.author;
    final isOwner = author.id == widget.currentUserId;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Konten Gambar Cerita
            Positioned.fill(
              child: GestureDetector(
                onTapDown: (_) => _progressController.stop(),
                onTapUp: (details) {
                  _progressController.forward();
                  final screenWidth = MediaQuery.of(context).size.width;
                  if (details.globalPosition.dx < screenWidth * 0.3) {
                    _goToPreviousStory();
                  } else {
                    _goToNextStory();
                  }
                },
                child: Center(
                  child: buildSmartImage(
                    currentStory.mediaUrl,
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: const Color(0xFF141414),
                      alignment: Alignment.center,
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image, color: Colors.white38, size: 54),
                          SizedBox(height: 8),
                          Text('Gambar tidak dapat dimuat',
                              style: TextStyle(color: Colors.white38)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Top Header: Bar Progress & Profil Pembuat Cerita
            Positioned(
              top: 8,
              left: 12,
              right: 12,
              child: Column(
                children: [
                  // Multiple Segment Progress Bar
                  Row(
                    children: List.generate(widget.stories.length, (index) {
                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          height: 2.5,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: index < _currentIndex
                                ? Container(color: Colors.white)
                                : index == _currentIndex
                                    ? AnimatedBuilder(
                                        animation: _progressController,
                                        builder: (ctx, child) {
                                          return LinearProgressIndicator(
                                            value: _progressController.value,
                                            backgroundColor: Colors.white24,
                                            valueColor:
                                                const AlwaysStoppedAnimation<Color>(
                                                    Colors.white),
                                          );
                                        },
                                      )
                                    : Container(color: Colors.white24),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 10),

                  // Info Author
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 17,
                        backgroundColor: const Color(0xFF262626),
                        backgroundImage: resolveSmartImageProvider(
                          author.fullAvatarUrl ?? author.avatar,
                        ),
                        child: (author.avatar == null || author.avatar!.isEmpty)
                            ? Text(
                                author.name.isNotEmpty
                                    ? author.name[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        author.username.isNotEmpty ? author.username : author.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                        ),
                      ),
                      if (author.isVerified) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.verified,
                          color: Color(0xFF0095F6),
                          size: 13,
                        ),
                      ],
                      const SizedBox(width: 6),
                      Text(
                        _formatStoryTime(currentStory.createDate),
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),

                      // Tombol Hapus jika pemilik cerita
                      if (isOwner)
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.white70, size: 20),
                          tooltip: 'Hapus Cerita',
                          onPressed: () async {
                            _progressController.stop();
                            final storyVm = context.read<StoryViewModel>();
                            final navigator = Navigator.of(context);
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: const Color(0xFF262626),
                                title: const Text('Hapus Cerita?',
                                    style: TextStyle(color: Colors.white)),
                                content: const Text(
                                    'Cerita ini akan dihapus secara permanen.',
                                    style: TextStyle(color: Colors.white70)),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Batal',
                                        style: TextStyle(color: Colors.white70)),
                                  ),
                                  FilledButton(
                                    style: FilledButton.styleFrom(
                                        backgroundColor: Colors.red),
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Hapus'),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              await storyVm.deleteStory(currentStory.id);
                              if (mounted) {
                                navigator.pop();
                              }
                            } else if (mounted) {
                              _progressController.forward();
                            }
                          },
                        ),

                      // Tombol Tutup (X)
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 22),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Bottom Caption Overlay (jika ada caption)
            if (currentStory.caption != null && currentStory.caption!.isNotEmpty)
              Positioned(
                bottom: 24,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    currentStory.caption!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
