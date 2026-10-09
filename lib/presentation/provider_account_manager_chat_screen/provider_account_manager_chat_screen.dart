import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/vera_api_service.dart';
import '../../theme/app_theme.dart';

class ProviderAccountManagerChatScreen extends StatefulWidget {
  const ProviderAccountManagerChatScreen({super.key});
  @override
  State<ProviderAccountManagerChatScreen> createState() =>
      _ProviderAccountManagerChatScreenState();
}

class _ProviderAccountManagerChatScreenState
    extends State<ProviderAccountManagerChatScreen> {
  final controller = TextEditingController();
  final scroll = ScrollController();
  Map<String, dynamic>? data;
  bool loading = true;
  bool sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    controller.dispose();
    scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final result = await VeraApiService.instance.fetchProviderConversation();
    if (!mounted) return;
    setState(() {
      data = result;
      loading = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scroll.hasClients) scroll.jumpTo(scroll.position.maxScrollExtent);
    });
  }

  Future<void> _send() async {
    final text = controller.text.trim();
    if (text.isEmpty || sending) return;
    setState(() => sending = true);
    final result = await VeraApiService.instance.sendProviderMessage(text);
    if (result?['success'] == true) {
      controller.clear();
      await _load();
    }
    if (mounted) setState(() => sending = false);
  }

  Widget _messageBubble(Map<String, dynamic> message, BuildContext context) {
    final mine = message['sender_type'] == 'provider';
    return Align(
      alignment: mine
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 310),
        decoration: BoxDecoration(
          color: mine ? AppTheme.primaryPink : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          message['body']?.toString() ?? '',
          style: GoogleFonts.cairo(
            color: mine
                ? Colors.white
                : Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final messages = (data?['messages'] as List? ?? [])
        .cast<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    final manager =
        data?['conversation']?['account_manager_name']?.toString() ??
        'مدير الحساب';
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'مراسلة $manager',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppTheme.backgroundLight,
        elevation: 0,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: messages.isEmpty
                      ? Center(
                          child: Text(
                            'ابدأ محادثة مع مدير حسابك',
                            style: GoogleFonts.cairo(color: AppTheme.grayText),
                          ),
                        )
                      : ListView.builder(
                          controller: scroll,
                          padding: const EdgeInsets.all(16),
                          itemCount: messages.length,
                          itemBuilder: (_, index) =>
                              _messageBubble(messages[index], context),
                        ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controller,
                            minLines: 1,
                            maxLines: 4,
                            textDirection: TextDirection.rtl,
                            decoration: InputDecoration(
                              hintText: 'اكتب رسالتك...',
                              hintStyle: GoogleFonts.cairo(),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          onPressed: sending ? null : _send,
                          icon: sending
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.send),
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
