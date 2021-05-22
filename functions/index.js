const functions = require('firebase-functions')
const admin = require('firebase-admin')
admin.initializeApp()

const runtimeOpts = {
    timeoutSeconds: 300,
    memory: '4GB'
}
exports.sendEmergencyAlert = functions.firestore
    .document('emergency/{currrentUserIdTime}')
    .onWrite((snap, context) => {
        console.log('----------------Start Emergency--------------------')
        const doc = snap.after.data()
        console.log(doc)

        // console.log(doc.idFrom)
        var userPhoneNumber
        var userPushToken

        var idFrom = doc.idFrom
        var latitude = doc.latitude
        var longitude = doc.longitude
        var timestamp = doc.timestamp
        var time = new Date().toLocaleString(undefined, { timeZone: 'Asia/Kolkata' }).replace(/T/, ' ').replace(/\..+/, '');
        // time.setUTCSeconds(time);
        var idsTo = doc.idsTo
        var nickname = doc.nickname
        var transactionid = doc.transactionid
        admin
            .firestore()
            .collection('users')
            .doc(idFrom)
            .get()
            .then(userDbSnap => {
                var userFromDbSnapData = userDbSnap.data()
                userPhoneNumber = userFromDbSnapData.phoneNumber
                userPushToken = userFromDbSnapData.pushToken
            }).then((value) => {



                idsTo.forEach(userIdTo => {
                    // console.log(userIdTo)
                    admin
                        .firestore()
                        .collection('users')
                        .doc(userIdTo)
                        .get()
                        .then(userDbSnap => {
                            var userDbSnapData = userDbSnap.data()
                            // console.log(userDbSnapData)

                            var payload = {
                                notification: {
                                    title: `This is an emergency !! Contact ${nickname} asap. `,
                                    body: `Number : ${userPhoneNumber} \nLocation : ${latitude}, ${longitude}\n${time}`,
                                    badge: '1',
                                    sound: 'default',
                                }
                            }

                            // add alert to database
                            admin
                                .firestore()
                                .collection('alerts')
                                .doc(userIdTo)
                                .update(
                                    {
                                        "alerts": admin.firestore.FieldValue.arrayUnion(
                                            {
                                                'idFrom': idFrom,
                                                'idTo': userIdTo,
                                                'name': nickname,
                                                'latitude': latitude,
                                                'longitude': longitude,
                                                'time': time,
                                                'emergency': true,
                                                'payload': payload,
                                                'pushToken': userDbSnapData.pushToken,
                                            }
                                        )
                                    },
                                )
                                .catch(error => {
                                    admin
                                        .firestore()
                                        .collection('alerts')
                                        .doc(userIdTo)
                                        .set(
                                            {
                                                "alerts": admin.firestore.FieldValue.arrayUnion(
                                                    {
                                                        'idFrom': idFrom,
                                                        'idTo': userIdTo,
                                                        'name': nickname,
                                                        'latitude': latitude,
                                                        'longitude': longitude,
                                                        'payload': payload,
                                                        'time': time,
                                                        'emergency': true,
                                                        'pushToken': userDbSnapData.pushToken,
                                                    }
                                                )
                                            },
                                        )
                                })
                            // Let push to the target device
                            admin
                                .messaging()
                                .sendToDevice(userDbSnapData.pushToken, payload)
                                .then(response => {
                                    console.log('Successfully sent message:', response)
                                })
                                .catch(error => {
                                    console.log('Error sending message:', error)
                                })

                        })
                })

                var payload1 = {
                    notification: {
                        title: `Emergency Alert Sent`,
                        body: `Alert was sent Succesfully`,
                        badge: '1',
                        sound: 'default',
                    }
                }

                admin
                    .messaging()
                    .sendToDevice(userPushToken, payload1)
                    .then(response => {
                        console.log('Successfully sent message:', response)
                    })
                    .catch(error => {
                        console.log('Error sending message:', error)
                    })
            })


        return null
    })

