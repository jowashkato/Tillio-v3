import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'dart:io';
import '../apis/api.dart';
import '../apis/contact.dart';
import '../helpers/AppTheme.dart';
import '../helpers/SizeConfig.dart';
import '../helpers/otherHelpers.dart';
import '../locale/MyLocalizations.dart';
import '../models/contact_model.dart';
import '../models/system.dart';
import '../pages/forms.dart';
import 'map_screen.dart'; // Import your map screen
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import '../config.dart';
import 'dart:convert';
import 'dart:math';
import 'package:encrypt/encrypt.dart' as encrypt;

class Contacts extends StatefulWidget {
  @override
  final String? labelText;
  final String? hintText;
  final ValueChanged<PhoneNumber>? onPhoneNumberChanged;
  final FormFieldValidator<String>? validator;

  const Contacts({
    Key? key,
    this.labelText,
    this.hintText,
    this.onPhoneNumberChanged,
    this.validator,
  }) : super(key: key);

  _ContactsState createState() => _ContactsState();
}

class _ContactsState extends State<Contacts> {
  final _formKey = GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool isLoading = false,
      isImage = false,
      useOrderBy = false,
      orderByAsc = true,
      useSearchBy = false;
  int currentTabIndex = 0;

  final ValueNotifier<String> imagePathNotifier = ValueNotifier('');

  String? _selectedGender;

  final String qrData = Config().digifarmerUrl;
  final String posKey = Config().posAPIKey;

  List<Map> leadsList = [],
      customerList = [],
      suppliersList = [],
      farmersList = [];

  ScrollController leadsListController = ScrollController(),
      customerListController = ScrollController(),
      farmersListController = ScrollController(),
      suppliersListController = ScrollController();

  var searchController = new TextEditingController();
  String? fetchLeads = Api().baseUrl + Api().apiUrl + "/crm/leads?per_page=10",
      fetchCustomers = Api().baseUrl +
          Api().apiUrl +
          "/contactapi?type=customer&per_page=10",
      fetchSuppliers = Api().baseUrl +
          Api().apiUrl +
          "/contactapi?type=supplier&per_page=10",
      fetchFarmers =
          Api().baseUrl + Api().apiUrl + "/farmer?type=farmer&per_page=10";
  String orderByColumn = 'name', orderByDirection = 'asc';

  TextEditingController prefix = new TextEditingController(),
      firstName = new TextEditingController(),
      middleName = new TextEditingController(),
      lastName = new TextEditingController(),
      mobile = new TextEditingController(),
      addressLine1 = new TextEditingController(),
      addressLine2 = new TextEditingController(),
      city = new TextEditingController(),
      state = new TextEditingController(),
      country = new TextEditingController(),
      zip = new TextEditingController(),
      field_area = new TextEditingController(),
      farm_name = new TextEditingController(),
      gender = new TextEditingController(),
      national_id = new TextEditingController(),
      size_unit = new TextEditingController(),
      email = new TextEditingController(),
      dob = new TextEditingController(),
      _controller = TextEditingController();
  PhoneNumber _phoneNumber = PhoneNumber(isoCode: 'UG');

  String? _fullNumber;
  String? _countryCode;
  String? _isoCode;
  String? _formattedNumber;

  static int themeType = 1;
  ThemeData themeData = AppTheme.getThemeFromThemeMode(themeType);
  CustomAppTheme customAppTheme = AppTheme.getCustomAppTheme(themeType);
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    setAllList();
    leadsListController.addListener(() {
      if (leadsListController.position.pixels ==
          leadsListController.position.maxScrollExtent) {
        setLeadsList();
      }
    });
    customerListController.addListener(() {
      if (customerListController.position.pixels ==
          customerListController.position.maxScrollExtent) {
        setCustomersList();
      }
    });
    suppliersListController.addListener(() {
      if (suppliersListController.position.pixels ==
          suppliersListController.position.maxScrollExtent) {
        setSuppliersList();
      }
    });
    farmersListController.addListener(() {
      if (farmersListController.position.pixels ==
          farmersListController.position.maxScrollExtent) {
        setFarmersList();
      }
    });
    Helper().syncCallLogs();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      initialIndex: 0,
      length: 3,
      child: Scaffold(
        key: _scaffoldKey,
        endDrawer: _filterDrawer(),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            setState(() {
              isLoading = false;
            });
            Navigator.of(context).push(new MaterialPageRoute<Null>(
                builder: (BuildContext context) {
                  return newCustomer(currentTabIndex);
                },
                fullscreenDialog: true));
          },
          child: Icon(MdiIcons.accountPlus),
          elevation: 2,
        ),
        appBar: AppBar(
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          actions: [
            IconButton(
              icon: Icon(MdiIcons.filterVariant),
              onPressed: () {
                _scaffoldKey.currentState!.openEndDrawer();
              },
            )
          ],
          title: Text(AppLocalizations.of(context).translate('contacts'),
              style: AppTheme.getTextStyle(themeData.textTheme.titleLarge,
                  fontWeight: 600)),
          bottom: TabBar(
              onTap: (int val) {
                currentTabIndex = val;
                searchController.clear();
                sortContactList(tabIndex: val);
              },
              tabs: [
                // Tab(
                //     icon: const Icon(MdiIcons.bookPlusMultipleOutline),
                //     child:
                //         Text(AppLocalizations.of(context).translate('leads'))),
                Tab(
                  icon: const Icon(MdiIcons.accountGroupOutline),
                  child:
                      Text(AppLocalizations.of(context).translate('customer')),
                ),
                Tab(
                  icon: const Icon(MdiIcons.accountMultipleOutline),
                  child:
                      Text(AppLocalizations.of(context).translate('suppliers')),
                ),
                Tab(
                  icon: const Icon(MdiIcons.bookPlusMultipleOutline),
                  child: Text(AppLocalizations.of(context).translate('farmer')),
                )
              ]),
        ),
        body: TabBarView(
          children: [
            // leadTab(leadsList),
            customerTab(customerList),
            supplierTab(suppliersList),
            farmerTab(farmersList),
          ],
        ),
      ),
    );
  }

  //Retrieve leads list from api
  setLeadsList() async {
    setState(() {
      isLoading = false;
    });
    final dio = new Dio();
    var token = await System().getToken();
    dio.options.headers['content-Type'] = 'application/json';
    dio.options.headers["Authorization"] = "Bearer $token";
    final response = await dio.get(fetchLeads!);
    List leads = response.data['data'];
    Map links = response.data['links'];
    setState(() {
      leads.forEach((element) {
        leadsList.add(element);
      });
    });
    isLoading = (links['next'] != null) ? true : false;
    fetchLeads = links['next'];
  }

  //Retrieve customers list from api
  setCustomersList() async {
    setState(() {
      isLoading = false;
    });
    final dio = new Dio();
    var token = await System().getToken();
    dio.options.headers['content-Type'] = 'application/json';
    dio.options.headers["Authorization"] = "Bearer $token";
    final response = await dio.get(fetchCustomers!);
    List customers = response.data['data'];
    Map links = response.data['links'];
    setState(() {
      customers.forEach((element) {
        customerList.add(element);
      });
    });
    isLoading = (links['next'] != null) ? true : false;
    fetchCustomers = links['next'];
    print(customerList.first['info']);
  }

  //Retrieve suppliers list from api
  setSuppliersList() async {
    setState(() {
      isLoading = false;
    });
    final dio = new Dio();
    var token = await System().getToken();
    dio.options.headers['content-Type'] = 'application/json';
    dio.options.headers["Authorization"] = "Bearer $token";
    final response = await dio.get(fetchSuppliers!);
    List suppliers = response.data['data'];
    Map links = response.data['links'];
    setState(() {
      suppliers.forEach((element) {
        suppliersList.add(element);
      });
    });
    isLoading = (links['next'] != null) ? true : false;
    fetchSuppliers = links['next'];
  }

