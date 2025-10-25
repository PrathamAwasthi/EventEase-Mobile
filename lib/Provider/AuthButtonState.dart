import 'package:flutter/material.dart';

class AuthButtonState with ChangeNotifier {
  int index = 0;

  void loginButton() {
    index = 0;
    notifyListeners();
  }

  void registerButton() {
    index = 1;
    notifyListeners();
  }
}
