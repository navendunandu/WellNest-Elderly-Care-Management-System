import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FamProfile extends StatefulWidget {
  final String residentId;
  const FamProfile({super.key, required this.residentId});

  @override
  State<FamProfile> createState() => _FamProfileState();
}

class _FamProfileState extends State<FamProfile> {
  final SupabaseClient supabase = Supabase.instance.client;
  Map<String, dynamic>? familyMember;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchFamilyMember();
  }

  Future<void> fetchFamilyMember() async {
    try {
      final response = await supabase
          .from('tbl_resident')
          .select('familymember_id')
          .eq('resident_id', widget.residentId)
          .maybeSingle();

      if (response == null || response['familymember_id'] == null) {
        setState(() => isLoading = false);
        return;
      }

      final familyResponse = await supabase
          .from('tbl_familymember')
          .select('*')
          .eq('familymember_id', response['familymember_id'])
          .maybeSingle();

      if (mounted) {
        setState(() {
          familyMember = familyResponse;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching family member: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(230, 255, 252, 197),
      appBar: AppBar(
        title: const Text('Family Member Details',
            style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
        backgroundColor: const Color.fromARGB(255, 0, 36, 94),
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : familyMember == null
              ? const Center(
                  child: Text("No family member found",
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
                              backgroundImage: familyMember!['familymember_photo'] !=
                                      null
                                  ? NetworkImage(familyMember!['familymember_photo'])
                                  : const AssetImage(
                                          'assets/default_avatar.png')
                                      as ImageProvider,
                            ),
                          ),
                          const SizedBox(height: 16),
                          profileRow("Name", familyMember!['familymember_name']),
                          profileRow("Contact", familyMember!['familymember_contact'].toString()),
                          profileRow("Address", familyMember!['familymember_address']),
                          profileRow("Email", familyMember!['familymember_email']),
                          
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
