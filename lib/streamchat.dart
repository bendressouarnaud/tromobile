import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

class StreamChatApp extends StatelessWidget {

  // Attributes :
  //final StreamChatClient client;
  final Channel channel;

  const StreamChatApp({ Key? key, required this.channel });


  @override
  Widget build(BuildContext context) {
    //
    return MaterialApp(
      builder: (context, child) {
        return StreamChat(client: StreamChatCore.of(context).client, child: child);
      },
      home: StreamChannel(
        channel: channel,
        child: const ChannelPage(),
      )
    );
  }

}


class ChannelPage extends StatelessWidget {
  const ChannelPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
        child: Scaffold(
            appBar: StreamChannelHeader(
              onBackPressed: () {
                Navigator.of(context, rootNavigator: true).pop(context);
              },
            ),
            body: Column(
              children: [
                Expanded(
                    child: StreamMessageListView()
                ),
                StreamMessageInput()
              ],
            )
        ));
  }
}