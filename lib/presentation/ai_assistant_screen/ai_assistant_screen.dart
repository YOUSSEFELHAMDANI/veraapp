import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../core/app_export.dart';
import '../../core/app_localizations.dart';
import '../../providers/chat_notifier.dart';
import '../../services/vera_api_service.dart';
import '../search_screen/widgets/voice_search_sheet.dart';
import '../search_screen/widgets/image_search_sheet.dart';

class AiAssistantScreen extends ConsumerStatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  ConsumerState<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends ConsumerState<AiAssistantScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _history = [];
  bool _isSearching = false;
  bool _isPicking = false;

  static const _config = ChatConfig(
    provider: 'OPEN_AI',
    model: 'gpt-4o-mini',
    streaming: true,
  );

  static const List<String> _quickPrompts = [
    'أريد عباية بأقل من 100 درهم',
    'أفضل عيادات تجميل في أبوظبي',
    'شقق للإيجار في دبي مارينا',
    'وظائف تسويق في دبي',
    'باقات تدريب شخصي قريبة مني',
  ];

  late final VeraApiService _apiService;

  @override
  void initState() {
    super.initState();
    _apiService = VeraApiService.instance;
  }

  Future<void> _openVoiceSearch() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: VoiceSearchSheet(onQuery: _onVoiceQuery),
      ),
    );
  }

  void _onVoiceQuery(String query) {
    _controller.text = query;
    _sendMessage(AppLocalizations.of(context));
  }

  Future<void> _openImageSearch() async {
    if (_isPicking) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => ImageSourceSheet(
        onChoose: (source) async {
          Navigator.pop(sheetContext);
          setState(() => _isPicking = true);
          await pickAndAnalyzeImage(context, ref, source);
          if (mounted) setState(() => _isPicking = false);
        },
      ),
    );
  }

  /// Detect intent from user message and fetch relevant VERA data
  Future<String> _fetchVeraContext(
      String userMessage, AppLocalizations l10n) async {
    final msg = userMessage.toLowerCase();

    // Keywords for each category
    final isFashion = _containsAny(msg, [
      'عباية',
      'فستان',
      'ملابس',
      'موضة',
      'fashion',
      'abaya',
      'dress',
      'clothes',
      'shirt',
      'shoes',
      'bag',
      'حذاء',
      'حقيبة',
      'قميص',
      'بنطلون',
      'تنورة',
      'skirt',
      'jacket',
      'جاكيت',
      'بلوزة',
      'blouse',
      'outfit',
      'style',
    ]);

    final isProperty = _containsAny(msg, [
      'شقة',
      'فيلا',
      'عقار',
      'apartment',
      'villa',
      'property',
      'real estate',
      'إيجار',
      'rent',
      'buy',
      'شراء',
      'سكن',
      'house',
      'studio',
      'استوديو',
      'bedroom',
      'غرفة',
      'دبي مارينا',
      'marina',
      'downtown',
      'جميرا',
      'jumeirah',
    ]);

    final isJob = _containsAny(msg, [
      'وظيفة',
      'عمل',
      'job',
      'career',
      'vacancy',
      'hiring',
      'توظيف',
      'مهنة',
      'راتب',
      'salary',
      'تسويق',
      'marketing',
      'engineer',
      'مهندس',
      'محاسب',
      'accountant',
      'مبيعات',
      'sales',
      'hr',
      'موارد بشرية',
    ]);

    final isService = _containsAny(msg, [
      'عيادة',
      'صالون',
      'جيم',
      'clinic',
      'salon',
      'gym',
      'spa',
      'سبا',
      'تجميل',
      'beauty',
      'hair',
      'شعر',
      'نيل',
      'nail',
      'massage',
      'مساج',
      'رياضة',
      'sports',
      'fitness',
      'لياقة',
      'تدريب',
      'trainer',
    ]);

    final results = <String>[];

    try {
      if (isFashion) {
        // Try to extract price filter from message
        final maxPrice = _extractMaxPrice(msg);
        final products = await _apiService.fetchProducts();
        var filtered = products;
        if (maxPrice != null) {
          filtered = products.where((p) => p.price <= maxPrice).toList();
        }
        if (filtered.isNotEmpty) {
          final top = filtered.take(8).toList();
          results.add(l10n.t('aiProductsAvailableHeader'));
          for (final p in top) {
            results.add(
              '- ${p.name}${p.brand.isNotEmpty ? " (${p.brand})" : ""} — ${p.price.toStringAsFixed(0)} AED'
              '${p.category.isNotEmpty ? " | ${p.category}" : ""}',
            );
          }
        }
      }

      if (isProperty) {
        final properties = await _apiService.fetchProperties();
        if (properties.isNotEmpty) {
          final top = properties.take(6).toList();
          results.add(l10n.t('aiPropertiesAvailableHeader'));
          for (final p in top) {
            results.add(
              '- ${p.name} — ${p.price}'
              '${p.location.isNotEmpty ? " | ${p.location}" : ""}',
            );
          }
        }
      }

      if (isJob) {
        final jobs = await _apiService.fetchJobs();
        if (jobs.isNotEmpty) {
          final top = jobs.take(6).toList();
          results.add(l10n.t('aiJobsAvailableHeader'));
          for (final j in top) {
            results.add(
              '- ${j.title} في ${j.company} — ${j.salary}'
              '${j.location.isNotEmpty ? " | ${j.location}" : ""}',
            );
          }
        }
      }

      if (isService) {
        final listings = await _apiService.search(query: userMessage);
        if (listings.isNotEmpty) {
          final top = listings.take(6).toList();
          results.add(l10n.t('aiServicesAvailableHeader'));
          for (final l in top) {
            results.add(
              '- ${l.name}${l.providerName.isNotEmpty ? " (${l.providerName})" : ""} — ${l.price}'
              '${l.location.isNotEmpty ? " | ${l.location}" : ""}',
            );
          }
        }
      }

      // Generic search fallback if no category matched or no results yet
      if (results.isEmpty) {
        final listings = await _apiService.search(query: userMessage);
        if (listings.isNotEmpty) {
          final top = listings.take(8).toList();
          results.add(l10n.t('aiResultsAvailableHeader'));
          for (final l in top) {
            results.add(
              '- ${l.name}${l.providerName.isNotEmpty ? " (${l.providerName})" : ""} — ${l.price}'
              '${l.location.isNotEmpty ? " | ${l.location}" : ""}',
            );
          }
        }
      }
    } catch (_) {}

    return results.join('\n');
  }

  bool _containsAny(String text, List<String> keywords) {
    return keywords.any((k) => text.contains(k));
  }

  double? _extractMaxPrice(String text) {
    // Match patterns like "أقل من 100" or "under 100" or "less than 200"
    final patterns = [
      RegExp(r'أقل من\s*(\d+)'),
      RegExp(r'under\s*(\d+)'),
      RegExp(r'less than\s*(\d+)'),
      RegExp(r'below\s*(\d+)'),
      RegExp(r'(\d+)\s*درهم'),
      RegExp(r'(\d+)\s*aed', caseSensitive: false),
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return double.tryParse(match.group(1) ?? '');
      }
    }
    return null;
  }

  void _sendMessage(AppLocalizations l10n) async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final userMsg = {'role': 'user', 'content': text};
    setState(() {
      _history.add(userMsg);
      _isSearching = true;
    });
    _controller.clear();
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);

    final veraContext = await _fetchVeraContext(text, l10n);

    setState(() => _isSearching = false);

    final systemContent = veraContext.isNotEmpty
        ? l10n.t('aiSystemPromptWithData', args: {'data': veraContext})
        : l10n.t('aiSystemPromptNoData');

    final messages = <Map<String, dynamic>>[
      {'role': 'system', 'content': systemContent},
      ..._history.map((m) => Map<String, dynamic>.from(m)),
    ];

    ref
        .read(chatNotifierProvider(_config).notifier)
        .sendMessage(messages, parameters: {'max_completion_tokens': 600});

    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final chatState = ref.watch(chatNotifierProvider(_config));

    ref.listen<ChatState>(chatNotifierProvider(chatImageSearchConfig), (
      prev,
      next,
    ) {
      if (next.error != null) {
        Fluttertoast.showToast(
          msg: l10n.t('imageAnalysisFailed'),
          backgroundColor: Colors.red,
          toastLength: Toast.LENGTH_SHORT,
        );
      }
      if (!next.isLoading &&
          next.response.isNotEmpty &&
          prev?.isLoading == true) {
        _controller.text = next.response.trim();
        _sendMessage(l10n);
      }
    });

    final quickPrompts = [
      l10n.t('aiQuickPrompt1'),
      l10n.t('aiQuickPrompt2'),
      l10n.t('aiQuickPrompt3'),
      l10n.t('aiQuickPrompt4'),
      l10n.t('aiQuickPrompt5'),
    ];

    ref.listen<ChatState>(chatNotifierProvider(_config), (prev, next) {
      if (next.error != null) {
        Fluttertoast.showToast(
          msg: l10n.t('aiUnavailable'),
          backgroundColor: Colors.red,
          toastLength: Toast.LENGTH_SHORT,
        );
      }
      if (prev?.isLoading == true &&
          !next.isLoading &&
          next.response.isNotEmpty) {
        setState(() {
          _history.add({'role': 'assistant', 'content': next.response});
        });
        Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
      }
      if (next.isLoading) {
        Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
      }
    });

    final isProcessing = _isSearching || chatState.isLoading;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: const BoxDecoration(
                gradient: AppTheme.splashGradient,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(200),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                        color: AppTheme.charcoal,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: AppTheme.aiGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      size: 20,
                      color: AppTheme.primaryPinkDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'VÉRA AI',
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.charcoal,
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: _isSearching
                                    ? AppTheme.primaryPink
                                    : AppTheme.success,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _isSearching
                                  ? l10n.t('aiSearchingInApp')
                                  : l10n.t('aiOnline'),
                              style: GoogleFonts.cairo(
                                fontSize: 11,
                                color: AppTheme.grayText,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() => _history.clear());
                      ref
                          .read(chatNotifierProvider(_config).notifier)
                          .clearResponse();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(200),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.refresh_rounded,
                        size: 18,
                        color: AppTheme.charcoal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _history.isEmpty && !isProcessing
                  ? _buildEmptyState(l10n, quickPrompts)
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                      itemCount: _history.length + (isProcessing ? 1 : 0),
                      itemBuilder: (context, i) {
                        if (i < _history.length) {
                          final msg = _history[i];
                          final isUser = msg['role'] == 'user';
                          return _MessageBubble(
                            text: msg['content'] ?? '',
                            isUser: isUser,
                          );
                        }
                        return _MessageBubble(
                          text: _isSearching
                              ? l10n.t('aiSearchingVera')
                              : (chatState.response.isNotEmpty
                                    ? chatState.response
                                    : '...'),
                          isUser: false,
                          isStreaming: true,
                        );
                      },
                    ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                MediaQuery.of(context).padding.bottom + 80,
              ),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                border: Border(
                  top: BorderSide(color: AppTheme.borderLight),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.ivoryLight,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: TextField(
                        controller: _controller,
                        maxLines: 3,
                        minLines: 1,
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          color: AppTheme.charcoal,
                        ),
                        decoration: InputDecoration(
                          hintText: l10n.t('aiSearchHint'),
                          hintStyle: GoogleFonts.cairo(
                            fontSize: 14,
                            color: AppTheme.grayText,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(l10n),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _openVoiceSearch,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryPinkLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.mic_rounded,
                        size: 18,
                        color: AppTheme.primaryPinkDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: _openImageSearch,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryPinkLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _isPicking
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.primaryPinkDark,
                              ),
                            )
                          : const Icon(
                              Icons.camera_alt_outlined,
                              size: 18,
                              color: AppTheme.primaryPinkDark,
                            ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: isProcessing ? null : () => _sendMessage(l10n),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: isProcessing
                            ? null
                            : AppTheme.primaryGradient,
                        color: isProcessing ? AppTheme.borderLight : null,
                        shape: BoxShape.circle,
                        boxShadow: isProcessing
                            ? []
                            : [
                                BoxShadow(
                                  color: AppTheme.primaryPink.withAlpha(80),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                      ),
                      child: isProcessing
                          ? Center(
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.grayText,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n, List<String> quickPrompts) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppTheme.aiGradient,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(200),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  size: 28,
                  color: AppTheme.primaryPinkDark,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                l10n.t('aiWelcomeMessage'),
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.charcoal,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.t('aiWelcomeDescription'),
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  color: AppTheme.charcoal.withAlpha(160),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          l10n.t('aiTryAsking'),
          style: GoogleFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.grayText,
          ),
        ),
        const SizedBox(height: 12),
        ...quickPrompts.map(
          (p) => GestureDetector(
            onTap: () {
              _controller.text = p;
              _sendMessage(l10n);
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 16,
                    color: AppTheme.primaryPinkDark,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      p,
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        color: AppTheme.charcoal,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 12,
                    color: AppTheme.grayText,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final bool isStreaming;

  const _MessageBubble({
    required this.text,
    required this.isUser,
    this.isStreaming = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                gradient: AppTheme.aiGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                size: 14,
                color: AppTheme.primaryPinkDark,
              ),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: isUser ? AppTheme.primaryGradient : null,
                color: isUser ? null : AppTheme.surfaceLight,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                border: isUser ? null : Border.all(color: AppTheme.borderLight),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(8),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      text,
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        color: isUser ? Colors.white : AppTheme.charcoal,
                        height: 1.5,
                      ),
                    ),
                  ),
                  if (isStreaming && text == '...') ...[
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: AppTheme.grayText,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }
}
