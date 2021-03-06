import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nlazyloader/src/blocs/firebase_streambuilder_bloc.dart';
import 'package:nlazyloader/src/utils/util.dart';

import '../../nlazyloader.dart';

class FBStreamBuilder<T> extends StatefulWidget {
  final Query<Map<String, dynamic>> query;
  final T Function(Map<String, dynamic> map) fromMap;
  final bool isSliver;
  final int limit;
  final Widget Function(int, T) itemBuilder;
  final Widget? empty;
  final Widget Function(LazyBuilder<T>, int)? builder;
  final FBStreamBuilderCubit? cubit;
  final Widget? errorWidget;
  const FBStreamBuilder(
      {Key? key,
      required this.query,
      required this.fromMap,
      this.isSliver = false,
      this.builder,
      this.empty,
      this.cubit,
      this.errorWidget,
      required this.itemBuilder,
      this.limit = 10})
      : super(key: key);

  @override
  State<FBStreamBuilder<T>> createState() => _FBStreamBuilderState<T>();
}

class _FBStreamBuilderState<T> extends State<FBStreamBuilder<T>> {
  late FBStreamBuilderCubit cubit;

  @override
  void initState() {
    cubit = widget.cubit ?? FBStreamBuilderCubit()
      ..init(widget.query);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FBStreamBuilderCubit, FBStreamBuilderState>(
      bloc: cubit,
      builder: (context, state) {
        var items =
            state.documents.map((e) => widget.fromMap(e.data()!)).toList();
        return state.loadingStatus == LoadingStatus.LOADING
            ? wrapSliver(BottomLoader(), widget.isSliver)
            : state.error.isNotEmpty
                ? (widget.errorWidget ?? SizedBox())
                : items.isEmpty
                    ? wrapSliver(widget.empty ?? SizedBox(), widget.isSliver)
                    : NLazyLoader<T>(
                        items: items,
                        isSliver: widget.isSliver,
                        itemBuilder: widget.itemBuilder,
                        status: state.loadingStatus,
                        onLoadMore: () => cubit.requestNextPage(widget.limit),
                        builder: widget.builder,
                      );
      },
    );
  }
}
