import 'package:flutter/material.dart';

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

class KartBilgisi {
  KartBilgisi({
    required this.id,
    required this.bankaAdi,
    required this.baslangicBorc,
    required this.kalanBorc,
    required this.kartLimiti,
    required this.ekstreTarihi,
    required this.sonOdemeTarihi,
  });

  final int id;
  String bankaAdi;
  double baslangicBorc;
  double kalanBorc;
  double kartLimiti;
  DateTime ekstreTarihi;
  DateTime sonOdemeTarihi;
}

class OdemeKaydi {
  OdemeKaydi({
    required this.id,
    required this.kartId,
    required this.bankaAdi,
    required this.tutar,
    required this.tarih,
  });

  final int id;
  final int kartId;
  final String bankaAdi;
  final double tutar;
  final DateTime tarih;
}

class AnaUygulama extends StatefulWidget {
  const AnaUygulama({super.key});

  @override
  State<AnaUygulama> createState() => _AnaUygulamaState();
}

class _AnaUygulamaState extends State<AnaUygulama> {
  int seciliSayfa = 0;
  int siradakiKartId = 1;
  int siradakiOdemeId = 1;

  final List<KartBilgisi> kartlar = [];
  final List<OdemeKaydi> odemeler = [];

  double get toplamBaslangicBorc {
    return kartlar.fold(
      0,
      (toplam, kart) => toplam + kart.baslangicBorc,
    );
  }

  double get toplamKalanBorc {
    return kartlar.fold(
      0,
      (toplam, kart) => toplam + kart.kalanBorc,
    );
  }

  double get toplamOdenen {
    return odemeler.fold(
      0,
      (toplam, odeme) => toplam + odeme.tutar,
    );
  }

  double get tamamlanmaOrani {
    if (toplamBaslangicBorc <= 0) return 0;

    final oran = toplamOdenen / toplamBaslangicBorc;
    return oran.clamp(0, 1).toDouble();
  }

  String paraYaz(double tutar) {
    final negatif = tutar < 0;
    final mutlakTutar = tutar.abs();

    final metin = mutlakTutar.toStringAsFixed(2);
    final parcalar = metin.split('.');
    final tamKisim = parcalar[0];
    final ondalik = parcalar[1];

    final ters = tamKisim.split('').reversed.toList();
    final gruplu = <String>[];

    for (int i = 0; i < ters.length; i++) {
      if (i > 0 && i % 3 == 0) {
        gruplu.add('.');
      }
      gruplu.add(ters[i]);
    }

    final sonuc = '${gruplu.reversed.join()},$ondalik TL';
    return negatif ? '-$sonuc' : sonuc;
  }

  String tarihYaz(DateTime tarih) {
    final gun = tarih.day.toString().padLeft(2, '0');
    final ay = tarih.month.toString().padLeft(2, '0');

    return '$gun/$ay/${tarih.year}';
  }

