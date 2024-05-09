import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => UniversityProvider(),
      child: const MyApp(),
    ),
  );
}

class University {
  final String name;
  final String website;

  University({required this.name, required this.website});

  factory University.fromJson(Map<String, dynamic> json) {
    return University(
      name: json['name'],
      website: json['web_pages'][0],
    );
  }
}

class UniversityProvider with ChangeNotifier {
  List<University>? universities;
  String _selectedCountry = 'Indonesia';

  String get selectedCountry => _selectedCountry;

  set selectedCountry(String country) {
    _selectedCountry = country;
    fetchData();
    notifyListeners();
  }

  Future<void> fetchData() async {
    final response = await http.get(Uri.parse('http://universities.hipolabs.com/search?country=$_selectedCountry'));
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body) as List<dynamic>;
      universities = jsonData.map((item) => University.fromJson(item)).toList();
      notifyListeners();
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daftar Universitas',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Daftar Universitas'),
        ),
        body: Column(
          children: [
            CountryDropdown(),
            UniversityList(),
          ],
        ),
      ),
    );
  }
}

class CountryDropdown extends StatefulWidget {
  const CountryDropdown({Key? key}) : super(key: key);

  @override
  _CountryDropdownState createState() => _CountryDropdownState();
}

class _CountryDropdownState extends State<CountryDropdown> {
  final List<String> countries = ['Indonesia', 'Singapore', 'Malaysia']; // Daftar negara ASEAN
  String dropdownValue = 'Indonesia';

  @override
  Widget build(BuildContext context) {
    final universityProvider = Provider.of<UniversityProvider>(context);
    return DropdownButton<String>(
      value: dropdownValue,
      onChanged: (String? newValue) {
        if (newValue != null) {
          setState(() {
            dropdownValue = newValue;
          });
          universityProvider.selectedCountry = newValue;
        }
      },
      items: countries.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
    );
  }
}

class UniversityList extends StatelessWidget {
  const UniversityList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final universityProvider = Provider.of<UniversityProvider>(context);
    final universities = universityProvider.universities;

    if (universities == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Expanded(
      child: ListView.builder(
        itemCount: universities.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(universities[index].name),
            subtitle: Text(universities[index].website),
          );
        },
      ),
    );
  }
}
