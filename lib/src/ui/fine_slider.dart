import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Preview while dragging; commit on release so whole-window zoom does not
/// move its own slider under the pointer. Typing is committed explicitly.
class FineSlider extends StatefulWidget {
  const FineSlider({
    super.key,
    required this.id,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.onPreview,
    this.unit = '',
  });
  final String id;
  final String label;
  final int value;
  final int min;
  final int max;
  final String unit;
  final ValueChanged<int> onChanged;
  final ValueChanged<int>? onPreview;

  @override
  State<FineSlider> createState() => _FineSliderState();
}

class _FineSliderState extends State<FineSlider> {
  late int _draft = widget.value;
  late final _text = TextEditingController(text: '$_draft');
  String? _error;
  bool _dragging = false;

  @override
  void didUpdateWidget(FineSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_dragging && oldWidget.value != widget.value) {
      _draft = widget.value;
      _text.text = '$_draft';
      _error = null;
    }
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _preview(int value, {bool updateText = true}) {
    setState(() {
      _draft = value;
      _error = null;
      if (updateText) _text.text = '$value';
    });
    widget.onPreview?.call(value);
  }

  void _submit() {
    final value = int.tryParse(_text.text);
    if (value == null || value < widget.min || value > widget.max) {
      setState(() => _error = '${widget.min}–${widget.max} arası');
      return;
    }
    _preview(value);
    widget.onChanged(value);
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Slider(
              key: Key('${widget.id}-slider'),
              value: _draft.toDouble(),
              min: widget.min.toDouble(),
              max: widget.max.toDouble(),
              divisions: widget.max - widget.min,
              label: '$_draft${widget.unit}',
              semanticFormatterCallback: (v) => '${v.round()}${widget.unit}',
              onChangeStart: (_) => _dragging = true,
              onChanged: (value) => _preview(value.round()),
              onChangeEnd: (value) {
                _dragging = false;
                widget.onChanged(value.round());
              },
            ),
          ),
          SizedBox(
            width: 112,
            child: TextField(
              key: Key('${widget.id}-value'),
              controller: _text,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              decoration: InputDecoration(
                labelText: widget.label,
                suffixText: widget.unit,
                errorText: _error,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (raw) {
                final value = int.tryParse(raw);
                if (value != null &&
                    value >= widget.min &&
                    value <= widget.max) {
                  _preview(value, updateText: false);
                } else {
                  setState(() => _error = '${widget.min}–${widget.max} arası');
                }
              },
              onSubmitted: (_) => _submit(),
            ),
          ),
        ],
      ),
      Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          key: Key('${widget.id}-apply'),
          onPressed: _submit,
          child: const Text('Uygula'),
        ),
      ),
    ],
  );
}
