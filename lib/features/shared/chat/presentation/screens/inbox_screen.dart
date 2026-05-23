import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../controllers/inbox_controller.dart';
import '../../data/models/conversation_model.dart';
import '../widgets/conversation_tile.dart';
import 'chat_screen.dart';

class InboxScreen extends StatefulWidget {
  final InboxController? controller;

  const InboxScreen({super.key, this.controller});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  late final InboxController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? InboxController();
    _ownsController = widget.controller == null;
    _controller.addListener(_onChanged);
    _controller.load();
    _controller.listenForUpdates();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  void _openChat(Conversation c) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              requestId: c.requestId,
              jobStatus: c.jobStatus,
              counterpartyName: c.counterpartyName,
              jobTitle: c.jobTitle,
            ),
          ),
        )
        .then((_) => _controller.load());
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
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: FieldifyColors.g800,
      padding: const EdgeInsets.fromLTRB(12, 6, 24, 16),
      child: Row(
        children: [
          IconButton(
            key: const Key('inboxBackButton'),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          Text(
            'Messages',
            style: GoogleFonts.dmSans(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: Colors.white,
              letterSpacing: -0.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_controller.isLoading && _controller.conversations.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_controller.error != null && _controller.conversations.isEmpty) {
      return _buildEmpty(
        icon: Icons.error_outline,
        title: 'Could not load messages',
        subtitle: _controller.error!,
      );
    }
    final items = _controller.conversations;
    if (items.isEmpty) {
      return _buildEmpty(
        icon: Icons.chat_bubble_outline,
        title: 'No conversations yet',
        subtitle:
            'Chats appear here once you have a job with an assigned professional.',
      );
    }
    return RefreshIndicator(
      onRefresh: _controller.load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, _) => const Divider(
          height: 1,
          thickness: 1,
          color: FieldifyColors.border,
        ),
        itemBuilder: (_, i) => ConversationTile(
          key: Key('conversationTile_${items[i].requestId}'),
          conversation: items[i],
          onTap: () => _openChat(items[i]),
        ),
      ),
    );
  }

  Widget _buildEmpty({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: FieldifyColors.ink4),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: FieldifyColors.ink2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: FieldifyColors.ink4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
