import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../core/smart_image.dart';
import '../model/message_model.dart';
import '../model/post_model.dart';
import '../viewmodel/chat_viewmodel.dart';
import '../viewmodel/login_viewmodel.dart';
import '../viewmodel/post_viewmodel.dart';
import 'chat_room_view.dart';
import 'profile_view.dart';

class ChatListView extends StatefulWidget {
  const ChatListView({super.key});

  @override
  State<ChatListView> createState() => _ChatListViewState();
}

class _ChatListViewState extends State<ChatListView> {
  static const Color _bgColor = Color(0xFFFFFFFF);
  static const Color _primaryColor = Color(0xFF4D41DF);
  static const Color _primaryContainer = Color(0xFF675DF9);
  static const Color _primaryFixed = Color(0xFFE3DFFF);
  static const Color _onPrimaryFixed = Color(0xFF100069);
  static const Color _secondaryContainer = Color(0xFF8C84FF);
  static const Color _onSurface = Color(0xFF1A1B1E);
  static const Color _onSurfaceVariant = Color(0xFF464555);
  static const Color _outline = Color(0xFF777587);
  static const Color _surfaceLow = Color(0xFFF4F3F7);
  static const Color _surfaceContainer = Color(0xFFEFEDF1);
  static const Color _surfaceHigh = Color(0xFFE9E7EB);
  static const Color _surfaceHighest = Color(0xFFE3E2E6);
  static const Color _emerald = Color(0xFF10B981);

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  String _myNote = 'Online';

  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(() {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final currentUserId = context.read<LoginViewModel>().activeUserId;
      context.read<ChatViewModel>().bindUser(currentUserId);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  String _formatRelativeTime(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Now';
      if (diff.inHours < 1) return '${diff.inMinutes}m';
      if (diff.inDays < 1) return '${diff.inHours}h';
      if (diff.inDays < 7) return '${diff.inDays}d';
      return '${dt.day}/${dt.month}';
    } catch (_) {
      return '';
    }
  }

  void _openChatWith(AuthorModel partner) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatRoomView(partner: partner),
      ),
    );
  }

  Future<void> _confirmDeleteConversation(
    ChatConversationSummary conv,
    int currentUserId,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Hapus Chat dengan @${conv.partner.username}?',
          style: const TextStyle(
            color: _onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: const Text(
          'Anda bisa menghapus percakapan untuk diri sendiri saja atau menghapus permanen untuk semua orang.',
          style: TextStyle(color: _onSurfaceVariant, fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: _outline)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<ChatViewModel>().clearConversation(
                currentUserId: currentUserId,
                partnerId: conv.partner.id,
                forEveryone: false,
              );
            },
            child: const Text(
              'Hapus untuk Saya',
              style: TextStyle(
                color: _primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<ChatViewModel>().clearConversation(
                currentUserId: currentUserId,
                partnerId: conv.partner.id,
                forEveryone: true,
              );
            },
            child: const Text('Hapus untuk Semua'),
          ),
        ],
      ),
    );
  }

  Future<void> _editMyNote() async {
    final controller = TextEditingController(text: _myNote);
    final updated = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Your Note',
          style: TextStyle(
            color: _onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        content: TextField(
          controller: controller,
          maxLength: 24,
          style: const TextStyle(color: _onSurface, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Share what you are up to...',
            hintStyle: const TextStyle(color: _outline),
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
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: _outline)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (updated != null && updated.isNotEmpty && mounted) {
      setState(() => _myNote = updated);
    }
  }

  void _showNewMessageSheet(List<AuthorModel> availableUsers) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _bgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        String modalQuery = '';
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final filtered = availableUsers.where((u) {
              if (modalQuery.trim().isEmpty) return true;
              final q = modalQuery.trim().toLowerCase();
              return u.username.toLowerCase().contains(q) ||
                  u.name.toLowerCase().contains(q);
            }).toList();

            return DraggableScrollableSheet(
              initialChildSize: 0.72,
              minChildSize: 0.45,
              maxChildSize: 0.92,
              expand: false,
              builder: (_, scrollCtrl) {
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
                    const Text(
                      'New Message',
                      style: TextStyle(
                        color: _onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: _surfaceLow,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: TextField(
                          onChanged: (val) =>
                              setModalState(() => modalQuery = val),
                          style: const TextStyle(
                            color: _onSurface,
                            fontSize: 14,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'To: search name or @username...',
                            hintStyle: TextStyle(color: _outline, fontSize: 14),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: _outline,
                              size: 20,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 11),
                          ),
                        ),
                      ),
                    ),
                    const Divider(color: _surfaceHigh, height: 1),
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24.0),
                                child: Text(
                                  'Belum ada pengguna lain yang terdaftar.\nBuat akun kedua untuk mulai saling berkirim pesan!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: _outline,
                                    fontSize: 13.5,
                                  ),
                                ),
                              ),
                            )
                          : ListView.builder(
                              controller: scrollCtrl,
                              itemCount: filtered.length,
                              itemBuilder: (_, idx) {
                                final user = filtered[idx];
                                final avatarUrl = user.fullAvatarUrl;
                                return ListTile(
                                  leading: _buildAvatar(
                                    name: user.name,
                                    avatarUrl: avatarUrl,
                                    radius: 22,
                                  ),
                                  title: Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          user.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: _onSurface,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      if (user.isVerified) ...[
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
                                    '@${user.username}',
                                    style: const TextStyle(
                                      color: _outline,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                  trailing: Container(
                                    width: 34,
                                    height: 34,
                                    decoration: const BoxDecoration(
                                      color: _primaryFixed,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.send_rounded,
                                      color: _primaryColor,
                                      size: 17,
                                    ),
                                  ),
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    _openChatWith(user);
                                  },
                                );
                              },
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

  Widget _buildAvatar({
    required String name,
    required String? avatarUrl,
    double radius = 24,
  }) {
    final hasImage = avatarUrl != null && avatarUrl.isNotEmpty;
    return CircleAvatar(
      radius: radius,
      backgroundColor: _surfaceContainer,
      backgroundImage: resolveSmartImageProvider(avatarUrl),
      child: !hasImage
          ? Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'U',
              style: TextStyle(
                color: _primaryColor,
                fontWeight: FontWeight.w700,
                fontSize: radius * 0.72,
              ),
            )
          : null,
    );
  }

  Widget _buildTopAppBar({
    required int currentUserId,
    required String currentName,
    required String currentAvatarUrl,
    required ChatViewModel chatVm,
    required List<AuthorModel> allUsers,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: _onSurface, size: 22),
            tooltip: 'Refresh Messages',
            onPressed: () => chatVm.refreshFromStorage(),
          ),
          IconButton(
            icon: const Icon(
              Icons.edit_square,
              color: _onSurface,
              size: 21,
            ),
            tooltip: 'New Message',
            onPressed: () => _showNewMessageSheet(allUsers),
          ),
          const SizedBox(width: 4),
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
              child: _buildAvatar(
                name: currentName,
                avatarUrl: currentAvatarUrl,
                radius: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(String query) {
    final isFocused = _searchFocus.hasFocus;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: isFocused ? _surfaceContainer : _surfaceLow,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isFocused
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocus,
          onChanged: (_) => setState(() {}),
          style: const TextStyle(color: _onSurface, fontSize: 13.5),
          cursorColor: _primaryColor,
          decoration: InputDecoration(
            hintText: 'Search direct messages...',
            hintStyle: const TextStyle(color: _outline, fontSize: 13.5),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: isFocused ? _primaryColor : _outline,
              size: 20,
            ),
            suffixIcon: query.isNotEmpty
                ? IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: _outline,
                      size: 18,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                  )
                : const Icon(
                    Icons.tune_rounded,
                    color: _outline,
                    size: 18,
                  ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveFriendsCarousel({
    required String currentName,
    required String currentAvatarUrl,
    required List<AuthorModel> availableUsers,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ACTIVE FRIENDS',
                style: TextStyle(
                  color: _onSurfaceVariant,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: _emerald,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${availableUsers.length} Online',
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
        SizedBox(
          height: 102,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            itemCount: 1 + availableUsers.length,
            itemBuilder: (context, index) {
              if (index == 0) {
                return GestureDetector(
                  onTap: _editMyNote,
                  child: Container(
                    width: 68,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: _surfaceHigh,
                                shape: BoxShape.circle,
                              ),
                              child: _buildAvatar(
                                name: currentName,
                                avatarUrl: currentAvatarUrl,
                                radius: 26,
                              ),
                            ),
                            Positioned(
                              top: -10,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _surfaceHighest,
                                    borderRadius: BorderRadius.circular(999),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            Colors.black.withValues(alpha: 0.06),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    '✨ $_myNote',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: _onSurface,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: _primaryColor,
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: _bgColor, width: 1.5),
                                ),
                                child: const Icon(
                                  Icons.add_rounded,
                                  color: Colors.white,
                                  size: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'Your note',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final user = availableUsers[index - 1];
              final avatarUrl = user.fullAvatarUrl;
              final displayName =
                  user.name.isNotEmpty ? user.name.split(' ').first : user.username;

              return GestureDetector(
                onTap: () => _openChatWith(user),
                child: Container(
                  width: 68,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
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
                                colors: [_primaryColor, _secondaryContainer],
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
                              child: _buildAvatar(
                                name: user.name,
                                avatarUrl: avatarUrl,
                                radius: 24,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 1,
                            right: 1,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: _emerald,
                                shape: BoxShape.circle,
                                border: Border.all(color: _bgColor, width: 2),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: _onSurface,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
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

  Widget _buildConversationTile(
    ChatConversationSummary conv,
    int currentUserId,
  ) {
    final partner = conv.partner;
    final avatarUrl = partner.fullAvatarUrl;
    final lastMsg = conv.lastMessage;
    final hasUnread = conv.unreadCount > 0;
    final isLastFromMe = lastMsg?.senderId == currentUserId;
    final hasPhoto = lastMsg?.imageUrl != null && lastMsg!.imageUrl!.isNotEmpty;
    final previewText = lastMsg == null
        ? 'Tap to send a message'
        : hasPhoto && lastMsg.text.isEmpty
            ? 'Sent a photo 📷'
            : lastMsg.text;
    final timeLabel = _formatRelativeTime(lastMsg?.timestamp);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: _bgColor,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          splashColor: _surfaceLow,
          highlightColor: _surfaceLow,
          onTap: () => _openChatWith(partner),
          onLongPress: () => _confirmDeleteConversation(conv, currentUserId),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Row(
              children: [
                Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: _buildAvatar(
                        name: partner.name,
                        avatarUrl: avatarUrl,
                        radius: 25,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: _emerald,
                          shape: BoxShape.circle,
                          border: Border.all(color: _bgColor, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    partner.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: _onSurface,
                                      fontSize: 15.5,
                                      fontWeight: hasUnread
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ),
                                if (partner.isVerified) ...[
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.verified_rounded,
                                    color: _primaryColor,
                                    size: 15,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (timeLabel.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text(
                              timeLabel,
                              style: TextStyle(
                                color: hasUnread ? _primaryColor : _outline,
                                fontSize: 11,
                                fontWeight: hasUnread
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          if (isLastFromMe) ...[
                            Icon(
                              Icons.done_all_rounded,
                              size: 15,
                              color: (lastMsg?.isRead ?? false)
                                  ? _primaryColor
                                  : _outline,
                            ),
                            const SizedBox(width: 4),
                          ] else if (hasPhoto) ...[
                            const Icon(
                              Icons.image_outlined,
                              size: 15,
                              color: _primaryColor,
                            ),
                            const SizedBox(width: 4),
                          ],
                          Expanded(
                            child: Text(
                              previewText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: hasUnread
                                    ? _onSurface
                                    : _onSurfaceVariant,
                                fontWeight: hasUnread
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (hasUnread)
                  Container(
                    width: 21,
                    height: 21,
                    decoration: const BoxDecoration(
                      color: _primaryColor,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${conv.unreadCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                else
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: _outline,
                    size: 19,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyInboxState(List<AuthorModel> availableUsers) {
    if (availableUsers.isNotEmpty) {
      return ListView(
        padding: const EdgeInsets.symmetric(vertical: 4),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Text(
              'Suggested friends to start chatting',
              style: TextStyle(color: _outline, fontSize: 12.5),
            ),
          ),
          ...availableUsers.map((user) {
            final avatarUrl = user.fullAvatarUrl;
            return ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: _buildAvatar(
                name: user.name,
                avatarUrl: avatarUrl,
                radius: 24,
              ),
              title: Text(
                user.name,
                style: const TextStyle(
                  color: _onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 14.5,
                ),
              ),
              subtitle: Text(
                '@${user.username}',
                style: const TextStyle(color: _outline, fontSize: 12.5),
              ),
              trailing: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                onPressed: () => _openChatWith(user),
                child: const Text(
                  'Chat',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
              ),
              onTap: () => _openChatWith(user),
            );
          }),
          _buildSecurityFooter(),
        ],
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: const BoxDecoration(
                color: _primaryFixed,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.near_me_rounded,
                color: _primaryColor,
                size: 38,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Your Messages',
              style: TextStyle(
                color: _onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Send private messages and photos to friends on ZieSocial.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _outline, fontSize: 13.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityFooter() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline_rounded, size: 15, color: _outline),
          SizedBox(width: 6),
          Text(
            'End-to-end encrypted with ZieSecurity',
            style: TextStyle(
              color: _outline,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loginVm = context.watch<LoginViewModel>();
    final currentUserId = loginVm.activeUserId;
    final currentName = loginVm.name;
    final currentAvatarUrl = ApiConstants.getImageUrl(loginVm.avatar);
    final posts = context.watch<PostViewModel>().posts;
    final chatVm = context.watch<ChatViewModel>();

    final query = _searchController.text;
    final conversations = chatVm.getConversationsFor(
      currentUserId,
      posts: posts,
      query: query,
    );
    final availableUsers = chatVm.getAvailableUsers(
      currentUserId,
      posts: posts,
      query: query,
    );
    final allUsers = chatVm.getAvailableUsers(currentUserId, posts: posts);
    final totalUnread = chatVm.getTotalUnreadCount(currentUserId);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: _bgColor),
      child: Scaffold(
        backgroundColor: _bgColor,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopAppBar(
                currentUserId: currentUserId,
                currentName: currentName,
                currentAvatarUrl: currentAvatarUrl,
                chatVm: chatVm,
                allUsers: allUsers,
              ),
              _buildSearchBar(query),
              _buildActiveFriendsCarousel(
                currentName: currentName,
                currentAvatarUrl: currentAvatarUrl,
                availableUsers: availableUsers,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Messages',
                          style: TextStyle(
                            color: _onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.1,
                          ),
                        ),
                        if (totalUnread > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: _primaryFixed,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '$totalUnread new',
                              style: const TextStyle(
                                color: _onPrimaryFixed,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => _showNewMessageSheet(allUsers),
                          style: TextButton.styleFrom(
                            foregroundColor: _onSurfaceVariant,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: Size.zero,
                          ),
                          child: const Text(
                            'New Chat',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        InkWell(
                          borderRadius: BorderRadius.circular(999),
                          onTap: () => _showNewMessageSheet(allUsers),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              color: _surfaceContainer,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.edit_square,
                              size: 17,
                              color: _onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: conversations.isEmpty
                    ? _buildEmptyInboxState(availableUsers)
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 12),
                        itemCount: conversations.length + 1,
                        itemBuilder: (context, index) {
                          if (index == conversations.length) {
                            return _buildSecurityFooter();
                          }
                          final conv = conversations[index];
                          return _buildConversationTile(conv, currentUserId);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
