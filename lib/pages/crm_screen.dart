import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:intl/intl.dart';
import 'package:mobile_pos/constants.dart';
import '../apis/api.dart';
import '../apis/contact.dart';
import '../apis/follow_up.dart';
import '../helpers/AppTheme.dart';
import '../helpers/SizeConfig.dart';
import '../helpers/otherHelpers.dart';
import '../locale/MyLocalizations.dart';
import '../models/contact_model.dart';
import '../models/system.dart';
import 'forms.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final _formKey = GlobalKey<FormState>();
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
      zip = new TextEditingController();


  List<bool> toggleValue = [true, false, false];
  int selectedToggleValue = 0;
  int? showCustomerDetails;
  List followUpList = [];

  List<String> followUpStatusList = [
        "All",
        "Scheduled",
        "Open",
        "Canceled",
        "Completed"
      ],
      followUpTypeList = ["All", "Call", "Sms", "Meeting", "Email"];

  String? followUpUrl =
      "${Api().baseUrl}${Api().apiUrl}/crm/follow-ups?per_page=10";
  String selectedFollowUpType = "All", selectedFollowUpStatus = "All";

  ScrollController followUpListController = ScrollController();
  bool isLoading = false, accessFollowUp = false;

  CustomAppTheme customAppTheme = AppTheme.getCustomAppTheme(themeType);

  bool
      // isLoading = false,
      useOrderBy = false,
      isFollowUpTab = false,
      orderByAsc = true,
      useSearchBy = false;
  int currentTabIndex = 0;
  static int themeType = 1;
  var searchController = new TextEditingController();

  List<Map> leadsList = [];
  ThemeData themeData = AppTheme.getThemeFromThemeMode(themeType);

  ScrollController leadsListController = ScrollController(),
      customerListController = ScrollController(),
      suppliersListController = ScrollController();

  String? fetchLeads = "${Api().baseUrl}${Api().apiUrl}/crm/leads?per_page=10";
  String orderByColumn = 'name', orderByDirection = 'asc';

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

  //Retrieve leads list from api
  setLeadsList() async {
    try{
      setState(() {
        isLoading = true;
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
    catch(e){

    }finally{
      setState(() {
        isLoading = false;
      });
    }

  }

  setAllList() async {
    fetchLeads = getUrl();
    leadsList = [];
    setLeadsList();
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
    getPermission();
    followUpListController.addListener(() {
      if (followUpListController.position.pixels ==
          followUpListController.position.maxScrollExtent) {
        getFollowUpList();
      }
    });
    Helper().syncCallLogs();
  }

  getFollowUpList() async {
    try{
      setState(() {
        isLoading = true;
      });
      final dio = new Dio();
      var token = await System().getToken();
      dio.options.headers['content-Type'] = 'application/json';
      dio.options.headers["Authorization"] = "Bearer $token";
      final response = await dio.get(followUpUrl!);
      List followUps = response.data['data'];
      Map links = response.data['links'];
      setState(() {
        followUps.forEach((element) {
          followUpList.add(element);
        });
      });
      isLoading = (links['next'] != null) ? true : false;
      followUpUrl = links['next'];

      setState(() {
        isLoading = false;
      });
    }
    catch(e){

    }finally{
      setState(() {
        isLoading = false;
      });
    }


  }

  //Fetch permission from database
  getPermission() async {
    if (await Helper().getPermission("crm.access_all_schedule") ||
        await Helper().getPermission("crm.access_own_schedule")) {
      accessFollowUp = true;
      onToggleFilter(selectedToggleValue);
    }
  }

  onToggleFilter(int index) {
    String? formattedDate;
    setState(() {
      followUpList = [];
    });
    if (index == 0) {
      formattedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    }

    if (index == 1) {
      formattedDate = DateFormat('yyyy-MM-dd')
          .format(DateTime.now().add(Duration(days: 1)));
    }
    followUpUrl = getFollowUpURL(
        endDate: formattedDate,
        startDate: formattedDate,
        followUpStatus: selectedFollowUpStatus.toLowerCase(),
        followUpType: selectedFollowUpType.toLowerCase());

    getFollowUpList();
  }

  getFollowUpURL(
      {String? perPage = '10',
      String? startDate,
      String? endDate,
      String? followUpType,
      String? followUpStatus}) {
    String url = "${Api().baseUrl}${Api().apiUrl}/crm/follow-ups?";

    Map<String, dynamic> params = {
      'order_by': 'start_datetime',
      'direction': 'desc'
    };
    if (perPage != null) {
      params['per_page'] = perPage;
    }

    if (startDate != null) {
      params['start_date'] = startDate;
    }

    if (endDate != null) {
      params['end_date'] = startDate;
    }

    if (followUpType != 'all') {
      params['follow_up_type'] = followUpType;
    }

    if (followUpStatus != 'all') {
      params['status'] = followUpStatus;
    }

    String queryString = Uri(queryParameters: params).query;
    url += queryString;
    return url;
  }

  @override
  Widget build(BuildContext context) {
    ThemeData themeData = AppTheme.getThemeFromThemeMode(1);
    return DefaultTabController(
      length: 2,
      initialIndex: 0,
      child: Scaffold(
        key: _scaffoldKey,
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.of(context).push(new MaterialPageRoute<Null>(
                builder: (BuildContext context) {
                  return newCustomer();
                },
                fullscreenDialog: true));
          },
          elevation: 2,
          child: Icon(MdiIcons.accountPlus),
        ),
        endDrawer: _filterDrawer(),
        appBar: AppBar(
          actions: [
            IconButton(
              icon: Icon(MdiIcons.filterVariant),
              onPressed: () {
                if(isFollowUpTab) {
                  _scaffoldKey.currentState!.openEndDrawer();
                }
              },
            )
          ],
          elevation: 0,
          title: Text("CRM",
              style: AppTheme.getTextStyle(themeData.textTheme.titleLarge,
                  fontWeight: 600)),
          bottom: TabBar(tabs: [
            Tab(
                icon: const Icon(MdiIcons.bookPlusMultipleOutline),
                child: Text(AppLocalizations.of(context).translate('leads'))),
            Tab(
              icon: const Icon(Icons.support_agent),
              child: Text(AppLocalizations.of(context).translate('follow_ups')),
            )
          ]),
        ),
        body: TabBarView(children: [leadTab(leadsList), followUpWidget()]),
      ),
    );
  }

  //lead widget
  Widget followUpWidget() {
    setState(() {
      isFollowUpTab = true;
    });
    return (accessFollowUp)
        ? followUps()
        : Center(
            child: Text(
              AppLocalizations.of(context).translate('unauthorised'),
            ),
          );
  }

  Widget followUps() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ToggleButtons(
                selectedColor: themeData.colorScheme.onPrimary,
                borderRadius: BorderRadius.circular(MySize.size4!),
                borderColor: themeData.colorScheme.primary,
                selectedBorderColor: themeData.colorScheme.primary,
                fillColor: themeData.colorScheme.primary,
                color: themeData.colorScheme.primary,
                textStyle: AppTheme.getTextStyle(themeData.textTheme.bodyLarge,
                    fontWeight: 600, color: themeData.colorScheme.onSurface),
                children: [
                  Padding(
                    padding: EdgeInsets.all(MySize.size10!),
                    child: Text(
                      AppLocalizations.of(context).translate('today'),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(MySize.size10!),
                    child: Text(
                      AppLocalizations.of(context).translate('tomorrow'),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(MySize.size10!),
                    child: Text(
                      AppLocalizations.of(context).translate('all'),
                    ),
                  ),
                ],
                onPressed: (int index) {
                  setState(() {
                    selectedToggleValue = index;
                    for (int i = 0; i < toggleValue.length; i++) {
                      toggleValue[i] = i == index;
                    }
                    onToggleFilter(index);
                  });
                },
                isSelected: toggleValue,
              ),
            ],
          ),
          Expanded(
            child: (isLoading)
                ? _buildProgressIndicator()
                : (followUpList.isNotEmpty)
                    ? ListView.builder(
                        controller: followUpListController,
                        padding: EdgeInsets.all(MySize.size16!),
                        shrinkWrap: true,
                        itemCount:
                            (followUpList.isNotEmpty) ? followUpList.length : 0,
                        itemBuilder: (context, index) {
                          if (index == followUpList.length) {
                            return (isLoading)
                                ? _buildProgressIndicator()
                                : Container();
                          } else {
                            return Container(
                                margin: EdgeInsets.only(bottom: MySize.size8!),
                                padding: EdgeInsets.all(MySize.size8!),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.all(
                                      Radius.circular(MySize.size8!)),
                                  color: customAppTheme.bgLayer1,
                                  border: Border.all(
                                      color: customAppTheme.bgLayer4,
                                      width: 1.2),
                                ),
                                child: Column(
                                  children: [
                                    contactBlockFollowup(followUpList[index]),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        GestureDetector(
                                          child: Icon(
                                            (showCustomerDetails == index)
                                                ? MdiIcons.chevronUp
                                                : MdiIcons.chevronDown,
                                            color:
                                                themeData.colorScheme.primary,
                                          ),
                                          onTap: () {
                                            setState(() {
                                              showCustomerDetails =
                                                  (showCustomerDetails == index)
                                                      ? null
                                                      : index;
                                            });
                                          },
                                        )
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Visibility(
                                          visible:
                                              (showCustomerDetails == index),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Visibility(
                                                visible: (followUpList[index]
                                                                ['customer']
                                                            ['name'] !=
                                                        null &&
                                                    followUpList[index]
                                                                    ['customer']
                                                                ['name']
                                                            .toString()
                                                            .trim() !=
                                                        ''),
                                                child: Text(
                                                  '${followUpList[index]['customer']['name']}',
                                                  style: AppTheme.getTextStyle(
                                                    themeData
                                                        .textTheme.bodyLarge,
                                                    fontWeight: 500,
                                                    color: themeData
                                                        .colorScheme.onSurface,
                                                  ),
                                                ),
                                              ),
                                              Visibility(
                                                visible: (followUpList[index]
                                                                ['customer'][
                                                            'supplier_business_name'] !=
                                                        null &&
                                                    followUpList[index]
                                                                    ['customer']
                                                                [
                                                                'supplier_business_name']
                                                            .toString()
                                                            .trim() !=
                                                        ''),
                                                child: Text(
                                                  '${followUpList[index]['customer']['supplier_business_name']}',
                                                  style: AppTheme.getTextStyle(
                                                    themeData
                                                        .textTheme.bodyLarge,
                                                    fontWeight: 500,
                                                    color: themeData
                                                        .colorScheme.onSurface,
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                width:
                                                    MySize.screenWidth! * 0.8,
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    (followUpList[index]
                                                                    ['customer']
                                                                [
                                                                'address_line_1'] !=
                                                            null)
                                                        ? Text(
                                                            "${followUpList[index]['customer']['address_line_1'] ?? ''}",
                                                            style: AppTheme
                                                                .getTextStyle(
                                                              themeData
                                                                  .textTheme
                                                                  .bodyLarge,
                                                              fontWeight: 500,
                                                              color: themeData
                                                                  .colorScheme
                                                                  .onSurface,
                                                            ),
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            maxLines: 2,
                                                          )
                                                        : Container(),
                                                    (followUpList[index]
                                                                    ['customer']
                                                                [
                                                                'address_line_2'] !=
                                                            null)
                                                        ? Text(
                                                            "${followUpList[index]['customer']['address_line_2'] ?? ''}",
                                                            style: AppTheme
                                                                .getTextStyle(
                                                              themeData
                                                                  .textTheme
                                                                  .bodyLarge,
                                                              fontWeight: 500,
                                                              color: themeData
                                                                  .colorScheme
                                                                  .onSurface,
                                                            ),
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            maxLines: 2,
                                                          )
                                                        : Container(),
                                                    Text(
                                                      "${followUpList[index]['customer']['city'] ?? ''} "
                                                      "${followUpList[index]['customer']['state'] ?? ''} "
                                                      "${followUpList[index]['customer']['country'] ?? ''} "
                                                      "${followUpList[index]['customer']['zip_code'] ?? ''} ",
                                                      style:
                                                          AppTheme.getTextStyle(
                                                        themeData.textTheme
                                                            .bodyLarge,
                                                        fontWeight: 500,
                                                        color: themeData
                                                            .colorScheme
                                                            .onSurface,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      maxLines: 2,
                                                    ),
                                                    (followUpList[index]
                                                                    ['customer']
                                                                ['email'] !=
                                                            null)
                                                        ? Text(
                                                            "${followUpList[index]['customer']['email'] ?? ''}",
                                                            style: AppTheme
                                                                .getTextStyle(
                                                              themeData
                                                                  .textTheme
                                                                  .bodyLarge,
                                                              fontWeight: 500,
                                                              color: themeData
                                                                  .colorScheme
                                                                  .onSurface,
                                                            ),
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            maxLines: 2,
                                                          )
                                                        : Container(),
                                                    (followUpList[index]
                                                                    ['customer']
                                                                ['mobile'] !=
                                                            null)
                                                        ? Text(
                                                            "${followUpList[index]['customer']['mobile'] ?? ''} "
                                                            "${followUpList[index]['customer']['alternate_number'] ?? ''} "
                                                            "${followUpList[index]['customer']['landline'] ?? ''} ",
                                                            style: AppTheme
                                                                .getTextStyle(
                                                              themeData
                                                                  .textTheme
                                                                  .bodyLarge,
                                                              fontWeight: 500,
                                                              color: themeData
                                                                  .colorScheme
                                                                  .onSurface,
                                                            ),
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            maxLines: 2,
                                                          )
                                                        : Container(),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      ],
                                    )
                                  ],
                                ));
                          }
                        })
                    : Helper().noDataWidget(context),
          ),
        ],
      ),
    );
  }

  Widget leadTab(leads) {
    setState(() {
      isFollowUpTab = false;
    });
    return (isLoading)
        ? _buildProgressIndicator()
        : (leads.length > 0)
            ? ListView.builder(
                controller: leadsListController,
                padding: EdgeInsets.all(MySize.size12!),
                shrinkWrap: true,
                itemCount: leads.length + 1,
                itemBuilder: (context, index) {
                  if (index == leads.length) {
                    return (isLoading)
                        ? _buildProgressIndicator()
                        : Container();
                  } else {}
                  return contactBlock(leads[index]);
                })
            : Helper().noDataWidget(context);
  }

  //contact widget
  Widget contactBlockFollowupOld(followUpDetails) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Visibility(
          visible: (followUpDetails['customer']['supplier_business_name'] !=
              null &&
              followUpDetails['customer']['supplier_business_name']
                  .toString()
                  .trim() !=
                  ''),
          child: Text(
            '${followUpDetails['customer']['supplier_business_name']}',
            style: AppTheme.getTextStyle(
              themeData.textTheme.titleLarge,
              fontWeight: 600,
              color: themeData.colorScheme.onSurface,
            ),
          ),
        ),
        Text(
          '${followUpDetails['title']}',
          style: AppTheme.getTextStyle(
            themeData.textTheme.titleMedium,
            fontWeight: 600,
          ),
        ),
        Visibility(
          visible: (followUpDetails['customer']['name'] != null &&
              followUpDetails['customer']['name'].toString().trim() != ''),
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
                  '${followUpDetails['customer']['name']}',
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      "${AppLocalizations.of(context).translate('follow_up_type')} : ",
                      style: AppTheme.getTextStyle(
                        themeData.textTheme.bodyLarge,
                        fontWeight: 600,
                        color: themeData.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      '${followUpDetails['schedule_type'].toUpperCase()}',
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.getTextStyle(
                        themeData.textTheme.bodyMedium,
                        fontWeight: 500,
                        color: themeData.colorScheme.onSurface,
                      ),
                    )
                  ],
                ),
                Row(
                  children: [
                    Text(
                      "${AppLocalizations.of(context).translate('status')} : ",
                      style: AppTheme.getTextStyle(
                        themeData.textTheme.bodyLarge,
                        fontWeight: 600,
                        color: themeData.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      (followUpDetails['status'] != null)
                          ? '${followUpDetails['status'].toUpperCase()}'
                          : '-',
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.getTextStyle(
                        themeData.textTheme.bodyMedium,
                        fontWeight: 500,
                        color: themeData.colorScheme.onSurface,
                      ),
                    )
                  ],
                ),
                Visibility(
                  visible: (followUpDetails['followup_category'] != null),
                  child: Row(
                    children: [
                      Text(
                        '${AppLocalizations.of(context).translate('follow_up_category')} : ',
                        style: AppTheme.getTextStyle(
                          themeData.textTheme.bodyLarge,
                          fontWeight: 600,
                          color: themeData.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        (followUpDetails['followup_category'] != null)
                            ? followUpDetails['followup_category']['name']
                            : ' - ',
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
                  visible: (followUpDetails['start_datetime'].toString() !=
                      'null' &&
                      followUpDetails['start_datetime'].toString().trim() !=
                          ''),
                  child: Row(
                    children: [
                      Text(
                        '${AppLocalizations.of(context).translate('start')} : ',
                        style: AppTheme.getTextStyle(
                          themeData.textTheme.bodyLarge,
                          fontWeight: 600,
                          color: themeData.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        (followUpDetails['start_datetime'].toString() !=
                            'null')
                            ? '${followUpDetails['start_datetime']}'
                            : ' - ',
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
                  visible:
                  (followUpDetails['end_datetime'].toString() != 'null' &&
                      followUpDetails['end_datetime'].toString().trim() !=
                          ''),
                  child: Row(
                    children: [
                      Text(
                        '${AppLocalizations.of(context).translate('end')} : ',
                        style: AppTheme.getTextStyle(
                          themeData.textTheme.bodyLarge,
                          fontWeight: 600,
                          color: themeData.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        (followUpDetails['end_datetime'].toString() != 'null')
                            ? '${followUpDetails['end_datetime']}'
                            : ' - ',
                        style: AppTheme.getTextStyle(
                          themeData.textTheme.bodyMedium,
                          fontWeight: 500,
                          color: themeData.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Visibility(
                  visible: (followUpDetails['status'] == 'open'),
                  child: GestureDetector(
                    onTap: () async {
                      await FollowUpApi()
                          .getSpecifiedFollowUp(followUpDetails['id'])
                          .then((value) {
                        var customerDetails =
                        FollowUpModel().followUpForm(value);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FollowUpForm(
                              customerDetails,
                              edit: true,
                            ),
                          ),
                        );
                      });
                    },
                    child: Icon(
                      MdiIcons.fileDocumentEditOutline,
                      color: themeData.colorScheme.onSurface,
                    ),
                  ),
                ),
                Visibility(
                  visible: (followUpDetails['schedule_type'] == 'call' &&
                      followUpDetails['status'] == 'open'),
                  child: Helper().callDropdown(
                      context,
                      followUpDetails,
                      [
                        followUpDetails['customer']['mobile'],
                        followUpDetails['customer']['alternate_number'],
                        followUpDetails['customer']['landline']
                      ],
                      type: 'whatsApp'),
                ),
                Visibility(
                  visible: (followUpDetails['schedule_type'] == 'call' &&
                      followUpDetails['status'] == 'open'),
                  child: Helper().callDropdown(
                      context,
                      followUpDetails,
                      [
                        followUpDetails['customer']['mobile'],
                        followUpDetails['customer']['alternate_number'],
                        followUpDetails['customer']['landline']
                      ],
                      type: 'call'),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }



  Widget contactBlock(contactDetails) {
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
          // Row(
          //   children: [
          //     Text(
          //       "Balance Due : ",
          //       style: AppTheme.getTextStyle(
          //         themeData.textTheme.bodyLarge,
          //         fontWeight: 600,
          //         color: themeData.colorScheme.onSurface,
          //       ),
          //     ),
          //     Expanded(
          //       child: Text(
          //        " Helper().formatCurrency(contactDetails['balance'])",
          //         style: AppTheme.getTextStyle(
          //           themeData.textTheme.bodyMedium,
          //           fontWeight: 500,
          //           color: themeData.colorScheme.onSurface,
          //         ),
          //         maxLines: 2,
          //         overflow: TextOverflow.ellipsis,
          //       ),
          //     ),
          //   ],
          // ),
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
                Expanded(
                  child: Text(
                    "${AppLocalizations.of(context).translate('upcoming')} : ",
                    style: AppTheme.getTextStyle(
                      themeData.textTheme.bodyLarge,
                      fontWeight: 600,
                      color: themeData.colorScheme.onSurface,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    contactDetails['upcoming_follow_up']!,
                    style: AppTheme.getTextStyle(
                      themeData.textTheme.bodyMedium,
                      fontWeight: 500,
                      color: themeData.colorScheme.onSurface,
                    ),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: EdgeInsets.all(MySize.size8!),
                  child: Text(
                    AppLocalizations.of(context).translate('filter'),
                    style: AppTheme.getTextStyle(themeData.textTheme.titleLarge,
                        fontWeight: 600,
                        color: themeData.colorScheme.onSurface),
                  ),
                ),
              ],
            ),
            Divider(),
            Text(
              "${AppLocalizations.of(context).translate('follow_up_status')} : ",
              style: AppTheme.getTextStyle(themeData.textTheme.bodyLarge,
                  fontWeight: 600, color: themeData.colorScheme.onSurface),
            ),
            followUpStatus(),
            Divider(),
            Text(
              "${AppLocalizations.of(context).translate('follow_up_type')} : ",
              style: AppTheme.getTextStyle(themeData.textTheme.bodyLarge,
                  fontWeight: 600, color: themeData.colorScheme.onSurface),
            ),
            followUpType(),
            Divider(),
          ],
        ),
      ),
    );
  }

  Widget followUpStatus() {
    return DropdownButtonHideUnderline(
      child: DropdownButton(
          dropdownColor: Colors.white,
          icon: Icon(
            Icons.arrow_drop_down,
          ),
          value: selectedFollowUpStatus,
          items:
              followUpStatusList.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  '$value',
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.getTextStyle(themeData.textTheme.bodyMedium,
                      fontWeight: 500, color: themeData.colorScheme.onSurface),
                ));
          }).toList(),
          onChanged: (newValue) async {
            setState(() {
              selectedFollowUpStatus = newValue.toString();
              onToggleFilter(selectedToggleValue);
            });
          }),
    );
  }

  Widget followUpType() {
    return DropdownButtonHideUnderline(
      child: DropdownButton(
          dropdownColor: Colors.white,
          icon: Icon(
            Icons.arrow_drop_down,
          ),
          value: selectedFollowUpType,
          items: followUpTypeList.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  '$value',
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.getTextStyle(themeData.textTheme.bodyMedium,
                      fontWeight: 500, color: themeData.colorScheme.onSurface),
                ));
          }).toList(),
          onChanged: (newValue) async {
            setState(() {
              selectedFollowUpType = newValue.toString();
              onToggleFilter(selectedToggleValue);
            });
          }),
    );
  }

  Widget contactBlockFollowup(followUpDetails) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Business Name
          if (followUpDetails['customer']['supplier_business_name']?.trim()?.isNotEmpty ?? false)
            Text(
              followUpDetails['customer']['supplier_business_name'],
              style: AppTheme.getTextStyle(
                themeData.textTheme.titleLarge,
                fontWeight: 600,
                color: themeData.colorScheme.onSurface,
              ),
            ),

          // Title
          Text(
            followUpDetails['title'] ?? '',
            style: AppTheme.getTextStyle(
              themeData.textTheme.titleMedium,
              fontWeight: 600,
            ),
          ),

          // Customer Name
          if (followUpDetails['customer']['name']?.trim()?.isNotEmpty ?? false)
            Row(
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
                  child: Text(
                    followUpDetails['customer']['name'] ?? '',
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

          const SizedBox(height: 10),

          // Follow-Up Details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Follow-Up Type
                  _buildDetailRow(
                    context,
                    label: AppLocalizations.of(context).translate('follow_up_type'),
                    value: followUpDetails['schedule_type']?.toUpperCase(),
                  ),

                  // Status
                  _buildDetailRow(
                    context,
                    label: AppLocalizations.of(context).translate('status'),
                    value: followUpDetails['status']?.toUpperCase() ?? '-',
                  ),

                  // Follow-Up Category
                  if (followUpDetails['followup_category'] != null)
                    _buildDetailRow(
                      context,
                      label: AppLocalizations.of(context).translate('follow_up_category'),
                      value: followUpDetails['followup_category']['name'] ?? '-',
                    ),

                  // Start Date & Time
                  if (followUpDetails['start_datetime']?.trim()?.isNotEmpty ?? false)
                    _buildDetailRow(
                      context,
                      label: AppLocalizations.of(context).translate('start'),
                      value: followUpDetails['start_datetime'] ?? '-',
                    ),

                  // End Date & Time
                  if (followUpDetails['end_datetime']?.trim()?.isNotEmpty ?? false)
                    _buildDetailRow(
                      context,
                      label: AppLocalizations.of(context).translate('end'),
                      value: followUpDetails['end_datetime'] ?? '-',
                    ),
                ],
              ),

              // Action Buttons
              _buildActionButtons(context, followUpDetails),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, {required String label, required String value}) {
    return Row(
      children: [
        Text(
          "$label : ",
          style: AppTheme.getTextStyle(
            themeData.textTheme.bodyLarge,
            fontWeight: 600,
            color: themeData.colorScheme.onSurface,
          ),
        ),
        Text(
          value,
          overflow: TextOverflow.ellipsis,
          style: AppTheme.getTextStyle(
            themeData.textTheme.bodyMedium,
            fontWeight: 500,
            color: themeData.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context,  followUpDetails) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Edit Button
        if (followUpDetails['status'] == 'open')
          GestureDetector(
            onTap: () async {
              await FollowUpApi().getSpecifiedFollowUp(followUpDetails['id']).then((value) {
                var customerDetails = FollowUpModel().followUpForm(value);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FollowUpForm(customerDetails, edit: true),
                  ),
                );
              });
            },
            child: Icon(
              MdiIcons.fileDocumentEditOutline,
              color: themeData.colorScheme.onSurface,
            ),
          ),

        // Call Dropdowns
        if (followUpDetails['schedule_type'] == 'call' && followUpDetails['status'] == 'open')
          Column(
            children: [
              Helper().callDropdown(
                context,
                followUpDetails,
                [
                  followUpDetails['customer']['mobile'],
                  followUpDetails['customer']['alternate_number'],
                  followUpDetails['customer']['landline'],
                ],
                type: 'whatsApp',
              ),
              Helper().callDropdown(
                context,
                followUpDetails,
                [
                  followUpDetails['customer']['mobile'],
                  followUpDetails['customer']['alternate_number'],
                  followUpDetails['customer']['landline'],
                ],
                type: 'call',
              ),
            ],
          ),
      ],
    );
  }

  //show add customer alert box
  Widget newCustomer() {
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
                                              color: themeData.colorScheme
                                                  .onSurface)),
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
                                              color: themeData.colorScheme
                                                  .onSurface)),
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
                                      child: Container(
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
                                                color: themeData.colorScheme
                                                    .onSurface)),
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
                                    ),
                                    Expanded(
                                      child: Container(
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
                                                color: themeData.colorScheme
                                                    .onSurface)),
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
                                  TextFormField(
                                    controller: addressLine1,
                                    style: themeData.textTheme.titleSmall!.merge(
                                        TextStyle(
                                            color: themeData
                                                .colorScheme.onSurface)),
                                    decoration: InputDecoration(
                                      hintStyle: themeData.textTheme.titleSmall!
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
                                  TextFormField(
                                    controller: addressLine2,
                                    style: themeData.textTheme.titleSmall!.merge(
                                        TextStyle(
                                            color: themeData
                                                .colorScheme.onSurface)),
                                    decoration: InputDecoration(
                                      hintStyle: themeData.textTheme.titleSmall!
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
                                  )
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
                                children: <Widget>[
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
                                    style: themeData.textTheme.titleSmall!.merge(
                                        TextStyle(
                                            color: themeData
                                                .colorScheme.onSurface)),
                                    decoration: InputDecoration(
                                      hintStyle: themeData.textTheme.titleSmall!
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
                                  Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      Expanded(
                                        child: Container(
                                          width: MySize.screenWidth! * 0.35,
                                          child: TextFormField(
                                            controller: city,
                                            style: themeData.textTheme.titleSmall!
                                                .merge(TextStyle(
                                                color: themeData.colorScheme
                                                    .onSurface)),
                                            decoration: InputDecoration(
                                              hintStyle: themeData
                                                  .textTheme.titleSmall!
                                                  .merge(TextStyle(
                                                  color: themeData.colorScheme
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
                                      ),
                                      Expanded(
                                        child: Container(
                                          width: MySize.screenWidth! * 0.35,
                                          child: TextFormField(
                                            controller: state,
                                            style: themeData.textTheme.titleSmall!
                                                .merge(TextStyle(
                                                color: themeData.colorScheme
                                                    .onSurface)),
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
                                        ),
                                      )
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      Expanded(
                                        child: Container(
                                          // width: MySize.screenWidth! * 0.35,
                                          child: TextFormField(
                                            controller: country,
                                            style: themeData.textTheme.titleSmall!
                                                .merge(TextStyle(
                                                color: themeData.colorScheme
                                                    .onSurface)),
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
                                      ),
                                      Expanded(
                                        child: Container(
                                          width: MySize.screenWidth! * 0.35,
                                          child: TextFormField(
                                            controller: zip,
                                            keyboardType: TextInputType.number,
                                            style: themeData.textTheme.titleSmall!
                                                .merge(TextStyle(
                                                color: themeData.colorScheme
                                                    .onSurface)),
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
                            if (_formKey.currentState!.validate()) {
                              showLoadingDialog(context, message: 'Adding customer, please wait');
                              Map newCustomer = {
                                'type': 'lead',
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
                                      .insertContact(
                                      Contact().contactModel(value['data']))
                                      .then((value) {
                                    Navigator.pop(context);
                                    Navigator.pop(context);
                                    _formKey.currentState!.reset();
                                    setAllList();
                                  });

                                  Navigator.pop(context);
                                }
                              });
                            }
                          } else {
                            Navigator.pop(context);
                            Fluttertoast.showToast(
                                msg: AppLocalizations.of(context)
                                    .translate('check_connectivity'));
                          }
                        },
                        child: Text(
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

}
