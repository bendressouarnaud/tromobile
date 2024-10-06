
import 'package:tro/dao/publication_dao.dart';
import '../models/publication.dart';

class PublicationRepository {
  final publicationDao = PublicationDao();

  Future<int> insert(Publication data) => publicationDao.insert(data);
  Future<int> update(Publication data) => publicationDao.update(data);
  Future<Publication> findPublicationById(int id) => publicationDao.findPublicationById(id);
  Future<Publication?> findOptionalPublicationById(int id) => publicationDao.findOptionalPublicationById(id);
  Future<int> deleteById(int id) => publicationDao.deleteById(id);
  Future<int> deleteAllPublications() => publicationDao.deleteAllPublications();
  Future<List<Publication>> findAll() => publicationDao.findAll();
  // These PUBLICATIONs that are still ongoing :
  Future<List<Publication>> findOngoingAll(int milliseconds) => publicationDao.findOngoingAll(milliseconds);
  Future<List<Publication>> findOldAll(int milliseconds) => publicationDao.findOldAll(milliseconds);
}