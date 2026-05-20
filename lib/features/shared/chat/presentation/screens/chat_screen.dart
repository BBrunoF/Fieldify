import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../controllers/chat_controller.dart';
import '../../data/models/message_model.dart';
import '../widgets/message_bubble.dart';
import '../widgets/reschedule_card.dart';
import '../widgets/reschedule_dialog.dart';

class ChatScreen extends StatefulWidget {
  final String requestId;
  final String jobStatus;
  final String counterpartyName;
  final String jobTitle;
  final ChatController? controller;

  const ChatScreen({
    super.key,
    required this.requestId,
    required this.jobStatus,
    required this.counterpartyName,
    required this.jobTitle,
    this.controller,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final ChatController _controller;
  late final bool _ownsController;
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  String? _shownError;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ??
        ChatController(
          requestId: widget.requestId,
          jobStatus: widget.jobStatus,
        );
    _ownsController = widget.controller == null;
    _controller.addListener(_onChanged);
    _controller.loadChatHistory();
  }

  void _onChanged() {
    if (!mounted) return;
    setState(() {});
    _maybeShowError();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _maybeShowError() {
    final err = _controller.error;
    if (err != null && err != _shownError) {
      _shownError = err;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err)),
      );
      _controller.clearError();
      _shownError = null;
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    if (_ownsController) _controller.dispose();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _inputController.text;
    if (text.trim().isEmpty) return;
    _inputController.clear();
    await _controller.sendMessage(text);
  }

  Future<void> _proposeReschedule() async {
    final picked = await showReschedulePicker(context);
    if (picked == null) return;
    await _controller.proposeReschedule(picked);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: FieldifyColors.g800,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: FieldifyColors.surface,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildHeader(),
              Expanded(child: _buildMessages()),
              _buildComposer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: FieldifyColors.g800,
      padding: const EdgeInsets.fromLTRB(8, 6, 20, 14),
      child: Row(
        children: [
          IconButton(
            key: const Key('chatBackButton'),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.counterpartyName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  widget.jobTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: FieldifyColors.g200,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessages() {
    if (_controller.isLoading && _controller.messages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    final messages = _controller.messages;
    if (messages.isEmpty) {
      return Center(
        child: Text(
          'No messages yet. Say hello!',
          style: GoogleFonts.dmSans(
            fontSize: 13,
            color: FieldifyColors.ink4,
          ),
        ),
      );
    }
    final uid = _controller.currentUserId;
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: messages.length,
      itemBuilder: (_, i) {
        final m = messages[i];
        final isMine = m.senderId == uid;
        if (m.type == MessageType.reschedule) {
          return RescheduleCard(
            key: Key('rescheduleCard_${m.id}'),
            message: m,
            isMine: isMine,
            onAccept: () => _controller.confirmReschedule(m),
            onReject: () => _controller.rejectReschedule(m),
          );
        }
        return MessageBubble(message: m, isMine: isMine);
      },
    );
  }

  Widget _buildComposer() {
    final bottom = MediaQuery.of(context).padding.bottom;

    if (_controller.isLocked) {
      return Container(
        width: double.infinity,
        color: Colors.white,
        padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottom),
        child: Text(
          'This job is no longer active. The chat is read-only.',
          key: const Key('chatLockedNotice'),
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            color: FieldifyColors.ink3,
          ),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: FieldifyColors.border)),
      ),
      padding: EdgeInsets.fromLTRB(12, 10, 12, 10 + bottom),
      child: Row(
        children: [
          IconButton(
            key: const Key('proposeRescheduleButton'),
            icon: const Icon(Icons.event_repeat, color: FieldifyColors.g800),
            tooltip: 'Propose a new date/time',
            onPressed: _proposeReschedule,
          ),
          Expanded(
            child: TextField(
              key: const Key('chatInputField'),
              controller: _inputController,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Message…',
                hintStyle: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: FieldifyColors.ink4,
                ),
                filled: true,
                fillColor: FieldifyColors.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            key: const Key('chatSendButton'),
            onTap: _controller.isSending ? null : _send,
            child: Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: FieldifyColors.g800,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}
