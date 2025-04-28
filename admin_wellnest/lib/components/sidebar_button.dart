import 'package:flutter/material.dart';

class SideButton extends StatelessWidget {
  final IconData icon;
  final String label;
  const SideButton({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: EdgeInsets.all(10),
        child: Row(
          children: [
            Icon(icon),
            SizedBox(
              width: 10,
            ),
            Text(label,
                style: TextStyle(
                    color: Color.fromARGB(255, 24, 56, 111), fontSize: 15, letterSpacing: 2)),
          ],
        ));
  }
}
