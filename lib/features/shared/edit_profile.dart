import 'dart:io'; // Required for File handling
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart'; // For picking images
import 'package:firebase_storage/firebase_storage.dart'; // For uploading files
import 'package:intl/intl.dart'; // For date formatting

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> userData;
  const EditProfilePage({super.key, required this.userData});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
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
  String? _currentPhotoURL; // The URL from Firebase
  File? _imageFile; // The new image file selected by the user
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    
    // Initialize controllers with data from your Firestore document
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
      // Parse the date string from Firestore
      _selectedDate = DateTime.tryParse(bdayString);
    }
    // Set the text field's value using our formatter
    _birthdayController = TextEditingController(text: _formatDate(_selectedDate));
  }

  @override
  void dispose() {
    // Clean up all controllers
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

  /// --- New Method: Shows the date picker dialog ---
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1920), // Earliest selectable date
      lastDate: DateTime.now(), // Latest selectable date (today)
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _birthdayController.text = _formatDate(picked);
      });
    }
  }

  /// --- Method to pick an image from the gallery (no changes) ---
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
        // We DO NOT update 'email' here. See point #4 above.
      };

      // 3. Conditionally add the new photoURL to the map
      if (newPhotoURL != null) {
        // This adds/updates the 'photoURL' field in Firestore
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
        Navigator.of(context).pop(true); // Return 'true' to refresh profile
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to update profile: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        elevation: 1,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                
                // --- Profile Picture Editor (no changes needed) ---
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey.shade300,
                        backgroundImage: _imageFile != null
                            ? FileImage(_imageFile!)
                            : (_currentPhotoURL != null &&
                                    _currentPhotoURL!.isNotEmpty
                                ? NetworkImage(_currentPhotoURL!)
                                : null) as ImageProvider?,
                        child: (_imageFile == null &&
                                (_currentPhotoURL == null ||
                                    _currentPhotoURL!.isEmpty))
                            ? Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.grey.shade700,
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: Theme.of(context).primaryColor,
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
                const SizedBox(height: 32),

                // --- First Name Field ---
                TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(
                    labelText: 'First Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
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
                  decoration: const InputDecoration(
                    labelText: 'Last Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
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
                  readOnly: true, // IMPORTANT!
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email_outlined),
                    suffixIcon: Tooltip(
                      message: 'Email cannot be changed from this page.\n'
                          'It is tied to your login credentials.',
                      child: Icon(Icons.help_outline, color: Colors.grey),
                    ),
                    filled: true,
                    fillColor: Color(0xFFf0f0f0), // A "disabled" look
                  ),
                ),
                const SizedBox(height: 16),

                // --- Birthday Field ---
                TextFormField(
                  controller: _birthdayController,
                  readOnly: true, // Make it read-only
                  decoration: const InputDecoration(
                    labelText: 'Birthday',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                  onTap: () {
                    // Show the date picker when tapped
                    _selectDate(context);
                  },
                ),
                const SizedBox(height: 24),

                // --- Save Button ---
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
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
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
