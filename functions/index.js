const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.sendEventNotification = functions.firestore
    .document("events/{eventId}") // listen to new events
    .onCreate(async (snap, context) => {
      const event = snap.data(); // get event data

      const message = {
        notification: {
          title: "New Event: " + event.title,
          body: event.description,
        },
        topic: "allUsers", // must match topic in Flutter app
      };

      try {
        const response = await admin.messaging().send(message);
        console.log("Notification sent:", response);
      } catch (error) {
        console.error("Error sending notification:", error);
      }
    });
