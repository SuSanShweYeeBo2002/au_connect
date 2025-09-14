import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class BangkokWeatherPage extends StatefulWidget {
  static String routeName = "/BangkokWeatherPage";
  const BangkokWeatherPage({super.key});

  @override
  State<BangkokWeatherPage> createState() => _BangkokWeatherPageState();
}

class _BangkokWeatherPageState extends State<BangkokWeatherPage> {

  // state
  double currentTemperature = 0.0;
  bool loading = false;
  // create a function to get weather forecast


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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Bangkok Weather"),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text("$loading"),
          if(loading) CircularProgressIndicator(),
          Text("${currentTemperature} C", style: TextStyle(fontSize: 72),),
          Text("Bangkok", style: TextStyle(fontSize: 24),),
          ElevatedButton(onPressed: ()async{
            // get weather forecast
            setState(() {
              loading = true;
            });
            double? result = await getBangkokTemperature();
            if(result != null){
              setState(() {
                currentTemperature = result;
              });
            }
            setState(() {
              loading = false;
            });
          }, child: Text("Get Weather Forecast")),
          Container(width: double.infinity,color: Colors.red,child: Text(""),)
        ],
      ),
    );
  }
}
