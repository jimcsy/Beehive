import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

// ==========================================
// 1. PARENT SCREEN (The Container)
// ==========================================
class VideoLessonScreen extends StatefulWidget {
  final List<String> contentIDs;

  const VideoLessonScreen({Key? key, required this.contentIDs}) : super(key: key);

  @override
  _VideoLessonScreenState createState() => _VideoLessonScreenState();
}

class _VideoLessonScreenState extends State<VideoLessonScreen> {
  final PageController _pageController = PageController();
  int _currentPageIndex = 0;
  late final Future<List<Map<String, dynamic>>> _fetchPages;
  // 1. Add a list for GlobalKeys
  List<GlobalKey<_VideoPlayerWidgetState>> _videoKeys = [];

  @override
  void initState() {
    super.initState();
    _fetchPages = _loadPagesFromSupabase();
  }

  // 2. Add the navigation logic
  Future<bool> _onWillPop() async {
    if (_videoKeys.isEmpty || _videoKeys.length <= _currentPageIndex) {
      return true; // Allow pop if keys aren't initialized or index is out of bounds
    }

    final playerState = _videoKeys[_currentPageIndex].currentState;
    if (playerState != null && playerState.controller.value.isFullScreen) {
      playerState.controller.toggleFullScreenMode(); // Exit fullscreen
      return false; // Prevent screen from popping
    }
    
    // If not in fullscreen, pause the video before popping
    playerState?.controller.pause();
    return true; // Allow screen to pop
  }

  Future<List<Map<String, dynamic>>> _loadPagesFromSupabase() async {
    final supabase = Supabase.instance.client;
    if (widget.contentIDs.isEmpty) return [];
    
    // (Your existing Supabase logic remains exactly the same)
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

    // 🔥 FIX: When back to portrait, restore safe UI
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
      // 🔥 Auto-hide appbar in landscape
      appBar: isLandscape ? null : AppBar(
        title: const Text("Video Lesson"),
        // 3. Use the custom pop logic for the AppBar back button
        leading: BackButton(onPressed: () {
          _onWillPop().then((shouldPop) {
            if (shouldPop) {
              Navigator.of(context).pop();
            }
          });
        }),
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
          // 4. Initialize keys only once when data is available
          if (_videoKeys.isEmpty) {
            _videoKeys = List.generate(pages.length, (_) => GlobalKey<_VideoPlayerWidgetState>());
          }

          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.98, end: 1.0).animate(animation),
                  child: child,
                ),
              );
            },
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
                        // 5. Assign the key to the widget
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

  Widget _buildNavigationControls(int totalPages) {
    final bool isLastPage = _currentPageIndex == (totalPages - 1);
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton(
            onPressed: _currentPageIndex == 0 ? null : () {
              _pageController.previousPage(
                duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
            },
            child: const Text('Prev'),
          ),
          Text('${_currentPageIndex + 1} / $totalPages'),
          ElevatedButton(
            onPressed: () {
              if (isLastPage) {
                // 6. Use the custom pop logic for the Done button
                _onWillPop().then((shouldPop) {
                  if (shouldPop) {
                    Navigator.of(context).pop();
                  }
                });
              } else {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
              }
            },
            child: Text(isLastPage ? 'Done' : 'Next'),
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
        // ⚠️ This ensures the player knows it can go fullscreen
        disableDragSeek: false,
        loop: false,
        isLive: false,
        forceHD: false,
      ),
    );
  }

  @override
  void deactivate() {
    // The controller is paused, but forcing fullscreen exit here is problematic
    // as the parent widget now handles it before navigation.
    controller.pause();
    super.deactivate();
    }

  @override
  void dispose() {
    // The fullscreen check is removed to prevent animation conflicts.
    // The parent's pop logic now ensures fullscreen is exited first.
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 🌟 THE MAGIC WIDGET
    // YoutubePlayerBuilder creates a separate Overlay Route when fullscreen is active.
    // This overlay sits ON TOP of your AppBar and Buttons, hiding them completely.
    
    return WillPopScope(
      onWillPop: () async {
        if (controller.value.isFullScreen) {
          controller.toggleFullScreenMode();
          return false; // Do not exit screen yet
        }
        return true;
      },
      child: YoutubePlayerBuilder(
        player: YoutubePlayer(
          controller: controller,
          showVideoProgressIndicator: true,
          progressIndicatorColor: Colors.amber,
          // Customizing the bottom actions to ensure FullScreenButton is there
          bottomActions: [
            CurrentPosition(),
            ProgressBar(isExpanded: true),
            RemainingDuration(),
            FullScreenButton(),
          ],
        ),
        builder: (context, player) {
          // This builder ONLY builds what the screen looks like in PORTRAIT mode.
          // When in Landscape/Fullscreen, the package ignores this part and just shows the video.
          
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // The Title above the video (Visible in Portrait)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    widget.title,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
                
                // The Player (Visible in Portrait)
                player,
                
                const SizedBox(height: 50),
                const Center(child: Text("Rotate phone or click icon for Fullscreen")),
              ],
            ),
          );
        },
      ),
    );
  }
}