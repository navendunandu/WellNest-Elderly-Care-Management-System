import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:caretaker_wellnest/screens/chat.dart'; // Import Chat Screen

class FamilyMember extends StatefulWidget {
  final String residentId;
  const FamilyMember({super.key, required this.residentId});

  @override
  State<FamilyMember> createState() => _FamilyMemberState();
}

class _FamilyMemberState extends State<FamilyMember> {
  final supabase = Supabase.instance.client;
  Map<String, dynamic>? familyMemberData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchFamilyMemberDetails();
  }

  Future<void> fetchFamilyMemberDetails() async {
    try {
      final residentResponse = await supabase
          .from('tbl_resident')
          .select('familymember_id')
          .eq('resident_id', widget.residentId)
          .maybeSingle();

      if (residentResponse == null ||
          residentResponse['familymember_id'] == null) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      final String familyMemberId = residentResponse['familymember_id'];
      final familyResponse = await supabase
          .from('tbl_familymember')
          .select('*')
          .eq('familymember_id', familyMemberId)
          .maybeSingle();

      setState(() {
        familyMemberData = familyResponse;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching family member details: $e');
      setState(() {
        isLoading = false;
      });
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
          : familyMemberData == null
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
                              backgroundImage: familyMemberData![
                                          'familymember_photo'] !=
                                      null
                                  ? NetworkImage(
                                      familyMemberData!['familymember_photo'])
                                  : const AssetImage(
                                          'assets/default_avatar.png')
                                      as ImageProvider,
                            ),
                          ),
                          const SizedBox(height: 16),
                          profileRow(
                              "Name", familyMemberData!['familymember_name']),
                          profileRow(
                              "Email", familyMemberData!['familymember_email']),
                          profileRow(
                              "Phone",
                              familyMemberData!['familymember_contact']
                                  .toString()),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            
                            style: ElevatedButton.styleFrom(
                              shape: const CircleBorder(),
                              padding: const EdgeInsets.all(8),
                              backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => Chat(
                                    caretakerId:
                                        supabase.auth.currentUser!.id,
                                    familyMemberId:
                                        familyMemberData!['familymember_id'],
                                  ),
                                ),
                              );
                            },
                            child: const Icon(
                              Icons.chat_rounded,
                              color: Color.fromARGB(255, 0, 36, 94),
                              size: 28,
                            ),
                          ),
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
