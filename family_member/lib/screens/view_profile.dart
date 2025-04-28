import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ViewProfile extends StatefulWidget {
  final String profile; // Assuming this is the resident_id (UUID)

  const ViewProfile({super.key, required this.profile});

  @override
  State<ViewProfile> createState() => _ViewProfileState();
}

class _ViewProfileState extends State<ViewProfile> {
  final SupabaseClient supabase = Supabase.instance.client;
  Map<String, dynamic>? residentData;
  bool isLoading = true;
  bool isEditing = false;

  // Controllers for the text fields
  late TextEditingController nameController;
  late TextEditingController addressController;
  late TextEditingController contactController;
  // late TextEditingController emailController;
  late TextEditingController dobController;

  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Initialize controllers
    nameController = TextEditingController();
    addressController = TextEditingController();
    contactController = TextEditingController();
    // emailController = TextEditingController();
    dobController = TextEditingController();

    fetchResidentProfile();
  }

  @override
  void dispose() {
    // Dispose controllers
    nameController.dispose();
    addressController.dispose();
    contactController.dispose();
    // emailController.dispose();
    dobController.dispose();
    super.dispose();
  }

  Future<void> fetchResidentProfile() async {
    final response = await supabase
        .from('tbl_resident')
        .select()
        .eq('resident_id', widget.profile)
        .maybeSingle();

    if (mounted) {
      setState(() {
        residentData = response;
        isLoading = false;

        // Set the controller values
        if (residentData != null) {
          nameController.text = residentData!['resident_name'] ?? '';
          addressController.text = residentData!['resident_address'] ?? '';
          contactController.text =
              residentData!['resident_contact']?.toString() ?? '';
          // emailController.text = residentData!['resident_email'] ?? '';
          dobController.text = residentData!['resident_dob'] ?? '';
        }
      });
    }
  }

  Future<void> updateResidentProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });

      try {
        await supabase.from('tbl_resident').update({
          'resident_name': nameController.text,
          'resident_address': addressController.text,
          'resident_contact': contactController.text,
          // 'resident_email': emailController.text,
          'resident_dob': dobController.text,
        }).eq('resident_id', widget.profile);

        // Refresh the data
        await fetchResidentProfile();

        // Exit edit mode
        setState(() {
          isEditing = false;
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully!')));
      } catch (e) {
        setState(() {
          isLoading = false;
        });

        // Show error message
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
          isEditing ? 'Edit Resident Profile' : 'Resident Profile',
          style: const TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 255, 255, 255),
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 0, 36, 94),
        foregroundColor: Colors.white,
        actions: [
          if (!isEditing && residentData != null)
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

                  // Reset the controller values
                  if (residentData != null) {
                    nameController.text = residentData!['resident_name'] ?? '';
                    addressController.text =
                        residentData!['resident_address'] ?? '';
                    contactController.text =
                        residentData!['resident_contact']?.toString() ?? '';
                    // emailController.text =
                    //     residentData!['resident_email'] ?? '';
                    dobController.text = residentData!['resident_dob'] ?? '';
                  }
                });
              },
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : residentData == null
              ? const Center(child: Text("No profile found"))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    color: Colors.white,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: isEditing ? _buildEditForm() : _buildViewProfile(),
                    ),
                  ),
                ),
      floatingActionButton: isEditing
          ? FloatingActionButton(
              backgroundColor: const Color.fromARGB(255, 0, 36, 94),
              onPressed: updateResidentProfile,
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
            backgroundImage: residentData!['resident_photo'] != null
                ? NetworkImage(residentData!['resident_photo'])
                : const AssetImage('assets/default_avatar.png')
                    as ImageProvider,
          ),
        ),
        const SizedBox(height: 20),
        profileRow("Name", residentData!['resident_name']),
        profileRow("Address", residentData!['resident_address']),
        profileRow("Contact", residentData!['resident_contact'].toString()),
        profileRow("Email", residentData!['resident_email']),
        profileRow("Date of Birth", residentData!['resident_dob']),
      ],
    );
  }

  Widget _buildEditForm() {
    return Form(
      key: _formKey,
      child: ListView(
        shrinkWrap: true,
        children: [
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: residentData!['resident_photo'] != null
                      ? NetworkImage(residentData!['resident_photo'])
                      : const AssetImage('assets/default_avatar.png')
                          as ImageProvider,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: CircleAvatar(
                    backgroundColor: const Color.fromARGB(255, 0, 36, 94),
                    radius: 18,
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt,
                          size: 18, color: Colors.white),
                      onPressed: () {
                        // Photo upload functionality can be added here
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text(
                                'Photo upload functionality not implemented yet')));
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a name';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: addressController,
            decoration: const InputDecoration(
              labelText: 'Address',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter an address';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: contactController,
            decoration: const InputDecoration(
              labelText: 'Contact',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a contact number';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          /*TextFormField(
            controller: emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter an email';
              }
              if (!value.contains('@')) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),*/
          const SizedBox(height: 12),
          TextFormField(
            controller: dobController,
            decoration: InputDecoration(
              labelText: 'Date of Birth',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() {
                      dobController.text =
                          picked.toIso8601String().split('T')[0];
                    });
                  }
                },
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a date of birth';
              }
              return null;
            },
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
              color: Color.fromARGB(255, 0, 36, 94),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
