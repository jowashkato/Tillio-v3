import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../apis/expenses.dart';
import '../constants.dart';
import '../helpers/AppTheme.dart';
import '../helpers/SizeConfig.dart';
import '../helpers/otherHelpers.dart';
import '../locale/MyLocalizations.dart';
import '../models/expenses.dart';
import '../models/system.dart';

class Expense extends StatefulWidget {
  @override
  _ExpenseState createState() => _ExpenseState();
}

class _ExpenseState extends State<Expense> {
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;

  List<Map<String, dynamic>> expenseCategories = [
    {'id': 0, 'name': 'Select Category'}
  ],
      expenseSubCategories = [],
      paymentMethods = [],
      paymentAccounts = [],
      locationListMap = [
        {'id': 0, 'name': 'Set location'}
      ],
      taxListMap = [
        {'id': 0, 'name': 'Tax rate', 'amount': 0}
      ];
  Map<String, dynamic> selectedLocation = {'id': 0, 'name': 'Set location'},
      selectedTax = {'id': 0, 'name': 'Tax rate', 'amount': 0},
      selectedExpenseCategoryId = {'id': 0, 'name': 'Select Category'},
      selectedExpenseSubCategoryId = {'id': 0, 'name': 'Select Sub Category'};

  TextEditingController expenseAmount = new TextEditingController(),
      expenseNote = new TextEditingController(),
      payingAmount = new TextEditingController();

  Map<String, dynamic> selectedPaymentAccount = {'id': null, 'name': "None"},
      selectedPaymentMethod = {
        'name': 'name',
        'value': 'value',
        'account_id': null
      };
  String symbol = '';

  static int themeType = 1;
  ThemeData themeData = AppTheme.getThemeFromThemeMode(themeType);
  CustomAppTheme customAppTheme = AppTheme.getCustomAppTheme(themeType);

  @override
  void initState() {
    super.initState();
    setLocationMap();
    setTaxMap();
    // setPaymentDetails(selectedLocation['id']);
    Helper().syncCallLogs();
  }

