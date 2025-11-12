import 'dart:convert';

import 'package:app/widgets/meme_display.dart';
import 'package:app/widgets/share_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:web/web.dart' as web;

class ViewerPage extends StatefulWidget {
  final String id;
  final String url;

  const ViewerPage({super.key, required this.id, required this.url});

  @override
  State<ViewerPage> createState() => _ViewerPageState();
}

class _ViewerPageState extends State<ViewerPage> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                MemeDisplay(url: widget.url),
                SizedBox(height: 64),
                OutlinedButton.icon(
                  onPressed: () => _download(widget.url),
                  label: Text('Download'),
                  icon: Icon(Icons.download),
                ),
                SizedBox(height: 16),
                ShareBuilder(
                  data: Data(url: widget.url),
                  builder: (context, onShare) {
                    if (onShare == null) {
                      return FilledButton.icon(
                        onPressed: () => _copy(widget.url),
                        label: Text('Copy Link'),
                        icon: Icon(Icons.copy),
                      );
                    }
                    return OutlinedButton.icon(
                      onPressed: () => _copy(widget.url),
                      label: Text('Copy Link'),
                      icon: Icon(Icons.copy),
                    );
                  },
                ),
                SizedBox(height: 16),
                ShareBuilder(
                  data: Data(url: widget.url),
                  builder: (context, onShare) {
                    if (onShare == null) {
                      return SizedBox.shrink();
                    }
                    return FilledButton.icon(
                      onPressed: () {},
                      label: Text('Share Meme'),
                      icon: Icon(Icons.ios_share),
                    );
                  },
                ),
                SizedBox(height: 64),
                TextButton(
                  onPressed: () => context.goNamed('home'),
                  child: Text('Create Another'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _copy(String url) {
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Link Copied')));
  }

  void _download(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      return;
    }
    final bas64Encoded = base64Encode(response.bodyBytes);
    final href =
        'data:application/octet-stream;charset=utf-16le;base64,$bas64Encoded';
    final filename = 'pp_meme_${widget.id}';
    web.HTMLAnchorElement()
      ..href = href
      ..download = filename
      ..click();
  }
}
