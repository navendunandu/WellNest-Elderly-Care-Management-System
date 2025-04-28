import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ResidentProfile extends StatefulWidget {
  final String residentId;
  const ResidentProfile({super.key, required this.residentId});

  @override
  State<ResidentProfile> createState() => _ResidentProfileState();
}

class _ResidentProfileState extends State<ResidentProfile> {
  final SupabaseClient supabase = Supabase.instance.client;
  Map<String, dynamic>? resident;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchResident();
  }

  Future<void> fetchResident() async {
    try {
      final response = await supabase
          .from('tbl_resident')
          .select("*, tbl_relation(*)")
          .eq('resident_id', widget.residentId)
          .maybeSingle();
      print("${response!['tbl_relation']['relation_name']}: response");
      if (mounted) {
        setState(() {
          resident = response;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching resident: $e');
      setState(() => isLoading = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(230, 255, 252, 197),
      appBar: AppBar(
        title: const Text('Resident Details',
            style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
        backgroundColor: const Color.fromARGB(255, 0, 36, 94),
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? Center(
                  child: Text("No resident found",
                      style: TextStyle(fontSize: 18, color: Colors.black54)))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    color: Colors.white,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: CircleAvatar(
                              radius: 50,
                              backgroundImage: resident!['resident_photo'] !=
                                      null
                                  ? NetworkImage(resident!['resident_photo'])
                                  : const AssetImage(
                                          'assets/default_avatar.png')
                                      as ImageProvider,
                            ),
                          ),
                          const SizedBox(height: 16),
                          profileRow("Name", resident!['resident_name']),
                          profileRow(
                              "DOB", resident!['resident_dob'].toString()),
                          profileRow("Contact",
                              resident!['resident_contact'].toString()),
                          profileRow("Address", resident!['resident_address']),
                          profileRow("Email", resident!['resident_email']),
                          profileRow(
                              "Relation",
                              resident!['tbl_relation']['relation_name']
                                  .toString()),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget profileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text(
            "$label: ",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color.fromARGB(255, 0, 36, 94),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
