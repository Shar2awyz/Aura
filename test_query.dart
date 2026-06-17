import 'dart:convert';
import 'dart:io';

void main() async {
  final client = HttpClient();
  
  Future<void> testQuery(String selectQuery) async {
    try {
      final uri = Uri.parse('https://hwncafjqdyjwykaditty.supabase.co/rest/v1/notifications?select=$selectQuery&limit=1');
      final request = await client.getUrl(uri);
      request.headers.add('apikey', 'sb_publishable__92PSezbkmrlXUkPsL0mwQ_mOn7vkD1');
      request.headers.add('Authorization', 'Bearer sb_publishable__92PSezbkmrlXUkPsL0mwQ_mOn7vkD1');
      
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      print('Query [ $selectQuery ] -> Status: ${response.statusCode}');
      print('Body: $body\n');
    } catch (e) {
      print('Error on [ $selectQuery ]: $e\n');
    }
  }

  await testQuery('*,profiles!sender_id(*)');
  await testQuery('*,profiles!notifications_sender_id_fkey(*)');
  await testQuery('*,profiles(*)');

  client.close();
}
