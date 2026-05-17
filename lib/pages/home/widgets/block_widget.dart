import 'package:flutter/material.dart';

import '../../../helpers/AppTheme.dart';
import '../../../helpers/SizeConfig.dart';
import '../../sales.dart';

class Block extends StatelessWidget {
  Block(
      {this.backgroundColor,
      this.subject,
      this.image,
      this.amount,
      required this.themeData});

  final Color? backgroundColor;
  final String? subject, image, amount;
  final ThemeData themeData;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: (){
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Sales(),
          ),
        );
      },
      child: Card(
        clipBehavior: Clip.antiAliasWithSaveLayer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MySize.size8!),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
          ),
          child: Container(
            padding:
                EdgeInsets.only(bottom: MySize.size16!, left: MySize.size16!),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                const SizedBox(
                  height: 15,
                ),
                Expanded(
                  child: Image.asset(
                    '$image',
                    height: 40,
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                Expanded(
                  child: Text(subject!,
                      style: AppTheme.getTextStyle(themeData.textTheme.titleLarge,
                          fontWeight: 700, color: Colors.white)),
                ),
                const SizedBox(
                  height: 5,
                ),
                Expanded(
                  child: Text("$amount",
                      style: AppTheme.getTextStyle(themeData.textTheme.bodySmall,
                          muted: true,
                          fontWeight: 500,
                          color: Colors.white,
                          letterSpacing: 0)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
