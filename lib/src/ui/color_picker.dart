import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'themes.dart';

String colorHex(Color color) => (color.toARGB32() & 0xFFFFFF)
    .toRadixString(16)
    .padLeft(6, '0')
    .toUpperCase();

Future<Color?> showAppColorPicker(
  BuildContext context, {
  required String title,
  required Color initial,
}) => showDialog<Color>(
  context: context,
  builder: (_) => _ColorPicker(title: title, initial: initial),
);

class _ColorPicker extends StatefulWidget {
  const _ColorPicker({required this.title, required this.initial});
  final String title;
  final Color initial;

  @override
  State<_ColorPicker> createState() => _ColorPickerState();
}

class _ColorPickerState extends State<_ColorPicker> {
  late HSVColor _hsv = HSVColor.fromColor(widget.initial);
  late final _hex = TextEditingController(text: colorHex(widget.initial));
  String? _error;

  Color get _color => _hsv.toColor();

  @override
  void dispose() {
    _hex.dispose();
    super.dispose();
  }

  void _set(HSVColor value) => setState(() {
    _hsv = value;
    final hex = colorHex(_color);
    _hex.value = TextEditingValue(
      text: hex,
      selection: TextSelection.collapsed(offset: hex.length),
    );
    _error = null;
  });

  void _position(Offset at, Size size) => _set(
    _hsv
        .withSaturation((at.dx / size.width).clamp(0.0, 1.0))
        .withValue((1 - at.dy / size.height).clamp(0.0, 1.0)),
  );

  Widget _sample(String label, Color color) => Expanded(
    child: Container(
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: contrastingText(color),
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final rgb = _color.toARGB32();
    final components = [(rgb >> 16) & 255, (rgb >> 8) & 255, rgb & 255];
    return AlertDialog(
      key: const Key('color-picker'),
      title: Text(widget.title),
      scrollable: true,
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _sample('Önceki', widget.initial),
                const SizedBox(width: 12),
                _sample('Seçilen', _color),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = Size(
                    constraints.maxWidth,
                    constraints.maxHeight,
                  );
                  return Semantics(
                    label: 'Doygunluk ve parlaklık renk alanı',
                    child: GestureDetector(
                      key: const Key('color-plane'),
                      onPanDown: (d) => _position(d.localPosition, size),
                      onPanUpdate: (d) => _position(d.localPosition, size),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white,
                                      HSVColor.fromAHSV(
                                        1,
                                        _hsv.hue,
                                        1,
                                        1,
                                      ).toColor(),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const Positioned.fill(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [Colors.transparent, Colors.black],
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: (_hsv.saturation * size.width - 8).clamp(
                                0.0,
                                size.width - 16,
                              ),
                              top: ((1 - _hsv.value) * size.height - 8).clamp(
                                0.0,
                                size.height - 16,
                              ),
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black54,
                                      blurRadius: 3,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Text('Renk tonu', style: Theme.of(context).textTheme.labelLarge),
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 12,
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: const LinearGradient(
                      colors: [
                        Colors.red,
                        Colors.yellow,
                        Colors.green,
                        Colors.cyan,
                        Colors.blue,
                        Colors.purple,
                        Colors.red,
                      ],
                    ),
                  ),
                ),
                Slider(
                  key: const Key('color-hue'),
                  value: _hsv.hue,
                  min: 0,
                  max: 360,
                  activeColor: Colors.transparent,
                  inactiveColor: Colors.transparent,
                  thumbColor: HSVColor.fromAHSV(1, _hsv.hue, 1, 1).toColor(),
                  semanticFormatterCallback: (v) => '${v.round()} derece',
                  onChanged: (v) => _set(_hsv.withHue(v)),
                ),
              ],
            ),
            TextField(
              key: const Key('color-hex'),
              controller: _hex,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp('[0-9a-fA-F]')),
                LengthLimitingTextInputFormatter(6),
              ],
              decoration: InputDecoration(
                labelText: 'HEX renk kodu',
                prefixText: '#',
                hintText: '3366FF',
                border: const OutlineInputBorder(),
                errorText: _error,
              ),
              onChanged: (v) => setState(() {
                final parsed = v.length == 6
                    ? int.tryParse(v, radix: 16)
                    : null;
                _error = parsed == null ? '6 haneli bir renk kodu gir.' : null;
                if (parsed != null) {
                  _hsv = HSVColor.fromColor(Color(0xFF000000 | parsed));
                }
              }),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final rgb in [
                  0xE0B24F,
                  0xF43F5E,
                  0xEC4899,
                  0xA855F7,
                  0x6366F1,
                  0x3B82F6,
                  0x06B6D4,
                  0x10B981,
                  0xFFFFFF,
                  0x171C26,
                ])
                  Tooltip(
                    message: '#${colorHex(Color(0xFF000000 | rgb))}',
                    child: Semantics(
                      button: true,
                      label: '#${colorHex(Color(0xFF000000 | rgb))}',
                      child: InkWell(
                        key: Key('swatch-${rgb.toRadixString(16)}'),
                        onTap: () =>
                            _set(HSVColor.fromColor(Color(0xFF000000 | rgb))),
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Color(0xFF000000 | rgb),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context)
                                  .colorScheme
                                  .outlineVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < 3; i++)
              Row(
                children: [
                  SizedBox(width: 20, child: Text(['R', 'G', 'B'][i])),
                  Expanded(
                    child: Slider(
                      key: Key('color-rgb-$i'),
                      min: 0,
                      max: 255,
                      divisions: 255,
                      value: components[i].toDouble(),
                      semanticFormatterCallback: (v) => '${v.round()}',
                      onChanged: (v) {
                        final next = [...components];
                        next[i] = v.round();
                        _set(
                          HSVColor.fromColor(
                            Color.fromARGB(255, next[0], next[1], next[2]),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(
                    width: 30,
                    child: Text('${components[i]}', textAlign: TextAlign.end),
                  ),
                ],
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const Key('color-cancel'),
          onPressed: () => Navigator.pop(context),
          child: const Text('Vazgeç'),
        ),
        FilledButton(
          key: const Key('color-confirm'),
          onPressed: _error != null
              ? null
              : () => Navigator.pop(context, _color),
          child: const Text('Rengi kullan'),
        ),
      ],
    );
  }
}
