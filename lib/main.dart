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
          seedColor: const Color(0xFF123B73),
        ),
      ),
      home: const AnaUygulama(),
    );
  }
}

class Kart {
  Kart({
    required this.id,
    required this.banka,
    required this.baslangicBorc,
    required this.kalanBorc,
    required this.limit,
    required this.ekstre,
    required this.sonOdeme,
  });

  final int id;
  String banka;
  double baslangicBorc;
  double kalanBorc;
  double limit;
  DateTime ekstre;
  DateTime sonOdeme;

  Map<String, dynamic> toJson() => {
        'id': id,
        'banka': banka,
        'baslangicBorc': baslangicBorc,
        'kalanBorc': kalanBorc,
        'limit': limit,
        'ekstre': ekstre.toIso8601String(),
        'sonOdeme': sonOdeme.toIso8601String(),
      };

  factory Kart.fromJson(Map<String, dynamic> json) {
    return Kart(
      id: (json['id'] as num).toInt(),
      banka: json['banka'] as String,
      baslangicBorc: (json['baslangicBorc'] as num).toDouble(),
      kalanBorc: (json['kalanBorc'] as num).toDouble(),
      limit: (json['limit'] as num).toDouble(),
      ekstre: DateTime.parse(json['ekstre'] as String),
      sonOdeme: DateTime.parse(json['sonOdeme'] as String),
    );
  }
}

class Odeme {
  Odeme({
    required this.id,
    required this.kartId,
    required this.banka,
    required this.tutar,
    required this.tarih,
  });

  final int id;
  final int kartId;
  final String banka;
  final double tutar;
  final DateTime tarih;

  Map<String, dynamic> toJson() => {
        'id': id,
        'kartId': kartId,
        'banka': banka,
        'tutar': tutar,
        'tarih': tarih.toIso8601String(),
      };

  factory Odeme.fromJson(Map<String, dynamic> json) {
    return Odeme(
      id: (json['id'] as num).toInt(),
      kartId: (json['kartId'] as num).toInt(),
      banka: json['banka'] as String,
      tutar: (json['tutar'] as num).toDouble(),
      tarih: DateTime.parse(json['tarih'] as String),
    );
  }
}

class AnaUygulama extends StatefulWidget {
  const AnaUygulama({super.key});

  @override
  State<AnaUygulama> createState() => _AnaUygulamaState();
}

class _AnaUygulamaState extends State<AnaUygulama> {
  static const String _kayitAnahtari = 'yfp_verileri_v1';

  final List<Kart> kartlar = [];
  final List<Odeme> odemeler = [];

  int seciliSayfa = 0;
  int siradakiKartId = 1;
  int siradakiOdemeId = 1;
  bool yukleniyor = true;

  @override
  void initState() {
    super.initState();
    _verileriYukle();
  }

  Future<void> _verileriYukle() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final metin = prefs.getString(_kayitAnahtari);

