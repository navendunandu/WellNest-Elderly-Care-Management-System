import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int residentCount = 0;
  int roomCount = 0;
  int caretakerCount = 0;
  int addressedComplaints = 0;
  int notAddressedComplaints = 0;
  int addressedLeaves=0;
  int notAddressedLeaves=0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() => isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      
      final residentData = await supabase.from('tbl_resident').select('resident_id');
      final leaveData = await supabase.from('tbl_leave').select('leave_id, leave_status');
      final caretakerData = await supabase.from('tbl_caretaker').select('caretaker_id');
      final complaintData = await supabase.from('tbl_complaint').select('complaint_id, complaint_status');
      
      setState(() {
        residentCount = residentData.length;
        roomCount = leaveData.length;
        caretakerCount = caretakerData.length;
        addressedComplaints = complaintData.where((c) => c['complaint_status'] == 1).length;
        notAddressedComplaints = complaintData.where((c) => c['complaint_status'] == 0).length;
        addressedLeaves=leaveData.where((l) => l['leave_status'] == 1).length;
        notAddressedLeaves=leaveData.where((l) => l['leave_status'] == 0).length;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching data: $e");
      setState(() => isLoading = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color.fromARGB(255, 227, 242, 253),
      padding: const EdgeInsets.all(30),
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildPieChart("Residents", residentCount, 70, Color.fromARGB(255, 33, 11, 55)),
                  _buildPieChart("Leaves", addressedLeaves, notAddressedLeaves + addressedLeaves, Color.fromARGB(255, 8, 38, 9)),
                  _buildPieChart("Caretakers", caretakerCount, 14, Color.fromARGB(255, 79, 0, 0)),
                  _buildPieChart("Complaints", addressedComplaints, addressedComplaints + notAddressedComplaints, Color.fromARGB(255, 5, 37, 63)),
                  
                ],
              ),
            ),
    );
  }

  Widget _buildPieChart(String title, int value, int maxValue, Color color) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: value.toDouble(),
                      title: '$value',
                      color: color,
                    ),
                    PieChartSectionData(
                      value: (maxValue - value).toDouble(),
                      title: '',
                      color: const Color.fromARGB(255, 255, 145, 145),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "$value / $maxValue",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
