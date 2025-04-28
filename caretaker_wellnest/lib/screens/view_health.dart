import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'update_health.dart';

class ViewHealth extends StatefulWidget {
  String resident_id;
  ViewHealth({super.key, required this.resident_id});

  @override
  State<ViewHealth> createState() => _ViewHealthState();
}

class _ViewHealthState extends State<ViewHealth> {
  final SupabaseClient supabase = Supabase.instance.client;
  Map<String, dynamic>? healthData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchHealthData();
  }

  Future<void> fetchHealthData() async {
    try {
      final response = await supabase
          .from('tbl_healthrecord')
          .select()
          .eq('resident_id', widget.resident_id)
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "No health records found.",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 14),
                        backgroundColor: Color.fromARGB(255, 0, 36, 94),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => UpdateHealth(
                                    residentId: widget.resident_id,
                                  )),
                        );
                      },
                      child: const Text(
                        'Update Health',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 255, 255, 255)),
                      ),
                    ),
                  ],
                ))
              : SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Date: ${DateTime.parse(healthData!['health_date']).toLocal().toString().split(' ')[0]}",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        _buildHealthCard(
                            "Sugar Level", healthData!['health_sugarlevel']),
                        _buildHealthCard(
                            "Cholesterol", healthData!['health_cholestrol']),
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
                        _buildHealthCard(
                            "Liver Function", healthData!['health_liver']),
                        // _buildHealthCard("Date", healthData!['health_date']),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 28, vertical: 14),
                              backgroundColor: Color.fromARGB(255, 0, 36, 94),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 5),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => UpdateHealth(
                                  residentId: widget.resident_id,
                                ),
                              ),
                            ).then((value) {
                            
                              if (value == true) {
                                fetchHealthData();
                              }
                            });
                          },
                          child: const Text(
                            'Update Health',
                            style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
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
