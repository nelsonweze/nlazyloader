import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
