import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../core/smart_image.dart';
import '../model/message_model.dart';
import '../model/post_model.dart';
import '../viewmodel/chat_viewmodel.dart';
import '../viewmodel/login_viewmodel.dart';
import 'profile_view.dart';

class ChatRoomView extends StatefulWidget {
  final AuthorModel partner;

  const ChatRoomView({
    super.key,
    required this.partner,
  });

  @override
  State<ChatRoomView> createState() => _ChatRoomViewState();
}

class _ChatRoomViewState extends State<ChatRoomView> {
  static const Color _bgColor = Color(0xFFFFFFFF);
  static const Color _primaryColor = Color(0xFF4D41DF);
  static const Color _primaryFixed = Color(0xFFE3DFFF);
  static const Color _onSurface = Color(0xFF1A1B1E);
  static const Color _onSurfaceVariant = Color(0xFF464555);
  static const Color _outline = Color(0xFF777587);
  static const Color _outlineVariant = Color(0xFFC7C4D8);
  static const Color _surfaceLow = Color(0xFFF4F3F7);
  static const Color _surfaceContainer = Color(0xFFEFEDF1);
  static const Color _surfaceHighest = Color(0xFFE3E2E6);
  static const Color _emerald = Color(0xFF10B981);
  static const Color _emeraldText = Color(0xFF059669);

  static const List<String> _reactionEmojis = [
    '❤️',
    '😂',
    '😮',
    '😢',
    '🙏',
    '🔥',
  ];

  final TextEditingController _messageController = TextEditingController();
  final FocusNode _inputFocus = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  final Map<int, GlobalKey> _messageKeys = {};

