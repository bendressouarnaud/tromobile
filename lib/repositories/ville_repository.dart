
import '../dao/ville_dao.dart';
import '../models/ville.dart';

class VilleRepository {
  final villeDao = VilleDao();

  Future<int> insert(Ville data) => villeDao.insert(data);
  Future<List<Ville>> findAll() => villeDao.findAll();
  Future<List<Ville>> findAllByPaysId(int paysId) => villeDao.findAllByPaysId(paysId);
  Future<Ville> findById(int id) => villeDao.findById(id);
}