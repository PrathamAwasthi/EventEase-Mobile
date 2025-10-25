import 'package:eventease/Provider/AuthButtonState.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Database/App_DB.dart';
import 'HomePage.dart';

class AuthenticationPage extends StatefulWidget {
  const AuthenticationPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return AuthenticationPageState();
  }
}

class AuthenticationPageState extends State<AuthenticationPage> {
  final _loginUsernameController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _regUsernameController = TextEditingController();
  final _regPasswordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _loginUsernameController.dispose();
    _loginPasswordController.dispose();
    _regUsernameController.dispose();
    _regPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);
    final db = DataBase.instance;
    final username = _loginUsernameController.text.trim();
    final password = _loginPasswordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      showSnackBar(context, 'Sabhi fields bharein', isError: true);
      setState(() => _isLoading = false);
      return;
    }

    final user = await db.login(username, password);

    if (user != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('userId', user.id!);
      await prefs.setString('username', user.username);

      if (mounted) {
        showSnackBar(context, 'Login successful!');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    } else {
      if (mounted) {
        showSnackBar(context, 'Invalid username ya password', isError: true);
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _handleRegister(AuthButtonState provider) async {
    setState(() => _isLoading = true);
    final db = DataBase.instance;
    final username = _regUsernameController.text.trim();
    final password = _regPasswordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      showSnackBar(context, 'Sabhi fields bharein', isError: true);
      setState(() => _isLoading = false);
      return;
    }

    final success = await db.register(username, password);

    if (success) {
      if (mounted) {
        showSnackBar(context, 'Registration successful! Ab login karein.');
        _regUsernameController.clear();
        _regPasswordController.clear();
        provider.loginButton();
      }
    } else {
      if (mounted) {
        showSnackBar(context, 'Username pehle se maujood hai', isError: true);
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;
    final provider = Provider.of<AuthButtonState>(context);

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: height * 0.08,
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset("assets/logo_image.png"),
          ),
          title: const Text("EventEase Mobile", style: TextStyle(fontSize: 20)),
          backgroundColor: Colors.white,
          leadingWidth: width * 0.15,
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                height: height * 0.08,
                color: Colors.white,
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.login,
                                color: provider.index == 0
                                    ? Colors.indigo
                                    : Colors.black),
                            Text(
                              "Login",
                              style: TextStyle(
                                  fontSize: 16,
                                  color: provider.index == 0
                                      ? Colors.indigo
                                      : Colors.black),
                            ),
                          ],
                        ),
                        onTap: () {
                          provider.loginButton();
                        },
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_add,
                                color: provider.index == 1
                                    ? Colors.indigo
                                    : Colors.black),
                            Text(
                              "Register",
                              style: TextStyle(
                                  fontSize: 16,
                                  color: provider.index == 1
                                      ? Colors.indigo
                                      : Colors.black),
                            ),
                          ],
                        ),
                        onTap: () {
                          provider.registerButton();
                        },
                      ),
                    )
                  ],
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                ),
              ),
              IndexedStack(
                index: provider.index,
                children: [
                  // --- LOGIN TAB ---
                  _buildLoginTab(context, height, width),
                  // --- REGISTER TAB ---
                  _buildRegisterTab(context, height, width, provider),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginTab(BuildContext context, double height, double width) {
    return Container(
      height: height * 0.76,
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: width * 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: height * 0.12),
          Text(
            "Hello!",
            style: TextStyle(
                fontSize: 24,
                color: Colors.indigo,
                fontWeight: FontWeight.bold),
          ),
          Text(
            "Welcome back",
            style: TextStyle(fontSize: 18, color: Colors.grey[700]),
          ),
          SizedBox(height: height * 0.05),
          TextField(
            controller: _loginUsernameController,
            decoration: const InputDecoration(
              hintText: "Enter Username",
              prefixIcon: Icon(Icons.person),
            ),
          ),
          SizedBox(height: height * 0.02),
          TextField(
            controller: _loginPasswordController,
            obscureText: true,
            decoration: const InputDecoration(
              hintText: "Enter Password",
              prefixIcon: Icon(Icons.lock),
            ),
          ),
          SizedBox(height: height * 0.04),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("LogIn", style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterTab(
      BuildContext context, double height, double width, AuthButtonState provider) {
    return Container(
      height: height * 0.76,
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: width * 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: height * 0.12),
          Text(
            "Create Your",
            style: TextStyle(
                fontSize: 24,
                color: Colors.indigo,
                fontWeight: FontWeight.bold),
          ),
          Text(
            "Account",
            style: TextStyle(fontSize: 18, color: Colors.grey[700]),
          ),
          SizedBox(height: height * 0.05),
          TextField(
            controller: _regUsernameController,
            decoration: const InputDecoration(
              hintText: "Enter Username",
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          SizedBox(height: height * 0.02),
          TextField(
            controller: _regPasswordController,
            obscureText: true,
            decoration: const InputDecoration(
              hintText: "Enter Password",
              prefixIcon: Icon(Icons.lock_outline),
            ),
          ),
          SizedBox(height: height * 0.04),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : () => _handleRegister(provider),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Create Account",
                  style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }
}
