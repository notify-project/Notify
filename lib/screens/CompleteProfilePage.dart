import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:notify/constants/colors.dart';
import 'package:notify/modals/completeProfile.dart';
import 'package:notify/screens/HomePage.dart';
import 'package:notify/services/authService.dart';


class CompleteProfilepage extends StatefulWidget {
  @override
  _CompleteProfilepageState createState() => _CompleteProfilepageState();
}

class _CompleteProfilepageState extends State<CompleteProfilepage> {
  String email = '';
  String name = '';
  String pin = '';
  String uid = FirebaseAuth.instance.currentUser.uid.toString();

  final profileFormKey = new GlobalKey<FormState>();

  createUser(CompleteProfile userProfile) async {
    FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .set(
          {
            'id': uid,
            'pushToken': "token",
            'name': userProfile.name,
            'email': userProfile.email,
            'pin': userProfile.pin,
            'phoneNumber': userProfile.number,
          }
        ).then((value) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => HomePage()));
    });
  }

 DateTime currentBackPressTime;
  Future<bool> onWillPop() {
    DateTime now = DateTime.now();
    if (currentBackPressTime == null || 
        now.difference(currentBackPressTime) > Duration(seconds: 2)) {
      currentBackPressTime = now;
      Fluttertoast.showToast(msg: "Do you really want to exit ?");
      return Future.value(false);
    }
    return Future.value(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login',
        style:TextStyle(
          fontFamily: 'FugazOne',
          color: Colors.white,
        ),),
      ),
      body: WillPopScope(
        onWillPop: onWillPop,
              child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
                    Colors.white,
                    Colors.lightBlueAccent
              ]),
          ),
          child: ListView(
            
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  top: 58.0,
                  left: 20,
                  right: 20,
                ),
                child: Container(
                  margin: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: white,
                      borderRadius: BorderRadius.all(Radius.circular(20))),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      SizedBox(
                        height: 20,
                      ),
                      // Complete profile heading
                      Container(
                        width: double.infinity,
                        child: Text(
                          "Complete Profile",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontFamily: 'FugazOne',
                              fontSize: 25.0,
                              color: Colors.blue,
                              shadows: [
                                new Shadow(
                                  offset: Offset(
                                    1.5,
                                    1.5,
                                  ),
                                  color: grey,
                                  blurRadius: 3,
                                )
                              ]),
                        ),
                      ),
                      SizedBox(
                        height: 20,
                      ),

                      // form fields
                      Form(
                          key: profileFormKey,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // Name
                              Padding(
                                padding: const EdgeInsets.only(
                                    left: 28.0, right: 28, top: 0, bottom: 5),
                                child: TextFormField(
                                  validator: (value) {
                                    if (value.isEmpty) {
                                      return '';
                                    } else {
                                      return null;
                                    }
                                  },
                                  keyboardType: TextInputType.name,
                                  decoration: InputDecoration(
                                    prefixIcon: Icon(Icons.person),
                                    labelText: "Name",

                                    //validator
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      this.name = value;
                                    });
                                  },
                                ),
                              ),

                              // E mail
                              Padding(
                                padding: const EdgeInsets.only(
                                    left: 28.0, right: 28, top: 0, bottom: 5),
                                child: TextFormField(
                                  validator: (value) {
                                    Pattern pattern =
                                        r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
                                    RegExp regex = new RegExp(pattern);
                                    if (!regex.hasMatch(value))
                                      return 'Enter Valid Email';
                                    else
                                      return null;
                                  },
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: InputDecoration(
                                    prefixIcon: Icon(Icons.alternate_email),
                                    labelText: "E-Mail",

                                    //validator
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      this.email = value;
                                    });
                                  },
                                ),
                              ),

                              // PIN 
                              Padding(
                                padding: const EdgeInsets.only(
                                    left: 28.0, right: 28, top: 0, bottom: 5),
                                child: TextFormField(
                                  validator: (value) {
                                    if(value.length == 6){
                                      return null;
                                    }
                                    else {
                                      return 'Enter a 6 digit PIN';
                                    } 
                                  },
                                  maxLength: 6,
                                  keyboardType: TextInputType.name,
                                  decoration: InputDecoration(
                                    prefixIcon: Icon(Icons.security),
                                    labelText: "Secret PIN",

                                    //validator
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      this.pin = value;
                                    });
                                  },
                                ),
                              ),

                             
                             ],
                          )),
                      SizedBox(
                        height: 20,
                      ),

                      //Proceed Button

                      Container(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(
                              right: 15, left: 8, bottom: 25),
                          child: Container(
                            decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(25)),
                                boxShadow: [
                                  new BoxShadow(
                                      color: shadowBlack,
                                      blurRadius: 2,
                                      spreadRadius: 1,
                                      offset: Offset(1, 1))
                                ],
                                gradient: LinearGradient(
                                    colors: [Colors.blue[100], Colors.blue[300], Colors.blue[300], Colors.blue[300]])),
                            child: TextButton(
                              onPressed: () {
                                if (profileFormKey.currentState.validate()) {
                                  createUser(new CompleteProfile(
                                    this.email,
                                    this.name,
                                    this.pin,
                                  ));
                                } else {
                                  Fluttertoast.showToast(
                                      msg: "Enter Valid Info",
                                      toastLength: Toast.LENGTH_SHORT,
                                      gravity: ToastGravity.BOTTOM,
                                      timeInSecForIosWeb: 1,
                                      backgroundColor: Colors.red,
                                      textColor: Colors.white,
                                      fontSize: 16.0);
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(
                                    top: 8.0, bottom: 8, left: 39, right: 39),
                                child: Text(
                                  "Proceed",
                                  style: TextStyle(
                                      color: white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: TextButton(
                    onPressed: Authservice().signOut,
                    child: Text(
                      "Change Number ? Logout",
                      style: TextStyle(color: white),
                    )),
              )
            ],
          ),
        ),
      ),
    );
  }
}
