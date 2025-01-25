import 'package:flutter/material.dart';

class LoadingSpinner extends StatelessWidget {
  final String message; // Message to display with the spinner

  LoadingSpinner({this.message = 'Loading...'}); // Default message

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircularProgressIndicator(), // The spinner
          SizedBox(height: 20),
          Text(
            message, // Display the message
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
