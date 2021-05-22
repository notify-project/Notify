import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:notify/constants/config.dart';
import 'package:notify/widgets/mapuserbadge.dart';

const double CAMERA_ZOOM = 16;
const double CAMERA_TILT = 80;
const double CAMERA_BEARING = 30;
const LatLng SOURCE_LOCATION = LatLng(42.7477863, -71.1699932);
const LatLng DEST_LOCATION = LatLng(42.743902, -71.170009);
// rest
const double PIN_VISIBLE_POSITION = 20;
const double PIN_INVISIBLE_POSITION = -220;
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
// const fetchBackground = "fetchBackground";
// void callbackDispatcher() {
//   Workmanager.executeTask((task, inputData) async {
//     switch (task) {
//       case fetchBackground:
//         callback();
//         // _determinePosition();
//         break;
//     }
//     return Future.value(true);
//   });
// }
// void callback(){

// print("\n===\nWork manager working\n===\n");
// callback();
// }

class location extends StatefulWidget {
  @override
  _locationState createState() => _locationState();
}

class _locationState extends State<location> {
  final _pinKey = new GlobalKey<FormFieldState>();
  var location;
  LatLng locationObject;
  bool sending = true;
  bool sendingLoc = false;
  bool locationSet = false;
  bool close = false;
  String timeStamp = DateTime.now().millisecondsSinceEpoch.toString();
  DateTime currentBackPressTime;
  int _counter;

  // Google Maps Setup
  Completer<GoogleMapController> _controller = Completer();
  Set<Marker> _markers = Set<Marker>();
  // for my drawn routes on the map
  List<LatLng> polylineCoordinates = [];
  String googleAPIKey = "AIzaSyCmF8S7KzEHONdCuBJcbELIbaz3E5GjrCY";
  BitmapDescriptor sourceIcon;
  // BitmapDescriptor destinationIcon;
  LatLng currentLocation;
  LatLng destinationLocation;
  double pinPillPosition = PIN_VISIBLE_POSITION;
  bool userBadgeSelected = false;
  CameraPosition initialCameraPosition;

  void setSourceAndDestinationMarkerIcons(BuildContext context) async {
    print("Setting");
    sourceIcon = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(devicePixelRatio: 2.0), 'assets/images/source_pin_android.png');

