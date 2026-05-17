import 'package:flutter/material.dart';

const Color kDefaultColor = Color.fromRGBO(47, 70, 100, 1);
const Color kColor = Color.fromRGBO(97, 55, 38, 1.0);
const Color kAppDefaultColor = Color(0xff205295);

void showLoadingDialog(BuildContext context, {String? message}) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xff4c53a5)),
                ),
              ),
              SizedBox(width: 16),
              Text(
                message ?? "Please wait...",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xff2d3436),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
