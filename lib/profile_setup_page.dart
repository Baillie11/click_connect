import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'welcome_page.dart';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  final _locationController = TextEditingController();
  final _dobController = TextEditingController();
  File? _imageFile;
  String? _imageUrl;

  String? _selectedSex;
  List<String> _selectedLookingFor = [];
  List<String> _selectedInterests = [];

  final List<String> _sexOptions = [
    'Male',
    'Female',
    'Couple',
    'Group',
    'Gender Diverse'
  ];

  final List<String> _lookingForOptions = [
    'Women',
    'Men',
    'Couples',
    'Groups',
    'MF Couples',
    'FF Couples'
  ];

  final List<String> _interestOptions = [
    'Casual sex',
    'Threesomes',
    'Friendship',
    'Long-term relationship',
    'Dating',
    'Fetish'
  ];

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
  }

  Future<void> _loadExistingProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final data = doc.data();
    if (data == null) return;

    setState(() {
      _nicknameController.text = data['nickname'] ?? '';
      _locationController.text = data['location'] ?? '';
      _dobController.text = data['dateOfBirth'] ?? '';
      _selectedSex = data['sex'];
      _selectedLookingFor = List<String>.from(data['lookingFor'] ?? []);
      _selectedInterests = List<String>.from(data['interests'] ?? []);
      _imageUrl = data['profileImageUrl'];
    });
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage(String uid) async {
    if (_imageFile == null) return _imageUrl;

    final ref = FirebaseStorage.instance.ref().child('user_images/$uid/profile.jpg');
    await ref.putFile(_imageFile!);
    return await ref.getDownloadURL();
  }

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final imageUrl = await _uploadImage(user.uid);

    final profileData = {
      'uid': user.uid,
      'email': user.email,
      'nickname': _nicknameController.text.trim(),
      'sex': _selectedSex,
      'dateOfBirth': _dobController.text.trim(),
      'location': _locationController.text.trim(),
      'lookingFor': _selectedLookingFor,
      'interests': _selectedInterests,
      'profileImageUrl': imageUrl,
      'profileComplete': true,
    };

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set(profileData, SetOptions(merge: true));

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const WelcomePage()),
      );
    }
  }

  Future<void> _pickDate() async {
    DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime(1995),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      _dobController.text = date.toLocal().toString().split(' ')[0];
    }
  }

  Widget _buildChips(List<String> options, List<String> selected) {
    return Wrap(
      spacing: 8.0,
      children: options.map((option) {
        final isSelected = selected.contains(option);
        return FilterChip(
          label: Text(option),
          selected: isSelected,
          onSelected: (_) => setState(() {
            isSelected ? selected.remove(option) : selected.add(option);
          }),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set Up Your Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 60,
                  backgroundImage: _imageFile != null
                      ? FileImage(_imageFile!)
                      : (_imageUrl != null ? NetworkImage(_imageUrl!) : null) as ImageProvider?,
                  child: _imageFile == null && _imageUrl == null
                      ? const Icon(Icons.add_a_photo, size: 40)
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nicknameController,
                decoration: const InputDecoration(labelText: 'Nickname'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter a nickname' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedSex,
                items: _sexOptions
                    .map((sex) => DropdownMenuItem(value: sex, child: Text(sex)))
                    .toList(),
                onChanged: (value) => setState(() => _selectedSex = value),
                decoration: const InputDecoration(labelText: 'Sex'),
                validator: (value) =>
                    value == null ? 'Please select your sex' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dobController,
                readOnly: true,
                decoration: const InputDecoration(labelText: 'Date of Birth'),
                onTap: _pickDate,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter your birth date' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Location'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter your location' : null,
              ),
              const SizedBox(height: 24),
              const Text('Looking for'),
              _buildChips(_lookingForOptions, _selectedLookingFor),
              const SizedBox(height: 24),
              const Text('Interests'),
              _buildChips(_interestOptions, _selectedInterests),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _submitProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pinkAccent,
                  padding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 60),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Save & Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
