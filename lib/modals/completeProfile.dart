import 'package:firebase_auth/firebase_auth.dart';

String userName = '';

class CompleteProfile {
  String email = '';
  String name = '';
  String pin = '';
  String number = FirebaseAuth.instance.currentUser.phoneNumber;
  CompleteProfile(
    this.email,
    this.name,
    this.pin,
  );
}

List<CompleteProfile> user = [];
