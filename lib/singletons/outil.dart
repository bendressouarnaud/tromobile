import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:tro/getxcontroller/getpublicationcontroller.dart';
import 'package:tro/getxcontroller/getusercontroller.dart';
import 'package:tro/models/publication.dart';
import 'package:tro/models/souscription.dart';
import 'package:tro/repositories/filiation_repository.dart';
import 'package:tro/repositories/ville_repository.dart';

import '../getxcontroller/getchatcontroller.dart';
import '../getxcontroller/getnavbarchat.dart';
import '../getxcontroller/getnavbarpublication.dart';
import '../getxcontroller/getparamscontroller.dart';
import '../getxcontroller/getsouscriptioncontroller.dart';
import '../mesbeans/devises.dart';
import '../models/chat.dart';
import '../models/parameters.dart';
import '../models/user.dart';
import '../models/ville.dart';

class Outil {

  // A t t r i b u t e s :
  static final Outil _instance = Outil._internal();
  late ChatGetController _chatController;
  late UserGetController _userController;
  late SouscriptionGetController _souscriptionController;
  late PublicationGetController _publicationController;
  late ParametersGetController _parametersController;
  late NavGetController _navController;
  late NavChatGetController _navChatController;
  final _villeRepository = VilleRepository();
  final _filiationRepository = FiliationRepository();
  String urlPrefix = '';
  User? publicationOwner;
  Publication? publicationSuscribed;
  final lesDevises = [
    Devises(libelle: 'CFA', id: 1),
    Devises(libelle: 'EURO', id: 2),
    Devises(libelle: 'USD', id: 3)
  ];
  bool fcmFlag = false;
  bool checkNetworkConnected = false;
  List<String> listeDate = [];

  // M E T H O D S
  // using a factory is important because it promises to return _an_ object of this type but it doesn't promise to make a new one.
  factory Outil() {
    return _instance;
  }
  // This named constructor is the "real" constructor
  // It'll be called exactly once, by the static property assignment         above
  // it's also private, so it can only be called in this class
  Outil._internal() {
    // initialization logic
    _chatController = Get.put(ChatGetController());
    _userController = Get.put(UserGetController());
    _souscriptionController = Get.put(SouscriptionGetController());
    _publicationController = Get.put(PublicationGetController());
    _parametersController = Get.put(ParametersGetController());
    _navController = Get.put(NavGetController());
    _navChatController = Get.put(NavChatGetController());
  }

  void setFcmFlag(bool value){
    fcmFlag = value;
  }

  bool getFcmFlag() {
    return fcmFlag;
  }

  // D E V I S E S
  List<Devises> getDevises() {
    return lesDevises;
  }

  // rest of class as normal, for example:
  void updateUrlPrefix(String name) {
    urlPrefix = name;
  }

  String getUrlPrefix(){
    return urlPrefix;
  }


  // C H A T
  Future<Chat> findChatByIdentifiant(String id) async{
    return await _chatController.findByIdentifiant(id);
  }

  void resetChat() {
    _navChatController.feed(0);
  }

  Future<List<Chat>> findAllChats({ bool refreshNav = false}) async{
    List<Chat> lte = await _chatController.findAllChats( refreshNav: false );
    if(refreshNav){
      int taille = lte.where((chat) => chat.read ==0).toList().length;
      _navChatController.feed(taille);
    }
    return lte;
  }

  Future<List<Chat>> getChatByIdpub(int idpub) async{
    // First Clean :
    return await _chatController.getData(idpub);
  }

  Future<List<Chat>> getChatByIdpubAndIduser(int idpub, int iduser, int idlocaluser) async{
    // First Clean :
    return await _chatController.getDataByIdpubAndIduser(idpub, iduser, idlocaluser);
  }

  Future<void> insertChat(Chat chat) async {
    await _chatController.addData(chat);
    if(chat.read == 0) {
      int newTaille = _navChatController.tableau[0];
      _navChatController.feed(newTaille + 1);
    }
  }

  Future<void> insertChatFromBackground(Chat chat) async {
    await _chatController.addDataFromBackgroundHandler(chat);
  }


  List<Chat> lookForChatToSend(int statut){
    // First Clean :
    return _chatController.lookForChatToSend(statut);
  }

  Future<int> updateData(Chat chat) async {
    return await _chatController.updateData(chat);
  }

  //
  Future<int> updateChatWithoutNotif(Chat chat) async {
    int ret = await _chatController.updateChatWithoutNotif(chat);
    // Test
    //await refreshAllChatsFromResumed(0);
    return ret;
  }

  //
  Future<int> updateChatWithoutNotifFromMessagerie(Chat chat) async {
    //int ret = await _chatController.updateChatWithoutNotifFromMessagerie(chat);
    int ret = await _chatController.updateChatWithoutNotif(chat);
    int newTaille = _navChatController.tableau[0];
    _navChatController.feed(newTaille > 0 ? newTaille - 1 : 0);
    return ret;
  }

  void callChatUpdate () {
    _chatController.callUpdate();
  }

  Future<void> refreshAllChatsFromResumed(int read) async {
    List<Chat> mList = await _chatController.findAllByRead(read);
    int taille = mList.length;
    _navChatController.feed(taille);
  }

