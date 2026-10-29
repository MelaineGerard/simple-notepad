import 'package:flutter_test/flutter_test.dart';
import 'package:simple_notepad/utils/document_statistics.dart';

void main() {
  test('empty document has one logical line and no words or characters', () {
    final statistics = DocumentStatistics.fromText('');
    expect(statistics.lines, 1);
    expect(statistics.words, 0);
    expect(statistics.characters, 0);
  });

  test('counts words across spaces, tabs and Windows or Unix line endings', () {
    final statistics = DocumentStatistics.fromText('one  two\r\nthree\tfour\nfive\r');
    expect(statistics.lines, 4);
    expect(statistics.words, 5);
  });

  test('counts composed accents and emoji as user-perceived characters', () {
    final statistics = DocumentStatistics.fromText('e\u0301 👩‍👩‍👧‍👦');
    expect(statistics.characters, 3);
    expect(statistics.words, 2);
  });

  test('whitespace-only document and trailing newline', () {
    final statistics = DocumentStatistics.fromText(' \t\n');
    expect(statistics.lines, 2);
    expect(statistics.words, 0);
    expect(statistics.characters, 3);
  });
}
