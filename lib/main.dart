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
    required this.toplamBorc,
    required this.kartLimiti,
    required this.ekstreTarihi,
    required this.sonOdemeTarihi,
  });

  final int id;
  String bankaAdi;
  double toplamBorc;
  double kartLimiti;
  DateTime ekstreTarihi;
  DateTime sonOdemeTarihi;
}

class AnaUygulama extends StatefulWidget {
  const AnaUygulama({super.key});

  @override
  State<AnaUygulama> createState() => _AnaUygulamaState();
}

class _AnaUygulamaState extends State<AnaUygulama> {
  int seciliSayfa = 0;
  int siradakiKartId = 1;

  final List<KartBilgisi> kartlar = [];

  double get toplamBorc {
    return kartlar.fold(
      0,
      (toplam, kart) => toplam + kart.toplamBorc,
    );
  }

  String paraYaz(double tutar) {
    final metin = tutar.toStringAsFixed(2);
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

    return '${gruplu.reversed.join()},$ondalik TL';
  }

  String tarihYaz(DateTime tarih) {
    final gun = tarih.day.toString().padLeft(2, '0');
    final ay = tarih.month.toString().padLeft(2, '0');
    return '$gun/$ay/${tarih.year}';
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

  Future<void> kartFormunuAc({KartBilgisi? mevcutKart}) async {
    final bankaController = TextEditingController(
      text: mevcutKart?.bankaAdi ?? '',
    );

    final borcController = TextEditingController(
      text: mevcutKart == null
          ? ''
          : mevcutKart.toplamBorc.toStringAsFixed(2).replaceAll('.', ','),
    );

    final limitController = TextEditingController(
      text: mevcutKart == null
          ? ''
          : mevcutKart.kartLimiti.toStringAsFixed(2).replaceAll('.', ','),
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
              final toplamBorc = sayiyaCevir(borcController.text);
              final kartLimiti = sayiyaCevir(limitController.text);

              if (bankaAdi.isEmpty) {
                dialogSetState(() {
                  hataMesaji = 'Banka veya kart adını yazın.';
                });
                return;
              }

              if (toplamBorc == null || toplamBorc < 0) {
                dialogSetState(() {
                  hataMesaji = 'Geçerli bir toplam borç girin.';
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
                  hataMesaji = 'Ekstre kesim tarihini seçin.';
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
                mevcutKart == null ? 'Kart Ekle' : 'Kartı Düzenle',
              ),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: bankaController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Banka veya kart adı',
                          prefixIcon: Icon(Icons.account_balance),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: borcController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Toplam borç',
                          suffixText: 'TL',
                          prefixIcon: Icon(Icons.payments_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: limitController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Kart limiti',
                          suffixText: 'TL',
                          prefixIcon: Icon(Icons.credit_card),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.receipt_long),
                        title: const Text('Ekstre kesim tarihi'),
                        subtitle: Text(
                          ekstreTarihi == null
                              ? 'Tarih seçilmedi'
                              : tarihYaz(ekstreTarihi!),
                        ),
                        trailing: const Icon(Icons.calendar_month),
                        onTap: () => tarihSec(ekstreMi: true),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.event_available),
                        title: const Text('Son ödeme tarihi'),
                        subtitle: Text(
                          sonOdemeTarihi == null
                              ? 'Tarih seçilmedi'
                              : tarihYaz(sonOdemeTarihi!),
                        ),
                        trailing: const Icon(Icons.calendar_month),
                        onTap: () => tarihSec(ekstreMi: false),
                      ),
                      if (hataMesaji != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          hataMesaji!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
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
      final toplamBorc = sayiyaCevir(borcController.text)!;
      final kartLimiti = sayiyaCevir(limitController.text)!;

      setState(() {
        if (mevcutKart == null) {
          kartlar.add(
            KartBilgisi(
              id: siradakiKartId++,
              bankaAdi: bankaController.text.trim(),
              toplamBorc: toplamBorc,
              kartLimiti: kartLimiti,
              ekstreTarihi: ekstreTarihi!,
              sonOdemeTarihi: sonOdemeTarihi!,
            ),
          );
        } else {
          mevcutKart.bankaAdi = bankaController.text.trim();
          mevcutKart.toplamBorc = toplamBorc;
          mevcutKart.kartLimiti = kartLimiti;
          mevcutKart.ekstreTarihi = ekstreTarihi!;
          mevcutKart.sonOdemeTarihi = sonOdemeTarihi!;
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
            '${kart.bankaAdi} uygulamadan silinecek.',
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
        kartlar.removeWhere((eleman) => eleman.id == kart.id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sayfalar = [
      AnaSayfa(
        kartlar: kartlar,
        toplamBorc: toplamBorc,
        paraYaz: paraYaz,
        tarihYaz: tarihYaz,
        kartaTiklandi: (kart) {
          kartDetayiniAc(kart);
        },
      ),
      KartlarSayfasi(
        kartlar: kartlar,
        paraYaz: paraYaz,
        tarihYaz: tarihYaz,
        kartEkle: () {
          kartFormunuAc();
        },
        kartDuzenle: (kart) {
          kartFormunuAc(mevcutKart: kart);
        },
        kartSil: kartSil,
      ),
      const BosSayfa(
        ikon: Icons.payments,
        baslik: 'Ödeme Yap',
        aciklama:
            'Kart ekleme tamamlandı. Sonraki aşamada kart seçme, ödeme girme ve borcu otomatik düşürme gelecek.',
      ),
      const BosSayfa(
        ikon: Icons.history,
        baslik: 'Ödeme Geçmişi',
        aciklama:
            'Yapılan ödemeler tarih, banka ve tutar bilgisiyle burada gösterilecek.',
      ),
      const BosSayfa(
        ikon: Icons.settings,
        baslik: 'Ayarlar',
        aciklama:
            'Sonraki aşamalarda kullanıcı tarafından değiştirilebilen maaş bilgisi eklenecek.',
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

  void kartDetayiniAc(KartBilgisi kart) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        final kullanilabilirLimit =
            (kart.kartLimiti - kart.toplamBorc).clamp(0, double.infinity);

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
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
                  baslik: 'Toplam borç',
                  deger: paraYaz(kart.toplamBorc),
                ),
                DetaySatiri(
                  baslik: 'Kart limiti',
                  deger: paraYaz(kart.kartLimiti),
                ),
                DetaySatiri(
                  baslik: 'Kullanılabilir limit',
                  deger: paraYaz(kullanilabilirLimit.toDouble()),
                ),
                DetaySatiri(
                  baslik: 'Ekstre kesim tarihi',
                  deger: tarihYaz(kart.ekstreTarihi),
                ),
                DetaySatiri(
                  baslik: 'Son ödeme tarihi',
                  deger: tarihYaz(kart.sonOdemeTarihi),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
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
        );
      },
    );
  }
}

class AnaSayfa extends StatelessWidget {
  const AnaSayfa({
    super.key,
    required this.kartlar,
    required this.toplamBorc,
    required this.paraYaz,
    required this.tarihYaz,
    required this.kartaTiklandi,
  });

  final List<KartBilgisi> kartlar;
  final double toplamBorc;
  final String Function(double) paraYaz;
  final String Function(DateTime) tarihYaz;
  final void Function(KartBilgisi) kartaTiklandi;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        OzetKarti(
          baslik: 'Toplam Borç',
          tutar: paraYaz(toplamBorc),
          ikon: Icons.account_balance_wallet,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Expanded(
              child: OzetKarti(
                baslik: 'Ödenen',
                tutar: '0,00 TL',
                ikon: Icons.check_circle_outline,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OzetKarti(
                baslik: 'Kalan',
                tutar: paraYaz(toplamBorc),
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
        const LinearProgressIndicator(
          value: 0,
          minHeight: 12,
          borderRadius: BorderRadius.all(
            Radius.circular(12),
          ),
        ),
        const SizedBox(height: 8),
        const Text('Tamamlanma: %0'),
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
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.credit_card_off,
                    size: 50,
                    color: Theme.of(context).colorScheme.primary,
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
                    'Kartlar sekmesine girip kendi kartınızı ekleyin.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          ...kartlar.map(
            (kart) => Card(
              child: ListTile(
                onTap: () {
                  kartaTiklandi(kart);
                },
                leading: const CircleAvatar(
                  child: Icon(Icons.account_balance),
                ),
                title: Text(
                  kart.bankaAdi,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  'Borç: ${paraYaz(kart.toplamBorc)}\n'
                  'Son ödeme: ${tarihYaz(kart.sonOdemeTarihi)}',
                ),
                isThreeLine: true,
                trailing: const Icon(Icons.chevron_right),
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

  final List<KartBilgisi> kartlar;
  final String Function(double) paraYaz;
  final String Function(DateTime) tarihYaz;
  final VoidCallback kartEkle;
  final void Function(KartBilgisi) kartDuzenle;
  final void Function(KartBilgisi) kartSil;

  @override
  Widget build(BuildContext context) {
    if (kartlar.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
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
                'Kendi bankanızı veya kredi kartınızı eklemek için aşağıdaki düğmeye basın.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: kartEkle,
                icon: const Icon(Icons.add),
                label: const Text('İlk Kartı Ekle'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      itemCount: kartlar.length,
      itemBuilder: (context, index) {
        final kart = kartlar[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.credit_card),
              ),
              title: Text(
                kart.bankaAdi,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                'Borç: ${paraYaz(kart.toplamBorc)}\n'
                'Limit: ${paraYaz(kart.kartLimiti)}\n'
                'Ekstre: ${tarihYaz(kart.ekstreTarihi)}\n'
                'Son ödeme: ${tarihYaz(kart.sonOdemeTarihi)}',
              ),
              isThreeLine: false,
              trailing: PopupMenuButton<String>(
                onSelected: (secim) {
                  if (secim == 'duzenle') {
                    kartDuzenle(kart);
                  } else if (secim == 'sil') {
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
          ),
        );
      },
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
      padding: const EdgeInsets.symmetric(vertical: 7),
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
          mainAxisAlignment: MainAxisAlignment.center,
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
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
