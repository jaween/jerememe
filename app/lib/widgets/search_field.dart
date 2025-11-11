import 'package:flutter/material.dart';

class SearchField extends StatelessWidget {
  final bool autofocus;
  final String? initialValue;
  final void Function(String query) onQuery;

  const SearchField({
    super.key,
    this.autofocus = false,
    this.initialValue,
    required this.onQuery,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 500,
      child: TextFormField(
        autofocus: autofocus,
        onChanged: onQuery,
        initialValue: initialValue,
        textInputAction: TextInputAction.search,
        textCapitalization: TextCapitalization.words,
        style: TextStyle(fontSize: 18),
        decoration: InputDecoration(
          hintText: 'Search Pure Pwnage Quotes',
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 20.0, right: 4),
            child: Icon(Icons.search),
          ),
        ),
      ),
    );
  }
}
