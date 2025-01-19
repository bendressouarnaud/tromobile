import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

import 'getxcontroller/getparamscontroller.dart';
import 'main.dart';
import 'models/parameters.dart';

class PolitiqueConfidentialite extends StatefulWidget {

  // A T T R I B U T E S :
  PolitiqueConfidentialite({ super.key });

  PolitiqueConfidentialite.setStream(StreamChatClient streamClient,
      int action) {
    this.streamClient = streamClient;
    this.action = action;
  }

  PolitiqueConfidentialite.setAction(int action) {
    this.action = action;
  }

  @override
  State<PolitiqueConfidentialite> createState() => _PolitiqueConfidentialite();

  StreamChatClient? streamClient;
  int action = 0;
}

class _PolitiqueConfidentialite extends State<PolitiqueConfidentialite> {
  // A T T R I B U T E S:
  final ParametersGetController _parametersController = Get.put(
      ParametersGetController());
  late BuildContext contextG;


  // M E T H O D S :
  @override
  void initState() {
    super.initState();

  }

  void openApp() {
    // Close WINDOW :
    Navigator.pop(contextG);

    Navigator
        .push(
        contextG,
        MaterialPageRoute(builder:
            (context) =>
            MyApp(client: client, streamclient: streamClient!)
        )
    );
  }

  @override
  Widget build(BuildContext context) {
    contextG = context;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Confidentialité',
          style: TextStyle(
            color: Colors.black
          ),
          textAlign: TextAlign.center,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(30),
            bottomRight: Radius.circular(30),
          )
        ),
      ),
      body: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          physics: const ScrollPhysics(),
          child: Column(
            children: [
              Container(
                alignment: Alignment.topLeft,
                margin: EdgeInsets.only(top: 10, left: 10, right: 10),
                child: Text('Cobagage est éditée par ANKK.'),
              ),
              Container(
                alignment: Alignment.topLeft,
                margin: EdgeInsets.only(top: 10, left: 10, right: 10),
                child: Text('Le terme Application s\'applique à l\'application pour mobile nommée « Cobagage ».'),
              ),
              Container(
                alignment: Alignment.topLeft,
                margin: EdgeInsets.only(top: 20, left: 10, right: 10),
                child: Text('Données personnelles',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                alignment: Alignment.topLeft,
                margin: EdgeInsets.only(left: 10, right: 10),
                child: Text('Depuis notre Application, nous ne collectons aucune donnée personnelle (par exemple: '
                    'les noms, les adresses, les numéros de téléphone, les adresses de courrier électronique ou '
                    'les adresses IP complètes).'),
              ),
              Container(
                alignment: Alignment.topLeft,
                margin: EdgeInsets.only(top: 20, left: 10, right: 10),
                child: Text('Contenu des marchandises',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                    color: Colors.red
                  ),
                ),
              ),
              Container(
                alignment: Alignment.topLeft,
                margin: EdgeInsets.only(left: 10, right: 10),
                child: Text.rich(
                    TextSpan(
                        text: 'Les marchandises ou colis transmis à un voyageur ne doivent en aucun cas contenir ',
                        //style: TextStyle(fontWeight: FontWeight.bold),
                        children: <TextSpan>[
                          TextSpan(text: 'de substances illicites',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(text: ' telles que la ',
                            style: TextStyle(fontWeight: FontWeight.normal),
                          ),
                          TextSpan(text: 'DROGUE',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(text: ' ou tout autre ',
                            style: TextStyle(fontWeight: FontWeight.normal),
                          ),
                          TextSpan(text: 'objet proscrit',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(text: ' par les lois des pays par lesquels '
                              'transiteront les marchandises.',
                            style: TextStyle(fontWeight: FontWeight.normal),
                          )
                        ]
                    ),
                  )
              ),
              Container(
                alignment: Alignment.topLeft,
                margin: EdgeInsets.only(top: 20, left: 10, right: 10),
                child: Text('Moyen de paiement',
                  style: TextStyle(
                      fontWeight: FontWeight.bold
                  ),
                ),
              ),
              Container(
                  alignment: Alignment.topLeft,
                  margin: EdgeInsets.only(left: 10, right: 10),
                  child: Text.rich(
                    TextSpan(
                        text: 'Compte tenu du faible taux de bancarisation en  ',
                        //style: TextStyle(fontWeight: FontWeight.bold),
                        children: <TextSpan>[
                          TextSpan(text: 'Afrique Subsaharienne',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(text: ', le principal moyen de paiement utilisé, sera ',
                            style: TextStyle(fontWeight: FontWeight.normal),
                          ),
                          TextSpan(text: 'WAVE',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(text: '. Il faudra donc disposer d\'une application WAVE installée pour '
                              'faciliter le ',
                            style: TextStyle(fontWeight: FontWeight.normal),
                          ),
                          TextSpan(text: 'paiement des transactions',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(text: ' qui le nécessiteront.',
                            style: TextStyle(fontWeight: FontWeight.normal),
                          )
                        ]
                    ),
                  )
              ),
              Visibility(
                visible: widget.action == 0 ? true : false,
                child: Container(
                    alignment: Alignment.topRight,
                    margin: EdgeInsets.only(top: 30, left: 10, right: 10),
                    child: ElevatedButton.icon(
                      style: ButtonStyle(
                          backgroundColor: MaterialStateColor.resolveWith((states) => Colors.brown)
                      ),
                      label: const Text("Valider",
                          style: TextStyle(
                              color: Colors.white
                          )
                      ),
                      onPressed: () async {
                        // Persist DATA :
                        Parameters? prms = await _parametersController.refreshData();
                        prms = Parameters(id: prms!.id,
                            state: prms.state,
                            travellocal: prms.travellocal,
                            travelabroad: prms.travelabroad,
                            notification: prms.notification,
                            epochdebut: prms.epochdebut,
                            epochfin: prms.epochfin,
                            comptevalide: prms.comptevalide,
                            deviceregistered: prms.deviceregistered,
                            privacypolicy: 1
                        );
                        await _parametersController.updateData(prms);

                        // Open the MAIN INTERFACE :
                        openApp();
                      },
                      icon: const Icon(
                        Icons.check_circle_outline,
                        size: 20,
                        color: Colors.white,
                      ),
                    )
                )
              )
            ],
          )
      )
    );
  }
}