//Retrieve farmers list from api
  setFarmersList() async {
    setState(() {
      isLoading = false;
    });
    final dio = new Dio();
    var token = await System().getToken();
    dio.options.headers['content-Type'] = 'application/json';
    dio.options.headers["Authorization"] = "Bearer $token";
    final response = await dio.get(fetchFarmers!);
    List farmers = response.data['data'];
    Map links = response.data['links'];
    setState(() {
      farmers.forEach((element) {
        farmersList.add(element);
      });
    });
    isLoading = (links['next'] != null) ? true : false;
    fetchFarmers = links['next'];
    //print(farmersList);
  }

  //set initial list
  setAllList() async {
    fetchLeads = getUrl();
    // setLeadsList();
    setCustomersList();
    setSuppliersList();
    setFarmersList();
  }

  //lead widget
  Widget leadTab(leads) {
    return (leads.length > 0)
        ? ListView.builder(
            controller: leadsListController,
            padding: EdgeInsets.all(MySize.size12!),
            shrinkWrap: true,
            itemCount: leads.length + 1,
            itemBuilder: (context, index) {
              if (index == leads.length) {
                return (isLoading) ? _buildProgressIndicator() : Container();
              } else {}
              return contactBlock(leads[index]);
            })
        : Helper().noDataWidget(context);
  }

  //customer widget
  Widget customerTab(customers) {
    return (customers.length > 0)
        ? ListView.builder(
            controller: customerListController,
            padding: EdgeInsets.all(MySize.size12!),
            shrinkWrap: true,
            itemCount: customers.length + 1,
            itemBuilder: (context, index) {
              if (index == customers.length) {
                return (isLoading) ? _buildProgressIndicator() : Container();
              } else {
                return contactBlock(customers[index]);
              }
            })
        : Helper().noDataWidget(context);
  }

  Widget contactBlock(contactDetails) {
    var totalInvoice = contactDetails['info']['total_invoice'] ?? 0.0;
    var invoiceReceived = contactDetails['info']['invoice_received'] ?? 0.0;
    var openingBalance = contactDetails['info']['opening_balance'] ?? 0.0;
    var openingBalancePaid =
        contactDetails['info']['opening_balance_paid'] ?? 0.0;
    // Ensure both values are of type double
    if (totalInvoice is! double) {
      totalInvoice = double.tryParse(totalInvoice.toString()) ?? 0.0;
    }
    if (openingBalance is! double) {
      openingBalance = double.tryParse(openingBalance.toString()) ?? 0.0;
    }
    if (openingBalancePaid is! double) {
      openingBalancePaid =
          double.tryParse(openingBalancePaid.toString()) ?? 0.0;
    }
    if (invoiceReceived is! double) {
      invoiceReceived = double.tryParse(invoiceReceived.toString()) ?? 0.0;
    }

    var balance = (totalInvoice + openingBalance) -
        (invoiceReceived + openingBalancePaid);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeData.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Business Name
          if (contactDetails['supplier_business_name'] != null &&
              contactDetails['supplier_business_name'].toString().isNotEmpty)
            Text(
              contactDetails['supplier_business_name']!,
              style: AppTheme.getTextStyle(
                themeData.textTheme.titleLarge,
                fontWeight: 800,
                color: themeData.colorScheme.primary,
              ),
            ),
          const SizedBox(height: 8),

          // Customer Name
          if (contactDetails['name'] != null &&
              contactDetails['name'].toString().trim().isNotEmpty)
            Row(
              children: [
                Text(
                  "${AppLocalizations.of(context).translate('customer')} : ",
                  style: AppTheme.getTextStyle(
                    themeData.textTheme.bodyLarge,
                    fontWeight: 600,
                    color: themeData.colorScheme.onSurface,
                  ),
                ),
                Expanded(
                  child: Text(
                    contactDetails['name']!,
                    style: AppTheme.getTextStyle(
                      themeData.textTheme.bodyMedium,
                      fontWeight: 500,
                      color: themeData.colorScheme.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          Row(
            children: [
              Text(
                "Balance Due : ",
                style: AppTheme.getTextStyle(
                  themeData.textTheme.bodyLarge,
                  fontWeight: 600,
                  color: themeData.colorScheme.onSurface,
                ),
              ),
              Expanded(
                child: Text(
                  Helper().formatCurrency(balance),
                  style: AppTheme.getTextStyle(
                    themeData.textTheme.bodyMedium,
                    fontWeight: 500,
                    color: themeData.colorScheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Last Follow-Up
          if (contactDetails['last_follow_up'] != null &&
              contactDetails['last_follow_up'].toString().trim().isNotEmpty)
            Row(
              children: [
                Text(
                  "${AppLocalizations.of(context).translate('last')} : ",
                  style: AppTheme.getTextStyle(
                    themeData.textTheme.bodyLarge,
                    fontWeight: 600,
                    color: themeData.colorScheme.onSurface,
                  ),
                ),
                Text(
                  contactDetails['last_follow_up']!,
                  style: AppTheme.getTextStyle(
                    themeData.textTheme.bodyMedium,
                    fontWeight: 500,
                    color: themeData.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 8),

          // Upcoming Follow-Up
          if (contactDetails['upcoming_follow_up'] != null &&
              contactDetails['upcoming_follow_up'].toString().trim().isNotEmpty)
            Row(
              children: [
                Text(
                  "${AppLocalizations.of(context).translate('upcoming')} : ",
                  style: AppTheme.getTextStyle(
                    themeData.textTheme.bodyLarge,
                    fontWeight: 600,
                    color: themeData.colorScheme.onSurface,
                  ),
                ),
                Text(
                  contactDetails['upcoming_follow_up']!,
                  style: AppTheme.getTextStyle(
                    themeData.textTheme.bodyMedium,
                    fontWeight: 500,
                    color: themeData.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          const Divider(height: 20),

          // Actions: Call and Follow-Up
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Call Dropdown
              Helper().callDropdown(
                context,
                contactDetails,
                [
                  contactDetails['mobile'],
                  contactDetails['alternate_number'],
                  contactDetails['landline']
                ],
                type: 'call',
              ),
              // Add Follow-Up Button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  backgroundColor: themeData.colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FollowUpForm(contactDetails),
                    ),
                  );
                },
                icon: const Icon(Icons.add, size: 18),
                label: Text(
                  AppLocalizations.of(context).translate('add_follow_up'),
                  style: AppTheme.getTextStyle(
                    themeData.textTheme.bodyMedium,
                    fontWeight: 800,
                    color: themeData.colorScheme.onPrimary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget contactFarmerBlock(farmerDetails) {
    double wd = MediaQuery.of(context).size.width;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeData.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (farmerDetails['custom_field5'] != null &&
              farmerDetails['custom_field5'].toString().isNotEmpty)
            Image.network(
                Api().baseUrl + '/storage/' + farmerDetails['custom_field5']!,
                height: 220,
                width: wd * 0.8,
                fit: BoxFit.cover),
          const SizedBox(height: 8),
          // Business Name
          if (farmerDetails['first_name'] != null &&
              farmerDetails['first_name'].toString().isNotEmpty)
            Text(
              farmerDetails['first_name']!,
              style: AppTheme.getTextStyle(
                themeData.textTheme.titleLarge,
                fontWeight: 800,
                color: themeData.colorScheme.primary,
              ),
            ),
          const SizedBox(height: 8),

          // Customer Name
          if (farmerDetails['first_name'] != null &&
              farmerDetails['first_name'].toString().trim().isNotEmpty)
            Row(
              children: [
                Text(
                  "${AppLocalizations.of(context).translate('farmer')} : ",
                  style: AppTheme.getTextStyle(
                    themeData.textTheme.bodyLarge,
                    fontWeight: 600,
                    color: themeData.colorScheme.onSurface,
                  ),
                ),
                Expanded(
                  child: Text(
                    farmerDetails['first_name']!,
                    style: AppTheme.getTextStyle(
                      themeData.textTheme.bodyMedium,
                      fontWeight: 500,
                      color: themeData.colorScheme.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          if (farmerDetails['email'] != null &&
              farmerDetails['email'].toString().trim().isNotEmpty)
            Row(
              children: [
                Text(
                  "Email : ",
                  style: AppTheme.getTextStyle(
                    themeData.textTheme.bodyLarge,
                    fontWeight: 600,
                    color: themeData.colorScheme.onSurface,
                  ),
                ),
                Expanded(
                  child: Text(
                    farmerDetails['email']!,
                    style: AppTheme.getTextStyle(
                      themeData.textTheme.bodyMedium,
                      fontWeight: 500,
                      color: themeData.colorScheme.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 8),

          // Last Follow-Up
          if (farmerDetails['state'] != null &&
              farmerDetails['state'].toString().trim().isNotEmpty)
            Row(
              children: [
                Text(
                  "${AppLocalizations.of(context).translate('state')} : ",
                  style: AppTheme.getTextStyle(
                    themeData.textTheme.bodyLarge,
                    fontWeight: 600,
                    color: themeData.colorScheme.onSurface,
                  ),
                ),
                Text(
                  farmerDetails['state']!,
                  style: AppTheme.getTextStyle(
                    themeData.textTheme.bodyMedium,
                    fontWeight: 500,
                    color: themeData.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 8),

          // Upcoming Follow-Up
          if (farmerDetails['land_details'] != null &&
              farmerDetails['land_details'].toString().trim().isNotEmpty &&
              farmerDetails['size_unit'] != null &&
              farmerDetails['size_unit'].toString().trim().isNotEmpty)
            Row(
              children: [
                Text(
                  "land_details : ",
                  style: AppTheme.getTextStyle(
                    themeData.textTheme.bodyLarge,
                    fontWeight: 600,
                    color: themeData.colorScheme.onSurface,
                  ),
                ),
                Text(
                  farmerDetails['land_details'] +
                      " " +
                      farmerDetails['size_unit']!,
                  style: AppTheme.getTextStyle(
                    themeData.textTheme.bodyMedium,
                    fontWeight: 500,
                    color: themeData.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          SizedBox(height: 7),

          // QR Code Display
          if (farmerDetails['farmer_code'] != null &&
              farmerDetails['farmer_code'].toString().trim().isNotEmpty)
            Container(
              padding: EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: QrImageView(
                data: generateQRCodeData(farmerDetails['farmer_code']!, posKey),
                version: QrVersions.auto,
                size: 120.0,
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: EdgeInsets.all(10),
              ),
            ),

          const Divider(height: 20),

          // Actions: Call and Follow-Up
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Call Dropdown
              Helper().callDropdown(
                context,
                farmerDetails,
                [
                  farmerDetails['mobile'],
                  farmerDetails['alternate_number'],
                  farmerDetails['landline']
                ],
                type: 'call',
              ),
              IconButton(
                icon: Icon(Icons.print),
                iconSize: 25.0,
                color: themeData.colorScheme.primary,
                onPressed: () {
                  _printQRCode(generateQRCodeData(
                      farmerDetails['farmer_code']!, posKey));
                },
              ),
              // Add Follow-Up Button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                  backgroundColor: themeData.colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(
                  //     builder: (context) => FollowUpForm(farmerDetails),
                  //   ),
                  // );
                  setState(() {
                    isLoading = false;
                  });
                  Navigator.of(context).push(new MaterialPageRoute<Null>(
                      builder: (BuildContext context) {
                        return editFarmer(farmerDetails);
                      },
                      fullscreenDialog: true));
                },
                icon: const Icon(Icons.add, size: 18),
                label: Text(
                  AppLocalizations.of(context).translate('edit_follow_up'),
                  style: AppTheme.getTextStyle(
                    themeData.textTheme.bodyMedium,
                    fontWeight: 800,
                    color: themeData.colorScheme.onPrimary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  //supplier widget
  Widget supplierTab(suppliers) {
    return (suppliers.length > 0)
        ? ListView.builder(
            controller: suppliersListController,
            padding: EdgeInsets.all(MySize.size12!),
            shrinkWrap: true,
            itemCount: suppliers.length + 1,
            itemBuilder: (context, index) {
              if (index == suppliers.length) {
                return (isLoading) ? _buildProgressIndicator() : Container();
              } else {
                return Container(
                  margin: EdgeInsets.only(bottom: MySize.size8!),
                  padding: EdgeInsets.all(MySize.size8!),
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.all(Radius.circular(MySize.size8!)),
                    color: customAppTheme.bgLayer1,
                    border:
                        Border.all(color: customAppTheme.bgLayer4, width: 1.2),
                  ),
                  child: contactBlock(suppliers[index]),
                );
              }
            })
        : Helper().noDataWidget(context);
  }

  //farmer widget
  Widget farmerTab(farmers) {
    return (farmers.length > 0)
        ? ListView.builder(
            controller: farmersListController,
            padding: EdgeInsets.all(MySize.size12!),
            shrinkWrap: true,
            itemCount: farmers.length + 1,
            itemBuilder: (context, index) {
              if (index == farmers.length) {
                return (isLoading) ? _buildProgressIndicator() : Container();
              } else {}
              return contactFarmerBlock(farmers[index]);
            })
        : Helper().noDataWidget(context);
  }

  //filter widget
  Widget _filterDrawer() {
    return SafeArea(
      child: Container(
        padding: EdgeInsets.all(MySize.size12!),
        width: MediaQuery.of(context).size.width * 0.75,
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Form(
              // key: _formKey,
              child: TextFormField(
                  style: AppTheme.getTextStyle(themeData.textTheme.titleSmall,
                      letterSpacing: 0, fontWeight: 500),
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context).translate('search'),
                    hintStyle: AppTheme.getTextStyle(
                        themeData.textTheme.titleSmall,
                        letterSpacing: 0,
                        fontWeight: 500),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(
                          Radius.circular(MySize.size16!),
                        ),
                        borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(
                          Radius.circular(MySize.size16!),
                        ),
                        borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(
                          Radius.circular(MySize.size16!),
                        ),
                        borderSide: BorderSide.none),
                    filled: true,
                    fillColor: themeData.colorScheme.surface,
                    prefixIcon: Icon(
                      MdiIcons.magnify,
                      color: themeData.colorScheme.onSurface.withAlpha(150),
                    ),
                    isDense: true,
                    contentPadding: EdgeInsets.only(right: MySize.size16!),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  controller: searchController,
                  onEditingComplete: () {
                    setState(() {
                      sortContactList(
                        tabIndex: currentTabIndex,
                      );
                    });
                    //unFocus cursor from search area
                    FocusScopeNode currentFocus = FocusScope.of(context);
                    if (!currentFocus.hasPrimaryFocus) {
                      currentFocus.unfocus();
                    }
                    //call method
                  }),
            ),
            Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      useOrderBy = !useOrderBy;
                      sortContactList(
                        tabIndex: currentTabIndex,
                      );
                    });
                  },
                  icon: (useOrderBy)
                      ? Icon(Icons.keyboard_arrow_up_outlined)
                      : Icon(Icons.keyboard_arrow_down_outlined),
                  label: (useOrderBy)
                      ? Text(
                          "${AppLocalizations.of(context).translate('order_by')} :",
                          style: AppTheme.getTextStyle(
                              themeData.textTheme.bodyLarge,
                              fontWeight: 600,
                              letterSpacing: 0),
                        )
                      : Text(
                          AppLocalizations.of(context)
                              .translate('tap_for_order_by'),
                          style: AppTheme.getTextStyle(
                              themeData.textTheme.bodyLarge,
                              fontWeight: 600,
                              letterSpacing: 0),
                        ),
                ),
                Visibility(
                  visible: useOrderBy,
                  child: TextButton.icon(
                    onPressed: () {
                      orderByAsc = !orderByAsc;
                      setState(() {
                        orderByDirection = (orderByAsc) ? 'asc' : 'desc';
                        sortContactList(
                          tabIndex: currentTabIndex,
                        );
                      });
                    },
                    label: Text(
                      "$orderByDirection".toUpperCase(),
                      style: AppTheme.getTextStyle(
                          themeData.textTheme.bodyLarge,
                          fontWeight: 500,
                          letterSpacing: 0),
                    ),
                    icon: (orderByAsc)
                        ? Icon(
                            MdiIcons.arrowUpCircleOutline,
                            color: Colors.black,
                          )
                        : Icon(MdiIcons.arrowDownCircleOutline,
                            color: Colors.black),
                  ),
                )
              ],
            ),
            Visibility(
              visible: useOrderBy,
              child: Column(
                children: [
                  ListTile(
                    title: Text(
                      AppLocalizations.of(context).translate('name'),
                      style: AppTheme.getTextStyle(
                          themeData.textTheme.bodyMedium,
                          fontWeight: 500,
                          letterSpacing: 0),
                    ),
                    leading: Radio(
                      value: 'name',
                      groupValue: orderByColumn,
                      onChanged: (value) {
                        setState(() {
                          orderByColumn = value.toString();
                          sortContactList(
                            tabIndex: currentTabIndex,
                          );
                        });
                      },
                    ),
                  ),
                  ListTile(
                    title: Text(
                      AppLocalizations.of(context).translate('business_name'),
                      style: AppTheme.getTextStyle(
                          themeData.textTheme.bodyMedium,
                          fontWeight: 500,
                          letterSpacing: 0),
                    ),
                    leading: Radio(
                      value: 'first_name',
                      groupValue: orderByColumn,
                      onChanged: (value) {
                        setState(() {
                          orderByColumn = value.toString();
                          sortContactList(
                            tabIndex: currentTabIndex,
                          );
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            Divider(),
            // RaisedButton.icon(
            //     onPressed: () {
            //       setState(() {
            //         sortContactList(
            //           tabIndex: currentTabIndex,
            //           searchText: searchController.text,
            //         );
            //       });
            //     },
            //     icon: Icon(Icons.margin),
            //     label: Text("APPLY"))
          ],
        ),
      ),
    );
  }

  //contact widget
  Widget contactBlockOld(contactDetails) {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Visibility(
            visible:
                (contactDetails['supplier_business_name'].toString() != 'null'),
            child: Text(
              '${contactDetails['supplier_business_name']}',
              style: AppTheme.getTextStyle(
                themeData.textTheme.bodyLarge,
                fontWeight: 600,
                color: themeData.colorScheme.onSurface,
              ),
            ),
          ),
          Visibility(
            visible: (contactDetails['name'].toString() != 'null' &&
                contactDetails['name'].toString().trim() != ''),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${AppLocalizations.of(context).translate('customer')} : ",
                  style: AppTheme.getTextStyle(
                    themeData.textTheme.bodyLarge,
                    fontWeight: 600,
                    color: themeData.colorScheme.onSurface,
                  ),
                ),
                Flexible(
                  fit: FlexFit.loose,
                  child: Text(
                    '${contactDetails['name']}',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.getTextStyle(
                      themeData.textTheme.bodyMedium,
                      fontWeight: 500,
                      color: themeData.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Visibility(
            visible: (contactDetails['last_follow_up'].toString() != 'null' &&
                contactDetails['last_follow_up'].toString().trim() != ''),
            child: Row(
              children: [
                Text(
                  "${AppLocalizations.of(context).translate('last')} : ",
                  style: AppTheme.getTextStyle(
                    themeData.textTheme.bodyLarge,
                    fontWeight: 600,
                    color: themeData.colorScheme.onSurface,
                  ),
                ),
                Text(
                  (contactDetails['last_follow_up'].toString() != 'null')
                      ? '${contactDetails['last_follow_up']}'
                      : ' - ',
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.getTextStyle(
                    themeData.textTheme.bodyMedium,
                    fontWeight: 500,
                    color: themeData.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          Visibility(
            visible: (contactDetails['upcoming_follow_up'].toString() !=
                    'null' &&
                contactDetails['upcoming_follow_up'].toString().trim() != ''),
            child: Row(
              children: [
                Text(
                  "${AppLocalizations.of(context).translate('upcoming')} : ",
                  style: AppTheme.getTextStyle(
                    themeData.textTheme.bodyLarge,
                    fontWeight: 600,
                    color: themeData.colorScheme.onSurface,
                  ),
                ),
                Text(
                  (contactDetails['upcoming_follow_up'].toString() != 'null')
                      ? '${contactDetails['upcoming_follow_up']}'
                      : ' - ',
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.getTextStyle(
                    themeData.textTheme.bodyMedium,
                    fontWeight: 500,
                    color: themeData.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Helper().callDropdown(
                  context,
                  contactDetails,
                  [
                    contactDetails['mobile'],
                    contactDetails['alternate_number'],
                    contactDetails['landline']
                  ],
                  type: 'call'),
              SizedBox(
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                FollowUpForm(contactDetails)));
                  },
                  icon: Icon(
                    Icons.add,
                    color: themeData.colorScheme.primary,
                  ),
                  label: Text(
                    AppLocalizations.of(context).translate('add_follow_up'),
                    style: AppTheme.getTextStyle(
                      themeData.textTheme.bodyLarge,
                      fontWeight: 600,
                      color: themeData.colorScheme.primary,
                    ),
                  ),
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  //filter list
  sortContactList({int? tabIndex}) {
    switch (tabIndex) {
      case 0:
        {
          leadsList = [];
          fetchLeads = getUrl();
          setLeadsList();
        }
        break;
      case 1:
        {
          customerList = [];
          fetchCustomers = getUrl();
          setCustomersList();
        }
        break;
      case 2:
        {
          suppliersList = [];
          fetchSuppliers = getUrl();
          setSuppliersList();
        }
        break;
      case 3:
        {
          farmersList = [];
          fetchFarmers = getUrl();
          setFarmersList();
        }
        break;
    }
  }

  getUrl({String? perPage = '10'}) {
    String contactType =
        (currentTabIndex == 0) ? '/crm/leads?' : '/contactapi?';
    String url = Api().baseUrl + Api().apiUrl + contactType;

    Map<String, dynamic> params = {};

    if (currentTabIndex == 1) {
      params['type'] = 'customer';
    }
    if (currentTabIndex == 2) {
      params['type'] = 'supplier';
    }
    if (searchController.text != '') {
      params['name'] = searchController.text;
      params['biz_name'] = searchController.text;
      params['mobile_num'] = searchController.text;
      params['contact_id'] = searchController.text;
    }

    if (perPage != null) {
      params['per_page'] = perPage;
    }

    if (useOrderBy) {
      params['order_by'] = '$orderByColumn';
      params['direction'] = '$orderByDirection';
    }

    String queryString = Uri(queryParameters: params).query;
    url += queryString;
    return url;
  }

  //show add customer alert box
  Widget newCustomer(lad) {
    return Scaffold(
      appBar: new AppBar(
        title: Text(
          AppLocalizations.of(context).translate('create_contact'),
        ),
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        padding: EdgeInsets.only(top: 8, bottom: 8, left: 16, right: 16),
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Container(
                          width: 64,
                          child: Center(
                            child: Icon(
                              MdiIcons.accountChildCircle,
                              color: themeData.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Container(
                            margin: EdgeInsets.only(left: 16),
                            child: Column(
                              children: <Widget>[
                                Row(
                                  children: <Widget>[
                                    Container(
                                      width: 50,
                                      child: TextFormField(
                                        controller: prefix,
                                        style: themeData.textTheme.titleSmall!
                                            .merge(TextStyle(
                                                color: themeData
                                                    .colorScheme.onSurface)),
                                        decoration: InputDecoration(
                                          hintStyle: themeData
                                              .textTheme.titleSmall!
                                              .merge(TextStyle(
                                                  color: themeData
                                                      .colorScheme.onSurface)),
                                          hintText: AppLocalizations.of(context)
                                              .translate('prefix'),
                                          border: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: themeData
                                                    .inputDecorationTheme
                                                    .border!
                                                    .borderSide
                                                    .color),
                                          ),
                                          enabledBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: themeData
                                                    .inputDecorationTheme
                                                    .enabledBorder!
                                                    .borderSide
                                                    .color),
                                          ),
                                          focusedBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: themeData
                                                    .inputDecorationTheme
                                                    .focusedBorder!
                                                    .borderSide
                                                    .color),
                                          ),
                                        ),
                                        textCapitalization:
                                            TextCapitalization.sentences,
                                      ),
                                    ),
                                    Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 4)),
                                    Expanded(
                                      child: TextFormField(
                                        controller: firstName,
                                        validator: (value) {
                                          if (value!.length < 1) {
                                            return AppLocalizations.of(context)
                                                .translate(
                                                    'please_enter_your_name');
                                          } else {
                                            return null;
                                          }
                                        },
                                        style: themeData.textTheme.titleSmall!
                                            .merge(TextStyle(
                                                color: themeData
                                                    .colorScheme.onSurface)),
                                        decoration: InputDecoration(
                                          hintStyle: themeData
                                              .textTheme.titleSmall!
                                              .merge(TextStyle(
                                                  color: themeData
                                                      .colorScheme.onSurface)),
                                          hintText: AppLocalizations.of(context)
                                                  .translate('first_name') +
                                              '*',
                                          border: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: themeData
                                                    .inputDecorationTheme
                                                    .border!
                                                    .borderSide
                                                    .color),
                                          ),
                                          enabledBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: themeData
                                                    .inputDecorationTheme
                                                    .enabledBorder!
                                                    .borderSide
                                                    .color),
                                          ),
                                          focusedBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: themeData
                                                    .inputDecorationTheme
                                                    .focusedBorder!
                                                    .borderSide
                                                    .color),
                                          ),
                                        ),
                                        textCapitalization:
                                            TextCapitalization.sentences,
                                      ),
                                    )
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    Container(
                                      width: MySize.screenWidth! * 0.35,
                                      child: TextFormField(
                                        controller: middleName,
                                        style: themeData.textTheme.titleSmall!
                                            .merge(TextStyle(
                                                color: themeData
                                                    .colorScheme.onSurface)),
                                        decoration: InputDecoration(
                                          hintStyle: themeData
                                              .textTheme.titleSmall!
                                              .merge(TextStyle(
                                                  color: themeData
                                                      .colorScheme.onSurface)),
                                          hintText: AppLocalizations.of(context)
                                              .translate('middle_name'),
                                          border: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: themeData
                                                    .inputDecorationTheme
                                                    .border!
                                                    .borderSide
                                                    .color),
                                          ),
                                          enabledBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: themeData
                                                    .inputDecorationTheme
                                                    .enabledBorder!
                                                    .borderSide
                                                    .color),
                                          ),
                                          focusedBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: themeData
                                                    .inputDecorationTheme
                                                    .focusedBorder!
                                                    .borderSide
                                                    .color),
                                          ),
                                        ),
                                        textCapitalization:
                                            TextCapitalization.sentences,
                                      ),
                                    ),
                                    Container(
                                      width: MySize.screenWidth! * 0.35,
                                      child: TextFormField(
                                        controller: lastName,
                                        style: themeData.textTheme.titleSmall!
                                            .merge(TextStyle(
                                                color: themeData
                                                    .colorScheme.onSurface)),
                                        decoration: InputDecoration(
                                          hintStyle: themeData
                                              .textTheme.titleSmall!
                                              .merge(TextStyle(
                                                  color: themeData
                                                      .colorScheme.onSurface)),
                                          hintText: AppLocalizations.of(context)
                                              .translate('last_name'),
                                          border: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: themeData
                                                    .inputDecorationTheme
                                                    .border!
                                                    .borderSide
                                                    .color),
                                          ),
                                          enabledBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: themeData
                                                    .inputDecorationTheme
                                                    .enabledBorder!
                                                    .borderSide
                                                    .color),
                                          ),
                                          focusedBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: themeData
                                                    .inputDecorationTheme
                                                    .focusedBorder!
                                                    .borderSide
                                                    .color),
                                          ),
                                        ),
                                        textCapitalization:
                                            TextCapitalization.sentences,
                                      ),
                                    )
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    if (lad == 2)
                                      Container(
                                        width: MySize.screenWidth! * 0.35,
                                        child: TextFormField(
                                          controller: farm_name,
                                          style: themeData.textTheme.titleSmall!
                                              .merge(TextStyle(
                                                  color: themeData
                                                      .colorScheme.onSurface)),
                                          decoration: InputDecoration(
                                            hintStyle: themeData
                                                .textTheme.titleSmall!
                                                .merge(TextStyle(
                                                    color: themeData.colorScheme
                                                        .onSurface)),
                                            hintText: AppLocalizations.of(
                                                        context)
                                                    .translate('farm name') +
                                                '*',
                                            border: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: themeData
                                                      .inputDecorationTheme
                                                      .border!
                                                      .borderSide
                                                      .color),
                                            ),
                                            enabledBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: themeData
                                                      .inputDecorationTheme
                                                      .enabledBorder!
                                                      .borderSide
                                                      .color),
                                            ),
                                            focusedBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: themeData
                                                      .inputDecorationTheme
                                                      .focusedBorder!
                                                      .borderSide
                                                      .color),
                                            ),
                                          ),
                                          textCapitalization:
                                              TextCapitalization.sentences,
                                          validator: (value) {
                                            if (value!.length < 1) {
                                              return AppLocalizations.of(
                                                      context)
                                                  .translate(
                                                      'please_enter_your_name');
                                            } else {
                                              return null;
                                            }
                                          },
                                        ),
                                      ),
                                    if (lad == 2)
                                      Container(
                                        width: MySize.screenWidth! * 0.35,
                                        child: TextFormField(
                                          controller: dob,
                                          style: themeData.textTheme.titleSmall!
                                              .merge(TextStyle(
                                                  color: themeData
                                                      .colorScheme.onSurface)),
                                          decoration: InputDecoration(
                                            hintStyle: themeData
                                                .textTheme.titleSmall!
                                                .merge(TextStyle(
                                                    color: themeData.colorScheme
                                                        .onSurface)),
                                            hintText:
                                                AppLocalizations.of(context)
                                                    .translate('date'),
                                            border: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: themeData
                                                      .inputDecorationTheme
                                                      .border!
                                                      .borderSide
                                                      .color),
                                            ),
                                            enabledBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: themeData
                                                      .inputDecorationTheme
                                                      .enabledBorder!
                                                      .borderSide
                                                      .color),
                                            ),
                                            focusedBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: themeData
                                                      .inputDecorationTheme
                                                      .focusedBorder!
                                                      .borderSide
                                                      .color),
                                            ),
                                          ),
                                          textCapitalization:
                                              TextCapitalization.sentences,
                                          onTap: () async {
                                            DateTime? pickedDate =
                                                await showDatePicker(
                                              context: context,
                                              initialDate: DateTime.now(),
                                              firstDate: DateTime(1900),
                                              lastDate: DateTime(2100),
                                            );

                                            if (pickedDate != null) {
                                              String formattedDate =
                                                  "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                                              setState(() {
                                                dob.text = formattedDate;
                                              });
                                            }
                                          },
                                        ),
                                      ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    if (lad == 2)
                                      Container(
                                        width: MySize.screenWidth! * 0.35,
                                        child: TextFormField(
                                          controller: national_id,
                                          style: themeData.textTheme.titleSmall!
                                              .merge(TextStyle(
                                                  color: themeData
                                                      .colorScheme.onSurface)),
                                          decoration: InputDecoration(
                                            hintStyle: themeData
                                                .textTheme.titleSmall!
                                                .merge(TextStyle(
                                                    color: themeData.colorScheme
                                                        .onSurface)),
                                            hintText: AppLocalizations.of(
                                                        context)
                                                    .translate('national_ID') +
                                                '*',
                                            border: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: themeData
                                                      .inputDecorationTheme
                                                      .border!
                                                      .borderSide
                                                      .color),
                                            ),
                                            enabledBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: themeData
                                                      .inputDecorationTheme
                                                      .enabledBorder!
                                                      .borderSide
                                                      .color),
                                            ),
                                            focusedBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: themeData
                                                      .inputDecorationTheme
                                                      .focusedBorder!
                                                      .borderSide
                                                      .color),
                                            ),
                                          ),
                                          textCapitalization:
                                              TextCapitalization.sentences,
                                          validator: (value) {
                                            if (value!.length < 1) {
                                              return AppLocalizations.of(
                                                      context)
                                                  .translate(
                                                      'please_enter_your_name');
                                            } else {
                                              return null;
                                            }
                                          },
                                        ),
                                      ),
                                    if (lad == 2)
                                      Container(
                                        width: MySize.screenWidth! * 0.35,
                                        child: DropdownButtonFormField<String>(
                                          value: _selectedGender,
                                          dropdownColor: Colors.white,
                                          decoration: InputDecoration(
                                            hintText:
                                                AppLocalizations.of(context)
                                                        .translate('gender') +
                                                    '*',
                                            border: OutlineInputBorder(),
                                          ),
                                          items:
                                              ['Male', 'Female'].map((gender) {
                                            return DropdownMenuItem(
                                                value: gender,
                                                child: Text(gender,
                                                    style:
                                                        AppTheme.getTextStyle(
                                                            themeData.textTheme
                                                                .bodyLarge,
                                                            color: themeData
                                                                .colorScheme
                                                                .onSurface)));
                                          }).toList(),
                                          onChanged: (value) {
                                            setState(() {
                                              _selectedGender = value;
                                            });
                                          },
                                          validator: (value) => value == null
                                              ? 'Please select gender'
                                              : null,
                                        ),
                                      ),
                                  ],
                                ),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: <Widget>[
                                    if (lad == 2)
                                      Container(
                                        width: MySize.screenWidth! * 0.65,
                                        child: TextFormField(
                                          controller: email,
                                          style: themeData.textTheme.titleSmall!
                                              .merge(TextStyle(
                                                  color: themeData
                                                      .colorScheme.onSurface)),
                                          decoration: InputDecoration(
                                            hintStyle: themeData
                                                .textTheme.titleSmall!
                                                .merge(TextStyle(
                                                    color: themeData.colorScheme
                                                        .onSurface)),
                                            hintText:
                                                AppLocalizations.of(context)
                                                        .translate('email') +
                                                    '*',
                                            border: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: themeData
                                                      .inputDecorationTheme
                                                      .border!
                                                      .borderSide
                                                      .color),
                                            ),
                                            enabledBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: themeData
                                                      .inputDecorationTheme
                                                      .enabledBorder!
                                                      .borderSide
                                                      .color),
                                            ),
                                            focusedBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: themeData
                                                      .inputDecorationTheme
                                                      .focusedBorder!
                                                      .borderSide
                                                      .color),
                                            ),
                                          ),
                                          textCapitalization:
                                              TextCapitalization.sentences,
                                          validator: (value) {
                                            if (value!.length < 1) {
                                              return AppLocalizations.of(
                                                      context)
                                                  .translate(
                                                      'please_enter_email');
                                            } else {
                                              return null;
                                            }
                                          },
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                    if (lad != 2)
                      Container(
                        margin: EdgeInsets.only(top: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            Container(
                              width: 64,
                              child: Center(
                                child: Icon(
                                  MdiIcons.homeCityOutline,
                                  color: themeData.colorScheme.onSurface,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Container(
                                margin: EdgeInsets.only(left: 16),
                                child: Column(
                                  children: <Widget>[
                                    if (lad < 2)
                                      TextFormField(
                                        controller: addressLine1,
                                        style: themeData.textTheme.titleSmall!
                                            .merge(TextStyle(
                                                color: themeData
                                                    .colorScheme.onSurface)),
                                        decoration: InputDecoration(
                                          hintStyle: themeData
                                              .textTheme.titleSmall!
                                              .merge(TextStyle(
                                                  color: themeData
                                                      .colorScheme.onSurface)),
                                          hintText: AppLocalizations.of(context)
                                              .translate('address_line_1'),
                                          border: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: themeData
                                                    .inputDecorationTheme
                                                    .border!
                                                    .borderSide
                                                    .color),
                                          ),
                                          enabledBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: themeData
                                                    .inputDecorationTheme
                                                    .enabledBorder!
                                                    .borderSide
                                                    .color),
                                          ),
                                          focusedBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: themeData
                                                    .inputDecorationTheme
                                                    .focusedBorder!
                                                    .borderSide
                                                    .color),
                                          ),
                                        ),
                                        textCapitalization:
                                            TextCapitalization.sentences,
                                      ),
                                    if (lad < 2)
                                      TextFormField(
                                        controller: addressLine2,
                                        style: themeData.textTheme.titleSmall!
                                            .merge(TextStyle(
                                                color: themeData
                                                    .colorScheme.onSurface)),
                                        decoration: InputDecoration(
                                          hintStyle: themeData
                                              .textTheme.titleSmall!
                                              .merge(TextStyle(
                                                  color: themeData
                                                      .colorScheme.onSurface)),
                                          hintText: AppLocalizations.of(context)
                                              .translate('address_line_2'),
                                          border: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: themeData
                                                    .inputDecorationTheme
                                                    .border!
                                                    .borderSide
                                                    .color),
                                          ),
                                          enabledBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: themeData
                                                    .inputDecorationTheme
                                                    .enabledBorder!
                                                    .borderSide
                                                    .color),
                                          ),
                                          focusedBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: themeData
                                                    .inputDecorationTheme
                                                    .focusedBorder!
                                                    .borderSide
                                                    .color),
                                          ),
                                        ),
                                        textCapitalization:
                                            TextCapitalization.sentences,
                                      ),
                                  ],
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    Container(
                      margin: EdgeInsets.only(top: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Container(
                            width: 64,
                            child: Center(
                              child: Icon(
                                MdiIcons.phoneOutline,
                                color: themeData.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Container(
                              margin: EdgeInsets.only(left: 16),
                              child: Column(
                                children: [
                                  if (lad == 2)
                                    Theme(
                                      data: Theme.of(context).copyWith(
                                        canvasColor: Colors.white,
                                        textTheme: Theme.of(context)
                                            .textTheme
                                            .copyWith(
                                              bodyMedium: TextStyle(
                                                  color: Colors.black),
                                            ),
                                      ),
                                      child: InternationalPhoneNumberInput(
                                        onInputChanged: (PhoneNumber number) {
                                          setState(() => _phoneNumber = number);
                                          // Extract phone number and country code
                                          _fullNumber = number
                                              .phoneNumber!; // e.g., "+1234567890"
                                          _countryCode =
                                              number.dialCode!; // e.g., "+1"
                                          _isoCode =
                                              number.isoCode!; // e.g., "US"
                                          _formattedNumber = number
                                              .parseNumber()!; // e.g., "(123) 456-7890"

                                          widget.onPhoneNumberChanged
                                              ?.call(number);
                                        },
                                        selectorConfig: SelectorConfig(
                                          selectorType:
                                              PhoneInputSelectorType.DROPDOWN,
                                          leadingPadding: 16,
                                          setSelectorButtonAsPrefixIcon: true,
                                        ),
                                        initialValue: _phoneNumber,
                                        textFieldController: _controller,
                                        formatInput: true,
                                        keyboardType: TextInputType.phone,
                                        inputDecoration: InputDecoration(
                                            labelText: widget.labelText ??
                                                'Phone Number',
                                            hintText: widget.hintText ??
                                                'Enter your phone number',
                                            border: OutlineInputBorder(),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 14),
                                            filled: true,
                                            fillColor: Colors.white),
                                        validator: widget.validator,
                                      ),
                                    ),
                                  if (lad < 2)
                                    TextFormField(
                                      controller: mobile,
                                      keyboardType: TextInputType.number,
                                      validator: (value) {
                                        if (value!.length < 1) {
                                          return AppLocalizations.of(context)
                                              .translate(
                                                  'please_enter_your_number');
                                        } else {
                                          return null;
                                        }
                                      },
                                      style: themeData.textTheme.titleSmall!
                                          .merge(TextStyle(
                                              color: themeData
                                                  .colorScheme.onSurface)),
                                      decoration: InputDecoration(
                                        hintStyle: themeData
                                            .textTheme.titleSmall!
                                            .merge(TextStyle(
                                                color: themeData
                                                    .colorScheme.onSurface)),
                                        hintText: AppLocalizations.of(context)
                                            .translate('phone'),
                                        border: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                              color: themeData
                                                  .inputDecorationTheme
                                                  .border!
                                                  .borderSide
                                                  .color),
                                        ),
                                        enabledBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                              color: themeData
                                                  .inputDecorationTheme
                                                  .enabledBorder!
                                                  .borderSide
                                                  .color),
                                        ),
                                        focusedBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                              color: themeData
                                                  .inputDecorationTheme
                                                  .focusedBorder!
                                                  .borderSide
                                                  .color),
                                        ),
                                      ),
                                      textCapitalization:
                                          TextCapitalization.sentences,
                                    ),
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Container(
                            width: 64,
                            child: Center(
                              child: Icon(
                                MdiIcons.homeCityOutline,
                                color: themeData.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Container(
                              margin: EdgeInsets.only(left: 16),
                              child: Column(
                                children: <Widget>[
                                  if (lad == 2)
                                    TextFormField(
                                      controller: addressLine1,
                                      onTap: _openMapScreen,
                                      style: themeData.textTheme.titleSmall!
                                          .merge(TextStyle(
                                              color: themeData
                                                  .colorScheme.onSurface)),
                                      decoration: InputDecoration(
                                        hintStyle: themeData
                                            .textTheme.titleSmall!
                                            .merge(TextStyle(
                                                color: themeData
                                                    .colorScheme.onSurface)),
                                        hintText: AppLocalizations.of(context)
                                                .translate('address') +
                                            '*',
                                        border: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                              color: themeData
                                                  .inputDecorationTheme
                                                  .border!
                                                  .borderSide
                                                  .color),
                                        ),
                                        enabledBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                              color: themeData
                                                  .inputDecorationTheme
                                                  .enabledBorder!
                                                  .borderSide
                                                  .color),
                                        ),
                                        focusedBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                              color: themeData
                                                  .inputDecorationTheme
                                                  .focusedBorder!
                                                  .borderSide
                                                  .color),
                                        ),
                                      ),
                                      textCapitalization:
                                          TextCapitalization.sentences,
                                      validator: (value) {
                                        if (value!.length < 1) {
                                          return AppLocalizations.of(context)
                                              .translate(
                                                  'please_set_a_location');
                                        } else {
                                          return null;
                                        }
                                      },
                                    ),

                                  // isImage!= null ? Image.file(
                                  //         File(isImage!),
                                  //         fit: BoxFit.cover,
                                  //         // errorBuilder: (context, error, stackTrace) {
                                  //         //   return Center(child: Text('Image not found'));
                                  //         // },
                                  //       ): Center(child: Text('Image not found')),
                                  if (lad != 2)
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: <Widget>[
                                        Container(
                                          width: MySize.screenWidth! * 0.35,
                                          child: TextFormField(
                                            controller: city,
                                            style: themeData
                                                .textTheme.titleSmall!
                                                .merge(TextStyle(
                                                    color: themeData.colorScheme
                                                        .onSurface)),
                                            decoration: InputDecoration(
                                              hintStyle: themeData
                                                  .textTheme.titleSmall!
                                                  .merge(TextStyle(
                                                      color: themeData
                                                          .colorScheme
                                                          .onSurface)),
                                              hintText:
                                                  AppLocalizations.of(context)
                                                      .translate('city'),
                                              border: UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: themeData
                                                        .inputDecorationTheme
                                                        .border!
                                                        .borderSide
                                                        .color),
                                              ),
                                              enabledBorder:
                                                  UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: themeData
                                                        .inputDecorationTheme
                                                        .enabledBorder!
                                                        .borderSide
                                                        .color),
                                              ),
                                              focusedBorder:
                                                  UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: themeData
                                                        .inputDecorationTheme
                                                        .focusedBorder!
                                                        .borderSide
                                                        .color),
                                              ),
                                            ),
                                            textCapitalization:
                                                TextCapitalization.sentences,
                                          ),
                                        ),
                                        Container(
                                          width: MySize.screenWidth! * 0.35,
                                          child: TextFormField(
                                            controller: state,
                                            style: themeData
                                                .textTheme.titleSmall!
                                                .merge(TextStyle(
                                                    color: themeData.colorScheme
                                                        .onSurface)),
                                            decoration: InputDecoration(
                                              hintStyle: themeData
                                                  .textTheme.titleSmall!
                                                  .merge(TextStyle(
                                                      color: themeData
                                                          .colorScheme
                                                          .onSurface)),
                                              hintText:
                                                  AppLocalizations.of(context)
                                                      .translate('state'),
                                              border: UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: themeData
                                                        .inputDecorationTheme
                                                        .border!
                                                        .borderSide
                                                        .color),
                                              ),
                                              enabledBorder:
                                                  UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: themeData
                                                        .inputDecorationTheme
                                                        .enabledBorder!
                                                        .borderSide
                                                        .color),
                                              ),
                                              focusedBorder:
                                                  UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: themeData
                                                        .inputDecorationTheme
                                                        .focusedBorder!
                                                        .borderSide
                                                        .color),
                                              ),
                                            ),
                                            textCapitalization:
                                                TextCapitalization.sentences,
                                          ),
                                        )
                                      ],
                                    ),
                                  if (lad != 2)
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: <Widget>[
                                        Container(
                                          width: MySize.screenWidth! * 0.35,
                                          child: TextFormField(
                                            controller: country,
                                            style: themeData
                                                .textTheme.titleSmall!
                                                .merge(TextStyle(
                                                    color: themeData.colorScheme
                                                        .onSurface)),
                                            decoration: InputDecoration(
                                              hintStyle: themeData
                                                  .textTheme.titleSmall!
                                                  .merge(TextStyle(
                                                      color: themeData
                                                          .colorScheme
                                                          .onSurface)),
                                              hintText:
                                                  AppLocalizations.of(context)
                                                      .translate('country'),
                                              border: UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: themeData
                                                        .inputDecorationTheme
                                                        .border!
                                                        .borderSide
                                                        .color),
                                              ),
                                              enabledBorder:
                                                  UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: themeData
                                                        .inputDecorationTheme
                                                        .enabledBorder!
                                                        .borderSide
                                                        .color),
                                              ),
                                              focusedBorder:
                                                  UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: themeData
                                                        .inputDecorationTheme
                                                        .focusedBorder!
                                                        .borderSide
                                                        .color),
                                              ),
                                            ),
                                            textCapitalization:
                                                TextCapitalization.sentences,
                                          ),
                                        ),
                                        Container(
                                          width: MySize.screenWidth! * 0.35,
                                          child: TextFormField(
                                            controller: zip,
                                            keyboardType: TextInputType.number,
                                            style: themeData
                                                .textTheme.titleSmall!
                                                .merge(TextStyle(
                                                    color: themeData.colorScheme
                                                        .onSurface)),
                                            decoration: InputDecoration(
                                              hintStyle: themeData
                                                  .textTheme.titleSmall!
                                                  .merge(TextStyle(
                                                      color: themeData
                                                          .colorScheme
                                                          .onSurface)),
                                              hintText:
                                                  AppLocalizations.of(context)
                                                      .translate('zip_code'),
                                              border: UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: themeData
                                                        .inputDecorationTheme
                                                        .border!
                                                        .borderSide
                                                        .color),
                                              ),
                                              enabledBorder:
                                                  UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: themeData
                                                        .inputDecorationTheme
                                                        .enabledBorder!
                                                        .borderSide
                                                        .color),
                                              ),
                                              focusedBorder:
                                                  UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: themeData
                                                        .inputDecorationTheme
                                                        .focusedBorder!
                                                        .borderSide
                                                        .color),
                                              ),
                                            ),
                                            textCapitalization:
                                                TextCapitalization.sentences,
                                          ),
                                        )
                                      ],
                                    ),
                                  //     if(lad == 2)
                                  // Row(
                                  //   mainAxisAlignment:
                                  //       MainAxisAlignment.spaceBetween,
                                  //   children: <Widget>[
                                  //     Container(
                                  //       width: MySize.screenWidth! * 0.35,
                                  //       child: TextFormField(
                                  //         controller: field_area,
                                  //         keyboardType: TextInputType.number,
                                  //         style: themeData.textTheme.titleSmall!
                                  //             .merge(TextStyle(
                                  //                 color: themeData.colorScheme
                                  //                     .onSurface)),
                                  //         decoration: InputDecoration(
                                  //           hintStyle: themeData
                                  //               .textTheme.titleSmall!
                                  //               .merge(TextStyle(
                                  //                   color: themeData.colorScheme
                                  //                       .onSurface)),
                                  //           hintText:
                                  //               AppLocalizations.of(context)
                                  //                   .translate('field_size')+'*',
                                  //           border: UnderlineInputBorder(
                                  //             borderSide: BorderSide(
                                  //                 color: themeData
                                  //                     .inputDecorationTheme
                                  //                     .border!
                                  //                     .borderSide
                                  //                     .color),
                                  //           ),
                                  //           enabledBorder: UnderlineInputBorder(
                                  //             borderSide: BorderSide(
                                  //                 color: themeData
                                  //                     .inputDecorationTheme
                                  //                     .enabledBorder!
                                  //                     .borderSide
                                  //                     .color),
                                  //           ),
                                  //           focusedBorder: UnderlineInputBorder(
                                  //             borderSide: BorderSide(
                                  //                 color: themeData
                                  //                     .inputDecorationTheme
                                  //                     .focusedBorder!
                                  //                     .borderSide
                                  //                     .color),
                                  //           ),
                                  //         ),
                                  //         textCapitalization:
                                  //             TextCapitalization.sentences,
                                  //       ),
                                  //     ),
                                  //     if(lad == 2)
                                  //     Container(
                                  //       width: MySize.screenWidth! * 0.35,
                                  //       child: DropdownButtonFormField<String>(
                                  //     value: _selectedGender,
                                  //     dropdownColor: Colors.white,
                                  //     decoration: InputDecoration(
                                  //       hintText: AppLocalizations.of(context).translate('gender')+'*',
                                  //       border: OutlineInputBorder(),
                                  //     ),
                                  //     items: ['Acre', 'Hactre'].map((gender) {
                                  //       return DropdownMenuItem(
                                  //         value: gender,
                                  //         child: Text(gender,
                                  //           style: AppTheme.getTextStyle(
                                  //               themeData.textTheme.bodyLarge,
                                  //               color: themeData.colorScheme
                                  //                   .onSurface))
                                  //       );
                                  //     }).toList(),
                                  //     onChanged: (value) {
                                  //       setState(() {
                                  //         _selectedGender = value;
                                  //       });
                                  //     },
                                  //     validator: (value) => value == null ? 'Please select size unit' : null,
                                  //   ),
                                  //     )
                                  //   ],
                                  // ),
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    if (lad == 2)
                      // 🖼 Display image

                      ValueListenableBuilder<String>(
                        valueListenable: imagePathNotifier,
                        builder: (context, path, child) {
                          if (path.isEmpty || !File(path).existsSync()) {
                            return Container(
                              height: 20,
                              alignment: Alignment.center,
                              child: Text("Image not found"),
                            );
                          }

                          return Container(
                            height: 200,
                            width: 200,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.blue),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(File(path), fit: BoxFit.cover),
                            ),
                          );
                        },
                      ),
                    if (lad == 2)
                      Container(
                        margin: EdgeInsets.only(top: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            Container(
                              width: 64,
                              child: Center(
                                child: Icon(
                                  MdiIcons.homeCityOutline,
                                  color: themeData.colorScheme.onSurface,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Container(
                                margin: EdgeInsets.only(left: 16),
                                child: Column(
                                  children: <Widget>[
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: <Widget>[
                                        if (lad == 2)
                                          Container(
                                            width: MySize.screenWidth! * 0.65,
                                            child: TextFormField(
                                              controller: field_area,
                                              style: themeData
                                                  .textTheme.titleSmall!
                                                  .merge(TextStyle(
                                                      color: themeData
                                                          .colorScheme
                                                          .onSurface)),
                                              decoration: InputDecoration(
                                                hintStyle: themeData
                                                    .textTheme.titleSmall!
                                                    .merge(TextStyle(
                                                        color: themeData
                                                            .colorScheme
                                                            .onSurface)),
                                                hintText:
                                                    AppLocalizations.of(context)
                                                            .translate(
                                                                'field_size') +
                                                        '*',
                                                border: UnderlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color: themeData
                                                          .inputDecorationTheme
                                                          .border!
                                                          .borderSide
                                                          .color),
                                                ),
                                                enabledBorder:
                                                    UnderlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color: themeData
                                                          .inputDecorationTheme
                                                          .enabledBorder!
                                                          .borderSide
                                                          .color),
                                                ),
                                                focusedBorder:
                                                    UnderlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color: themeData
                                                          .inputDecorationTheme
                                                          .focusedBorder!
                                                          .borderSide
                                                          .color),
                                                ),
                                              ),
                                              textCapitalization:
                                                  TextCapitalization.sentences,
                                              validator: (value) {
                                                if (value!.length < 1) {
                                                  return AppLocalizations.of(
                                                          context)
                                                      .translate('field_size');
                                                } else {
                                                  return null;
                                                }
                                              },
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    Container(
                      margin: EdgeInsets.only(top: 16),
                      child: TextButton(
                        style: TextButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4)),
                          padding:
                              EdgeInsets.symmetric(vertical: 8, horizontal: 48),
                          backgroundColor: themeData.colorScheme.primary,
                        ),
                        onPressed: () async {
                          if (await Helper().checkConnectivity()) {
                            if (_formKey.currentState!.validate() &&
                                !isLoading) {
                              if (lad == 2) {
                                setState(() {
                                  isLoading = true;
                                });
                                Map newCustomer = {
                                  'type': 'farmer',
                                  'prefix': prefix.text,
                                  'first_name': firstName.text,
                                  'middle_name': middleName.text,
                                  'last_name': lastName.text,
                                  'mobile': _fullNumber,
                                  'longitude': addressLine1.text,
                                  'latitude': longitude,
                                  'city': cty,
                                  'state': stat,
                                  'country': countrytext,
                                  'zip_code': _countryCode,
                                  'field_area': fieldarea,
                                  'size_unit': "Acres",
                                  'name': farm_name.text,
                                  'gender': _selectedGender,
                                  'national_id': national_id.text,
                                  'date_of_birth': dob.text,
                                  'email': email.text,
                                  'image': base54Image,
                                  'imageName': imagePath,
                                };
                                await CustomerApi()
                                    .addFarmer(newCustomer)
                                    .then((value) {
                                  if (value['data'] != null) {
                                    String? errorCode =
                                        value['data']?['error_code'];
                                    String message = value['data']?['message'];
                                    //print(errorCode);
                                    if (errorCode == 400.toString()) {
                                      setState(() {
                                        isLoading = false;
                                      });

                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(message),
                                        ),
                                      );
                                    } else {
                                      Navigator.pop(context);
                                      _formKey.currentState!.reset();
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text('successfully'),
                                        ),
                                      );
                                    }
                                    // Contact()
                                    //     .insertContact(
                                    //         Contact().contactModel(value['data']))
                                    //     .then((value) {
                                    //   Navigator.pop(context);
                                    //   _formKey.currentState!.reset();
                                    // });
                                  }
                                });
                              } else {
                                Map newCustomer = {
                                  'type': 'customer',
                                  'prefix': prefix.text,
                                  'first_name': firstName.text,
                                  'middle_name': middleName.text,
                                  'last_name': lastName.text,
                                  'mobile': mobile.text,
                                  'address_line_1': addressLine1.text,
                                  'address_line_2': addressLine2.text,
                                  'city': city.text,
                                  'state': state.text,
                                  'country': country.text,
                                  'zip_code': zip.text
                                };
                                await CustomerApi()
                                    .add(newCustomer)
                                    .then((value) {
                                  if (value['data'] != null) {
                                    Contact()
                                        .insertContact(Contact()
                                            .contactModel(value['data']))
                                        .then((value) {
                                      Navigator.pop(context);
                                      _formKey.currentState!.reset();
                                    });
                                  }
                                });
                              }
                            }
                          } else {
                            Fluttertoast.showToast(
                                msg: AppLocalizations.of(context)
                                    .translate('check_connectivity'));
                            setState(() {
                              isLoading = false;
                            });
                          }
                        },
                        child: isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                                // backgroundColor: Colors.green,
                              )
                            : Text(
                                AppLocalizations.of(context)
                                    .translate('add_to_contact')
                                    .toUpperCase(),
                                style: AppTheme.getTextStyle(
                                    themeData.textTheme.bodyLarge,
                                    color: themeData.colorScheme.onPrimary,
                                    letterSpacing: 0.3)),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  //show add customer alert box
  Widget editFarmer(lad) {
    int id = lad['id'];
    // prefix.text = lad;
    firstName.text = lad['first_name'] ?? '';
    //middleName.text = lad['middle_name'];
    lastName.text = lad['last_name'] ?? '';
    _fullNumber = lad['mobile'] ?? '';
    addressLine1.text = lad['district'] ?? '';
    // addressLine1.text = lad.isEmpty['first_name'];
    // city.text = lad['city'] ?? '';
    // state.text = lad['state'] ?? '';
    // country.text = lad['country'] ?? '';
    // //zip.text = lad['zip'];
    field_area.text = lad['land_details'] + ' Acres' ?? '';
    // size_unit.text = lad['size_unit'] ?? '';
    // //farm_name.text = lad['first_name'];
    _selectedGender = lad['gender'] ?? '';
    national_id.text = lad['national_id'] ?? '';
    dob.text = lad['date_of_birth'];
    email.text = lad['email'] ?? '';

    return Scaffold(
      appBar: new AppBar(
        title: Text(
          AppLocalizations.of(context).translate('edit_follow_up'),
        ),
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        padding: EdgeInsets.only(top: 8, bottom: 8, left: 16, right: 16),
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Container(
                          width: 64,
                          child: Center(
                            child: Icon(
                              MdiIcons.accountChildCircle,
                              color: themeData.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Container(
                            margin: EdgeInsets.only(left: 16),
                            child: Column(
                              children: <Widget>[
                                Row(
                                  children: <Widget>[
                                    Container(
                                      width: 50,
                                      child: TextFormField(
                                        controller: prefix,
                                        style: themeData.textTheme.titleSmall!
                                            .merge(TextStyle(
                                                color: themeData
                                                    .colorScheme.onSurface)),
                                        decoration: InputDecoration(
                                          hintStyle: themeData
                                              .textTheme.titleSmall!
                                              .merge(TextStyle(
                                                  color: themeData
                                                      .colorScheme.onSurface)),
                                          hintText: AppLocalizations.of(context)
                                              .translate('prefix'),
                                          border: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: themeData
                                                    .inputDecorationTheme
                                                    .border!
                                                    .borderSide
                                                    .color),
                                          ),
                                          enabledBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: themeData
                                                    .inputDecorationTheme
                                                    .enabledBorder!
                                                    .borderSide
                                                    .color),
                                          ),
                                          focusedBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: themeData
                                                    .inputDecorationTheme
                                                    .focusedBorder!
                                                    .borderSide
                                                    .color),
                                          ),
                                        ),
                                        textCapitalization:
                                            TextCapitalization.sentences,
                                      ),
                                    ),
                                    Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 4)),
                                    Expanded(
                                      child: TextFormField(
                                        controller: firstName,
                                        validator: (value) {
                                          if (value!.length < 1) {
                                            return AppLocalizations.of(context)
                                                .translate(
                                                    'please_enter_your_name');
                                          } else {
                                            return null;
                                          }
                                        },
                                        style: themeData.textTheme.titleSmall!
                                            .merge(TextStyle(
                                                color: themeData
                                                    .colorScheme.onSurface)),
                                        decoration: InputDecoration(
                                          hintStyle: themeData
                                              .textTheme.titleSmall!
                                              .merge(TextStyle(
                                                  color: themeData
                                                      .colorScheme.onSurface)),
                                          hintText: AppLocalizations.of(context)
                                              .translate('first_name'),
                                          border: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: themeData
                                                    .inputDecorationTheme
                                                    .border!
                                                    .borderSide
                                                    .color),
                                          ),
                                          enabledBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: themeData
                                                    .inputDecorationTheme
                                                    .enabledBorder!
                                                    .borderSide
                                                    .color),
                                          ),
                                          focusedBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: themeData
                                                    .inputDecorationTheme
                                                    .focusedBorder!
                                                    .borderSide
                                                    .color),
                                          ),
                                        ),
                                        textCapitalization:
                                            TextCapitalization.sentences,
                                      ),
                                    )
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    Expanded(
                                      // width: MySize.screenWidth! * 0.35,
                                      child: TextFormField(
                                        controller: middleName,
                                        style: themeData.textTheme.titleSmall!
                                            .merge(TextStyle(
                                                color: themeData
                                                    .colorScheme.onSurface)),
                                        decoration: InputDecoration(
                                          hintStyle: themeData
                                              .textTheme.titleSmall!
                                              .merge(TextStyle(
                                                  color: themeData
                                                      .colorScheme.onSurface)),
                                          hintText: AppLocalizations.of(context)
                                              .translate('middle_name'),
                                          border: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: themeData
                                                    .inputDecorationTheme
                                                    .border!
                                                    .borderSide
                                                    .color),
                                          ),
                                          enabledBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: themeData
                                                    .inputDecorationTheme
                                                    .enabledBorder!
                                                    .borderSide
                                                    .color),
                                          ),
                                          focusedBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: themeData
                                                    .inputDecorationTheme
                                                    .focusedBorder!
                                                    .borderSide
                                                    .color),
                                          ),
                                        ),
                                        textCapitalization:
                                            TextCapitalization.sentences,
                                      ),
                                    ),
                                    Expanded(
                                      // width: MySize.screenWidth! * 0.35,
                                      child: TextFormField(
                                        controller: lastName,
                                        style: themeData.textTheme.titleSmall!
                                            .merge(TextStyle(
                                                color: themeData
                                                    .colorScheme.onSurface)),
                                        decoration: InputDecoration(
                                          hintStyle: themeData
                                              .textTheme.titleSmall!
                                              .merge(TextStyle(
                                                  color: themeData
                                                      .colorScheme.onSurface)),
                                          hintText: AppLocalizations.of(context)
                                              .translate('last_name'),
                                          border: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: themeData
                                                    .inputDecorationTheme
                                                    .border!
                                                    .borderSide
                                                    .color),
                                          ),
                                          enabledBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: themeData
                                                    .inputDecorationTheme
                                                    .enabledBorder!
                                                    .borderSide
                                                    .color),
                                          ),
                                          focusedBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: themeData
                                                    .inputDecorationTheme
                                                    .focusedBorder!
                                                    .borderSide
                                                    .color),
                                          ),
                                        ),
                                        textCapitalization:
                                            TextCapitalization.sentences,
                                      ),
                                    )
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    //if(lad == 2)
                                    Container(
                                      width: MySize.screenWidth! * 0.35,
                                      child: TextFormField(
                                        controller: farm_name,
                                        style: themeData.textTheme.titleSmall!
                                            .merge(TextStyle(
                                                color: themeData
                                                    .colorScheme.onSurface)),
                                        decoration: InputDecoration(
                                          hintStyle: themeData
                                              .textTheme.titleSmall!
                                              .merge(TextStyle(
                                                  color: themeData
                                                      .colorScheme.onSurface)),
                                          hintText: AppLocalizations.of(context)
                                              .translate('farm name'),
                                          border: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: themeData
                                                    .inputDecorationTheme
                                                    .border!
                                                    .borderSide
                                                    .color),
                                          ),
                                          enabledBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: themeData
                                                    .inputDecorationTheme
                                                    .enabledBorder!
                                                    .borderSide
                                                    .color),
                                          ),
                                          focusedBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: themeData
                                                    .inputDecorationTheme
                                                    .focusedBorder!
                                                    .borderSide
                                                    .color),
                                          ),
                                        ),
                                        textCapitalization:
                                            TextCapitalization.sentences,
                                      ),
                                    ),
                                    //if(lad == 2)
                                    Container(
                                      width: MySize.screenWidth! * 0.35,
                                      child: TextFormField(
                                        controller: dob,
                                        style: themeData.textTheme.titleSmall!
                                            .merge(TextStyle(
                                                color: themeData
                                                    .colorScheme.onSurface)),
                                        decoration: InputDecoration(
                                          hintStyle: themeData
                                              .textTheme.titleSmall!
                                              .merge(TextStyle(
                                                  color: themeData
                                                      .colorScheme.onSurface)),
                                          hintText: AppLocalizations.of(context)
                                              .translate('date'),
                                          border: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: themeData
                                                    .inputDecorationTheme
                                                    .border!
                                                    .borderSide
                                                    .color),
                                          ),
                                          enabledBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: themeData
                                                    .inputDecorationTheme
                                                    .enabledBorder!
                                                    .borderSide
                                                    .color),
                                          ),
                                          focusedBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: themeData
                                                    .inputDecorationTheme
                                                    .focusedBorder!
                                                    .borderSide
                                                    .color),
                                          ),
                                        ),
                                        textCapitalization:
                                            TextCapitalization.sentences,
                                        onTap: () async {
                                          DateTime? pickedDate =
                                              await showDatePicker(
                                            context: context,
                                            initialDate: DateTime.now(),
                                            firstDate: DateTime(1900),
                                            lastDate: DateTime(2100),
                                          );

                                          if (pickedDate != null) {
                                            String formattedDate =
                                                "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                                            setState(() {
                                              dob.text = formattedDate;
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    //if(lad == 2)
                                    Container(
                                      width: MySize.screenWidth! * 0.35,
                                      child: TextFormField(
                                        controller: national_id,
                                        style: themeData.textTheme.titleSmall!
                                            .merge(TextStyle(
                                                color: themeData
                                                    .colorScheme.onSurface)),
                                        decoration: InputDecoration(
                                          hintStyle: themeData
                                              .textTheme.titleSmall!
                                              .merge(TextStyle(
                                                  color: themeData
                                                      .colorScheme.onSurface)),
                                          hintText: AppLocalizations.of(context)
                                              .translate('national_ID'),
                                          border: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: themeData
                                                    .inputDecorationTheme
                                                    .border!
                                                    .borderSide
                                                    .color),
                                          ),
                                          enabledBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: themeData
                                                    .inputDecorationTheme
                                                    .enabledBorder!
                                                    .borderSide
                                                    .color),
                                          ),
                                          focusedBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: themeData
                                                    .inputDecorationTheme
                                                    .focusedBorder!
                                                    .borderSide
                                                    .color),
                                          ),
                                        ),
                                        textCapitalization:
                                            TextCapitalization.sentences,
                                      ),
                                    ),
                                    // if(lad == 2)
                                    Container(
                                      width: MySize.screenWidth! * 0.35,
                                      child: DropdownButtonFormField<String>(
                                        value: _selectedGender,
                                        dropdownColor: Colors.white,
                                        decoration: InputDecoration(
                                          hintText: AppLocalizations.of(context)
                                              .translate('gender'),
                                          border: OutlineInputBorder(),
                                        ),
                                        items: ['Male', 'Female'].map((gender) {
                                          return DropdownMenuItem(
                                              value: gender,
                                              child: Text(gender,
                                                  style: AppTheme.getTextStyle(
                                                      themeData
                                                          .textTheme.bodyLarge,
                                                      color: themeData
                                                          .colorScheme
                                                          .onSurface)));
                                        }).toList(),
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedGender = value;
                                          });
                                        },
                                        validator: (value) => value == null
                                            ? 'Please select gender'
                                            : null,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: <Widget>[
                                    //if(lad == 2)
                                    Container(
                                      width: MySize.screenWidth! * 0.65,
                                      child: TextFormField(
                                        controller: email,
                                        style: themeData.textTheme.titleSmall!
                                            .merge(TextStyle(
                                                color: themeData
                                                    .colorScheme.onSurface)),
                                        decoration: InputDecoration(
                                          hintStyle: themeData
                                              .textTheme.titleSmall!
                                              .merge(TextStyle(
                                                  color: themeData
                                                      .colorScheme.onSurface)),
                                          hintText: AppLocalizations.of(context)
                                              .translate('email'),
                                          border: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: themeData
                                                    .inputDecorationTheme
                                                    .border!
                                                    .borderSide
                                                    .color),
                                          ),
                                          enabledBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: themeData
                                                    .inputDecorationTheme
                                                    .enabledBorder!
                                                    .borderSide
                                                    .color),
                                          ),
                                          focusedBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: themeData
                                                    .inputDecorationTheme
                                                    .focusedBorder!
                                                    .borderSide
                                                    .color),
                                          ),
                                        ),
                                        textCapitalization:
                                            TextCapitalization.sentences,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Container(
                            width: 64,
                            child: Center(
                              child: Icon(
                                MdiIcons.phoneOutline,
                                color: themeData.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Container(
                              margin: EdgeInsets.only(left: 16),
                              child: Column(
                                children: <Widget>[
                                  //if(lad == 2)
                                  Theme(
                                    data: Theme.of(context).copyWith(
                                      canvasColor: Colors.white,
                                      textTheme: Theme.of(context)
                                          .textTheme
                                          .copyWith(
                                            bodyMedium:
                                                TextStyle(color: Colors.black),
                                          ),
                                    ),
                                    child: InternationalPhoneNumberInput(
                                      onInputChanged: (PhoneNumber number) {
                                        setState(() => _phoneNumber = number);
                                        // Extract phone number and country code
                                        _fullNumber = number
                                            .phoneNumber!; // e.g., "+1234567890"
                                        _countryCode =
                                            number.dialCode!; // e.g., "+1"
                                        _isoCode =
                                            number.isoCode!; // e.g., "US"
                                        _formattedNumber = number
                                            .parseNumber()!; // e.g., "(123) 456-7890"

                                        widget.onPhoneNumberChanged
                                            ?.call(number);
                                      },
                                      selectorConfig: SelectorConfig(
                                        selectorType:
                                            PhoneInputSelectorType.DROPDOWN,
                                        leadingPadding: 16,
                                        setSelectorButtonAsPrefixIcon: true,
                                      ),
                                      initialValue: _phoneNumber,
                                      textFieldController: _controller,
                                      formatInput: true,
                                      keyboardType: TextInputType.phone,
                                      inputDecoration: InputDecoration(
                                          labelText: widget.labelText ??
                                              'Phone Number',
                                          hintText: widget.hintText ??
                                              'Enter your phone number',
                                          border: OutlineInputBorder(),
                                          contentPadding: EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 14),
                                          filled: true,
                                          fillColor: Colors.white),
                                      validator: widget.validator,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Container(
                            width: 64,
                            child: Center(
                              child: Icon(
                                MdiIcons.homeCityOutline,
                                color: themeData.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Container(
                              margin: EdgeInsets.only(left: 16),
                              child: Column(
                                children: <Widget>[
                                  //if(lad == 2)
                                  TextFormField(
                                    controller: addressLine1,
                                    onTap: _openMapScreen,
                                    style: themeData.textTheme.titleSmall!
                                        .merge(TextStyle(
                                            color: themeData
                                                .colorScheme.onSurface)),
                                    decoration: InputDecoration(
                                      hintStyle: themeData.textTheme.titleSmall!
                                          .merge(TextStyle(
                                              color: themeData
                                                  .colorScheme.onSurface)),
                                      hintText: AppLocalizations.of(context)
                                          .translate('address'),
                                      border: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                            color: themeData
                                                .inputDecorationTheme
                                                .border!
                                                .borderSide
                                                .color),
                                      ),
                                      enabledBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                            color: themeData
                                                .inputDecorationTheme
                                                .enabledBorder!
                                                .borderSide
                                                .color),
                                      ),
                                      focusedBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                            color: themeData
                                                .inputDecorationTheme
                                                .focusedBorder!
                                                .borderSide
                                                .color),
                                      ),
                                    ),
                                    textCapitalization:
                                        TextCapitalization.sentences,
                                  ),
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    // 🖼 Display image

                    ValueListenableBuilder<String>(
                      valueListenable: imagePathNotifier,
                      builder: (context, path, child) {
                        if (path.isEmpty || !File(path).existsSync()) {
                          return Container(
                            height: 120,
                            alignment: Alignment.center,
                            child: // Text("Image not found"),
                                Image.network(
                                    Api().baseUrl +
                                            '/storage/' +
                                            lad['custom_field5'] ??
                                        '',
                                    width:
                                        MediaQuery.of(context).size.width * 0.8,
                                    fit: BoxFit.cover),
                          );
                        }

                        return Container(
                          height: 200,
                          width: 200,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.blue),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(File(path), fit: BoxFit.cover),
                          ),
                        );
                      },
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Container(
                            width: 64,
                            child: Center(
                              child: Icon(
                                MdiIcons.homeCityOutline,
                                color: themeData.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Container(
                              margin: EdgeInsets.only(left: 16),
                              child: Column(
                                children: <Widget>[
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      Expanded(
                                        // width: MySize.screenWidth! * 0.35,
                                        child: TextFormField(
                                          controller: city,
                                          textCapitalization:
                                              TextCapitalization.sentences,
                                          style: themeData.textTheme.titleSmall!
                                              .merge(
                                            TextStyle(
                                              color: themeData
                                                  .colorScheme.onSurface,
                                            ),
                                          ),
                                          decoration: InputDecoration(
                                            hintText: AppLocalizations.of(
                                                        context)
                                                    .translate('field_size') +
                                                '*',
                                            border: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                color: themeData
                                                    .inputDecorationTheme
                                                    .border!
                                                    .borderSide
                                                    .color,
                                              ),
                                            ),
                                            enabledBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                color: themeData
                                                    .inputDecorationTheme
                                                    .enabledBorder!
                                                    .borderSide
                                                    .color,
                                              ),
                                            ),
                                            focusedBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                color: themeData
                                                    .inputDecorationTheme
                                                    .focusedBorder!
                                                    .borderSide
                                                    .color,
                                              ),
                                            ),
                                          ),
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return AppLocalizations.of(
                                                      context)
                                                  .translate('field_size');
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                      Expanded(
                                        // width: MySize.screenWidth! * 0.35,
                                        child: TextFormField(
                                          controller: state,
                                          style: themeData.textTheme.titleSmall!
                                              .merge(TextStyle(
                                                  color: themeData
                                                      .colorScheme.onSurface)),
                                          decoration: InputDecoration(
                                            hintStyle: themeData
                                                .textTheme.titleSmall!
                                                .merge(TextStyle(
                                                    color: themeData.colorScheme
                                                        .onSurface)),
                                            hintText:
                                                AppLocalizations.of(context)
                                                    .translate('state'),
                                            border: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: themeData
                                                      .inputDecorationTheme
                                                      .border!
                                                      .borderSide
                                                      .color),
                                            ),
                                            enabledBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: themeData
                                                      .inputDecorationTheme
                                                      .enabledBorder!
                                                      .borderSide
                                                      .color),
                                            ),
                                            focusedBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: themeData
                                                      .inputDecorationTheme
                                                      .focusedBorder!
                                                      .borderSide
                                                      .color),
                                            ),
                                          ),
                                          textCapitalization:
                                              TextCapitalization.sentences,
                                        ),
                                      )
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      Expanded(
                                        // width: MySize.screenWidth! * 0.35,
                                        child: TextFormField(
                                          controller: country,
                                          style: themeData.textTheme.titleSmall!
                                              .merge(TextStyle(
                                                  color: themeData
                                                      .colorScheme.onSurface)),
                                          decoration: InputDecoration(
                                            hintStyle: themeData
                                                .textTheme.titleSmall!
                                                .merge(TextStyle(
                                                    color: themeData.colorScheme
                                                        .onSurface)),
                                            hintText:
                                                AppLocalizations.of(context)
                                                    .translate('country'),
                                            border: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: themeData
                                                      .inputDecorationTheme
                                                      .border!
                                                      .borderSide
                                                      .color),
                                            ),
                                            enabledBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: themeData
                                                      .inputDecorationTheme
                                                      .enabledBorder!
                                                      .borderSide
                                                      .color),
                                            ),
                                            focusedBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: themeData
                                                      .inputDecorationTheme
                                                      .focusedBorder!
                                                      .borderSide
                                                      .color),
                                            ),
                                          ),
                                          textCapitalization:
                                              TextCapitalization.sentences,
                                        ),
                                      ),
                                      Expanded(
                                        // width: MySize.screenWidth! * 0.25,
                                        child: TextFormField(
                                          controller: zip,
                                          keyboardType: TextInputType.number,
                                          style: themeData.textTheme.titleSmall!
                                              .merge(TextStyle(
                                                  color: themeData
                                                      .colorScheme.onSurface)),
                                          decoration: InputDecoration(
                                            hintStyle: themeData
                                                .textTheme.titleSmall!
                                                .merge(TextStyle(
                                                    color: themeData.colorScheme
                                                        .onSurface)),
                                            hintText:
                                                AppLocalizations.of(context)
                                                    .translate('zip_code'),
                                            border: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: themeData
                                                      .inputDecorationTheme
                                                      .border!
                                                      .borderSide
                                                      .color),
                                            ),
                                            enabledBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: themeData
                                                      .inputDecorationTheme
                                                      .enabledBorder!
                                                      .borderSide
                                                      .color),
                                            ),
                                            focusedBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: themeData
                                                      .inputDecorationTheme
                                                      .focusedBorder!
                                                      .borderSide
                                                      .color),
                                            ),
                                          ),
                                          textCapitalization:
                                              TextCapitalization.sentences,
                                        ),
                                      )
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 16),
                      child: TextButton(
                        style: TextButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4)),
                          padding:
                              EdgeInsets.symmetric(vertical: 8, horizontal: 48),
                          backgroundColor: themeData.colorScheme.primary,
                        ),
                        onPressed: () async {
                          if (await Helper().checkConnectivity()) {
                            if (_formKey.currentState!.validate() &&
                                !isLoading) {
                              //if(lad == 2){
                              setState(() {
                                isLoading = true;
                              });
                              Map newCustomer = {
                                'type': 'farmer',
                                'id': id,
                                'prefix': prefix.text,
                                'first_name': firstName.text,
                                'middle_name': middleName.text,
                                'last_name': lastName.text,
                                'mobile': _fullNumber ?? lad['mobile'],
                                'longitude': addressLine1.text,
                                'latitude': longitude,
                                'city': cty ?? lad['district'],
                                'state': stat ?? lad['state'],
                                'country': countrytext ?? lad['country'],
                                'zip_code': _countryCode ?? '+256',
                                'field_area': fieldarea ?? lad['land_details'],
                                'size_unit': 'Acres',
                                'name': farm_name.text,
                                'gender': _selectedGender,
                                'national_id': national_id.text,
                                'date_of_birth': dob.text,
                                'email': email.text,
                                'image': base54Image,
                                'imageName': imagePath,
                              };
                              await CustomerApi()
                                  .updateFarmer(newCustomer)
                                  .then((value) {
                                if (value['data'] != null) {
                                  //print(value['data']);
                                  Navigator.pop(context);
                                  _formKey.currentState!.reset();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('successfully'),
                                    ),
                                  );
                                  // Contact()
                                  //     .insertContact(
                                  //         Contact().contactModel(value['data']))
                                  //     .then((value) {
                                  //   Navigator.pop(context);
                                  //   _formKey.currentState!.reset();
                                  // });
                                }
                              });
                              //}
                            }
                          } else {
                            setState(() {
                              isLoading = false;
                            });
                            Fluttertoast.showToast(
                                msg: AppLocalizations.of(context)
                                    .translate('check_connectivity'));
                          }
                        },
                        child: isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : Text(
                                AppLocalizations.of(context)
                                    .translate('add_to_contact')
                                    .toUpperCase(),
                                style: AppTheme.getTextStyle(
                                    themeData.textTheme.bodyLarge,
                                    color: themeData.colorScheme.onPrimary,
                                    letterSpacing: 0.3)),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  //progress indicator
  Widget _buildProgressIndicator() {
    return new Padding(
      padding: const EdgeInsets.all(8.0),
      child: new Center(
        child: FutureBuilder<bool>(
            future: Helper().checkConnectivity(),
            builder: (context, AsyncSnapshot<bool> snapshot) {
              if (snapshot.data == false) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppLocalizations.of(context)
                          .translate('check_connectivity'),
                      style: AppTheme.getTextStyle(
                          themeData.textTheme.titleMedium,
                          fontWeight: 700,
                          letterSpacing: -0.2),
                    ),
                    Icon(
                      Icons.error_outline,
                      color: themeData.colorScheme.onSurface,
                    )
                  ],
                );
              } else {
                return CircularProgressIndicator();
              }
            }),
      ),
    );
  }

  List<LatLng> _selectedPolygon = [];
  String? village;
  String? cty;
  String? stat;
  String? countrytext;
  String? longitude;
  String? fieldarea;
  String imagePath = '';
  String base54Image = '';

  void _openMapScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            MapPolygonPage(), //        builder: (_) => PolygonMapScreen(initialPolygon: _selectedPolygon),
      ),
    );

    // if (result != null && result is List<LatLng>) {
    //   setState(() {
    //     _selectedPolygon = result;
    //     addressLine1.text =
    //         result.map((point) => '${point.latitude},${point.longitude}').join(' | ');
    //   });
    // }
    if (result != null) {
      imagePathNotifier.value = result.imagePath!;

      setState(() {
        // _selectedPolygon = result;
        addressLine1.text =
            " Country: ${result.country}, State: ${result.state}, Village: ${result.village}";
        field_area.text =
            "Area: ${result.areaM2.toStringAsFixed(2)} m² | ${result.areaAcres.toStringAsFixed(4)} Acres ,${result.areaHectares.toStringAsFixed(4)} Acres ";
        imagePath = "${result.imagePath}";
        longitude = "${result.points}";
        cty = "${result.village}";
        stat = " ${result.state}";
        countrytext = "${result.country}";
        fieldarea = "${result.areaAcres.toStringAsFixed(4)}";
        village = "${result.village}";
        base54Image = "${result.base54Image}";
      });
    }
  }

  String generateQRCodeData(String farmerCode, String secretKey) {
    // 1. Prepare payload
    final payload = {
      'farmer_code': farmerCode,
      'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'exp': DateTime.now().add(Duration(minutes: 5)).millisecondsSinceEpoch ~/
          1000,
    };

    final payloadJson = jsonEncode(payload);

    // 2. Prepare key (must be 32 bytes for AES-256)
    final key =
        encrypt.Key.fromUtf8(secretKey.padRight(32, ' ')); // ensure 32 bytes
    final ivBytes = _generateRandomBytes(16);
    final iv = encrypt.IV(ivBytes);

    // 3. Encrypt
    final encrypter =
        encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
    final encrypted = encrypter.encrypt(payloadJson, iv: iv);

    // 4. Combine IV + encrypted data
    final combined = Uint8List.fromList(ivBytes + encrypted.bytes);
    final base64Encoded = base64Encode(combined);

    // 5. Generate final QR code URL
    final qrCodeUrl = "$qrData${Uri.encodeComponent(base64Encoded)}";

    return qrCodeUrl;
  }

  // Helper: Generate random IV bytes
  Uint8List _generateRandomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
        List.generate(length, (_) => random.nextInt(256)));
  }

  Future<Uint8List> _generateQRCodePdf(String data) async {
    final pdf = pw.Document();

    final image = await QrPainter(
      data: data,
      version: QrVersions.auto,
      gapless: true,
    ).toImageData(200); // returns ByteData

    final imageUint8List = image!.buffer.asUint8List();

    final qrImage = pw.MemoryImage(imageUint8List);

    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Center(
            child: pw.Image(qrImage, width: 200, height: 200),
          );
        },
      ),
    );

    return pdf.save();
  }

  void _printQRCode(qrData) async {
    final pdfBytes = await _generateQRCodePdf(qrData);
    await Printing.layoutPdf(onLayout: (_) => pdfBytes);
  }

