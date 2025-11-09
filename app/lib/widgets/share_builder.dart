import 'package:app/services/share_service.dart';
import 'package:flutter/material.dart';

class ShareBuilder extends StatefulWidget {
  final Data data;
  final Widget Function(BuildContext context, Future<void> Function()? onShare)
  builder;

  const ShareBuilder({super.key, required this.data, required this.builder});

  @override
  State<ShareBuilder> createState() => _ShareBuilderState();
}

class _ShareBuilderState extends State<ShareBuilder> {
  bool _canShare = false;

  @override
  void initState() {
    super.initState();
    _checkShareData(widget.data);
  }

  @override
  void didUpdateWidget(covariant ShareBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      _checkShareData(widget.data);
    }
  }

  void _checkShareData(Data data) async {
    final result = await canShare(ShareData(url: data.url));
    if (mounted) {
      setState(() => _canShare = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(
      context,
      _canShare ? () => shareContent(ShareData(url: widget.data.url)) : null,
    );
  }
}

class Data {
  final String? url;

  Data({required this.url});
}
