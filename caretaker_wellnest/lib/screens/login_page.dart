import 'package:caretaker_wellnest/components/form_validation.dart';
import 'package:caretaker_wellnest/main.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'homepage.dart'; 

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool _isVisible = true;

  String email = '';
  String password = '';

 Future<void> submit() async {
  if (formKey.currentState!.validate()) {
    setState(() {
      email = emailController.text;
      password = passwordController.text;
    });

    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        final caretaker = await supabase
            .from('tbl_caretaker')
            .select()
            .eq('caretaker_id', response.user!.id);
            
        if (caretaker.isNotEmpty) {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => Homepage()),
          );
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Login failed: Caretaker not found')),
          );
        }
      }
    } on AuthException catch (e) {
      // Specific handling for auth errors
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: ${e.message}')),
      );
    } catch (e) {
      // General error handling
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,
              // color: Color.fromARGB(255, 0, 36, 94)
            ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          "Login Page",
          style: TextStyle(
            // color: Color.fromARGB(255, 0, 36, 94),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 0, 36, 94),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        color: const Color.fromARGB(230, 255, 252, 197),
        child: Center(
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: SizedBox(
                width: 400,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Welcome",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color.fromARGB(255, 0, 36, 94),
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Login to Continue",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Color.fromARGB(255, 0, 36, 94),
                          fontSize: 15),
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      "Email Address",
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        color: Color.fromARGB(255, 0, 36, 94),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      validator: (value) => FormValidation.validateEmail(value),
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Color.fromARGB(255, 24, 56, 111),
                            width: 1,
                          ),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Color.fromARGB(255, 24, 56, 111),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Password",
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        color: Color.fromARGB(255, 24, 56, 111),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: passwordController,
                      validator: (value) =>
                          FormValidation.validatePassword(value),
                      obscureText: _isVisible,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Color.fromARGB(255, 0, 36, 94),
                            width: 1,
                          ),
                        ),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _isVisible = !_isVisible;
                            });
                          },
                          icon: Icon(_isVisible
                              ? Icons.visibility_off
                              : Icons.visibility),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Color.fromARGB(255, 24, 56, 111),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: submit,
                      style: ElevatedButton.styleFrom(
                        shape: const ContinuousRectangleBorder(),
                        backgroundColor: const Color.fromARGB(255, 0, 36, 94),
                        fixedSize: const Size(
                            100, 55), // Ensures button is exactly this size
                      ),
                      child: const Text(
                        "Sign in",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Image.asset(
                      'asset/care.png',
                      fit: BoxFit.contain,
                      height: 300,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}