  String tarihSaatYaz(DateTime tarih) {
    final gun = tarih.day.toString().padLeft(2, '0');
    final ay = tarih.month.toString().padLeft(2, '0');
    final saat = tarih.hour.toString().padLeft(2, '0');
    final dakika = tarih.minute.toString().padLeft(2, '0');

    return '$gun/$ay/${tarih.year} - $saat:$dakika';
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

  int kalanGunSayisi(DateTime tarih) {
    final bugun = DateTime.now();
    final temizBugun = DateTime(
      bugun.year,
      bugun.month,
      bugun.day,
    );

    final temizTarih = DateTime(
      tarih.year,
      tarih.month,
      tarih.day,
    );

    return temizTarih.difference(temizBugun).inDays;
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

  Future<void> kartFormunuAc({
    KartBilgisi? mevcutKart,
  }) async {
    final bankaController = TextEditingController(
      text: mevcutKart?.bankaAdi ?? '',
    );

    final borcController = TextEditingController(
      text: mevcutKart == null
          ? ''
          : mevcutKart.baslangicBorc
              .toStringAsFixed(2)
              .replaceAll('.', ','),
    );

    final limitController = TextEditingController(
      text: mevcutKart == null
          ? ''
          : mevcutKart.kartLimiti
              .toStringAsFixed(2)
              .replaceAll('.', ','),
    );

    DateTime? ekstreTarihi = mevcutKart?.ekstreTarihi;
    DateTime? sonOdemeTarihi = mevcutKart?.sonOdemeTarihi;
    String? hataMesaji;

    final kaydedildi = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            Future<void> tarihSec({
              required bool ekstreMi,
            }) async {
              final secilenTarih = await showDatePicker(
                context: context,
                initialDate: ekstreMi
                    ? (ekstreTarihi ?? DateTime.now())
                    : (sonOdemeTarihi ?? DateTime.now()),
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );

              if (secilenTarih == null) return;

              dialogSetState(() {
                if (ekstreMi) {
                  ekstreTarihi = secilenTarih;
                } else {
                  sonOdemeTarihi = secilenTarih;
                }
              });
            }

            void formuKaydet() {
              final bankaAdi = bankaController.text.trim();
              final toplamBorc = sayiyaCevir(
                borcController.text,
              );
              final kartLimiti = sayiyaCevir(
                limitController.text,
              );

              if (bankaAdi.isEmpty) {
                dialogSetState(() {
                  hataMesaji = 'Banka veya kart adını yazın.';
                });
                return;
              }

              if (toplamBorc == null || toplamBorc < 0) {
                dialogSetState(() {
                  hataMesaji = 'Geçerli bir borç girin.';
                });
                return;
              }

              if (kartLimiti == null || kartLimiti < 0) {
                dialogSetState(() {
                  hataMesaji = 'Geçerli bir kart limiti girin.';
                });
                return;
              }

              if (ekstreTarihi == null) {
                dialogSetState(() {
                  hataMesaji = 'Ekstre tarihini seçin.';
                });
                return;
              }

              if (sonOdemeTarihi == null) {
                dialogSetState(() {
                  hataMesaji = 'Son ödeme tarihini seçin.';
                });
                return;
              }

              Navigator.of(dialogContext).pop(true);
            }

            return AlertDialog(
              title: Text(
                mevcutKart == null
                    ? 'Kart Ekle'
                    : 'Kartı Düzenle',
              ),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: bankaController,
                        textCapitalization:
                            TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Banka veya kart adı',
                          prefixIcon:
                              Icon(Icons.account_balance),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: borcController,
                        keyboardType:
                            const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Toplam borç',
                          suffixText: 'TL',
                          prefixIcon:
                              Icon(Icons.payments_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: limitController,
                        keyboardType:
                            const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Kart limiti',
                          suffixText: 'TL',
                          prefixIcon:
                              Icon(Icons.credit_card),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading:
                            const Icon(Icons.receipt_long),
                        title:
                            const Text('Ekstre kesim tarihi'),
                        subtitle: Text(
                          ekstreTarihi == null
                              ? 'Tarih seçilmedi'
                              : tarihYaz(ekstreTarihi!),
                        ),
                        trailing:
                            const Icon(Icons.calendar_month),
                        onTap: () {
                          tarihSec(ekstreMi: true);
                        },
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading:
                            const Icon(Icons.event_available),
                        title:
                            const Text('Son ödeme tarihi'),
                        subtitle: Text(
                          sonOdemeTarihi == null
                              ? 'Tarih seçilmedi'
                              : tarihYaz(sonOdemeTarihi!),
                        ),
                        trailing:
                            const Icon(Icons.calendar_month),
                        onTap: () {
                          tarihSec(ekstreMi: false);
                        },
                      ),
                      if (hataMesaji != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          hataMesaji!,
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(false);
                  },
                  child: const Text('İptal'),
                ),
                FilledButton.icon(
                  onPressed: formuKaydet,
                  icon: const Icon(Icons.save),
                  label: const Text('Kaydet'),
                ),
              ],
            );
          },
        );
      },
    );

    if (kaydedildi == true) {
      final yeniBorc = sayiyaCevir(
        borcController.text,
      )!;

      final yeniLimit = sayiyaCevir(
        limitController.text,
      )!;

      if (!mounted) return;

      setState(() {
        if (mevcutKart == null) {
          kartlar.add(
            KartBilgisi(
              id: siradakiKartId++,
              bankaAdi: bankaController.text.trim(),
              baslangicBorc: yeniBorc,
              kalanBorc: yeniBorc,
              kartLimiti: yeniLimit,
              ekstreTarihi: ekstreTarihi!,
              sonOdemeTarihi: sonOdemeTarihi!,
            ),
          );
        } else {
          final dahaOnceOdenen =
              mevcutKart.baslangicBorc -
                  mevcutKart.kalanBorc;

          mevcutKart.bankaAdi =
              bankaController.text.trim();

          mevcutKart.baslangicBorc = yeniBorc;

          mevcutKart.kalanBorc =
              (yeniBorc - dahaOnceOdenen)
                  .clamp(0, yeniBorc)
                  .toDouble();

          mevcutKart.kartLimiti = yeniLimit;
          mevcutKart.ekstreTarihi = ekstreTarihi!;
          mevcutKart.sonOdemeTarihi =
              sonOdemeTarihi!;
        }
      });
    }
  }

  Future<void> kartSil(KartBilgisi kart) async {
    final onaylandi = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Kart silinsin mi?'),
          content: Text(
            '${kart.bankaAdi} ve bu karta ait ödeme geçmişi silinecek.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Sil'),
            ),
          ],
        );
      },
    );

    if (onaylandi == true) {
      setState(() {
        kartlar.removeWhere(
          (eleman) => eleman.id == kart.id,
        );

        odemeler.removeWhere(
          (odeme) => odeme.kartId == kart.id,
        );
      });
    }
  }

  String? odemeEkle({
    required int kartId,
    required double tutar,
  }) {
    KartBilgisi? secilenKart;

    for (final kart in kartlar) {
      if (kart.id == kartId) {
        secilenKart = kart;
        break;
      }
    }

    if (secilenKart == null) {
      return 'Seçilen kart bulunamadı.';
    }

    if (tutar <= 0) {
      return 'Ödeme tutarı sıfırdan büyük olmalıdır.';
    }

    if (secilenKart.kalanBorc <= 0) {
      return 'Bu kartın borcu zaten tamamlanmış.';
    }

    if (tutar > secilenKart.kalanBorc) {
      return 'Ödeme tutarı kalan borçtan fazla olamaz.';
    }

    setState(() {
      secilenKart!.kalanBorc -= tutar;

      if (secilenKart.kalanBorc < 0.01) {
        secilenKart.kalanBorc = 0;
      }

      odemeler.insert(
        0,
        OdemeKaydi(
          id: siradakiOdemeId++,
          kartId: secilenKart.id,
          bankaAdi: secilenKart.bankaAdi,
          tutar: tutar,
          tarih: DateTime.now(),
        ),
      );
    });

    return null;
  }

  Future<void> odemeSil(OdemeKaydi odeme) async {
    final onaylandi = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Ödeme silinsin mi?'),
          content: Text(
            '${odeme.bankaAdi} için yapılan '
            '${paraYaz(odeme.tutar)} ödeme silinecek.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Sil'),
            ),
          ],
        );
      },
    );

    if (onaylandi != true) return;

    KartBilgisi? kart;

    for (final eleman in kartlar) {
      if (eleman.id == odeme.kartId) {
        kart = eleman;
        break;
      }
    }

    setState(() {
      if (kart != null) {
        kart!.kalanBorc += odeme.tutar;

        if (kart!.kalanBorc >
            kart!.baslangicBorc) {
          kart!.kalanBorc =
              kart!.baslangicBorc;
        }
      }

      odemeler.removeWhere(
        (eleman) => eleman.id == odeme.id,
      );
    });
  }

  void kartDetayiniAc(KartBilgisi kart) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        final kullanilabilirLimit =
            kart.kartLimiti - kart.kalanBorc;

        final odenen =
            kart.baslangicBorc - kart.kalanBorc;

        final oran = kart.baslangicBorc <= 0
            ? 0.0
            : (odenen / kart.baslangicBorc)
                .clamp(0, 1)
                .toDouble();

        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    kart.bankaAdi,
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 18),
                  DetaySatiri(
                    baslik: 'Başlangıç borcu',
                    deger: paraYaz(kart.baslangicBorc),
                  ),
                  DetaySatiri(
                    baslik: 'Toplam ödenen',
                    deger: paraYaz(odenen),
                  ),
                  DetaySatiri(
                    baslik: 'Kalan borç',
                    deger: paraYaz(kart.kalanBorc),
                  ),
                  DetaySatiri(
                    baslik: 'Kart limiti',
                    deger: paraYaz(kart.kartLimiti),
                  ),
                  DetaySatiri(
                    baslik: 'Kullanılabilir limit',
                    deger: paraYaz(kullanilabilirLimit),
                  ),
                  DetaySatiri(
                    baslik: 'Ekstre kesim tarihi',
                    deger: tarihYaz(kart.ekstreTarihi),
                  ),
                  DetaySatiri(
                    baslik: 'Son ödeme tarihi',
                    deger:
                        tarihYaz(kart.sonOdemeTarihi),
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: oran,
                    minHeight: 12,
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tamamlanma: '
                    '%${(oran * 100).toStringAsFixed(1)}',
                  ),
                  const SizedBox(height: 12),
                  Text(
                    sonOdemeMesaji(
                      kart.sonOdemeTarihi,
                    ),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: kalanGunSayisi(
                                kart.sonOdemeTarihi,
                              ) <=
                              3
                          ? Theme.of(context)
                              .colorScheme
                              .error
                          : Theme.of(context)
                              .colorScheme
                              .primary,
                    ),
                  ),
                  const SizedBox(height: 18),
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
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        kartFormunuAc(
                          mevcutKart: kart,
                        );
                      },
                      icon: const Icon(Icons.edit),
                      label:
                          const Text('Kartı Düzenle'),
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
    final sayfalar = [
      AnaSayfa(
        kartlar: kartlar,
        toplamBaslangicBorc:
            toplamBaslangicBorc,
        toplamOdenen: toplamOdenen,
        toplamKalanBorc: toplamKalanBorc,
        tamamlanmaOrani: tamamlanmaOrani,
        paraYaz: paraYaz,
        tarihYaz: tarihYaz,
        sonOdemeMesaji: sonOdemeMesaji,
        kartaTiklandi: kartDetayiniAc,
      ),
      KartlarSayfasi(
        kartlar: kartlar,
        paraYaz: paraYaz,
        tarihYaz: tarihYaz,
        kartEkle: () {
          kartFormunuAc();
        },
        kartDuzenle: (kart) {
          kartFormunuAc(
            mevcutKart: kart,
          );
        },
        kartSil: kartSil,
        kartaTiklandi: kartDetayiniAc,
      ),
      OdemeYapSayfasi(
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
      const AyarlarSayfasi(),
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
              onPressed: () {
                kartFormunuAc();
              },
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
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Ana Sayfa',
          ),
          NavigationDestination(
            icon: Icon(Icons.credit_card_outlined),
            selectedIcon: Icon(Icons.credit_card),
            label: 'Kartlar',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_card_outlined),
            selectedIcon: Icon(Icons.add_card),
            label: 'Ödeme',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Geçmiş',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
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
    required this.toplamBaslangicBorc,
    required this.toplamOdenen,
    required this.toplamKalanBorc,
    required this.tamamlanmaOrani,
    required this.paraYaz,
    required this.tarihYaz,
    required this.sonOdemeMesaji,
    required this.kartaTiklandi,
  });

  final List<KartBilgisi> kartlar;
  final double toplamBaslangicBorc;
  final double toplamOdenen;
  final double toplamKalanBorc;
  final double tamamlanmaOrani;
  final String Function(double) paraYaz;
  final String Function(DateTime) tarihYaz;
  final String Function(DateTime) sonOdemeMesaji;
  final void Function(KartBilgisi) kartaTiklandi;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        OzetKarti(
          baslik: 'Toplam Borç',
          tutar: paraYaz(toplamBaslangicBorc),
          ikon: Icons.account_balance_wallet,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OzetKarti(
                baslik: 'Ödenen',
                tutar: paraYaz(toplamOdenen),
                ikon: Icons.check_circle_outline,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OzetKarti(
                baslik: 'Kalan',
                tutar: paraYaz(toplamKalanBorc),
                ikon: Icons.pending_actions,
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        const Text(
          'Borç Durumu',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        LinearProgressIndicator(
          value: tamamlanmaOrani,
          minHeight: 12,
          borderRadius: BorderRadius.circular(12),
        ),
        const SizedBox(height: 8),
        Text(
          'Tamamlanma: '
          '%${(tamamlanmaOrani * 100).toStringAsFixed(1)}',
        ),
        const SizedBox(height: 24),
        const Text(
          'Kartlar',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (kartlar.isEmpty)
          const BosKartBilgisi()
        else
          ...kartlar.map(
            (kart) {
              final odenen =
                  kart.baslangicBorc - kart.kalanBorc;

              final oran = kart.baslangicBorc <= 0
                  ? 0.0
                  : (odenen / kart.baslangicBorc)
                      .clamp(0, 1)
                      .toDouble();

              return Card(
                child: ListTile(
                  onTap: () {
                    kartaTiklandi(kart);
                  },
                  leading: CircleAvatar(
                    child: kart.kalanBorc <= 0
                        ? const Icon(Icons.check)
                        : const Icon(
                            Icons.account_balance,
                          ),
                  ),
                  title: Text(
                    kart.bankaAdi,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        'Kalan: '
                        '${paraYaz(kart.kalanBorc)}',
                      ),
                      Text(
                        sonOdemeMesaji(
                          kart.sonOdemeTarihi,
                        ),
                      ),
                      const SizedBox(height: 7),
                      LinearProgressIndicator(
                        value: oran,
                        borderRadius:
                            BorderRadius.circular(8),
                      ),
                    ],
                  ),
                  isThreeLine: true,
                  trailing:
                      const Icon(Icons.chevron_right),
                ),
              );
            },
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
    required this.kartaTiklandi,
  });

  final List<KartBilgisi> kartlar;
  final String Function(double) paraYaz;
  final String Function(DateTime) tarihYaz;
  final VoidCallback kartEkle;
  final void Function(KartBilgisi) kartDuzenle;
  final void Function(KartBilgisi) kartSil;
  final void Function(KartBilgisi) kartaTiklandi;

  @override
  Widget build(BuildContext context) {
    if (kartlar.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.credit_card,
                size: 72,
              ),
              const SizedBox(height: 16),
              const Text(
                'Henüz kart eklenmedi',
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Kendi bankanızı veya kredi kartınızı ekleyin.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: kartEkle,
                icon: const Icon(Icons.add),
                label:
                    const Text('İlk Kartı Ekle'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding:
          const EdgeInsets.fromLTRB(16, 16, 16, 90),
      itemCount: kartlar.length,
      itemBuilder: (context, index) {
        final kart = kartlar[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            onTap: () {
              kartaTiklandi(kart);
            },
            leading: CircleAvatar(
              child: kart.kalanBorc <= 0
                  ? const Icon(Icons.check)
                  : const Icon(Icons.credit_card),
            ),
            title: Text(
              kart.bankaAdi,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              'Kalan borç: '
              '${paraYaz(kart.kalanBorc)}\n'
              'Limit: ${paraYaz(kart.kartLimiti)}\n'
              'Ekstre: '
              '${tarihYaz(kart.ekstreTarihi)}\n'
              'Son ödeme: '
              '${tarihYaz(kart.sonOdemeTarihi)}',
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (secim) {
                if (secim == 'duzenle') {
                  kartDuzenle(kart);
                }

                if (secim == 'sil') {
                  kartSil(kart);
                }
              },
              itemBuilder: (context) {
                return const [
                  PopupMenuItem(
                    value: 'duzenle',
                    child: Row(
                      children: [
                        Icon(Icons.edit),
                        SizedBox(width: 10),
                        Text('Düzenle'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'sil',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline),
                        SizedBox(width: 10),
                        Text('Sil'),
                      ],
                    ),
                  ),
                ];
              },
            ),
          ),
        );
      },
    );
  }
}

class OdemeYapSayfasi extends StatefulWidget {
  const OdemeYapSayfasi({
    super.key,
    required this.kartlar,
    required this.paraYaz,
    required this.sayiyaCevir,
    required this.odemeEkle,
  });

  final List<KartBilgisi> kartlar;
  final String Function(double) paraYaz;
  final double? Function(String) sayiyaCevir;

  final String? Function({
    required int kartId,
    required double tutar,
  }) odemeEkle;

  @override
  State<OdemeYapSayfasi> createState() =>
      _OdemeYapSayfasiState();
}

class _OdemeYapSayfasiState
    extends State<OdemeYapSayfasi> {
  int? seciliKartId;
  final tutarController = TextEditingController();

  @override
  void dispose() {
    tutarController.dispose();
    super.dispose();
  }

  KartBilgisi? get seciliKart {
    if (seciliKartId == null) return null;

    for (final kart in widget.kartlar) {
      if (kart.id == seciliKartId) {
        return kart;
      }
    }

    return null;
  }

  void odemeyiKaydet() {
    final tutar = widget.sayiyaCevir(
      tutarController.text,
    );

    if (seciliKartId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Önce bir kart seçin.'),
        ),
      );
      return;
    }

    if (tutar == null || tutar <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Geçerli bir ödeme tutarı girin.'),
        ),
      );
      return;
    }

    final hata = widget.odemeEkle(
      kartId: seciliKartId!,
      tutar: tutar,
    );

    if (hata != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(hata),
        ),
      );
      return;
    }

    tutarController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Ödeme başarıyla kaydedildi.',
        ),
      ),
    );

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (widget.kartlar.isEmpty) {
      return const BosSayfa(
        ikon: Icons.credit_card_off,
        baslik: 'Ödeme Yapılamıyor',
        aciklama:
            'Ödeme yapabilmek için önce Kartlar bölümünden bir kart ekleyin.',
      );
    }

    if (seciliKartId != null &&
        !widget.kartlar.any(
          (kart) => kart.id == seciliKartId,
        )) {
      seciliKartId = null;
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Icon(
          Icons.payments,
          size: 64,
        ),
        const SizedBox(height: 12),
        const Text(
          'Yeni Ödeme',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        DropdownButtonFormField<int>(
          value: seciliKartId,
          decoration: const InputDecoration(
            labelText: 'Ödeme yapılacak kart',
            border: OutlineInputBorder(),
            prefixIcon:
                Icon(Icons.account_balance),
          ),
          items: widget.kartlar.map(
            (kart) {
              return DropdownMenuItem<int>(
                value: kart.id,
                child: Text(kart.bankaAdi),
              );
            },
          ).toList(),
          onChanged: (deger) {
            setState(() {
              seciliKartId = deger;
            });
          },
        ),
        if (seciliKart != null) ...[
          const SizedBox(height: 14),
          Card(
            child: ListTile(
              leading:
                  const Icon(Icons.info_outline),
              title: const Text('Kalan borç'),
              subtitle: Text(
                widget.paraYaz(
                  seciliKart!.kalanBorc,
                ),
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 18),
        TextField(
          controller: tutarController,
          keyboardType:
              const TextInputType.numberWithOptions(
            decimal: true,
          ),
          decoration: const InputDecoration(
            labelText: 'Ödeme tutarı',
            suffixText: 'TL',
            prefixIcon:
                Icon(Icons.currency_lira),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: odemeyiKaydet,
          icon: const Icon(Icons.save),
          label: const Padding(
            padding: EdgeInsets.symmetric(
              vertical: 14,
            ),
            child: Text(
              'Ödemeyi Kaydet',
              style: TextStyle(fontSize: 17),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Ödeme tarihi ve saati otomatik olarak kaydedilir.',
          textAlign: TextAlign.center,
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

  final List<OdemeKaydi> odemeler;
  final String Function(double) paraYaz;
  final String Function(DateTime) tarihSaatYaz;
  final void Function(OdemeKaydi) odemeSil;

  @override
  Widget build(BuildContext context) {
    if (odemeler.isEmpty) {
      return const BosSayfa(
        ikon: Icons.history,
        baslik: 'Ödeme Geçmişi',
        aciklama:
            'Henüz ödeme yapılmadı. Yapılan ödemeler burada gösterilecek.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: odemeler.length,
      itemBuilder: (context, index) {
        final odeme = odemeler[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.payments),
            ),
            title: Text(
              odeme.bankaAdi,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              tarihSaatYaz(odeme.tarih),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  paraYaz(odeme.tutar),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    odemeSil(odeme);
                  },
                  icon:
                      const Icon(Icons.delete_outline),
                  tooltip: 'Ödemeyi sil',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class AyarlarSayfasi extends StatelessWidget {
  const AyarlarSayfasi({super.key});

  @override
  Widget build(BuildContext context) {
    return const BosSayfa(
      ikon: Icons.settings,
      baslik: 'Ayarlar',
      aciklama:
          'Kalıcı kayıt tamamlandıktan sonra maaş, bildirim ve görünüm ayarları buraya eklenecek.',
    );
  }
}

class OzetKarti extends StatelessWidget {
  const OzetKarti({
    super.key,
    required this.baslik,
    required this.tutar,
    required this.ikon,
  });

  final String baslik;
  final String tutar;
  final IconData ikon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(ikon, size: 30),
            const SizedBox(height: 8),
            Text(
              baslik,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              tutar,
              textAlign: TextAlign.center,
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

class DetaySatiri extends StatelessWidget {
  const DetaySatiri({
    super.key,
    required this.baslik,
    required this.deger,
  });

  final String baslik;
  final String deger;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(baslik),
          ),
          const SizedBox(width: 12),
          Text(
            deger,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class BosKartBilgisi extends StatelessWidget {
  const BosKartBilgisi({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.credit_card_off,
              size: 50,
              color:
                  Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            const Text(
              'Henüz kart eklenmedi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Kartlar bölümünden kendi kartınızı ekleyin.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class BosSayfa extends StatelessWidget {
  const BosSayfa({
    super.key,
    required this.ikon,
    required this.baslik,
    required this.aciklama,
  });

  final IconData ikon;
  final String baslik;
  final String aciklama;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(ikon, size: 72),
            const SizedBox(height: 16),
            Text(
              baslik,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              aciklama,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
