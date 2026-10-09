import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/app_localizations.dart';
import '../../../providers/chat_notifier.dart';
import '../../../theme/app_theme.dart';

class AiSuggestionsWidget extends ConsumerStatefulWidget {
  final String query;
  final Function(String) onSuggestionTap;

  const AiSuggestionsWidget({
    required this.query,
    required this.onSuggestionTap,
    super.key,
  });

  @override
  ConsumerState<AiSuggestionsWidget> createState() =>
      _AiSuggestionsWidgetState();
}

class _AiSuggestionsWidgetState extends ConsumerState<AiSuggestionsWidget> {
  static const _config = ChatConfig(
    provider: 'OPEN_AI',
    model: 'gpt-4o-mini',
    streaming: false,
  );

  String _lastQuery = '';
  List<String> _suggestions = [];

  @override
  void didUpdateWidget(AiSuggestionsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.query != oldWidget.query && widget.query.length >= 3) {
      _fetchSuggestions();
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.query.length >= 3) {
      _fetchSuggestions();
    }
  }

  Future<void> _fetchSuggestions() async {
    if (widget.query == _lastQuery) return;
    _lastQuery = widget.query;

    ref
        .read(chatNotifierProvider(_config).notifier)
        .sendMessage(
          [
            {
              'role': 'system',
              'content':
                  'You are a smart search assistant for VÉRA, a Gulf marketplace for fashion, real estate, clinics, salons, jobs, and gym services. Given a partial search query, return exactly 5 smart search suggestions as a JSON array of strings. Only return the JSON array, nothing else. Example: ["suggestion 1","suggestion 2","suggestion 3","suggestion 4","suggestion 5"]',
            },
            {'role': 'user', 'content': 'Query: "${widget.query}"'},
          ],
          parameters: {'max_completion_tokens': 200},
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final chatState = ref.watch(chatNotifierProvider(_config));

    ref.listen<ChatState>(chatNotifierProvider(_config), (prev, next) {
      if (next.error != null) {
        Fluttertoast.showToast(
          msg: l10n.t('aiSuggestionsUnavailable'),
          backgroundColor: Colors.red,
          toastLength: Toast.LENGTH_SHORT,
        );
      }
      if (!next.isLoading && next.response.isNotEmpty) {
        _parseSuggestions(next.response);
      }
    });

    if (chatState.isLoading) {
      return _buildLoadingState();
    }

    if (_suggestions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  gradient: AppTheme.aiGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  size: 14,
                  color: AppTheme.primaryPinkDark,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                l10n.t('aiSuggestions'),
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.charcoal,
                ),
              ),
            ],
          ),
        ),
        ..._suggestions.map(
          (s) => InkWell(
            onTap: () => widget.onSuggestionTap(s),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.search_rounded,
                    size: 16,
                    color: AppTheme.primaryPinkDark,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      s,
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        color: AppTheme.charcoal,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.north_west_rounded,
                    size: 14,
                    color: AppTheme.grayText,
                  ),
                ],
              ),
            ),
          ),
        ),
        Divider(height: 16, color: AppTheme.borderLight),
      ],
    );
  }

  void _parseSuggestions(String response) {
    try {
      final cleaned = response.trim();
      final start = cleaned.indexOf('[');
      final end = cleaned.lastIndexOf(']');
      if (start == -1 || end == -1) return;
      final jsonStr = cleaned.substring(start, end + 1);
      // Simple parse without dart:convert dependency issues
      final items = jsonStr
          .replaceAll('[', '')
          .replaceAll(']', '')
          .split(',')
          .map((e) => e.trim().replaceAll('"', '').replaceAll("'", ''))
          .where((e) => e.isNotEmpty)
          .take(5)
          .toList();
      if (mounted) {
        setState(() => _suggestions = items);
      }
    } catch (_) {}
  }

  Widget _buildLoadingState() {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              gradient: AppTheme.aiGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.primaryPinkDark,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            l10n.t('gettingAiSuggestions'),
            style: GoogleFonts.cairo(fontSize: 13, color: AppTheme.grayText),
          ),
        ],
      ),
    );
  }
}
