import 'package:pine/pine.dart';

class DeckRefDTO extends DTO {
  final String slug;
  final String name;

  const DeckRefDTO({required this.slug, required this.name});

  factory DeckRefDTO.fromJson(Map<String, dynamic> json) =>
      DeckRefDTO(slug: json['slug'] as String, name: json['name'] as String);

  Map<String, dynamic> toJson() => {'slug': slug, 'name': name};
}
