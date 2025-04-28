import 'package:admin_wellnest/main.dart';
import 'package:flutter/material.dart';

class AssignCaretaker extends StatefulWidget {
  final String id;
  const AssignCaretaker({super.key, required this.id});

  @override
  State<AssignCaretaker> createState() => _AssignCaretakerState();
}

class _AssignCaretakerState extends State<AssignCaretaker> {
  bool isLoading = true;
  List<Map<String, dynamic>> caretaker = [];
  String? currentCaretakerId; // To store the currently assigned caretaker ID

  @override
  void initState() {
    super.initState();
    fetchData();
    fetchCurrentAssignment();
  }

  Future<void> fetchData() async {
    setState(() {
      isLoading = true;
    });
    try {
      final response = await supabase.from('tbl_caretaker').select();
      for(var item in response) {
      final assign = await supabase.from('tbl_assign').count().eq('caretaker_id', item['caretaker_id']).neq('resident_id', widget.id);
      if(assign>=6){
        response.remove(item);
      }
      }
      setState(() {
        caretaker = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching caretaker data: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchCurrentAssignment() async {
    try {
      final response = await supabase
          .from('tbl_assign')
          .select('caretaker_id')
          .eq('resident_id', widget.id)
          .maybeSingle(); // Use maybeSingle since there should be at most one assignment
      
      setState(() {
        currentCaretakerId = response != null ? response['caretaker_id'] as String? : null;
      });
      print("Current caretaker ID for resident ${widget.id}: $currentCaretakerId");
    } catch (e) {
      print("Error fetching current assignment: $e");
    }
  }

  Future<void> assign(String id) async {
    try {
      // If already assigned, update instead of insert
      if (currentCaretakerId != null) {
        await supabase
            .from('tbl_assign')
            .update({'caretaker_id': id, 'assign_date':DateTime.now().toIso8601String()})
            .eq('resident_id', widget.id);
      } else {
        await supabase.from('tbl_assign').insert({
          'resident_id': widget.id,
          'caretaker_id': id,
        });
      }

      await supabase.from('tbl_resident').update({
        'resident_status': 4,
      }).eq('resident_id', widget.id);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Assigned")),
      );
      Navigator.pop(context, true);
    } catch (e) {
      print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Assign Caretaker",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        elevation: 4,
        backgroundColor: const Color.fromARGB(255, 24, 56, 111),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.fromARGB(255, 227, 242, 253),
              Color.fromARGB(255, 227, 242, 253),
            ],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            const Text(
              "Caretaker List",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 24, 56, 111),
              ),
            ),
            const SizedBox(height: 20),
            isLoading
                ? const CircularProgressIndicator()
                : caretaker.isEmpty
                    ? const Text("No caretakers found.")
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: caretaker.length,
                        itemBuilder: (context, index) {
                          final data = caretaker[index];
                          // Check if this caretaker is currently assigned
                          final bool isAssigned =
                              currentCaretakerId != null &&
                              currentCaretakerId == data['caretaker_id'];

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 10),
                            child: ListTile(
                              title: Text(data['caretaker_name']),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text("Email: ${data['caretaker_email']}"),
                                      ElevatedButton(
                                        onPressed: isAssigned
                                            ? null // Disable if already assigned
                                            : () {
                                                assign(data['caretaker_id']);
                                              },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: isAssigned
                                              ? Colors.grey // Grey when disabled
                                              : const Color.fromARGB(
                                                  255, 24, 56, 111),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 17, vertical: 8),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                        ),
                                        child: Text(
                                          isAssigned ? "Assigned" : "Assign",
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text("Contact: ${data['caretaker_contact']}"),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ],
        ),
      ),
    );
  }
}