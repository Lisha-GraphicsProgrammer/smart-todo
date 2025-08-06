import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:todo_lisha/pages/home_page.dart';
import 'package:todo_lisha/pages/login_page.dart';

class AuthServices {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Sign in with Google
  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      if (userCredential.user != null) {
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (context) => HomePage()));
      }
    } catch (e) {
      //
    }
  }

  // Sign out from Google
  Future<void> signOut(BuildContext context) async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      Navigator.of(context).popUntil((route) => route.isFirst);
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => SignInPage()));
    } catch (e) {
      //
    }
  }
}
