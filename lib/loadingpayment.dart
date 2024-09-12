import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:http/http.dart';
import 'package:url_launcher/url_launcher.dart';

import 'httpbeans/hubwaveresponse.dart';
import 'httpbeans/hubwaveresponseshort.dart';


class LoadingPayment extends StatefulWidget {

  final int amount;
  final int idpub;
  final int iduser;
  final int reserve;

  const LoadingPayment({Key? key, required this.amount, required this.idpub, required this.iduser, required this.reserve}) : super(key: key);

  @override
  _LoadingPaymentState createState() => _LoadingPaymentState();
}

class _LoadingPaymentState extends State<LoadingPayment> {

  // A T T R I B U T E S :
  bool paiementEnCours = false;



  // M E T H O D S
  // Call HUB API
  Future<void> callWaveApi() async {
    final url = Uri.parse('${dotenv.env['URL']}generatewaveid');
    var response = await post(url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "amount": widget.amount,
          "currency": 'XOF',
          "error_url": 'https://example.com/error',
          "success_url": 'https://example.com/success',
          "idpub": widget.idpub,
          "iduser": widget.iduser,
          "reserve": widget.reserve
        }));

    // Checks :
    if(response.statusCode == 200){
      paiementEnCours = false;
      HubWaveResponseShort hubWaveResponse = HubWaveResponseShort.fromJson(json.decode(response.body));
      if(hubWaveResponse.id.isNotEmpty) {
        // Open link
        final Uri url = Uri.parse(hubWaveResponse.wave_launch_url);
        if (!await launchUrl(url)) {
          //throw Exception('Could not launch $_url');
        }
      }
    }
  }


  Future<bool> _onBackPressed() async {
    bool retour = paiementEnCours ? false : true;
    return retour;
  }

  @override
  void initState() {
    super.initState();

    Future.delayed(
      const Duration(milliseconds: 2000),
      () {
        paiementEnCours = true;
        callWaveApi();
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Paiement en cours ...',
            textAlign: TextAlign.start,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            )
          )
        ),
        body: Column(
          children: [
            const Text('Initialisation du paiement'),
            Container(
              margin: const EdgeInsets.only(top: 15),
              child: const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                strokeWidth: 3.0, /// Width of the circular line
              ),
            ),
            const Text('Veuillez patienter ...'),
          ],
        ),
      )
    );
  }
}