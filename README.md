# AU Connect


## 2025-09-14 API Integration Sample Code


```dart
Future<double?> getBangkokTemperature() async {
  final url = Uri.parse('http://api.weatherapi.com/v1/current.json?key=2195048ca86d45e2bb6150052251109&q=Bangkok&aqi=no');

  try {
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      // Accessing temp_c from the 'current' object
      return data['current']['temp_c'].toDouble(); 
    } else {
      print('Failed to load weather data. Status code: ${response.statusCode}');
      return null;
    }
  } catch (e) {
    print('An error occurred: $e');
    return null;
  }
}
```