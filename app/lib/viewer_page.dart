import 'package:app/widgets/meme_display.dart';
import 'package:app/widgets/share_builder.dart';
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            MemeDisplay(url: widget.url),
            SizedBox(height: 16),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextButton.icon(
                  onPressed: () => _copy(widget.url),
                  label: Text('Copy Link'),
                  icon: Icon(Icons.copy),
                ),
                SizedBox(height: 4),
                ShareBuilder(
                  data: Data(url: widget.url),
                  builder: (context, onShare) {
                    if (onShare == null) {
                      return SizedBox.shrink();
                    }
                    return TextButton.icon(
                      onPressed: onShare,
                      label: Text('Share Meme'),
                      icon: Icon(Icons.ios_share),
                    );
                  },
                ),
              ],
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
        width: 500 - 16 * 2,
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: Colors.white),
          borderRadius: BorderRadiusGeometry.all(Radius.circular(8)),
        ),
        content: Text('Link Copied', style: TextStyle(color: Colors.white)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
