
import 'package:tro/models/souscription.dart';
import '../dao/souscription_dao.dart';

class SouscriptionRepository {
  final dao = SouscriptionDao();

  Future<int> insert(Souscription data) => dao.insert(data);
  Future<int> update(Souscription data) => dao.update(data);
  Future<List<Souscription>> findAllByIdpub(int idpub) => dao.findAllByIdpub(idpub);
  Future<List<Souscription>> findAllByPublicationsIn(List<int> ids) => dao.findAllByPublicationsIn(ids);
  Future<int> deleteAllSouscriptions() => dao.deleteAllSouscriptions();
  Future<Souscription> findByIdpubAndIduser(int idpub, int iduser) => dao.findByIdpubAndIduser(idpub, iduser);

  Future<Souscription?> findOptionalByStreamChannel(String id) => dao.findOptionalByStreamChannel(id);
  Future<List<Souscription>> findAllWithStreamId() => dao.findAllWithStreamId();
}