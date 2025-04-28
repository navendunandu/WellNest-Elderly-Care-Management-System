import 'package:family_member/main.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:family_member/components/form_validation.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

class Userregistration extends StatefulWidget {
  const Userregistration({super.key});

  @override
  State<Userregistration> createState() => _UserregistrationState();
}

class _UserregistrationState extends State<Userregistration> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool isLoading = true;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  File? _photo;
  File? _proof;

  final ImagePicker _picker = ImagePicker();

  // Pick Image Function
  Future<void> _pickImage(bool isPhoto) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        if (isPhoto) {
          _photo = File(pickedFile.path);
        }
      });
    }
  }

  File? selectedFile;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    File? file = File(result!.files.single.path!);
    setState(() {
      selectedFile = file;
    });
  }

  Future<void> register() async {
    try {
      final auth = await supabase.auth.signUp(
          password: _passwordController.text, email: _emailController.text);
      String uid = auth.user!.id;
      submit(uid);
    } catch (e) {
      print("Error: $e");
    }
  }

  Future<void> submit(String uid) async {
    setState(() {
      isLoading = true;
    });
    try {
      await supabase.from('tbl_familymember').insert({
        'familymember_id': uid,
        'familymember_name': _nameController.text,
        'familymember_email': _emailController.text,
        'familymember_password': _passwordController.text,
        'familymember_contact': _phoneController.text,
        'familymember_address': _addressController.text,
      });
      String? proofUrl = await uploadFile(uid);
      String? photoUrl = await _uploadImage(uid);
      if (photoUrl != null && proofUrl != null) {
        update(photoUrl, proofUrl, uid);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Registration Successful"),
          backgroundColor: Color.fromARGB(255, 86, 1, 1),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      print("Error: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> update(String image, String proof, String uid) async {
    try {
      await supabase.from('tbl_familymember').update({
        'familymember_photo': image,
        'familymember_proof': proof,
      }).eq('familymember_id', uid);
    } catch (e) {
      print("Error: $e");
    }
  }

  Future<String?> uploadFile(String userId) async {
    final fileName = 'userproof_$userId';

    try {
      await supabase.storage.from('fm_files').upload(fileName, selectedFile!);
      final fileUrl = supabase.storage.from('fm_files').getPublicUrl(fileName);
      return fileUrl;
    } catch (e) {
      print("Upload failed: $e");
    }
    return null;
  }

  Future<String?> _uploadImage(String userId) async {
    try {
      final fileName = 'userphoto_$userId';

      await supabase.storage.from('fm_files').upload(fileName, _photo!);

      final imageUrl = supabase.storage.from('fm_files').getPublicUrl(fileName);
      return imageUrl;
    } catch (e) {
      print('Image upload failed: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(230, 255, 252, 197),
      appBar: AppBar(
        title: const Text(
          "Create Account",
          style: TextStyle(
              fontWeight: FontWeight.bold,
              ),
        ),
        backgroundColor: Color.fromARGB(255, 0, 36, 94),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,
              ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            elevation: 5,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      "Family Member Registration",
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 0, 36, 94)),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(_nameController, 'Name', Icons.person,
                        FormValidation.validateName),
                    _buildTextField(_addressController, 'Address', Icons.home,
                        FormValidation.validateAddress),
                    _buildTextField(_emailController, 'Email', Icons.email,
                        FormValidation.validateEmail),
                    _buildTextField(
                      _passwordController,
                      'Password',
                      Icons.lock,
                      FormValidation.validatePassword,
                      obscureText: !_isPasswordVisible,
                      isPasswordField: true,
                      toggleVisibility: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                    _buildTextField(
                      _confirmPasswordController,
                      'Confirm Password',
                      Icons.lock_outline,
                      (value) => FormValidation.validateConfirmPassword(
                          value, _passwordController.text),
                      obscureText: !_isConfirmPasswordVisible,
                      isPasswordField: true,
                      toggleVisibility: () {
                        setState(() {
                          _isConfirmPasswordVisible =
                              !_isConfirmPasswordVisible;
                        });
                      },
                    ),
                    _buildTextField(_phoneController, 'Phone Number',
                        Icons.phone, FormValidation.validateContact),
                    const SizedBox(height: 10),
                    const Text("Upload Proof (ID or Document)",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    _proof != null
                        ? Image.file(_proof!, height: 100)
                        : ElevatedButton.icon(
                            icon: const Icon(Icons.upload_file),
                            label: const Text("Upload Proof"),
                            onPressed: () => _pickFile(),
                          ),
                    // Upload Photo
                    const SizedBox(height: 10),
                    const Text("Upload Photo",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    _photo != null
                        ? Image.file(_photo!, height: 100)
                        : ElevatedButton.icon(
                            icon: const Icon(Icons.camera_alt),
                            label: const Text("Upload Photo"),
                            onPressed: () => _pickImage(true),
                          ),
                    const SizedBox(height: 20),

                    const Divider(),
                    const SizedBox(height: 20),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromARGB(255, 0, 36, 94),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          register();
                        }
                      },
                      child: const Text(
                        'Register',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      IconData icon, String? Function(String?)? validator,
      {bool obscureText = false,
      bool isPasswordField = false,
      VoidCallback? toggleVisibility}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.blueGrey),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: Colors.white,
          suffixIcon: isPasswordField
              ? IconButton(
                  icon: Icon(
                    obscureText ? Icons.visibility_off : Icons.visibility,
                    color: Colors.blueGrey,
                  ),
                  onPressed: toggleVisibility,
                )
              : null,
        ),
        obscureText: obscureText,
        validator: validator,
      ),
    );
  }
}
