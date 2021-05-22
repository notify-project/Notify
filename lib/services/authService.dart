import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:notify/constants/config.dart';
import 'package:notify/screens/CompleteProfilePage.dart';
import 'package:notify/screens/HomePage.dart';
import 'package:notify/screens/LoadingScreen.dart';
import 'package:notify/screens/LoginPage.dart';


bool isProfileComplete = true;
String authValue;

class Authservice {
  //Handles Auth
  handleAuth() {
    return StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (BuildContext context, snapshot) {
          if (snapshot.hasData) {
           return handleProfile();
          } else {
            return LoginPage();
          }
        });
  }

  handleProfile() {
    return StreamBuilder(
        stream:
        FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser.uid.toString())
        .get()
        .asStream(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          // print(snapshot.data.exists);          
          if (snapshot.hasError) {
          return CompleteProfilepage();
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Loader();
        }        
        if (snapshot.connectionState == ConnectionState.done) {
            if (!snapshot.data.exists) {
              return CompleteProfilepage();
            } else {
              return HomePage();
            }
          }
          return Loader();
        });
  }

  //Sign out Profile Page
  signOutProfile(BuildContext context) {
    FirebaseAuth.instance.signOut().then((value) {
      // _selectedIndex = 0;
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    });
    otpTextfieldVisibility = false;
    phoneNumberVisibility = true;
  }

  //Sign out
  signOut() {
    FirebaseAuth.instance.signOut();
    otpTextfieldVisibility = false;
    phoneNumberVisibility = true;
  }

  //SignIn
  signIn(AuthCredential authCreds) {
    FirebaseAuth.instance.signInWithCredential(authCreds);
  }

  signInWithOTP(smsCode, verId) {
    AuthCredential authCreds =
        PhoneAuthProvider.credential(verificationId: verId, smsCode: smsCode);
    signIn(authCreds);
  }
}
