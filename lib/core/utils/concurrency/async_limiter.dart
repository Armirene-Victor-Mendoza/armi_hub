import 'dart:async';
import 'dart:collection';

class AsyncLimiter {
  final int maxConcurrent;

  int _running = 0;
  final Queue<Completer<void>> _queue = Queue();

  AsyncLimiter(this.maxConcurrent) : assert(maxConcurrent > 0, 'maxConcurrent must be > 0');

  Future<T> run<T>(Future<T> Function() task) async {
    await _acquire();

    try {
      return await task();
    } finally {
      _release();
    }
  }

  Future<void> _acquire() async {
    if (_running < maxConcurrent) {
      _running++;
      return;
    }

    final completer = Completer<void>();
    _queue.add(completer);

    await completer.future;

    _running++;
  }

  void _release() {
    if (_queue.isNotEmpty) {
      _queue.removeFirst().complete();
    } else {
      _running--;
    }
  }
}
