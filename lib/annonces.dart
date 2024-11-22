import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'package:tro/app.dart';
import 'package:tro/getxcontroller/getpublicationcontroller.dart';
import 'package:tro/models/chat.dart';
import 'package:tro/repositories/chat_repository.dart';
import 'package:tro/repositories/pays_repository.dart';
import 'package:tro/repositories/publication_repository.dart';
import 'package:tro/repositories/souscription_repository.dart';
import 'package:tro/repositories/user_repository.dart';
import 'package:tro/repositories/ville_repository.dart';
import 'package:tro/streamchat.dart';
import 'package:tro/widget/display_error_message.dart';
import 'package:tro/widget/unread_indicator.dart';

import 'helpers.dart';
import 'main.dart';
import 'mesbeans/destinataires.dart';
import 'models/pays.dart';
import 'models/publication.dart';
import 'models/souscription.dart';
import 'models/user.dart' as databaseuser;
import 'models/ville.dart';

import 'package:jiffy/jiffy.dart';

class AnnoncesUsers extends StatefulWidget {
  final StreamChatClient streamclient;
  final List<Publication> listePublication;
  final List<Souscription> listeSouscription;
  const AnnoncesUsers({Key? key, required this.streamclient, required this.listePublication, required this.listeSouscription}) : super(key: key);

  @override
  State<AnnoncesUsers> createState() => _AnnoncesUsersState();
}

class _AnnoncesUsersState extends State<AnnoncesUsers> {
  // O B J E C T S :
  final _publicationRepository = PublicationRepository();
  final _souscriptionRepository = SouscriptionRepository();
  final _chatRepository = ChatRepository();
  List<Pays> listePays = [];
  List<Ville> listeVille = [];
  User? localUser;

  final lesCouleurs = [Colors.black12, Colors.blue[100], Colors.blueGrey[100], Colors.red[100], Colors.orange[100], Colors.yellow[100],
    Colors.green[100], Colors.purple[100], Colors.brown[100], Colors.white70, Colors.pink[100]];
  int cptCouleur = 0;
  late List<User> ownersChat;
  late List<Publication> lesPublications;
  late List<int> feedPublications;
  late databaseuser.User tUser;
  databaseuser.User? cUser;
  late String leMessage;
  List<Destinataires> lesDestinataires = [];
  late List<Souscription> tampSub;
  late final channelListController = StreamChannelListController(
    client: StreamChatCore.of(context).client,
    filter: Filter.and([
      Filter.equal('type', 'messaging'),
      Filter.in_(
        'members',
        [
          StreamChatCore.of(context).currentUser!.id
        ],
      ),
    ]),
  );


  // M E T H O D S :
  @override
  void initState() {
    cleanChatUnread();
    channelListController.doInitialLoad();
    super.initState();
  }

  // Look for PUBLICATION IDENTIFIANT :
  void cleanChatUnread() async{
    List<Chat> lte = await _chatRepository.findAllChats();
    int taille = lte.where((chat) => chat.read ==0).toList().length;
    if(taille > 0){
      // Refresh :
      _chatRepository.deleteAllChats();
      outil.resetChat();
    }
  }

  @override
  void dispose() {
    channelListController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PagedValueListenableBuilder<int, Channel>(
      valueListenable: channelListController,
      builder: (context, value, child) {
        return value.when(
              (channels, nextPageKey, error) {
            if (channels.isEmpty) {
              return const Center(
                child: Text(
                  'Aucun message.\nVeuillez avoir une annonce encours',
                  textAlign: TextAlign.center,
                ),
              );
            }
            return LazyLoadScrollView(
              onEndOfPage: () async {
                if (nextPageKey != null) {
                  channelListController.loadMore(nextPageKey);
                }
              },
              child: CustomScrollView(
                slivers: [
                  /*const SliverToBoxAdapter(
                    child: _Stories(),
                  ),*/
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) {
                        return _MessageTile(
                          channel: channels[index], listePublication: widget.listePublication, listeSouscription: widget.listeSouscription,
                        );
                      },
                      childCount: channels.length,
                    ),
                  )
                ],
              ),
            );
          },
          loading: () => const Center(
            child: SizedBox(
              height: 100,
              width: 100,
              child: CircularProgressIndicator(),
            ),
          ),
          error: (e) => DisplayErrorMessage(
            error: e,
          ),
        );
      },
    );
  }
}