  Future<void> raiseFlagForNewChat() async {
    int taille = _navChatController.getLength();
    _navChatController.feed(taille + 1);
  }
  /*Future<void> updateChatNavNotif(List<int> liste) async{
    int newTaille = _navChatController.tableau[0];
    _navChatController.feed(newTaille - liste.length);
  }*/


  // For U S E R
  User getLocalUser(){
    return _userController.getLocalUser();
  }

  Future<int> deleteAllUsers() async{
    return await _userController.deleteAllUsers();
  }

  Future<User?> pickLocalUser() async{
    return await _userController.pickLocalUser();
  }

  Future<User?> findUserById(int id) async {
    publicationOwner = await _userController.findById(id);
    return publicationOwner;
  }

  void addUser(User user) {
    _userController.addData(user);
  }

  Future<List<User>> findAllUserByIdin(List<int> ids) async {
    return await _userController.findAllByIdIn(ids);
  }

  User? getPublicationOwner() {
    return publicationOwner;
  }


  // for  S O U S C R I P T I O N
  Future<void> addSouscription(Souscription souscription) async{
      await _souscriptionController.addData(souscription);
  }

  Future<List<Souscription>> getAllSouscriptionByIdpub(int idpub) async{
    return await _souscriptionController.getData(idpub); // Ajout du AWAIT le 29/08/2024
  }

  //
  Future<List<Souscription>> findAllSuscriptionByIdpub(int idpub) async{
    return await _souscriptionController.findAllSuscriptionByIdpub(idpub);
  }

  Future<Souscription> getSouscriptionByIdpubAndIduser(int idpub, int iduser) async{
    return await _souscriptionController.getByIdpubAndIduser(idpub, iduser); // Ajout du AWAIT le 29/08/2024
  }

  Future<int> updateSouscription(Souscription data) async{
    return await _souscriptionController.updateSouscription(data);
  }

  // Pick this one from 'publicationController'
  List<Souscription> getAllSouscriptionFromPublication() {
    return _publicationController.getAllSouscription();
  }

  // for  P U B L I C A T I O N
  Future<int> deleteAllPublications() async{
    // Delete OTHERS
    await _chatController.deleteAllChats();
    await _souscriptionController.deleteAllSouscriptions();
    await _filiationRepository.deleteAllFiliations();
    return await _publicationController.deleteAllPublications();
  }

  void addPublication(Publication publication){
    _publicationController.addData(publication);
    // Update this :
    if(publication.read == 0) {
      int newTaille = _navController.tableau[0];
      _navController.feed(newTaille + 1);
    }
  }

  Future<void> updatePublicationWithoutFurtherActions(Publication publication) async{
    _publicationController.updateData(publication);
  }

  Future<void> removeDeletedPublication(Publication publication) async{
    _publicationController.removeData(publication);
  }

  Future<void> justUpdatePublicationController() async{
    _publicationController.justUpdate();
  }

  Future<void> updatePublication(Publication publication) async{
    publicationSuscribed = publication;
    _publicationController.updateData(publication);
    publicationOwner = await _userController.findById(publication.souscripteur);

    // Use to refresh NAV BAR
    int newTaille = _navController.tableau[0];
    _navController.feed(newTaille - 1);
  }

  Future<Publication> refreshPublication(int idpub) async {
    return await _publicationController.refreshPublication(idpub);
  }

  Future<Publication?> findOptionalPublicationById(int idpub) async {
    return await _publicationController.findOptionalPublicationById(idpub);
  }

  Future<List<Publication>> findAllPublication() async {
    List<Publication> mList = await _publicationController.findAllPublication();
    int taille = mList.where((element) => element.read == 0).toList().length;
    _navController.feed(taille);
    return mList;
  }

  // OLD DATA :
  Future<List<Publication>> findOldAll() async {
    return await _publicationController.findOldAll();
  }

  List<Publication> readCurrentPublication() {
    return _publicationController.publicationData();
  }

  Future<void> refreshAllPublicationsFromResumed() async {
    List<Publication> mList = await _publicationController.refreshAllPublicationsFromResumed();
    int taille = mList.where((element) => (element.read == 0 && element.milliseconds >= DateTime.now().millisecondsSinceEpoch))
        .toList().length;
    _navController.feed(taille);
  }


  Publication? getPublicationSuscribed() {
    return publicationSuscribed;
  }

  void setPublicationSuscribed() {
    publicationSuscribed = null;
  }


  // P A R A M E T E R S  :
  Future<Parameters?> getParameter() async{
    return await _parametersController.refreshData();
  }

  Future<void> updateParameter(Parameters params) async {
    await _parametersController.updateData(params);
  }

  // V I L L E
  Future<Ville> getVilleById(int id) async{
    return await _villeRepository.findById(id);
  }

  void setCheckNetworkConnected(bool value) {
    checkNetworkConnected = value;
  }

  bool getCheckNetworkConnected() {
    return checkNetworkConnected;
  }

  void resetListe() {
    listeDate = [];
  }

  void addNewDate(String date) {
    listeDate.add(date);
  }

  List<String> getListDate() {
    return listeDate;
  }
}