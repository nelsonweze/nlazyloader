import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

enum LoadingStatus { LOADING, STABLE, RETRIEVING }

class NLazyLoader<T> extends StatelessWidget {
  final Widget Function(LazyItemBuilder<T>, int)? builder;
  final Widget? child;
  final bool reverse;
  final FutureCallBack? onLoadMore;
  final double scrollOffset;
  final List<T>? items;
  final LazyItemBuilder<T>? itemBuilder;
  final bool isSliver;
  final bool isLoading;
  NLazyLoader(
      {this.child,
      this.builder,
      this.reverse = false,
      this.isSliver = false,
      this.isLoading = false,
      this.onLoadMore,
      this.scrollOffset = 80,
      this.itemBuilder,
      this.items});

  Widget build(BuildContext context) {
    LoadingStatus status =
        isLoading ? LoadingStatus.LOADING : LoadingStatus.STABLE;

    int itemCount = items != null
        ? status == LoadingStatus.LOADING || status == LoadingStatus.RETRIEVING
            ? items!.length + 1
            : items!.length
        : 0;

    LazyItemBuilder<T?> _builder = (index, item) {
      return index >= items!.length
          ? BottomLoader()
          : Column(
              children: [
                itemBuilder!(index, items![index]),
                if (reverse && index == 0 || index == items!.length - 1)
                  SizedBox(
                    height: 50,
                  )
              ],
            );
    };

    Widget? body() {
      Widget? _child;
      if (child != null)
        _child = child;
      else if (isSliver)
        _child = SliverList(
          delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) => _builder(index, null),
              addAutomaticKeepAlives: true,
              childCount: itemCount),
        );
      else if (builder != null)
        _child = builder!(_builder, itemCount);
      else
        _child = ListView.builder(
          physics: ClampingScrollPhysics(),
          reverse: reverse,
          itemCount: itemCount,
          itemBuilder: (context, index) => _builder(index, null),
          shrinkWrap: true,
        );
      return _child;
    }

    return NotificationListener(
      onNotification: (ScrollUpdateNotification info) {
        if (!reverse && info.scrollDelta! > 0) {
          if (info.metrics.maxScrollExtent > info.metrics.pixels &&
              info.metrics.maxScrollExtent - info.metrics.pixels <=
                  scrollOffset) {
            if (status == LoadingStatus.STABLE) {
              status = LoadingStatus.LOADING;
              print('read more');
              if (onLoadMore != null)
                onLoadMore!().then((value) {
                  status = value ? LoadingStatus.LOADING : LoadingStatus.STABLE;
                });
            }
          }
          return true;
        }
        return false;
      },
      child: body()!,
    );
  }
}

typedef Future<bool> FutureCallBack();

typedef Widget LazyItemBuilder<T>(
  int index,
  T child,
);

class BottomLoader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: EdgeInsets.only(top: 20, bottom: 10),
      child: Center(
        child: SizedBox(
          width: 30,
          height: 30,
          child: Theme.of(context).platform != TargetPlatform.iOS
              ? CircularProgressIndicator(
                  strokeWidth: 2.0,
                  valueColor: new AlwaysStoppedAnimation<Color?>(null),
                )
              : CupertinoActivityIndicator(),
        ),
      ),
    );
  }
}

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
