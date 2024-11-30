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
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'package:tro/models/souscription.dart';
import 'package:tro/pageaccueil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:tro/repositories/filiation_repository.dart';
import 'package:tro/services/servicegeo.dart';
import 'package:tro/singletons/outil.dart';

import 'accountcreationhome.dart';
import 'confirmermail.dart';
import 'constants.dart';
import 'firebase_options.dart';
import 'getxcontroller/getchatcontroller.dart';
import 'getxcontroller/getpublicationcontroller.dart';
import 'models/chat.dart';
import 'models/filiation.dart';
import 'models/parameters.dart';
import 'models/publication.dart';
import 'models/user.dart' as databaseuser;


final PublicationGetController _publicationController = Get.put(PublicationGetController());
final ChatGetController _chatController = Get.put(ChatGetController());
Outil outil = Outil();
bool processOnGoing = false;
late Client client;
late StreamChatClient streamClient;



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

// String
String getFirstPrenomIfNeeded(String prenom){
  List<String> tp = prenom.split(" ");
  return tp[0];
}


@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await setupFlutterNotifications();
  //showFlutterNotification(message, 'Num. : ${message.data['identifiant']}', 'Réserve initiale : ${message.data['reserve']} Kg');
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.

  databaseuser.User? localUser = await outil.pickLocalUser();
  //
  /*streamClient.connectUser(
    User(
      id: localUser!.id.toString(),
      name: '${localUser.nom} ${getFirstPrenomIfNeeded(localUser.prenom)}'
    ),
    localUser.streamtoken,
    connectWebSocket: false,
  );*/
  String tampon = message.data['type'];
  if(tampon == "message.new"){
    // From STREAM CHAT, Display 'MESSAGE' :
    // https://getstream.io/chat/docs/sdk/flutter/guides/push-notifications/adding_push_notifications_v2/
    // https://getstream.io/chat/docs/flutter-dart/push_introduction/
    //outil.raiseFlagForNewChat();

    // Virtual CHAT :
    Chat newChat = Chat(
        id: 0,
        idpub: 0,
        milliseconds: 0,
        sens: 0,
        contenu: '',
        statut: 0,
        identifiant: '',
        iduser: 0,
        idlocaluser: 0,
        read: 0
    );
    await outil.insertChatFromBackground(newChat);
  }
  else {
    int sujet = int.parse(message.data['sujet']);
    switch(sujet){
      case 1:
        Publication? publication = Servicegeo().generatePublication(message);
        if (publication != null) {
          // Check if this ONE exists ALREADY or NOT :
          Publication? pubCheck = await _publicationController.findOptionalPublicationById(publication.id);
          if(pubCheck == null){
            // Create
            _publicationController.addData(publication);
          }
          else{
            // Update :
            await _publicationController.updateData(publication);
          }
        }
        break;

      case 2:
      // Create User if not exist :
        databaseuser.User? user = await outil.findUserById(int.parse(message.data['id']));
        if(user == null){
          // Persist DATA :
          // Create new :
          user = databaseuser.User(nationnalite: message.data['nationalite'],
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
              codeinvitation: "123",
              villeresidence: 0, streamtoken: '');
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
            statut: 0,
            streamchannelid: message.data['channelid']);
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
            idlocaluser: localUser!.id,
            read: 0
        );
        await outil.insertChatFromBackground(newChat);

        // Send back 'ACCUsé DE RéCEPTION'
        try {
          final url = Uri.parse('https://vps-b2e0c1f2.vps.ovh.net/trobackend/sendaccusereception');
          // Force INITIALIZATION :
          client = await getSSLPinningClient();
          await client.post(url,
              headers: {"Content-Type": "application/json"},
              body: jsonEncode({
                "identifiant": message.data['identifiant'],
                "idpub": int.parse(message.data['idpub'])
              })
          ).timeout(const Duration(seconds: timeOutValue));
        }
        catch (e) {
          //print('Exception durant CASE 3 : ${e.toString()}');
        }

        // Display NOTIFICATIONS :
        // Check lastest APP state, if DETACHED or PAUSED, then display NOTIFICATION and persist DATA :
        /*Parameters? prms = await outil.getParameter();
      if(prms != null && prms.state != 'resumed'){

      }*/
        break;


      case 4:
        databaseuser.User? user = await outil.findUserById(int.parse(message.data['id']));
        if(user == null){
          // Persist DATA :
          user = databaseuser.User(nationnalite: message.data['nationalite'],
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
              codeinvitation: "123",
              villeresidence: 0, streamtoken: '');
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
            read: 1,
            streamchannelid: pub.streamchannelid
        );
        // Update  :
        //await outil.updatePublication(newPub);
        await outil.updatePublicationWithoutFurtherActions(newPub);
        break;

      case 5:
      // On PUBLICATION :
        Publication pub = await outil.refreshPublication(int.parse(message.data['idpub']));
        Publication newPub = Publication(
            id: pub.id,
            userid: pub.userid,
            villedepart: pub.villedepart,
            villedestination: pub.villedestination,
            datevoyage: pub.datevoyage,
            datepublication: pub.datepublication,
            reserve: pub.reserve,
            active: 2,
            reservereelle: pub.reservereelle,
            souscripteur: pub.souscripteur, // Use OWNER Id
            milliseconds: pub.milliseconds,
            identifiant: pub.identifiant,
            devise: pub.devise,
            prix: pub.prix,
            read: 1,
            streamchannelid: pub.streamchannelid
        );
        // Update  :
        //await outil.updatePublication(newPub);
        await outil.updatePublicationWithoutFurtherActions(newPub);
        break;

      case 6:
      // Réception ACCUSé DE RéCEPTION :
        Chat ct = await outil.findChatByIdentifiant(message.data['identifiant']);
        Chat newChat = Chat(
            id: ct.id,
            idpub: ct.idpub,
            milliseconds: ct.milliseconds,
            sens: ct.sens,
            contenu: ct.contenu,
            statut: 3, // Accusé de réception
            identifiant: ct.identifiant,
            iduser: ct.iduser,
            idlocaluser: ct.idlocaluser,
            read: ct.read
        );
        await outil.updateChatWithoutNotif(newChat);
        break;

      case 7:
        Publication? pub = await outil.findOptionalPublicationById(int.parse(message.data['idpub']));
        if(pub != null) {
          Publication newPub = Publication(
              id: pub.id,
              userid: pub.userid,
              villedepart: pub.villedepart,
              villedestination: pub.villedestination,
              datevoyage: pub.datevoyage,
              datepublication: pub.datepublication,
              reserve: pub.reserve,
              active: pub.active,
              reservereelle: int.parse(message.data['poids']),
              souscripteur: pub.souscripteur,
              // Use OWNER Id
              milliseconds: pub.milliseconds,
              identifiant: pub.identifiant,
              devise: pub.devise,
              prix: pub.prix,
              read: pub.read,
              streamchannelid: pub.streamchannelid
          );
          // Update  :
          await outil.updatePublicationWithoutFurtherActions(newPub);
        }
        break;

      case 8:
        Publication? pub = await outil.findOptionalPublicationById(int.parse(message.data['idpub']));
        if(pub != null) {
          Publication newPub = Publication(
              id: pub.id,
              userid: pub.userid,
              villedepart: pub.villedepart,
              villedestination: pub.villedestination,
              datevoyage: pub.datevoyage,
              datepublication: pub.datepublication,
              reserve: pub.reserve,
              active: 0,
              reservereelle: pub.reservereelle,
              souscripteur: pub.souscripteur,
              // Use OWNER Id
              milliseconds: pub.milliseconds,
              identifiant: pub.identifiant,
              devise: pub.devise,
              prix: pub.prix,
              read: pub.read,
              streamchannelid: pub.streamchannelid
          );
          // Update  :
          await outil.updatePublicationWithoutFurtherActions(newPub);
        }
        break;

      case 9:
        try {
          Souscription souscription = await outil.getSouscriptionByIdpubAndIduser(
              int.parse(message.data['idpub']),
              int.parse(message.data['iduser']));
          Souscription souscriptionUpdate = Souscription(
              id: souscription.id,
              idpub: souscription.idpub,
              iduser: souscription.iduser,
              millisecondes: souscription.millisecondes,
              reserve: souscription.reserve,
              statut: 2 ,
              streamchannelid:
              souscription.streamchannelid// To cancel
          );
          await outil.updateSouscription(souscriptionUpdate);
        }
        catch (e){
        }
        break;

      case 10:
        try {
          final filiationRepository = FiliationRepository();
          Filiation? filiation = await filiationRepository.findById(1);
          if(filiation != null){
            Filiation upDateFiliation = Filiation(id: 1, code: filiation.code,
                bonus: double.parse(message.data['montant']));
            filiationRepository.update(upDateFiliation);
          }
        }
        catch (e){
        }
        break;

      case 11:
        try {
          Publication? pub = await outil.findOptionalPublicationById(int.parse(message.data['idpub']));
          if(pub != null) {
            Publication newPub = Publication(
                id: pub.id,
                userid: pub.userid,
                villedepart: pub.villedepart,
                villedestination: pub.villedestination,
                datevoyage: pub.datevoyage,
                datepublication: pub.datepublication,
                reserve: pub.reserve,
                active: pub.active,
                reservereelle: pub.reservereelle,
                souscripteur: pub.souscripteur,
                // Use OWNER Id
                milliseconds: pub.milliseconds,
                identifiant: pub.identifiant,
                devise: pub.devise,
                prix: pub.prix,
                read: pub.read,
                streamchannelid: message.data['channelid']
            );
            // Update  :
            await outil.updatePublicationWithoutFurtherActions(newPub);
          }
        }
        catch (e){}
        break;
    }
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
  /*print('Start running');
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
      }
      catch (e) {
        print('Exception durant : ${e.toString()}');
      }
    }
    print('Taille : ${liste.length}');
    service.stopSelf();
    processOnGoing = false;
    print('Le service prend fin : ');
  } catch (e) {
    print('Error retrieving data: $e');
  }*/
}


