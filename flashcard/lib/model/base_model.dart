abstract class BaseModel {
  final String id;

  const BaseModel({required this.id});

  Map<String, dynamic> toJson();

  BaseModel copyWith({String? id});
}