exports.sendAlert = functions.runWith(runtimeOpts).firestore
    .document('journeys/{currrentUserIdTime}')
    .onCreate((snap, context) => {
        console.log('----------------Start function--------------------')

        const doc = snap.data()
        // console.log(doc.idFrom)    

        var idFrom = doc.idFrom
        var userPhoneNumber
        var userPushToken
        admin
            .firestore()
            .collection('users')
            .doc(idFrom)
            .get()
            .then(userDbSnap => {
                var userFromDbSnapData = userDbSnap.data()
                userPhoneNumber = userFromDbSnapData.phoneNumber
                userPushToken = userFromDbSnapData.pushToken
            })
        var loop = true
        var latitude = doc.latitude
        var longitude = doc.longitude
        var stopped = doc.stopped
        var timestamp = doc.timestamp
        var idsTo = doc.idsTo
        var nickname = doc.nickname
        var transactionid = doc.transactionid
        var isPaused = false;
        var alertSent = false;

        var checkFunction = setInterval(() => {
            if (!isPaused) {
                admin.
                    firestore()
                    .collection('journeys')
                    .doc(transactionid)
                    .get()
                    .then(snapshot => {
                        // console.log('---------------Inside first check--------------------')
                        var doc1 = snapshot.data()
                        // console.log(doc1.timestamp)
                        if (!doc1.stopped && loop) {
                            // console.log('---------------journey not stopped--------------------')
                            if ((doc1.timestamp == timestamp) && loop) {

                                timestamp = doc1.timestamp
                                latitude = doc1.latitude
                                longitude = doc1.longitude
                                stopped = doc1.stopped
                                isPaused = true

                                // write wait and recheck code here
                                setTimeout(() => {
                                    admin.
                                        firestore()
                                        .collection('journeys')
                                        .doc(transactionid)
                                        .get()
                                        .then(finalSnap => {
                                            // console.log('---------------ready to send--------------------')
                                            var doc2 = finalSnap.data()
                                            if (!doc2.stopped) {
                                                if (doc2.timestamp == timestamp) {
                                                    clearInterval(this) // this change
                                                    loop = false
                                                    var time = new Date().toLocaleString(undefined, { timeZone: 'Asia/Kolkata' }).replace(/T/, ' ').replace(/\..+/, '');
                                                    // time.setUTCSeconds(time);
                                                    // write push notification code here 
                                                    // console.log('---------------Inside sender--------------------')
                                                    // get userTo pushToken & send notification
                                                    idsTo.forEach(userIdTo => {
                                                        // console.log(userIdTo)
                                                        admin
                                                            .firestore()
                                                            .collection('users')
                                                            .doc(userIdTo)
                                                            .get()
                                                            .then(userDbSnap => {
                                                                var userDbSnapData = userDbSnap.data()
                                                                // console.log(userDbSnapData)

                                                                var payload = {
                                                                    notification: {
                                                                        title: `${nickname}'s device just lost connection. Contact immediately !`,
                                                                        body: `Number : ${userPhoneNumber} \nLocation : ${latitude}, ${longitude}\n${time}`,
                                                                        badge: '1',
                                                                        sound: 'default',
                                                                    }
                                                                }

                                                                // add notification node
                                                                admin
                                                                    .firestore()
                                                                    .collection('notifications')
                                                                    .doc(`${userIdTo}${transactionid}`)
                                                                    .set(
                                                                        {
                                                                            'idFrom': idFrom,
                                                                            'idTo': userIdTo,
                                                                            'name': nickname,
                                                                            'payload': payload,
                                                                            'pushToken': userDbSnapData.pushToken,
                                                                        }
                                                                    ).catch(error => {

                                                                    })

                                                                // add alert to database
                                                                admin
                                                                    .firestore()
                                                                    .collection('alerts')
                                                                    .doc(userIdTo)
                                                                    .update(
                                                                        {
                                                                            "alerts": admin.firestore.FieldValue.arrayUnion(
                                                                                {
                                                                                    'idFrom': idFrom,
                                                                                    'idTo': userIdTo,
                                                                                    'name': nickname,
                                                                                    'latitude': latitude,
                                                                                    'longitude': longitude,
                                                                                    'payload': payload,
                                                                                    'time': time,
                                                                                    'emergency': false,
                                                                                    'pushToken': userDbSnapData.pushToken,
                                                                                }
                                                                            )
                                                                        },
                                                                    )
                                                                    .catch(error => {
                                                                        admin
                                                                            .firestore()
                                                                            .collection('alerts')
                                                                            .doc(userIdTo)
                                                                            .set(
                                                                                {
                                                                                    "alerts": admin.firestore.FieldValue.arrayUnion(
                                                                                        {
                                                                                            'idFrom': idFrom,
                                                                                            'idTo': userIdTo,
                                                                                            'name': nickname,
                                                                                            'latitude': latitude,
                                                                                            'longitude': longitude,
                                                                                            'payload': payload,
                                                                                            'time': time,
                                                                                            'emergency': false,
                                                                                            'pushToken': userDbSnapData.pushToken,
                                                                                        }
                                                                                    )
                                                                                },
                                                                            )
                                                                    })
                                                                alertSent = true;
                                                                if (alertSent) {
                                                                    // Let push to the target device
                                                                    // sending notification 
                                                                    var payload1 = {
                                                                        notification: {
                                                                            title: `Alert sent`,
                                                                            body: `Alert Sent Succesfully !`,
                                                                            badge: '1',
                                                                            sound: 'default',
                                                                        }
                                                                    }

                                                                    admin
                                                                        .messaging()
                                                                        .sendToDevice(userPushToken, payload1)
                                                                        .then(response => {
                                                                            alertSent = false;
                                                                            console.log('Successfully sent message:', response)
                                                                        })
                                                                        .catch(error => {
                                                                            console.log('Error sending message:', error)
                                                                        })
                                                                    alertSent = false;

                                                                }


                                                            })
                                                    })
                                                    return null

                                                }
                                                else {
                                                    isPaused = false
                                                }
                                            } else {
                                                // console.log('---------------Inside 1st else--------------------')
                                                return null
                                            }
                                        })
                                }, 10000);

                            }
                            else {
                                // console.log('---------------Inside 2nd else--------------------')
                                timestamp = doc1.timestamp
                                latitude = doc1.latitude
                                longitude = doc1.longitude
                                stopped = doc1.stopped
                            }
                        } else {
                            // console.log('---------------Inside 3rd else--------------------')
                            loop = false
                            return null
                        }
                    })
            }
        }, 6000);



        return null
    })

// 
exports.sendNotification = functions.runWith(runtimeOpts).firestore
    .document('notifications/{transactionID}')
    .onCreate((snap, context) => {
        console.log('----------------Start notification part--------------------')
        // console.log('snap')
        // console.log(snap)
        // console.log('snap.data')
        const doc = snap.data()
        // console.log(doc)
        console.log('----------------Start notification part--------------------')
        var idFrom = doc.idFrom
        // var latitude = doc.latitude
        // var longitude = doc.longitude
        var idTo = doc.idTo
        var payload = doc.payload
        var pushToken = doc.pushToken

        // Let push to the target device
        admin
            .messaging()
            .sendToDevice(pushToken, payload)
            .then(response => {
                console.log('Successfully sent message:', response)
            })
            .catch(error => {
                console.log('Error sending message:', error)
            })
        return null;


    })