      if (metin != null && metin.isNotEmpty) {
        final veri = jsonDecode(metin) as Map<String, dynamic>;

        kartlar
          ..clear()
          ..addAll(
            (veri['kartlar'] as List<dynamic>? ?? []).map(
              (e) => Kart.fromJson(
                Map<String, dynamic>.from(e as Map),
              ),
            ),
          );

        odemeler
          ..clear()
          ..addAll(
            (veri['odemeler'] as List<dynamic>? ?? []).map(
              (e) => Odeme.fromJson(
                Map<String, dynamic>.from(e as Map),
              ),
            ),
          );

        if (kartlar.isNotEmpty) {
          siradakiKartId =
              kartlar.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1;
        }

        if (odemeler.isNotEmpty) {
          siradakiOdemeId =
              odemeler.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1;
        }
      }
    } catch (_) {
      kartlar.clear();
      odemeler.clear();
    }

    if (!mounted) return;

    setState(() {
      yukleniyor = false;
    });
  }

  Future<void> _verileriKaydet() async {
    final prefs = await SharedPreferences.getInstance();

    final veri = {
      'kartlar': kartlar.map((e) => e.toJson()).toList(),
      'odemeler': odemeler.map((e) => e.toJson()).toList(),
    };

    await prefs.setString(_kayitAnahtari, jsonEncode(veri));
  }

  double get toplamBaslangicBorc =>
      kartlar.fold(0, (toplam, kart) => toplam + kart.baslangicBorc);

  double get toplamKalanBorc =>
      kartlar.fold(0, (toplam, kart) => toplam + kart.kalanBorc);

  double get toplamOdenen =>
      odemeler.fold(0, (toplam, odeme) => toplam + odeme.tutar);

  double get tamamlanmaOrani {
    if (toplamBaslangicBorc <= 0) return 0;
    return (toplamOdenen / toplamBaslangicBorc).clamp(0, 1).toDouble();
  }

  String paraYaz(double tutar) {
    final metin = tutar.abs().toStringAsFixed(2);
    final parcalar = metin.split('.');
    final tam = parcalar[0];
    final ondalik = parcalar[1];
    final ters = tam.split('').reversed.toList();
    final sonuc = <String>[];

    for (int i = 0; i < ters.length; i++) {
      if (i > 0 && i % 3 == 0) {
        sonuc.add('.');
      }
      sonuc.add(ters[i]);
    }

    final para = '${sonuc.reversed.join()},$ondalik TL';
    return tutar < 0 ? '-$para' : para;
  }

  String tarihYaz(DateTime tarih) {
    final gun = tarih.day.toString().padLeft(2, '0');
    final ay = tarih.month.toString().padLeft(2, '0');
    return '$gun/$ay/${tarih.year}';
  }

  String tarihSaatYaz(DateTime tarih) {
    final saat = tarih.hour.toString().padLeft(2, '0');
    final dakika = tarih.minute.toString().padLeft(2, '0');
    return '${tarihYaz(tarih)} - $saat:$dakika';
  }
    int kalanGunSayisi(DateTime tarih) {
    final simdi = DateTime.now();
    final bugun = DateTime(simdi.year, simdi.month, simdi.day);
    final hedef = DateTime(tarih.year, tarih.month, tarih.day);

    return hedef.difference(bugun).inDays;
  }

  String sonOdemeMesaji(DateTime tarih) {
    final kalanGun = kalanGunSayisi(tarih);

    if (kalanGun > 0) {
      return 'Son ödeme tarihine $kalanGun gün kaldı';
    }

    if (kalanGun == 0) {
      return 'Son ödeme tarihi bugün';
    }

    return 'Son ödeme tarihi ${kalanGun.abs()} gün geçti';
  }

  double? sayiyaCevir(String metin) {
    String temiz = metin.trim().replaceAll(' ', '');

    if (temiz.contains(',') && temiz.contains('.')) {
      temiz = temiz.replaceAll('.', '').replaceAll(',', '.');
    } else if (temiz.contains(',')) {
      temiz = temiz.replaceAll(',', '.');
    }

    return double.tryParse(temiz);
  }

  Future<void> kartFormunuAc({Kart? mevcutKart}) async {
    final bankaController =
        TextEditingController(text: mevcutKart?.banka ?? '');

    final borcController = TextEditingController(
      text: mevcutKart == null
          ? ''
          : mevcutKart.baslangicBorc.toStringAsFixed(2).replaceAll('.', ','),
    );

    final limitController = TextEditingController(
      text: mevcutKart == null
          ? ''
          : mevcutKart.limit.toStringAsFixed(2).replaceAll('.', ','),
    );

    DateTime? ekstre = mevcutKart?.ekstre;
    DateTime? sonOdeme = mevcutKart?.sonOdeme;
    String? hata;

    final kaydedildi = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            Future<void> tarihSec(bool ekstreMi) async {
              final secilen = await showDatePicker(
                context: context,
                initialDate: ekstreMi
                    ? (ekstre ?? DateTime.now())
                    : (sonOdeme ?? DateTime.now()),
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );

              if (secilen == null) return;

              dialogSetState(() {
                if (ekstreMi) {
                  ekstre = secilen;
                } else {
                  sonOdeme = secilen;
                }
              });
            }

            void kaydet() {
              final banka = bankaController.text.trim();
              final borc = sayiyaCevir(borcController.text);
              final limit = sayiyaCevir(limitController.text);

              if (banka.isEmpty) {
                dialogSetState(() => hata = 'Banka adını yazın.');
                return;
              }

              if (borc == null || borc < 0) {
                dialogSetState(() => hata = 'Geçerli bir borç girin.');
                return;
              }

              if (limit == null || limit < 0) {
                dialogSetState(() => hata = 'Geçerli bir limit girin.');
                return;
              }

              if (ekstre == null || sonOdeme == null) {
                dialogSetState(() => hata = 'İki tarihi de seçin.');
                return;
              }

              Navigator.of(dialogContext).pop(true);
            }

            return AlertDialog(
              title: Text(mevcutKart == null ? 'Kart Ekle' : 'Kartı Düzenle'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: bankaController,
                      decoration: const InputDecoration(
                        labelText: 'Banka veya kart adı',
                        prefixIcon: Icon(Icons.account_balance),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: borcController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Toplam borç',
                        suffixText: 'TL',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: limitController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Kart limiti',
                        suffixText: 'TL',
                      ),
                    ),
                    const SizedBox(height: 10),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Ekstre kesim tarihi'),
                      subtitle: Text(
                        ekstre == null ? 'Tarih seçilmedi' : tarihYaz(ekstre!),
                      ),
                      trailing: const Icon(Icons.calendar_month),
                      onTap: () => tarihSec(true),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Son ödeme tarihi'),
                      subtitle: Text(
                        sonOdeme == null
                            ? 'Tarih seçilmedi'
                            : tarihYaz(sonOdeme!),
                      ),
                      trailing: const Icon(Icons.calendar_month),
                      onTap: () => tarihSec(false),
                    ),
                    if (hata != null)
                      Text(
                        hata!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('İptal'),
                ),
                FilledButton(
                  onPressed: kaydet,
                  child: const Text('Kaydet'),
                ),
              ],
            );
          },
        );
      },
    );
        if (kaydedildi != true) return;

    final yeniBorc = sayiyaCevir(borcController.text)!;
    final yeniLimit = sayiyaCevir(limitController.text)!;

    setState(() {
      if (mevcutKart == null) {
        kartlar.add(
          Kart(
            id: siradakiKartId++,
            banka: bankaController.text.trim(),
            baslangicBorc: yeniBorc,
            kalanBorc: yeniBorc,
            limit: yeniLimit,
            ekstre: ekstre!,
            sonOdeme: sonOdeme!,
          ),
        );
      } else {
        final odenen =
            mevcutKart.baslangicBorc - mevcutKart.kalanBorc;

        mevcutKart.banka = bankaController.text.trim();
        mevcutKart.baslangicBorc = yeniBorc;
        mevcutKart.kalanBorc =
            (yeniBorc - odenen).clamp(0, yeniBorc).toDouble();
        mevcutKart.limit = yeniLimit;
        mevcutKart.ekstre = ekstre!;
        mevcutKart.sonOdeme = sonOdeme!;
      }
    });

    await _verileriKaydet();
  }

  Future<void> kartSil(Kart kart) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Kart silinsin mi?'),
          content: Text('${kart.banka} ve ödemeleri silinecek.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Sil'),
            ),
          ],
        );
      },
    );

    if (onay != true) return;

    setState(() {
      kartlar.removeWhere((e) => e.id == kart.id);
      odemeler.removeWhere((e) => e.kartId == kart.id);
    });

    await _verileriKaydet();
  }

  Future<String?> odemeEkle(int kartId, double tutar) async {
    Kart? kart;

    for (final eleman in kartlar) {
      if (eleman.id == kartId) {
        kart = eleman;
        break;
      }
    }

    if (kart == null) return 'Kart bulunamadı.';
    if (tutar <= 0) return 'Geçerli bir tutar girin.';
    if (tutar > kart.kalanBorc) {
      return 'Ödeme kalan borçtan fazla olamaz.';
    }

    setState(() {
      kart!.kalanBorc -= tutar;

      if (kart.kalanBorc < 0.01) {
        kart.kalanBorc = 0;
      }

      odemeler.insert(
        0,
        Odeme(
          id: siradakiOdemeId++,
          kartId: kart.id,
          banka: kart.banka,
          tutar: tutar,
          tarih: DateTime.now(),
        ),
      );
    });

    await _verileriKaydet();
    return null;
  }

  Future<void> odemeSil(Odeme odeme) async {
    Kart? kart;

    for (final eleman in kartlar) {
      if (eleman.id == odeme.kartId) {
        kart = eleman;
        break;
      }
    }

    setState(() {
      if (kart != null) {
        kart!.kalanBorc += odeme.tutar;

        if (kart.kalanBorc > kart.baslangicBorc) {
          kart.kalanBorc = kart.baslangicBorc;
        }
      }

      odemeler.removeWhere((e) => e.id == odeme.id);
    });

    await _verileriKaydet();
  }
  void kartDetayiniAc(Kart kart) {
    final toplamOdenen = kart.baslangicBorc - kart.kalanBorc;
    final kullanilabilirLimit = kart.limit - kart.kalanBorc;

    final oran = kart.baslangicBorc <= 0
        ? 0.0
        : (toplamOdenen / kart.baslangicBorc)
            .clamp(0, 1)
            .toDouble();

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    kart.banka,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  ListTile(
                    title: const Text('Başlangıç borcu'),
                    trailing: Text(
                      paraYaz(kart.baslangicBorc),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  ListTile(
                    title: const Text('Toplam ödenen'),
                    trailing: Text(
                      paraYaz(toplamOdenen),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  ListTile(
                    title: const Text('Kalan borç'),
                    trailing: Text(
                      paraYaz(kart.kalanBorc),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  ListTile(
                    title: const Text('Kart limiti'),
                    trailing: Text(
                      paraYaz(kart.limit),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  ListTile(
                    title: const Text('Kullanılabilir limit'),
                    trailing: Text(
                      paraYaz(kullanilabilirLimit),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  ListTile(
                    title: const Text('Ekstre kesim tarihi'),
                    trailing: Text(
                      tarihYaz(kart.ekstre),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  ListTile(
                    title: const Text('Son ödeme tarihi'),
                    trailing: Text(
                      tarihYaz(kart.sonOdeme),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  LinearProgressIndicator(
                    value: oran,
                    minHeight: 12,
                    borderRadius: BorderRadius.circular(12),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Tamamlanma: %${(oran * 100).toStringAsFixed(1)}',
                  ),

                  const SizedBox(height: 14),

                  Text(
                    sonOdemeMesaji(kart.sonOdeme),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: kalanGunSayisi(kart.sonOdeme) <= 3
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(context);

                        setState(() {
                          seciliSayfa = 2;
                        });
                      },
                      icon: const Icon(Icons.payments),
                      label: const Text('Ödeme Yap'),
                    ),
                  ),

                  const SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        kartFormunuAc(mevcutKart: kart);
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Kartı Düzenle'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (yukleniyor) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final sayfalar = [
      AnaSayfa(
        kartlar: kartlar,
        toplamBorc: toplamBaslangicBorc,
        odenen: toplamOdenen,
        kalan: toplamKalanBorc,
        oran: tamamlanmaOrani,
        paraYaz: paraYaz,
      ),
      KartlarSayfasi(
        kartlar: kartlar,
        paraYaz: paraYaz,
        tarihYaz: tarihYaz,
        kartEkle: () => kartFormunuAc(),
        kartDuzenle: (kart) => kartFormunuAc(mevcutKart: kart),
        kartSil: kartSil,
      ),
      OdemeSayfasi(
        kartlar: kartlar,
        paraYaz: paraYaz,
        sayiyaCevir: sayiyaCevir,
        odemeEkle: odemeEkle,
      ),
      GecmisSayfasi(
        odemeler: odemeler,
        paraYaz: paraYaz,
        tarihSaatYaz: tarihSaatYaz,
        odemeSil: odemeSil,
      ),
      const Center(
        child: Text('Ayarlar'),
      ),
    ];

    const basliklar = [
      'YFP Finans',
      'Kartlar',
      'Ödeme Yap',
      'Geçmiş',
      'Ayarlar',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          basliklar[seciliSayfa],
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: IndexedStack(
        index: seciliSayfa,
        children: sayfalar,
      ),
      floatingActionButton: seciliSayfa == 1
          ? FloatingActionButton.extended(
              onPressed: () => kartFormunuAc(),
              icon: const Icon(Icons.add),
              label: const Text('Kart Ekle'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: seciliSayfa,
        onDestinationSelected: (index) {
          setState(() {
            seciliSayfa = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home),
            label: 'Ana Sayfa',
          ),
          NavigationDestination(
            icon: Icon(Icons.credit_card),
            label: 'Kartlar',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_card),
            label: 'Ödeme',
          ),
          NavigationDestination(
            icon: Icon(Icons.history),
            label: 'Geçmiş',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            label: 'Ayarlar',
          ),
        ],
      ),
    );
  }
}

class AnaSayfa extends StatelessWidget {
  const AnaSayfa({
    super.key,
    required this.kartlar,
    required this.toplamBorc,
    required this.odenen,
    required this.kalan,
    required this.oran,
    required this.paraYaz,
    required this.kartaTiklandi,
  });

  final List<Kart> kartlar;
  final double toplamBorc;
  final double odenen;
  final double kalan;
  final double oran;
  final String Function(double) paraYaz;
  final void Function(Kart) kartaTiklandi;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _OzetKarti(
          baslik: 'Toplam Borç',
          tutar: paraYaz(toplamBorc),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _OzetKarti(
                baslik: 'Ödenen',
                tutar: paraYaz(odenen),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _OzetKarti(
                baslik: 'Kalan',
                tutar: paraYaz(kalan),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          'Borç Durumu',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        LinearProgressIndicator(
          value: oran,
          minHeight: 12,
          borderRadius: BorderRadius.circular(12),
        ),
        const SizedBox(height: 8),
        Text(
          'Tamamlanma: %${(oran * 100).toStringAsFixed(1)}',
        ),
        const SizedBox(height: 20),
        const Text(
          'Kartlar',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        if (kartlar.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Henüz kart eklenmedi.',
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          ...kartlar.map(
            (kart) => Card(
              child: ListTile(
                onTap: () => kartaTiklandi(kart),
                leading: const CircleAvatar(
                  child: Icon(Icons.account_balance),
                ),
                title: Text(kart.banka),
                subtitle: Text(
                  'Kalan: ${paraYaz(kart.kalanBorc)}',
                ),
              ),
            ),
          ),
      ],
    );
  }
}
class KartlarSayfasi extends StatelessWidget {
  const KartlarSayfasi({
    super.key,
    required this.kartlar,
    required this.paraYaz,
    required this.tarihYaz,
    required this.kartEkle,
    required this.kartDuzenle,
    required this.kartSil,
  });

  final List<Kart> kartlar;
  final String Function(double) paraYaz;
  final String Function(DateTime) tarihYaz;
  final VoidCallback kartEkle;
  final void Function(Kart) kartDuzenle;
  final void Function(Kart) kartSil;

  @override
  Widget build(BuildContext context) {
    if (kartlar.isEmpty) {
      return Center(
        child: FilledButton.icon(
          onPressed: kartEkle,
          icon: const Icon(Icons.add),
          label: const Text('İlk Kartı Ekle'),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      itemCount: kartlar.length,
      itemBuilder: (context, index) {
        final kart = kartlar[index];

        return Card(
          child: ListTile(
            title: Text(kart.banka),
            subtitle: Text(
              'Kalan: ${paraYaz(kart.kalanBorc)}\n'
              'Limit: ${paraYaz(kart.limit)}\n'
              'Ekstre: ${tarihYaz(kart.ekstre)}\n'
              'Son ödeme: ${tarihYaz(kart.sonOdeme)}',
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (secim) {
                if (secim == 'duzenle') {
                  kartDuzenle(kart);
                } else {
                  kartSil(kart);
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'duzenle',
                  child: Text('Düzenle'),
                ),
                PopupMenuItem(
                  value: 'sil',
                  child: Text('Sil'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class OdemeSayfasi extends StatefulWidget {
  const OdemeSayfasi({
    super.key,
    required this.kartlar,
    required this.paraYaz,
    required this.sayiyaCevir,
    required this.odemeEkle,
  });

  final List<Kart> kartlar;
  final String Function(double) paraYaz;
  final double? Function(String) sayiyaCevir;
  final Future<String?> Function(
    int kartId,
    double tutar,
  ) odemeEkle;

  @override
  State<OdemeSayfasi> createState() => _OdemeSayfasiState();
}

class _OdemeSayfasiState extends State<OdemeSayfasi> {
  int? seciliKartId;
  final tutarController = TextEditingController();

  @override
  void dispose() {
    tutarController.dispose();
    super.dispose();
  }

  Kart? get seciliKart {
    for (final kart in widget.kartlar) {
      if (kart.id == seciliKartId) {
        return kart;
      }
    }

    return null;
  }

  Future<void> odemeyiKaydet() async {
    final tutar = widget.sayiyaCevir(
      tutarController.text,
    );

    if (seciliKartId == null || tutar == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kart ve tutar girin.'),
        ),
      );
      return;
    }

    final hata = await widget.odemeEkle(
      seciliKartId!,
      tutar,
    );

    if (!mounted) return;

    if (hata != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(hata),
        ),
      );
      return;
    }

    tutarController.clear();
    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ödeme kaydedildi.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.kartlar.isEmpty) {
      return const Center(
        child: Text(
          'Ödeme için önce kart ekleyin.',
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        DropdownButtonFormField<int>(
          value: seciliKartId,
          decoration: const InputDecoration(
            labelText: 'Ödeme yapılacak kart',
            border: OutlineInputBorder(),
          ),
          items: widget.kartlar
              .map(
                (kart) => DropdownMenuItem<int>(
                  value: kart.id,
                  child: Text(kart.banka),
                ),
              )
              .toList(),
          onChanged: (deger) {
            setState(() {
              seciliKartId = deger;
            });
          },
        ),
        if (seciliKart != null) ...[
          const SizedBox(height: 12),
          Text(
            'Kalan borç: '
            '${widget.paraYaz(seciliKart!.kalanBorc)}',
          ),
        ],
        const SizedBox(height: 12),
        TextField(
          controller: tutarController,
          keyboardType:
              const TextInputType.numberWithOptions(
            decimal: true,
          ),
          decoration: const InputDecoration(
            labelText: 'Ödeme tutarı',
            suffixText: 'TL',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: odemeyiKaydet,
          child: const Text('Ödemeyi Kaydet'),
        ),
      ],
    );
  }
}

class GecmisSayfasi extends StatelessWidget {
  const GecmisSayfasi({
    super.key,
    required this.odemeler,
    required this.paraYaz,
    required this.tarihSaatYaz,
    required this.odemeSil,
  });

  final List<Odeme> odemeler;
  final String Function(double) paraYaz;
  final String Function(DateTime) tarihSaatYaz;
  final void Function(Odeme) odemeSil;

  @override
  Widget build(BuildContext context) {
    if (odemeler.isEmpty) {
      return const Center(
        child: Text(
          'Henüz ödeme yapılmadı.',
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: odemeler.length,
      itemBuilder: (context, index) {
        final odeme = odemeler[index];

        return Card(
          child: ListTile(
            title: Text(odeme.banka),
            subtitle: Text(
              tarihSaatYaz(odeme.tarih),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  paraYaz(odeme.tutar),
                ),
                IconButton(
                  onPressed: () => odemeSil(odeme),
                  icon: const Icon(
                    Icons.delete_outline,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OzetKarti extends StatelessWidget {
  const _OzetKarti({
    required this.baslik,
    required this.tutar,
  });

  final String baslik;
  final String tutar;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(baslik),
            const SizedBox(height: 6),
            Text(
              tutar,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
