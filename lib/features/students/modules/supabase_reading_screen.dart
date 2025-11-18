import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// For inline code examples (small, read-only code boxes)
import 'package:code_text_field/code_text_field.dart';
import 'package:highlight/languages/python.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:google_fonts/google_fonts.dart' as gfonts;
import 'dart:convert'; // For your robust JSON parsing

class PagedReadingScreen extends StatefulWidget {
  final String lessonTitle;
  final List<String> contentIDs;
  


  const PagedReadingScreen({
    Key? key,
    required this.lessonTitle,
    required this.contentIDs,
  }) : super(key: key);

  @override
  _PagedReadingScreenState createState() => _PagedReadingScreenState();
}

class _PagedReadingScreenState extends State<PagedReadingScreen> {
  final PageController _pageController = PageController();
  int _currentPageIndex = 0;
  
  // This Future will hold our pages
  late final Future<List<Map<String, dynamic>>> _fetchPages;

  @override
  void initState() {
    super.initState();
    _fetchPages = _loadPagesFromSupabase();
  }

  // 🌟 THIS IS YOUR WORKING, SORTING FUNCTION 🌟
  // I've just removed the "flattening" part.
  Future<List<Map<String, dynamic>>> _loadPagesFromSupabase() async {
    final supabase = Supabase.instance.client;

    if (widget.contentIDs.isEmpty) {
      return [];
    }

    try {
      // 1. Fetch all rows that match our list of IDs
      final List<Map<String, dynamic>> fetchedPages = await supabase
          .from('Reading')
          .select()
          .inFilter('lessonContentId', widget.contentIDs);

      // 2. Re-sort them to match the Firestore order
      final Map<String, Map<String, dynamic>> pageMap = {
        for (var page in fetchedPages) page['lessonContentId']: page
      };
      final List<Map<String, dynamic>> sortedPages = [];
      for (String id in widget.contentIDs) {
        if (pageMap.containsKey(id)) {
          sortedPages.add(pageMap[id]!);
        }
      }
      
      // 3. ❗️ CHANGE ❗️
      // Instead of flattening, just return the 3 sorted pages
      return sortedPages;

    } catch (e) {
      print('Error fetching from Supabase: $e');
      throw Exception('Failed to load content: $e');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchPages,
      builder: (context, snapshot) {
        // Default title (fallback)
        String appBarTitle = widget.lessonTitle;

        if (snapshot.connectionState == ConnectionState.waiting) {
          // While loading, show a scaffold with progress
          return Scaffold(
            appBar: AppBar(title: Text(appBarTitle)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: Text(appBarTitle)),
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: Text(appBarTitle)),
            body: Center(child: Text('This lesson has no content.')),
          );
        } 

        // We have pages now; build the full scaffold using the loaded pages
        final pages = snapshot.data!;
        return Scaffold(
          appBar: AppBar(title: Text(appBarTitle)),
          body: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: pages.length,
                  onPageChanged: (index) {
                    setState(() { _currentPageIndex = index; });
                  },
                  itemBuilder: (context, index) {
                    final pageData = pages[index];

                    final dynamic raw = pageData['content_array'];
                    final String title = pageData['title'] ?? widget.lessonTitle;

                    List<dynamic> blocks = [];
                    if (raw == null) {
                      blocks = [];
                    } else if (raw is String) {
                      try {
                        blocks = jsonDecode(raw) as List<dynamic>;
                      } catch (_) {
                        blocks = [];
                      }
                    } else if (raw is List) {
                      blocks = List<dynamic>.from(raw);
                    } else {
                      blocks = [];
                    }

                    return DynamicPageContent(
                      title: title,
                      blocks: blocks,
                    );
                  },
                ),
              ),
              _buildNavigationControls(pages.length),
            ],
          ),
        );
      },
    );
  }

  // Navigation controls
  Widget _buildNavigationControls(int totalPages) {
    // 🌟 1. Check if we are on the last page
    final bool isLastPage = _currentPageIndex == (totalPages - 1);

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // --- "Prev" Button ---
          // (This logic is unchanged)
          ElevatedButton.icon(
            icon: Icon(Icons.arrow_back),
            label: Text('Prev'),
            onPressed: _currentPageIndex == 0 ? null : () {
              _pageController.previousPage(
                duration: Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            },
          ),
          
          // --- Page Count ---
          // (This logic is unchanged)
          Text(
            'Page ${_currentPageIndex + 1} of $totalPages',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          
          // 🌟 --- 2. "Next" / "Done" Button --- 🌟
          ElevatedButton.icon(
            icon: Icon(Icons.arrow_forward),
            
            // 3. Change the text based on the page
            label: Text(isLastPage ? 'Done' : 'Next'), 
            
            style: ElevatedButton.styleFrom(
              // 4. (Optional) Make the "Done" button a different color
              backgroundColor: isLastPage ? Colors.green : null, 
            ),
            
            // 5. Change the function based on the page
            onPressed: () {
              if (isLastPage) {
                // --- ON "DONE" ---
                // TODO: Add your "mark as complete" logic here
                
                // Navigate back to the previous screen   
                Navigator.of(context).pop(); 
                
              } else {
                // --- ON "NEXT" ---
                // Just go to the next page
                _pageController.nextPage(
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------------
// DYNAMIC PAGE CONTENT WIDGET
// This widget builds the content for ONE page
// (I've added the 'CODE' case back in for you)
// -------------------------------------------------------------------
class DynamicPageContent extends StatelessWidget {
  final String title;
  final List<dynamic> blocks;

  const DynamicPageContent({
    Key? key,
    required this.title,
    required this.blocks,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.all(16.0),
      // We add 1 for the main page title
      itemCount: blocks.length + 1,
      itemBuilder: (context, index) {
        
        // Item 0 is the main title
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(
              title,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
          );
        }
        
        // All other items are the content blocks
        final block = Map<String, dynamic>.from(blocks[index - 1] as Map);
        return _buildContentWidget(context, block);
      },
    );
  }

  Widget _buildContentWidget(BuildContext context, Map<String, dynamic> data) {
    final String type = data['type']?.toUpperCase() ?? 'PARAGRAPH';
    final String text = data['value'] ?? '';

    switch (type) {
      case 'HEADING':
        return Padding(
          padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
          child: Text(text, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
        );
      case 'PARAGRAPH':
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(text, style: TextStyle(fontSize: 16, height: 1.5)),
        );
      case 'BULLET':
        return Padding(
          padding: const EdgeInsets.only(left: 16.0, bottom: 4.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("• ", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, height: 1.5)),
              Expanded(child: Text(text, style: TextStyle(fontSize: 16, height: 1.5))),
            ],
          ),
        );
      case 'CODE_EXAMPLE':
        // Small, read-only code box using the same styling as the IDE
        final CodeController _controller = CodeController(
          text: text,
          language: python,
          // We keep it read-only by not exposing an editor controller externally
        );

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Container(
            decoration: BoxDecoration(
              color: monokaiSublimeTheme['root']?.backgroundColor ?? Colors.black87,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade800),
            ),
            constraints: const BoxConstraints(minHeight: 80, maxHeight: 220),
            padding: const EdgeInsets.all(8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: MediaQuery.of(context).size.width - 64,
                child: CodeTheme(
                  data: CodeThemeData(styles: monokaiSublimeTheme),
                  child: CodeField(
                    controller: _controller,
                    textStyle: gfonts.GoogleFonts.jetBrainsMono(fontSize: 12, height: 1.4),
                    lineNumbers: false,
                    readOnly: true,
                    expands: false,
                    maxLines: null,
                    wrap: true,
                    decoration: null,
                  ),
                ),
              ),
            ),
          ),
        );
      default:
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(text, style: TextStyle(fontSize: 16, height: 1.5)),
        );
    }
  }
}