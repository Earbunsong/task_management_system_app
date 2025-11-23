import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:task_management_app/services/api_client.dart';

class MediaFile {
  final int id;
  final String fileUrl;
  final String fileType;
  final String uploadedAt;

  MediaFile({
    required this.id,
    required this.fileUrl,
    required this.fileType,
    required this.uploadedAt,
  });

  factory MediaFile.fromJson(Map<String, dynamic> json) {
    return MediaFile(
      id: json['id'] as int,
      fileUrl: json['file_url'] as String,
      fileType: json['file_type'] as String? ?? '',
      uploadedAt: json['uploaded_at'] as String? ?? '',
    );
  }
}

class MediaService {
  final _client = ApiClient()..init();

  /// Get all media files for a task
  Future<List<MediaFile>> getTaskMedia(int taskId) async {
    final res = await _client.dio.get('/tasks/$taskId/media/');
    final list = res.data as List<dynamic>;
    return list.map((e) => MediaFile.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Upload media file to task
  Future<MediaFile> uploadMedia(int taskId, File file) async {
    // Get MIME type
    final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
    final mimeTypeParts = mimeType.split('/');

    // Create multipart file
    final multipartFile = await MultipartFile.fromFile(
      file.path,
      filename: file.path.split(Platform.pathSeparator).last,
      contentType: MediaType(mimeTypeParts[0], mimeTypeParts[1]),
    );

    // Create form data
    final formData = FormData.fromMap({
      'file': multipartFile,
    });

    // Upload to backend
    final res = await _client.dio.post(
      '/tasks/$taskId/media/',
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
        followRedirects: false,
        validateStatus: (status) => status! < 500,
      ),
    );

    if (res.statusCode == 201) {
      return MediaFile.fromJson(res.data);
    } else {
      throw Exception('Failed to upload media: ${res.data}');
    }
  }

  /// Delete media file
  Future<void> deleteMedia(int taskId, int mediaId) async {
    await _client.dio.delete(
      '/tasks/$taskId/media/',
      data: {'media_id': mediaId},
    );
  }
}
