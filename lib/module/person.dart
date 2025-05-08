import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

class Person extends ParseObject implements ParseCloneable {
  Person() : super('Person');

  Person.clone() : this();

  @override
  clone(Map<String, dynamic> map) => Person.clone()..fromJson(map);

  String get name => get<String>('name') ?? '';
  set name(String value) => set<String>('name', value);

  int get age => get<int>('age') ?? 0;
  set age(int value) => set<int>('age', value);
}