Future<void> main() async {

  // Load environment DATA :
  await dotenv.load(fileName: "variable.env");

  // Wait for :
  WidgetsFlutterBinding.ensureInitialized();

  if(defaultTargetPlatform == TargetPlatform.android) {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
    // Set the background messaging handler early on, as a named top-level function
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  // Init SERVICE :
  await initializeService();
  client = await getSSLPinningClient();
  streamClient = StreamChatClient(dotenv.env['API_STREAM']!);

  databaseuser.User? localUser = await outil.pickLocalUser();
  Parameters? params = await outil.getParameter();
  if(localUser == null) {
    runApp(AccountCreationHome());
  }
  else if(params!.comptevalide == 0){
    runApp(MyAppMail(client: client));
  }
  else {
    runApp(MyApp(client: client, streamclient: streamClient));
  }
}

class MyApp extends StatelessWidget {
  final Client? client;
  final StreamChatClient streamclient;
  const MyApp({super.key, required this.client, required this.streamclient});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: (context, child) {
        return StreamChatCore(client: streamclient, child: child!);
      },
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: WelcomePage(client: client!, streamclient: streamclient),
    );
  }
}


class MyAppMail extends StatelessWidget {
  final Client? client;
  const MyAppMail({super.key, required this.client});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        // This is the theme of your application.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: ConfirmerMail(client: client!, tache: 1,)
    );
  }
}
