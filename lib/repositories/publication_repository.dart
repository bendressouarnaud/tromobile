
import 'package:tro/dao/publication_dao.dart';
import '../models/publication.dart';

class PublicationRepository {
  final publicationDao = PublicationDao();

  Future<int> insert(Publication data) => publicationDao.insert(data);
  Future<int> update(Publication data) => publicationDao.update(data);
  Future<Publication> findPublicationById(int id) => publicationDao.findPublicationById(id);
  Future<int> deleteById(int id) => publicationDao.deleteById(id);
  Future<List<Publication>> findAll() => publicationDao.findAll();
}