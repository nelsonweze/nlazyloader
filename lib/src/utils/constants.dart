import 'package:flutter/material.dart';

enum LoadingStatus { LOADING, STABLE, RETRIEVING }

typedef Future<bool> FutureCallBack();

typedef Widget LazyBuilder<T>(
  int index,
);

typedef Widget LazyItemBuilder<T>(
  int index, T child
);