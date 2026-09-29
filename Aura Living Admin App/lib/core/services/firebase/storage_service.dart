import 'dart:async';
import 'dart:typed_data';
import 'firestore_collections.dart';

/// Progress callback for file upload streams
typedef UploadProgressCallback = void Function(double progressPercentage);

/// Contract for Cloud Storage Operations (Firebase Cloud Storage ready)
abstract class StorageService {
  /// Upload a raw file buffer to cloud storage and retrieve download URL
  Future<String> uploadProductImage({
    required String productId,
    required Uint8List bytes,
    required String fileName,
    String contentType = 'image/jpeg',
    UploadProgressCallback? onProgress,
  });

  /// Upload promotional banner image
  Future<String> uploadBannerImage({
    required Uint8List bytes,
    required String fileName,
    UploadProgressCallback? onProgress,
  });

  /// Delete asset from cloud storage
  Future<void> deleteFile(String fileUrl);
}

/// Firebase Cloud Storage Service Implementation with local fallback
class FirebaseStorageService implements StorageService {
  final String bucketName;

  FirebaseStorageService({this.bucketName = 'aura-living-bd.appspot.com'});

  @override
  Future<String> uploadProductImage({
    required String productId,
    required Uint8List bytes,
    required String fileName,
    String contentType = 'image/jpeg',
    UploadProgressCallback? onProgress,
  }) async {
    // In full Firebase integration:
    // final ref = FirebaseStorage.instance
    //     .ref()
    //     .child('${FirestoreCollections.storageProducts}/$productId/$fileName');
    // final uploadTask = ref.putData(bytes, SettableMetadata(contentType: contentType));
    // uploadTask.snapshotEvents.listen((event) {
    //   final progress = event.bytesTransferred / event.totalBytes;
    //   onProgress?.call(progress);
    // });
    // final snapshot = await uploadTask;
    // return await snapshot.ref.getDownloadURL();

    // Simulated cloud upload with realistic latency
    onProgress?.call(0.2);
    await Future.delayed(const Duration(milliseconds: 300));
    onProgress?.call(0.65);
    await Future.delayed(const Duration(milliseconds: 300));
    onProgress?.call(1.0);

    return 'https://firebasestorage.googleapis.com/v0/b/$bucketName/o/${FirestoreCollections.storageProducts}%2F$productId%2F$fileName?alt=media';
  }

  @override
  Future<String> uploadBannerImage({
    required Uint8List bytes,
    required String fileName,
    UploadProgressCallback? onProgress,
  }) async {
    onProgress?.call(0.5);
    await Future.delayed(const Duration(milliseconds: 400));
    onProgress?.call(1.0);
    return 'https://firebasestorage.googleapis.com/v0/b/$bucketName/o/${FirestoreCollections.storageBanners}%2F$fileName?alt=media';
  }

  @override
  Future<void> deleteFile(String fileUrl) async {
    // In full Firebase integration:
    // final ref = FirebaseStorage.instance.refFromURL(fileUrl);
    // await ref.delete();
    await Future.delayed(const Duration(milliseconds: 200));
  }
}
