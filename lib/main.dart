import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const YFPApp());
}

class YFPApp extends StatelessWidget {
  const YFPApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'YFP Finans',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
        ),
      ),
      home: const AnaUygulama(),
    );
  }
}

class Kart {
  int id;
  String banka;
  double borc;
  double kalan;
  double limit;
  DateTime ekstre;
  DateTime sonOdeme;

  Kart({
    required this.id,
    required this.banka,
    required this.borc,
    required this.kalan,
    required this.limit,
    required this.ekstre,
    required this.sonOdeme,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'banka': banka,
      'borc': borc,
      'kalan': kalan,
      'limit': limit,
      'ekstre': ekstre.toIso8601String(),
      'sonOdeme': sonOdeme.toIso8601String(),
    };
  }

  factory Kart.fromJson(Map<String, dynamic> json) {
    return Kart(
      id: json['id'],
      banka: json['banka'],
      borc: json['borc'],
      kalan: json['kalan'],
      limit: json['limit'],
      ekstre: DateTime.parse(json['ekstre']),
      sonOdeme: DateTime.parse(json['sonOdeme']),
    );
  }
}

class Odeme {
  int id;
  int kartId;
  String banka;
  double tutar;
  DateTime tarih;

  Odeme({
    required this.id,
    required this.kartId,
    required this.banka,
    required this.tutar,
    required this.tarih,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'kartId': kartId,
      'banka': banka,
      'tutar': tutar,
      'tarih': tarih.toIso8601String(),
    };
  }

  factory Odeme.fromJson(Map<String, dynamic> json) {
    return Odeme(
      id: json['id'],
      kartId: json['kartId'],
      banka: json['banka'],
      tutar: json['tutar'],
      tarih: DateTime.parse(json['tarih']),
    );
  }
}

class AnaUygulama extends StatefulWidget {
  const AnaUygulama({super.key});

  @override
  State<AnaUygulama> createState() => _AnaUygulamaState();
}

class _AnaUygulamaState extends State<AnaUygulama> {

  static const String kayitAnahtari = "yfp_kayit";

  List<Kart> kartlar = [];
  List<Odeme> odemeler = [];

  int sayfa = 0;
  int kartId = 1;
  int odemeId = 1;

  @override
  void initState() {
    super.initState();
    yukle();
  }

  Future<void> yukle() async {

    final prefs = await SharedPreferences.getInstance();

    final veri = prefs.getString(kayitAnahtari);

    if(veri != null){

      final data = jsonDecode(veri);

      kartlar = (data['kartlar'] as List)
          .map((e)=>Kart.fromJson(e))
          .toList();

      odemeler = (data['odemeler'] as List)
          .map((e)=>Odeme.fromJson(e))
          .toList();
    }

    setState(() {});
  }

  Future<void> kaydet() async {

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      kayitAnahtari,
      jsonEncode({
        "kartlar":
        kartlar.map((e)=>e.toJson()).toList(),

        "odemeler":
        odemeler.map((e)=>e.toJson()).toList(),
      }),
    );
      double get toplamBorc =>
      kartlar.fold(0, (toplam, kart) => toplam + kart.borc);

  double get kalanBorc =>
      kartlar.fold(0, (toplam, kart) => toplam + kart.kalan);

  double get odenen =>
      toplamBorc - kalanBorc;


  String para(double deger){

    return "${deger.toStringAsFixed(2)} TL";
  }


  Future<void> kartEkle() async {

    final banka = TextEditingController();
    final borc = TextEditingController();
    final limit = TextEditingController();


    final sonuc = await showDialog<bool>(
      context: context,
      builder:(context){

        return AlertDialog(
          title: const Text("Kart Ekle"),

          content: Column(
            mainAxisSize: MainAxisSize.min,
            children:[

              TextField(
                controller:banka,
                decoration:
                const InputDecoration(
                  labelText:"Banka adı"
                ),
              ),

              TextField(
                controller:borc,
                keyboardType:
                TextInputType.number,
                decoration:
                const InputDecoration(
                  labelText:"Borç"
                ),
              ),

              TextField(
                controller:limit,
                keyboardType:
                TextInputType.number,
                decoration:
                const InputDecoration(
                  labelText:"Kart limiti"
                ),
              ),

            ],
          ),

          actions:[

            TextButton(
              onPressed:(){
                Navigator.pop(context,false);
              },
              child:
              const Text("İptal"),
            ),

            ElevatedButton(
              onPressed:(){

                kartlar.add(

                  Kart(
                    id:kartId++,
                    banka:banka.text,
                    borc:double.tryParse(borc.text) ?? 0,
                    kalan:double.tryParse(borc.text) ?? 0,
                    limit:double.tryParse(limit.text) ?? 0,
                    ekstre:DateTime.now(),
                    sonOdeme:DateTime.now(),
                  )

                );

                Navigator.pop(context,true);

              },
              child:
              const Text("Kaydet"),
            )

          ],
        );
      }
    );


    if(sonuc==true){

      await kaydet();

      setState((){});

    }

  }



