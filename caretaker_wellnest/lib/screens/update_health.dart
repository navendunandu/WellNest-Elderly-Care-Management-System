import 'package:caretaker_wellnest/main.dart';
import 'package:flutter/material.dart';

class UpdateHealth extends StatefulWidget {
  final String residentId;
  const UpdateHealth({super.key, required this.residentId});

  @override
  State<UpdateHealth> createState() => _UpdateHealthState();
}

class _UpdateHealthState extends State<UpdateHealth> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _sugarlevel = TextEditingController();
  final TextEditingController _cholestrol = TextEditingController();
  final TextEditingController _bp = TextEditingController();
  final TextEditingController _diabetes = TextEditingController();
  final TextEditingController _bd = TextEditingController();
  final TextEditingController _lp = TextEditingController();
  final TextEditingController _thyroid = TextEditingController();
  final TextEditingController _liverfunction = TextEditingController();

  bool isLoading = false; // Set initial value to false

  Future<void> submit() async {
    // Check if the form is valid before submitting
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });
      try {
        await supabase.from('tbl_healthrecord').insert({
          'health_sugarlevel': _sugarlevel.text,
          'health_cholestrol': _cholestrol.text,
          'health_bp': _bp.text,
          'health_diabetes': _diabetes.text,
          'health_bd': _bd.text,
          'health_lp': _lp.text,
          'health_thyroid': _thyroid.text,
          'health_liver': _liverfunction.text,
          'resident_id': widget.residentId,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Updation Successful"),
            backgroundColor: Color.fromARGB(255, 86, 1, 1),
          ),
        );
        Navigator.pop(context, true);
      } catch (e) {
        print("Error: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(230, 255, 252, 197),
      appBar: AppBar(
        title: const Text(
          "Update Health",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(255, 0, 36, 94),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            elevation: 5,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      "Update Health Record",
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 0, 36, 94)),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                        _sugarlevel, 'Sugar Level', Icons.health_and_safety,
                        validator: _numericValidator),
                    _buildTextField(
                      _cholestrol,
                      'Cholesterol Level',
                      Icons.panorama_horizontal_select_sharp,
                      validator: _numericValidator,
                    ),
                    _buildTextField(
                      _diabetes,
                      'Diabetes',
                      Icons.lunch_dining,
                      validator: _numericValidator,
                    ),
                    _buildTextField(
                      _bp,
                      'Blood Pressure',
                      Icons.sports_gymnastics,
                      validator: _bpValidator,
                    ),
                    _buildTextField(
                      _bd,
                      'Bone Density',
                      Icons.brightness_high_rounded,
                      validator: _numericValidator,
                    ),
                    _buildTextField(
                      _lp,
                      'Lipid Profile',
                      Icons.bloodtype,
                      validator: _numericValidator,
                    ),
                    _buildTextField(
                      _thyroid,
                      'Thyroid Level',
                      Icons.live_help_outlined,
                      validator: _numericValidator,
                    ),
                    _buildTextField(
                      _liverfunction,
                      'Liver Function',
                      Icons.local_hospital,
                      validator: _numericValidator,
                    ),
                    const Divider(),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 0, 36, 94),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: isLoading
                          ? null
                          : submit, // Disable button when loading
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Update',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
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

  // Generic validator for numeric fields
  String? _numericValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    if (double.tryParse(value) == null) {
      return 'Please enter a valid number';
    }
    return null;
  }

  // Specific validator for Blood Pressure (e.g., format like "120/80")
  String? _bpValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    final bpPattern = RegExp(r'^\d{2,3}/\d{2,3}$'); // Matches "120/80" format
    if (!bpPattern.hasMatch(value)) {
      return 'Please enter BP in format like "120/80"';
    }
    return null;
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.blueGrey),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: Colors.white,
        ),
        validator: validator, // Attach the validator here
        keyboardType: label == 'Enter value'
            ? TextInputType.text
            : TextInputType.number, // Numeric keyboard for most fields
      ),
    );
  }
}
