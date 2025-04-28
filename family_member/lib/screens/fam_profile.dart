import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FamProfile extends StatefulWidget {
  final String familymemberID;

  const FamProfile({super.key, required this.familymemberID});

  @override
  State<FamProfile> createState() => _FamProfileState();
}

class _FamProfileState extends State<FamProfile> {
  final SupabaseClient supabase = Supabase.instance.client;
  Map<String, dynamic>? familyData;
  bool isLoading = true;
  bool isEditing = false;

  // Controllers for form fields
  late TextEditingController nameController;
  late TextEditingController addressController;
  late TextEditingController contactController;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    // Initialize controllers
    nameController = TextEditingController();
    addressController = TextEditingController();
    contactController = TextEditingController();

    fetchFamilyProfile();
  }

  @override
  void dispose() {
    nameController.dispose();
    addressController.dispose();
    contactController.dispose();
    super.dispose();
  }

  Future<void> fetchFamilyProfile() async {
    final response = await supabase
        .from('tbl_familymember')
        .select()
        .eq('familymember_id', widget.familymemberID)
        .maybeSingle();

    if (mounted) {
      setState(() {
        familyData = response;
        isLoading = false;

        // Set initial values in controllers
        if (familyData != null) {
          nameController.text = familyData!['familymember_name'] ?? '';
          addressController.text = familyData!['familymember_address'] ?? '';
          contactController.text =
              familyData!['familymember_contact']?.toString() ?? '';
        }
      });
    }
  }

  Future<void> updateFamilyProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });

      try {
        await supabase.from('tbl_familymember').update({
          'familymember_name': nameController.text,
          'familymember_address': addressController.text,
          'familymember_contact': contactController.text,
        }).eq('familymember_id', widget.familymemberID);

        await fetchFamilyProfile();

        setState(() {
          isEditing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully!')));
      } catch (e) {
        setState(() {
          isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating profile: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(230, 255, 252, 197),
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Family Profile' : 'Family Member Profile',
          style: const TextStyle(
              fontSize: 23, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color.fromARGB(255, 0, 36, 94),
        foregroundColor: Colors.white,
        actions: [
          if (!isEditing && familyData != null)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: () {
                setState(() {
                  isEditing = true;
                });
              },
            ),
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () {
                setState(() {
                  isEditing = false;
                  nameController.text = familyData!['familymember_name'] ?? '';
                  addressController.text =
                      familyData!['familymember_address'] ?? '';
                  contactController.text =
                      familyData!['familymember_contact']?.toString() ?? '';
                });
              },
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : familyData == null
              ? const Center(child: Text("No profile found"))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    color: Colors.white,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: isEditing ? _buildEditForm() : _buildViewProfile(),
                    ),
                  ),
                ),
      floatingActionButton: isEditing
          ? FloatingActionButton(
              backgroundColor: const Color.fromARGB(255, 0, 36, 94),
              onPressed: updateFamilyProfile,
              child: const Icon(Icons.save, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildViewProfile() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: CircleAvatar(
            radius: 50,
            backgroundImage: familyData!['familymember_photo'] != null
                ? NetworkImage(familyData!['familymember_photo'])
                : const AssetImage('assets/default_avatar.png')
                    as ImageProvider,
          ),
        ),
        const SizedBox(height: 20),
        profileRow("Name", familyData!['familymember_name']),
        profileRow("Address", familyData!['familymember_address']),
        profileRow("Phone", familyData!['familymember_contact'].toString()),
        profileRow("Email", familyData!['familymember_email']),
      ],
    );
  }

  Widget _buildEditForm() {
    return Form(
      key: _formKey,
      child: ListView(
        shrinkWrap: true,
        children: [
          const SizedBox(height: 20),
          TextFormField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
            ),
            validator: (value) =>
                value == null || value.isEmpty ? 'Please enter a name' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: addressController,
            decoration: const InputDecoration(
              labelText: 'Address',
              border: OutlineInputBorder(),
            ),
            validator: (value) => value == null || value.isEmpty
                ? 'Please enter an address'
                : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: contactController,
            decoration: const InputDecoration(
              labelText: 'Phone',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
            validator: (value) => value == null || value.isEmpty
                ? 'Please enter a phone number'
                : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: familyData!['familymember_email'],
            decoration: const InputDecoration(
              labelText: 'Email (Non-editable)',
              border: OutlineInputBorder(),
            ),
            enabled: false,
          ),
        ],
      ),
    );
  }

  Widget profileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text(
            "$label: ",
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color.fromARGB(255, 0, 36, 94)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
