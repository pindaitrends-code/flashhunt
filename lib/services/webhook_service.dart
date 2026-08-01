import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_model.dart';

class WebhookService {
  static String _token = '';
  static List<String> _marketplacePackages = [];
  static Map<String, String> _marketplaceAffiliates = {};
  
  static const String WEBHOOK_ACTOR = 'bunyamin~webhook-receiver-v2';
  static const String SCRAPER_ACTOR = 'bunyamin~flash-sale-all-in-one';

  static void updateToken(String newToken) {
    _token = newToken;
  }

  static void updateMarketplaces(List<String> packages, Map<String, String> affiliates) {
    _marketplacePackages = packages;
    _marketplaceAffiliates = affiliates;
  }

  static Future<String> _getToken() async {
    if (_token.isNotEmpty) return _token;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('apify_token') ?? '';
    return _token;
  }

  static Future<String> _getWebhookUrl() async {
    final token = await _getToken();
    return 'https://api.apify.com/v2/acts/$WEBHOOK_ACTOR/runs?token=$token';
  }

  static Future<String> _getScraperUrl() async {
    final token = await _getToken();
    return 'https://api.apify.com/v2/acts/$SCRAPER_ACTOR/runs?token=$token';
  }

  static Future<String> _getAffiliateId(String packageName) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('affiliate_$packageName') ?? '';
  }

  static Future<List<String>> getEnabledMarketplaces() async {
    final prefs = await SharedPreferences.getInstance();
    final packages = prefs.getStringList('marketplace_packages') ?? [];
    final enabled = <String>[];
    for (var pkg in packages) {
      if (prefs.getBool('enabled_$pkg') ?? true) {
        enabled.add(pkg);
      }
    }
    return enabled;
  }

  static bool detectFlashSale(NotificationModel notification) {
    final List<String> keywords = [
      'flash sale', 'diskon', 'promo', 'murah', 'obral', 'gratis',
      'potongan', 'sale', 'discount'
    ];
    final String text = '${notification.title} ${notification.content}'.toLowerCase();
    for (final keyword in keywords) {
      if (text.contains(keyword)) return true;
    }
    return false;
  }

  static Future<void> sendWebhookSignal(NotificationModel notification) async {
    try {
      final token = await _getToken();
      if (token.isEmpty) {
        print('❌ Token Apify kosong! Isi di Settings.');
        return;
      }

      final String webhookUrl = await _getWebhookUrl();
      final String affiliateId = await _getAffiliateId(notification.packageName);
      
      final payload = {
        'payload': {
          'type': 'flash_sale_notification',
          'title': notification.title,
          'content': notification.content,
          'packageName': notification.packageName,
          'platform': _getPlatform(notification.packageName),
          'affiliateId': affiliateId,
          'timestamp': notification.timestamp.toIso8601String(),
          'isFlashSale': detectFlashSale(notification),
        }
      };

      final response = await http.post(
        Uri.parse(webhookUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Webhook signal terkirim');
        await triggerScraper(notification);
      } else {
        print('❌ Webhook gagal: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Webhook error: $e');
    }
  }

  static Future<void> triggerScraper(NotificationModel notification) async {
    try {
      final enabledPackages = await getEnabledMarketplaces();
      if (!enabledPackages.contains(notification.packageName)) {
        print('⏭️ Marketplace ${notification.packageName} tidak aktif');
        return;
      }

      final token = await _getToken();
      if (token.isEmpty) {
        print('❌ Token Apify kosong!');
        return;
      }

      final String scraperUrl = await _getScraperUrl();
      final String keyword = _extractKeyword(notification);
      final String affiliateId = await _getAffiliateId(notification.packageName);
      final String platform = _getPlatform(notification.packageName);

      final Map<String, dynamic> input = {
        'mode': 'discovery',
        'search_keyword': keyword,
        'platforms': [platform.toLowerCase()],
        'min_discount': 30,
        'min_rating': 4.0,
        'max_products': 20,
        'ai_verification': true,
        'enable_affiliate': affiliateId.isNotEmpty,
        'affiliate_id': affiliateId,
        'webhook_url': await _getWebhookUrl(),
      };

      final response = await http.post(
        Uri.parse(scraperUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(input),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Scraper triggered: $keyword');
        print('📦 Platform: $platform');
        print('📦 Affiliate: ${affiliateId.isNotEmpty ? affiliateId : 'Tidak ada'}');
      } else {
        print('❌ Scraper gagal: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Scraper error: $e');
    }
  }

  static String _getPlatform(String packageName) {
    final Map<String, String> platformMap = {
      'com.shopee': 'Shopee',
      'com.tokopedia': 'Tokopedia',
      'com.lazada': 'Lazada',
      'com.blibli': 'Blibli',
      'com.tiktok': 'TikTok',
      'com.amazon': 'Amazon',
    };
    return platformMap[packageName] ?? packageName;
  }

  static String _extractKeyword(NotificationModel notification) {
    final String text = '${notification.title} ${notification.content}';
    final RegExp regex = RegExp(r'(diskon|flash sale|promo|murah|obral|gratis)\s*(.*?)(?:\s|$)');
    final match = regex.firstMatch(text.toLowerCase());

    if (match != null && match.groupCount >= 2) {
      final String keyword = match.group(2)?.trim() ?? '';
      if (keyword.isNotEmpty && keyword.length > 2) return keyword;
    }

    final List<String> words = text.split(' ').where((w) => w.length > 3).toList();
    return words.isNotEmpty ? words.first : 'flash sale';
  }
}