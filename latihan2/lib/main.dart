import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

void main() {
  runApp(
    BlocProvider<UniversityBloc>(
      create: (context) => UniversityBloc(),
      child: const MyApp(),
    ),
  );
}

class University extends Equatable {
  final String name;
  final String website;

  University({required this.name, required this.website});

  factory University.fromJson(Map<String, dynamic> json) {
    return University(
      name: json['name'],
      website: json['web_pages'][0],
    );
  }

  @override
  List<Object?> get props => [name, website];
}

class UniversityState extends Equatable {
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

  @override
  List<Object?> get props => [universities, selectedCountry];
}

abstract class UniversityEvent extends Equatable {
  const UniversityEvent();

  @override
  List<Object?> get props => [];
}

class FetchUniversities extends UniversityEvent {
  final String country;

  const FetchUniversities(this.country);

  @override
  List<Object?> get props => [country];
}

class UniversityBloc extends Bloc<UniversityEvent, UniversityState> {
  UniversityBloc() : super(UniversityState.initial());

  @override
  Stream<UniversityState> mapEventToState(UniversityEvent event) async* {
    if (event is FetchUniversities) {
      yield* _mapFetchUniversitiesToState(event);
    }
  }

  Stream<UniversityState> _mapFetchUniversitiesToState(FetchUniversities event) async* {
    try {
      final response = await http.get(Uri.parse('http://universities.hipolabs.com/search?country=${event.country}'));
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as List<dynamic>;
        final universities = jsonData.map((item) => University.fromJson(item)).toList();
        yield state.copyWith(universities: universities, selectedCountry: event.country);
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      yield state.copyWith(universities: [], selectedCountry: event.country);
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
    final universityBloc = BlocProvider.of<UniversityBloc>(context);

    return BlocBuilder<UniversityBloc, UniversityState>(
      builder: (context, state) {
        return DropdownButton<String>(
          value: state.selectedCountry,
          onChanged: (String? newValue) {
            if (newValue != null) {
              universityBloc.add(FetchUniversities(newValue));
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
    return BlocBuilder<UniversityBloc, UniversityState>(
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
