import 'package:flutter/material.dart';

/// Custom Loader Widget
class CustomLoader extends StatelessWidget {
  const CustomLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors:[
            Color(0xFFF4E3C2),
            Color(0xFFE8A319),
            Color(0xFFA0701F),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Opacity(
              opacity: 0.6,
              child: Image.asset(
                'assets/icons/gifs/loader.gif',
                width: 80,
                height: 80,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

/// Reusable Loader Overlay Widget
/// 
/// Wraps any child widget and displays a full-screen overlay with CustomLoader
/// when isLoading is true. When isLoading is false, displays the child normally.
/// 
/// Usage:
/// ```dart
/// LoaderOverlay(
///   isLoading: _isLoading,
///   child: YourContentWidget(),
/// )
/// ```
class LoaderOverlay extends StatelessWidget {
  /// Whether to show the loading overlay
  final bool isLoading;
  
  /// The child widget to display when not loading
  final Widget child;
  
  /// Optional loading message to display below the loader
  final String? loadingMessage;
  
  /// Whether the loading overlay should be dismissible (default: false)
  final bool dismissible;

  const LoaderOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.loadingMessage,
    this.dismissible = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main content
        child,
        
        // Loading overlay
        if (isLoading)
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: Container(
                color: Colors.black.withOpacity(0.3),
                child: Center(
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFFF4E3C2),
                          Color(0xFFE8A319),
                          Color(0xFFA0701F),
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Opacity(
                          opacity: 0.8,
                          child: Image.asset(
                            'assets/icons/gifs/loader.gif',
                            width: 100,
                            height: 100,
                          ),
                        ),
                        if (loadingMessage != null) ...[
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              loadingMessage!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
