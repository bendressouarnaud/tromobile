
import 'package:tro/dao/chat_dao.dart';
import '../models/chat.dart';

class ChatRepository {
  final chatDao = ChatDao();

  Future<int> insert(Chat data) => chatDao.insert(data);
  Future<int> update(Chat data) => chatDao.update(data);
  Future<Chat> findById(int data) => chatDao.findById(data);
  Future<Chat> findByIdentifiant(String data) => chatDao.findByIdentifiant(data);
  Future<List<Chat>> findAll(int data) => chatDao.findAllBy(data);
  Future<List<Chat>> findAllByIdpubAndIduser(int idpub, int iduser, int idlocaluser) =>
      chatDao.findAllByIdpubAndIduser(idpub, iduser, idlocaluser);
  Future<List<Chat>> findAllByStatut(int data) => chatDao.findAllByStatut(data);
}