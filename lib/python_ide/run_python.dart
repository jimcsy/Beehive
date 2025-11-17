import 'package:serious_python/serious_python.dart';

Future<String> runPythonCode(String codeToRun) async {
  try {
    // Execute raw Python code directly
    final result = await SeriousPython.run(codeToRun);
    return result.toString();
  } catch (e) {
    return "Error running Python code: $e";
  }
}
