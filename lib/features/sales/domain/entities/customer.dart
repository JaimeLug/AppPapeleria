import 'package:equatable/equatable.dart';

class CustomerEntity extends Equatable {
  final String id;
  final String name;
  final String phone;

  const CustomerEntity({
    required this.id,
    required this.name,
    required this.phone,
  });

  @override
  List<Object?> get props => [id, name, phone];
}
