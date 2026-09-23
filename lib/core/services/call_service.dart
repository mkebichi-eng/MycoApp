import 'package:url_launcher/url_launcher.dart';

class CallService {
  /// Passe un appel téléphonique en 1 seul tap
  static Future<bool> makePhoneCall(String phoneNumber) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri);
    }
    return false;
  }

  /// Ouvre l'application de navigation GPS vers une adresse
  static Future<bool> openMapNavigation(String address) async {
    final encodedAddress = Uri.encodeComponent(address);
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encodedAddress');
    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }
}
