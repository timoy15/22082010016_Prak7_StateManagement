import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() {
  runApp(
    BlocProvider(
      create: (context) => UniversityCubit(),
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

class UniversityState {
  final List<University>? universities;
  final String selectedCountry;

  UniversityState({required this.universities, required this.selectedCountry});

  factory UniversityState.initial() {
    return UniversityState(universities: null, selectedCountry: 'Indonesia');
  }

  UniversityState copyWith({List<University>? universities, String? selectedCountry}) {
    return UniversityState(
      universities: universities ?? this.universities,
      selectedCountry: selectedCountry ?? this.selectedCountry,
    );
  }
}

class UniversityCubit extends Cubit<UniversityState> {
  UniversityCubit() : super(UniversityState.initial());

  void selectCountry(String country) {
    emit(state.copyWith(selectedCountry: country));
    fetchData();
  }

  Future<void> fetchData() async {
    final response =
        await http.get(Uri.parse('http://universities.hipolabs.com/search?country=${state.selectedCountry}'));
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body) as List<dynamic>;
      final universities = jsonData.map((item) => University.fromJson(item)).toList();
      emit(state.copyWith(universities: universities));
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

class CountryDropdown extends StatelessWidget {
  const CountryDropdown({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UniversityCubit, UniversityState>(
      builder: (context, state) {
        return DropdownButton<String>(
          value: state.selectedCountry,
          onChanged: (String? newValue) {
            if (newValue != null) {
              context.read<UniversityCubit>().selectCountry(newValue);
            }
          },
          items: ['Indonesia', 'Singapore', 'Malaysia'].map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        );
      },
    );
  }
}

class UniversityList extends StatelessWidget {
  const UniversityList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UniversityCubit, UniversityState>(
      builder: (context, state) {
        final universities = state.universities;

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
      },
    );
  }
}
