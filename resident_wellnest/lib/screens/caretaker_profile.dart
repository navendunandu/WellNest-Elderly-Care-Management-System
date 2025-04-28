import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CaretakerProfile extends StatefulWidget {
  final String residentId;
  const CaretakerProfile({super.key, required this.residentId});

  @override
  State<CaretakerProfile> createState() => _CaretakerProfileState();
}

class _CaretakerProfileState extends State<CaretakerProfile> {
  final SupabaseClient supabase = Supabase.instance.client;
  Map<String, dynamic>? caretaker;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCaretaker();
  }

  Future<void> fetchCaretaker() async {
    try {
      final response = await supabase
          .from('tbl_assign')
          .select('caretaker_id')
          .eq('resident_id', widget.residentId)
          .maybeSingle();

      if (response == null || response['caretaker_id'] == null) {
        setState(() => isLoading = false);
        return;
      }

      final caretakerResponse = await supabase
          .from('tbl_caretaker')
          .select('*')
          .eq('caretaker_id', response['caretaker_id'])
          .maybeSingle();

      if (mounted) {
        setState(() {
          caretaker = caretakerResponse;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching caretaker: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(230, 255, 252, 197),
      appBar: AppBar(
        title: const Text('Caretaker Details',
            style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
        backgroundColor: const Color.fromARGB(255, 0, 36, 94),
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : caretaker == null
              ? const Center(
                  child: Text("No caretaker assigned",
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
                              backgroundImage: caretaker!['caretaker_photo'] !=
                                      null
                                  ? NetworkImage(caretaker!['caretaker_photo'])
                                  : const AssetImage(
                                          'assets/default_avatar.png')
                                      as ImageProvider,
                            ),
                          ),
                          const SizedBox(height: 16),
                          profileRow("Name", caretaker!['caretaker_name']),
                          profileRow("Contact", caretaker!['caretaker_contact'].toString()),
                          profileRow("Email", caretaker!['caretaker_email']),
                          
                         
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
