import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:notify/constants/config.dart';
import 'package:notify/modals/FCm_Item.dart';
import 'package:notify/screens/Alerts.dart';
import 'package:notify/screens/Contacts.dart';
import 'package:notify/screens/location.dart';
import 'package:notify/services/authService.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:wakelock/wakelock.dart';

final Map<String, Item> _items = <String, Item>{};
Item _itemForMessage(Map<String, dynamic> message) {
  final dynamic data = message['notification'] ?? message;
  final String itemId = data['title'];
  final String itemBody = data['body'];
  final Item item = _items.putIfAbsent(
      itemId, () => Item(itemId: itemId, itemBody: itemBody))
    ..status = data['status'];
  return item;
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _pinChangeKey = new GlobalKey<FormFieldState>();
  final _newPinKey = new GlobalKey<FormFieldState>();
  DateTime currentBackPressTime;
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  FlutterLocalNotificationsPlugin fltNotification;
  bool _isEditingText = false;
  TextEditingController _editingController;
  String initialText = "Username";
  String newPin = "";

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
   void _showItemDialog(Map<String, dynamic> message) {
    showDialog<bool>(
      context: context,
      builder: (_) => _buildDialog(context, _itemForMessage(message)),
    ).then((bool shouldNavigate) {
      if (shouldNavigate == true) {
        _navigateToItemDetail(message);
      }
    });
  }
  void _navigateToItemDetail(Map<String, dynamic> message) {
    final Item item = _itemForMessage(message);
    // Clear away dialogs
    Navigator.popUntil(context, (Route<dynamic> route) => route is PageRoute);
    if (!item.route.isCurrent) {
      Navigator.push(context, item.route);
    }
  }

  Widget _buildDialog(BuildContext context, Item item) {
    return AlertDialog(
      content: Wrap(children: [
        Text("You just recieved an Alert message"),
        Text("Check Alerts Page"),
        // Text(item.itemBody.toString()??"Fast")
      ]),
      actions: <Widget>[
        FlatButton(
          child: const Text('CLOSE'),
          onPressed: () {
            Navigator.pop(context, false);
          },
        ),
      ],
    );
  }


  @override
  void initState() {
    super.initState();
    notitficationPermission();
    initMessaging();
    getUserDetails();
    Wakelock.enable();
  }

  void getUserDetails() async {
    FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser.uid.toString())
        .get().then((value) {         
          
          setState(() {
                      userName = value.data()['name'];
                      userPin = value.data()['pin'];
                      initialText = value.data()['name']??"Username";
                      _editingController = TextEditingController(text: initialText);
                    });
          List sentRequests = value.data()['sentRequests'];
          idsTo.clear();
          sentRequests.forEach((element) { 
          if(element['accepted']=="true"){
            idsTo.add(element["uid"]);
          }
          });
          // print(idsTo);
          
        });
          userPhoneNumber = FirebaseAuth.instance.currentUser.phoneNumber.toString();
  }

  void getToken() async {
    var token = await messaging.getToken();
    FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser.uid.toString())
        .update({'pushToken': token});
  }

  void initMessaging() {
    var androiInit = AndroidInitializationSettings('@mipmap/launcher_icon');

    var iosInit = IOSInitializationSettings(defaultPresentBadge: true,);

    var initSetting = InitializationSettings(android:androiInit,iOS:iosInit);

    fltNotification = FlutterLocalNotificationsPlugin();

    fltNotification.initialize(initSetting);
    
  
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      showNotification();
      _showItemDialog(message.data);
    });
    getToken();
  }

  void showNotification() async {
    var androidDetails =
        AndroidNotificationDetails(
          '1', 'channelName',
           'channel Description',
            playSound: true, 
            fullScreenIntent: true, 
            icon: '@mipmap/launcher_icon',
            ticker: 'ticker',

            );

    var iosDetails = IOSNotificationDetails();

    var generalNotificationDetails =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    await fltNotification.show(
      0, 'Notify',
       'Alert',
        generalNotificationDetails,
        payload: 'notification');
  }

  void notitficationPermission() async {
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      carPlay: false,
      criticalAlert: true,
      provisional: false,
      sound: true,      
    );
    print('User granted permission: ${settings.authorizationStatus}');
  }
  Widget _buildDeleteDialog(BuildContext context, ) {
    return AlertDialog(
      content: Wrap(children: [
        Text("Are you sure you want to delete your account?"),
        Text("Press Yes to confirm."),
      ]),
      actions: <Widget>[
        TextButton(
          style: ButtonStyle(
                                backgroundColor: MaterialStateProperty.all(Colors.red[300]),
                                elevation: MaterialStateProperty.all(1.4),
                                shadowColor: MaterialStateProperty.all(Colors.grey),
                                // shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(14)))),
                              ),
          child: const Text('Yes',style: TextStyle(color: Colors.white),),
          onPressed: () async {
            await  FirebaseFirestore.instance.collection('alerts').
            doc(FirebaseAuth.instance.currentUser.uid.toString()).delete();
            await FirebaseFirestore.instance.collection('users').
            doc(FirebaseAuth.instance.currentUser.uid.toString()).delete().then(
              (value) {
                Authservice().signOut();
            Navigator.pop(context);}
              );

          },
        ),
        FlatButton(
          child: const Text('No'),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ],
      
    );
  }

  Widget _buildChangePinDialog(BuildContext context, ) {
    return AlertDialog(
      content: Wrap(children: [
        Text("Change Secret PIN."),
        TextFormField(
          key: _pinChangeKey,
          validator: (value) {
                                    if(value == userPin){
                                      return null;
                                    }
                                    else {
                                      return 'Wrong PIN';
                                    } 
                                  },
                                  keyboardType: TextInputType.name,
                                  maxLength: 6,
                                  decoration: InputDecoration(
                                    prefixIcon: Icon(Icons.history_sharp),
                                    labelText: "Old Secret PIN ",

                                    //validator
                                  ),
                                  onChanged: (value) {
                                    
                                  },
        ),
        TextFormField(
          key: _newPinKey,
          validator: (value) {
                                    if(value.length == 6){
                                      return null;
                                    }
                                    else {
                                      return 'Enter a 6 digit PIN';
                                    } 
                                  },
                                  keyboardType: TextInputType.name,
                                  maxLength: 6,
                                  decoration: InputDecoration(
                                    prefixIcon: Icon(Icons.security),
                                    labelText: "New Secret PIN ",

                                    //validator
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      this.newPin = value;
                                    });
                                  },
        )
      ]),
      actions: <Widget>[
        TextButton(
          style: ButtonStyle(
                                backgroundColor: MaterialStateProperty.all(Colors.red[300]),
                                elevation: MaterialStateProperty.all(1.4),
                                shadowColor: MaterialStateProperty.all(Colors.grey),
                                // shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(14)))),
                              ),
          child: const Text('Yes',style: TextStyle(color: Colors.white),),
          onPressed: () async {
            if(_pinChangeKey.currentState.validate()){
              if(_newPinKey.currentState.validate()){
                await FirebaseFirestore.instance.collection('users').
            doc(FirebaseAuth.instance.currentUser.uid.toString())
            .update({
              'pin':this.newPin
            })
            .then(
              (value) {
                setState(() {
                        userPin = this.newPin;
                     });
                Fluttertoast.showToast(msg: "PIN changed");            
            Navigator.pop(context);}
              );

              }
            }
            
            

          },
        ),
        FlatButton(
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ],
      
    );
  }

    Color getColor(Set<MaterialState> states) {
      const Set<MaterialState> interactiveStates = <MaterialState>{
        MaterialState.pressed,
        MaterialState.hovered,
        MaterialState.focused,
      };
      if (states.any(interactiveStates.contains)) {
        return Colors.green[300];
      }
      return Colors.green[100];
    }    
    Color getColor2(Set<MaterialState> states) {
      const Set<MaterialState> interactiveStates = <MaterialState>{
        MaterialState.pressed,
        MaterialState.hovered,
        MaterialState.focused,
      };
      if (states.any(interactiveStates.contains)) {
        return Colors.yellow[300];
      }
      return Colors.yellow[100];
    }
    Color getColor3(Set<MaterialState> states) {
      const Set<MaterialState> interactiveStates = <MaterialState>{
        MaterialState.pressed,
        MaterialState.hovered,
        MaterialState.focused,
      };
      if (states.any(interactiveStates.contains)) {
        return Colors.deepOrange[300];
      }
      return Colors.deepOrange[100];
    }
    Color getColor4(Set<MaterialState> states) {
      const Set<MaterialState> interactiveStates = <MaterialState>{
        MaterialState.pressed,
        MaterialState.hovered,
        MaterialState.focused,
      };
      if (states.any(interactiveStates.contains)) {
        return Colors.red[300];
      }
      return Colors.red[100];
    }

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.lightBlueAccent,
          title: Center(child:
          Text('Home      ',style: TextStyle(
            fontFamily: 'FugazOne',
            fontSize: 30,
          ),),),
        ),
        drawer: Drawer(
          child: ListView(
            children: <Widget>[
              // SizedBox(height: 20,),
              ListTile(
                title: _editTitleTextField(),
                // title: Text(userName??"Username"),
                leading: Icon(
                  Icons.account_circle,
                  color: Colors.blue,
                ),
                subtitle: Text(userPhoneNumber??"Number"),
                tileColor: Colors.blue[100],
                trailing: IconButton(
                  icon: Icon(Icons.edit,
                  color: Colors.grey,),
                   onPressed: () {
                     setState(() {_isEditingText = true;});
                   } 
                   ),
              ),
              InkWell(
                onTap: () {
                 // Add an about Page
                 showDialog<bool>(
      context: context,
      builder: (_) => _buildDeleteDialog(context ),
    );
                },
                child: ListTile(
                  title: Text('Delete Account'),
                  leading: Icon(
                    Icons.delete,
                    color: Colors.red[300],
                  ),
                ),
              ),
              InkWell(
                onTap: () {
                 showDialog<bool>(
      context: context,
      builder: (_) => _buildChangePinDialog(context ), // change
    );
                },
                child: ListTile(
                  title: Text('Change Secret PIN'),
                  leading: Icon(
                    Icons.security,
                    color: Colors.blue,
                  ),
                ),
              ),
              InkWell(
                onTap: () {
                  Authservice().signOut();
                },
                child: ListTile(
                  title: Text('Logout'),
                  leading: Icon(
                    Icons.phonelink_erase,
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.white,
        body: WillPopScope(
          onWillPop: onWillPop,
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: MediaQuery.of(context).size.width * 1,
                  height: MediaQuery.of(context).size.height * .25,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.white,
                        child: Image(
                          image: AssetImage('assets/images/icon.png'),
                        ),
                        radius: 55,
                      ),
                      Text(
                        'Notify',
                        style: TextStyle(
                          fontFamily: 'FugazOne',
                          fontSize: 45.0,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    width: MediaQuery.of(context).size.width * 1,
                    height: MediaQuery.of(context).size.height * .38,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Container(
                            margin :new EdgeInsets.symmetric(vertical:8),
                            padding: new EdgeInsets.symmetric(vertical: 4),
                            width: MediaQuery.of(context).size.width * .6,
                            child: TextButton(
                              style: ButtonStyle(
                                backgroundColor: MaterialStateProperty.resolveWith(getColor),
                                elevation: MaterialStateProperty.all(1.4),
                                shadowColor: MaterialStateProperty.all(Colors.grey),
                                // shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(14)))),
                              ),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (context)=> location())
                                );
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.location_on_sharp,
                                    color: Colors.blue,
                                    size: 30,
                                  ),
                                  SizedBox(
                                    width: 10,
                                  ),
                                  Text(
                                    'Track',
                                    style: TextStyle(
                                      fontFamily: 'FugazOne',
                                      color: Colors.blue,
                                      fontSize: 30,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child:Container(
                            margin :new EdgeInsets.symmetric(vertical: 8),
                            padding: new EdgeInsets.symmetric(vertical: 4),
                          width: MediaQuery.of(context).size.width * .6,
                          child: TextButton(
                              style: ButtonStyle(
                                backgroundColor: MaterialStateProperty.resolveWith(getColor2),
                                elevation: MaterialStateProperty.all(1.4),
                                shadowColor: MaterialStateProperty.all(Colors.grey),
                                // shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(14))))

                              ),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => contacts(),
                                ),
                              );
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.contacts,
                                  color: Colors.blue,
                                  size: 30,
                                ),
                                SizedBox(
                                  width: 10,
                                ),
                                Text(
                                  'Contacts',
                                  style: TextStyle(
                                    fontFamily: 'FugazOne',
                                    color: Colors.blue,
                                    fontSize: 30,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        ),
                        Expanded(
                          child: Container(
                            margin :new EdgeInsets.symmetric(vertical: 8),
                            padding: new EdgeInsets.symmetric(vertical: 4),
                            width: MediaQuery.of(context).size.width * .6,
                            //margin: EdgeInsets.symmetric(horizontal: 90),
                            child: TextButton(
                              style: ButtonStyle(
                                backgroundColor: MaterialStateProperty.resolveWith(getColor3),
                                elevation: MaterialStateProperty.all(1.4),
                                shadowColor: MaterialStateProperty.all(Colors.grey),
                                // shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(14))))

                              ),
                              onPressed: () {
                                Navigator.of(context).push(MaterialPageRoute(
                                  builder: (context) => alerts(),
                                ));
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.warning,
                                    color: Colors.blue,
                                    size: 30,
                                  ),
                                  SizedBox(
                                    width: 10,
                                  ),
                                  Text(
                                    'Alerts',
                                    style: TextStyle(
                                      fontFamily: 'FugazOne',
                                      color: Colors.blue,
                                      fontSize: 30,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            margin :new EdgeInsets.symmetric(vertical:8),
                            padding: new EdgeInsets.symmetric(vertical: 4),
                            width: MediaQuery.of(context).size.width * .6,
                            //margin: EdgeInsets.symmetric(horizontal: 90),
                            child: TextButton(
                              style: ButtonStyle(
                                backgroundColor: MaterialStateProperty.resolveWith(getColor4),
                                elevation: MaterialStateProperty.all(1.4),
                                shadowColor: MaterialStateProperty.all(Colors.grey),
                                // shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(14))))

                              ),
                              onPressed: () {
                                exit(0);
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.exit_to_app,
                                    color: Colors.blue,
                                    size: 30,
                                  ),
                                  SizedBox(
                                    width: 10,
                                  ),
                                  Text(
                                    'Exit',
                                    style: TextStyle(
                                      fontFamily: 'FugazOne',
                                      color: Colors.blue,
                                      fontSize: 30,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 20,)
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  Widget _editTitleTextField() {
  if (_isEditingText)
    return Center(
      child: TextField(
      
        onSubmitted: (newValue){
          FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser.uid.toString())
        .update({'name': newValue});
          setState(() {
            initialText = newValue;
            _isEditingText =false;
          });
        },
        autofocus: true,
        controller: _editingController,
      ),
    );
  return InkWell(
    onTap: () {
      setState(() {
        _isEditingText = true;
      });
    },
    child: Text(
  initialText,
  style: TextStyle(
    color: Colors.black,
    fontSize: 18.0,
  ),
    )
 );
}
}
