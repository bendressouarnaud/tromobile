import 'dart:math';

import 'package:stream_chat_flutter_core/stream_chat_flutter_core.dart';

abstract class Helpers {
  static final random = Random();

  static String randomPictureUrl() {
    final randomInt = random.nextInt(1000);
    return 'https://picsum.photos/seed/$randomInt/300/300';
  }

  static String getChannelName(Channel channel, User currentUser) {
    if (channel.name != null) {
      return channel.name!;
    } else if (channel.state?.members.isNotEmpty ?? false) {
      final otherMembers = channel.state?.members
          .where(
            (element) => element.userId != currentUser.id,
          )
          .toList();

      if (otherMembers?.length == 1) {
        
        /*var _publicationRepo = PublicationRepository();
        String pubId = '';
        Publication? pub = await _publicationRepo.findOptionalPublicationByStreamChannel(channel.id!);
        if(pub == null){
          var _souscriptionRepo = SouscriptionRepository();
          Souscription? souscript = await _souscriptionRepo.findOptionalByStreamChannel(channel.id!);
          if(souscript != null){
            Publication pubOwner = await _publicationRepo.findPublicationById(souscript.idpub);
            pubId = pubOwner.identifiant;
          }
        }
        else{
          pubId = pub.identifiant;
        }*/
        
        return otherMembers!.first.user?.name ?? 'No name';
      } else {
        return 'Multiple users';
      }
    } else {
      return 'No Channel Name';
    }
  }

  static String? getChannelImage(Channel channel, User currentUser) {
    if (channel.image != null) {
      return channel.image!;
    } else if (channel.state?.members.isNotEmpty ?? false) {
      final otherMembers = channel.state?.members
          .where(
            (element) => element.userId != currentUser.id,
          )
          .toList();

      if (otherMembers?.length == 1) {
        return otherMembers!.first.user?.image;
      }
    }
    return null;
  }
}
