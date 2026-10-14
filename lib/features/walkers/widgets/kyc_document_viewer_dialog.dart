import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

const Color _kycOrange = Color(0xFFFF7900);
const Color _kycBackground = Color(0xFFFFFAF5);
const Color _kycText = Color(0xFF292524);
const Color _kycMuted = Color(0xFF78716C';

/// Opens a KYC document in a popup dialog.
///
/// Supports HTTPS URLs, Firebase Storage URLs,
/// Storage paths, and map-based document references.
Future<void> showKycDocumentViewerDialog({
  required BuildContext context,
  required String title,
  required dynamic document,
}) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    useSafeArea: true,
    builder: (_) => KycDocumentViewerDialog(
      title: title,
      document: document,
    ),
  );
}

class KycDocumentViewerDialog extends StatefulWidget {
  const KycDocumentViewerDialog({
    super.key,
    required this.title,
    required this.document,
  });

  final String title;
  final dynamic document;

  @override
  State<KycDocumentViewerDialog> createState() =>
      _KycDocumentViewerDialogState();
}

class _KycDocumentViewerDialogState
    extends State<KycDocumentViewerDialog> {
  String? _documentUrl;
  String? _error;

  bool _loading = true;
  bool _isPdf = false;

  late final PdfViewerController _pdfController;

  final TransformationController _imageController =
      TransformationController();

  double _imageScale = 1.0;

  @override
  void initState() {
    super.initState();

    _pdfController = PdfViewerController();
    _resolveDocument();
  }

  @override
  void dispose() {
    // PdfViewerController in the project's pdfrx version
    // does not expose dispose().
    _imageController.dispose();
    super.dispose();
  }

  Future<void> _resolveDocument() async {
    try {
      final reference = _extractReference(widget.document);

      if (reference == null || reference.isEmpty) {
        throw Exception('Document link is missing.');
      }

      String resolvedUrl;

      if (_isHttpUrl(reference)) {
        resolvedUrl = reference;
      } else {
        resolvedUrl = await FirebaseStorage.instance
            .ref(reference)
            .getDownloadURL();
      }

      final isPdf = _detectPdf(
        resolvedUrl,
        widget.document,
      );

      if (!mounted) return;

      setState(() {
        _documentUrl = resolvedUrl;
        _isPdf = isPdf;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = _friendlyError(e);
      });
    }
  }

  String? _extractReference(dynamic document) {
    if (document is String && document.trim().isNotEmpty) {
      return document.trim();
    }

    if (document is Map) {
      final url = document['downloadUrl'] ?? document['url'];

      if (url is String && url.trim().isNotEmpty) {
        return url.trim();
      }

      final path = document['storagePath'] ?? document['path'];

      if (path is String && path.trim().isNotEmpty) {
        return path.trim();
      }
    }

    return null;
  }

  bool _isHttpUrl(String value) {
    final uri = Uri.tryParse(value);

    return uri != null &&
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host.isNotEmpty;
  }

  bool _detectPdf(String url, dynamic document) {
    if (document is Map) {
      final type = document['contentType'] ??
          document['mimeType'] ??
          document['type'];

      if (type is String) {
        final normalized = type.toLowerCase().trim();

        if (normalized == 'application/pdf' ||
            normalized == 'pdf') {
          return true;
        }

        if (normalized.startsWith('image/')) {
          return false;
        }
      }
    }

    final uri = Uri.tryParse(url);
    final path = uri?.path.toLowerCase() ?? '';

    if (path.endsWith('.pdf')) {
      return true;
    }

    if (path.endsWith('.png') ||
        path.endsWith('.jpg') ||
        path.endsWith('.jpeg') ||
        path.endsWith('.webp') ||
        path.endsWith('.gif')) {
      return false;
    }

    // If the URL has no extension, use the document metadata
    // above when available. Otherwise, default to image mode.
    return false;
  }

  String _friendlyError(Object error) {
    final message = error.toString().toLowerCase();

    if (message.contains('object-not-found') ||
        message.contains('not found')) {
      return 'Document was not found in storage.';
    }

    if (message.contains('unauthorized') ||
        message.contains('permission') ||
        message.contains('unauthenticated')) {
      return 'You do not have permission to view this document.';
    }

    return 'Unable to load this document. Check its link and access permissions.';
  }

  void _zoomImage(double factor) {
    final nextScale =
        (_imageScale * factor).clamp(1.0, 5.0).toDouble();

    setState(() {
      _imageScale = nextScale;
      _imageController.value = Matrix4.identity()
        ..scaleByDouble(nextScale, nextScale, 1.0, 1.0);
    });
  }

  void _resetImageZoom() {
    setState(() {
      _imageScale = 1.0;
      _imageController.value = Matrix4.identity();
    });
  }

  Future<void> _zoomPdf(bool zoomIn) async {
    if (!_pdfController.isReady) return;

    if (zoomIn) {
      await _pdfController.zoomUp();
    } else {
      await _pdfController.zoomDown();
    }
  }

  Future<void> _fitPdf() async {
    if (!_pdfController.isReady) return;

    final page = _pdfController.pageNumber ?? 1;

    final matrix = _pdfController.calcMatrixForFit(
      pageNumber: page,
    );

    if (matrix != null) {
      await _pdfController.goTo(matrix);
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    final dialogWidth = media.size.width > 850
        ? 760.0
        : media.size.width * 0.96;

    final dialogHeight = media.size.height * 0.88;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 12,
      ),
      backgroundColor: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: Column(
          children: [
            _buildHeader(),
            _buildToolbar(),
            Expanded(
              child: _buildDocumentBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      decoration: const BoxDecoration(
        color: _kycBackground,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE7E5E4)),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: const Color(0xFFFFE8D2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.verified_user_outlined,
              color: _kycOrange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _kycText,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'KYC Document Preview',
                  style: TextStyle(
                    fontSize: 12,
                    color: _kycMuted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Close document',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    final canZoom = !_loading &&
        _error == null &&
        _documentUrl != null;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE7E5E4)),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isPdf
                ? Icons.picture_as_pdf_outlined
                : Icons.image_outlined,
            size: 20,
            color: _kycOrange,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _isPdf ? 'PDF Document' : 'Image Document',
              style: const TextStyle(
                fontSize: 12,
                color: _kycMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Zoom out',
            onPressed: !canZoom
                ? null
                : () {
                    if (_isPdf) {
                      _zoomPdf(false);
                    } else {
                      _zoomImage(1 / 1.25);
                    }
                  },
            icon: const Icon(Icons.remove),
          ),
          IconButton(
            tooltip: 'Fit to screen / Reset zoom',
            onPressed: !canZoom
                ? null
                : () {
                    if (_isPdf) {
                      _fitPdf();
                    } else {
                      _resetImageZoom();
                    }
                  },
            icon: const Icon(Icons.fit_screen_outlined),
          ),
          IconButton(
            tooltip: 'Zoom in',
            onPressed: !canZoom
                ? null
                : () {
                    if (_isPdf) {
                      _zoomPdf(true);
                    } else {
                      _zoomImage(1.25);
                    }
                  },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentBody() {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: _kycOrange,
            ),
            SizedBox(height: 16),
            Text(
              'Loading document...',
              style: TextStyle(color: _kycMuted),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return _buildError();
    }

    final url = _documentUrl;

    if (url == null) {
      return _buildError();
    }

    if (_isPdf) {
      return _buildPdf(url);
    }

    return _buildImage(url);
  }

  Widget _buildPdf(String url) {
    return ColoredBox(
      color: const Color(0xFFF1F0EE),
      child: PdfViewer.uri(
        Uri.parse(url),
        controller: _pdfController,
        params: PdfViewerParams(
          backgroundColor: const Color(0xFFF1F0EE),
          onViewerReady: (document, controller) {
            if (mounted) {
              setState(() {});
            }
          },
        ),
      ),
    );
  }

  Widget _buildImage(String url) {
    return Container(
      color: const Color(0xFFF1F0EE),
      alignment: Alignment.center,
      child: InteractiveViewer(
        transformationController: _imageController,
        minScale: 1,
        maxScale: 5,
        panEnabled: true,
        scaleEnabled: true,
        boundaryMargin: const EdgeInsets.all(80),
        child: Image.network(
          url,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;

            final total = progress.expectedTotalBytes;
            final loaded = progress.cumulativeBytesLoaded;

            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    color: _kycOrange,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    total == null
                        ? 'Loading image...'
                        : 'Loading ${((loaded / total) * 100).round()}%',
                    style: const TextStyle(color: _kycMuted),
                  ),
                ],
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Unable to display this image. Check the image URL and permissions.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _kycMuted),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Unable to load document.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _kycText,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _loading = true;
                  _error = null;
                });

                _resolveDocument();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
