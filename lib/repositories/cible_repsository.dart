
import 'package:tro/dao/cible_dao.dart';
import '../models/cible.dart';

class CibleRepository {
  final cibleDao = CibleDao();

  Future<int> insert(Cible data) => cibleDao.insert(data);
  Future<int> update(Cible data) => cibleDao.update(data);
  Future<Cible> findById(int data) => cibleDao.findById(data);
  Future<List<Cible>> findAll() => cibleDao.findAll();
}