//   String _scanResult = 'Scan a barcode or QR code';
//   ScanResult? _lastResult;

//   Future<void> _scanBarcode() async {

//     try {
//       // Request camera permission
//       final status = await Permission.camera.request();
//       if (!status.isGranted) {
//         setState(() => _scanResult = 'Camera permission denied');print('Scanned2: ${_scanResult}');
//         return;
//       }

//       // Configure scan options
//       const options = ScanOptions(
//         strings: {
//           'cancel': 'Cancel',
//           'flash_on': 'Flash ON',
//           'flash_off': 'Flash OFF',
//         },
//         restrictFormat: [], // Empty array means all formats
//         useCamera: -1, // -1 for default camera
//         autoEnableFlash: false,
//       );

//       // Launch scanner
//       final result = await BarcodeScanner.scan(options: options);

//       setState(() {
//         _lastResult = result;
//         _scanResult = result.rawContent ?? 'No content';
//       });
//       if(_scanResult.isNotEmpty){
// //
//                                 await CustomerApi()
//                                   .qrlogin(_scanResult)
//                                   .then((value) {
//                                 if (value['data'] != null) {
//                                 print(value['data']);
//                                 // Navigator.pop(context);
//                                 //     _formKey.currentState!.reset();
//                                 //     ScaffoldMessenger.of(context).showSnackBar(
//                                 //       SnackBar(
//                                 //         content: Text('successfully'),
//                                 //       ),
//                                 //     );

//                                 }
//                               });
//                          //   }
// //
//       }
//     } on PlatformException catch (e) {
//       setState(() => _scanResult = 'Error: ${e.message}');
//       print('Platform error: ${e.message}');
//     print('Error code: ${e.code}');
//     print('Details: ${e.details}');
//     } catch (e) {
//       setState(() => _scanResult = 'Error: $e');
//       print('Other error: $e');
//     }
//   }
}
