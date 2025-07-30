import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/utils/bloc_extensions.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  List<DocumentItem> _documents = [];

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  void _loadDocuments() {
    // Mock data - in a real app, this would come from API
    setState(() {
      _documents = [
        DocumentItem(
          id: 'doc_1',
          title: 'Driving License',
          description: 'Valid driving license with photo',
          type: DocumentType.drivingLicense,
          isRequired: true,
          status: DocumentStatus.approved,
          uploadDate: DateTime.now().subtract(const Duration(days: 30)),
          expiryDate: DateTime.now().add(const Duration(days: 365)),
          fileName: 'driving_license.pdf',
        ),
        DocumentItem(
          id: 'doc_2',
          title: 'Vehicle Registration',
          description: 'Vehicle registration certificate',
          type: DocumentType.vehicleRegistration,
          isRequired: true,
          status: DocumentStatus.pending,
          uploadDate: DateTime.now().subtract(const Duration(days: 2)),
          expiryDate: DateTime.now().add(const Duration(days: 180)),
          fileName: 'vehicle_registration.jpg',
        ),
        DocumentItem(
          id: 'doc_3',
          title: 'Insurance Certificate',
          description: 'Valid vehicle insurance certificate',
          type: DocumentType.insurance,
          isRequired: true,
          status: DocumentStatus.rejected,
          uploadDate: DateTime.now().subtract(const Duration(days: 7)),
          expiryDate: DateTime.now().add(const Duration(days: 120)),
          fileName: 'insurance_cert.pdf',
          rejectionReason: 'Document image is not clear. Please upload a higher quality image.',
        ),
        DocumentItem(
          id: 'doc_4',
          title: 'Identity Proof',
          description: 'Government issued ID card or passport',
          type: DocumentType.identity,
          isRequired: true,
          status: DocumentStatus.notUploaded,
        ),
        DocumentItem(
          id: 'doc_5',
          title: 'Background Check',
          description: 'Criminal background verification',
          type: DocumentType.backgroundCheck,
          isRequired: false,
          status: DocumentStatus.notUploaded,
        ),
      ];
    });
  }

  Future<void> _uploadDocument(DocumentItem document) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final fileName = result.files.single.name;

        // Simulate upload process
        await _simulateUpload(document, fileName);
      }
    } catch (e) {
      context.showErrorSnackBar('Failed to upload document: ${e.toString()}');
    }
  }

  Future<void> _simulateUpload(DocumentItem document, String fileName) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Uploading document...'),
          ],
        ),
      ),
    );

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    Navigator.pop(context); // Close loading dialog

    // Update document status
    setState(() {
      final index = _documents.indexWhere((doc) => doc.id == document.id);
      if (index != -1) {
        _documents[index] = document.copyWith(
          status: DocumentStatus.pending,
          uploadDate: DateTime.now(),
          fileName: fileName,
        );
      }
    });

    context.showSuccessSnackBar('Document uploaded successfully!');
  }

  void _viewDocument(DocumentItem document) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(document.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('File: ${document.fileName ?? 'No file'}'),
            if (document.uploadDate != null)
              Text('Uploaded: ${_formatDate(document.uploadDate!)}'),
            if (document.expiryDate != null)
              Text('Expires: ${_formatDate(document.expiryDate!)}'),
            const SizedBox(height: 16),
            Text(
              'Status: ${document.status.displayName}',
              style: TextStyle(
                color: _getStatusColor(document.status),
                fontWeight: FontWeight.w600,
              ),
            ),
            if (document.rejectionReason != null) ...[
              const SizedBox(height: 8),
              Text(
                'Rejection Reason:',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                document.rejectionReason!,
                style: const TextStyle(color: AppColors.error),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (document.status == DocumentStatus.rejected ||
              document.status == DocumentStatus.notUploaded)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _uploadDocument(document);
              },
              child: const Text('Upload New'),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _getStatusColor(DocumentStatus status) {
    switch (status) {
      case DocumentStatus.approved:
        return AppColors.success;
      case DocumentStatus.pending:
        return AppColors.warning;
      case DocumentStatus.rejected:
        return AppColors.error;
      case DocumentStatus.notUploaded:
        return AppColors.textSecondary;
    }
  }

  IconData _getStatusIcon(DocumentStatus status) {
    switch (status) {
      case DocumentStatus.approved:
        return Icons.check_circle;
      case DocumentStatus.pending:
        return Icons.schedule;
      case DocumentStatus.rejected:
        return Icons.cancel;
      case DocumentStatus.notUploaded:
        return Icons.upload_file;
    }
  }

  @override
  Widget build(BuildContext context) {
    final requiredDocs = _documents.where((doc) => doc.isRequired).toList();
    final optionalDocs = _documents.where((doc) => !doc.isRequired).toList();
    final completedRequired = requiredDocs.where((doc) => doc.status == DocumentStatus.approved).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Documents'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildProgressHeader(completedRequired, requiredDocs.length),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppDimensions.spaceM),
              children: [
                if (requiredDocs.isNotEmpty) ...[
                  _buildSectionHeader('Required Documents'),
                  const SizedBox(height: AppDimensions.spaceM),
                  ...requiredDocs.map((doc) => _buildDocumentCard(doc)),
                ],
                if (optionalDocs.isNotEmpty) ...[
                  const SizedBox(height: AppDimensions.spaceL),
                  _buildSectionHeader('Optional Documents'),
                  const SizedBox(height: AppDimensions.spaceM),
                  ...optionalDocs.map((doc) => _buildDocumentCard(doc)),
                ],
                const SizedBox(height: AppDimensions.spaceXL),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressHeader(int completed, int total) {
    final progress = total > 0 ? completed / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceL),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.divider),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Document Verification',
                      style: AppTextStyles.headlineSmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '$completed of $total required documents approved',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(AppDimensions.spaceS),
                decoration: BoxDecoration(
                  color: progress == 1.0 ? AppColors.success.withOpacity(0.1) : AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                ),
                child: Icon(
                  progress == 1.0 ? Icons.verified : Icons.pending,
                  color: progress == 1.0 ? AppColors.success : AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceM),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.divider,
            valueColor: AlwaysStoppedAnimation<Color>(
              progress == 1.0 ? AppColors.success : AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: AppTextStyles.headlineSmall.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildDocumentCard(DocumentItem document) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spaceM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(
          color: document.isRequired && document.status == DocumentStatus.notUploaded
              ? AppColors.error.withOpacity(0.3)
              : Colors.transparent,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.textHint.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _viewDocument(document),
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.spaceM),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppDimensions.spaceS),
                      decoration: BoxDecoration(
                        color: _getStatusColor(document.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                      ),
                      child: Icon(
                        _getStatusIcon(document.status),
                        color: _getStatusColor(document.status),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spaceM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                document.title,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (document.isRequired) ...[
                                const SizedBox(width: AppDimensions.spaceS),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppDimensions.spaceS,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.error.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(AppDimensions.radiusXS),
                                  ),
                                  child: Text(
                                    'Required',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: AppColors.error,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Text(
                            document.description,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.spaceS,
                        vertical: AppDimensions.spaceXS,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(document.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                        border: Border.all(
                          color: _getStatusColor(document.status).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        document.status.displayName,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: _getStatusColor(document.status),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                if (document.fileName != null || document.expiryDate != null) ...[
                  const SizedBox(height: AppDimensions.spaceM),
                  const Divider(height: 1),
                  const SizedBox(height: AppDimensions.spaceM),
                  Row(
                    children: [
                      if (document.fileName != null) ...[
                        const Icon(
                          Icons.description,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: AppDimensions.spaceS),
                        Expanded(
                          child: Text(
                            document.fileName!,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      if (document.expiryDate != null) ...[
                        const SizedBox(width: AppDimensions.spaceM),
                        const Icon(
                          Icons.schedule,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: AppDimensions.spaceS),
                        Text(
                          'Expires ${_formatDate(document.expiryDate!)}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
                if (document.status == DocumentStatus.rejected && document.rejectionReason != null) ...[
                  const SizedBox(height: AppDimensions.spaceM),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppDimensions.spaceM),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                      border: Border.all(color: AppColors.error.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rejection Reason:',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.spaceXS),
                        Text(
                          document.rejectionReason!,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (document.status == DocumentStatus.notUploaded ||
                    document.status == DocumentStatus.rejected) ...[
                  const SizedBox(height: AppDimensions.spaceM),
                  CustomButton(
                    text: document.status == DocumentStatus.notUploaded ? 'Upload Document' : 'Re-upload Document',
                    onPressed: () => _uploadDocument(document),
                    variant: ButtonVariant.primary,
                    size: ButtonSize.medium,
                    isExpanded: true,
                    prefixIcon: const Icon(
                      Icons.upload_file,
                      color: AppColors.surface,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Document Models
class DocumentItem {
  final String id;
  final String title;
  final String description;
  final DocumentType type;
  final bool isRequired;
  final DocumentStatus status;
  final DateTime? uploadDate;
  final DateTime? expiryDate;
  final String? fileName;
  final String? rejectionReason;

  DocumentItem({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.isRequired,
    required this.status,
    this.uploadDate,
    this.expiryDate,
    this.fileName,
    this.rejectionReason,
  });

  DocumentItem copyWith({
    String? id,
    String? title,
    String? description,
    DocumentType? type,
    bool? isRequired,
    DocumentStatus? status,
    DateTime? uploadDate,
    DateTime? expiryDate,
    String? fileName,
    String? rejectionReason,
  }) {
    return DocumentItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      isRequired: isRequired ?? this.isRequired,
      status: status ?? this.status,
      uploadDate: uploadDate ?? this.uploadDate,
      expiryDate: expiryDate ?? this.expiryDate,
      fileName: fileName ?? this.fileName,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }
}

enum DocumentType {
  drivingLicense,
  vehicleRegistration,
  insurance,
  identity,
  backgroundCheck,
}

enum DocumentStatus {
  notUploaded,
  pending,
  approved,
  rejected,
}

extension DocumentStatusExtension on DocumentStatus {
  String get displayName {
    switch (this) {
      case DocumentStatus.notUploaded:
        return 'Not Uploaded';
      case DocumentStatus.pending:
        return 'Under Review';
      case DocumentStatus.approved:
        return 'Approved';
      case DocumentStatus.rejected:
        return 'Rejected';
    }
  }
}