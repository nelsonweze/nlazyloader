import 'package:flutter_bloc/flutter_bloc.dart';

class CustomBuilderState<T> {
  final bool loading;
  final List<T>? items;
  CustomBuilderState({this.items, this.loading = false});

  CustomBuilderState<T> copyWith({
    final bool? loading,
    final List<T>? items,
  }) {
    return CustomBuilderState<T>(
        items: items ?? this.items, loading: loading ?? this.loading);
  }
}

class CustomBuilderCubit<T> extends Cubit<CustomBuilderState<T>> {
  CustomBuilderCubit() : super(CustomBuilderState());

  void init(Future<List<T>>? Function()? future, List<T>? items) async {
    if (items != null) {
      return emit(state.copyWith(items: items, loading: false));
    }
    emit(state.copyWith(loading: true));
    var value = await future?.call();
    if (value != null) {
      emit(state.copyWith(items: value, loading: false));
    }
  }

  Future<bool> loadMore(Future<bool> Function(T)? funct) async {
    if (state.items != null && state.items!.isNotEmpty && funct != null) {
      return funct.call(state.items!.last);
    }
    return false;
  }
}
