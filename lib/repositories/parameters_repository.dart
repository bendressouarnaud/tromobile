
import 'package:tro/dao/chat_dao.dart';
import '../dao/parameters_dao.dart';
import '../models/chat.dart';
import '../models/parameters.dart';

class ParametersRepository {
  final dao = ParametersDao();

  Future<Parameters?> findById(int data) => dao.findById(data);
  Future<int> update(Parameters data) => dao.update(data);
}