import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/ebara_data_service.dart';
import '../services/analytics_service.dart';
import '../services/download_service.dart';
import '../models/product_model.dart';
import '../models/representative_model.dart';
import '../router/app_router.dart';
import 'history_provider.dart';
import '../../core/extensions/context_extensions.dart';

class ProductDescKeys {
  static const String description = 'description';
  static const String specifications = 'specifications';
  static const String options = 'options';
  static const String apps = 'apps';
}

class ProductDetailsProvider with ChangeNotifier {
  final EbaraDataService _dataService;
  final DownloadService _downloadService;

  int _currentIndex = 0;
  int _comparisonBaseIndex = 0;
  bool _isLoading = true;

  Map<String, dynamic>? _descriptions;
  List<Map<String, dynamic>> _applications = [];
  List<Map<String, dynamic>> _files = [];

  final ExpansibleController featuresCtrl = ExpansibleController();
  final ExpansibleController specsCtrl = ExpansibleController();
  final ExpansibleController optionsCtrl = ExpansibleController();
  final ExpansibleController docsCtrl = ExpansibleController();

  ProductDetailsProvider({
    required EbaraDataService dataService,
    required DownloadService downloadService,
  }) : _dataService = dataService,
       _downloadService = downloadService;

  int get currentIndex => _currentIndex;
  int get comparisonBaseIndex => _comparisonBaseIndex;
  bool get isLoading => _isLoading;
  Map<String, dynamic>? get descriptions => _descriptions;
  List<Map<String, dynamic>> get applications => _applications;
  List<Map<String, dynamic>> get files => _files;

  Future<void> initProductView({
    required String productId,
    required int languageId,
    required ProductModel product,
    required String category,
    required HistoryProvider historyProvider,
  }) async {
    _currentIndex = 0;
    _comparisonBaseIndex = 0;
    _isLoading = true;
    _collapseAllSections();
    notifyListeners();

    historyProvider.addToHistory(product.toMap(), category);
    AnalyticsService.logViewProduct(product.productId, product.name, category);

    final results = await Future.wait([
      _dataService.getProductDescriptions(productId, idLanguage: languageId),
      _dataService.getProductApplications(productId, idLanguage: languageId),
      _dataService.getProductFiles(productId, idLanguage: languageId),
    ]);

    _descriptions = results[0] as Map<String, dynamic>?;
    _applications = results[1] as List<Map<String, dynamic>>;
    _files = results[2] as List<Map<String, dynamic>>;

    _isLoading = false;
    notifyListeners();
  }

  void updateIndex(int index) {
    _currentIndex = index;
    _collapseAllSections();
    notifyListeners();
  }

  void setComparisonBase(int index) {
    _comparisonBaseIndex = index;
    HapticFeedback.mediumImpact();
    notifyListeners();
  }

  Future<bool> checkFileStatus(String fileName) async {
    return _downloadService.isFileDownloaded(fileName);
  }

  Future<void> openDocument(
    BuildContext context, {
    required Map<String, dynamic> fileData,
    required Function(double) onProgress,
    required VoidCallback onStart,
    required VoidCallback onFinish,
    required String productName,
  }) async {
    onStart();
    final String fileName = fileData['file'];
    final String url = fileData['full_url'];
    final String extension = fileData['extension'] ?? '';
    final String title = fileData['name'];
    final bool isPdf = extension.toLowerCase() == 'pdf';

    AnalyticsService.logDownloadDocument(title, productName);

    try {
      final isDownloaded = await _downloadService.isFileDownloaded(fileName);

      if (isDownloaded) {
        if (isPdf) {
          final localFile = await _downloadService.getLocalFile(fileName);
          if (localFile != null && context.mounted) {
            context.pushNamed(
              AppRoutes.pdfViewer,
              extra: {'path': localFile.path, 'title': title},
            );
          }
        } else {
          await _downloadService.openFile(fileName, url);
        }
      } else {
        if (Uri.base.scheme.startsWith('http')) {
          await _downloadService.openFile(fileName, url);
        } else {
          await _downloadService.downloadFile(
            url: url,
            filename: fileName,
            onProgress: onProgress,
          );

          if (isPdf) {
            final localFile = await _downloadService.getLocalFile(fileName);
            if (localFile != null && context.mounted) {
              context.pushNamed(
                AppRoutes.pdfViewer,
                extra: {'path': localFile.path, 'title': title},
              );
            }
          } else {
            await _downloadService.openFile(fileName, url);
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        context.showSnackBar(
          context.l10n.translate('error_downloading'),
          isError: true,
        );
      }
    } finally {
      onFinish();
    }
  }

  Future<void> shareProduct(
    ProductModel product,
    String shareTextTemplate,
  ) async {
    final String name = product.name;
    final String model = product.model;
    final String link = product.ecommerceLink ?? 'https://ebara.com.br';
    final String imageUrl = product.image;

    final text = shareTextTemplate
        .replaceAll('{name}', name)
        .replaceAll('{model}', model);

    final fullText = '$text $link';

    if (imageUrl.isNotEmpty && imageUrl.startsWith('http')) {
      try {
        final dio = Dio();
        final response = await dio.get<List<int>>(
          imageUrl,
          options: Options(responseType: ResponseType.bytes),
        );
        final bytes = response.data!;
        final temp = await getTemporaryDirectory();
        final path = '${temp.path}/${name}_$model.jpg';
        File(path).writeAsBytesSync(bytes);

        await SharePlus.instance.share(
          ShareParams(text: fullText, files: [XFile(path)]),
        );
        return;
      } catch (_) {}
    }

    await SharePlus.instance.share(ShareParams(text: fullText));
  }

  Future<void> launchEcommerce(String? url) async {
    if (url == null || url.isEmpty) {
      return;
    }
    final Uri uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<List<RepresentativeModel>> fetchRepresentatives({
    required String state,
    required int languageId,
    String? brandId,
  }) async {
    final rawData = await _dataService.getRepresentatives(
      state: state,
      idLanguage: languageId,
      brandId: brandId,
    );
    return rawData.map((e) => RepresentativeModel.fromJson(e)).toList();
  }

  void handleSectionExpansion(ExpansibleController selected) {
    if (selected != featuresCtrl && featuresCtrl.isExpanded) {
      featuresCtrl.collapse();
    }
    if (selected != specsCtrl && specsCtrl.isExpanded) {
      specsCtrl.collapse();
    }
    if (selected != optionsCtrl && optionsCtrl.isExpanded) {
      optionsCtrl.collapse();
    }
    if (selected != docsCtrl && docsCtrl.isExpanded) {
      docsCtrl.collapse();
    }
  }

  void _collapseAllSections() {
    if (featuresCtrl.isExpanded) featuresCtrl.collapse();
    if (specsCtrl.isExpanded) specsCtrl.collapse();
    if (optionsCtrl.isExpanded) optionsCtrl.collapse();
    if (docsCtrl.isExpanded) docsCtrl.collapse();
  }
}
