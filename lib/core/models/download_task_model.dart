class DownloadTaskModel {
  final String url;
  final String fileName;
  final String product;
  int downloaded;
  int total;

  DownloadTaskModel({
    required this.url,
    required this.fileName,
    required this.product,
    this.downloaded = 0,
    this.total = 0,
  });

  Map<String, dynamic> toJson() => {
    'url': url,
    'fileName': fileName,
    'product': product,
    'downloaded': downloaded,
    'total': total,
  };

  factory DownloadTaskModel.fromJson(Map<String, dynamic> json) {
    return DownloadTaskModel(
      url: json['url'],
      fileName: json['fileName'],
      product: json['product'],
      downloaded: json['downloaded'],
      total: json['total'],
    );
  }
}
