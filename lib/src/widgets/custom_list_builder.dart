import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nlazyloader/nlazyloader.dart';
import 'package:nlazyloader/src/blocs/blocs.dart';

class CustomListBuilder<T> extends StatefulWidget {
  final Future<List<T>>? future;
  final List<T>? items;
  final Future<bool> Function(T)? onLoadMore;
  final Widget Function(int, T) itemBuilder;
  final bool isSliver;
  final Widget? empty;
  final Widget Function(Widget Function(int, T), int)? builder;
  const CustomListBuilder(
      {Key? key,
      this.future,
      this.onLoadMore,
      required this.itemBuilder,
      this.builder,
      this.empty,
      this.items,
      this.isSliver = false})
      : super(key: key);

  @override
  _CustomListBuilderState<T> createState() => _CustomListBuilderState<T>();
}

class _CustomListBuilderState<T> extends State<CustomListBuilder<T>> {
  var cubit = CustomBuilderCubit<T>();
  @override
  void initState() {
    cubit.init(() => widget.future, widget.items);
    super.initState();
  }

  @override
  void didUpdateWidget(covariant CustomListBuilder<T> oldWidget) {
    if (oldWidget.items != widget.items && oldWidget.items == null) {
      cubit.init(() => widget.future, widget.items);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CustomBuilderCubit<T>, CustomBuilderState<T>>(
      bloc: cubit,
      builder: (context, state) {
        return state.loading
            ? wrapSliver(BottomLoader(), widget.isSliver)
            : state.items!.isEmpty
                ? wrapSliver(widget.empty ?? SizedBox(), widget.isSliver)
                : NLazyLoader<T>(
                    items: state.items!,
                    isSliver: widget.isSliver,
                    itemBuilder: widget.itemBuilder,
                    onLoadMore: () => cubit.loadMore(widget.onLoadMore),
                    builder: widget.builder,
                  );
      },
    );
  }
}
