import 'package:flutter/material.dart';
import 'package:flutter_web_bluetooth/flutter_web_bluetooth.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: BleHomePage(),
    );
  }
}

class BleHomePage extends StatefulWidget {
  const BleHomePage({super.key});

  @override
  State<BleHomePage> createState() => _BleHomePageState();
}

class _BleHomePageState extends State<BleHomePage> {
  BluetoothDevice? device;
  BluetoothCharacteristic? notifyChar;

  String displayedPH = "--";
  String displayedMV = "--";
  String trendArrow = "→";
  double lastMV = 0.0;

  final uartService = "6e400001-b5a3-f393-e0a9-e50e24dcca9e";
  final uartTx = "6e400003-b5a3-f393-e0a9-e50e24dcca9e";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5FA),
      appBar: AppBar(
        title: const Text("pH Sensor BLE"),
        backgroundColor: Colors.blue.shade700,
      ),

      body: Column(
        children: [

          // ---------------- MAIN CONTENT ----------------
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  // Scan button
                  ElevatedButton(
                    onPressed: scanAndConnect,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text("Scan & Connect",
                        style: TextStyle(fontSize: 18, color: Colors.white)),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    "Device: ${device?.name ?? "None"}",
                    style: const TextStyle(fontSize: 18, color: Colors.black54),
                  ),

                  const SizedBox(height: 40),

                  // ---------- pH CARD ----------
                  Card(
                    elevation: 6,
                    color: const Color(0xFFE8F3FF), // soft blue tint
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Container(
                      width: 260,
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      child: Column(
                        children: [
                          Text("pH",
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.grey.shade700,
                              )),
                          const SizedBox(height: 8),
                          Text(
                            displayedPH,
                            style: const TextStyle(
                              fontSize: 72,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ---------- mV CARD ----------
                  Card(
                    elevation: 6,
                    color: const Color(0xFFFFF2E5), // soft orange tint
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Container(
                      width: 260,
                      padding: const EdgeInsets.symmetric(vertical: 22),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "$displayedMV mV",
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            trendArrow,
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: trendArrow == "↑"
                                  ? Colors.green
                                  : trendArrow == "↓"
                                      ? Colors.red
                                      : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ---------------- BOTTOM NAPIER LOGO ----------------
          Padding(
            padding: const EdgeInsets.only(bottom: 28),
            child: Image.asset(
              'web/assets/napier_logo.png',
              height: 100,
            ),
          )
        ],
      ),
    );
  }

  // -----------------------------------------------------
  // BLE LOGIC (same as your working version)
  // -----------------------------------------------------
  Future<void> scanAndConnect() async {
    final req = RequestOptionsBuilder([
      RequestFilterBuilder(services: [uartService]),
    ]);

    final d = await FlutterWebBluetooth.instance.requestDevice(req);
    device = d;
    setState(() {});

    await device!.connect();

    final services = await device!.discoverServices();
    final service = services.firstWhere((s) => s.uuid == uartService);

    final chars = await service.getCharacteristics();
    notifyChar = chars.firstWhere((c) => c.uuid == uartTx);

    await notifyChar!.startNotifications();

    notifyChar!.value.listen((byteData) {
      final bytes = byteData.buffer.asUint8List();
      final text = String.fromCharCodes(bytes).trim();
      _processIncoming(text);
    });
  }

  void _processIncoming(String text) {
    final parts = text.split(",");
    if (parts.length != 2) return;

    final mv = double.tryParse(parts[0]) ?? lastMV;
    final ph = parts[1];

    if (mv > lastMV) {
      trendArrow = "↑";
    } else if (mv < lastMV) {
      trendArrow = "↓";
    } else {
      trendArrow = "→";
    }

    lastMV = mv;

    setState(() {
      displayedMV = mv.toStringAsFixed(5);
      displayedPH = ph;
    });
  }
}
