import 'package:syntax_highlight/syntax_highlight.dart';

/// Centralized initializer and holder for the IDE/highlighter theme.
late final HighlighterTheme ideTheme;

/// Initialize the syntax highlighter and load a dark theme.
/// Call this from `main()` before running the app.
Future<void> initIdeTheme() async {
  await Highlighter.initialize(['python']);
  ideTheme = await HighlighterTheme.loadDarkTheme();
}
