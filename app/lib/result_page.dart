import 'package:app/services/models/meme.dart';
import 'package:app/widgets/meme_display.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ResultPage extends StatefulWidget {
  final Meme meme;

  const ResultPage({super.key, required this.meme});

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MemeDisplay(meme: widget.meme),

            SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _copy(widget.meme.url),
              label: Text(widget.meme.url.substring(0, 20)),
              icon: Icon(Icons.copy),
            ),
          ],
        ),
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
