import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/smart_image.dart';
import '../model/notification_model.dart';
import '../model/post_model.dart';
import '../viewmodel/chat_viewmodel.dart';
import '../viewmodel/notification_viewmodel.dart';
import 'chat_room_view.dart';
import 'profile_view.dart';

class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  static const Color _bgColor = Color(0xFFFFFFFF);
  static const Color _primaryColor = Color(0xFF4D41DF);
  static const Color _primaryFixed = Color(0xFFE3DFFF);
  static const Color _onSurface = Color(0xFF1A1B1E);
  static const Color _onSurfaceVariant = Color(0xFF464555);
  static const Color _outline = Color(0xFF777587);
  static const Color _surfaceLow = Color(0xFFF4F3F7);
  static const Color _surfaceContainer = Color(0xFFEFEDF1);
  static const Color _errorColor = Color(0xFFBA1A1A);
  static const Color _emerald = Color(0xFF059669);

  String _selectedFilter = 'all'; // all, engagement, chat, follow

  List<AppNotificationModel> _applyFilter(List<AppNotificationModel> items) {
    switch (_selectedFilter) {
      case 'engagement':
        return items
            .where((n) => n.type == 'like' || n.type == 'comment')
            .toList();
      case 'chat':
        return items
            .where(
              (n) =>
                  n.type == 'message' ||
                  n.type == 'reply' ||
                  n.type == 'mention' ||
                  n.type == 'reaction',
            )
            .toList();
      case 'follow':
        return items.where((n) => n.type == 'follow').toList();
      default:
        return items;
    }
  }

  String _formatRelativeTime(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inSeconds < 45) return 'Baru saja';
      if (diff.inMinutes < 60) return '${diff.inMinutes} mnt lalu';
      if (diff.inHours < 24) return '${diff.inHours} jam lalu';
      if (diff.inDays < 7) return '${diff.inDays} hari lalu';
      final day = dt.day.toString().padLeft(2, '0');
      final month = dt.month.toString().padLeft(2, '0');
      return '$day/$month/${dt.year}';
    } catch (_) {
      return 'Baru saja';
    }
  }

  Widget _buildTypeBadge(String type) {
    IconData icon;
    Color bgColor;
    switch (type) {
      case 'like':
        icon = Icons.favorite_rounded;
        bgColor = _errorColor;
      case 'comment':
        icon = Icons.chat_bubble_rounded;
        bgColor = const Color(0xFF0095F6);
      case 'follow':
        icon = Icons.person_add_alt_1_rounded;
        bgColor = _emerald;
      case 'reply':
        icon = Icons.reply_rounded;
        bgColor = _primaryColor;
      case 'mention':
        icon = Icons.alternate_email_rounded;
        bgColor = _primaryColor;
      case 'reaction':
        icon = Icons.emoji_emotions_rounded;
        bgColor = const Color(0xFFE11D48);
      default:
        icon = Icons.near_me_rounded;
        bgColor = _primaryColor;
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: Border.all(color: _bgColor, width: 1.8),
      ),
      child: Icon(icon, size: 11, color: Colors.white),
    );
  }

  void _handleNotificationTap(AppNotificationModel item) {
    context.read<NotificationViewModel>().markAsRead(item.id);

    final fallbackAuthor = AuthorModel(
      id: item.actorId,
      username: item.actorUsername,
      name: item.actorName,
      avatar: item.actorAvatar,
    );
    final resolvedAuthor = context.read<ChatViewModel>().resolveUserInfo(
      item.actorId,
      fallback: fallbackAuthor,
    );

    final isChatType = item.type == 'message' ||
        item.type == 'reply' ||
        item.type == 'mention' ||
        item.type == 'reaction';

    if (isChatType) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatRoomView(partner: resolvedAuthor),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileView(
          userId: resolvedAuthor.id,
          initialAuthor: resolvedAuthor,
        ),
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedFilter == key;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = key),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? _primaryColor : _surfaceLow,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : _onSurfaceVariant,
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationTile(AppNotificationModel item) {
    final avatarUrl = item.actorAvatar;
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;

    return Dismissible(
      key: ValueKey('notif_${item.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        context.read<NotificationViewModel>().deleteNotification(item.id);
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: _errorColor,
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      child: InkWell(
        onTap: () => _handleNotificationTap(item),
        child: Container(
          color: item.isRead
              ? _bgColor
              : _primaryFixed.withValues(alpha: 0.28),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 23,
                    backgroundColor: _surfaceContainer,
                    backgroundImage: resolveSmartImageProvider(avatarUrl),
                    child: !hasAvatar
                        ? Text(
                            item.actorName.isNotEmpty
                                ? item.actorName[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              color: _primaryColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          )
                        : null,
                  ),
                  Positioned(
                    right: -3,
                    bottom: -2,
                    child: _buildTypeBadge(item.type),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: item.actorName,
                            style: const TextStyle(
                              color: _onSurface,
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                              height: 1.35,
                            ),
                          ),
                          TextSpan(
                            text: ' (@${item.actorUsername}) ',
                            style: const TextStyle(
                              color: _outline,
                              fontWeight: FontWeight.w500,
                              fontSize: 12.5,
                              height: 1.35,
                            ),
                          ),
                          TextSpan(
                            text: item.body,
                            style: const TextStyle(
                              color: _onSurface,
                              fontWeight: FontWeight.w400,
                              fontSize: 13.5,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatRelativeTime(item.createdAt),
                      style: const TextStyle(
                        color: _outline,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (!item.isRead) ...[
                const SizedBox(width: 8),
                Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                    color: _primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<NotificationViewModel>();
    final filtered = _applyFilter(vm.notifications);

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
        title: const Text(
          'Notifikasi',
          style: TextStyle(
            color: _onSurface,
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          if (vm.unreadCount > 0)
            TextButton(
              onPressed: () => vm.markAllAsRead(),
              child: const Text(
                'Tandai dibaca',
                style: TextStyle(
                  color: _primaryColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              children: [
                _buildFilterChip('all', 'Semua'),
                _buildFilterChip('engagement', 'Suka & Komentar'),
                _buildFilterChip('chat', 'Pesan & Tag'),
                _buildFilterChip('follow', 'Pengikut'),
              ],
            ),
          ),
          const Divider(height: 1, color: _surfaceContainer),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: const BoxDecoration(
                              color: _surfaceLow,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.notifications_none_rounded,
                              size: 36,
                              color: _primaryColor,
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Belum ada notifikasi',
                            style: TextStyle(
                              color: _onSurface,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Saat ada yang menyukai, berkomentar, mengikuti, mengirim pesan, atau menandai Anda, notifikasinya akan tampil real-time di sini.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _onSurfaceVariant,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const Divider(
                      height: 1,
                      indent: 76,
                      color: _surfaceContainer,
                    ),
                    itemBuilder: (_, index) =>
                        _buildNotificationTile(filtered[index]),
                  ),
          ),
        ],
      ),
    );
  }
}
