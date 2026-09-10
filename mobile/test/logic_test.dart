import 'dart:convert';

import 'package:test/test.dart';
import 'package:photo_enhance/ai/provider.dart';
import 'package:photo_enhance/core/history.dart';

void main() {
  group('job state machine (§52)', () {
    test('allows the happy path', () {
      expect(canTransition(JobStatus.created, JobStatus.queued), isTrue);
      expect(canTransition(JobStatus.queued, JobStatus.processing), isTrue);
      expect(canTransition(JobStatus.processing, JobStatus.completed), isTrue);
    });

    test('refuses arbitrary transitions', () {
      expect(canTransition(JobStatus.created, JobStatus.completed), isFalse);
      expect(canTransition(JobStatus.completed, JobStatus.processing), isFalse);
      expect(canTransition(JobStatus.failed, JobStatus.completed), isFalse);
      // §52: a job already being processed can no longer be cancelled.
      expect(canTransition(JobStatus.processing, JobStatus.cancelled), isFalse);
    });

    test('terminal states are terminal', () {
      for (final s in [JobStatus.completed, JobStatus.failed, JobStatus.cancelled, JobStatus.expired]) {
        expect(isTerminal(s), isTrue, reason: '$s');
      }
      for (final s in [JobStatus.created, JobStatus.queued, JobStatus.processing]) {
        expect(isTerminal(s), isFalse, reason: '$s');
      }
    });
  });

  group('poll schedule (D6)', () {
    test('1s for the first ten attempts, then 3s', () {
      expect(pollDelay(0), const Duration(seconds: 1));
      expect(pollDelay(9), const Duration(seconds: 1));
      expect(pollDelay(10), const Duration(seconds: 3));
    });

    test('backs off before the 90s hard stop', () {
      var elapsed = Duration.zero;
      var n = 0;
      while (elapsed < kPollTimeout) {
        elapsed += pollDelay(n++);
      }
      // 10 fast polls then 3s each: well under 60 requests for a 90s job.
      expect(n, lessThan(40));
    });
  });

  group('error taxonomy (§53)', () {
    test('parses wire codes and falls back to unknown', () {
      expect(ErrorCode.parse('QUOTA_EXCEEDED'), ErrorCode.quotaExceeded);
      expect(ErrorCode.parse('SOMETHING_NEW_FROM_THE_SERVER'), ErrorCode.unknown);
      expect(ErrorCode.parse(null), ErrorCode.unknown);
    });

    test('every code has a message that does not blame the user for our failures', () {
      for (final c in ErrorCode.values) {
        expect(c.message, isNotEmpty, reason: c.wire);
      }
      // §29 — a failed job must state that nothing was charged.
      expect(ErrorCode.modelError.message, contains('chưa bị trừ'));
      expect(ErrorCode.unknown.message, contains('chưa bị trừ'));
    });
  });

  group('history entry (§31 screen 07)', () {
    test('survives a round trip through storage', () {
      final e = HistoryEntry(
        id: '42',
        before: '/docs/history/42_b.jpg',
        after: 'https://cdn/out.jpg',
        at: DateTime.fromMillisecondsSinceEpoch(1757000000000),
      );

      final back = HistoryEntry.fromJson(jsonDecode(jsonEncode(e.toJson())) as Map<String, dynamic>);

      expect(back.id, e.id);
      expect(back.before, e.before);
      expect(back.after, e.after);
      expect(back.at, e.at, reason: 'a wrong timestamp reorders the whole grid');
    });
  });
}
