import 'package:admin_wellnest/main.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ManageRelation extends StatefulWidget {
  const ManageRelation({super.key});

  @override
  State<ManageRelation> createState() => _ManageRelationState();
}

class _ManageRelationState extends State<ManageRelation> {
  final nameController = TextEditingController();

  bool isLoading = true;
  List<Map<String, dynamic>> relation = [];
  @override
  void initState() {
    super.initState();
    fetchData();
  }



 int eid=0;

  Future<void> fetchData() async {
    setState(() {
      isLoading = true;
    });
    try {
      final response = await supabase.from('tbl_relation').select().order('relation_name',ascending: true);
      print("Fetched data: $response");
      setState(() {
        relation = response;
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
      await supabase.from('tbl_relation').insert({
        'relation_name': nameController.text,
      });

      print("Insert Successful");
      nameController.clear();
      await fetchData();
    } catch (e) {
      print("Error: $e");
      setState(() {
        isLoading = false;
      });
    }
  }


  Future<void> updaterelation() async {
    try {
      await supabase.from('tbl_relation').update({'relation_name': nameController.text}).eq('relation_id', eid);
      print("Update Successful");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Relation updated successfully!'),
          backgroundColor: const Color.fromARGB(255, 77, 10, 0),
        ),
      );
     nameController.clear();
      fetchData();
    } catch (e) {
      print("Error updating relation: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update room. Please try again.'),
          backgroundColor: const Color.fromARGB(255, 77, 5, 0),
        ),
      );
    }
  }

  Future<void> deleteRoom(int id) async {
    try {
      await supabase.from('tbl_relation').delete().eq('relation_name', id);
      print("Delete Successful");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Relation deleted successfully!'),
          backgroundColor: const Color.fromARGB(255, 77, 10, 0),
        ),
      );
      print("Deleted relation with id: $id");
      fetchData();
    } catch (e) {
      print("Error deleting relation: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete room. Please try again.'),
          backgroundColor: const Color.fromARGB(255, 77, 5, 0),
        ),
      );
    }
  }

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
                    'Manage Relationships',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 24, 56, 111)),
                  ),
                  SizedBox(height: 20),
                  _buildTextField(nameController, "Relation Name",
                      "Enter Relation", Icons.arrow_drop_down),
                  SizedBox(height: 15),
                  ElevatedButton(
                    onPressed: eid==0?submit:updaterelation,
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
                            itemCount: relation.length,
                            itemBuilder: (context, index) {
                              final data = relation[index];
                              return Card(
                                margin: EdgeInsets.symmetric(vertical: 10),
                                child: ListTile(
                                  title: Text(data['relation_name']),
                                  // subtitle: Text('Count: ${data['count']}'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Text('Price: \$${data['price']}'),
                                      IconButton(
                                        icon: Icon(Icons.delete,
                                            color: const Color.fromARGB(
                                                255, 67, 4, 0)),
                                        onPressed: () {
                                          deleteRoom(data['relation_id']);
                                        },
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.edit,
                                            color: const Color.fromARGB(
                                                255, 67, 4, 0)),
                                        onPressed: () {
                                          setState(() {
                                            nameController.text =
                                                data['relation_name'];
                                            eid=data['relation_id'];  
                                          });
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
          prefixIcon: Icon(icon, color: Color.fromARGB(255, 24, 56, 111)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}
