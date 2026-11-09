class CompanyProfile {
  CompanyProfile({
    required this.id,
    required this.name,
    required this.description,
    required this.phone,
    required this.address,
    required this.coordinates,
    required this.workingHours,
    this.logoUrl,
    required this.carouselUrls,
  });

  final String id;
  final String name;
  final String description;
  final String phone;
  final String address;
  final String coordinates;
  final String workingHours;
  final String? logoUrl;
  final List<String> carouselUrls;

  factory CompanyProfile.fromJson(Map<String, dynamic> json) {
    final urls = json['carousel_urls'] as List? ?? [];
    return CompanyProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      phone: json['phone'] as String,
      address: json['address'] as String,
      coordinates: json['coordinates'] as String,
      workingHours: json['working_hours'] as String,
      logoUrl: json['logo_url'] as String?,
      carouselUrls: urls.map((url) => url.toString()).toList(),
    );
  }
}
