import 'package:mobile/core/nav.dart'; // AG_FIX3
import 'package:flutter/material.dart';
import '../../../core/i18n.dart'; // AG_I18N1

class MaxConnectScreen extends StatelessWidget {
  const MaxConnectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const AgBackButton(fallback: '/login'), /* AG_FIX3 */ title: const Text('MAX')),

      body: Padding(
        padding: const EdgeInsets.all(24),

        child: Column(
          children: [
            const SizedBox(height: 50),

            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(25),
              ),

              child: const Center(
                child: Text(
                  'M',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              'MAX',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 15),

            Text(
              tr('Подключите MAX для входа в AG Service'),
              textAlign: TextAlign.center,
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,

              child: ElevatedButton(
                onPressed: () {},

                child: Text(tr('Подключить MAX')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
