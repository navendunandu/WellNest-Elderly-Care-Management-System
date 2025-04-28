import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ManageComplaints extends StatefulWidget {
  const ManageComplaints({super.key});

  @override
  _ManageComplaintsState createState() => _ManageComplaintsState();
}

class _ManageComplaintsState extends State<ManageComplaints> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> complaints = [];
  final TextEditingController _replyControllers = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchComplaints();
  }

  Future<void> _fetchComplaints() async {
    try {
      final response = await supabase
          .from('tbl_complaint')
          .select('*, tbl_familymember(*)')
          .eq('complaint_status', 0);
      List<Map<String, dynamic>> complaintList = [];
      for (var item in response) {
        final residents = await supabase
            .from('tbl_resident')
            .select()
            .eq('familymember_id', item['familymember_id']);
        List<String> residentName = [];
        for (var resident in residents) {
          residentName.add(resident['resident_name']);
        }
        complaintList.add({
          'id': item['complaint_id'],
          'title': item['complaint_title'],
          'date': item['complaint_date'],
          'content': item['complaint_content'],
          'reply': item['complaint_reply'],
          'status': item['complaint_status'],
          'family_member': item['tbl_familymember']['familymember_name'],
          'family_member_contact': item['tbl_familymember']
              ['familymember_contact'],
          'family_member_email': item['tbl_familymember']['familymember_email'],
          'residents': residentName
        });
        setState(() {
          complaints = complaintList;
        });
      }
      print("Complaint Data: $complaintList");
    } catch (error) {
      print('Error fetching complaints: $error');
    }
  }

  Future<void> _submitReply(int complaintId) async {
    print("Started");
    try {
      final replyText = _replyControllers.text;
      if (replyText.isNotEmpty) {
        await supabase
            .from('tbl_complaint')
            .update({'complaint_reply': replyText, 'complaint_status': 1}).eq(
                'complaint_id', complaintId);
        _replyControllers.clear();
        _fetchComplaints();
        Navigator.pop(context);
      }
    } catch (error) {
      print('Error submitting reply: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color.fromARGB(255, 227, 242, 253),
      padding: EdgeInsets.all(30),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: complaints.length,
        itemBuilder: (context, index) {
          final complaint = complaints[index];
          final complaintId = complaint[
              'id']; // Changed from complaint_id to id as per your complaintList mapping

          return Card(
            margin: const EdgeInsets.all(8.0),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                // Removed Expanded as it's not needed inside a Card
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Title: ${complaint['title']}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('Date: ${complaint['date']}'),
                  Text('Content: ${complaint['content']}'),
                  Text(
                    'Resident Name: ${complaint['residents'].join(', ')}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('Family Member: ${complaint['family_member']}'),
                  Text('Phone: ${complaint['family_member_contact']}'),
                  Text('Email: ${complaint['family_member_email']}'),
                  const SizedBox(height: 10),
                  complaint['status'] ==
                          0 // Changed from complaint_status to status
                      ? ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color.fromARGB(255, 0, 36, 94),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            padding: EdgeInsets.symmetric(
                                vertical: 16, horizontal: 32),
                          ),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('Provide Your Response'),
                                content: TextFormField(
                                  controller: _replyControllers,
                                  minLines: 2,
                                  maxLines: null,
                                  decoration: InputDecoration(
                                    hintText: "Enter Response",
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                actions: [
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Color.fromARGB(255, 0, 36, 94),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                      padding: EdgeInsets.symmetric(
                                          vertical: 14, horizontal: 28),
                                    ),
                                    onPressed: () => Navigator.pop(context),
                                    child: Text(
                                      'Cancel',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 18),
                                    ),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Color.fromARGB(255, 0, 36, 94),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                      padding: EdgeInsets.symmetric(
                                          vertical: 14, horizontal: 28),
                                    ),
                                    onPressed: () {
                                      _submitReply(complaintId);
                                    },
                                    child: Text(
                                      'Submit',
                                      style: TextStyle(fontSize: 18),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: const Text('Reply'),
                        )
                      : Text('Reply: ${complaint['reply'] ?? 'No reply yet'}'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
