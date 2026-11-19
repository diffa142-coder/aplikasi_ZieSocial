class ContactModel {
  final int id;
  final String name;
  final String phone;
  final String avatar;

  ContactModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.avatar,
  });

  factory ContactModel.fromJson(Map<String, dynamic> json) {
    return ContactModel(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      avatar: json['avatar'],
    );
  }
}