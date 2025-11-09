import 'package:app/widgets/meme_display.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ViewerPage extends StatefulWidget {
  final String url;

  const ViewerPage({super.key, required this.url});

  @override
  State<ViewerPage> createState() => _ViewerPageState();
}

class _ViewerPageState extends State<ViewerPage> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          MemeDisplay(url: widget.url),
          SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => _copy(widget.url),
            label: Text(widget.url),
            icon: Icon(Icons.copy),
          ),
        ],
      ),
    );
  }

  void _copy(String url) {
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied To Clipboard'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
