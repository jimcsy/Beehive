import 'dart:io'; 
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'package:beehive/utils/hexagonal.dart'; // Ensure this path is correct

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> userData;
  const EditProfilePage({super.key, required this.userData});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage>
    with SingleTickerProviderStateMixin { 
  
  // --- Animation Variables ---
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  // --- Controllers for our new fields ---
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _birthdayController;
  DateTime? _selectedDate;

  // --- State variables for image handling ---
  String? _currentPhotoURL;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();

    // --- ANIMATION INITIALIZATION ---
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    _animationController.forward();
    // --------------------------------

    // Initialize controllers with data from your Firestore document.
    _firstNameController =
        TextEditingController(text: widget.userData['firstName'] ?? '');
    _lastNameController =
        TextEditingController(text: widget.userData['lastName'] ?? '');
    _emailController =
        TextEditingController(text: widget.userData['email'] ?? '');

    // Initialize photo URL
    _currentPhotoURL = widget.userData['photoURL'];

    // --- Special handling for the Birthday field ---
    final String? bdayString = widget.userData['birthday'];
    if (bdayString != null && bdayString.isNotEmpty) {
      _selectedDate = DateTime.tryParse(bdayString);
    }
    _birthdayController = TextEditingController(text: _formatDate(_selectedDate));
  }

  @override
  void dispose() {
    _animationController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _birthdayController.dispose();
    super.dispose();
  }

  /// Helper function to format DateTime into 'YYYY-MM-DD'
  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('yyyy-MM-dd').format(date);
  }

  /// --- Helper Method for Consistent Input Styling ---
  InputDecoration _getInputDecoration({
    required String labelText,
    IconData? prefixIcon,
    Widget? suffixIcon,
    Color? fillColor,
  }) {
    // Define the common border style
    final borderStyle = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(
        color: Colors.grey[400]!,
        width: 1,
      ),
    );
    
    // Define the focused border style
    final focusedBorderStyle = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(
        color: Colors.black,
        width: 1,
      ),
    );

    return InputDecoration(
      labelText: labelText,
      labelStyle: TextStyle(
        color: Colors.grey[600],
        fontSize: 16,
      ),
      floatingLabelStyle: const TextStyle(
        color: Colors.black,
        fontSize: 16,
      ),
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Colors.black54) : null,
      suffixIcon: suffixIcon,
      filled: fillColor != null,
      fillColor: fillColor,
      
      enabledBorder: borderStyle,
      focusedBorder: focusedBorderStyle,
      border: borderStyle,
      
      // Custom vertical padding to make fields taller
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
      isDense: true,
    );
  }

  /// --- Method: Shows the date picker dialog ---
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _birthdayController.text = _formatDate(picked);
      });
    }
  }

  /// --- Method to pick an image from the gallery ---
  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile =
          await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to pick image: $e";
      });
    }
  }

  /// --- Updated Method: Saves all new fields to Firestore ---
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _animationController.reverse(); // Reverse animation when saving starts

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No user is currently logged in.');
      }

      String? newPhotoURL;

      // 1. Upload new image if one was selected
      if (_imageFile != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_pictures')
            .child('${user.uid}.jpg');
        UploadTask uploadTask = storageRef.putFile(_imageFile!);
        TaskSnapshot snapshot = await uploadTask;
        newPhotoURL = await snapshot.ref.getDownloadURL();
      }

      // 2. Create the data map using your exact field names
      final Map<String, dynamic> dataToUpdate = {
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'birthday': _birthdayController.text,
      };

      // 3. Conditionally add the new photoURL to the map
      if (newPhotoURL != null) {
        dataToUpdate['photoURL'] = newPhotoURL;
      }

      // 4. Update the document in Firestore
      final userRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);
      await userRef.update(dataToUpdate);

      // 5. Success
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to update profile: $e';
      });
      _animationController.forward(); // Rerun animation if save fails
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String initialFirstName = widget.userData['firstName'] ?? '';
    final String? initialPhotoURL = widget.userData['photoURL'];

    final String fallbackChar = initialFirstName.isNotEmpty
        ? initialFirstName[0].toUpperCase()
        : 'K';

    // --- THEME COLORS ---
    const Color customButtonColor = Color(0xFFA0701F); // Darker Gold/Brown
    const Color customEditIconColor = Color(0xFFE8A319); // Lighter Gold

    return Scaffold(
      body: Stack(
        children: [
          // 1. ANIMATED SCROLLABLE FORM CONTENT
          SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: 280,
                    left: 16.0,
                    right: 16.0,
                    bottom: 16.0,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 16),
                        
                        // --- First Name Field ---
                        TextFormField(
                          controller: _firstNameController,
                          decoration: _getInputDecoration(
                            labelText: 'First Name',
                            prefixIcon: Icons.person_outline,
                          ),
                          style: const TextStyle(fontSize: 16, color: Colors.black), 
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your first name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // --- Last Name Field ---
                        TextFormField(
                          controller: _lastNameController,
                          decoration: _getInputDecoration(
                            labelText: 'Last Name',
                            prefixIcon: Icons.person_outline,
                          ),
                          style: const TextStyle(fontSize: 16, color: Colors.black),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your last name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // --- Email Field (Read-only) ---
                        TextFormField(
                          controller: _emailController,
                          readOnly: true,
                          decoration: _getInputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icons.email_outlined,
                            suffixIcon: const Tooltip(
                              message: 'Email cannot be changed from this page.\n'
                                  'It is tied to your login credentials.',
                              child: Icon(Icons.help_outline, color: Colors.grey),
                            ),
                            fillColor: const Color(0xFFf0f0f0),
                          ),
                          style: const TextStyle(fontSize: 16, color: Colors.black),
                        ),
                        const SizedBox(height: 16),

                        // --- Birthday Field ---
                        TextFormField(
                          controller: _birthdayController,
                          readOnly: true,
                          decoration: _getInputDecoration(
                            labelText: 'Birthday',
                            prefixIcon: Icons.calendar_today_outlined,
                          ),
                          style: const TextStyle(fontSize: 16, color: Colors.black),
                          onTap: () {
                            _selectDate(context);
                          },
                        ),
                        const SizedBox(height: 24),

                        // --- Save Button (DESIGN APPLIED HERE) ---
                        ElevatedButton(
                          onPressed: _isLoading ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: customButtonColor, // Custom Brown Color
                            foregroundColor: Colors.white, // White Text
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8), 
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Save Changes'),
                        ),

                        // --- Error Message Display ---
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage!,
                            style:
                                TextStyle(color: Theme.of(context).colorScheme.error),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // 2. The header background
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/icons/rectangle.png',
              height: 265,
              fit: BoxFit.cover,
            ),
          ),

          // 3. The BeeHive logo and text
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/icons/logo_white.png',
                      height: 28,
                    ),
                    const SizedBox(width: 8),
                    Image.asset(
                      'assets/icons/BeeHive.png',
                      height: 15,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 4. The Profile Picture Editor
          Positioned(
            top: 150,
            left: MediaQuery.of(context).size.width / 2 - 65,
            child: Stack(
              children: [
                ClipPath(
                  clipper: HexClipper(),
                  child: Container(
                    width: 140,
                    height: 130,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      image: _imageFile != null
                          ? DecorationImage(
                              image: FileImage(_imageFile!),
                              fit: BoxFit.cover,
                            )
                          : (initialPhotoURL != null && initialPhotoURL.isNotEmpty)
                              ? DecorationImage(
                                  image: NetworkImage(initialPhotoURL),
                                  fit: BoxFit.cover,
                                )
                              : null,
                    ),
                    child: (_imageFile == null &&
                            (initialPhotoURL == null || initialPhotoURL.isEmpty))
                        ? Center(
                            child: Text(
                              fallbackChar,
                              style: const TextStyle(
                                  fontSize: 60, color: Colors.black54),
                            ),
                          )
                        : null,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: customEditIconColor, // Custom Yellow Color
                    child: IconButton(
                      icon: const Icon(Icons.edit,
                          color: Colors.white, size: 20),
                      onPressed: _pickImage,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 5. The Back Button
          Positioned(
            top: 0,
            left: 0,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}