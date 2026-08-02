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
        primarySwatch: Colors.blue,
      ),
      home: const AnaSayfa(),
    );
  }
}

class AnaSayfa extends StatelessWidget {
  const AnaSayfa({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('YFP Finans'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            Card(
              child: ListTile(
                title: const Text(
                  'Toplam Borç',
                  style: TextStyle(fontSize: 18),
                ),
                subtitle: const Text(
                  '87.953,16 TL',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            Card(
              child: ListTile(
                title: const Text('Ödenen'),
                subtitle: const Text(
                  '0 TL',
                  style: TextStyle(fontSize: 22),
                ),
              ),
            ),

            const SizedBox(height: 10),

            Card(
              child: ListTile(
                title: const Text('Kalan Borç'),
                subtitle: const Text(
                  '87.953,16 TL',
                  style: TextStyle(fontSize: 22),
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Bankalar',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            Expanded(
              child: ListView(
                children: const [

                  ListTile(
                    leading: Icon(Icons.account_balance),
                    title: Text('Ziraat Bankası'),
                    subtitle: Text('16.000 TL'),
                  ),

                  ListTile(
                    leading: Icon(Icons.account_balance),
                    title: Text('Garanti Bankası'),
                    subtitle: Text('1.500 TL'),
                  ),

                  ListTile(
                    leading: Icon(Icons.account_balance),
                    title: Text('Akbank'),
                    subtitle: Text('2.000 TL'),
                  ),

                  ListTile(
                    leading: Icon(Icons.account_balance),
                    title: Text('QNB'),
                    subtitle: Text('3.883 TL'),
                  ),

                  ListTile(
                    leading: Icon(Icons.account_balance),
                    title: Text('İş Bankası'),
                    subtitle: Text('13.476 TL'),
                  ),

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
