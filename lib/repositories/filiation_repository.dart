
import 'package:tro/dao/chat_dao.dart';
import 'package:tro/models/filiation.dart';
import '../dao/filiation_dao.dart';
import '../dao/parameters_dao.dart';
import '../models/chat.dart';
import '../models/parameters.dart';

class FiliationRepository {
  final dao = FiliationDao();

  Future<int> insert(Filiation data) => dao.save(data);
  Future<Filiation?> findById(int data) => dao.findById(data);
  Future<int> update(Filiation data) => dao.update(data);
  Future<int> deleteAllFiliations() => dao.deleteAllFiliations();
}