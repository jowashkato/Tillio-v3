import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import '../apis/product_stock_report.dart';
import '../helpers/AppTheme.dart';
import '../helpers/otherHelpers.dart';
import '../locale/MyLocalizations.dart';
import '../models/product_stock_report_model.dart';

class ProductStockReportScreen extends StatefulWidget {
  static const String routeName = '/ProductStockReport';
  ProductStockReportScreen({
    Key? key,
  }) : super(key: key);

  static int themeType = 1;

  @override
  State<ProductStockReportScreen> createState() =>
      _ProductStockReportScreenState();
}

class _ProductStockReportScreenState extends State<ProductStockReportScreen> {
  ThemeData themeData =
  AppTheme.getThemeFromThemeMode(ProductStockReportScreen.themeType);

  CustomAppTheme customAppTheme =
  AppTheme.getCustomAppTheme(ProductStockReportScreen.themeType);

  late List<ProductStockReportModel> myProductReportList;
  late bool loading;

  Future<void> _getProductStockReport() async {
    dev.log("Start");

    loading = true;

    var result = await ProductStockReportService().getProductStockReport();
    if (result == null) {
      setState(() {
        loading = true;
      });
    } else {
      setState(() {
        myProductReportList = result;
        loading = false;
      });
    }
  }

  @override
  void initState() {
    _getProductStockReport();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          elevation: 0,
          title: Text(AppLocalizations.of(context).translate('products_stock'),
              style: AppTheme.getTextStyle(themeData.textTheme.titleLarge,
                  fontWeight: 600)),
        ),
        body: SizedBox(
            child: loading
                ? const Center(
              child: CircularProgressIndicator(),
            )
                : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: DataTable(
                  columnSpacing: 20,
                  headingTextStyle: textHeadStyle(context),
                  headingRowColor:
                  WidgetStateColor.resolveWith((states) {
                    return themeData.primaryColor;
                  }),
                  columns: [
                    DataColumn(
                        label: Text(AppLocalizations.of(context)
                            .translate('product'))),
                    DataColumn(
                        label: Text(AppLocalizations.of(context)
                            .translate('type'))),

                    DataColumn(
                        label: Text(AppLocalizations.of(context)
                            .translate('stock_price'))),
                    DataColumn(
                        label: Text(AppLocalizations.of(context)
                            .translate('total_sold'))),

                    DataColumn(
                        label: Text(AppLocalizations.of(context)
                            .translate('stock'))),

                    DataColumn(
                        label: Text(AppLocalizations.of(context)
                            .translate('sku'))),

                    DataColumn(
                        label: Text(AppLocalizations.of(context)
                            .translate('alert_quantity'))),
                    DataColumn(
                        label: Text(AppLocalizations.of(context)
                            .translate('category_name'))),
                    DataColumn(
                        label: Text(AppLocalizations.of(context)
                            .translate('unit'))),
                    DataColumn(
                        label: Text(AppLocalizations.of(context)
                            .translate('unit_price'))),
                    DataColumn(
                        label: Text(AppLocalizations.of(context)
                            .translate('location_name'))),
                  ],
                  rows: List.generate(
                      myProductReportList.length,
                          (index) => myCardWidget(
                          myProductReport: myProductReportList[index],
                          context: context,
                          index: index)),
                ),
              ),
            )));
  }

  DataRow myCardWidget({
    required ProductStockReportModel myProductReport,
    required BuildContext context,
    required int index,
  }) {
    print(myProductReport.stock);
    return DataRow(
      color: WidgetStateColor.resolveWith(
            (states) => index % 2 == 0
            ? Colors.grey.shade100 // Background color for even rows
            : Colors.white, // Background color for odd rows
      ),
      cells: [
        DataCell(Text(myProductReport.product!, style: textStyle(context))),
        DataCell(Text(myProductReport.type!, style: textStyle(context))),
        DataCell(Text(Helper().formatCurrency(myProductReport.stockPrice!), style: textStyle(context))),
        DataCell(Text(Helper().formatCurrency(myProductReport.totalSold!), style: textStyle(context))),
        DataCell(Text(Helper().formatCurrency(myProductReport.stock!), style: textStyle(context))),
        DataCell(Text(myProductReport.sku!, style: textStyle(context))),
        DataCell(Text(Helper().formatCurrency(myProductReport.alertQuantity!), style: textStyle(context))),
        DataCell(Text(myProductReport.categoryName!, style: textStyle(context))),
        DataCell(Text(myProductReport.unit!, style: textStyle(context))),
        DataCell(Text( Helper().formatCurrency(myProductReport.unitPrice!), style: textStyle(context))),
        DataCell(Text(myProductReport.locationName!, style: textStyle(context))),

      ],
    );
  }

  TextStyle textStyle(BuildContext context) {
    return TextStyle(
      fontSize: MediaQuery.of(context).size.width / 25,
      fontWeight: FontWeight.w500,
    );
  }

  TextStyle textHeadStyle(BuildContext context) {
    return TextStyle(
      fontSize: MediaQuery.of(context).size.width / 25,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    );
  }

}
