
import '../dao/pays_dao.dart';
import '../models/pays.dart';

class PaysRepository {
  final paysDao = PaysDao();

  Future<int> insert(Pays data) => paysDao.insert(data);
  Future<Pays> findPaysByIso(String data) => paysDao.findPaysByIso(data);
  Future<List<Pays>> findAll() => paysDao.findAll();
}