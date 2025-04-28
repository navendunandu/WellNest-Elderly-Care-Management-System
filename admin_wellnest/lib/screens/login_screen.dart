import 'package:admin_wellnest/components/form_validation.dart';
import 'package:admin_wellnest/main.dart';
import 'package:admin_wellnest/screens/homepage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();
  String n = '';
  String p = '';
  final formKey = GlobalKey<FormState>();
  bool _isVisible = true;
  
  Future<void> submit() async {
  try {
    final auth = await supabase.auth.signInWithPassword(
      password: password.text, 
      email: email.text,
    );
    
    if (auth.user != null) {
      final admin = await supabase
          .from('tbl_admin')
          .count()
          .eq('admin_id', auth.user!.id);
          print(admin);  // Print the count of admin records
      
      print("Admin count: $admin");

      if (admin > 0) {  // Check if count is greater than 0
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const Homepage(),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login failed: Admin not found')),
        );
      }
    }
  } on AuthException catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Login failed: ${e.message}')),
    );
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: ${e.toString()}')),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(248, 248, 248, 1.0),
      body: Container(
          margin: EdgeInsets.symmetric(vertical: 70, horizontal: 200),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    blurRadius: 20,
                    color: const Color.fromARGB(92, 49, 48, 48),
                    spreadRadius: 7)
              ]),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  margin: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: const Color.fromARGB(255, 255, 255, 255),
                      image: DecorationImage(
                          image: AssetImage('asset/adminloginr.png'))),
                ),
              ),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(40),
                  decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 255, 255, 255),
                      borderRadius: BorderRadius.circular(20)),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'WellNest',
                          style: GoogleFonts.openSans(
                              fontSize: 60,
                              color: Color.fromRGBO(81, 40, 0, 1),
                              textStyle: TextStyle(
                                  letterSpacing: 2,
                                  fontWeight: FontWeight.bold)),
                        ),
                        Text('Login to your account',
                            style: GoogleFonts.sourceSans3(
                                fontSize: 18,
                                color: Color.fromRGBO(89, 46, 2, 1))),
                        SizedBox(
                          height: 20,
                        ),
                        TextFormField(
                          validator: (value) =>
                              FormValidation.validateEmail(value),
                          controller: email,
                          decoration: InputDecoration(
                            enabledBorder: UnderlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.brown, width: 1),
                            ),
                            focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                    color: Color.fromRGBO(86, 43, 0, 1),
                                    width: 2)),
                            hintText: "Enter Username",
                            hintStyle: TextStyle(),
                            labelText: "Username",
                            labelStyle: TextStyle(color: Colors.brown),
                            prefixIcon: Icon(Icons.person_2),
                          ),
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        TextFormField(
                          validator: (value) =>
                              FormValidation.validatePassword(value),
                          controller: password,
                          obscureText: _isVisible,
                          decoration: InputDecoration(
                              enabledBorder: UnderlineInputBorder(
                                borderSide:
                                    BorderSide(color: Colors.brown, width: 1),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Color.fromRGBO(86, 43, 0, 1),
                                      width: 2)),
                              hintText: "Enter Password",
                              labelStyle: TextStyle(color: Colors.brown),
                              labelText: "Password",
                              prefixIcon: Icon(Icons.password_sharp),
                              suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _isVisible = !_isVisible;
                                    });
                                  },
                                  icon: Icon(_isVisible
                                      ? Icons.visibility_off
                                      : Icons.visibility))),
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromRGBO(81, 40, 0, 1),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            padding: EdgeInsets.symmetric(
                                vertical: 16, horizontal: 32),
                          ),
                          onPressed: () {
                            if (formKey.currentState!.validate()) {
                              submit();
                              
                            }
                          },
                          child: Text("Log in"),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            ],
          )),
    );
  }
}
