import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// This is the function you will call from your GestureDetector.
/// It needs the 'context' from the page it's being called from.
void showForgotPasswordModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    isScrollControlled: true, // IMPORTANT: Allows modal to resize
    enableDrag: false,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (modalContext) {
      // 1. This Padding moves the modal up when the keyboard appears
      return Padding(
        padding: MediaQuery.of(modalContext).viewInsets,
        // 2. This Material widget fixes the 'debugCheckHasMaterial' error
        child: Material(
          color: Colors.transparent, // Use transparent to see modal's color
          child: SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              // 3. This makes the Column only as tall as its children
              child: Column(
                mainAxisSize: MainAxisSize.min, // THIS IS THE KEY FIX
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 8.0, bottom: 12.0),
                      child: Text(
                        'Reset Password',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  // Divider
                  const Divider(),

                  // 4. This ensures the form is scrollable
                  Flexible(
                    child: SingleChildScrollView(
                      // This now refers to the widget in SECTION 2
                      child: const _ForgotPasswordForm(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

// -------------------------------------------------------------------
//  SECTION 2: The form widget itself (now private)
// -------------------------------------------------------------------

class _ForgotPasswordForm extends StatefulWidget {
  // We make it private ( _ ) since it's only used inside this file.
  const _ForgotPasswordForm({Key? key}) : super(key: key);

  @override
  State<_ForgotPasswordForm> createState() => _ForgotPasswordFormState();
}

class _ForgotPasswordFormState extends State<_ForgotPasswordForm> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  /// Sends the password reset link to the user's email.
  Future<void> _sendResetLink() async {
    // 1. Validate the form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 2. Send the reset email
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );

      // 3. Show success and close the modal
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Password reset link sent to ${_emailController.text.trim()}',
            ),
            backgroundColor: Colors.green,
          ),
        );
        // This will close the bottom sheet
        Navigator.of(context).pop();
      }
    } on FirebaseAuthException catch (e) {
      // 4. Show an error message
      String errorMessage = 'An error occurred. Please try again.';
      if (e.code == 'user-not-found') {
        errorMessage = 'No user found with that email.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      // Handle any other unexpected errors
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('An unexpected error occurred.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      // 5. Stop the loading indicator
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // This widget is just the form itself.
    // The title and divider are in the modal builder.
    return Form(
      key: _formKey,
      child: Padding(
        // Add some padding so it's not edge-to-edge
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start, // Align to the top
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Enter the email associated with your account, and we\'ll send you a link to reset your password.',
              style: TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Convert to textformfield
            SizedBox(
              height: 50,
              child: TextFormField(
                controller: _emailController,
                style: const TextStyle(fontSize: 12),
                cursorColor: Color(0xFF443C36),
                decoration: InputDecoration(
                labelText: "Email",
                labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFF443C36), width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF443C36).withOpacity(0.3), width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                floatingLabelStyle: const TextStyle(color: Color(0xFF443C36)),
              ),
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                /*validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty ||
                      !value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },*/
              ),
            ),
            const SizedBox(height: 24),
            // Send Link Button
            SizedBox(
              width: double.infinity, // Full width like TextField
              height: 50, 
              child: ElevatedButton(
                onPressed:  _isLoading ? null : _sendResetLink,
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                  : const Text(
                      'Send Reset Link',
                      style: TextStyle(fontSize: 12, // Match TextField font size
                                    fontWeight: FontWeight.w600,),
                    ),
            
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFA27221),
                  foregroundColor: Colors.white,  // Text color
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  //elevation: 4, // Drop shadow
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50), // Match TextField radius
                  ),
                  textStyle: TextStyle(
                    fontSize: 12, // Match TextField font size
                    fontWeight: FontWeight.w600,
                  ),
                ),

              ),
            ),              
          ],
        ),
      ),
    );
  }
}

