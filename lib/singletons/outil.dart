import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:tro/getxcontroller/getpublicationcontroller.dart';
import 'package:tro/getxcontroller/getusercontroller.dart';
import 'package:tro/models/publication.dart';
import 'package:tro/models/souscription.dart';
import 'package:tro/repositories/ville_repository.dart';

import '../getxcontroller/getchatcontroller.dart';
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
  final _villeRepository = VilleRepository();
  String urlPrefix = '';
  User? publicationOwner;
  Publication? publicationSuscribed;
  final lesDevises = [
    Devises(libelle: 'CFA', id: 1),
    Devises(libelle: 'EURO', id: 2),
    Devises(libelle: 'USD', id: 3)
  ];
  bool fcmFlag = false;

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

  // For U S E R
  User getLocalUser(){
    return _userController.getLocalUser();
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

  Future<Souscription> getSouscriptionByIdpubAndIduser(int idpub, int iduser) async{
    return await _souscriptionController.getByIdpubAndIduser(idpub, iduser); // Ajout du AWAIT le 29/08/2024
  }

  Future<int> updateSouscription(Souscription data) async{
    return await _souscriptionController.updateSouscription(data);
  }

  // for  P U B L I C A T I O N
  void addPublication(Publication publication){
    _publicationController.addData(publication);
  }

  Future<void> updatePublication(Publication publication) async{
    publicationSuscribed = publication;
    _publicationController.updateData(publication);
    publicationOwner = await _userController.findById(publication.souscripteur);
    //return null;
  }

  Future<Publication> refreshPublication(int idpub) async {
    return await _publicationController.refreshPublication(idpub);
  }

  Future<List<Publication>> findAllPublication() async {
    return await _publicationController.findAllPublication();
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

  // V I L L E
  Future<Ville> getVilleById(int id) async{
    return await _villeRepository.findById(id);
  }

}