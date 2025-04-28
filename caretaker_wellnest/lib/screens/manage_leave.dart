import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class ManageLeave extends StatefulWidget {
  const ManageLeave({super.key});

  @override
  State<ManageLeave> createState() => _ManageLeaveState();
}

class _ManageLeaveState extends State<ManageLeave> {
  // Supabase client
  final SupabaseClient supabase = Supabase.instance.client;

  // List to store leave data
  List<Map<String, dynamic>> leaveData = [];

  // Function to fetch leave data from Supabase
  Future<void> fetchLeaveData() async {
    try {
      final response = await supabase
          .from('tbl_leave')
          .select()
          .gt('leave_status', -1)
          .neq('leave_status', 2);

      if (response != null) {
        setState(() {
          leaveData = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (e) {
      print('Error fetching leave data: $e');
    }
  }

  // Function to map leave_status to status string
  String getLeaveStatus(int status) {
    switch (status) {
      case 0:
        return 'Pending';
      case 1:
        return 'Approved';
      default:
        return 'Rejected';
    }
  }

  @override
  void initState() {
    super.initState();
    fetchLeaveData(); // Fetch data when the screen loads
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: Color.fromARGB(230, 255, 252, 197),
        appBar: AppBar(
          title: const Text('Leave Manager',style: TextStyle(color: Colors.white),),
          backgroundColor: Color.fromARGB(255, 0 , 36, 80),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: leaveData.isEmpty
            ? const Center(
                child: CircularProgressIndicator()) // Show loading indicator
            : ListView.builder(
                itemCount: leaveData.length,
                itemBuilder: (context, index) {
                  final leave = leaveData[index];

                
                  final appliedDate = DateFormat('yyyy-MM-dd')
                      .format(DateTime.parse(leave['leave_date']));

                  return Card(
                    margin: const EdgeInsets.all(8),
                    child: ListTile(
                      title: Text('Applied Date: $appliedDate'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              'From: ${leave['leave_fromdate']}'), // Leave as is
                          Text('To: ${leave['leave_todate']}'), // Leave as is
                          Text(
                              'Status: ${getLeaveStatus(leave['leave_status'])}'),
                        ],
                      ),
                    ),
                  );
                },
              ));
  }
}
