import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;
import 'dart:convert';

class Chat extends StatefulWidget {
  final String caretakerId;
  final String familyMemberId;

  const Chat({
    super.key,
    required this.caretakerId,
    required this.familyMemberId,
  });

  @override
  State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  final SupabaseClient supabase = Supabase.instance.client;
  final TextEditingController _messageController = TextEditingController();
  List<Map<String, dynamic>> messages = [];
  bool isLoading = true; // Track loading state

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  /// Initialize chat by fetching messages and setting up listener
  Future<void> _initializeChat() async {
    await fetchMessages();
    listenForMessages();
  }

  /// Fetch chat history between caretaker and family member
  Future<void> fetchMessages() async {
    try {
      final response = await supabase
          .from('tbl_chat')
          .select()
          .match({
            'chat_fromcid': widget.caretakerId,
            'chat_tofid': widget.familyMemberId,
          })
          .or(
            'chat_fromfid.eq.${widget.familyMemberId},chat_tocid.eq.${widget.caretakerId}',
          )
          .order('datetime', ascending: true);

      if (mounted) {
        setState(() {
          messages =
              response.map((msg) => Map<String, dynamic>.from(msg)).toList();
          isLoading = false; // Done loading
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false; // Stop loading even on error
        });
        print('Error fetching messages: $e'); // Log error for debugging
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load messages: $e')),
        );
      }
    }
  }

  Future<void> sendNotification() async {
    try {
      final response = await supabase
          .from('tbl_caretaker')
          .select()
          .eq('caretaker_id', widget.caretakerId)
          .single();

      String name = response['caretaker_name'] as String? ?? 'CareTaker';

      final fm = await supabase
          .from('tbl_familymember')
          .select()
          .eq('familymember_id', widget.familyMemberId)
          .single();

      String token = fm['fcm_token'];
      String title = 'New message';
      String body = 'You have a new message from $name.';
      sendPushNotification(token, body, title);
    } catch (a) {
      print('Error sending notification: $a');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send notification: $a')),
        );
      }
    } finally {
      print('Notification sent successfully!');
    }
  }

  Future<Map<String, dynamic>> loadConfig() async {
    try {
      final String jsonString =
          await rootBundle.loadString('asset/config.json');
      print("DATA: $jsonString");
      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      print("Error loading config.json: $e");
      return {}; // Return an empty map or handle appropriately
    }
  }

  Future<String> getAccessToken() async {
    // Your client ID and client secret obtained from Google Cloud Console
    final serviceAccountJson = await loadConfig();

    List<String> scopes = [
      "https://www.googleapis.com/auth/userinfo.email",
      "https://www.googleapis.com/auth/firebase.database",
      "https://www.googleapis.com/auth/firebase.messaging"
    ];

    http.Client client = await auth.clientViaServiceAccount(
      auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
      scopes,
    );

    // Obtain the access token
    auth.AccessCredentials credentials =
        await auth.obtainAccessCredentialsViaServiceAccount(
            auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
            scopes,
            client);

    // Close the HTTP client
    client.close();

    // Return the access token
    return credentials.accessToken.data;
  }

  void sendPushNotification(String userToken, String msg, String title) async {
    try {
      final String serverKey = await getAccessToken(); // Your FCM server key
      const String fcmEndpoint =
          'https://fcm.googleapis.com/v1/projects/wellnest-81951/messages:send';
      final Map<String, dynamic> message = {
        'message': {
          'token':
              userToken, // Token of the device you want to send the message to
          'notification': {
            "title": title,
            "body": msg,
          },
          'data': {
            'current_user_fcm_token':
                userToken, // Include the current user's FCM token in data payload
          },
        }
      };

      final http.Response response = await http.post(
        Uri.parse(fcmEndpoint),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $serverKey',
        },
        body: jsonEncode(message),
      );

      if (response.statusCode == 200) {
        print('FCM message sent successfully');
      } else {
        print('Failed to send FCM message: ${response.statusCode}');
      }
    } catch (e) {
      print("Failed Notification: $e");
    }
  }

  /// Listen for new messages in real time
  void listenForMessages() {
    supabase
        .from('tbl_chat')
        .stream(primaryKey: ['chat_id'])
        .order('datetime', ascending: true)
        .listen((snapshot) {
          if (mounted) {
            setState(() {
              final filteredMessages = snapshot.where((message) {
                return (message['chat_fromcid'] == widget.caretakerId &&
                        message['chat_tofid'] == widget.familyMemberId) ||
                    (message['chat_fromfid'] == widget.familyMemberId &&
                        message['chat_tocid'] == widget.caretakerId);
              }).toList();

              for (var message in filteredMessages) {
                if (!messages
                    .any((msg) => msg['chat_id'] == message['chat_id'])) {
                  messages.add(Map<String, dynamic>.from(message));
                }
              }
            });
          }
        })
        .onError((error) {
          print('Stream error: $error'); // Log stream errors
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Stream error: $error')),
            );
          }
        });
  }

  /// Send a new message
  Future<void> sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    try {
      await supabase.from('tbl_chat').insert({
        'chat_fromcid': widget.caretakerId,
        'chat_fromfid': null,
        'chat_tocid': null,
        'chat_tofid': widget.familyMemberId,
        'chat_content': messageText,
        'datetime': DateTime.now().toIso8601String(),
      });
      sendNotification();
      _messageController.clear();
    } catch (e) {
      print('Error sending message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: Column(
        children: [
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : messages.isEmpty
                    ? const Center(child: Text('No messages yet'))
                    : ListView.builder(
                        reverse: false,
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final isMe =
                              message['chat_fromcid'] == widget.caretakerId;

                          return Align(
                            alignment: isMe
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                  vertical: 5, horizontal: 10),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? Colors.greenAccent
                                    : Colors.grey[300],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                message['chat_content'] ?? '',
                                style: TextStyle(
                                    color: isMe ? Colors.white : Colors.black),
                              ),
                            ),
                          );
                        },
                      ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: "Type a message...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.green),
                  onPressed: sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
