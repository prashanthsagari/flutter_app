// import 'package:flutter/material.dart';
//
// class PersonsPage extends StatelessWidget {
//   final List<Map<String, dynamic>> persons = [
//     {'name': 'Alice', 'age': 25},
//     {'name': 'Bob', 'age': 30},
//     {'name': 'Charlie', 'age': 22},
//   ];
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Persons List')),
//       body: ListView.builder(
//         itemCount: persons.length,
//         itemBuilder: (context, index) {
//           final person = persons[index];
//           return ListTile(
//             title: Text(person['name']),
//             subtitle: Text('Age: ${person['age']}'),
//           );
//         },
//       ),
//     );
//   }
// }
