class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    this.professionalTitle,
    this.gender,
    this.age,
    this.imageUrl,
  });

  final String id;
  final String? name;
  final String phone;
  final String email;
  final String? professionalTitle;
  final String? gender;
  final int? age;
  final String? imageUrl;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      name: json['name'] as String?,
      phone: json['phone'] as String,
      email: json['email'] as String,
      professionalTitle:
          (json['professional_title'] ?? json['professionalTitle'] ?? json['specialty'])
              as String?,
      gender: json['gender'] as String?,
      age: json['age'] as int?,
      imageUrl: json['imageUrl'] as String?,
    );
  }
}
