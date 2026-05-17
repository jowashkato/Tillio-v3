import 'dart:async';

import 'package:date_time_picker/date_time_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../config.dart';
import '../helpers/AppTheme.dart';
import '../helpers/SizeConfig.dart';
import '../helpers/otherHelpers.dart';
import '../locale/MyLocalizations.dart';
import '../models/paymentDatabase.dart';
import '../models/sell.dart';
import '../models/sellDatabase.dart';
import '../models/system.dart';

class CheckOut extends StatefulWidget {
  @override
  CheckOutState createState() => CheckOutState();
}

class CheckOutState extends State<CheckOut> {
  List<Map> paymentMethods = [];
  int? sellId;
  double totalPaying = 0.0;
  String symbol = '',
      invoiceType = "Mobile",
      transactionDate =
          DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
  Map? argument;
  List<Map> payments = [],
      paymentAccounts = [
        {'id': null, 'name': "None"}
      ];
  List<int> deletedPaymentId = [];
  late Map<String, dynamic> paymentLine;
  List sellDetail = [];
  double invoiceAmount = 0.00, pendingAmount = 0.00, changeReturn = 0.00;
  TextEditingController dateController = new TextEditingController(),
      saleNote = new TextEditingController(),
      staffNote = new TextEditingController(),
      shippingDetails = new TextEditingController(),
      shippingCharges = new TextEditingController();
  bool _printInvoice = true,
      printWebInvoice = false,
      saleCreated = false,
      isLoading = false;
  static int themeType = 1;
  ThemeData themeData = AppTheme.getThemeFromThemeMode(themeType);
  CustomAppTheme customAppTheme = AppTheme.getCustomAppTheme(themeType);

  @override
  void initState() {
    super.initState();
    getInitDetails();
  }

  getInitDetails() async {
    setState(() {
      isLoading = true;
    });
    await Helper().getFormattedBusinessDetails().then((value) {
      symbol = value['symbol'];
    });
  }

  setPaymentAccounts() async {
    List payments =
        await System().get('payment_method', argument!['locationId']);
    await System().getPaymentAccounts().then((value) {
      value.forEach((element) {
        List<String> accIds = [];
        //check if payment account is assigned to any payment method
        // of selected location.
        payments.forEach((paymentMethod) {
          if ((paymentMethod['account_id'].toString() ==
                  element['id'].toString()) &&
              !accIds.contains(element['id'].toString())) {
            setState(() {
              paymentAccounts
                  .add({'id': element['id'], 'name': element['name']});
            });
          }
        });
      });
    });
  }

  @override
  void didChangeDependencies() {
    argument = ModalRoute.of(context)!.settings.arguments as Map?;
    invoiceAmount = argument!['invoiceAmount'];
    setPaymentAccounts().then((value) {
      if (argument!['sellId'] == null) {
        setPaymentDetails().then((value) {
          payments.add({
            'amount': invoiceAmount,
            'method': paymentMethods[0]['name'],
            'note': '',
            'account_id': paymentMethods[0]['account_id']
          });
          calculateMultiPayment();
        });
      } else {
        setPaymentDetails().then((value) {
          onEdit(argument!['sellId']);
        });
      }
    });
    setState(() {
      isLoading = false;
    });
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    staffNote.dispose();
    saleNote.dispose();
    super.dispose();
  }

