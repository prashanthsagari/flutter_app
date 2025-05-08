// import 'package:flutter/material.dart';
// import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
// import 'package:simple_app/module/person.dart';
//
//
// class PersonsPage extends StatefulWidget {
//   const PersonsPage({super.key});
//
//   @override
//   State<PersonsPage> createState() => _PersonsPageState();
// }
//
// class _PersonsPageState extends State<PersonsPage> {
//   List<Person> persons = [];
//   bool isLoading = true;
//
//   @override
//   void initState() {
//     super.initState();
//     fetchPersons();
//   }
//
//   Future<void> fetchPersons() async {
//     final query = QueryBuilder(Person());
//     final response = await query.query();
//
//     if (response.success && response.results != null) {
//       setState(() {
//         persons = response.results!.cast<Person>();
//         isLoading = false;
//       });
//     } else {
//       setState(() {
//         isLoading = false;
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to fetch persons: ${response.error?.message}')),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Persons List')),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : persons.isEmpty
//           ? const Center(child: Text('No persons found.'))
//           : ListView.builder(
//         itemCount: persons.length,
//         itemBuilder: (context, index) {
//           final person = persons[index];
//           return ListTile(
//             title: Text(person.name),
//             subtitle: Text('Age: ${person.age}'),
//           );
//         },
//       ),
//     );
//   }
// }
