importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyAcAfdMKBGGl1M7oa9B0rkrQEZ8D1khZug",
  authDomain: "takhotel-b0a4a.firebaseapp.com",
  projectId: "takhotel-b0a4a",
  storageBucket: "takhotel-b0a4a.appspot.com",
  messagingSenderId: "886351472574",
  appId: "1:886351472574:web:0f9e9206d32fd85d4a7bef",
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage(function(payload) {
  self.registration.showNotification(
    payload.notification?.title || 'Commande prête',
    {
      body: payload.notification?.body || '',
    }
  );
});