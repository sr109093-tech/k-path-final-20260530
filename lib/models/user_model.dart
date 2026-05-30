import 'dart:convert';

class UserProfile {
  String id, name, password;
  int age;
  double height, weight;

  UserProfile({this.id = '', this.name = '', this.password = '', this.age = 0, this.height = 0.0, this.weight = 0.0});

  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'password': password, 'age': age, 'height': height, 'weight': weight};
  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
    id: map['id'] ?? '', name: map['name'] ?? '', password: map['password'] ?? '',
    age: map['age'] ?? 0, height: (map['height'] ?? 0).toDouble(), weight: (map['weight'] ?? 0).toDouble(),
  );
  String toJson() => json.encode(toMap());
  factory UserProfile.fromJson(String source) => UserProfile.fromMap(json.decode(source));
}