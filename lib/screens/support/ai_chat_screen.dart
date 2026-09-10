import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/providers.dart';

const _kHeroBg      = Color(0xFF4A1000);
const _kBodyBg      = Color(0xFFFFFFFF);
const _kCardBg      = Color(0xFFFFFFFF);
const _kBorderLight = Color(0xFFDDD0C4);
const _kGold        = Color(0xFFD4891A);
const _kTextDark    = Color(0xFF2D0F05);
const _kTextLight   = Color(0xFFA07050);
const _kCream       = Color(0xFFF5E6C8);

class _ChatMessage {
  final String role; // "user" or "assistant"
  final String text;
  const _ChatMessage(this.role, this.text);
}

/// In-app AI support chat, backed by Groq on the server side (the API key
/// never reaches the app). Stateless backend — this screen keeps the
/// conversation and resends it each turn.
class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<_ChatMessage> _messages = [
    const _ChatMessage('assistant',
        'Hi! I\'m the One Tent AI assistant. Ask me about booking, GST, cancellations, passport upload, or anything else about the app — I\'m happy to help.'),
  ];
  bool _sending = false;

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() {
      _messages.add(_ChatMessage('user', text));
      _sending = true;
      _inputCtrl.clear();
    });
    _scrollToBottom();

    final history = _messages
        .where((m) => m != _messages.last) // exclude the message just sent
        .map((m) => {'role': m.role, 'content': m.text})
        .toList();

    final support = context.read<SupportProvider>();
    final reply = await support.chat(message: text, history: history);

    if (!mounted) return;
    setState(() {
      _sending = false;
      _messages.add(_ChatMessage(
        'assistant',
        reply ?? (support.error ?? 'Something went wrong. Please try again.'),
      ));
    });
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBodyBg,
      appBar: AppBar(
        backgroundColor: _kCardBg,
        surfaceTintColor: _kCardBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: _kTextDark, size: 28),
          onPressed: () => context.pop(),
        ),
        title: const Text('AI Support',
            style: TextStyle(
                color: _kTextDark, fontWeight: FontWeight.w700, fontSize: 17)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _kBorderLight),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_sending ? 1 : 0),
              itemBuilder: (_, i) {
                if (i == _messages.length) return const _TypingBubble();
                return _MessageBubble(message: _messages[i]);
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: _kCardBg,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: _kBorderLight),
                    ),
                    child: TextField(
                      controller: _inputCtrl,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      style: const TextStyle(color: _kTextDark, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Ask a question…',
                        hintStyle: const TextStyle(
                            color: _kTextLight, fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sending ? null : _send,
                  child: Container(
                    width: 46, height: 46,
                    decoration: BoxDecoration(
                      color: _sending ? _kBorderLight : _kHeroBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.send_rounded,
                        color: _sending ? _kTextLight : _kGold, size: 20),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? _kHeroBg : _kCardBg,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: isUser ? null : Border.all(color: _kBorderLight),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: isUser ? _kCream : _kTextDark,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kBorderLight),
        ),
        child: const SizedBox(
          width: 18, height: 18,
          child: CircularProgressIndicator(color: _kGold, strokeWidth: 2),
        ),
      ),
    );
  }
}
