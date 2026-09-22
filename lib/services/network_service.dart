import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class NetworkService {
  /// Checks if active network / API connection is available
  static Future<bool> isNetworkAvailable() async {
    // 1. Probe local/remote API backend server health endpoint first
    try {
      final host = await ApiService.getBaseUrl();
      final res = await http.get(Uri.parse('$host/health')).timeout(const Duration(seconds: 2));
      if (res.statusCode == 200) {
        return true;
      }
    } catch (_) {}

    // 2. Web Browser compatibility fallback (InternetAddress is unsupported on Web)
    if (kIsWeb) {
      return true;
    }

    // 3. Mobile / Desktop WAN DNS lookup
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 2));
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true;
      }
    } catch (_) {}

    return false;
  }

  /// Displays standard No Internet Connection SnackBar
  static void showNoInternetSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                '📶 No Internet Connection. Please check your network settings and try again.',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade800,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  /// Build Offline UI screen banner when network is unavailable
  static Widget buildOfflineWidget({required VoidCallback onRetry}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.wifi_off, size: 54, color: Colors.red),
            ),
            const SizedBox(height: 16),
            const Text(
              '📶 No Internet Connection',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your mobile internet or Wi-Fi connection is unavailable. Please check your network settings and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry Connection', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F766E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
