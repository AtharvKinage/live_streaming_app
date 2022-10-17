import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:live_streaming/firebase/auth_service.dart';
import 'package:live_streaming/screens/home_page.dart';
import 'package:live_streaming/models/user.dart' as model;
import 'package:live_streaming/providers/user_provider.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  static const routeName = '/login';
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _authService = AuthService();
  final _userRef = FirebaseFirestore.instance.collection('users');

  void signUp() async {
    await _authService.signInWithGoogle(context);
    // model.User user = model.User(
    //   username: FirebaseAuth.instance.currentUser!.displayName!,
    //   email: FirebaseAuth.instance.currentUser!.email!,
    //   uid: FirebaseAuth.instance.currentUser!.uid!,
    // );
    // await _userRef
    //     .doc(FirebaseAuth.instance.currentUser!.uid!)
    //     .set(user.toMap());
    // Provider.of<UserProvider>(context, listen: false)
    //     .setUser(user);
    // Navigator.pushNamed(context, HomePage.routeName);
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Google Login"),
        backgroundColor: Colors.green,
      ),
      body: Container(
        width: size.width,
        height: size.height,
        padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: size.height * 0.2,
            bottom: size.height * 0.5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Hello, \nGoogle sign in",
                style: TextStyle(fontSize: 30)),
            GestureDetector(
                onTap: signUp,
                child: const Image(
                    width: 100, image: AssetImage('assets/google.png'))),
          ],
        ),
      ),
    );
  }
}
