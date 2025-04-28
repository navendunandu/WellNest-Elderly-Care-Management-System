import 'package:family_member/screens/chat.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ViewCaretaker extends StatefulWidget {
  final String resId;
  const ViewCaretaker({super.key, required this.resId});

  @override
  State<ViewCaretaker> createState() => _ViewCaretakerState();
}

class _ViewCaretakerState extends State<ViewCaretaker> {
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
      final assignResponse = await supabase
          .from('tbl_assign')
          .select('caretaker_id')
          .eq('resident_id', widget.resId)
          .maybeSingle();

      if (assignResponse == null) {
        setState(() => isLoading = false);
        return;
      }

      final caretakerId = assignResponse['caretaker_id'];
      final caretakerResponse = await supabase
          .from('tbl_caretaker')
          .select()
          .eq('caretaker_id', caretakerId)
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
                          profileRow("Email", caretaker!['caretaker_email']),
                          profileRow("Contact",
                              caretaker!['caretaker_contact'].toString()),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              shape: CircleBorder(),
                              padding: EdgeInsets.all(12),
                              backgroundColor:
                                  Colors.blue, // Adjust color as needed
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => Chat(
                                    familyMemberId:
                                        supabase.auth.currentUser!.id,
                                    caretakerId: caretaker!['caretaker_id'],
                                  ),
                                ),
                              );
                            },
                            child: Icon(
                              Icons.chat_bubble_outline,
                              color: Colors.white,
                              size: 28,
                            ),
                          )
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
