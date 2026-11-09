import 'package:flutter_test/flutter_test.dart';
import 'package:mousify/connection/live_typing.dart';

void main() {
  test('append at end', () {
    final d = computeTextDelta('Hello', 'Hello world');
    expect(d.deleteCount, 0);
    expect(d.insert, ' world');
  });

  test('backspace at end', () {
    final d = computeTextDelta('Hello world', 'Hello worl');
    expect(d.deleteCount, 1);
    expect(d.insert, '');
  });

  test('replace selection in middle', () {
    final d = computeTextDelta('foo BAR baz', 'foo NEW baz');
    expect(d.deleteCount, 3); // BAR removed
    expect(d.insert, 'NEW');
  });

  test('dictation inserts a chunk', () {
    final d = computeTextDelta('', 'make me a task list please');
    expect(d.deleteCount, 0);
    expect(d.insert, 'make me a task list please');
  });

  test('clear all', () {
    final d = computeTextDelta('something', '');
    expect(d.deleteCount, 9);
    expect(d.insert, '');
  });

  test('no change', () {
    final d = computeTextDelta('same', 'same');
    expect(d.deleteCount, 0);
    expect(d.insert, '');
  });
}
