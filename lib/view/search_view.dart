import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../card/post_card.dart';
import '../core/constants.dart';
import '../core/smart_image.dart';
import '../model/post_model.dart';
import '../viewmodel/chat_viewmodel.dart';
import '../viewmodel/login_viewmodel.dart';
import '../viewmodel/post_viewmodel.dart';
import '../viewmodel/profile_viewmodel.dart';
import 'profile_view.dart';

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  static const Color _bgColor = Color(0xFFFFFFFF);
  static const Color _primaryColor = Color(0xFF4D41DF);
  static const Color _primaryContainer = Color(0xFF675DF9);
  static const Color _primaryFixed = Color(0xFFE3DFFF);
  static const Color _onPrimaryFixed = Color(0xFF100069);
  static const Color _secondaryColor = Color(0xFF564CC6);
  static const Color _tertiaryColor = Color(0xFF9C00BB);
  static const Color _onSurface = Color(0xFF1A1B1E);
  static const Color _onSurfaceVariant = Color(0xFF464555);
  static const Color _outline = Color(0xFF777587);
  static const Color _surfaceLow = Color(0xFFF4F3F7);
  static const Color _surfaceContainer = Color(0xFFEFEDF1);
  static const Color _surfaceHighest = Color(0xFFE3E2E6);

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  String _selectedCategory = 'All';

  final List<_CategoryOption> _categories = const [
    _CategoryOption(id: 'All', label: 'All'),
    _CategoryOption(id: 'Trending', label: 'Trending', emoji: '🔥'),
    _CategoryOption(
      id: 'Creators',
      label: 'Creators',
      icon: Icons.person_search_rounded,
    ),
    _CategoryOption(id: 'Posts', label: 'Photography', emoji: '📸'),
    _CategoryOption(id: 'Popular', label: 'Popular', emoji: '✨'),
  ];

  final List<_TrendingTag> _trendingTags = const [
    _TrendingTag(
      category: 'Featured #1',
      tag: '#ZieCreative',
      keyword: 'zie',
      postsLabel: 'Featured',
      growth: '+18.4%',
      icon: Icons.trending_up_rounded,
      accent: _primaryColor,
    ),
    _TrendingTag(
      category: 'Photography',
      tag: '#PhotoLovers',
      keyword: 'foto',
      postsLabel: 'Visual Arts',
      growth: '+12.1%',
      icon: Icons.auto_awesome_rounded,
      accent: _tertiaryColor,
    ),
    _TrendingTag(
      category: 'Tech & Design',
      tag: '#TechFuture',
      keyword: 'tech',
      postsLabel: 'Innovation',
      growth: '+9.7%',
      icon: Icons.bolt_rounded,
      accent: _secondaryColor,
    ),
    _TrendingTag(
      category: 'Lifestyle',
      tag: '#DailyVibes',
      keyword: 'hari',
      postsLabel: 'Community',
      growth: '+22.3%',
      icon: Icons.flight_takeoff_rounded,
      accent: _primaryColor,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {});
  }

  void _openProfile(AuthorModel author) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileView(
          userId: author.id,
          initialAuthor: author,
        ),
      ),
    );
  }

  void _showPostDetailModal(BuildContext context, PostModel post) {
    final currentUserId = context.read<LoginViewModel>().activeUserId;
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
          builder: (_, controller) {
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
                        controller: controller,
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
    required int currentUserId,
    required String currentName,
    required String currentAvatarUrl,
  }) {
    return Container(
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
          Container(
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
          ),
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
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfileView(userId: currentUserId),
                ),
              );
            },
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
                backgroundImage: resolveSmartImageProvider(currentAvatarUrl),
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
    );
  }

  Widget _buildSearchInputBar(String query) {
    final isFocused = _searchFocus.hasFocus;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              decoration: BoxDecoration(
                color: isFocused ? _bgColor : _surfaceLow,
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withValues(alpha: isFocused ? 0.08 : 0.03),
                    blurRadius: isFocused ? 12 : 4,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: isFocused
                    ? Border.all(
                        color: _primaryColor.withValues(alpha: 0.25),
                        width: 1,
                      )
                    : null,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    color: isFocused ? _primaryColor : _outline,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocus,
                      onChanged: _onSearchChanged,
                      style: const TextStyle(color: _onSurface, fontSize: 13.5),
                      cursorColor: _primaryColor,
                      decoration: const InputDecoration(
                        hintText: 'Search creators, tags, or topics...',
                        hintStyle: TextStyle(color: _outline, fontSize: 13.5),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 11),
                      ),
                    ),
                  ),
                  if (query.isNotEmpty)
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 28, minHeight: 28),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: _outline,
                        size: 18,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    )
                  else
                    const Icon(
                      Icons.mic_none_rounded,
                      color: _outline,
                      size: 20,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: _surfaceLow,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () {
                setState(() => _selectedCategory = 'All');
                _searchController.clear();
                FocusScope.of(context).unfocus();
              },
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  Icons.tune_rounded,
                  color: _onSurface,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPills() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: _categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategory == cat.id;

          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: EdgeInsets.symmetric(
                horizontal: isSelected ? 16 : 14,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: isSelected ? _primaryColor : _surfaceLow,
                borderRadius: BorderRadius.circular(999),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: _primaryColor.withValues(alpha: 0.22),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (cat.icon != null) ...[
                    Icon(
                      cat.icon,
                      size: 15,
                      color: isSelected ? Colors.white : _primaryColor,
                    ),
                    const SizedBox(width: 5),
                  ],
                  Text(
                    cat.label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : _onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (cat.emoji != null) ...[
                    const SizedBox(width: 4),
                    Text(cat.emoji!, style: const TextStyle(fontSize: 12)),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSpotlightBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: [_primaryColor, _primaryContainer, _secondaryColor],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: _primaryColor.withValues(alpha: 0.25),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: const Text(
                'Z',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          'ZieSocial Spotlight',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.verified_rounded,
                        color: Color(0xFFFED6FF),
                        size: 15,
                      ),
                    ],
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Temukan kreator & postingan terbaik hari ini',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                setState(() => _selectedCategory = 'Trending');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: _primaryColor,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                minimumSize: Size.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: const Text(
                'Explore',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendingTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'Trending in Social',
                    style: TextStyle(
                      color: _onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: _primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => setState(() => _selectedCategory = 'Trending'),
                style: TextButton.styleFrom(
                  foregroundColor: _primaryColor,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'See all',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 102,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _trendingTags.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final item = _trendingTags[index];
              return GestureDetector(
                onTap: () {
                  _searchController.text = item.keyword;
                  setState(() {});
                },
                child: Container(
                  width: 168,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _surfaceLow,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            item.category,
                            style: const TextStyle(
                              color: _outline,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Icon(item.icon, color: item.accent, size: 17),
                        ],
                      ),
                      Text(
                        item.tag,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _onSurface,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            item.postsLabel,
                            style: const TextStyle(
                              color: _onSurfaceVariant,
                              fontSize: 11.5,
                            ),
                          ),
                          Text(
                            item.growth,
                            style: const TextStyle(
                              color: _primaryColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestedCreatorsSection(
    List<AuthorModel> creators,
    int currentUserId,
  ) {
    if (creators.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'Suggested Creators',
                    style: TextStyle(
                      color: _onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2.5,
                    ),
                    decoration: BoxDecoration(
                      color: _primaryFixed,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'New',
                      style: TextStyle(
                        color: _onPrimaryFixed,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => setState(() => _selectedCategory = 'Creators'),
                style: TextButton.styleFrom(
                  foregroundColor: _primaryColor,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Discover',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 166,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: creators.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final creator = creators[index];
              final avatarUrl = creator.fullAvatarUrl;
              final isFollowing = context
                  .watch<ProfileViewModel>()
                  .isFollowing(currentUserId, creator.id);

              return GestureDetector(
                onTap: () => _openProfile(creator),
                child: Container(
                  width: 138,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _surfaceLow,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [_primaryColor, _secondaryColor],
                                begin: Alignment.bottomLeft,
                                end: Alignment.topRight,
                              ),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: _bgColor,
                                shape: BoxShape.circle,
                              ),
                              child: CircleAvatar(
                                backgroundColor: _surfaceContainer,
                                backgroundImage:
                                    resolveSmartImageProvider(avatarUrl),
                                child: (avatarUrl == null || avatarUrl.isEmpty)
                                    ? Text(
                                        creator.name.isNotEmpty
                                            ? creator.name[0].toUpperCase()
                                            : 'U',
                                        style: const TextStyle(
                                          color: _primaryColor,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 18,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                          ),
                          if (creator.isVerified)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 17,
                                height: 17,
                                decoration: const BoxDecoration(
                                  color: _primaryColor,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 11,
                                ),
                              ),
                            ),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            creator.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: _onSurface,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '@${creator.username}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: _outline,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        width: double.infinity,
                        height: 30,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: isFollowing
                                ? _surfaceContainer
                                : _primaryColor,
                            foregroundColor:
                                isFollowing ? _onSurfaceVariant : Colors.white,
                            elevation: 0,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          onPressed: () {
                            context.read<ProfileViewModel>().toggleFollow(
                                  followerId: currentUserId,
                                  followingId: creator.id,
                                );
                          },
                          child: Text(
                            isFollowing ? 'Following' : 'Follow',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDiscoveryCard(PostModel post, {required bool isTall}) {
    final imageUrl = post.fullImageUrl;
    final username = post.author?.username.isNotEmpty == true
        ? post.author!.username
        : (post.author?.name ?? 'user');

    return GestureDetector(
      onTap: () => _showPostDetailModal(context, post),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: AspectRatio(
          aspectRatio: isTall ? 9 / 13 : 1,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                color: _surfaceContainer,
                child: (imageUrl != null && imageUrl.isNotEmpty)
                    ? buildSmartImage(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: _surfaceLow,
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.broken_image_outlined,
                            color: _outline,
                          ),
                        ),
                      )
                    : Container(
                        color: _surfaceLow,
                        padding: const EdgeInsets.all(14),
                        alignment: Alignment.center,
                        child: Text(
                          post.caption,
                          maxLines: 5,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: _onSurfaceVariant,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
              ),
              // Subtle dark scrim at bottom for readable overlay
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 24, 10, 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        _onSurface.withValues(alpha: 0.85),
                        _onSurface.withValues(alpha: 0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (post.caption.isNotEmpty)
                        Text(
                          post.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      const SizedBox(height: 3),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              '@$username',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 10.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.favorite_rounded,
                                size: 13,
                                color: Color(0xFFFF6584),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '${post.likeCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCuratedMasonryFeed(List<PostModel> posts) {
    final sortedPosts = List<PostModel>.from(posts);
    if (_selectedCategory == 'Trending' || _selectedCategory == 'Popular') {
      sortedPosts.sort((a, b) => b.likeCount.compareTo(a.likeCount));
    }

    if (sortedPosts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
        child: Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: _surfaceLow,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.explore_outlined,
                  size: 36,
                  color: _outline,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Belum ada postingan untuk dijelajahi',
                style: TextStyle(
                  color: _onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final leftPosts = <PostModel>[];
    final rightPosts = <PostModel>[];
    for (int i = 0; i < sortedPosts.length; i++) {
      if (i.isEven) {
        leftPosts.add(sortedPosts[i]);
      } else {
        rightPosts.add(sortedPosts[i]);
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              children: [
                for (int i = 0; i < leftPosts.length; i++) ...[
                  _buildDiscoveryCard(leftPosts[i], isTall: i % 2 == 0),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              children: [
                for (int i = 0; i < rightPosts.length; i++) ...[
                  _buildDiscoveryCard(rightPosts[i], isTall: i % 2 == 1),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExploreHome({
    required List<PostModel> posts,
    required List<AuthorModel> creators,
    required int currentUserId,
  }) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 28),
      children: [
        if (_selectedCategory == 'All') _buildSpotlightBanner(),
        if (_selectedCategory == 'All' || _selectedCategory == 'Trending')
          _buildTrendingTagsSection(),
        if (_selectedCategory == 'All' || _selectedCategory == 'Creators')
          _buildSuggestedCreatorsSection(creators, currentUserId),
        if (_selectedCategory != 'Creators') ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.grid_view_rounded,
                      color: _primaryColor,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Curated Discovery',
                      style: TextStyle(
                        color: _onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${posts.length} posts',
                  style: const TextStyle(
                    color: _outline,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          _buildCuratedMasonryFeed(posts),
        ],
        // Caught up footer
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Column(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: _primaryFixed,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: _primaryColor,
                  size: 18,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "You're caught up with today's trends",
                style: TextStyle(
                  color: _onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'ZieSocial updates discovery feeds in real time',
                style: TextStyle(color: _outline, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResults({
    required String query,
    required List<PostModel> posts,
    required List<AuthorModel> accounts,
    required int currentUserId,
  }) {
    if (posts.isEmpty && accounts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: _surfaceLow,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.search_off_rounded,
                  size: 40,
                  color: _outline,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Tidak ada hasil untuk "$query"',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Coba cari dengan kata kunci lain atau periksa ejaan.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _outline, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        if ((_selectedCategory == 'All' || _selectedCategory == 'Creators') &&
            accounts.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 6),
            child: Text(
              'Creators & Accounts',
              style: TextStyle(
                color: _onSurface,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ...accounts.map((author) {
            final avatarUrl = author.fullAvatarUrl;
            final isFollowing = context
                .watch<ProfileViewModel>()
                .isFollowing(currentUserId, author.id);

            return ListTile(
              onTap: () => _openProfile(author),
              leading: CircleAvatar(
                radius: 23,
                backgroundColor: _surfaceContainer,
                backgroundImage: resolveSmartImageProvider(avatarUrl),
                child: (avatarUrl == null || avatarUrl.isEmpty)
                    ? Text(
                        author.name.isNotEmpty
                            ? author.name[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          color: _primaryColor,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : null,
              ),
              title: Row(
                children: [
                  Flexible(
                    child: Text(
                      author.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 14.5,
                      ),
                    ),
                  ),
                  if (author.isVerified) ...[
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
                '@${author.username}',
                style: const TextStyle(color: _outline, fontSize: 12.5),
              ),
              trailing: author.id == currentUserId
                  ? null
                  : FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor:
                            isFollowing ? _surfaceContainer : _primaryColor,
                        foregroundColor:
                            isFollowing ? _onSurfaceVariant : Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        minimumSize: Size.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      onPressed: () {
                        context.read<ProfileViewModel>().toggleFollow(
                              followerId: currentUserId,
                              followingId: author.id,
                            );
                      },
                      child: Text(
                        isFollowing ? 'Following' : 'Follow',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
            );
          }),
          const Divider(color: _surfaceContainer, height: 18),
        ],
        if (_selectedCategory != 'Creators' && posts.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Related Posts',
                  style: TextStyle(
                    color: _onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${posts.length} found',
                  style: const TextStyle(color: _outline, fontSize: 12),
                ),
              ],
            ),
          ),
          ...posts.map((post) {
            final img = post.fullImageUrl;
            final uname = post.author?.username.isNotEmpty == true
                ? post.author!.username
                : (post.author?.name ?? 'user');

            return ListTile(
              onTap: () => _showPostDetailModal(context, post),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 52,
                  height: 52,
                  color: _surfaceContainer,
                  child: (img != null && img.isNotEmpty)
                      ? buildSmartImage(img, fit: BoxFit.cover)
                      : const Icon(Icons.article_outlined, color: _outline),
                ),
              ),
              title: Text(
                post.caption.isNotEmpty ? post.caption : 'Postingan @$uname',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _onSurface,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                '@$uname · ${post.likeCount} likes',
                style: const TextStyle(color: _outline, fontSize: 12),
              ),
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: _outline,
                size: 20,
              ),
            );
          }),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final loginVm = context.watch<LoginViewModel>();
    final currentUserId = loginVm.activeUserId;
    final currentName = loginVm.name;
    final currentAvatarUrl = ApiConstants.getImageUrl(loginVm.avatar);
    final postViewModel = context.watch<PostViewModel>();
    final chatViewModel = context.watch<ChatViewModel>();

    final allPosts = postViewModel.posts;
    final query = _searchController.text.trim();
    final searchResults = postViewModel.searchPosts(query);

    final availableCreators = chatViewModel.getAvailableUsers(
      currentUserId,
      posts: allPosts,
      query: query,
    );

    final Map<int, AuthorModel> matchedAccounts = {};
    for (final u in availableCreators) {
      matchedAccounts[u.id] = u;
    }
    for (final post in searchResults) {
      if (post.author != null && post.author!.id > 0) {
        matchedAccounts.putIfAbsent(post.author!.id, () => post.author!);
      }
    }
    final accountsList = matchedAccounts.values.toList();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: _bgColor),
      child: Scaffold(
        backgroundColor: _bgColor,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildTopBar(
                currentUserId: currentUserId,
                currentName: currentName,
                currentAvatarUrl: currentAvatarUrl,
              ),
              _buildSearchInputBar(query),
              _buildCategoryPills(),
              const SizedBox(height: 4),
              Expanded(
                child: query.isNotEmpty
                    ? _buildSearchResults(
                        query: query,
                        posts: searchResults,
                        accounts: accountsList,
                        currentUserId: currentUserId,
                      )
                    : _buildExploreHome(
                        posts: allPosts,
                        creators: availableCreators,
                        currentUserId: currentUserId,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryOption {
  final String id;
  final String label;
  final IconData? icon;
  final String? emoji;

  const _CategoryOption({
    required this.id,
    required this.label,
    this.icon,
    this.emoji,
  });
}

class _TrendingTag {
  final String category;
  final String tag;
  final String keyword;
  final String postsLabel;
  final String growth;
  final IconData icon;
  final Color accent;

  const _TrendingTag({
    required this.category,
    required this.tag,
    required this.keyword,
    required this.postsLabel,
    required this.growth,
    required this.icon,
    required this.accent,
  });
}
