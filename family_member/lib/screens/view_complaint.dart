import 'package:family_member/main.dart';
import 'package:flutter/material.dart';
import 'complaints.dart'; // Import the Complaints page

class ViewComplaint extends StatefulWidget {
  ViewComplaint({super.key});

  @override
  _ViewComplaintState createState() => _ViewComplaintState();
}

class _ViewComplaintState extends State<ViewComplaint> {
  // List to store fetched complaints
  List<Map<String, dynamic>> _complaints = [];

  // Flag to track loading state
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Fetch complaints when the widget is initialized
    _fetchComplaints();
  }

  // Function to fetch complaints from Supabase
  Future<void> _fetchComplaints() async {
    try {
      // Fetch data from 'tbl_complaint'
      final response = await supabase
          .from('tbl_complaint')
          .select()
          .eq('familymember_id', supabase.auth.currentUser!.id)
          .order('complaint_date', ascending: false); // Order by latest first

      // Update the state with fetched data
      setState(() {
        _complaints = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      // Handle errors
      setState(() {
        _isLoading = false;
      });
      print('Error fetching complaint: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching complaints: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(230, 255, 252, 197),
      appBar: AppBar(
        title: const Text(
          "View Complaints",
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 255, 255, 255),
              fontSize: 23),
        ),
        backgroundColor: const Color.fromARGB(255, 0, 36, 94),
        foregroundColor: Colors.white,
        elevation: 4,
        shadowColor: Colors.black45,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Card(
            elevation: 8,
            shadowColor: Colors.black45,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Your Complaints",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  // Display loading indicator or complaints list
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _complaints.isEmpty
                            ? const Center(child: Text("No complaints found."))
                            : ListView.builder(
                                itemCount: _complaints.length,
                                itemBuilder: (context, index) {
                                  final complaint = _complaints[index];
                                  return Card(
                                    color: Color.fromARGB(230, 255, 252, 197),
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    elevation: 3,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    child: ListTile(
                                      title: Text(
                                        complaint['complaint_title'] ??
                                            "No Title",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color.fromARGB(255, 0, 0, 0),
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            complaint['complaint_content'] ??
                                                "No Description",
                                            style: TextStyle(
                                              color:
                                                  Color.fromARGB(255, 0, 0, 0),
                                            ),
                                          ),
                                          SizedBox(
                                              height:
                                                  4), // Adds some spacing between content and reply
                                          Text(
                                            "Reply: ${complaint['complaint_reply'] ?? 'No reply yet'}",
                                            style: TextStyle(
                                              color: Color.fromARGB(
                                                  255,
                                                  100,
                                                  100,
                                                  100), // Slightly grey for distinction
                                              fontStyle: FontStyle
                                                  .italic, // Optional: to differentiate reply
                                            ),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const Complaints()),
          );
        },
        backgroundColor: const Color.fromARGB(255, 0, 36, 94),
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }
}
