import 'package:flutter_test/flutter_test.dart';
import 'package:gunluk_gorevler/src/domain/codec.dart';
import 'package:gunluk_gorevler/src/domain/local_date.dart';
import 'package:gunluk_gorevler/src/domain/repeat_rule.dart';
import 'package:gunluk_gorevler/src/domain/task.dart';
import 'package:gunluk_gorevler/src/domain/task_data.dart';

void main() {
  final day = LocalDate(2026, 11, 7);
  final at = DateTime.utc(2026, 11, 7, 9);

  test('format 2 keeps difficulty, time, steps and step ticks', () {
    final t = Task(
      id: 'a',
      title: 'Spor',
      note: '',
      schedule: [ScheduleSegment(day, const DailyRule())],
      createdAt: at,
      order: 0,
      difficulty: Difficulty.zor,
      time: ClockTime(18, 30),
      steps: [TaskStep('s1', 'Isın'), TaskStep('s2', 'Koş')],
    );
    final data = TaskData(tasks: [t]).withStepTick('a', day, 's1', true);
    final back = decodeTaskData(encodeTaskData(data, savedAt: at));
    final b = back.tasks.single;
    expect(b.difficulty, Difficulty.zor);
    expect(b.time, ClockTime(18, 30));
    expect(b.steps.map((s) => s.title), ['Isın', 'Koş']);
    expect(back.stepsDone('a', day), {'s1'});
  });

  test('a format 1 file opens with the defaults', () {
    const v1 =
        '{"app": "gunluk_gorevler", "schema_version": 1, '
        '"tasks": [{"id": "a", "title": "Su", "note": "", '
        '"schedule": [{"from": "2026-11-01", "rule": {"type": "daily"}}], '
        '"created_at": "2026-11-01T00:00:00Z", "order": 0}], '
        '"completions": [{"task_id": "a", "date": "2026-11-02", '
        '"done_at": "2026-11-02T08:00:00Z"}]}';
    final data = decodeTaskData(v1);
    final t = data.tasks.single;
    expect(t.difficulty, Difficulty.orta);
    expect(t.time, isNull);
    expect(t.steps, isEmpty);
    expect(data.isDone('a', LocalDate(2026, 11, 2)), isTrue);
  });

  test('refuses bad times, difficulties and duplicate steps', () {
    expect(() => ClockTime.parse('24:00'), throwsFormatException);
    expect(() => ClockTime.parse('9:00'), throwsFormatException);
    expect(ClockTime.parse('09:05').format(), '09:05');
    expect(() => Difficulty.parse('efsane'), throwsFormatException);
    expect(
      () => Task(
        id: 'a',
        title: 'x',
        note: '',
        schedule: [ScheduleSegment(day, const DailyRule())],
        createdAt: at,
        order: 0,
        steps: [TaskStep('s', 'a'), TaskStep('s', 'b')],
      ),
      throwsArgumentError,
    );
  });

  test('steps that no longer exist are not counted as done', () {
    final t = Task(
      id: 'a',
      title: 'x',
      note: '',
      schedule: [ScheduleSegment(day, const DailyRule())],
      createdAt: at,
      order: 0,
      steps: [TaskStep('s1', 'Bir')],
    );
    final data = TaskData(tasks: [t])
        .withStepTick('a', day, 's1', true)
        .withStepTick('a', day, 'gone', true);
    expect(data.stepsDone('a', day), {'s1'});
    expect(data.withoutTask('a').stepTicks, isEmpty);
  });
}
