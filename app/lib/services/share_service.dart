import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'share_service.freezed.dart';

@freezed
abstract class ShareData with _$ShareData {
  const factory ShareData({
    @Default(null) String? title,
    @Default(null) String? text,
    @Default(null) String? url,
  }) = _ShareData;
}

@JS()
@staticInterop
class Navigator {
  external factory Navigator();
}

extension _NavigatorShare on Navigator {
  external JSBoolean canShare(_ShareOptions options);
  external JSPromise share(_ShareOptions options);
}

@JS()
@anonymous
@staticInterop
class _ShareOptions {
  external factory _ShareOptions({String? title, String? text, String? url});
}

@JS('navigator')
external Navigator? get navigator;

Future<bool> canShare(ShareData data) async {
  if (navigator == null) {
    return false;
  }
  try {
    return navigator
            ?.canShare(
              _ShareOptions(title: data.title, text: data.text, url: data.url),
            )
            .toDart ??
        false;
  } catch (e) {
    return false;
  }
}

Future<void> shareContent(ShareData data) async {
  if (navigator == null) {
    debugPrint('Web Share API is not supported on this browser.');
    return;
  }

  try {
    await navigator?.share(_ShareOptions(title: data.url)).toDart;
  } catch (e) {
    debugPrint('Error sharing: $e');
  }
}
