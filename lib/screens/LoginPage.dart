import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:notify/constants/colors.dart';
import 'package:notify/constants/config.dart';
import 'package:notify/services/authService.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  final _formKey = new GlobalKey<FormState>();
  final mobileFielsController = TextEditingController();
  String phoneNo, verificationId, smsCode;
  int _forceResendingToken;
  bool codeSent = false;
  bool codeReSent = false;

  @override
  void initState() {
    super.initState();
    codeSent = false;
    codeReSent = false;
  }
  // Method for double press to exit
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
         child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    Colors.white,
                    Colors.lightBlueAccent
              ]),),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        (10.0),
                      ),
                    ),
                    child: Container(
                      height: 260,
                      width: 300,
                      padding: EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  otpTextfieldVisibility?"Enter OTP":"Enter Mobile Number",
                                  style: TextStyle(
                              fontFamily: 'FugazOne',
                              fontSize: 15.0,
                              color: Colors.blue,
                              ),),
                              ),
                              // Number Field                    
                              Visibility(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                  left: 28.0, right: 28, top: 0, bottom: 5),
                              child: TextFormField(
                                controller: mobileFielsController,
                                validator: (value) {
                                  Pattern pattern = r'(^(?:[+0]9)?[0-9]{10,12}$)';
                                  RegExp regex = new RegExp(pattern);                     
                                  if (value.isEmpty) {
                                    return "Please Enter your Mobile Number";
                                  } else {
                                    if (value.length != 10) {
                                      return 'Enter Valid Number';
                                    } else if(!regex.hasMatch(value)){
                                      return "Use digits only";
                                    }else{
                                      return null;
                                    }
                                    }
                                  
                                },
                                keyboardType: TextInputType.phone,
                                enableSuggestions: true,
                                autocorrect: true,
                                enableInteractiveSelection: true,
                                decoration: InputDecoration(
                              prefixIcon: Icon(Icons.phone),
                              labelText: "+91  Phone Number",
                                  //validator
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    this.phoneNo = value;
                                  });
                                },
                              ),
                            ),
                            visible: phoneNumberVisibility,
                          ),
                              // otp
                              Visibility(
                            visible: otpTextfieldVisibility,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                  left: 28.0, right: 28, top: 5, bottom: 0),
                              child: TextFormField(
                                validator: (value) {
                                  if (value.length != 6) {
                                    return "Enter valid OTP";
                                  } else {
                                    return null;
                                  }
                                },
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(
                                  prefixIcon: Icon(Icons.phone_iphone_rounded),
                                  hintText: "OTP",
                                  //validator validateandsave method globalkey formstate
                                ),
                                onChanged: (code) {
                                  setState(() {
                                    this.smsCode = code;
                                  });
                                },
                              ),
                            ),
                          ),
                              SizedBox(
                             height: 30,
                            ),
                              Container(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: const EdgeInsets.only(
                                right: 15, left: 8, bottom: 15),
                            child: Container(

                              decoration: BoxDecoration(
                                color: Colors.blueAccent,
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(25)),
                                  ),
                              child: TextButton(
                                onPressed: () {
                                  if (_formKey.currentState.validate()) {
                                    setState(() {
                                      phoneNumberVisibility = false;
                                      otpTextfieldVisibility = true;
                                    });
                                    codeSent
                                        ? Authservice().signInWithOTP(
                                            smsCode, verificationId)
                                        : registerUser(phoneNo);
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                      top: 5.0, bottom: 5, left: 20, right: 20),
                                  child: Text(
                                    otpTextfieldVisibility ? "  Verify  " : "Send OTP",
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
                    ),
                  ),
                  TextButton(
                    onPressed: (){
                      this.phoneNo = "";
                      mobileFielsController.text='';
                      phoneTextFieldVisibilitySetter();
                    },
                  child: Text(otpTextfieldVisibility?'Resend OTP?':"",
                  style: TextStyle(
                    fontSize: 10,
                    fontFamily: 'FugazOne',
                    color: Colors.blue[300],
                  ),),
                  ),
                  SizedBox(height: 20),
                  TextButton(
                    onPressed: (){
                      this.phoneNo = "";
                      mobileFielsController.text='';
                      phoneTextFieldVisibilitySetter();
                      Authservice().signOut();
                    },
                  child: Text(otpTextfieldVisibility?'Change Mobile Number':"",
                  style: TextStyle(
                    fontSize: 10,
                    fontFamily: 'FugazOne',
                    color: Colors.blue[300],
                  ),),
                  ),
                ],
              ),
            ),
          ],
      ),
     ),    
    );
  }

  otpTextFieldVisibilitySetter() {
    setState(() {
      phoneNumberVisibility = false;
      otpTextfieldVisibility = true;
    });
  }
  phoneTextFieldVisibilitySetter() {
    setState(() {
      phoneNumberVisibility = true;
      otpTextfieldVisibility = false;
      codeSent = false;
    });
  }
  codeResent() {
    setState(() {
      codeSent = true;
    });
  }


  Future<void> registerUser(mobile) async {
    final PhoneVerificationCompleted verified = (AuthCredential authResult) {      
      Authservice().signIn(authResult);       
    };
    final PhoneVerificationFailed verificationfailed = (FirebaseAuthException authException) {
      debugPrint('${authException.message}');
    };
    final PhoneCodeSent smsSent = (String verId, [int forceResendingToken]) {
      Fluttertoast.showToast(
          msg: "OTP Sent",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.blue,
          textColor: Colors.white,
          fontSize: 16.0);
      this.verificationId = verId;
      this._forceResendingToken = forceResendingToken;
      setState(() {
        this.codeSent = true;
      });
    };
    final PhoneCodeAutoRetrievalTimeout autoTimeout = (String verId) {
      this.verificationId = verId;
    };
    
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: "+91$mobile",
      timeout: const Duration(seconds: 5),
      forceResendingToken: _forceResendingToken,
      verificationCompleted: verified,
      verificationFailed: verificationfailed,
      codeSent: smsSent,
      codeAutoRetrievalTimeout: autoTimeout,
    );
  }
}