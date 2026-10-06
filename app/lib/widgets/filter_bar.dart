import 'package:flutter/material.dart';

import '../models/place.dart';
import '../util.dart';

class SearchBox extends StatefulWidget {
  const SearchBox({super.key, required this.initial, required this.onChanged});

  final String initial;
  final ValueChanged<String> onChanged;

  @override
  State<SearchBox> createState() => _SearchBoxState();
}

class _SearchBoxState extends State<SearchBox> {
  late final TextEditingController _c =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _c,
      onChanged: (v) {
        widget.onChanged(v);
        setState(() {});
      },
      textInputAction: TextInputAction.search,
      style: const TextStyle(color: Colors.white),
      cursorColor: Colors.white,
      decoration: InputDecoration(
        hintText: 'Search places',
        hintStyle: TextStyle(color: Colors.white.fade(0.6)),
        prefixIcon: const Icon(Icons.search, color: Colors.white70),
        suffixIcon: _c.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                icon: const Icon(Icons.close, color: Colors.white70),
                onPressed: () {
                  _c.clear();
                  widget.onChanged('');
                  setState(() {});
                },
              ),
        filled: true,
        fillColor: Colors.white.fade(0.18),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class MoodChips extends StatelessWidget {
  const MoodChips({
    super.key,
    required this.selected,
    required this.onSelected,
    this.padding = EdgeInsets.zero,
  });

  final Mood selected;
  final ValueChanged<Mood> onSelected;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: padding,
        children: [for (final m in Mood.values) _chip(m)],
      ),
    );
  }

  Widget _chip(Mood m) {
    final on = selected == m;
    return Semantics(
      button: true,
      selected: on,
      label: m.label,
      child: GestureDetector(
        onTap: () => onSelected(m),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? Colors.white : Colors.white.fade(0.18),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            m.label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: on ? Colors.black87 : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