  @override
  void dispose() {
    expenseAmount.dispose();
    expenseNote.dispose();
    payingAmount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0.0,
        title: Text(AppLocalizations.of(context).translate('expenses'),
            style: AppTheme.getTextStyle(themeData.textTheme.titleLarge,
                fontWeight: 800)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(MySize.size20!),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '${AppLocalizations.of(context).translate('location')}:',
                        style: AppTheme.getTextStyle(
                          themeData.textTheme.titleLarge,
                          fontWeight: 700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      locations(),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Visibility(
                    visible: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          '${AppLocalizations.of(context).translate('tax')}:',
                          style: AppTheme.getTextStyle(
                            themeData.textTheme.titleLarge,
                            fontWeight: 700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        taxes(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '${AppLocalizations.of(context).translate('expense_categories')}:',
                        style: AppTheme.getTextStyle(
                          themeData.textTheme.titleLarge,
                          fontWeight: 700,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 8),
                      expenseCategory(),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (expenseSubCategories.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          '${AppLocalizations.of(context).translate('sub_categories')}:',
                          style: AppTheme.getTextStyle(
                            themeData.textTheme.titleLarge,
                            fontWeight: 700,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                        const SizedBox(width: 8),
                        expenseSubCategory(),
                        const SizedBox(height: 10),
                      ],
                    ),
                  TextFormField(
                    validator: (value) {
                      if (value!.isEmpty) {
                        return AppLocalizations.of(context)
                            .translate('please_enter_expense_amount');
                      }
                      return null;
                    },
                    textAlign: TextAlign.end,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)
                          .translate('expense_amount'),
                      prefix: Text(symbol),
                      border: const OutlineInputBorder(),
                    ),
                    controller: expenseAmount,
                    style: AppTheme.getTextStyle(
                      themeData.textTheme.bodyLarge,
                    ),
                    onChanged: (value){
                      payingAmount.text = value;
                    },
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)
                          .translate('expense_note'),
                      border: const OutlineInputBorder(),
                    ),
                    controller: expenseNote,
                    style: AppTheme.getTextStyle(
                      themeData.textTheme.bodyLarge,
                      // fontWeight: FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 12),
                  payment(),
                  const SizedBox(height: 24),
                  isLoading
                      ? const Center(child: CircularProgressIndicator(
                    color: kAppDefaultColor,
                  ))
                      : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: 16.0, horizontal: 32.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        backgroundColor: themeData.colorScheme.primary,
                      ),
                      onPressed: () async {
                        if (await Helper().checkConnectivity()) {
                          if (_formKey.currentState!.validate()) {
                            onSubmit();
                          }
                        } else {
                          Fluttertoast.showToast(
                            msg: AppLocalizations.of(context)
                                .translate('check_connectivity'),
                          );
                        }
                      },
                      child: Text(
                        AppLocalizations.of(context).translate('submit'),
                        style: AppTheme.getTextStyle(
                          themeData.textTheme.titleLarge,
                          color: themeData.colorScheme.onPrimary,
                          fontWeight: 700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  setLocationMap() async {
    await System().get('location').then((value) {
      value.forEach((element) {
        setState(() {
          locationListMap.add({
            'id': element['id'],
            'name': element['name'],
          });
        });
      });
    });
  }

  onSubmitOld() async {
    if (selectedLocation['id'] != 0) {
      if (expenseAmount.text == '') {
        expenseAmount.text = '0.00';
      }
      if (payingAmount.text == '') {
        payingAmount.text = '0.00';
      }
      var expenseMap = ExpenseManagement().createExpense(
          locId: selectedLocation['id'],
          finalTotal: double.parse(expenseAmount.text),
          amount: double.parse(payingAmount.text),
          method: selectedPaymentMethod['name'],
          accountId: selectedPaymentAccount['id'],
          expenseCategoryId: selectedExpenseCategoryId['id'],
          expenseSubCategoryId: selectedExpenseSubCategoryId['id'],
          taxId: (selectedTax['id'] != 0) ? selectedTax['id'] : null,
          note: expenseNote.text);
      await ExpenseApi().create(expenseMap).then((value) {
        Navigator.pop(context);
        Fluttertoast.showToast(
            msg: AppLocalizations.of(context)
                .translate('expense_added_successfully'));
      });
    } else {
      Fluttertoast.showToast(
          msg:
          AppLocalizations.of(context).translate('error_invalid_location'));
    }
  }

  onSubmit() async {
    if (selectedLocation['id'] != 0) {
      if (expenseAmount.text == '') {
        expenseAmount.text = '0.00';
      }
      if (payingAmount.text == '') {
        payingAmount.text = '0.00';
      }
      // Set the loading state to true
      setState(() {
        isLoading = true;
      });

      var expenseMap = ExpenseManagement().createExpense(
          locId: selectedLocation['id'],
          finalTotal: double.parse(expenseAmount.text),
          amount: double.parse(payingAmount.text),
          method: selectedPaymentMethod['name'],
          accountId: selectedPaymentAccount['id'],
          expenseCategoryId: selectedExpenseCategoryId['id'],
          expenseSubCategoryId: selectedExpenseSubCategoryId['id'],
          taxId: (selectedTax['id'] != 0) ? selectedTax['id'] : null,
          note: expenseNote.text,
      );

      await ExpenseApi().create(expenseMap).then((value) {
        // Set the loading state to false when the operation is complete
        setState(() {
          isLoading = false;
        });
        Navigator.pop(context);

        Fluttertoast.showToast(
          msg: AppLocalizations.of(context)
              .translate('expense_added_successfully'),
        );
      }).catchError((error) {
        // Handle any error
        setState(() {
          isLoading = false;
        });
        Fluttertoast.showToast(msg: 'Error_occurred');
      });
    } else {
      Fluttertoast.showToast(
        msg: AppLocalizations.of(context).translate('error_invalid_location'),
      );
    }
  }

  setTaxMap() {
    System().get('tax').then((value) {
      value.forEach((element) {
        taxListMap.add({
          'id': element['id'],
          'name': element['name'],
          'amount': element['amount']
        });
      });
    });
  }

  //dropdown tax widget
  Widget taxes() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: MySize.size12!),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(MySize.size8!),
        color: customAppTheme.bgLayer1,
        border: Border.all(color: customAppTheme.bgLayer3, width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Map<String, dynamic>>(
          value: taxListMap.contains(selectedTax) ? selectedTax : null,
          isExpanded: true,
          icon: Icon(
            MdiIcons.chevronDown,
            size: MySize.size22,
            color: themeData.colorScheme.onSurface,
          ),
          dropdownColor: Colors.white,
          items: taxListMap.map((Map<String, dynamic> value) {
            return DropdownMenuItem<Map<String, dynamic>>(
              value: value,
              child: Text(
                value['name'],
                style: AppTheme.getTextStyle(
                  themeData.textTheme.bodyMedium,
                  color: themeData.colorScheme.onSurface,
                ),
              ),
            );
          }).toList(),
          onChanged: (Map<String, dynamic>? newValue) {
            setState(() {
              selectedTax = newValue!;
            });
          },
        ),
      ),
    );
  }

  // Location
  Widget locations() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: MySize.size12!),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(MySize.size8!),
        color: customAppTheme.bgLayer1,
        border: Border.all(color: customAppTheme.bgLayer3, width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Map<String, dynamic>>(
          value: locationListMap.firstWhere(
                (element) => element['id'] == selectedLocation['id'],
            orElse: () => locationListMap[0],
          ),
          isExpanded: true,
          icon: Icon(
            MdiIcons.chevronDown,
            size: MySize.size22,
            color: themeData.colorScheme.onSurface,
          ),
          dropdownColor: Colors.white,
          items: locationListMap.map((Map<String, dynamic> value) {
            return DropdownMenuItem<Map<String, dynamic>>(
              value: value,
              child: Text(
                value['name'],
                style: AppTheme.getTextStyle(
                  themeData.textTheme.bodyMedium,
                  color: themeData.colorScheme.onSurface,
                ),
              ),
            );
          }).toList(),
          onChanged: (Map<String, dynamic>? newValue) {
            if (newValue != null) {
              setState(() {
                selectedLocation = newValue;
                if (selectedLocation['id'] != 0) {
                  setExpenseCategories();
                } else {
                  expenseCategories = [];
                  expenseCategories.add({'id': 0, 'name': 'Select Category'});
                }
                setPaymentDetails(selectedLocation['id']).then((_) {
                  if (paymentMethods.isNotEmpty) {
                    selectedPaymentMethod = paymentMethods[0];
                  }
                  if (paymentAccounts.isNotEmpty) {
                    selectedPaymentAccount = paymentAccounts.firstWhere(
                          (element) =>
                      selectedPaymentMethod['account_id'] == element['id'],
                      orElse: () => paymentAccounts[0],
                    );
                  } else {
                    paymentAccounts = [];
                    paymentAccounts.add({'id': 0, 'name': 'Select Account'});
                  }
                });
              });
            }
          },
        ),
      ),
    );
  }

  // Category Section
  Widget expenseCategory() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: MySize.size12!),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(MySize.size8!),
        color: customAppTheme.bgLayer1,
        border: Border.all(color: customAppTheme.bgLayer3, width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Map<String, dynamic>>(
          value: expenseCategories.firstWhere(
                (element) => element['id'] == selectedExpenseCategoryId['id'],
            orElse: () => expenseCategories[0],
          ),
          isExpanded: true,
          icon: Icon(
            MdiIcons.chevronDown,
            size: MySize.size22,
            color: themeData.colorScheme.onSurface,
          ),
          dropdownColor: Colors.white,
          items: expenseCategories.map((Map<String, dynamic> value) {
            return DropdownMenuItem<Map<String, dynamic>>(
              value: value,
              child: Text(
                value['name'],
                style: AppTheme.getTextStyle(
                  themeData.textTheme.bodyMedium,
                  color: themeData.colorScheme.onSurface,
                ),
              ),
            );
          }).toList(),
          onChanged: (Map<String, dynamic>? newValue) {
            if (newValue != null) {
              setState(() {
                selectedExpenseCategoryId = newValue;
                selectedExpenseSubCategoryId = {
                  'id': 0,
                  'name': 'Select Sub Category'
                };
                if (newValue.containsKey('sub_categories') &&
                    newValue['sub_categories'].isNotEmpty) {
                  expenseSubCategories = newValue['sub_categories']
                      .map((element) =>
                  {'id': element['id'], 'name': element['name']})
                      .toList();
                } else {
                  expenseSubCategories = [];
                }
              });
            }
          },
        ),
      ),
    );
  }

  Widget expenseSubCategory() {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: MySize.size12!, vertical: MySize.size8!),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(MySize.size8!)),
        color: customAppTheme.bgLayer1,
        border: Border.all(color: customAppTheme.bgLayer3, width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Map<String, dynamic>>(
          value: selectedExpenseSubCategoryId.isEmpty
              ? {
            'id': 0,
            'name': 'Select Subcategory'
          } // Default value when empty
              : selectedExpenseSubCategoryId,
          onChanged: (Map<String, dynamic>? newValue) {
            if (newValue != null) {
              setState(() {
                selectedExpenseSubCategoryId = newValue;
              });
            }
          },
          icon: Icon(
            MdiIcons.chevronDown,
            size: MySize.size22,
            color: themeData.colorScheme.onSurface,
          ),
          isExpanded: true,
          dropdownColor: Colors.white,
          items: expenseSubCategories.map((Map<String, dynamic> value) {
            return DropdownMenuItem<Map<String, dynamic>>(
              value: value,
              child: Text(
                value['name'],
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
                style: AppTheme.getTextStyle(
                  themeData.textTheme.bodyMedium,
                  color: themeData.colorScheme.onSurface,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  setExpenseCategories() async {
    expenseCategories = [];
    expenseCategories.add({'id': 0, 'name': 'please wait...'});
    await ExpenseApi().get().then((value) {
      expenseCategories = [];
      expenseCategories.add({'id': 0, 'name': 'Select Category'});
      value.forEach((element) {
        setState(() {
          expenseCategories.add({
            'id': element['id'],
            'name': element['name'],
            'sub_categories': element['sub_categories']
          });
        });
      });
    });
  }

  //payment widget
  Widget payment() {
    return Column(
      children: <Widget>[
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(
              child: Divider(
                color: themeData.colorScheme.onSurface
                    .withOpacity(0.3), // Optional color for the divider
                thickness: 1,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                AppLocalizations.of(context).translate('payment_details'),
                style: AppTheme.getTextStyle(
                  themeData.textTheme.bodyMedium,
                  fontWeight: 700,
                  letterSpacing: -0.2,
                  color: themeData.colorScheme.onSurface,
                ),
              ),
            ),
            Expanded(
              child: Divider(
                color: themeData.colorScheme.onSurface.withOpacity(0.3),
                thickness: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '${AppLocalizations.of(context).translate('payment_method')} : ',
              style: AppTheme.getTextStyle(
                themeData.textTheme.titleLarge,
                fontWeight: 700,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: MySize.size12!, vertical: MySize.size8!),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(MySize.size8!)),
                color: customAppTheme.bgLayer1,
                border: Border.all(color: customAppTheme.bgLayer3, width: 1),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<Map<String, dynamic>>(
                  value: selectedPaymentMethod.isEmpty
                      ? {
                    'id': 0,
                    'value': 'Select Payment Method'
                  } // Default value when empty
                      : selectedPaymentMethod,
                  onChanged: (Map<String, dynamic>? newValue) {
                    if (newValue != null) {
                      setState(() {
                        selectedPaymentMethod = newValue;
                        selectedPaymentAccount =
                        paymentAccounts[0]; // Reset to the first account
                        paymentAccounts.forEach((element) {
                          if (selectedPaymentMethod['account_id'] ==
                              element['id']) {
                            selectedPaymentAccount = element;
                          }
                        });
                      });
                    }
                  },
                  icon: Icon(
                    MdiIcons.chevronDown,
                    size: MySize.size22,
                    color: themeData.colorScheme.onSurface,
                  ),
                  isExpanded: true,
                  dropdownColor: Colors.white,
                  items: paymentMethods.map((Map<String, dynamic> value) {
                    return DropdownMenuItem<Map<String, dynamic>>(
                      value: value,
                      child: Text(
                        value['value'],
                        style: AppTheme.getTextStyle(
                          themeData.textTheme.bodyMedium,
                          color: themeData.colorScheme.onSurface,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        paymentAccount(),
        const SizedBox(height: 12),
        TextFormField(
            validator: (value) {
              if (value == '') value = '0.00';
              if (expenseAmount.text == '' ||
                  double.parse(value!) > double.parse(expenseAmount.text)) {
                return AppLocalizations.of(context)
                    .translate('enter_valid_payment_amount');
              } else {
                return null;
              }
            },
            decoration: InputDecoration(
              prefix: Text(symbol),
              labelText:
              AppLocalizations.of(context).translate('payment_amount'),
              border: themeData.inputDecorationTheme.border,
              enabledBorder: themeData.inputDecorationTheme.border,
              focusedBorder: themeData.inputDecorationTheme.focusedBorder,
            ),
            controller: payingAmount,
            textAlign: TextAlign.end,
            style: AppTheme.getTextStyle(themeData.textTheme.titleSmall,
                fontWeight: 400, letterSpacing: -0.2),
            inputFormatters: [
              FilteringTextInputFormatter(RegExp(r'^(\d+)?\.?\d{0,2}'),
                  allow: true)
            ],
            keyboardType: TextInputType.number,
            onChanged: (value) {}),
      ],
    );
  }

  setPaymentDetails(int locId) async {
    await Helper().getFormattedBusinessDetails().then((value) {
      setState(() {
        symbol = value['symbol'];
      });
    });
    List payments =
    await System().get('payment_method', selectedLocation['id']);
    paymentAccounts = [
      {'id': null, 'name': "None"}
    ];
    await System().getPaymentAccounts().then((value) {
      List<String> accIds = [];
      value.forEach((element) {
        payments.forEach((payment) {
          if ((payment['account_id'].toString() == element['id'].toString()) &&
              !accIds.contains(element['id'].toString())) {
            accIds.add(element['id'].toString());
            paymentAccounts.add({'id': element['id'], 'name': element['name']});
          }
        });
      });
    });
    paymentMethods = [];
    payments.forEach((element) {
      setState(() {
        paymentMethods.add({
          'name': element['name'],
          'value': element['label'],
          'account_id': (element['account_id'] != null)
              ? int.parse(element['account_id'].toString())
              : null
        });
      });
    });
  }

  // payment account widget
  Widget paymentAccount() {
    return  Visibility(
      visible: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '${AppLocalizations.of(context).translate('payment_account')} : ',
            style: AppTheme.getTextStyle(
              themeData.textTheme.titleLarge,
              fontWeight: 700,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: MySize.size12!, vertical: MySize.size8!),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(MySize.size8!)),
              color: customAppTheme.bgLayer1,
              border: Border.all(color: customAppTheme.bgLayer3, width: 1),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Map<String, dynamic>>(
                // Set the value of the DropdownButton to selectedPaymentAccount or default
                value: selectedPaymentAccount['id'] == null
                    ? {
                  'id': null,
                  'name': 'Select Account'
                } // Default value when empty
                    : selectedPaymentAccount,
                onChanged: (Map<String, dynamic>? newValue) {
                  if (newValue != null) {
                    setState(() {
                      selectedPaymentAccount = newValue;
                      selectedPaymentMethod['account_id'] = newValue['id'];
                    });
                  }
                },
                icon: Icon(
                  MdiIcons.chevronDown,
                  size: MySize.size22,
                  color: themeData.colorScheme.onSurface,
                ),
                isExpanded: true,
                dropdownColor: Colors.white,
                items: [
                  // Don't include the default item when there is a valid selection
                  ...paymentAccounts
                      .where((item) => item['id'] != null)
                      .map((Map<String, dynamic> value) {
                    return DropdownMenuItem<Map<String, dynamic>>(
                      value: value,
                      child: Text(
                        value['name'] ??
                            'None', // Use 'None' as fallback for null name
                        style: AppTheme.getTextStyle(
                          themeData.textTheme.bodyMedium,
                          color: themeData.colorScheme.onSurface,
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
