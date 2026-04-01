import 'dart:collection';

import 'package:collection/collection.dart';

class PriorityQueueWrapper<E> implements Queue<E>{
  final PriorityQueue<E> _pq;

  PriorityQueueWrapper(int Function(E, E) compare) 
      : _pq = HeapPriorityQueue<E>(compare);

  @override
  void add(E value) => _pq.add(value);

  @override
  void addAll(Iterable<E> iterable) => _pq.addAll(iterable);

  @override
  E get first => _pq.first;

  @override
  bool remove(Object? element) => _pq.remove(element as E);

  @override
  E removeFirst() => _pq.removeFirst();

  @override
  bool get isEmpty => _pq.isEmpty;

  @override
  bool get isNotEmpty => !_pq.isEmpty;

  @override
  int get length => _pq.length;

  @override
  void clear() => _pq.clear();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}