  onEdit(sellId) async {
    sellDetail = await SellDatabase().getSellBySellId(sellId);
    this.sellId = argument!['sellId'];
    await SellDatabase().getSellBySellId(sellId).then((value) {
      shippingCharges.text = value[0]['shipping_charges'].toString();
      shippingDetails.text = value[0]['shipping_details'] ?? '';
      saleNote.text = value[0]['sale_note'] ?? '';
      staffNote.text = value[0]['staff_note'] ?? '';
      invoiceAmount =
          argument!['invoiceAmount'] + double.parse(shippingCharges.text);
    });
    payments = [];
    List paymentLines = await PaymentDatabase().get(sellId, allColumns: true);
    paymentLines.forEach((element) {
      if (element['is_return'] == 0) {
        payments.add({
          'id': element['id'],
          'amount': element['amount'],
          'method': element['method'],
          'note': element['note'],
          'account_id': element['account_id']
        });
      }
    });
    calculateMultiPayment();
    if (this.mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          elevation: 0,
          title: Text(AppLocalizations.of(context).translate('checkout'),
              style: AppTheme.getTextStyle(themeData.textTheme.titleLarge,
                  fontWeight: 600)),
        ),
        body: SingleChildScrollView(
          child:
              (isLoading) ? Helper().loadingIndicator(context) : paymentBox(),
        ));
  }

  //payment widget
  Widget paymentBox() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Transaction Date Section
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xff4c53a5), Color(0xff6c7ae0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Color(0xff4c53a5).withOpacity(0.3),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.schedule, color: Colors.white, size: 24),
                    SizedBox(width: 12),
                    Text(
                      "Transaction Date",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: DateTimePicker(
                    use24HourFormat: true,
                    locale: Locale('en', 'US'),
                    initialValue: transactionDate,
                    type: DateTimePickerType.dateTime,
                    firstDate: DateTime.now().subtract(Duration(days: 366)),
                    lastDate: DateTime.now(),
                    dateLabelText: "Select Date & Time",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                    onChanged: (val) {
                      setState(() {
                        transactionDate = val;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 24),

          // Payment Methods Section
          Text(
            "Payment Methods",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xff2d3436),
            ),
          ),
          SizedBox(height: 16),

          ListView.builder(
            physics: NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: payments.length,
            itemBuilder: (context, index) {
              return Container(
                margin: EdgeInsets.only(bottom: 16),
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 2,
                      offset: Offset(0, 2),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Payment Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Payment ${index + 1}",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff2d3436),
                          ),
                        ),
                        if (index > 0)
                          IconButton(
                            icon: Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => alertConfirm(context, index),
                          ),
                      ],
                    ),

                    SizedBox(height: 16),

                    // Amount Input
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Amount",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: 8),
                              Container(
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Color(0xfff8f9fa),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                                ),
                                child: TextFormField(
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    suffixText: symbol,
                                    suffixStyle: TextStyle(
                                      color: Color(0xff4c53a5),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  initialValue: payments[index]['amount'].toStringAsFixed(2),
                                  inputFormatters: [
                                    FilteringTextInputFormatter(
                                      RegExp(r'^(\d+)?\.?\d{0,2}'),
                                      allow: true,
                                    )
                                  ],
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) {
                                    payments[index]['amount'] = Helper().validateInput(value);
                                    calculateMultiPayment();
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Payment Method",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: 8),
                              Container(
                                height: 50,
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  color: Color(0xfff8f9fa),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    isExpanded: true,
                                    value: payments[index]['method'],
                                    icon: Icon(Icons.arrow_drop_down, color: Color(0xff4c53a5)),
                                    items: paymentMethods.map<DropdownMenuItem<String>>((Map value) {
                                      return DropdownMenuItem<String>(
                                        value: value['name'],
                                        child: Text(
                                          value['value'],
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (newValue) {
                                      paymentMethods.forEach((element) {
                                        if (element['name'] == newValue) {
                                          setState(() {
                                            payments[index]['method'] = newValue;
                                            payments[index]['account_id'] = element['account_id'];
                                          });
                                        }
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 16),

                    // Payment Note
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Payment Note (Optional)",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Color(0xfff8f9fa),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.withOpacity(0.2)),
                          ),
                          child: TextFormField(
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              hintText: "Add payment note...",
                              hintStyle: TextStyle(color: Colors.grey[400]),
                            ),
                            onChanged: (value) {
                              payments[index]['note'] = value;
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),

          // Add Payment Button
          Container(
            width: double.infinity,
            margin: EdgeInsets.only(bottom: 24),
            child: OutlinedButton.icon(
              icon: Icon(Icons.add, color: Color(0xff4c53a5)),
              label: Text(
                "Add Another Payment",
                style: TextStyle(
                  color: Color(0xff4c53a5),
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Color(0xff4c53a5), width: 2),
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                setState(() {
                  payments.add({
                    'amount': pendingAmount,
                    'method': paymentMethods[0]['name'],
                    'note': '',
                    'account_id': paymentMethods[0]['account_id'],
                  });
                  calculateMultiPayment();
                });
              },
            ),
          ),

          // Shipping Section
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.local_shipping, color: Color(0xff4c53a5), size: 24),
                    SizedBox(width: 12),
                    Text(
                      "Shipping Information",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff2d3436),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Shipping Charges",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 8),
                          Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: Color(0xfff8f9fa),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.withOpacity(0.2)),
                            ),
                            child: TextFormField(
                              controller: shippingCharges,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                hintText: "0.00",
                                suffixText: symbol,
                                suffixStyle: TextStyle(
                                  color: Color(0xff4c53a5),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              textAlign: TextAlign.center,
                              inputFormatters: [
                                FilteringTextInputFormatter(
                                  RegExp(r'^(\d+)?\.?\d{0,2}'),
                                  allow: true,
                                )
                              ],
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                invoiceAmount = argument!['invoiceAmount'] + Helper().validateInput(value);
                                calculateMultiPayment();
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Shipping Details",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Color(0xfff8f9fa),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withOpacity(0.2)),
                      ),
                      child: TextFormField(
                        controller: shippingDetails,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          hintText: "Enter shipping details...",
                          hintStyle: TextStyle(color: Colors.grey[400]),
                        ),
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 24),

          // Payment Summary
          Container(
            padding: EdgeInsets.all(5),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xff00b894), Color(0xff00cec9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Color(0xff00b894).withOpacity(0.3),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  "Payment Summary",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20),
                GridView.count(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 2.0,
                  children: [
                    _summaryCard("Total Payable", Helper().formatCurrency(invoiceAmount), Icons.receipt_long),
                    _summaryCard("Total Paying", Helper().formatCurrency(totalPaying), Icons.payment),
                    _summaryCard("Change Return", Helper().formatCurrency(changeReturn), Icons.trending_up),
                    _summaryCard("Balance", Helper().formatCurrency(pendingAmount), Icons.account_balance_wallet),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 24),

          // Notes Section
          Container(
            padding: EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.note_alt, color: Color(0xff4c53a5), size: 24),
                    SizedBox(width: 12),
                    Text(
                      "Additional Notes",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff2d3436),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Sale Note",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 8),
                          Container(
                            height: 80,
                            decoration: BoxDecoration(
                              color: Color(0xfff8f9fa),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.withOpacity(0.2)),
                            ),
                            child: TextFormField(
                              controller: saleNote,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.all(12),
                                hintText: "Customer visible note...",
                                hintStyle: TextStyle(color: Colors.grey[400]),
                              ),
                              maxLines: 3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Staff Note",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 8),
                          Container(
                            height: 80,
                            decoration: BoxDecoration(
                              color: Color(0xfff8f9fa),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.withOpacity(0.2)),
                            ),
                            child: TextFormField(
                              controller: staffNote,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.all(12),
                                hintText: "Internal staff note...",
                                hintStyle: TextStyle(color: Colors.grey[400]),
                              ),
                              maxLines: 3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 24),

          // Invoice Type Selection
          Container(
            padding: EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Invoice Layout",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff2d3436),
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: invoiceType == "Mobile" ? Color(0xff4c53a5).withOpacity(0.1) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: invoiceType == "Mobile" ? Color(0xff4c53a5) : Colors.grey.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: RadioListTile<String>(
                          title: Text(
                            "Mobile Layout",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: invoiceType == "Mobile" ? Color(0xff4c53a5) : Colors.grey[700],
                            ),
                          ),
                          value: "Mobile",
                          groupValue: invoiceType,
                          activeColor: Color(0xff4c53a5),
                          onChanged: (value) {
                            setState(() {
                              invoiceType = value.toString();
                              printWebInvoice = false;
                            });
                          },
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: invoiceType == "Web" ? Color(0xff4c53a5).withOpacity(0.1) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: invoiceType == "Web" ? Color(0xff4c53a5) : Colors.grey.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: RadioListTile<String>(
                          title: Text(
                            "Web Layout",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: invoiceType == "Web" ? Color(0xff4c53a5) : Colors.grey[700],
                            ),
                          ),
                          value: "Web",
                          groupValue: invoiceType,
                          activeColor: Color(0xff4c53a5),
                          onChanged: (value) async {
                            if (await Helper().checkConnectivity()) {
                              setState(() {
                                invoiceType = value.toString();
                                printWebInvoice = true;
                              });
                            } else {
                              Fluttertoast.showToast(
                                  msg: AppLocalizations.of(context).translate('check_connectivity')
                              );
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 32),

          // Final Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: Icon(Icons.share, size: 20),
                  label: Text(
                    "FINALIZE & SHARE",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      // fontSize: 13,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Color(0xff4c53a5),
                    side: BorderSide(color: Color(0xff4c53a5), width: 2),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    _printInvoice = false;
                    if (pendingAmount >= 0.01) {
                      alertPending(context);
                    } else {
                      if (!saleCreated) {
                        onSubmit();
                      }
                    }
                  },
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  icon: Icon(Icons.print, size: 20, color: Colors.white,),
                  label: Text(
                    "FINALIZE & PRINT",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      // fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xff4c53a5),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                    shadowColor: Color(0xff4c53a5).withOpacity(0.4),
                  ),
                  onPressed: () {
                    _printInvoice = true;
                    if (pendingAmount >= 0.01) {
                      alertPending(context);
                    } else {
                      if (!saleCreated) {
                        onSubmit();
                      }
                    }
                  },
                ),
              ),
            ],
          ),

          SizedBox(height: 20),
        ],
      ),
    );
  }

  block({Color? backgroundColor, String? subject, amount, Color? textColor}) {
    ThemeData themeData = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAliasWithSaveLayer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MySize.size8!),
      ),
      child: Container(
        height: MySize.size30,
        child: Container(
          padding: EdgeInsets.all(MySize.size2!),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text(
                subject!,
                style: AppTheme.getTextStyle(themeData.textTheme.bodyLarge,
                    color: themeData.colorScheme.onSurface,
                    fontWeight: 800,
                    fontSize: 10,
                    muted: true),
              ),
              Text(
                " $amount $symbol",
                overflow: TextOverflow.ellipsis,
                style: AppTheme.getTextStyle(themeData.textTheme.bodyLarge,
                    color: textColor, fontWeight: 600, muted: true),
              ),
            ],
          ),
        ),
      ),
    );
  }

  //calculate multiple payment
  calculateMultiPayment() {
    totalPaying = 0.0;
    payments.forEach((element) {
      totalPaying += element['amount'];
    });
    if (totalPaying > invoiceAmount) {
      changeReturn = totalPaying - invoiceAmount;
      pendingAmount = 0.0;
    } else if (invoiceAmount > totalPaying) {
      pendingAmount = invoiceAmount - totalPaying;
      changeReturn = 0.0;
    } else {
      pendingAmount = 0.0;
      changeReturn = 0.0;
    }
    if (this.mounted) {
      setState(() {});
    }
  }

  setPaymentDetails() async {
    List payments =
        await System().get('payment_method', argument!['locationId']);
    payments.forEach((element) {
      if (this.mounted) {
        setState(() {
          paymentMethods.add({
            'name': element['name'],
            'value': element['label'],
            'account_id': (element['account_id'] != null)
                ? int.parse(element['account_id'].toString())
                : null
          });
        });
      }
    });
  }

  //on submit
  onSubmit() async {
    setState(() {
      isLoading = true;
      saleCreated = true;
    });
    //value for sell table

    //TODO: remove change return from here and add it to payments
    Map<String, dynamic> sell = await Sell().createSell(
        // invoiceNo: "${Config.userId}_${DateFormat('yMdHm').format(DateTime.now())}",
        invoiceNo: "INV-${Config.userId}-${DateFormat('yyyyMMddHHmmss').format(DateTime.now())}",
        transactionDate: transactionDate,
        changeReturn: changeReturn,
        contactId: argument!['customerId'],
        discountAmount: argument!['discountAmount'],
        discountType: argument!['discountType'],
        invoiceAmount: invoiceAmount,
        locId: argument!['locationId'],
        pending: pendingAmount,
        saleNote: saleNote.text,
        saleStatus: 'final',
        sellId: sellId,
        shippingCharges: (shippingCharges.text != '')
            ? double.parse(shippingCharges.text)
            : 0.00,
        shippingDetails: shippingDetails.text,
        staffNote: staffNote.text,
        taxId: argument!['taxId'],
        isQuotation: 0);

    var response;
    if (sellId != null) {
      //update sell
      response = sellId;
      await SellDatabase().updateSells(sellId, sell).then((value) async {
        //get payment map
        //TODO: change payment name to payment type.
        //create payment line
        payments.forEach((element) {
          if (element['id'] != null) {
            paymentLine = {
              'amount': element['amount'],
              'method': element['method'],
              'note': element['note'],
              'account_id': element['account_id']
            };
            PaymentDatabase()
                .updateEditedPaymentLine(element['id'], paymentLine);
          } else {
            paymentLine = {
              'sell_id': sellId,
              'method': element['method'],
              'amount': element['amount'],
              'note': element['note'],
              'account_id': element['account_id']
            };
            PaymentDatabase().store(paymentLine);
          }
        });
        if (deletedPaymentId.length > 0) {
          PaymentDatabase().deletePaymentLineByIds(deletedPaymentId);
        }
        //check internet connection and create api sell
        if (await Helper().checkConnectivity()) {
          await Sell()
              .createApiSell(sellId: sellId)
              .then((value) => printOption(response));
        } else {
          //print option

          printOption(response);
        }
      });
    } else {
      //save sell in database
      response = await SellDatabase().storeSell(sell);
      //save payments in sell_payments
      Sell().makePayment(payments, response);
      SellDatabase().updateSellLine({'sell_id': response, 'is_completed': 1});
      if (await Helper().checkConnectivity()) {
        await Sell().createApiSell(sellId: response);
      }
      //print option
      printOption(response);

    }
  }

  //print option
  printOption(sellId) async {
    Timer(Duration(seconds: 2), () async {
      List sellDetail = await SellDatabase().getSellBySellId(sellId);
      String? invoice = sellDetail[0]['invoice_url'];
      String invoiceNo = sellDetail[0]['invoice_no'];
      //print invoice
      if (_printInvoice) {
        if (printWebInvoice && invoice != null) {
          final response = await http.Client().get(Uri.parse(invoice));
          if (response.statusCode == 200) {
            await Helper()
                .printDocument(sellId, argument!['taxId'], context,
                    invoice: response.body)
                .then((value) {
              Navigator.pushNamedAndRemoveUntil(
                  context,
                  (argument!['sellId'] == null) ? '/layout' : '/sale',
                  ModalRoute.withName('/home'));
            });
          } else {
            await Helper()
                .printDocument(sellId, argument!['taxId'], context)
                .then((value) {
              Navigator.pushNamedAndRemoveUntil(
                  context,
                  (argument!['sellId'] == null) ? '/layout' : '/sale',
                  ModalRoute.withName('/home'));
            });
          }
        } else {
          Helper()
              .printDocument(sellId, argument!['taxId'], context)
              .then((value) {
            Navigator.pushNamedAndRemoveUntil(
                context,
                (argument!['sellId'] == null) ? '/layout' : '/sale',
                ModalRoute.withName('/home'));
          });
        }
      } else {
        if (printWebInvoice && invoice != null) {
          final response = await http.Client().get(Uri.parse(invoice));
          if (response.statusCode == 200) {
            await Helper()
                .savePdf(sellId, argument!['taxId'], context, invoiceNo,
                    invoice: response.body)
                .then((value) {
              Navigator.pushNamedAndRemoveUntil(
                  context,
                  (argument!['sellId'] == null) ? '/layout' : '/sale',
                  ModalRoute.withName('/home'));
            });
          } else {
            await Helper()
                .savePdf(sellId, argument!['taxId'], context, invoiceNo)
                .then((value) {
              Navigator.pushNamedAndRemoveUntil(
                  context,
                  (argument!['sellId'] == null) ? '/layout' : '/sale',
                  ModalRoute.withName('/home'));
            });
          }
        } else {
          Helper()
              .savePdf(sellId, argument!['taxId'], context, invoiceNo)
              .then((value) {
            Navigator.pushNamedAndRemoveUntil(
                context,
                (argument!['sellId'] == null) ? '/layout' : '/sale',
                ModalRoute.withName('/home'));
          });
        }
      }
    });
  }

  //alert dialog for amount pending
  alertPending(BuildContext context) {
    AlertDialog alert = new AlertDialog(
      content: Text(AppLocalizations.of(context).translate('pending_message'),
          style: AppTheme.getTextStyle(themeData.textTheme.bodyMedium,
              color: themeData.colorScheme.onSurface,
              fontWeight: 500,
              muted: true)),
      actions: <Widget>[
        TextButton(
            style: TextButton.styleFrom(
                foregroundColor: themeData.colorScheme.onPrimary, backgroundColor: themeData.colorScheme.primary),
            onPressed: () {
              Navigator.pop(context);
              if (!saleCreated) {
                onSubmit();
              }
            },
            child: Text(AppLocalizations.of(context).translate('ok'))),
        TextButton(
            style: TextButton.styleFrom(
                foregroundColor: themeData.colorScheme.primary, backgroundColor: themeData.colorScheme.onPrimary),
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(AppLocalizations.of(context).translate('cancel')))
      ],
    );
    showDialog(
      barrierDismissible: true,
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  //alert dialog for confirmation
  alertConfirm(BuildContext context, index) {
    AlertDialog alert = new AlertDialog(
      title: Icon(
        MdiIcons.alert,
        color: Colors.red,
        size: MySize.size50,
      ),
      content: Text(AppLocalizations.of(context).translate('are_you_sure'),
          textAlign: TextAlign.center,
          style: AppTheme.getTextStyle(themeData.textTheme.bodyLarge,
              color: themeData.colorScheme.onSurface,
              fontWeight: 600,
              muted: true)),
      actions: <Widget>[
        TextButton(
            style: TextButton.styleFrom(
                foregroundColor: themeData.colorScheme.primary, backgroundColor: themeData.colorScheme.onPrimary),
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(AppLocalizations.of(context).translate('cancel'))),
        TextButton(
            style: TextButton.styleFrom(
                foregroundColor: themeData.colorScheme.onError, backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              if (sellId != null && payments[index]['id'] != null) {
                deletedPaymentId.add(payments[index]['id']);
              }
              payments.removeAt(index);
              calculateMultiPayment();
            },
            child: Text(AppLocalizations.of(context).translate('ok')))
      ],
    );
    showDialog(
      barrierDismissible: true,
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  Widget _summaryCard(String title, String amount, IconData icon) {
    return Container(
      padding: EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 2),
          Text(
            "$amount $symbol",
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
