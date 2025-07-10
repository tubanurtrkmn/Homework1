import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:garbagedetector/home_page.dart';
import 'package:garbagedetector/login_page.dart';

class AuthService {
  final userCollection = FirebaseFirestore.instance.collection("users");
  final firebaseAuth = FirebaseAuth.instance;

  Future<void> signUp(BuildContext context, {required String name, required String mail, required String password}) async {
    final navigator = Navigator.of(context);
    try {
      final UserCredential userCredential = await firebaseAuth.createUserWithEmailAndPassword( email: mail, password: password);
      if (userCredential.user != null )  {
        await _registerUser(name: name, mail: mail, password: password);
        Fluttertoast.showToast(msg: 'Kayıt başarılı! Giriş yapabilirsiniz.', toastLength: Toast.LENGTH_LONG);
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      Fluttertoast.showToast(msg: e.message!, toastLength: Toast.LENGTH_LONG);
    }
  }

  Future<void> signIn(BuildContext context, {required String mail, required String password}) async {
    final navigator = Navigator.of(context);
    try {
      final UserCredential userCredential = await firebaseAuth.signInWithEmailAndPassword( email: mail, password: password);
      if (userCredential.user != null) {
        navigator.pushReplacement(MaterialPageRoute(builder: (context) => HomePage(),));
      }
    } on FirebaseAuthException catch(e) {
      Fluttertoast.showToast(msg: e.message!, toastLength: Toast.LENGTH_LONG);
    }
  }

  Future<void> _registerUser({required String name, required String mail, required String password}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await userCollection.doc(user.uid).set({
        "mail" : mail,
        "name": name,
        "completedTasks": [],
        "totalPoints": 0,
        "users": user.uid
      });
    }
  }

  Future<void> signOut(BuildContext context) async {
    await firebaseAuth.signOut();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }
}