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

class AnaUygulama extends StatefulWidget {
  const AnaUygulama({super.key});

  @override
  State<AnaUygulama> createState() => _AnaUygulamaState();
}

class _AnaUygulamaState extends State<AnaUygulama> {
  int seciliSayfa = 0;

  final List<String> sayfaBasliklari = const [
    'YFP Finans',
    'Kartlar',
    'Ödeme Yap',
    'Geçmiş',
    'Ayarlar',
  ];

  final List<Widget> sayfalar = const [
    AnaSayfa(),
    KartlarSayfasi(),
    OdemeYapSayfasi(),
    GecmisSayfasi(),
    AyarlarSayfasi(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          sayfaBasliklari[seciliSayfa],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: IndexedStack(
        index: seciliSayfa,
        children: sayfalar,
      ),
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
  const AnaSayfa({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        OzetKarti(
          baslik: 'Toplam Borç',
          tutar: '87.953,16 TL',
          ikon: Icons.account_balance_wallet,
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OzetKarti(
                baslik: 'Ödenen',
                tutar: '0 TL',
                ikon: Icons.check_circle_outline,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: OzetKarti(
                baslik: 'Kalan',
                tutar: '87.953,16 TL',
                ikon: Icons.pending_actions,
              ),
            ),
          ],
        ),
        SizedBox(height: 24),
        Text(
          'Borç Durumu',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        LinearProgressIndicator(
          value: 0,
          minHeight: 12,
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        SizedBox(height: 8),
        Text('Tamamlanma: %0'),
        SizedBox(height: 24),
        Text(
          'Bankalar',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        BankaKarti(
          bankaAdi: 'Ziraat Bankası',
          kalanBorc: '16.000 TL',
        ),
        BankaKarti(
          bankaAdi: 'Garanti Bankası',
          kalanBorc: '1.500 TL',
        ),
        BankaKarti(
          bankaAdi: 'QNB',
          kalanBorc: '3.883,25 TL',
        ),
        BankaKarti(
          bankaAdi: 'İş Bankası',
          kalanBorc: '13.476,22 TL',
        ),
      ],
    );
  }
}

class OzetKarti extends StatelessWidget {
  final String baslik;
  final String tutar;
  final IconData ikon;

  const OzetKarti({
    super.key,
    required this.baslik,
    required this.tutar,
    required this.ikon,
  });

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
              style: const TextStyle(fontSize: 14),
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

class BankaKarti extends StatelessWidget {
  final String bankaAdi;
  final String kalanBorc;

  const BankaKarti({
    super.key,
    required this.bankaAdi,
    required this.kalanBorc,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.account_balance),
        ),
        title: Text(
          bankaAdi,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Kalan borç: $kalanBorc'),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class KartlarSayfasi extends StatelessWidget {
  const KartlarSayfasi({super.key});

  @override
  Widget build(BuildContext context) {
    return const BosSayfa(
      ikon: Icons.credit_card,
      baslik: 'Kartlar',
      aciklama:
          'Bir sonraki adımda buraya kart ekleme, düzenleme ve silme özellikleri gelecek.',
    );
  }
}

class OdemeYapSayfasi extends StatelessWidget {
  const OdemeYapSayfasi({super.key});

  @override
  Widget build(BuildContext context) {
    return const BosSayfa(
      ikon: Icons.payments,
      baslik: 'Ödeme Yap',
      aciklama:
          'Bir sonraki aşamada banka seçme, tutar girme ve borcu otomatik düşürme özelliği gelecek.',
    );
  }
}

class GecmisSayfasi extends StatelessWidget {
  const GecmisSayfasi({super.key});

  @override
  Widget build(BuildContext context) {
    return const BosSayfa(
      ikon: Icons.history,
      baslik: 'Ödeme Geçmişi',
      aciklama:
          'Yapılan tüm ödemeler tarih ve tutar bilgisiyle burada gösterilecek.',
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
          'Buraya kullanıcı tarafından değiştirilebilen maaş bilgisi eklenecek.',
    );
  }
}

class BosSayfa extends StatelessWidget {
  final IconData ikon;
  final String baslik;
  final String aciklama;

  const BosSayfa({
    super.key,
    required this.ikon,
    required this.baslik,
    required this.aciklama,
  });

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
