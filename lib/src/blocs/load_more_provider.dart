import 'package:flutter/material.dart';
import 'package:nlazyloader/src/utils/util.dart';

class LoadMoreProvider extends ChangeNotifier {
  LoadingStatus _status = LoadingStatus.STABLE;
  LoadingStatus get status => _status;
  set status(LoadingStatus val) {
    _status = val;
    notifyListeners();
  }

  bool _hasReachedMax = false;
  bool get hasReachedMax => _hasReachedMax;
  set hasReachedMax(bool val) {
    _hasReachedMax = val;
    notifyListeners();
  }

  bool _hasReachedEnd = false;
  bool get hasReachedEnd => _hasReachedEnd;
  set hasReachedEnd(bool val) {
    _hasReachedEnd = val;
    notifyListeners();
  }
}
