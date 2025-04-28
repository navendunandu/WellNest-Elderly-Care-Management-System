import 'dart:io';
import 'dart:typed_data';

import 'package:admin_wellnest/main.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class ManageRoom extends StatefulWidget {
  const ManageRoom({super.key});

  @override
  State<ManageRoom> createState() => _ManageRoomState();
}

class _ManageRoomState extends State<ManageRoom> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController countController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  bool isLoading = true;
  List<Map<String, dynamic>> rooms = [];
  PlatformFile? pickedImage;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> handleImagePick() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: false, // Only single file upload
    );
    if (result != null) {
      setState(() {
        pickedImage = result.files.first;
      });
    }
  }

  Future<void> fetchData() async {
    setState(() {
      isLoading = true;
    });
    try {
      final response = await supabase.from('tbl_room').select();
      print("Fetched data: $response");
      setState(() {
        rooms = response;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching data: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> submit() async {
    setState(() {
      isLoading = true;
    });
    try {
      String? url = await photoUpload();
      await supabase.from('tbl_room').insert({
        'room_name': nameController.text,
        'room_count': countController.text,
        'room_price': priceController.text,
        'room_photo': url,
      });

      print("Insert Successful");
      nameController.clear();
      countController.clear();
      priceController.clear();

      await fetchData();
    } catch (e) {
      print("Error: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  int eid=0;

  Future<void> editroom() async {
    try{
      await supabase.from('tbl_room').update({
        'room_name': nameController.text,
        'room_count': countController.text,
        'room_price': priceController.text,
      }).eq('room_id', eid);
      print("Update Successful");
      nameController.clear();
      countController.clear();
      priceController.clear();
      fetchData();
    }catch(e){
      print("Error: $e");
    }

  }

  Future<String?> photoUpload() async {
    try {
      final bucketName = 'room_files'; // Replace with your bucket name
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileExtension =
          pickedImage!.name.split('.').last; // Extract extension
      final filePath =
          "${pickedImage!.name.split('.').first}_$timestamp.$fileExtension";
      await supabase.storage.from(bucketName).uploadBinary(
            filePath,
            pickedImage!.bytes!, // Use file.bytes for Flutter Web
          );
      final publicUrl =
          supabase.storage.from(bucketName).getPublicUrl(filePath);
      // await updateImage(uid, publicUrl);
      pickedImage = null;
      return publicUrl;
    } catch (e) {
      print("Error photo upload: $e");
      return null;
    }
  }

  Future<void> deleteRoom(int id) async {
    try {
      await supabase.from('tbl_room').delete().eq('room_id', id);
      print("Delete Successful");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Room deleted successfully!'),
          backgroundColor: const Color.fromARGB(255, 0, 61, 2),
        ),
      );
      print("Deleted room with id: $id");
      fetchData();
    } catch (e) {
      print("Error deleting room: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete room. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color.fromARGB(255, 227, 242, 253),
      padding: EdgeInsets.all(30),
      child: Center(
        child: Card(
          elevation: 5,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Manage Rooms',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 24, 56, 111)),
                  ),
                  SizedBox(height: 20),
                  _buildTextField(nameController, "Room Name",
                      "Enter Room Name", Icons.room),
                  _buildTextField(countController, "Count", "Enter Total Count",
                      Icons.numbers),
                  _buildTextField(priceController, "Price", "Enter Price",
                      Icons.price_check),
                  SizedBox(height: 15),
                  SizedBox(
                    height: 120,
                    width: 120,
                    child: pickedImage == null
                        ? GestureDetector(
                            onTap: handleImagePick,
                            child: Icon(
                              Icons.add_a_photo,
                              color: Color(0xFF0277BD),
                              size: 50,
                            ),
                          )
                        : GestureDetector(
                            onTap: handleImagePick,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(100),
                              child: pickedImage!.bytes != null
                                  ? Image.memory(
                                      Uint8List.fromList(
                                          pickedImage!.bytes!), // For web
                                      fit: BoxFit.cover,
                                    )
                                  : Image.file(
                                      File(pickedImage!
                                          .path!), // For mobile/desktop
                                      fit: BoxFit.cover,
                                    ),
                            ),
                          ),
                  ),
                  ElevatedButton(
                    onPressed: eid==0?submit:editroom,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromARGB(255, 24, 56, 111),
                      padding:
                          EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                      textStyle: TextStyle(fontSize: 16),
                    ),
                    child: Text(
                      "Submit",
                      style:
                          TextStyle(color: Color.fromARGB(255, 227, 242, 253)),
                    ),
                  ),
                  SizedBox(height: 15),
                  Divider(),
                  SizedBox(height: 15),
                  isLoading
                      ? CircularProgressIndicator()
                      : SizedBox(
                          height: 300,
                          child: ListView.builder(
                            itemCount: rooms.length,
                            itemBuilder: (context, index) {
                              final data = rooms[index];
                              return Card(
                                margin: EdgeInsets.symmetric(vertical: 10),
                                child: ListTile(
                                  title: Text(data['room_name']),
                                  leading: Image.network(data['room_photo']),
                                  subtitle:
                                      Text('Count: ${data['room_count']}'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('Price: \₹${data['room_price']}'),
                                      IconButton(
                                        icon: Icon(Icons.edit,
                                            color: const Color.fromARGB(
                                                255, 67, 4, 0)),
                                        onPressed: () {
                                          setState(() {
                                            nameController.text = data['room_name'];
                                            countController.text = data['room_count'].toString();
                                            priceController.text = data['room_price'].toString();
                                            eid=data['room_id'].toInt();
                                          });
                                        },
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete,
                                            color: const Color.fromARGB(
                                                255, 67, 4, 0)),
                                        onPressed: () {
                                          deleteRoom(data['room_id']);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      String hint, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: Color.fromARGB(255, 0, 36, 94)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}
