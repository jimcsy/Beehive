import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// For inline code examples
import 'package:code_text_field/code_text_field.dart';
import 'package:highlight/languages/python.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart'; // Added a backup theme
import 'package:google_fonts/google_fonts.dart' as gfonts;
import 'dart:convert';
import 'package:beehive/features/students/modules/progress_service.dart';

class PagedReadingScreen extends StatefulWidget {
  final String lessonTitle;
  final List<String> contentIDs;
  final String moduleId;
  final String roomId;
  final String lessonId;

  const PagedReadingScreen({
    Key? key,
    required this.lessonTitle,
    required this.contentIDs,
    required this.moduleId,
    required this.roomId,
    required this.lessonId,
  }) : super(key: key);

  @override
  _PagedReadingScreenState createState() => _PagedReadingScreenState();
}

class _PagedReadingScreenState extends State<PagedReadingScreen> {
  final PageController _pageController = PageController();
  int _currentPageIndex = 0;

  late final Future<List<Map<String, dynamic>>> _fetchPages;

  @override
  void initState() {
    super.initState();
    _fetchPages = _loadPagesFromSupabase();
  }

  Future<List<Map<String, dynamic>>> _loadPagesFromSupabase() async {
    final supabase = Supabase.instance.client;

    if (widget.contentIDs.isEmpty) {
      return [];
    }

    try {
      final List<Map<String, dynamic>> fetchedPages = await supabase
          .from('Reading')
          .select()
          .inFilter('lessonContentId', widget.contentIDs);

      final Map<String, Map<String, dynamic>> pageMap = {
        for (var page in fetchedPages) page['lessonContentId'] as String: page
      };

      final List<Map<String, dynamic>> sortedPages = [];
      
      // 🌟 FIX 1: Safety check. If ID is missing in DB, skip it instead of crashing.
      for (String id in widget.contentIDs) {
        if (pageMap.containsKey(id)) {
          sortedPages.add(pageMap[id]!);
        } else {
          debugPrint("Warning: Content ID $id not found in Reading table.");
        }
      }
      return sortedPages;
    } catch (e) {
      print('Error fetching from Supabase: $e');
      // Return empty list to avoid crashing UI, or rethrow if you want to show error screen
      return []; 
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
        String appBarTitle = widget.lessonTitle;

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: _buildAppBar(appBarTitle),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: _buildAppBar(appBarTitle),
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: _buildAppBar(appBarTitle),
            body: const Center(child: Text('This lesson has no content.')),
          );
        }

        final pages = snapshot.data!;
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: _buildAppBar(appBarTitle),
          body: Column(
            children: [
              // 🌟 CONTENT AREA
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(), 
                  itemCount: pages.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPageIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final pageData = pages[index];
                    final dynamic raw = pageData['content_array'];
                    final String title =
                        pageData['title'] ?? widget.lessonTitle;

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
                    }

                    return Container(
                      margin: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA), 
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: DynamicPageContent(
                          title: title,
                          blocks: blocks,
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              // 🌟 NAVIGATION CONTROLS
              _buildNavigationControls(pages.length),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(String title) {
    return AppBar(
      title: Text(
        title,
        style: gfonts.GoogleFonts.inter(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      centerTitle: true,
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black),
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }

  Widget _buildNavigationControls(int totalPages) {
    final bool isLastPage = _currentPageIndex == (totalPages - 1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Prev Button
          SizedBox(
            width: 120,
            height: 45,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFA0701F), 
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _currentPageIndex == 0
                  ? null
                  : () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.arrow_back_ios_new, size: 14),
                  SizedBox(width: 8),
                  Text('Prev', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),

          // Next / Done Button
          SizedBox(
            width: 120,
            height: 45,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFA0701F), 
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                if (isLastPage) {
                  try {
                    await ProgressService().markLessonAsCompleted(
                      roomId: widget.roomId,
                      moduleId: widget.moduleId,
                      lessonId: widget.lessonId,
                    );
                  } catch (e) {
                    print('Failed to mark lesson complete: $e');
                  }
                  Navigator.of(context).pop();
                } else {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                }
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(isLastPage ? 'Done' : 'Next', 
                       style: const TextStyle(fontWeight: FontWeight.bold)),
                  if (!isLastPage) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_ios, size: 14),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------------
// DYNAMIC PAGE CONTENT WIDGET
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
      padding: const EdgeInsets.all(24.0),
      // 🌟 FIX 2: Added checks to ensure we don't read out of bounds or read nulls
      itemCount: blocks.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: Text(
              title,
              style: gfonts.GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.black,
                height: 1.2,
              ),
            ),
          );
        }

        // 🌟 FIX 3: Safe casting of the block
        final rawBlock = blocks[index - 1];
        if (rawBlock == null || rawBlock is! Map) {
          return const SizedBox.shrink(); // Skip bad data
        }
        
        final block = Map<String, dynamic>.from(rawBlock);
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
          padding: const EdgeInsets.only(top: 20.0, bottom: 12.0),
          child: Text(
            text,
            style: gfonts.GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        );
      case 'PARAGRAPH':
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Text(
            text,
            style: gfonts.GoogleFonts.inter(
              fontSize: 15,
              height: 1.6,
              color: const Color(0xFF333333),
            ),
          ),
        );
      case 'BULLET':
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 6.0, right: 12.0),
                child: Icon(Icons.circle, size: 5, color: Colors.black87),
              ),
              Expanded(
                child: Text(
                  text,
                  style: gfonts.GoogleFonts.inter(
                    fontSize: 15,
                    height: 1.5,
                    color: const Color(0xFF333333),
                  ),
                ),
              ),
            ],
          ),
        );
      case 'CODE_EXAMPLE':
        // 🌟 FIX 4: Moved the Code Widget to a separate Stateful widget.
        // This prevents the Controller from recreating during build (Layout errors)
        // and handles the themes safely.
        return CodeBlockWidget(code: text);
        
      default:
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(text),
        );
    }
  }
}

// -------------------------------------------------------------------
// NEW: DEDICATED STATEFUL WIDGET FOR CODE BLOCKS
// -------------------------------------------------------------------
class CodeBlockWidget extends StatefulWidget {
  final String code;
  const CodeBlockWidget({Key? key, required this.code}) : super(key: key);

  @override
  State<CodeBlockWidget> createState() => _CodeBlockWidgetState();
}

class _CodeBlockWidgetState extends State<CodeBlockWidget> {
  late CodeController _controller;

  @override
  void initState() {
    super.initState();
    // Initialize controller once
    _controller = CodeController(
      text: widget.code,
      language: python,
    );
  }

  @override
  void dispose() {
    _controller.dispose(); // Proper cleanup
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2D2D2D), // Dark gray
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(12.0),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: CodeTheme(
            // 🌟 FIX 5: Using a robust theme. If monokai fails, it won't crash layout 
            // because the Controller is now stable.
            data: CodeThemeData(styles: monokaiSublimeTheme),
            child: SizedBox(
              // Constraints help the RenderBox know its width limits inside ListView
              width: 600, // Give it enough width to scroll horizontally
              child: CodeField(
                controller: _controller,
                textStyle: gfonts.GoogleFonts.jetBrainsMono(fontSize: 13),
                readOnly: true,
                lineNumbers: false,
                decoration: null,
                // Prevent keyboard popping up on read-only code
                enabled: false, 
              ),
            ),
          ),
        ),
      ),
    );
  }
}