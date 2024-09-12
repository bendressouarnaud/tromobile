import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:http/http.dart';
import 'package:http/io_client.dart';
import 'package:tro/models/souscription.dart';
import 'package:tro/pageaccueil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:tro/services/servicegeo.dart';
import 'package:tro/singletons/outil.dart';

import 'firebase_options.dart';
import 'getxcontroller/getchatcontroller.dart';
import 'getxcontroller/getpublicationcontroller.dart';
import 'models/chat.dart';
import 'models/parameters.dart';
import 'models/publication.dart';
import 'models/user.dart';


final PublicationGetController _publicationController = Get.put(PublicationGetController());
final ChatGetController _chatController = Get.put(ChatGetController());
Outil outil = Outil();
bool processOnGoing = false;



Future<SecurityContext> get globalContext async {
  final sslCert = await rootBundle.load('assets/certificat.pem');
  SecurityContext securityContext = SecurityContext(withTrustedRoots: false);
  securityContext.setTrustedCertificatesBytes(sslCert.buffer.asInt8List());
  return securityContext;
}

Future<Client> getSSLPinningClient() async {
  HttpClient client = HttpClient(context: await globalContext);
  client.badCertificateCallback =
      (X509Certificate cert, String host, int port) => false;
  IOClient ioClient = IOClient(client);
  return ioClient;
}


@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await setupFlutterNotifications();
  //showFlutterNotification(message, 'Num. : ${message.data['identifiant']}', 'Réserve initiale : ${message.data['reserve']} Kg');
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  print('Handling a background message ');
  User? localUser = await outil.pickLocalUser();
  //print('Handling a background message ${message.messageId}');
  int sujet = int.parse(message.data['sujet']);
  switch(sujet){
    case 1:
      Publication? publication = Servicegeo().generatePublication(message);
      if(publication != null){
        _publicationController.addData(publication);
      }
      break;

    case 2:
      // Create User if not exist :
      User? user = await outil.findUserById(int.parse(message.data['sujet']));
      if(user == null){
        // Persist DATA :
        // Create new :
        user = User(nationnalite: message.data['nationalite'],
            id: int.parse(message.data['id']),
            typepieceidentite: '',
            numeropieceidentite: '',
            nom: message.data['nom'],
            prenom: message.data['prenom'],
            email: '',
            numero: '',
            adresse: message.data['adresse'],
            fcmtoken: '',
            pwd: "123",
            codeinvitation: "123");
        // Save :
        outil.addUser(user);
      }
      
      // Now feed 'souscription table' :
      Souscription souscription = Souscription(
        id: 0,
        idpub: int.parse(message.data['idpub']),
        iduser: int.parse(message.data['id']),
        millisecondes: DateTime.now().millisecondsSinceEpoch,
        reserve: int.parse(message.data['reserve']),
        statut: 0);
      outil.addSouscription(souscription);
      break;

    case 3:
      //outil = Outil();
      Chat newChat = Chat(
          id: 0,
          idpub: int.parse(message.data['idpub']),
          milliseconds: int.parse(message.data['time']),
          sens: 1,
          contenu: message.data['message'],
          statut: 2,
          identifiant: message.data['identifiant'],
          iduser: int.parse(message.data['sender']),
          idlocaluser: localUser!.id
      );
      outil.insertChatFromBackground(newChat);

      // Display NOTIFICATIONS :
      // Check lastest APP state, if DETACHED or PAUSED, then display NOTIFICATION and persist DATA :
      Parameters? prms = await outil.getParameter();
      if(prms != null && prms.state != 'resumed'){

      }


      //if(message.notification == null) {
      //showFlutterNotification(message, 'Nouveau message', 'C\'est un test');
      //}
      break;


    case 4:
      User? user = await outil.findUserById(int.parse(message.data['id']));
      if(user == null){
        // Persist DATA :
        user = User(nationnalite: message.data['nationalite'],
            id: int.parse(message.data['id']),
            typepieceidentite: '',
            numeropieceidentite: '',
            nom: message.data['nom'],
            prenom: message.data['prenom'],
            email: '',
            numero: '',
            adresse: message.data['adresse'],
            fcmtoken: '',
            pwd: "123",
            codeinvitation: "123");
        // Save :
        outil.addUser(user);
      }

      // On PUBLICATION :
      Publication pub = await outil.refreshPublication(int.parse(message.data['publicationid']));
      Publication newPub = Publication(
          id: pub.id,
          userid: pub.userid,
          villedepart: pub.villedepart,
          villedestination: pub.villedestination,
          datevoyage: pub.datevoyage,
          datepublication: pub.datepublication,
          reserve: pub.reserve,
          active: 1,
          reservereelle: int.parse(message.data['reservevalide']),
          souscripteur: pub.souscripteur, // Use OWNER Id
          milliseconds: pub.milliseconds,
          identifiant: pub.identifiant,
          devise: pub.devise,
          prix: pub.prix,
          read: 1
      );
      // Update  :
      await outil.updatePublication(newPub);
      break;
  }
}

