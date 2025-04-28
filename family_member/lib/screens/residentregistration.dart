import 'dart:io';
import 'package:family_member/screens/manage_profile.dart';
import 'package:family_member/services/auth_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:family_member/components/form_validation.dart';
import 'package:family_member/main.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class Residentregistration extends StatefulWidget {
  const Residentregistration({super.key});

  @override
  State<Residentregistration> createState() => _ResidentregistrationState();
}

class _ResidentregistrationState extends State<Residentregistration> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  TextEditingController ageController = TextEditingController();
  bool isLoading = true;
  File? _photo;
  File? _proof;
  final ImagePicker _picker = ImagePicker();
  final AuthService _authService = AuthService();
  List<Map<String, dynamic>> rooms = [];

  List<Map<String, dynamic>> relation = [];
  DateTime? selectedDate;

  Future<void> _pickDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime maxDate = DateTime(now.year - 25, now.month, now.day);
    final DateTime minDate = DateTime(now.year - 90, now.month, now.day);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: maxDate,
      firstDate: minDate,
      lastDate: maxDate,
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
        _calculateAge(picked);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchData();
    checkResident();
    fetchRoomData();
  }

  Future<void> fetchData() async {
    try {
      final response = await supabase.from('tbl_relation').select();
      setState(() {
        relation = response;
      });
    } catch (e) {
      print("Error fetching data: $e");
    }
  }

  Future<void> fetchRoomData() async {
    try {
      final response = await supabase.from('tbl_room').select();
      print("Fetched data: $response");
      setState(() {
        rooms = response;
      });
    } catch (e) {
      print("Error fetching data: $e");
    }
  }

  String? selectedRelation;

  // Pick Image Function
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _photo = File(pickedFile.path);
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
      print("User1: ${supabase.auth.currentUser!.id}");
      final auth = await supabase.auth.signUp(
          password: _passwordController.text, email: _emailController.text);
      String uid = auth.user!.id;
      await _authService.relogin();
      await submit(uid);
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> submit(String uid) async {
    setState(() {
      isLoading = true;
    });
    if (selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Select a date of birth")),
      );
      return;
    }
    try {
      String fmid = supabase.auth.currentUser!.id;
      await supabase.from('tbl_resident').insert({
        'resident_id': uid,
        'resident_name': _nameController.text,
        'resident_email': _emailController.text,
        'resident_password': _passwordController.text,
        'resident_contact': _phoneController.text,
        'resident_address': _addressController.text,
        'familymember_id': fmid,
        'relation_id': selectedRelation,
        'resident_dob': selectedDate!.toIso8601String().split('T')[0]
      });

      String? proofUrl = await uploadFile(uid);
      String? photoUrl = await _uploadImage(uid);

      if (proofUrl != null && photoUrl != null) {
        update(photoUrl, proofUrl, uid);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Registration Successful"),
          backgroundColor: Color.fromARGB(255, 86, 1, 1),
        ),
      );
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ManageProfile(),
          ));
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
      await supabase.from('tbl_resident').update({
        'resident_photo': image,
        'resident_proof': proof,
        'room_id': selectedRoom,
      }).eq('resident_id', uid);
    } catch (e) {
      print("Error: $e");
    }
  }

  Future<String?> uploadFile(String userId) async {
    final fileName = 'userproof_$userId';

    try {
      await supabase.storage
          .from('resident_files')
          .upload(fileName, selectedFile!);
      final fileUrl =
          supabase.storage.from('resident_files').getPublicUrl(fileName);
      return fileUrl;
    } catch (e) {
      print("Upload failed: $e");
    }
    return null;
  }

  Future<String?> _uploadImage(String userId) async {
    try {
      final fileName = 'userphoto_$userId';

      await supabase.storage.from('resident_files').upload(fileName, _photo!);

      // Get public URL of the uploaded image
      final imageUrl =
          supabase.storage.from('resident_files').getPublicUrl(fileName);
      return imageUrl;
    } catch (e) {
      print('Image upload failed: $e');
      return null;
    }
  }

  void _calculateAge(DateTime birthDate) {
    DateTime today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    ageController.text = age.toString(); // Update age field
  }

  bool isMember = false;
  String? roomId;

  Future<void> checkResident() async {
    try {
      final response = await supabase
          .from('tbl_resident')
          .select()
          .eq('familymember_id', supabase.auth.currentUser!.id)
          .eq('resident_status', 1);
      print("Checking data: $response");
      print("Checking room: ${response[0]['room_id']}");
      if (response.length == 1) {
        print("Happening");
        setState(() {
          isMember = true;
          roomId = response[0]['room_id'].toString();
        });
      }
    } catch (e) {
      print("Error checking: $e");
    }
  }

  String? selectedRoom;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color.fromARGB(230, 255, 252, 197),
        appBar: AppBar(
          title: Text(
            'Resident Registration Page',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          backgroundColor: Color.fromARGB(255, 0, 36, 94),
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        body: Expanded(
          child: SingleChildScrollView(
              child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    elevation: 5,
                    child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Form(
                            key: _formKey,
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Text(
                                    "Resident Registration",
                                    style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Color.fromARGB(255, 0, 36, 94)),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 20),
                                  _buildTextField(
                                      _nameController,
                                      'Name',
                                      Icons.person,
                                      FormValidation.validateName),
                                  _buildTextField(
                                      _addressController,
                                      'Address',
                                      Icons.home,
                                      FormValidation.validateAddress),
                                  _buildTextField(
                                      _phoneController,
                                      'Phone',
                                      Icons.phone_android_outlined,
                                      FormValidation.validateContact),
                                  TextField(
                                    readOnly: true,
                                    controller: TextEditingController(
                                      text: selectedDate == null
                                          ? ""
                                          : "${selectedDate!.toLocal()}".split(
                                              ' ')[0], // Display YYYY-MM-DD
                                    ),
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Colors.white,
                                      labelText: "Date of Birth",
                                      suffixIcon: IconButton(
                                        icon: Icon(Icons.calendar_today),
                                        onPressed: () => _pickDate(context),
                                      ),
                                      border: OutlineInputBorder(),
                                    ),
                                    onTap: () => _pickDate(
                                        context), // Open calendar when field is tapped
                                  ),
                                  SizedBox(height: 10),
                                  TextField(
                                    readOnly: true,
                                    controller: ageController,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Colors.white,
                                      labelText: "Age",
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  _buildTextField(
                                      _emailController,
                                      'Email',
                                      Icons.email,
                                      FormValidation.validateEmail),
                                  _buildTextField(
                                      _passwordController,
                                      'Password',
                                      Icons.lock,
                                      FormValidation.validatePassword,
                                      obscureText: true),
                                  _buildTextField(
                                    _confirmPasswordController,
                                    'Confirm Password',
                                    Icons.lock_outline,
                                    (value) =>
                                        FormValidation.validateConfirmPassword(
                                            value, _passwordController.text),
                                    obscureText: true,
                                  ),
                                  const SizedBox(height: 10),
                                  DropdownButtonFormField<String>(
                                    decoration: InputDecoration(
                                      labelText: "Select Relation",
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                    ),
                                    value: selectedRelation,
                                    hint: Text("Select an option"),
                                    items: relation.map((value) {
                                      return DropdownMenuItem<String>(
                                        value: value['relation_id'].toString(),
                                        child: Text(value['relation_name']),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        selectedRelation = value;
                                      });
                                    },
                                  ),
                                  SizedBox(
                                    height: 10,
                                  ),

                                  ListView(
                                    shrinkWrap: true,
                                    physics: NeverScrollableScrollPhysics(),
                                    children: rooms.map((room) {
                                      int? roomAmt;
                                      if (isMember &&
                                          roomId ==
                                              room['room_id'].toString()) {
                                        roomAmt = 0;
                                      } else {
                                        roomAmt = room['room_price'];
                                      }
                                      print("Debugging phase 1");
                                      print(
                                          "Room ${room['room_id']} : price: $roomAmt");
                                      print(isMember);
                                      print("Checked room is $roomId");
                                      return Row(
                                        children: [
                                          Expanded(
                                            child: RadioListTile<String>(
                                              title: Text(
                                                  "${room['room_name']} = Rs. ${roomAmt.toString()}"), // Display room name
                                              value: room['room_id'].toString(),
                                              groupValue:
                                                  selectedRoom, // Compare with selected value
                                              onChanged: (String? value) {
                                                setState(() {
                                                  selectedRoom = value;
                                                });
                                              },
                                            ),
                                          ),
                                          TextButton(
                                              onPressed: () {
                                                showDialog(
                                                  context: context,
                                                  builder: (context) {
                                                    return Dialog(
                                                      child: SizedBox(
                                                          height: 500,
                                                          width: 500,
                                                          child: Image.network(
                                                              room[
                                                                  'room_photo'])),
                                                    );
                                                  },
                                                );
                                              },
                                              child: Text('View Photo'))
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text("Upload Proof (ID or Document)",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
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
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 5),
                                  _photo != null
                                      ? Image.file(_photo!, height: 100)
                                      : ElevatedButton.icon(
                                          icon: const Icon(Icons.camera_alt),
                                          label: const Text("Upload Photo"),
                                          onPressed: () => _pickImage(),
                                        ),
                                  const SizedBox(height: 20),
                                  const Divider(),
                                  const SizedBox(height: 20),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Color.fromARGB(255, 0, 36, 94),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10)),
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
                                ]))),
                  ))),
        ));
  }

  Widget _buildTextField(TextEditingController controller, String label,
      IconData icon, String? Function(String?)? validator,
      {bool obscureText = false}) {
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
        ),
        obscureText: obscureText,
        validator: validator,
      ),
    );
  }
}