  Future<void> odemeYap(Kart kart) async {


    final tutar =
    TextEditingController();


    final sonuc =
    await showDialog<bool>(

      context:context,

      builder:(context){

        return AlertDialog(

          title:
          Text("${kart.banka} Ödeme"),


          content:
          TextField(

            controller:tutar,

            keyboardType:
            TextInputType.number,

            decoration:
            const InputDecoration(
              labelText:"Ödeme tutarı"
            ),

          ),


          actions:[

            TextButton(
              onPressed:(){

                Navigator.pop(context,false);

              },

              child:
              const Text("İptal"),

            ),


            ElevatedButton(

              onPressed:(){

                double miktar =
                double.tryParse(tutar.text) ?? 0;


                if(miktar > 0 &&
                    miktar <= kart.kalan){

                  kart.kalan -= miktar;


                  odemeler.insert(

                    0,

                    Odeme(

                      id:odemeId++,

                      kartId:kart.id,

                      banka:kart.banka,

                      tutar:miktar,

                      tarih:DateTime.now(),

                    ),

                  );

                  Navigator.pop(context,true);

                }

              },

              child:
              const Text("Kaydet"),

            )

          ],

        );

      }

    );


    if(sonuc==true){

      await kaydet();

      setState((){});

    }

  }
      @override
  Widget build(BuildContext context){

    final sayfalar=[

      Column(
        children:[

          Card(
            child:ListTile(
              title:
              const Text("Toplam Borç"),

              subtitle:
              Text(para(toplamBorc)),
            ),
          ),

          Card(
            child:ListTile(
              title:
              const Text("Ödenen"),

              subtitle:
              Text(para(odenen)),
            ),
          ),

          Card(
            child:ListTile(
              title:
              const Text("Kalan Borç"),

              subtitle:
              Text(para(kalanBorc)),
            ),
          ),

        ],
      ),



      ListView(

        children:[

          ElevatedButton.icon(

            onPressed: kartEkle,

            icon:
            const Icon(Icons.add),

            label:
            const Text("Kart Ekle"),

          ),


          ...kartlar.map(

            (kart)=>Card(

              child:ListTile(

                title:
                Text(kart.banka),


                subtitle:
                Text(
                  "Kalan: ${para(kart.kalan)}"
                ),


                trailing:
                PopupMenuButton(

                  itemBuilder:(context)=>[

                    const PopupMenuItem(
                      value:1,
                      child:
                      Text("Ödeme Yap"),
                    )

                  ],


                  onSelected:(v){

                    odemeYap(kart);

                  },

                ),

              ),

            ),

          )

        ],

      ),




      ListView(

        children: odemeler.map(

          (odeme)=>Card(

            child:ListTile(

              title:
              Text(odeme.banka),


              subtitle:
              Text(
                para(odeme.tutar)
              ),


              trailing:
              Text(
                "${odeme.tarih.day}/"
                "${odeme.tarih.month}/"
                "${odeme.tarih.year}"
              ),

            ),

          ),

        ).toList(),

      ),




      const Center(

        child:
        Text(
          "Ayarlar"
        ),

      ),


    ];



    return Scaffold(

      appBar:
      AppBar(

        title:
        const Text(
          "YFP Finans"
        ),

      ),



      body:
      Padding(

        padding:
        const EdgeInsets.all(12),

        child:
        sayfalar[sayfa],

      ),



      bottomNavigationBar:

      NavigationBar(

        selectedIndex:
        sayfa,


        onDestinationSelected:(index){

          setState((){

            sayfa=index;

          });

        },


        destinations:
        const [

          NavigationDestination(

            icon:
            Icon(Icons.home),

            label:
            "Ana Sayfa",

          ),


          NavigationDestination(

            icon:
            Icon(Icons.credit_card),

            label:
            "Kartlar",

          ),


          NavigationDestination(

            icon:
            Icon(Icons.history),

            label:
            "Geçmiş",

          ),


          NavigationDestination(

            icon:
            Icon(Icons.settings),

            label:
            "Ayarlar",

          ),

        ],

      ),


    );

  }

}
  
