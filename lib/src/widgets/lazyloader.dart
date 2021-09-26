import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../utils/util.dart';
import 'bottom_loader.dart';

class NLazyLoader<T> extends StatelessWidget {
  final Widget Function(LazyItemBuilder<T>, int)? builder;
  final Widget? child;
  final bool reverse;
  final FutureCallBack? onLoadMore;
  final double scrollOffset;
  final List<T>? items;
  final LazyItemBuilder<T>? itemBuilder;
  final bool isSliver;
  final LoadingStatus status;
  NLazyLoader(
      {this.child,
      this.builder,
      this.reverse = false,
      this.isSliver = false,
      this.status = LoadingStatus.STABLE,
      this.onLoadMore,
      this.scrollOffset = 80,
      this.itemBuilder,
      this.items});

  Widget build(BuildContext context) {
    int itemCount = items != null
        ? status == LoadingStatus.RETRIEVING
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
              onLoadMore?.call();
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
