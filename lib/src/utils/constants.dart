import 'package:flutter/material.dart';

enum LoadingStatus { LOADING, STABLE, RETRIEVING }

typedef Future<bool> FutureCallBack();

typedef Widget LazyItemBuilder<T>(
  int index,
  T child,
);