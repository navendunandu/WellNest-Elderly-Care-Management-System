import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class ViewHealth extends StatefulWidget {
  String profile;
  ViewHealth({super.key, required this.profile});

  @override
  State<ViewHealth> createState() => _ViewHealthState();
}

class _ViewHealthState extends State<ViewHealth> {
  final SupabaseClient supabase = Supabase.instance.client;
  Map<String, dynamic>? healthData;
  bool isLoading = true;

  void initState() {
    super.initState();
    fetchHealthData();
  }

  Future<void> fetchHealthData() async {
    try {
      final response = await supabase
          .from('tbl_healthrecord')
          .select()
          .eq('resident_id', widget.profile)
          .order('health_date', ascending: false)
          .limit(1)
          .single();

      setState(() {
        healthData = response;
        isLoading = false;
      });
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching health data: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color.fromARGB(230, 255, 252, 197),
        appBar: AppBar(
          title: const Text(
            'View Health',
            style: TextStyle(
                color: Color.fromARGB(255, 255, 255, 255),
                fontSize: 23,
                fontWeight: FontWeight.bold),
          ),
          backgroundColor: Color.fromARGB(255, 0, 36, 94),
          foregroundColor: Colors.white,
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : healthData == null
                ? Center(
                    child: Column(
                      children: [
                        Text(
                          "No health records found.",
                          style: TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Date: ${DateFormat('yyyy-MM-dd').format(DateTime.parse(healthData!['health_date']))}",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              _buildHealthCard("Sugar Level",
                                  healthData!['health_sugarlevel']),
                              _buildHealthCard("Cholesterol",
                                  healthData!['health_cholestrol']),
                              _buildHealthCard(
                                  "Blood Pressure", healthData!['health_bp']),
                              _buildHealthCard(
                                  "Diabetes", healthData!['health_diabetes']),
                              _buildHealthCard(
                                  "Bone Density", healthData!['health_bd']),
                              _buildHealthCard(
                                  "Lipid Profile", healthData!['health_lp']),
                              _buildHealthCard(
                                  "Thyroid", healthData!['health_thyroid']),
                              _buildHealthCard("Liver Function",
                                  healthData!['health_liver']),
                            ]))));
  }

  Widget _buildHealthCard(String label, String value) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        tileColor: Colors.white,
        title: Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          value,
          style: TextStyle(fontSize: 16, color: Colors.grey.shade800),
        ),
        leading: const Icon(Icons.health_and_safety, color: Colors.orange),
      ),
    );
  }
}
