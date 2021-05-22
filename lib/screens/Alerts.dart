import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;

import 'package:url_launcher/url_launcher.dart';

// ignore: camel_case_types
class alerts extends StatefulWidget {
  @override
  _alertsState createState() => _alertsState();
}

// ignore: camel_case_types
class _alertsState extends State<alerts> {
  // Color(0xffFF5B95), Color(0xffF8556D) == red gradient
  // Color(0xff6DC8F3), Color(0xff73A1F9) == blue gradient
  Color startColor = Color(0xff6DC8F3);
  Color endColor = Color(0xff73A1F9);
  final double _borderRadius = 24;
  String uid;
  CollectionReference alerts;
  Map<String, dynamic> alertsList ;
  List builderList ;

  @override
  void initState(){
    super.initState();
     uid = FirebaseAuth.instance.currentUser.uid.toString();
     alerts = FirebaseFirestore.instance.collection('alerts');
  }
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Alerts',
          style:TextStyle(
            fontSize: 20,
            fontFamily: 'FugazOne',
            color: Colors.white,
          ),
        ),
        automaticallyImplyLeading: true,
        //`true` if you want Flutter to automatically add Back Button when needed,
        //or `false` if you want to force your own back button every where
        leading: IconButton(
          color: Colors.white,
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
      future: alerts
      .doc(uid)
      .get(),
      builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {   
         
        switch (snapshot.connectionState) {
                case ConnectionState.waiting:
                  // return Center(child: Text('Loading !'));
                case ConnectionState.active:
                  return Center(child: Text('\nPlease Wait !'));
                case ConnectionState.done: 
                if(snapshot.data.data()!=null){
                  return buildAlertsList(
                    snapshot.data.data()['alerts'], 
                  _borderRadius,  startColor,  endColor);
                }
                return Center(child: Text('No alert on Notify yet ._.'));
                case ConnectionState.none:
                  return Center(child: Text('No alert on Notify yet ._.'));
                default:
                  return Text('Click on refresh to load ._.');
              } 
        // print(snapshot.data.data()['alerts'][0]['payload']);
         
        // return buildAlertsList(alertsData: alertsData, borderRadius: _borderRadius, startColor: startColor, endColor: endColor);
      },
    )
    );
  }
  launchMap(String lat , String long ) async{
                              // var mapSchema = 'geo:$lat,$long?q=Last Location'; 
                              var mapSchema = 'google.navigation:q=$lat,$long&mode=d';
                                if (await canLaunch(mapSchema)) {
                                 await launch(mapSchema);
                            } else {
                         throw 'Could not launch $mapSchema';
                       }
                  }
  Widget buildAlertsList( 
                    List paramalertsData,
                    double _borderRadius,
                    Color startColor,
                    Color endColor) {
                      List alertsData = paramalertsData??[];
                      print(paramalertsData);
    return ListView.builder(
      itemCount:alertsData.length,      
      itemBuilder: (BuildContext context,int index){
        return Center(
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: InkWell(
                onLongPress: (){
                      launchMap(alertsData[index]['latitude'], alertsData[index]['longitude']);
                    },
                child: Stack(
                  children: <Widget>[
                    Container(
                      height: 150,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(_borderRadius),
                        gradient: LinearGradient(colors: [
                          startColor, endColor
                        ], begin: Alignment.topLeft, end: Alignment.bottomRight),
                        boxShadow: [
                          BoxShadow(
                            color: endColor,
                            blurRadius: 3,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      top: 0,
                      child: CustomPaint(
                        size: Size(100, 150),
                        painter: CustomCardShapePainter(_borderRadius,
                           startColor, endColor),
                      ),
                    ),
                    Positioned.fill(
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Image.asset(
                              'assets/images/icon.png',                                
                              height: 64,
                              width: 64,                                                      
                            ),
                            flex: 2,
                          ),
                          Expanded(
                            flex: 4,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                alertsData[index]['emergency']??false
                                ?Text(
                                  "Emergency\n",
                                  style: TextStyle(
                                      color: Colors.red[400],
                                      fontFamily: 'Avenir',
                                      fontWeight: FontWeight.w700),
                                )
                                :Container(),

                                Text(
                                  alertsData[index]['time']??"",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'Avenir',
                                      fontWeight: FontWeight.w700),
                                ),
                                Text(
                                  "Contact ${alertsData[index]['name']} immediately.",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'Avenir',
                                  ),
                                ),
                                SizedBox(height: 16),
                                Row(
                                  children: <Widget>[
                                    Icon(
                                      Icons.location_on,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    SizedBox(
                                      width: 8,
                                    ),
                                    Flexible(
                                      child: Text(
                                        // "${alertsData[index]['latitude']}, ${alertsData[index]['longitude']}",
                                        "Long Press for ${alertsData[index]['name']}'s last location",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontFamily: 'Avenir',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Container(
                                height: 45,
                                width: 25,
                                child: ElevatedButton(
                                style: ButtonStyle(
                                  backgroundColor: MaterialStateProperty.all(Colors.red[300]),
                                  elevation: MaterialStateProperty.all(1.4),
                                  shadowColor: MaterialStateProperty.all(Colors.grey),
                                  shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(14)))),
                                          ),
                            onPressed: () {
                               // change accepted status to true
                               FirebaseFirestore.instance.collection('alerts')
                               .doc(alertsData[index]['idTo'])
                               .update({
                                'alerts':FieldValue.arrayRemove(
                                  [
                                        {
                                      'idFrom':alertsData[index]['idFrom'],
                                      'idTo':alertsData[index]['idTo'],
                                      'latitude':alertsData[index]['latitude'],
                                       'longitude':alertsData[index]['longitude'],
                                       'payload':alertsData[index]['payload'],
                                       'name':alertsData[index]['name'],
                                       'time':alertsData[index]['time'],
                                       'emergency':alertsData[index]['emergency'],
                                       'pushToken':alertsData[index]['pushToken'],
                                          }]
                                )
                               });
                               setState(() {  });      
                                    },
                                    child: Center(child: Icon(Icons.delete)),
                                    ),
                               ),
                          
                          ),
                          SizedBox(width: 5),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
   
      }

      );
  }

}




class PlaceInfo {
  final String name;
  final String category;
  final String location;
  final double rating;
  final Color startColor;
  final Color endColor;

  PlaceInfo(this.name, this.startColor, this.endColor, this.rating,
      this.location, this.category);
}

class CustomCardShapePainter extends CustomPainter {
  final double radius;
  final Color startColor;
  final Color endColor;

  CustomCardShapePainter(this.radius, this.startColor, this.endColor);

  @override
  void paint(Canvas canvas, Size size) {
    var radius = 24.0;

    var paint = Paint();
    paint.shader = ui.Gradient.linear(
        Offset(0, 0), Offset(size.width, size.height), [
      HSLColor.fromColor(startColor).withLightness(0.8).toColor(),
      endColor
    ]);

    var path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width - radius, size.height)
      ..quadraticBezierTo(
          size.width, size.height, size.width, size.height - radius)
      ..lineTo(size.width, radius)
      ..quadraticBezierTo(size.width, 0, size.width - radius, 0)
      ..lineTo(size.width - 1.5 * radius, 0)
      ..quadraticBezierTo(-radius, 2 * radius, 0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
        