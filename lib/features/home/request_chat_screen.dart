import 'package:flutter/material.dart';

import '../../core/l10n/l10n_extension.dart';
import '../../models/request_message.dart';
import '../../services/request_message_repository.dart';
import '../../services/supabase_service.dart';

/// Чат по конкретной заявке — здесь клиент и администратор согласовывают
/// детали и стоимость ремонта. Общий экран для обеих ролей: кто есть кто
/// определяется сравнением sender_id сообщения с id текущего пользователя,
/// а RLS на уровне базы уже гарантирует, что видно только переписку по
/// заявкам, к которым у пользователя есть доступ.
class RequestChatScreen extends StatefulWidget {
  const RequestChatScreen({
    super.key,
    required this.requestId,
    required this.title,
    required this.otherPartyName,
  });

  final String requestId;

  /// Заголовок экрана — обычно название заведения.
  final String title;

  /// Имя, которое показывается под чужими сообщениями.
  final String otherPartyName;

  @override
  State<RequestChatScreen> createState() => _RequestChatScreenState();
}

class _RequestChatScreenState extends State<RequestChatScreen> {
  final _repository = RequestMessageRepository();
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  late final Stream<List<RequestMessage>> _messagesStream;
  bool _isSending = false;

  String? get _currentUserId =>
      SupabaseService.client.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _messagesStream = _repository.watchMessages(widget.requestId);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _controller.clear();
    try {
      await _repository.send(requestId: widget.requestId, body: text);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.chatSendError)),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _scrollToBottomSoon() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.chatTitle(widget.title))),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<RequestMessage>>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        context.l10n.chatLoadError(snapshot.error.toString()),
                      ),
                    ),
                  );
                }

                final messages = snapshot.data ?? const [];
                if (messages.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(context.l10n.chatEmpty),
                    ),
                  );
                }

                _scrollToBottomSoon();
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return _MessageBubble(
                      message: message,
                      isMine: message.senderId == _currentUserId,
                      otherPartyName: widget.otherPartyName,
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: context.l10n.chatMessageHint,
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(24)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _isSending ? null : _send,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.otherPartyName,
  });

  final RequestMessage message;
  final bool isMine;
  final String otherPartyName;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bubbleColor =
        isMine ? colorScheme.primary : colorScheme.surfaceContainerHighest;
    final textColor = isMine ? colorScheme.onPrimary : colorScheme.onSurface;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMine)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  otherPartyName,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: textColor.withValues(alpha: 0.7),
                  ),
                ),
              ),
            Text(message.body, style: TextStyle(color: textColor)),
            const SizedBox(height: 2),
            Text(
              _formatTime(message.createdAt),
              style:
                  TextStyle(fontSize: 10, color: textColor.withValues(alpha: 0.7)),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatTime(DateTime dateTime) {
  final local = dateTime.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
