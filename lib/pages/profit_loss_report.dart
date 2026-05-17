import 'dart:developer' as dev;
import 'dart:math';

import 'package:flutter/material.dart';

import '../apis/profit_loss_report.dart';
import '../helpers/AppTheme.dart';
import '../helpers/otherHelpers.dart';
import '../locale/MyLocalizations.dart';
import '../models/profit_loss_report_model.dart';

class ProfitLossReportScreen extends StatefulWidget {
  static const String routeName = '/ProfitLossReport';
  ProfitLossReportScreen({
    Key? key,
  }) : super(key: key);

  static int themeType = 1;

  @override
  State<ProfitLossReportScreen> createState() => _ProfitLossReportScreenState();
}

class _ProfitLossReportScreenState extends State<ProfitLossReportScreen> {
  TextStyle textStyle(
      BuildContext context,
      ) {
    return TextStyle(
      fontSize: MediaQuery.of(context).size.width / 25,
      fontWeight: FontWeight.bold,
    );
  }

  ThemeData themeData =
  AppTheme.getThemeFromThemeMode(ProfitLossReportScreen.themeType);

  CustomAppTheme customAppTheme =
  AppTheme.getCustomAppTheme(ProfitLossReportScreen.themeType);

  List<Color> myColors = [
    Colors.white,
    Color(0xff3d63ff).withOpacity(.3),
    Colors.blue[100] as Color,
    Colors.red[100] as Color,
    Colors.yellow[100] as Color,
    Colors.green[100] as Color,
    Colors.grey[100] as Color,
    Colors.purple[100] as Color,
  ];
  ProfitLossReportModel? profitLossReportModel;
  late bool loading;
  Map<String, dynamic>? mapData;
  List myReports = [];

  Future<void> _getProfitLossReport() async {
    dev.log("Start");

    loading = true;

    var result = await ProfitLossReportService().getProfitLossReport();

    if (result == null) {
      setState(() {
        loading = true;
      });
    } else {
      setState(() {
        profitLossReportModel = result;
        mapData = profitLossReportModel!.toJson();
        mapData!.forEach((key, value) {
          myReports.add({"title": key, "data": value});
        });
        dev.log("myReports ${myReports[0]}");
        loading = false;
      });
    }
  }

  @override
  void initState() {
    _getProfitLossReport();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          AppLocalizations.of(context).translate('reports'),
          style: AppTheme.getTextStyle(
            themeData.textTheme.titleLarge,
            fontWeight: 600,
          ),
        ),
      ),
      body: SizedBox(
        child: loading
            ? const Center(
          child: CircularProgressIndicator(),
        )
            : SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
            padding: const EdgeInsets.all(10.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Table(
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              border: TableBorder.all(
                color: Colors.grey.shade300,
                style: BorderStyle.solid,
                width: 1,
              ),
              children: List.generate(
                myReports.length,
                    (index) => myCellWidget(
                  title: AppLocalizations.of(context)
                      .translate(myReports[index]['title']),
                  data: myReports[index]['data'].toString(),
                  context: context,
                  isEven: index % 2 == 0, // Determine row striping
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  TableRow myCellWidget({
    required String title,
    required String data,
    required BuildContext context,
    required bool isEven, // Added to handle striped rows
  }) {
    return TableRow(
      decoration: BoxDecoration(
        color: isEven ? Colors.grey.shade100 : Colors.white70, // Alternating colors
        border:  Border(
          bottom: BorderSide(
            width: 1,
            color: Colors.grey.shade100,
          ),
        ),
      ),
      children: [
        // Title Cell
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Text(
            title,
            textAlign: TextAlign.left,
            style: textStyle(context).copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        // Data Cell
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Text(
            Helper().formatCurrency(data),
            textAlign: TextAlign.right,
            style: textStyle(context).copyWith(
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: Colors.grey.shade800,
            ),
          ),
        ),
      ],
    );
  }

  String toCamelCase(String input) {
    if (input.isEmpty) return input;

    // Split the string by spaces, underscores, or hyphens
    List<String> words = input.split(RegExp(r'[\s_\-]+'));

    // Capitalize the first letter of each word except the first one, and make all other letters lowercase
    String camelCaseString = words.first.toLowerCase() +
        words
            .skip(1)
            .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
            .join();

    return camelCaseString;
  }


}
