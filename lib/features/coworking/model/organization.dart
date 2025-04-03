class Organization {
  final int id;
  final String name;
  final String type;
  final String? description;
  final String? shortDescription;
  final String? phone;
  final String? address;
  final String? workingHours;
  final PreviewImage? previewImage;
  final List<dynamic> images;
  final String? websiteLink;
  final String? instagramLink;
  final List<Category> categories;
  final String? bin;

  Organization({
    required this.id,
    required this.name,
    required this.type,
    this.description,
    this.shortDescription,
    this.phone,
    this.address,
    this.workingHours,
    this.previewImage,
    required this.images,
    this.websiteLink,
    this.instagramLink,
    required this.categories,
    this.bin,
  });

  factory Organization.fromJson(Map<String, dynamic> json) {
    return Organization(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      description: json['description'],
      shortDescription: json['short_description'],
      phone: json['phone'],
      address: json['address'],
      workingHours: json['working_hours'],
      previewImage: json['preview_image'] != null
          ? PreviewImage.fromJson(json['preview_image'])
          : null,
      images: json['images'] ?? [],
      websiteLink: json['website_link'],
      instagramLink: json['instagram_link'],
      categories: json['categories'] != null
          ? List<Category>.from(
              json['categories'].map((x) => Category.fromJson(x)))
          : [],
      bin: json['bin'],
    );
  }
}

class PreviewImage {
  final int id;
  final String uuid;
  final String url;
  final String urlOriginal;
  final int orderColumn;
  final String collectionName;

  PreviewImage({
    required this.id,
    required this.uuid,
    required this.url,
    required this.urlOriginal,
    required this.orderColumn,
    required this.collectionName,
  });

  factory PreviewImage.fromJson(Map<String, dynamic> json) {
    return PreviewImage(
      id: json['id'],
      uuid: json['uuid'],
      url: json['url'],
      urlOriginal: json['urlOriginal'],
      orderColumn: json['order_column'],
      collectionName: json['collection_name'],
    );
  }
}

class Category {
  final int id;
  final String title;

  Category({
    required this.id,
    required this.title,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      title: json['title'],
    );
  }
}

class OrganizationsResponse {
  final List<Organization> data;
  final int total;
  final int currentPage;
  final int lastPage;

  OrganizationsResponse({
    required this.data,
    required this.total,
    required this.currentPage,
    required this.lastPage,
  });

  factory OrganizationsResponse.fromJson(Map<String, dynamic> json) {
    return OrganizationsResponse(
      data: List<Organization>.from(
          json['data'].map((x) => Organization.fromJson(x))),
      total: json['meta']['total'],
      currentPage: json['meta']['current_page'],
      lastPage: json['meta']['last_page'],
    );
  }
}
