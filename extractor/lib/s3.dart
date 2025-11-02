import 'dart:typed_data';

import 'package:aws_s3_api/s3-2006-03-01.dart' as aws;

class S3Storage {
  late final aws.S3 _s3;
  final String _bucket;

  S3Storage({
    required String accessKey,
    required String secretKey,
    required String region,
    required String bucket,
  }) : _bucket = bucket {
    final credentials = aws.AwsClientCredentials(
      accessKey: accessKey,
      secretKey: secretKey,
    );
    _s3 = aws.S3(region: region, credentials: credentials);
  }

  Future<void> upload({
    required String key,
    required Uint8List data,
    String? contentType,
  }) async {
    await _s3.putObject(
      bucket: _bucket,
      key: key,
      body: data,
      contentType: contentType,
    );
  }
}