late AndroidNotificationChannel channel;
bool isFlutterLocalNotificationsInitialized = false;
var flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();


Future<void> setupFlutterNotifications() async {
  if (isFlutterLocalNotificationsInitialized) {
    return;
  }
  channel = const AndroidNotificationChannel(
    'fcm_default_channel', // id
    'Information', // title
    description:
    'Statut de la commande', // description
    importance: Importance.high,
  );

  /// Create an Android Notification Channel.
  ///
  /// We use this channel in the `AndroidManifest.xml` file to override the
  /// default FCM channel to enable heads up notifications.
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  /// Update the iOS foreground notification presentation options to allow
  /// heads up notifications.
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );
  isFlutterLocalNotificationsInitialized = true;
}

void showFlutterNotification(RemoteMessage message, String titre, String contenu) {
  RemoteNotification? notification = message.notification;
  AndroidNotification? android = message.notification?.android;
  //if (notification != null && android != null && !kIsWeb) {
    flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      '12345',//notification.title,
      contenu,//notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          // TODO add a proper drawable resource to android, for now using
          //      one that already exists in example app.  tro_notification  launch_background
          icon: 'launch_background',
        ),
        iOS: const DarwinNotificationDetails(
            presentSound: true,
            presentAlert: true,
            presentBadge: true
        )
      ),
      payload: 'Open from Local Notification'
    );
  //}
}


Future<void> initializeService() async {
  final service = FlutterBackgroundService();
  outil = Outil();
  //outil.updateUrlPrefix(dotenv.env['URL']!);
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
      isForegroundMode: false,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}

// For ANDROID :
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async{
  // Only available for flutter 3.0.0 and later
  //DartPluginRegistrant.ensureInitialized();
  /*service.on('task').listen((event) {
    print('Call back is being called');
    callback();
  });*/
  Timer.periodic(const Duration(milliseconds: 850), (timer) {
    if(!processOnGoing){
      processOnGoing= true;
      callback(service);
    }

    //print('Timer periodic');
    //service.invoke('task');
  });
}

// For iOS :
@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  //DartPluginRegistrant.ensureInitialized();
  service.on('task').listen((event) {
    callback(service);
  });
  Timer.periodic(const Duration(seconds: 50), (timer) {
    //service.invoke('task');
  });
  return true;
}


// Our callBack
void callback(ServiceInstance service) async {
  print('Start running');
  try {
    outil = Outil();
    List<Chat> liste = outil.lookForChatToSend(0);// _chatController.getChatToSend(0);
    for(Chat chat in liste){
      try {
        final url = Uri.parse('http://192.168.1.244:8089/trobackend/sendmessage');
        var response = await post(url,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "message": chat.contenu,
              "date": DateTime.now()
            })
        );

        // Update it :
        /*Chat newChat = Chat(id: chat.id,
            idpub: chat.idpub,
            milliseconds: chat.milliseconds,
            sens: chat.sens,
            contenu:
            chat.contenu,
            statut: 1);
        await outil.updateData(newChat);*/
      }
      catch (e) {
        print('Exception durant : ${e.toString()}');
      }
    }
    print('Taille : ${liste.length}');
    service.stopSelf();
    processOnGoing = false;
    print('Le service prend fin : ');

    /*final url = Uri.parse('${dotenv.env['URL']}sendmessage');
    var response = await post(url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "message": 'Pommier',
          "date": DateTime.now()
        }));*/
  } catch (e) {
    print('Error retrieving data: $e');
  }
}


Future<void> main() async {

  // Load environment DATA :
  await dotenv.load(fileName: "variable.env");

  // Wait for :
  WidgetsFlutterBinding.ensureInitialized();

  // Init SERVICE :
  await initializeService();

  if(defaultTargetPlatform == TargetPlatform.android) {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
    // Set the background messaging handler early on, as a named top-level function
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    /*if (!kIsWeb) {
      await setupFlutterNotifications();
    }*/
  }

  final client = await getSSLPinningClient();

  runApp(MyApp(client: client,));
}

class MyApp extends StatelessWidget {
  final Client? client;
  MyApp({super.key, required this.client});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: WelcomePage(client: client!),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