class _MessageTile extends StatelessWidget {
  const _MessageTile({
    Key? key,
    required this.channel, required this.listePublication, required this.listeSouscription,
  }) : super(key: key);

  final Channel channel;
  final List<Publication> listePublication;
  final List<Souscription> listeSouscription;

  // Process :
  String getPublicationId(String channelId) {
    String pubId = '';
    Publication? tampPUB = listePublication.where((pub) => pub.streamchannelid == channelId).firstOrNull;
    if(tampPUB == null){
      Souscription? tampSOUS = listeSouscription.where((souscript) => souscript.streamchannelid == channelId).firstOrNull;
      if(tampSOUS != null){
        Publication? pubOwner = listePublication.where((pub) => pub.id == tampSOUS.idpub).firstOrNull;
        pubId = pubOwner!.identifiant;
      }
    }
    else{
      pubId = tampPUB!.identifiant;
    }
    return pubId;
  }

  @override
  Widget build(BuildContext context) {
    //print('Channel IDs : ${channel.id}');
    return InkWell(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context){
                  return StreamChatApp(channel: channel);
                }
            )
        );
        //Navigator.of(context).push(ChatScreen.routeWithChannel(channel));
      },
      child: Container(
        height: 100,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context).dividerColor,
              width: 0.5,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(10.0),
                /*child: Avatar.medium(
                    url:
                    Helpers.getChannelImage(channel, context.currentUser!)),*/
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        '${Helpers.getChannelName(channel, context.currentUser!)} -- ${getPublicationId(channel.id!)}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          letterSpacing: 0.2,
                          wordSpacing: 1.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 20,
                      child: _buildLastMessage(),
                    )
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const SizedBox(
                      height: 4,
                    ),
                    _buildLastMessageAt(),
                    const SizedBox(
                      height: 8,
                    ),
                    Center(
                      child: UnreadIndicator(
                        channel: channel,
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLastMessage() {
    return BetterStreamBuilder<int>(
      stream: channel.state!.unreadCountStream,
      initialData: channel.state?.unreadCount ?? 0,
      builder: (context, count) {
        return BetterStreamBuilder<Message>(
          stream: channel.state!.lastMessageStream,
          initialData: channel.state!.lastMessage,
          builder: (context, lastMessage) {
            return Text(
              lastMessage.text ?? '',
              overflow: TextOverflow.ellipsis,
              style: (count > 0)
                  ? const TextStyle(
                fontSize: 12,
                color: Color(0xFF3B76F6),
              )
                  : const TextStyle(
                fontSize: 12,
                color: Color(0xFF9899A5),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLastMessageAt() {
    return BetterStreamBuilder<DateTime>(
      stream: channel.lastMessageAtStream,
      initialData: channel.lastMessageAt,
      builder: (context, data) {
        final lastMessageAt = data.toLocal();
        String stringDate;
        final now = DateTime.now();

        final startOfDay = DateTime(now.year, now.month, now.day);

        if (lastMessageAt.millisecondsSinceEpoch >=
            startOfDay.millisecondsSinceEpoch) {
          stringDate = Jiffy.parseFromDateTime(lastMessageAt.toLocal()).jm;
        } else if (lastMessageAt.millisecondsSinceEpoch >=
            startOfDay
                .subtract(const Duration(days: 1))
                .millisecondsSinceEpoch) {
          stringDate = 'YESTERDAY';
        } else if (startOfDay.difference(lastMessageAt).inDays < 7) {
          stringDate = Jiffy.parseFromDateTime(lastMessageAt.toLocal()).EEEE;
        } else {
          stringDate = Jiffy.parseFromDateTime(lastMessageAt.toLocal()).yMd;
        }
        return Text(
          stringDate,
          style: const TextStyle(
            fontSize: 11,
            letterSpacing: -0.2,
            fontWeight: FontWeight.w600,
            color: Color(0xFF9899A5)
          ),
        );
      },
    );
  }
}

class _Stories extends StatelessWidget {
  const _Stories({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Card(
        elevation: 0,
        child: SizedBox(
          height: 140,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 16.0, top: 8, bottom: 16),
                child: Text(
                  'Stories',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    //color: AppColors.textFaded,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (BuildContext context, int index) {
                    //final faker = Faker();
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SizedBox(
                        width: 60,
                        child: Text('OK'),

                      ),
                    );
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