  bool _hasText = false;
  DirectMessageModel? _replyTarget;
  String? _replyTargetSenderName;
  int? _highlightedMessageId;
  String? _mentionQuery;
  int _mentionStartOffset = -1;
  bool _isSelectionMode = false;
  final Set<int> _selectedMessageIds = {};

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_handleComposerChanged);
    _inputFocus.addListener(() {
      if (mounted) setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markReadAndScroll();
    });
  }

  void _handleComposerChanged() {
    final text = _messageController.text;
    final notEmpty = text.trim().isNotEmpty;

    final cursor = _messageController.selection.baseOffset;
    String? nextMentionQuery;
    int nextMentionStart = -1;

    if (cursor > 0 && cursor <= text.length) {
      final beforeCursor = text.substring(0, cursor);
      final match = RegExp(r'(?:^|\s)@([a-zA-Z0-9._]*)$').firstMatch(
        beforeCursor,
      );
      if (match != null) {
        nextMentionQuery = match.group(1) ?? '';
        nextMentionStart = beforeCursor.lastIndexOf('@');
      }
    }

    if (notEmpty != _hasText ||
        nextMentionQuery != _mentionQuery ||
        nextMentionStart != _mentionStartOffset) {
      setState(() {
        _hasText = notEmpty;
        _mentionQuery = nextMentionQuery;
        _mentionStartOffset = nextMentionStart;
      });
    }
  }

  void _insertMention(AuthorModel user) {
    final uname =
        user.username.isNotEmpty ? user.username : user.name.replaceAll(' ', '');
    final text = _messageController.text;
    final cursor = _messageController.selection.baseOffset;
    if (_mentionStartOffset < 0 ||
        _mentionStartOffset >= text.length ||
        cursor < _mentionStartOffset) {
      return;
    }

    final prefix = text.substring(0, _mentionStartOffset);
    final suffix = cursor <= text.length ? text.substring(cursor) : '';
    final inserted = '@$uname ';
    final updated = '$prefix$inserted$suffix';
    final newCursor = prefix.length + inserted.length;

    _messageController.value = TextEditingValue(
      text: updated,
      selection: TextSelection.collapsed(offset: newCursor),
    );
    setState(() {
      _mentionQuery = null;
      _mentionStartOffset = -1;
    });
  }

  void _markReadAndScroll() {
    if (!mounted) return;
    final currentUserId = context.read<LoginViewModel>().activeUserId;
    final chatVm = context.read<ChatViewModel>();
    chatVm.bindConversation(currentUserId, widget.partner.id);
    chatVm.markConversationRead(
      currentUserId: currentUserId,
      partnerId: widget.partner.id,
    );
    _scrollToBottom(animated: false);
  }

  void _scrollToBottom({bool animated = true}) {
    Future.delayed(const Duration(milliseconds: 60), () {
      if (!mounted || !_scrollController.hasClients) return;
      final target = _scrollController.position.maxScrollExtent;
      if (animated) {
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(target);
      }
    });
  }

  void _scrollToMessage(int messageId) {
    final key = _messageKeys[messageId];
    final ctx = key?.currentContext;
    if (ctx == null) return;

    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      alignment: 0.35,
    );
    setState(() => _highlightedMessageId = messageId);
    Future.delayed(const Duration(milliseconds: 1100), () {
      if (mounted && _highlightedMessageId == messageId) {
        setState(() => _highlightedMessageId = null);
      }
    });
  }

  void _setReplyTarget(
    DirectMessageModel msg, {
    required bool isMe,
    required AuthorModel partner,
  }) {
    HapticFeedback.lightImpact();
    final loginVm = context.read<LoginViewModel>();
    final myLabel = loginVm.username.isNotEmpty
        ? loginVm.username
        : loginVm.name;
    final partnerLabel =
        partner.username.isNotEmpty ? partner.username : partner.name;

    setState(() {
      _replyTarget = msg;
      _replyTargetSenderName = isMe ? myLabel : partnerLabel;
    });
    _inputFocus.requestFocus();
  }

  void _clearReplyTarget() {
    if (_replyTarget == null) return;
    setState(() {
      _replyTarget = null;
      _replyTargetSenderName = null;
    });
  }

  String _previewForReply(DirectMessageModel msg) {
    if (msg.text.isNotEmpty) {
      return msg.text.length > 180
          ? '${msg.text.substring(0, 180)}...'
          : msg.text;
    }
    if (msg.imageUrl != null && msg.imageUrl!.isNotEmpty) {
      return '📷 Photo';
    }
    return 'Message';
  }

  @override
  void dispose() {
    _messageController.removeListener(_handleComposerChanged);
    _messageController.dispose();
    _inputFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage([String? customText]) {
    final text = (customText ?? _messageController.text).trim();
    if (text.isEmpty) return;

    final currentUserId = context.read<LoginViewModel>().activeUserId;
    final reply = _replyTarget;
    final replySender = _replyTargetSenderName;

    context.read<ChatViewModel>().sendMessage(
          senderId: currentUserId,
          receiverId: widget.partner.id,
          text: text,
          receiverInfo: widget.partner,
          replyToId: reply?.id,
          replyToSenderName: reply != null ? replySender : null,
          replyToText: reply != null ? _previewForReply(reply) : null,
        );

    if (customText == null) {
      _messageController.clear();
    }
    _clearReplyTarget();
    _scrollToBottom();
  }

  Future<void> _pickAndSendPhoto(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 80,
      );
      if (picked == null || !mounted) return;

      final bytes = await picked.readAsBytes();
      final dataUrl = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      if (!mounted) return;
      final currentUserId = context.read<LoginViewModel>().activeUserId;
      final caption = _messageController.text.trim();
      final reply = _replyTarget;
      final replySender = _replyTargetSenderName;

      context.read<ChatViewModel>().sendMessage(
            senderId: currentUserId,
            receiverId: widget.partner.id,
            text: caption,
            imageUrl: dataUrl,
            receiverInfo: widget.partner,
            replyToId: reply?.id,
            replyToSenderName: reply != null ? replySender : null,
            replyToText: reply != null ? _previewForReply(reply) : null,
          );

      if (caption.isNotEmpty) {
        _messageController.clear();
      }
      _clearReplyTarget();
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengirim foto: $e')),
        );
      }
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _bgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: _surfaceHighest,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: _primaryFixed,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.photo_library_outlined,
                    color: _primaryColor,
                  ),
                ),
                title: const Text(
                  'Choose Photo from Gallery',
                  style: TextStyle(
                    color: _onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndSendPhoto(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: _primaryFixed,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt_outlined,
                    color: _primaryColor,
                  ),
                ),
                title: const Text(
                  'Take a Photo',
                  style: TextStyle(
                    color: _onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndSendPhoto(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } catch (_) {
      return '';
    }
  }

  void _showMessageOptions(
    DirectMessageModel msg,
    bool isMe,
    AuthorModel resolvedPartner,
  ) {
    final activeReaction = msg.activeReaction;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _bgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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
                // Bar Emoji Reaksi ala Instagram DM
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _surfaceLow,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: _reactionEmojis.map((emoji) {
                      final isSelected = activeReaction == emoji;
                      return GestureDetector(
                        onTap: () {
                          Navigator.pop(ctx);
                          context
                              .read<ChatViewModel>()
                              .setMessageReaction(msg.id, emoji);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isSelected ? _primaryFixed : null,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 22),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  leading: const Icon(
                    Icons.reply_rounded,
                    color: _primaryColor,
                  ),
                  title: const Text(
                    'Balas / Tag Pesan',
                    style: TextStyle(
                      color: _onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _setReplyTarget(
                      msg,
                      isMe: isMe,
                      partner: resolvedPartner,
                    );
                  },
                ),
                if (msg.text.isNotEmpty)
                  ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    leading: const Icon(
                      Icons.copy_rounded,
                      color: _onSurfaceVariant,
                    ),
                    title: const Text(
                      'Salin Teks',
                      style: TextStyle(
                        color: _onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      Clipboard.setData(ClipboardData(text: msg.text));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Pesan disalin ke clipboard.'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  leading: const Icon(
                    Icons.checklist_rounded,
                    color: _onSurfaceVariant,
                  ),
                  title: const Text(
                    'Pilih Pesan',
                    style: TextStyle(
                      color: _onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _isSelectionMode = true;
                      _selectedMessageIds
                        ..clear()
                        ..add(msg.id);
                    });
                  },
                ),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  leading: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.redAccent,
                  ),
                  title: const Text(
                    'Hapus Pesan',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _confirmDeleteSingleMessage(msg, isMe);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDeleteSingleMessage(
    DirectMessageModel msg,
    bool isMe,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Hapus Pesan?',
          style: TextStyle(color: _onSurface, fontWeight: FontWeight.w700),
        ),
        content: Text(
          isMe
              ? 'Pilih apakah pesan ini ingin dihapus untuk semua orang atau hanya untuk Anda.'
              : 'Pesan ini akan dihapus dari tampilan chat Anda.',
          style: const TextStyle(color: _onSurfaceVariant, fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: _outline)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<ChatViewModel>().deleteMessageForMe(msg.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Pesan dihapus untuk Anda.'),
                  duration: Duration(seconds: 1),
                ),
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
          if (isMe)
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () {
                Navigator.pop(ctx);
                context.read<ChatViewModel>().deleteMessage(msg.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Pesan ditarik untuk semua orang.'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              child: const Text('Hapus untuk Semua'),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteSelectedMessages(
    List<DirectMessageModel> allMessages,
    int currentUserId,
    int partnerId,
  ) async {
    if (_selectedMessageIds.isEmpty) return;
    final selectedMsgs = allMessages
        .where((m) => _selectedMessageIds.contains(m.id))
        .toList();
    final allAreMine =
        selectedMsgs.isNotEmpty &&
        selectedMsgs.every((m) => m.senderId == currentUserId);
    final count = _selectedMessageIds.length;

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Hapus $count Pesan?',
          style: const TextStyle(
            color: _onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          allAreMine
              ? 'Pilih apakah pesan terpilih ingin dihapus untuk semua orang atau hanya untuk Anda.'
              : 'Pesan terpilih akan dihapus dari tampilan chat Anda.',
          style: const TextStyle(color: _onSurfaceVariant, fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: _outline)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<ChatViewModel>().deleteMessagesForMe(
                _selectedMessageIds.toList(),
              );
              setState(() {
                _isSelectionMode = false;
                _selectedMessageIds.clear();
              });
            },
            child: const Text(
              'Hapus untuk Saya',
              style: TextStyle(
                color: _primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (allAreMine)
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () async {
                Navigator.pop(ctx);
                final ids = _selectedMessageIds.toList();
                setState(() {
                  _isSelectionMode = false;
                  _selectedMessageIds.clear();
                });
                await context.read<ChatViewModel>().deleteMessagesForEveryone(
                  currentUserId: currentUserId,
                  partnerId: partnerId,
                  messageIds: ids,
                );
              },
              child: const Text('Hapus untuk Semua'),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmClearConversation(
    int currentUserId,
    AuthorModel partner,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Hapus Obrolan dengan @${partner.username}?',
          style: const TextStyle(
            color: _onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: const Text(
          'Anda bisa menghapus riwayat chat untuk diri sendiri saja atau menghapus permanen untuk kedua pihak.',
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
                partnerId: partner.id,
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
                partnerId: partner.id,
                forEveryone: true,
              );
            },
            child: const Text('Hapus untuk Semua'),
          ),
        ],
      ),
    );
  }

  void _openPartnerProfile(AuthorModel resolvedPartner) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileView(
          userId: resolvedPartner.id,
          initialAuthor: resolvedPartner,
        ),
      ),
    );
  }

  void _openMentionedUsername(String username) {
    final currentUserId = context.read<LoginViewModel>().activeUserId;
    final chatVm = context.read<ChatViewModel>();
    final users = chatVm.getAvailableUsers(currentUserId);
    final lower = username.toLowerCase();

    AuthorModel? target;
    if (widget.partner.username.toLowerCase() == lower) {
      target = widget.partner;
    } else {
      for (final u in users) {
        if (u.username.toLowerCase() == lower) {
          target = u;
          break;
        }
      }
    }

    if (target != null) {
      _openPartnerProfile(target);
      return;
    }

    final loginVm = context.read<LoginViewModel>();
    if (loginVm.username.toLowerCase() == lower) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProfileView(userId: currentUserId),
        ),
      );
    }
  }

  Widget _buildAvatar({
    required String name,
    required String? avatarUrl,
    double radius = 20,
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

  Widget _buildHeader(
    AuthorModel resolvedPartner,
    String? avatarUrl,
    int currentUserId,
    List<DirectMessageModel> messages,
  ) {
    if (_isSelectionMode) {
      return Container(
        padding: const EdgeInsets.fromLTRB(6, 6, 8, 8),
        decoration: BoxDecoration(
          color: _bgColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.close_rounded, color: _onSurface),
              tooltip: 'Batal pilih',
              onPressed: () {
                setState(() {
                  _isSelectionMode = false;
                  _selectedMessageIds.clear();
                });
              },
            ),
            const SizedBox(width: 4),
            Text(
              '${_selectedMessageIds.length} dipilih',
              style: const TextStyle(
                color: _onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.select_all_rounded, color: _onSurfaceVariant),
              tooltip: 'Pilih semua',
              onPressed: () {
                setState(() {
                  if (_selectedMessageIds.length == messages.length) {
                    _selectedMessageIds.clear();
                  } else {
                    _selectedMessageIds
                      ..clear()
                      ..addAll(messages.map((m) => m.id));
                  }
                });
              },
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: Colors.redAccent,
              ),
              tooltip: 'Hapus terpilih',
              onPressed: _selectedMessageIds.isEmpty
                  ? null
                  : () => _confirmDeleteSelectedMessages(
                      messages,
                      currentUserId,
                      resolvedPartner.id,
                    ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(6, 6, 8, 8),
      decoration: BoxDecoration(
        color: _bgColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: _onSurface,
              size: 24,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _openPartnerProfile(resolvedPartner),
              child: Row(
                children: [
                  Stack(
                    children: [
                      _buildAvatar(
                        name: resolvedPartner.name,
                        avatarUrl: avatarUrl,
                        radius: 21,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _emerald,
                            shape: BoxShape.circle,
                            border: Border.all(color: _bgColor, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                resolvedPartner.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: _onSurface,
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (resolvedPartner.isVerified) ...[
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
                            Flexible(
                              child: Text(
                                '@${resolvedPartner.username}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: _onSurfaceVariant,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Container(
                              width: 4,
                              height: 4,
                              margin: const EdgeInsets.symmetric(horizontal: 5),
                              decoration: const BoxDecoration(
                                color: _outlineVariant,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const Text(
                              'Active now',
                              style: TextStyle(
                                color: _emeraldText,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.call_outlined,
              color: _onSurfaceVariant,
              size: 21,
            ),
            tooltip: 'Audio call',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Calling @${resolvedPartner.username}...'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.info_outline_rounded,
              color: _onSurfaceVariant,
              size: 21,
            ),
            tooltip: 'Profile details',
            onPressed: () => _openPartnerProfile(resolvedPartner),
          ),
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert_rounded,
              color: _onSurfaceVariant,
              size: 21,
            ),
            color: _bgColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            onSelected: (value) {
              if (value == 'select') {
                setState(() {
                  _isSelectionMode = true;
                  _selectedMessageIds.clear();
                });
              } else if (value == 'clear') {
                _confirmClearConversation(currentUserId, resolvedPartner);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'select',
                child: Row(
                  children: [
                    Icon(Icons.checklist_rounded, size: 19, color: _onSurfaceVariant),
                    SizedBox(width: 10),
                    Text('Pilih Pesan', style: TextStyle(color: _onSurface)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_sweep_outlined,
                      size: 19,
                      color: Colors.redAccent,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Hapus Obrolan',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileIntroHeader(
    AuthorModel partner,
    String? avatarUrl,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _primaryFixed.withValues(alpha: 0.6),
            ),
            child: _buildAvatar(
              name: partner.name,
              avatarUrl: avatarUrl,
              radius: 38,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                partner.name,
                style: const TextStyle(
                  color: _onSurface,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (partner.isVerified) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.verified_rounded,
                  color: _primaryColor,
                  size: 16,
                ),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '@${partner.username} · ZieSocial',
            style: const TextStyle(
              color: _outline,
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => _openPartnerProfile(partner),
            style: OutlinedButton.styleFrom(
              backgroundColor: _surfaceLow,
              side: BorderSide.none,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              minimumSize: Size.zero,
            ),
            child: const Text(
              'View Profile',
              style: TextStyle(
                color: _onSurface,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: _surfaceLow,
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.schedule_rounded, size: 13, color: _outline),
                SizedBox(width: 5),
                Text(
                  'Today · Geser pesan untuk membalas/tag',
                  style: TextStyle(
                    color: _onSurfaceVariant,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuotedReplySnippet({
    required DirectMessageModel msg,
    required bool isMe,
  }) {
    final senderLabel = msg.replyToSenderName ?? 'Pesan';
    final replyPreview = msg.replyToText ?? '';

    return GestureDetector(
      onTap: () {
        if (msg.replyToId != null) {
          _scrollToMessage(msg.replyToId!);
        }
      },
      child: Padding(
        padding: EdgeInsets.only(bottom: 4, left: isMe ? 0 : 38),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.reply_rounded,
                  size: 12,
                  color: _outline,
                ),
                const SizedBox(width: 4),
                Text(
                  'Membalas @$senderLabel',
                  style: const TextStyle(
                    color: _outline,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.68,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: _surfaceLow,
                borderRadius: BorderRadius.circular(14),
                border: Border(
                  left: BorderSide(
                    color: isMe ? _primaryColor : _outlineVariant,
                    width: 3,
                  ),
                ),
              ),
              child: Text(
                replyPreview,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _onSurfaceVariant,
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble({
    required DirectMessageModel msg,
    required bool isMe,
    required AuthorModel partner,
    required String? partnerAvatarUrl,
  }) {
    final itemKey = _messageKeys.putIfAbsent(msg.id, () => GlobalKey());
    final hasImage = msg.imageUrl != null && msg.imageUrl!.isNotEmpty;
    final hasReply =
        (msg.replyToText != null && msg.replyToText!.isNotEmpty) ||
            msg.replyToId != null;
    final activeReaction = msg.activeReaction;
    final isSingleEmoji =
        !hasImage && !hasReply && (msg.text == '❤️' || msg.text == '🔥' || msg.text == '😍');
    final timeStr = _formatTime(msg.timestamp);
    final isHighlighted = _highlightedMessageId == msg.id;
    final isSelected = _selectedMessageIds.contains(msg.id);

    return _SwipeToReplyWrapper(
      key: ValueKey('swipe_msg_${msg.id}'),
      swipeLeft: isMe,
      onReply: () => _setReplyTarget(msg, isMe: isMe, partner: partner),
      child: GestureDetector(
        onTap: _isSelectionMode
            ? () {
                setState(() {
                  if (isSelected) {
                    _selectedMessageIds.remove(msg.id);
                    if (_selectedMessageIds.isEmpty) {
                      _isSelectionMode = false;
                    }
                  } else {
                    _selectedMessageIds.add(msg.id);
                  }
                });
              }
            : null,
        child: AnimatedContainer(
          key: itemKey,
          duration: const Duration(milliseconds: 250),
          padding: EdgeInsets.only(
            bottom: activeReaction != null ? 20 : 12,
            top: (isHighlighted || isSelected) ? 4 : 0,
          ),
          decoration: (isHighlighted || isSelected)
              ? BoxDecoration(
                  color: _primaryFixed.withValues(alpha: isSelected ? 0.55 : 0.45),
                  borderRadius: BorderRadius.circular(16),
                )
              : null,
          child: Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (hasReply) _buildQuotedReplySnippet(msg: msg, isMe: isMe),
              Row(
                mainAxisAlignment:
                    isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (_isSelectionMode)
                    Padding(
                      padding: const EdgeInsets.only(right: 8, bottom: 6),
                      child: Icon(
                        isSelected
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: isSelected ? _primaryColor : _outlineVariant,
                        size: 20,
                      ),
                    ),
                  if (!isMe) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2, right: 8),
                    child: _buildAvatar(
                      name: partner.name,
                      avatarUrl: partnerAvatarUrl,
                      radius: 14,
                    ),
                  ),
                ],
                Flexible(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.78,
                    ),
                    child: GestureDetector(
                      onTap: _isSelectionMode
                          ? () {
                              setState(() {
                                if (isSelected) {
                                  _selectedMessageIds.remove(msg.id);
                                  if (_selectedMessageIds.isEmpty) {
                                    _isSelectionMode = false;
                                  }
                                } else {
                                  _selectedMessageIds.add(msg.id);
                                }
                              });
                            }
                          : null,
                      onDoubleTap: _isSelectionMode
                          ? null
                          : () {
                              context
                                  .read<ChatViewModel>()
                                  .toggleLikeMessage(msg.id);
                            },
                      onLongPress: _isSelectionMode
                          ? null
                          : () => _showMessageOptions(msg, isMe, partner),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            padding: isSingleEmoji
                                ? const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  )
                                : hasImage
                                    ? const EdgeInsets.all(8)
                                    : const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 11,
                                      ),
                            decoration: isSingleEmoji
                                ? null
                                : BoxDecoration(
                                    color: isMe ? _primaryColor : _surfaceLow,
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(isMe ? 18 : 4),
                                      topRight: Radius.circular(isMe ? 4 : 18),
                                      bottomLeft: const Radius.circular(18),
                                      bottomRight: const Radius.circular(18),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: isMe
                                            ? _primaryColor.withValues(
                                                alpha: 0.22,
                                              )
                                            : Colors.black.withValues(
                                                alpha: 0.04,
                                              ),
                                        blurRadius: isMe ? 10 : 4,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                            child: Column(
                              crossAxisAlignment: isMe
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                if (hasImage) ...[
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: buildSmartImage(
                                      msg.imageUrl!,
                                      width: 220,
                                      height: 170,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  if (msg.text.isNotEmpty)
                                    const SizedBox(height: 8),
                                ],
                                if (msg.text.isNotEmpty)
                                  Padding(
                                    padding: hasImage
                                        ? const EdgeInsets.symmetric(
                                            horizontal: 6,
                                          )
                                        : EdgeInsets.zero,
                                    child: isSingleEmoji
                                        ? Text(
                                            msg.text,
                                            style: const TextStyle(
                                              fontSize: 34,
                                              height: 1.3,
                                            ),
                                          )
                                        : _MentionText(
                                            text: msg.text,
                                            baseColor: isMe
                                                ? Colors.white
                                                : _onSurface,
                                            mentionColor: isMe
                                                ? Colors.white
                                                : _primaryColor,
                                            onMentionTap:
                                                _openMentionedUsername,
                                          ),
                                  ),
                              ],
                            ),
                          ),
                          if (activeReaction != null)
                            Positioned(
                              bottom: -11,
                              right: isMe ? null : 10,
                              left: isMe ? 10 : null,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _bgColor,
                                  borderRadius: BorderRadius.circular(999),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.10),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  activeReaction,
                                  style: const TextStyle(fontSize: 11),
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
            if (!isSingleEmoji && timeStr.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(
                  top: activeReaction != null ? 13 : 4,
                  left: isMe ? 0 : 38,
                  right: isMe ? 4 : 0,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      timeStr,
                      style: const TextStyle(
                        color: _outline,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.done_all_rounded,
                        size: 14,
                        color: msg.isRead ? _primaryColor : _outline,
                      ),
                    ] else ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _setReplyTarget(
                          msg,
                          isMe: false,
                          partner: partner,
                        ),
                        child: const Text(
                          'Reply',
                          style: TextStyle(
                            color: _primaryColor,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildMentionSuggestionsOverlay(
    int currentUserId,
    AuthorModel partner,
  ) {
    if (_mentionQuery == null) return const SizedBox.shrink();

    final chatVm = context.watch<ChatViewModel>();
    final candidates = <int, AuthorModel>{
      partner.id: partner,
    };
    for (final u in chatVm.getAvailableUsers(currentUserId)) {
      candidates.putIfAbsent(u.id, () => u);
    }

    final q = _mentionQuery!.toLowerCase();
    final matched = candidates.values.where((u) {
      if (q.isEmpty) return true;
      return u.username.toLowerCase().contains(q) ||
          u.name.toLowerCase().contains(q);
    }).take(4).toList();

    if (matched.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _surfaceContainer),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: matched.map((user) {
          return ListTile(
            dense: true,
            leading: _buildAvatar(
              name: user.name,
              avatarUrl: user.fullAvatarUrl,
              radius: 16,
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
                      fontSize: 13,
                    ),
                  ),
                ),
                if (user.isVerified) ...[
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.verified_rounded,
                    color: _primaryColor,
                    size: 13,
                  ),
                ],
              ],
            ),
            subtitle: Text(
              '@${user.username}',
              style: const TextStyle(color: _outline, fontSize: 11.5),
            ),
            onTap: () => _insertMention(user),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildReplyPreviewBanner() {
    final target = _replyTarget;
    if (target == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
      decoration: const BoxDecoration(
        color: _surfaceLow,
        border: Border(
          left: BorderSide(color: _primaryColor, width: 3.5),
          bottom: BorderSide(color: _surfaceContainer, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Membalas kepada @${_replyTargetSenderName ?? 'Pengguna'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _primaryColor,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _previewForReply(target),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18, color: _outline),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: _clearReplyTarget,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomComposer(int currentUserId, AuthorModel partner) {
    final isFocused = _inputFocus.hasFocus;
    final suggestions = [
      '🙌 Absolutely!',
      '🗓️ Today?',
      '❤️',
      '🔥',
      '😍',
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildMentionSuggestionsOverlay(currentUserId, partner),
        Container(
          decoration: BoxDecoration(
            color: _bgColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildReplyPreviewBanner(),

                // Suggestions Chip Rail (hidden while composing a reply to save space)
                if (_replyTarget == null)
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 2),
                      itemCount: suggestions.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final chip = suggestions[index];
                        return GestureDetector(
                          onTap: () => _sendMessage(chip),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: _surfaceLow,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              chip,
                              style: const TextStyle(
                                color: _onSurface,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                // Main Message Input Control Row
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
                  child: Row(
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: _showAttachmentOptions,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: _surfaceLow,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.photo_camera_outlined,
                            color: _onSurfaceVariant,
                            size: 21,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _surfaceLow,
                            borderRadius: BorderRadius.circular(999),
                            border: isFocused
                                ? Border.all(color: _primaryColor, width: 1.5)
                                : null,
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                tooltip: 'Tag teman (@username)',
                                icon: const Icon(
                                  Icons.alternate_email_rounded,
                                  color: _onSurfaceVariant,
                                  size: 19,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 30,
                                  minHeight: 34,
                                ),
                                onPressed: () {
                                  final current = _messageController.text;
                                  final needsSpace = current.isNotEmpty &&
                                      !current.endsWith(' ');
                                  final next =
                                      '$current${needsSpace ? ' ' : ''}@';
                                  _messageController.value = TextEditingValue(
                                    text: next,
                                    selection: TextSelection.collapsed(
                                      offset: next.length,
                                    ),
                                  );
                                  _inputFocus.requestFocus();
                                },
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: TextField(
                                  controller: _messageController,
                                  focusNode: _inputFocus,
                                  style: const TextStyle(
                                    color: _onSurface,
                                    fontSize: 13.5,
                                  ),
                                  cursorColor: _primaryColor,
                                  textInputAction: TextInputAction.send,
                                  onSubmitted: (_) => _sendMessage(),
                                  decoration: const InputDecoration(
                                    hintText: 'Message... (ketik @ untuk tag)',
                                    hintStyle: TextStyle(
                                      color: _outline,
                                      fontSize: 13.5,
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding:
                                        EdgeInsets.symmetric(vertical: 10),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.attach_file_rounded,
                                  color: _onSurfaceVariant,
                                  size: 20,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 30,
                                  minHeight: 34,
                                ),
                                onPressed: _showAttachmentOptions,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _primaryColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _primaryColor.withValues(alpha: 0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            _hasText
                                ? Icons.send_rounded
                                : Icons.favorite_rounded,
                            color: Colors.white,
                            size: 19,
                          ),
                          tooltip: _hasText ? 'Send Message' : 'Send Heart',
                          onPressed: () =>
                              _hasText ? _sendMessage() : _sendMessage('❤️'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.watch<LoginViewModel>().activeUserId;
    final chatVm = context.watch<ChatViewModel>();
    final resolvedPartner = chatVm.resolveUserInfo(
      widget.partner.id,
      fallback: widget.partner,
    );
    final avatarUrl = resolvedPartner.fullAvatarUrl;
    final messages = chatVm.getMessagesBetween(
      currentUserId,
      resolvedPartner.id,
    );

    if (messages.any(
      (m) =>
          m.senderId == resolvedPartner.id &&
          m.receiverId == currentUserId &&
          !m.isRead,
    )) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        chatVm.markConversationRead(
          currentUserId: currentUserId,
          partnerId: resolvedPartner.id,
        );
        _scrollToBottom();
      });
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: _bgColor),
      child: Scaffold(
        backgroundColor: _bgColor,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildHeader(resolvedPartner, avatarUrl, currentUserId, messages),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  itemCount: messages.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _buildProfileIntroHeader(
                        resolvedPartner,
                        avatarUrl,
                      );
                    }

                    final msg = messages[index - 1];
                    final isMe = msg.senderId == currentUserId;

                    return _buildMessageBubble(
                      msg: msg,
                      isMe: isMe,
                      partner: resolvedPartner,
                      partnerAvatarUrl: avatarUrl,
                    );
                  },
                ),
              ),
              _buildBottomComposer(currentUserId, resolvedPartner),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget teks dengan highlight & tap-to-profile otomatis untuk @mention.
class _MentionText extends StatefulWidget {
  final String text;
  final Color baseColor;
  final Color mentionColor;
  final ValueChanged<String> onMentionTap;

  const _MentionText({
    required this.text,
    required this.baseColor,
    required this.mentionColor,
    required this.onMentionTap,
  });

  @override
  State<_MentionText> createState() => _MentionTextState();
}

class _MentionTextState extends State<_MentionText> {
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();

    final regex = RegExp(r'@[a-zA-Z0-9._]+');
    final matches = regex.allMatches(widget.text).toList();

    if (matches.isEmpty) {
      return Text(
        widget.text,
        style: TextStyle(
          color: widget.baseColor,
          fontSize: 13.5,
          height: 1.4,
        ),
      );
    }

    final spans = <InlineSpan>[];
    int currentIndex = 0;

    for (final match in matches) {
      if (match.start > currentIndex) {
        spans.add(
          TextSpan(
            text: widget.text.substring(currentIndex, match.start),
            style: TextStyle(
              color: widget.baseColor,
              fontSize: 13.5,
              height: 1.4,
            ),
          ),
        );
      }
      final fullToken = match.group(0)!;
      final username = fullToken.substring(1);
      final recognizer = TapGestureRecognizer()
        ..onTap = () => widget.onMentionTap(username);
      _recognizers.add(recognizer);

      spans.add(
        TextSpan(
          text: fullToken,
          recognizer: recognizer,
          style: TextStyle(
            color: widget.mentionColor,
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            decoration: TextDecoration.underline,
            decorationColor: widget.mentionColor.withValues(alpha: 0.6),
            height: 1.4,
          ),
        ),
      );
      currentIndex = match.end;
    }

    if (currentIndex < widget.text.length) {
      spans.add(
        TextSpan(
          text: widget.text.substring(currentIndex),
          style: TextStyle(
            color: widget.baseColor,
            fontSize: 13.5,
            height: 1.4,
          ),
        ),
      );
    }

    return RichText(text: TextSpan(children: spans));
  }
}

/// Wrapper geser pendek ala Instagram DM untuk membalas/tag pesan tanpa
/// menggeser bubble terlalu jauh ke seluruh layar.
class _SwipeToReplyWrapper extends StatefulWidget {
  final bool swipeLeft;
  final VoidCallback onReply;
  final Widget child;

  const _SwipeToReplyWrapper({
    super.key,
    required this.swipeLeft,
    required this.onReply,
    required this.child,
  });

  @override
  State<_SwipeToReplyWrapper> createState() => _SwipeToReplyWrapperState();
}

class _SwipeToReplyWrapperState extends State<_SwipeToReplyWrapper>
    with SingleTickerProviderStateMixin {
  static const double _maxDrag = 52.0;
  static const double _triggerThreshold = 34.0;
  static const Color _primaryColor = Color(0xFF4D41DF);
  static const Color _primaryFixed = Color(0xFFE3DFFF);

  late final AnimationController _springController;
  Animation<double>? _springAnimation;
  double _dragOffset = 0.0;
  bool _triggeredHaptic = false;

  @override
  void initState() {
    super.initState();
    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    )..addListener(() {
        if (!mounted || _springAnimation == null) return;
        setState(() {
          _dragOffset = _springAnimation!.value;
        });
      });
  }

  @override
  void dispose() {
    _springController.dispose();
    super.dispose();
  }

  void _handleDragStart(DragStartDetails _) {
    _springController.stop();
    _springAnimation = null;
    _triggeredHaptic = false;
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    final damping = _dragOffset.abs() >= _triggerThreshold ? 0.35 : 0.78;
    final nextOffset = _dragOffset + details.delta.dx * damping;
    final clamped = widget.swipeLeft
        ? nextOffset.clamp(-_maxDrag, 0.0)
        : nextOffset.clamp(0.0, _maxDrag);

    if (!_triggeredHaptic && clamped.abs() >= _triggerThreshold) {
      _triggeredHaptic = true;
      HapticFeedback.selectionClick();
    }

    if (clamped != _dragOffset) {
      setState(() {
        _dragOffset = clamped;
      });
    }
  }

  void _handleDragEndOrCancel() {
    final shouldTrigger = _dragOffset.abs() >= _triggerThreshold;
    if (shouldTrigger) {
      widget.onReply();
    }
    if (_dragOffset == 0.0) return;
    _springAnimation = Tween<double>(
      begin: _dragOffset,
      end: 0.0,
    ).animate(
      CurvedAnimation(
        parent: _springController,
        curve: Curves.easeOutCubic,
      ),
    );
    _springController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_dragOffset.abs() / _triggerThreshold).clamp(0.0, 1.0);
    final isReady = _dragOffset.abs() >= _triggerThreshold;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: _handleDragStart,
      onHorizontalDragUpdate: _handleDragUpdate,
      onHorizontalDragEnd: (_) => _handleDragEndOrCancel(),
      onHorizontalDragCancel: _handleDragEndOrCancel,
      child: Stack(
        alignment: Alignment.center,
        fit: StackFit.passthrough,
        children: [
          if (_dragOffset != 0.0)
            Positioned(
              left: widget.swipeLeft ? null : 10,
              right: widget.swipeLeft ? 10 : null,
              child: Opacity(
                opacity: progress,
                child: Transform.scale(
                  scale: 0.65 + (0.35 * progress),
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: isReady ? _primaryColor : _primaryFixed,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.reply_rounded,
                      color: isReady ? Colors.white : _primaryColor,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ),
          Transform.translate(
            offset: Offset(_dragOffset, 0),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}
