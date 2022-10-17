import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:live_streaming/screens/home_page.dart';
import 'package:live_streaming/screens/login_page.dart';
import 'package:live_streaming/models/user.dart' as model;
import 'package:live_streaming/providers/user_provider.dart';
import 'package:provider/provider.dart';

class AuthService {
  final _userRef = FirebaseFirestore.instance.collection('users');
//Determine if the user is authenticated.
  handleAuthState() {
    return StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (BuildContext context, snapshot) {
          if (snapshot.hasData) {
            return HomePage();
          } else {
            return const LoginPage();
          }
        });
  }

  Future<Map<String, dynamic>?> getCurrentUser(String? uid) async {
    if (uid != null) {
      final snap = await _userRef.doc(uid).get();
      return snap.data();
    }
    return null;
  }

  signInWithGoogle(BuildContext context) async {
    // Trigger the authentication flow
    final GoogleSignInAccount? googleUser =
        await GoogleSignIn(scopes: <String>["email"]).signIn();

    // Obtain the auth details from the request
    final GoogleSignInAuthentication googleAuth =
        await googleUser!.authentication;

    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    UserCredential cred =
        await FirebaseAuth.instance.signInWithCredential(credential);
    if (cred.user != null) {
      model.User user = model.User(
        username: FirebaseAuth.instance.currentUser!.displayName!,
        email: FirebaseAuth.instance.currentUser!.email!,
        uid: FirebaseAuth.instance.currentUser!.uid,
      );
      await _userRef
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .set(user.toMap());

      // Provider.of<UserProvider>(context, listen: false).setUser(
      //   model.User.fromMap(
      //     await getCurrentUser(cred.user!.uid) ?? {},
      //   ),
      // );
    }

    // Once signed in, return the UserCredential
    return await FirebaseAuth.instance.signInWithCredential(credential);
  }

  //Sign out
  signOut() {
    FirebaseAuth.instance.signOut();
  }
}
