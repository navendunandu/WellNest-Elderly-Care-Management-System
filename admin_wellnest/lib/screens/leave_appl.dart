import 'package:admin_wellnest/main.dart';
import 'package:flutter/material.dart';

class LeaveApplication extends StatefulWidget {
  const LeaveApplication({super.key});

  @override
  State<LeaveApplication> createState() => _LeaveApplicationState();
}

class _LeaveApplicationState extends State<LeaveApplication> {
  List<Map<String, dynamic>> _filetypeList = [];

  @override
  void initState() {
    super.initState();
    fetchFiletype();
  }

  Future<void> fetchFiletype() async {
    try {
      final response = await supabase
          .from('tbl_leave')
          .select('*, tbl_caretaker("*")')
          .eq('leave_status', 0);

      setState(() {
        _filetypeList = response;
      });
    } catch (e) {
      print("ERROR FETCHING FILE TYPE DATA: $e");
    }
  }

  Future<void> updateLeaveStatus(String leaveId, int status) async {
    try {
      await supabase
          .from('tbl_leave')
          .update({'leave_status': status}).match({'leave_id': leaveId});
      fetchFiletype();
    } catch (e) {
      print("ERROR UPDATING LEAVE STATUS: $e");
    }
  }

  void leaveVerify(String leaveId) {
    _showConfirmationDialog(
      "Are you sure you want to accept the request?",
      () => updateLeaveStatus(leaveId, 1),
    );
  }

  void leavedeny(String leaveId) {
    _showConfirmationDialog(
      "Are you sure you want to reject the request?",
      () => updateLeaveStatus(leaveId, 2),
    );
  }
  
  void _showConfirmationDialog(String message, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirmation"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm();
              },
              child: Text("Confirm"),
            ),
          ],
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      child: Center(
        child: SingleChildScrollView(
          child: Card(
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Leave Applications",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 24, 56, 111),
                    ),
                  ),
                  SizedBox(height: 20),
                  _filetypeList.isEmpty
                      ? Text("No leave applications available.")
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: _filetypeList.length,
                          itemBuilder: (context, index) {
                            final entry = _filetypeList[index];
                            final caretaker = entry['tbl_caretaker']
                                    ['caretaker_name']
                                .toString();
                            print(caretaker);
                            return Card(
                              margin: EdgeInsets.symmetric(vertical: 10),
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ListTile(
                                title: Text(
                                  "${entry['leave_reason']} (by $caretaker)",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("From: ${entry['leave_fromdate']}"),
                                    Text("To: ${entry['leave_todate']}"),
                                    Text(
                                      "Applied on: ${DateTime.parse(entry['leave_date']).toLocal().toString().split(' ')[0]} at "
                                      "${DateTime.parse(entry['leave_date']).toLocal().toString().split(' ')[1].split('.')[0]}",
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.check,
                                          color: Colors.green),
                                      onPressed: () {
                                        leaveVerify(
                                            entry['leave_id'].toString());
                                      },
                                    ),
                                    IconButton(
                                      icon:
                                          Icon(Icons.close, color: Colors.red),
                                      onPressed: () {
                                        leavedeny(entry['leave_id'].toString());
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
