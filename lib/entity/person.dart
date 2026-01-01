import 'package:json_annotation/json_annotation.dart';
import 'package:holo/entity/image.dart';

part 'person.g.dart';

@JsonSerializable()
class Person {
  final Image? images;
  final String? name;
  final String? relation;
  final List<String>? career;
  final int? type;
  final int? id;
  final String? eps;

  Person({
    this.images,
    this.name,
    this.relation,
    this.career,
    this.type,
    this.id,
    this.eps,
  });

  factory Person.fromJson(Map<String, dynamic> json) => _$PersonFromJson(json);
  Map<String, dynamic> toJson() => _$PersonToJson(this);
}
