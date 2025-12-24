// Quick test script to verify Gemini API
// Run with: dart test_gemini_api.dart

import 'dart:io';

void main() async {
  print('🧪 Testing Gemini API...\n');
  
  const apiKey = 'AIzaSyD1lq4IJogT-uUU40HveoC_aIKL1qkQ5JY';
  
  print('📋 API Key: ${apiKey.substring(0, 20)}...');
  print('🔗 Testing connection to Gemini API...\n');
  
  try {
    final client = HttpClient();
    final request = await client.getUrl(
      Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey'),
    );
    
    request.headers.set('Content-Type', 'application/json');
    request.write('''
{
  "contents": [{
    "parts": [{
      "text": "Say hello in Vietnamese"
    }]
  }]
}
''');
    
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    
    print('📊 Response Status: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      print('✅ API Key is valid and working!\n');
      print('📝 Response: $responseBody');
    } else {
      print('❌ API returned error status: ${response.statusCode}');
      print('📝 Response: $responseBody');
    }
    
    client.close();
  } catch (e) {
    print('❌ Error testing API: $e');
    print('\n💡 Possible issues:');
    print('   1. API key might be invalid');
    print('   2. Network connection issue');
    print('   3. API quota exceeded');
    print('   4. API endpoint changed');
  }
}

