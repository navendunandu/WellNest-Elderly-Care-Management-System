import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ViewMedappointment extends StatefulWidget {
  final String residentId; // Made final as it won't change
  const ViewMedappointment({super.key, required this.residentId});

  @override
  State<ViewMedappointment> createState() => _ViewMedappointmentState();
}

class _ViewMedappointmentState extends State<ViewMedappointment> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> appointments = [];

  @override
  void initState() {
    super.initState();
    fetchAppointments(); // Call the fetch method when widget initializes
  }

  Future<void> fetchAppointments() async {
    try {
      final response = await supabase
          .from('tbl_appointment')
          .select()
          .eq('resident_id', widget.residentId)
          .order('appointment_date', ascending: false);
      
      setState(() {
        appointments = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      // Optional: Add error handling
      print('Error fetching appointments: $e');
      setState(() {
        appointments = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(230, 255, 252, 197),
      appBar: AppBar(
        title: const Text(
          'View Appointments',
          style: TextStyle(
            color: Color.fromARGB(255, 255, 255, 255),
            fontWeight: FontWeight.bold,
            fontSize: 23,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 0, 36, 94),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            appointments.isEmpty
                ? const Center(
                    child: Text(
                      "No Appointments Available",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : Expanded(
                    child: ListView.builder(
                      itemCount: appointments.length,
                      itemBuilder: (context, index) {
                        final appointment = appointments[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            title: Text("Dr. ${appointment['appointment_name']}"),
                            subtitle: Text(
                              "Date: ${appointment['appointment_date']}\n"
                              "Time: ${appointment['appointment_time']}",
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}