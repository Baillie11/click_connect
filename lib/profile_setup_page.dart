import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  Future<void> _submitProfile() async {
    print('🔄 Submit button pressed');

    if (!_formKey.currentState!.validate()) {
      print('❌ Form validation failed');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      print('❌ No user found. Are you logged in?');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to save your profile')),
      );
      return;
    }

    print('✅ User UID: ${user.uid}');

    final profileData = {
      'uid': user.uid,
      'email': user.email,
      'nickname': _nicknameController.text.trim(),
      'sex': _selectedSex,
      'dateOfBirth': _dobController.text.trim(),
      'location': _locationController.text.trim(),
      'lookingFor': _selectedLookingFor,
      'interests': _selectedInterests,
      'profileComplete': true,
    };

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(profileData, SetOptions(merge: true));

      print('✅ Profile data saved to Firestore');

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const WelcomePage()),
        );
      }
    } catch (e) {
      print('🔥 Firestore save error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error saving profile')),
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
