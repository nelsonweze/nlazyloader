import 'package:flutter/material.dart';

Widget wrapSliver(Widget child, bool isSliver) {
  if (isSliver) {
    return SliverToBoxAdapter(
      child: child,
    );
  }
  return Center(child: child);
}
