import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:notify/constants/config.dart';

// ignore: camel_case_types
class contacts extends StatefulWidget {
  @override
  _contactsState createState() => _contactsState();
}

// ignore: camel_case_types
class _contactsState extends State<contacts> {
  final _formKey = GlobalKey<FormState>();
  String phoneNo;

  String userID ;
  String userPhoneNumber ;
  String userPhoneNumberfull ;

Future<void> _showCircularIndicator() {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,      
      // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          actionsPadding: EdgeInsets.zero,
          content: SingleChildScrollView(
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  CircularProgressIndicator(
                    backgroundColor: Colors.blue[300],
                  ),
                  
                  Padding(
                    padding: const EdgeInsets.only(left:10.0, right: 6, top: 7, bottom: 7),
                    child: Text("This may take some time"),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }


  @override
  void initState() {
    userID = FirebaseAuth.instance.currentUser.uid.toString();
    userPhoneNumberfull= FirebaseAuth.instance.currentUser.phoneNumber.toString().replaceAll(' ', "replace");
    userPhoneNumber = userPhoneNumberfull.substring( userPhoneNumberfull.length -10, userPhoneNumberfull.length);
    super.initState();
    // _query();
  }

  @override
  void dispose() {    
    super.dispose();
  }


  Future<void> getContacts(String number) async {
    String userPhoneFull = FirebaseAuth.instance.currentUser.phoneNumber.toString();
    String userPhone= userPhoneFull.substring(userPhoneFull.length -10, userPhoneFull.length );
    String recievedfullContact = number.replaceAll(' ', '');
    String recievedtrimmedContact = recievedfullContact.substring(recievedfullContact.length -10, recievedfullContact.length );
    if(userPhone == recievedtrimmedContact){
      Fluttertoast.showToast(msg: "Don't use your own number");
      return null;
    }

    String name, userNumber,uid;
    bool loop = false;
    // _showCircularIndicator();
    print("inisde getContacts()");
    // final Iterable<Contact> contacts = await ContactsService.getContacts();
    print("inisde getContacts() done");
    await FirebaseFirestore.instance.collection('users').get().then((value) {
      value.docs.forEach((element) { 
        var data = element.data();
        // print(element.data());
        // print("user phone number -- ${data['phoneNumber']}");
        String userPhoneNumberFull;
        String userPhoneNumberTrimmed;
        
        userPhoneNumberFull = data['phoneNumber'].replaceAll(' ', '');
        userPhoneNumberTrimmed= userPhoneNumberFull.substring(userPhoneNumberFull.length -10, userPhoneNumberFull.length  );
        String fullContact = number.replaceAll(' ', '');
        String trimmedContact = fullContact.substring(fullContact.length -10, fullContact.length );
        print('$trimmedContact: $userPhoneNumberTrimmed');
        if(trimmedContact == userPhoneNumberTrimmed){
          print("number found $data");
          setState(() {
           String userNumberFull = data['phoneNumber'].replaceAll(' ', '');
          userNumber = data['phoneNumber'].substring(userNumberFull.length -10, userNumberFull.length );
          name = data['name'];
          uid = data['id'];  
          loop = true;
                    });       
           }      
      });
    });  
          
                    if(loop){
                    showDialog(
            context: context,
            builder: (BuildContext context) {
        return AlertDialog(
          actionsPadding: EdgeInsets.zero,
          content: SingleChildScrollView(
            child: Center(
              child: ListTile(                
                title: Text("$name"??"name"),
                subtitle: Text("$userNumber"??"phoneNumber"),          
                leading: CircleAvatar(backgroundColor: Colors.blue[100],
                    child: Icon(Icons.account_circle,color: Colors.blue[300]),),  
                onTap: (){
                  // send req
                  FirebaseFirestore.instance.collection('users')
                  .doc(uid)
                  .update({
                    'requests': FieldValue.arrayUnion([
                      {
                        'uid':userID,
                        'accepted':'false',
                        'name':userName,
                        'number':userPhoneNumber,
                        }
                        ])
                  });
                  // record sent req
                  FirebaseFirestore.instance.collection('users')
                  .doc(userID)
                  .update({
                    'sentRequests': FieldValue.arrayUnion([
                      {
                        'uid':uid,
                        'accepted':'false',
                        'name':name,
                        'number':userNumber,
                        }])
                  });
                  Fluttertoast.showToast(msg: "Request Sent");
                  Navigator.of(context).pop();
                  setState(() { });

                },            
              )
            ),
          ),
        );
      },
            );}else{
              Fluttertoast.showToast(msg: "Not Found");
            }
                    
  }
  Widget _loadUsersFromContacts(DocumentSnapshot snapshot) {
    List<dynamic> requestsData=[];
    List<dynamic> sentRequestsData=[];
    requestsData = snapshot.data()['requests']??[];
    sentRequestsData = snapshot.data()['sentRequests']??[];
    if (requestsData.length != 0 || sentRequestsData.length != 0 ) {
      return  Column(
        children: [
          Padding(
                    padding: const EdgeInsets.only(top: 18.0),
                    child: const Text("Requests", style: TextStyle(
                              fontFamily: 'FugazOne',
                              fontSize: 15.0,
                              color: Colors.blue,),),
                  ),
          requestsData.length != 0
          ?Container(
            height: (requestsData.length)*85.0,
            child: ListView.builder(          
                    itemCount: requestsData?.length ?? 0,
                    itemBuilder: (BuildContext context, int index) {                  
                      return ListTile(                  
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 2, horizontal: 18),
                        leading: (requestsData[index] != null )
                            ? CircleAvatar(
                                backgroundColor: Colors.pink,
                                child: Icon(Icons.account_circle),
                              )
                            : CircleAvatar(
                                child: Text(requestsData[index]['name'].toString().substring(0,1)),
                                backgroundColor: Theme.of(context).accentColor,
                              ),
                              trailing: Container(
                                              height: 30,
                                              width: 60,
                                              child: ElevatedButton(
                                                style: ButtonStyle(
                                          backgroundColor: requestsData[index]['accepted']=='false'
                                          ? MaterialStateProperty.all(Colors.green)
                                          :MaterialStateProperty.all(Colors.blue[300]),
                                          elevation: MaterialStateProperty.all(1.4),
                                          shadowColor: MaterialStateProperty.all(Colors.grey),
                                          shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(14)))),
                                        ),
                          onPressed: () {
                             // change accepted status to true
                             if(requestsData[index]['accepted']=='false'){
                             FirebaseFirestore.instance.collection('users')
                             .doc(userID)
                             .update({
                              'requests':FieldValue.arrayRemove(
                                [
                                      {
                                    'uid':requestsData[index]['uid'],
                                    'accepted':'false',
                                    'name':requestsData[index]['name'],
                                     'number':requestsData[index]['number'],
                                        }]
                              )
                             });
                             FirebaseFirestore.instance.collection('users')
                             .doc(userID)
                             .update({
                              'requests':FieldValue.arrayUnion(
                                [
                                      {
                                    'uid':requestsData[index]['uid'],
                                    'accepted':'true',
                                    'name':requestsData[index]['name'],
                                     'number':requestsData[index]['number'],
                                        }]
                              )
                             });
                             // -------------------//
                             // change accepted status true in sender's accnt
                             FirebaseFirestore.instance.collection('users')
                             .doc(requestsData[index]['uid'])
                             .update({
                              'sentRequests':FieldValue.arrayRemove(
                                [
                                      {
                                    'uid':userID,
                                    'accepted':'false',
                                    'name':userName,
                                     'number':userPhoneNumber,
                                        }]
                              )
                             });
                             FirebaseFirestore.instance.collection('users')
                             .doc(requestsData[index]['uid'])
                             .update({
                              'sentRequests':FieldValue.arrayUnion(
                                [
                                      {
                                    'uid':userID,
                                    'accepted':'true',
                                    'name':userName,
                                     'number':userPhoneNumber,
                                        }]
                              )
                             });

                             setState(() {  });
                             }else{
                               
                               // delete the entry from requests of user
                             String userPhoneFull = FirebaseAuth.instance.currentUser.phoneNumber.toString();
                              String userPhone= userPhoneFull.substring(userPhoneFull.length -10, userPhoneFull.length );
                               FirebaseFirestore.instance.collection('users')
                               .doc(userID)
                               .update({
                                  'requests': FieldValue.arrayRemove([
                                  {
                                      'uid':requestsData[index]['uid'],
                                      'accepted':requestsData[index]['accepted'],
                                      'name':requestsData[index]['name'],
                                      'number':requestsData[index]['number'],
                                    }])
                               });
                               // delete the entry from other users senRequests
                               FirebaseFirestore.instance.collection('users')
                             .doc(requestsData[index]['uid'])
                             .update({
                              'sentRequests':FieldValue.arrayRemove(
                                [
                                      {
                                    'uid':userID,
                                    'accepted':requestsData[index]['accepted'],
                                    'name':userName,
                                     'number':userPhone,
                                        }]
                              )
                             });
                             Fluttertoast.showToast(msg: "Deleted");
                               
                               setState(() {  });  

                             }
                                  },
                                  child: requestsData[index]['accepted']=='false'?Icon(Icons.check):Icon(Icons.delete),
                                  ),
                                            ),
                        title: Text(requestsData[index]['name'] ?? 'name'),
                        subtitle: Text(requestsData[index]['number']??'number'),
                        //This can be further expanded to showing contacts detail
                        // onPressed().
                      );
                    },
                  ),
          )
          : Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text("No requests yet :("),
          ),
          Padding(
                    padding: const EdgeInsets.only(top: 18.0),
                    child: const Text("Your Emergency Contacts", style: TextStyle(
                              fontFamily: 'FugazOne',
                              fontSize: 15.0,
                              color: Colors.blue,),),
                  ),          
          sentRequestsData.length != 0
          ?Container(
            height: (sentRequestsData.length)*85.0,
            child: ListView.builder(          
                    itemCount: sentRequestsData?.length ?? 0,
                    itemBuilder: (BuildContext context, int index) {                  
                      return ListTile(                  
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 2, horizontal: 18),
                        leading: (sentRequestsData[index] != null )
                            ? CircleAvatar(
                                backgroundColor: Colors.pink,
                                child: Icon(Icons.account_circle),
                              )
                            : CircleAvatar(
                                child: Text(sentRequestsData[index]['name'].toString().substring(0,1)),
                                backgroundColor: Theme.of(context).accentColor,
                              ),
                              trailing: Container(
                                              height: 30,
                                              width: 60,
                                              child: ElevatedButton(
                                                style: ButtonStyle(
                                          backgroundColor: sentRequestsData[index]['accepted']=='false'
                                          ? MaterialStateProperty.all(Colors.red[300])
                                          :MaterialStateProperty.all(Colors.green),
                                          elevation: MaterialStateProperty.all(1.4),
                                          shadowColor: MaterialStateProperty.all(Colors.grey),
                                          shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(14)))),
                                        ),
                          onPressed: () {
                             // delete the entry from sent requests of user
                             String userPhoneFull = FirebaseAuth.instance.currentUser.phoneNumber.toString();
                              String userPhone= userPhoneFull.substring(userPhoneFull.length -10, userPhoneFull.length );
                               FirebaseFirestore.instance.collection('users')
                               .doc(userID)
                               .update({
                                  'sentRequests': FieldValue.arrayRemove([
                                  {
                                      'uid':sentRequestsData[index]['uid'],
                                      'accepted':sentRequestsData[index]['accepted'],
                                      'name':sentRequestsData[index]['name'],
                                      'number':sentRequestsData[index]['number'],
                                    }])
                               });
                               // delete the entry from other users Requests
                               FirebaseFirestore.instance.collection('users')
                             .doc(sentRequestsData[index]['uid'])
                             .update({
                              'requests':FieldValue.arrayRemove(
                                [
                                      {
                                    'uid':userID,
                                    'accepted':sentRequestsData[index]['accepted'],
                                    'name':userName,
                                     'number':userPhone,
                                        }]
                              )
                             });
                             Fluttertoast.showToast(msg: "Deleted");
                               
                               setState(() {  });  
                                  },
                                  child: sentRequestsData[index]['accepted']=='false'?Icon(Icons.delete_forever):Icon(Icons.delete),
                                  ),
                                            ),
                        title: Text(sentRequestsData[index]['name'] ?? 'name'),
                        subtitle: Text(sentRequestsData[index]['number']??'number'),
                        //This can be further expanded to showing contacts detail
                        // onPressed().
                      );
                    },
                  ),
          )
          : Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text("No requests yet :("),
          ),
       
        ],
      )
          ;
    } else {
      return Center(child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text("No Requests yet :("),
      ),);
    }
  }

   @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Contacts',
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
                    });
        },
        child: Icon(
          Icons.refresh,
        ),
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Form(   
            key: _formKey,         
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                                "Enter Mobile Number",
                                style: TextStyle(
                                  fontFamily: 'FugazOne',
                                  fontSize: 15.0,
                                  color: Colors.blue,
                              ),),
                              ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Container(
                        width: MediaQuery.of(context).size.width/1.4,
                        child: TextFormField(
                                                  validator: (value) {
                                                    if (value.isEmpty) {
                                                      return "Please Enter your Mobile Number";
                                                    } else {
                                                      if (value.length != 10) {
                                                        return 'Enter Valid Number';
                                                      } else {
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
                                        Container(
                                          height: 40,
                                          width: 80,
                                          child: ElevatedButton(
                                            style: ButtonStyle(
                                      backgroundColor: MaterialStateProperty.all(Colors.green),
                                      elevation: MaterialStateProperty.all(1.4),
                                      shadowColor: MaterialStateProperty.all(Colors.grey),
                                      shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(14)))),
                                    ),
                      onPressed: () {
                         // Validate returns true if the form is valid, or false otherwise.
                            if (_formKey.currentState.validate()) {
                             // If the form is valid, display a snackbar. In the real world,
                              // you'd often call a server or save the information in a database.
                           getContacts(phoneNo);
                         }
                              },
                              child: Text('Search'),
                              ),
                                        ),
                    ],
                  ),
                  
                  FutureBuilder<DocumentSnapshot>(
          future : FirebaseFirestore.instance.collection('users').doc(userID).get(),
          builder: (BuildContext context,
                AsyncSnapshot<DocumentSnapshot> snapshot) {
              switch (snapshot.connectionState) {
                case ConnectionState.waiting:
                  // return Center(child: Text('Loading !'));
                case ConnectionState.active:
                  return Center(child: Text('\nPlease Wait !'));
                case ConnectionState.done:
                  return _loadUsersFromContacts(snapshot.data);
                case ConnectionState.none:
                  return Text('No contacts use Notify yet ._.');
                default:
                  return Text('Click on refresh to load ._.');
              }
          },
        ),                             
        ],
       ),
      ))
        ],
      )
       );
  }
}            
                    