import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:google_fonts/google_fonts.dart'; // Ensure this is in pubspec.yaml
import 'package:beehive/features/students/modules/progress_service.dart';

// ==========================================
// 1. PARENT SCREEN (The Container)
// ==========================================
class VideoLessonScreen extends StatefulWidget {
  final List<String> contentIDs;
  final String moduleId;
  final String roomId;
  final String lessonId;

  const VideoLessonScreen({
    Key? key,
    required this.contentIDs,
    required this.moduleId,
    required this.roomId,
    required this.lessonId,
  }) : super(key: key);

  @override
  _VideoLessonScreenState createState() => _VideoLessonScreenState();
}

class _VideoLessonScreenState extends State<VideoLessonScreen> {
  final PageController _pageController = PageController();
  int _currentPageIndex = 0;
  late final Future<List<Map<String, dynamic>>> _fetchPages;
  List<GlobalKey<_VideoPlayerWidgetState>> _videoKeys = [];

  @override
  void initState() {
    super.initState();
    _fetchPages = _loadPagesFromSupabase();
  }

  Future<bool> _onWillPop() async {
    if (_videoKeys.isEmpty || _videoKeys.length <= _currentPageIndex) {
      return true;
    }

    final playerState = _videoKeys[_currentPageIndex].currentState;
    if (playerState != null && playerState.controller.value.isFullScreen) {
      playerState.controller.toggleFullScreenMode();
      return false;
    }
    
    playerState?.controller.pause();
    return true;
  }

  Future<List<Map<String, dynamic>>> _loadPagesFromSupabase() async {
    final supabase = Supabase.instance.client;
    if (widget.contentIDs.isEmpty) return [];
    
    try {
      final List<Map<String, dynamic>> fetchedPages = await supabase
          .from('Video')
          .select()
          .inFilter('lessonContentId', widget.contentIDs);

      final Map<String, Map<String, dynamic>> pageMap = {
        for (var page in fetchedPages) page['lessonContentId']: page
      };
      final List<Map<String, dynamic>> sortedPages = [];
      for (String id in widget.contentIDs) {
        if (pageMap.containsKey(id)) sortedPages.add(pageMap[id]!);
      }
      return sortedPages;
    } catch (e) {
      print('Error fetching from Supabase: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    if (!isLandscape) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.transparent,
        ),
      );
    }

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.white, // 🌟 MATCH IMAGE BACKGROUND
        appBar: isLandscape ? null : AppBar(
          title: Text(
            "Video Lesson",
            style: GoogleFonts.inter(
              color: Colors.black,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          leading: BackButton(
            color: Colors.black,
            onPressed: () {
              _onWillPop().then((shouldPop) {
                if (shouldPop) {
                  Navigator.of(context).pop();
                }
              });
            },
          ),
        ),

        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: _fetchPages,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('This lesson has no videos.'));
            }

            final pages = snapshot.data!;
            if (_videoKeys.isEmpty) {
              _videoKeys = List.generate(pages.length, (_) => GlobalKey<_VideoPlayerWidgetState>());
            }

            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: Column(
                children: [
                  // VIDEO AREA
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: pages.length,
                      onPageChanged: (index) {
                        setState(() { _currentPageIndex = index; });
                      },
                      itemBuilder: (context, index) {
                        final pageData = pages[index];
                        return VideoPlayerWidget(
                          key: _videoKeys[index],
                          url: pageData['url'] ?? '',
                          title: pageData['title'] ?? 'No Title',
                        );
                      },
                    ),
                  ),
              
                  if (!isLandscape) _buildNavigationControls(pages.length),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // 🌟 UPDATED NAVIGATION CONTROLS (PILL SHAPE & COLORS)
  Widget _buildNavigationControls(int totalPages) {
    final bool isLastPage = _currentPageIndex == (totalPages - 1);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // --- PREV BUTTON (Grey) ---
          SizedBox(
            width: 120,
            height: 45,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF0F0F0), // Light Gray
                foregroundColor: Colors.black54, // Dark Text
                elevation: 0,
                shape: const StadiumBorder(), // Pill Shape
              ),
              onPressed: _currentPageIndex == 0 ? null : () {
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
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

          // --- PAGE COUNT ---
          Text(
            '${_currentPageIndex + 1} / $totalPages',
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black54),
          ),

          // --- NEXT/DONE BUTTON (Gold) ---
          SizedBox(
            width: 120,
            height: 45,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFA0701F), // Gold/Brown
                foregroundColor: Colors.white,
                elevation: 0,
                shape: const StadiumBorder(), // Pill Shape
              ),
              onPressed: () async {
                if (isLastPage) {
                  final shouldPop = await _onWillPop();
                  if (shouldPop) {
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
                  }
                } else {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
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

// ==========================================
// 2. VIDEO PLAYER WIDGET (The Child)
// ==========================================
class VideoPlayerWidget extends StatefulWidget {
  final String url;
  final String title;

  const VideoPlayerWidget({Key? key, required this.url, required this.title}) : super(key: key);

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late final YoutubePlayerController controller;

  @override
  void initState() {
    super.initState();
    final videoId = YoutubePlayer.convertUrlToId(widget.url) ?? '';
    
    controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
        enableCaption: true,
        disableDragSeek: false,
        loop: false,
        isLive: false,
        forceHD: false,
      ),
    );
  }

  @override
  void deactivate() {
    controller.pause();
    super.deactivate();
    }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (controller.value.isFullScreen) {
          controller.toggleFullScreenMode();
          return false;
        }
        return true;
      },
      child: YoutubePlayerBuilder(
        player: YoutubePlayer(
          controller: controller,
          showVideoProgressIndicator: true,
          progressIndicatorColor: const Color(0xFFA0701F), // Match app theme
          bottomActions: [
            CurrentPosition(),
            ProgressBar(isExpanded: true, colors: const ProgressBarColors(
              playedColor: Color(0xFFA0701F),
              handleColor: Color(0xFFA0701F),
            )),
            RemainingDuration(),
            FullScreenButton(),
          ],
        ),
        builder: (context, player) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 🌟 TYPOGRAPHY MATCHING IMAGE 2
                const SizedBox(height: 24),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    widget.title, // e.g. "Basic Input and Output"
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // The Player Container
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 0), // Full width or added padding
                  child: AspectRatio(
                    aspectRatio: 16/9,
                    child: player,
                  ),
                ),
                
                const SizedBox(height: 20),
                
                Text(
                  "Rotate phone for Fullscreen",
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}