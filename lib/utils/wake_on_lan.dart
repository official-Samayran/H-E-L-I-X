import 'dart:io';

class WakeOnLan {
  static Future<void> wake(String macAddress) async {
    if (macAddress.isEmpty) return;
    
    // Clean MAC address
    final cleanMac = macAddress.replaceAll(':', '').replaceAll('-', '');
    if (cleanMac.length != 12) return;

    try {
      final macBytes = List<int>.generate(6, (i) => int.parse(cleanMac.substring(i * 2, i * 2 + 2), radix: 16));
      
      // Magic packet: 6 bytes of 0xFF followed by 16 repetitions of the MAC address
      final magicPacket = <int>[...List.filled(6, 0xFF)];
      for (var i = 0; i < 16; i++) {
        magicPacket.addAll(macBytes);
      }

      final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.broadcastEnabled = true;
      socket.send(magicPacket, InternetAddress('255.255.255.255'), 9);
      socket.close();
    } catch (e) {
      // Fail silently for WoL magic packets on UI threads
    }
  }
}
