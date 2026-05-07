import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_manager.dart';
import '../services/connection_service.dart';

class SearchResultsScreen extends StatefulWidget {
  const SearchResultsScreen({super.key});

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  final TextEditingController _queryController = TextEditingController();
  bool _isLoading = false;
  List<SearchResultItem> _results = [];
  bool _hasSearched = false;

  Future<void> _performSearch() async {
    final query = _queryController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    final connection = Provider.of<ConnectionService>(context, listen: false);
    final results = await connection.semanticSearchHistory(query);

    if (mounted) {
      setState(() {
        _results = results;
        _isLoading = false;
      });
    }
  }

  TextSpan _highlightKeywords(String text, String query, Color highlightColor, Color textColor) {
    if (query.isEmpty) return TextSpan(text: text, style: TextStyle(color: textColor));
    
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    
    int start = 0;
    List<TextSpan> spans = [];
    
    while (true) {
      final index = lowerText.indexOf(lowerQuery, start);
      if (index == -1) {
        spans.add(TextSpan(text: text.substring(start), style: TextStyle(color: textColor)));
        break;
      }
      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index), style: TextStyle(color: textColor)));
      }
      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: TextStyle(color: highlightColor, fontWeight: FontWeight.bold),
      ));
      start = index + query.length;
    }
    
    return TextSpan(children: spans);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeManager>(context);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.accentColor),
        title: TextField(
          controller: _queryController,
          style: TextStyle(color: theme.textColor),
          decoration: InputDecoration(
            hintText: 'Semantic Search...',
            hintStyle: TextStyle(color: theme.textColor.withValues(alpha: 0.5)),
            border: InputBorder.none,
          ),
          onSubmitted: (_) => _performSearch(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: theme.accentColor),
            onPressed: _performSearch,
          )
        ],
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator(color: theme.accentColor))
        : (!_hasSearched 
            ? Center(child: Text("Search your Helix history...", style: TextStyle(color: theme.textColor.withValues(alpha: 0.5))))
            : (_results.isEmpty 
                ? Center(child: Text("No relevant messages found.", style: TextStyle(color: theme.textColor.withValues(alpha: 0.5))))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final item = _results[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.chatBackgroundColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: theme.accentColor.withValues(alpha: 0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'AI Insight: ',
                                    style: TextStyle(color: theme.accentColor, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                  _highlightKeywords(item.summary, _queryController.text.trim(), theme.accentColor, theme.textColor.withValues(alpha: 0.8)),
                                ],
                                style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Divider(color: theme.textColor.withValues(alpha: 0.1), height: 1),
                            const SizedBox(height: 12),
                            Text(
                              '[${item.message.role.name.toUpperCase()}] ${item.message.text}',
                              style: TextStyle(color: theme.textColor, fontSize: 14),
                            ),
                          ],
                        ),
                      );
                    },
                  )
            )
        ),
    );
  }
}
