import 'package:flutter/material.dart';

class SearchField extends StatelessWidget {
  final TextEditingController controller;
  final bool autofocus;
  final void Function(String query) onQuery;
  final VoidCallback onClear;

  const SearchField({
    super.key,
    required this.controller,
    this.autofocus = false,
    required this.onQuery,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 500,
      child: TextFormField(
        controller: controller,
        autofocus: autofocus,
        onChanged: onQuery,
        textInputAction: TextInputAction.search,
        textCapitalization: TextCapitalization.words,
        style: TextStyle(fontSize: 18),
        decoration: InputDecoration(
          hintText: 'Search Pure Pwnage Quotes',
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 4),
            child: Icon(Icons.search),
          ),
          suffixIcon: ValueListenableBuilder(
            valueListenable: controller,
            builder: (context, value, child) {
              if (value.text.isEmpty) {
                return SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    controller.clear();
                    onClear();
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