    // destinationIcon = await BitmapDescriptor.fromAssetImage(
    //   ImageConfiguration(devicePixelRatio: 2.0),
    //   'assets/images/destination_pin_android.png'
    // );
  }

  Future<void> setInitialLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permantly denied, we cannot request permissions.');
    }

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse && permission != LocationPermission.always) {
        return Future.error('Location permissions are denied (actual value: $permission).');
      }
    }
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

    destinationLocation = LatLng(DEST_LOCATION.latitude, DEST_LOCATION.longitude);
    setState(() {
      currentLocation = LatLng(SOURCE_LOCATION.latitude, SOURCE_LOCATION.longitude);

      initialCameraPosition = CameraPosition(
          zoom: CAMERA_ZOOM,
          tilt: CAMERA_TILT,
          bearing: CAMERA_BEARING,
          target: LatLng(position.latitude, position.longitude));
      locationSet = true;
    });
    return null;
  }

  void showPinsOnMap() {
    setState(() {
      _markers.add(Marker(
          markerId: MarkerId('sourcePin'),
          position: currentLocation,
          icon: sourceIcon,
          onTap: () {
            setState(() {
              this.userBadgeSelected = true;
            });
          }));

      // _markers.add(Marker(
      //   markerId: MarkerId('destinationPin'),
      //   position: destinationLocation,
      //   icon: destinationIcon,
      //   onTap: () {
      //     setState(() {
      //       this.pinPillPosition = PIN_VISIBLE_POSITION;
      //     });
      //   }
      // ));
    });
  }
  // end
  //
  // // background process

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permantly denied, we cannot request permissions.');
    }

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse && permission != LocationPermission.always) {
        return Future.error('Location permissions are denied (actual value: $permission).');
      }
    }

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

    setState(
      () {
        location = position;
        currentLocation = LatLng(position.latitude, position.latitude);
        sendingLoc = true;
      },
    );
    String uid = FirebaseAuth.instance.currentUser.uid.toString();
    // print(uid);
    String transactionid = uid + timeStamp;
    // print(transactionid);
    DocumentReference documentReference =
        FirebaseFirestore.instance.collection('journeys').doc(transactionid);

    FirebaseFirestore.instance.runTransaction((transaction) async {
      transaction.set(
        documentReference,
        {
          'idFrom': uid,
          "latitude": position.latitude.toString(),
          "longitude": position.longitude.toString(),
          'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
          'stopped': false,
          'idsTo': idsTo,
          'nickname': userName,
          'transactionid': transactionid,
        },
      );
    });
    CameraPosition cPosition = CameraPosition(
      zoom: CAMERA_ZOOM,
      tilt: CAMERA_TILT,
      bearing: CAMERA_BEARING,
      target: LatLng(position.latitude, position.longitude),
    );
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(cPosition));
    setState(() {
      _markers.clear();
      _markers.add(Marker(
        markerId: MarkerId('sourcePin'),
        position: LatLng(position.latitude, position.longitude),
        icon: sourceIcon,
      ));
    });
    await Future.delayed(Duration(seconds: 5));
    if (sending) {
      _determinePosition();
    } else {
      FirebaseFirestore.instance.runTransaction((transaction) async {
        transaction.set(
          documentReference,
          {
            'stopped': true,
          },
        );
      });
      return null;
    }
    return null;
  }

  Future<void> _showCircularIndicator() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          actionsPadding: EdgeInsets.zero,
          content: SingleChildScrollView(
            child: Center(
              child: CircularProgressIndicator(
                backgroundColor: Colors.red[300],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> sendEmergencyAlert() async {
    Fluttertoast.showToast(msg: "Sending Alert");
    _showCircularIndicator();

    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permantly denied, we cannot request permissions.');
    }

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse && permission != LocationPermission.always) {
        return Future.error('Location permissions are denied (actual value: $permission).');
      }
    }

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    String uid = FirebaseAuth.instance.currentUser.uid.toString();
    String transactionid = uid + timeStamp;
    // print(transactionid);
    DocumentReference documentReference =
        FirebaseFirestore.instance.collection('emergency').doc(transactionid);

    FirebaseFirestore.instance.runTransaction((transaction) async {
      transaction.set(
        documentReference,
        {
          'idFrom': uid,
          "latitude": position.latitude.toString(),
          "longitude": position.longitude.toString(),
          'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
          'idsTo': idsTo,
          'nickname': userName,
          'transactionid': transactionid,
        },
      );
    });
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
    Fluttertoast.showToast(msg: "Alert Sent");
  }

  @override
  void initState() {
    super.initState();
    // Workmanager.initialize(
    //      callbackDispatcher,
    //      isInDebugMode: true,
    //   );
    setInitialLocation();
    getBytesFromAsset('assets/images/source_pin_android.png', 64).then((onValue) {
      sourceIcon = BitmapDescriptor.fromBytes(onValue);
    });
    _counter = 0;
  }

  Future<void> _showNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'your channel id', 'your channel name', 'your channel description',
        priority: Priority.high,
        autoCancel: true,
        onlyAlertOnce: true,
        ongoing: true,
        color: Color(0xff006ec7),
        icon: '@mipmap/launcher_icon',
        playSound: true,
        fullScreenIntent: true,
        visibility: NotificationVisibility.public,
        ticker: 'ticker');
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
        0, 'Notify is Running', 'Do not close the app or your GPS', platformChannelSpecifics,
        payload: 'item x');
  }

  @override
  void dispose() {
    super.dispose();
    _controller = Completer();
    flutterLocalNotificationsPlugin.cancelAll();
  }

  static Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png)).buffer.asUint8List();
  }

  Widget _buildStartDialog(
    BuildContext context,
  ) {
    return AlertDialog(
      content: Wrap(children: [
        Text("Start Tracking ? "),
        Text("Press Yes to confirm."),
      ]),
      actions: <Widget>[
        FlatButton(
          child: const Text('Yes'),
          onPressed: () {
            _determinePosition();
            _showNotification();
            Navigator.pop(context);
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

  Widget _buildStopDialog(
    BuildContext context,
  ) {
    return AlertDialog(
      content: Wrap(children: [
        Text("Stop Tracking ? "),
        Text("Press Yes to confirm."),
        TextFormField(
          key: _pinKey,
          validator: (value) {
            if (value == userPin) {
              return null;
            } else {
              if (_counter < 3) {
                _counter = _counter + 1;
                return 'Wrong PIN(${3 - _counter}/3 attempts remainig)';
              } else {
                sendEmergencyAlert();
                return 'Wrong PIN. Alert is sent to your contacts';
              }
            }
          },
          keyboardType: TextInputType.name,
          maxLength: 6,
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.person),
            labelText: "Secret PIN ",

            //validator
          ),
          onChanged: (value) {},
        )
      ]),
      actions: <Widget>[
        FlatButton(
          child: const Text('Yes'),
          onPressed: () {
            if (_pinKey.currentState.validate()) {
              setState(() {
                sending = false;
                sendingLoc = false;
                close = true;
              });
              flutterLocalNotificationsPlugin.cancelAll();
              Fluttertoast.showToast(msg: "Journey Stopped");
              Navigator.pop(context, true);
            }
          },
        ),
        FlatButton(
          child: const Text('No'),
          onPressed: () {
            Navigator.pop(context, false);
          },
        ),
      ],
    );
  }

  Widget _buildDialog(
    BuildContext context,
  ) {
    return AlertDialog(
      content: Wrap(children: [
        Text("Press STOP to stop this journey and exit"),
        Text("Press Cancel to stay"),
      ]),
      actions: <Widget>[
        FlatButton(
          child: const Text('STOP'),
          onPressed: () {
            setState(() {
              sending = false;
              sendingLoc = false;
              close = true;
            });
            Navigator.pop(context, true);
          },
        ),
        FlatButton(
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.pop(context, false);
          },
        ),
      ],
    );
  }

  Future<bool> onWillPop() {
    if (sendingLoc) {
      showDialog<bool>(
        context: context,
        builder: (_) => _buildStopDialog(context),
      ).then((bool value) async {
        print(value);
        _showCircularIndicator();
        await Future.delayed(Duration(seconds: 2));
        Navigator.pop(context);
        close = value;
        return Future.value(close);
      });
      return Future.value(close);
    } else {
      return Future.value(true);
    }
  }

  Widget build(BuildContext context) {
    // gmap setup
    // set up the marker icons
    // this.setSourceAndDestinationMarkerIcons(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Location',
          style: TextStyle(
            fontSize: 20,
            fontFamily: 'FugazOne',
            color: Colors.white,
          ),
        ),

        automaticallyImplyLeading: false,
        //`true` if you want Flutter to automatically add Back Button when needed,
        //or `false` if you want to force your own back button every where
        leading: IconButton(
          color: Colors.white,
          icon: Icon(Icons.location_history),
          onPressed: () => null,
        ),
      ),
      body: WillPopScope(
        onWillPop: onWillPop,
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 10),
              sendingLoc
                  ? TextButton(
                      onPressed: () {
                        showDialog<bool>(
                          context: context,
                          builder: (_) => _buildStopDialog(context),
                        );
                      },
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(Colors.red),
                        elevation: MaterialStateProperty.all(1.4),
                        shadowColor: MaterialStateProperty.all(Colors.grey),
                        shape: MaterialStateProperty.all(RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(14)))),
                      ),
                      child: Text(
                        '  Stop  ',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    )
                  : TextButton(
                      onPressed: () {
                        showDialog<bool>(
                          context: context,
                          builder: (_) => _buildStartDialog(context),
                        );

                        // Workmanager.registerPeriodicTask(
                        //          "1",
                        //             fetchBackground,
                        //         frequency: Duration(minutes: 15),
                        //            );
                      },
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(Colors.green),
                        elevation: MaterialStateProperty.all(1.4),
                        shadowColor: MaterialStateProperty.all(Colors.grey),
                        shape: MaterialStateProperty.all(RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(14)))),
                      ),
                      child: Text('  Start  ',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
              SizedBox(height: 10),
              Stack(
                children: [
                  locationSet
                      ? SizedBox(
                          height: 500,
                          child: GoogleMap(
                            myLocationEnabled: true,
                            compassEnabled: false,
                            tiltGesturesEnabled: false,
                            markers: _markers,
                            mapType: MapType.normal,
                            initialCameraPosition: initialCameraPosition,
                            buildingsEnabled: true,
                            mapToolbarEnabled: true,
                            onTap: (LatLng loc) {
                              setState(() {
                                // this.pinPillPosition = PIN_INVISIBLE_POSITION;
                                // this.userBadgeSelected = false;
                              });
                            },
                            onMapCreated: (GoogleMapController controller) {
                              _controller.complete(controller);
                              showPinsOnMap();
                            },
                          ),
                        )
                      : Container(),
                  //       // gmap setup
                  Positioned(
                    top: 20,
                    left: 0,
                    right: 0,
                    child: MapUserBadge(
                      isSelected: this.userBadgeSelected,
                    ),
                  ),
                  // AnimatedPositioned(
                  //   duration: const Duration(milliseconds: 500),
                  //   curve: Curves.easeInOut,
                  //   left: 0,
                  //   right: 0,
                  //   bottom: this.pinPillPosition,
                  //   child: MapBottomPill()
                  // ),
                ],
              ),
              SizedBox(height: 10),
              Text("   Press this button to send direct notification to your contacts.",
                  style: TextStyle(
                    color: Colors.red[300],
                  )),
              TextButton(
                onPressed: () {
                  sendEmergencyAlert();
                },
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(Colors.red),
                  elevation: MaterialStateProperty.all(1.6),
                  shadowColor: MaterialStateProperty.all(Colors.red[100]),
                  shape: MaterialStateProperty.all(
                      RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(14)))),
                ),
                child: Text('  Emergency  ',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
