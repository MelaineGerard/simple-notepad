import 'dart:convert';
import 'dart:typed_data';

enum TextEncoding {
  utf8('UTF-8'), utf8Bom('UTF-8 with BOM'),
  utf16le('UTF-16 LE'), utf16be('UTF-16 BE'),
  latin1('ISO-8859-1'), ascii('ASCII');

  final String label;
  const TextEncoding(this.label);

  static TextEncoding detect(List<int> bytes) {
    if (bytes.length >= 3 && bytes[0] == 0xef && bytes[1] == 0xbb && bytes[2] == 0xbf) {
      return utf8Bom;
    }
    if (bytes.length >= 2 && bytes[0] == 0xff && bytes[1] == 0xfe) return utf16le;
    if (bytes.length >= 2 && bytes[0] == 0xfe && bytes[1] == 0xff) return utf16be;
    return utf8;
  }

  String decode(List<int> input) {
    final bytes = Uint8List.fromList(input);
    switch (this) {
      case utf8:
      case utf8Bom:
        final start = bytes.length >= 3 && bytes[0] == 0xef &&
            bytes[1] == 0xbb && bytes[2] == 0xbf ? 3 : 0;
        return const Utf8Decoder().convert(bytes.sublist(start));
      case latin1:
        return const Latin1Codec().decode(bytes);
      case ascii:
        return const AsciiCodec().decode(bytes);
      case utf16le:
      case utf16be:
        if (bytes.length.isOdd) throw const FormatException('Incomplete UTF-16 code unit');
        final endian = this == utf16le ? Endian.little : Endian.big;
        final data = ByteData.sublistView(bytes);
        var start = 0;
        if (bytes.length >= 2 && data.getUint16(0, endian) == 0xfeff) start = 2;
        final units = <int>[];
        for (var i = start; i < bytes.length; i += 2) {
          units.add(data.getUint16(i, endian));
        }
        for (var i = 0; i < units.length; i++) {
          final unit = units[i];
          if (unit >= 0xd800 && unit <= 0xdbff) {
            if (++i >= units.length || units[i] < 0xdc00 || units[i] > 0xdfff) {
              throw const FormatException('Invalid UTF-16 surrogate pair');
            }
          } else if (unit >= 0xdc00 && unit <= 0xdfff) {
            throw const FormatException('Invalid UTF-16 surrogate pair');
          }
        }
        return String.fromCharCodes(units);
    }
  }

  Uint8List encode(String text) {
    switch (this) {
      case utf8:
        return Uint8List.fromList(const Utf8Encoder().convert(text));
      case utf8Bom:
        return Uint8List.fromList([0xef, 0xbb, 0xbf, ...const Utf8Encoder().convert(text)]);
      case latin1:
        return Uint8List.fromList(const Latin1Codec().encode(text));
      case ascii:
        return Uint8List.fromList(const AsciiCodec().encode(text));
      case utf16le:
      case utf16be:
        final endian = this == utf16le ? Endian.little : Endian.big;
        final bytes = Uint8List((text.length + 1) * 2);
        final data = ByteData.sublistView(bytes)..setUint16(0, 0xfeff, endian);
        for (var i = 0; i < text.length; i++) {
          data.setUint16((i + 1) * 2, text.codeUnitAt(i), endian);
        }
        return bytes;
    }
  }
}
