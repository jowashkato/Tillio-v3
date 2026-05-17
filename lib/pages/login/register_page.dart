import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config.dart';
import '../../helpers/otherHelpers.dart';

class RegistrationPage extends StatefulWidget {
  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _invitationEmailController =
      TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmationController =
      TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _taxLabel1Controller = TextEditingController();
  final TextEditingController _tinController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _deviceNoController = TextEditingController();
  final TextEditingController _deviceSerialController = TextEditingController();
  final TextEditingController _branchCodeController = TextEditingController();
  final TextEditingController _branchNameController = TextEditingController();

  // Dropdown values
  String? _selectedCountry;
  String? _selectedCurrencyId;
  String? _selectedCurrencyCode;
  String? _selectedCurrencyName;
  String? _selectedCurrencySymbol;
  String? _selectedCountryCode;
  String? _efrisOption;
  String? _registrationType;

  // UI states
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _showEfrisDropdown = false;
  bool _showTinField = false;
  bool _showDeviceDetails = false;

  // Country list
  final List<Map<String, String>> _countries = [
    {'value': 'Uganda', 'label': 'Uganda', 'flag': '🇺🇬', 'code': '+256'},
    {'value': 'Kenya', 'label': 'Kenya', 'flag': '🇰🇪', 'code': '+254'},
    {'value': 'Tanzania', 'label': 'Tanzania', 'flag': '🇹🇿', 'code': '+255'},
    {'value': 'India', 'label': 'India', 'flag': '🇮🇳', 'code': '+91'},
  ];

  // Currency list - User will select from these
  final List<Map<String, dynamic>> _currencies = [
    {'id': '2', 'code': 'UGX', 'name': 'Uganda Shilling', 'symbol': 'USh'},
    {'id': '1', 'code': 'USD', 'name': 'US Dollar', 'symbol': '\$'},
    {'id': '3', 'code': 'KES', 'name': 'Kenya Shilling', 'symbol': 'KSh'},
    {'id': '4', 'code': 'TZS', 'name': 'Tanzania Shilling', 'symbol': 'TSh'},
    {'id': '5', 'code': 'INR', 'name': 'Indian Rupee', 'symbol': '₹'}
  ];

  final List<Map<String, dynamic>> _registrationMethods = [
    {
      'value': 'direct',
      'label': 'Direct Registration',
      'icon': Icons.person_add
    },
    {'value': 'invitation', 'label': 'Email Invitation', 'icon': Icons.email},
  ];

  final List<Map<String, String>> _efrisOptions = [
    {
      'value': 'without_efris',
      'label': 'Without EFRIS (Standard registration)'
    },
    {'value': 'with_efris', 'label': 'With EFRIS (Enable URA compliance)'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedCountryCode = '+256';
    _selectedCountry = 'Uganda';
    _selectedCurrencyId = '2';
    _selectedCurrencyCode = 'UGX';
    _selectedCurrencyName = 'Uganda Shilling';
    _selectedCurrencySymbol = 'USh';
    _registrationType = null;
  }

  void _showMessage(String message, {bool isError = true}) {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green,
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _showVerificationDialog(String email) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Icon(Icons.mark_email_read, size: 50, color: Colors.green),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Registration Successful!',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff3d63ff)),
              ),
              SizedBox(height: 15),
              Text(
                'Please verify your email address',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 10),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(0xff3d63ff).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.email, size: 20, color: Color(0xff3d63ff)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        email,
                        style: TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 15),
              Text(
                'A confirmation link has been sent to your email address. Please check your inbox and click the link to verify your account.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              SizedBox(height: 10),
              Text(
                'You can login after email verification.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff3d63ff)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushReplacementNamed('/login');
              },
              child: Text('Go to Login',
                  style: TextStyle(
                      color: Color(0xff3d63ff), fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _updateCountry(String? country) {
    setState(() {
      _selectedCountry = country;
      if (country != null) {
        final countryData = _countries.firstWhere((c) => c['value'] == country);
        _selectedCountryCode = countryData['code'];
      }
      _showEfrisDropdown = (country == 'Uganda');
      if (!_showEfrisDropdown) {
        _showTinField = false;
        _showDeviceDetails = false;
        _efrisOption = null;
        _tinController.clear();
        _deviceNoController.clear();
        _deviceSerialController.clear();
        _branchCodeController.clear();
        _branchNameController.clear();
      }
    });
  }

  void _updateCurrency(String? currencyId) {
    setState(() {
      _selectedCurrencyId = currencyId;
      final currency = _currencies.firstWhere((c) => c['id'] == currencyId);
      _selectedCurrencyCode = currency['code'];
      _selectedCurrencyName = currency['name'];
      _selectedCurrencySymbol = currency['symbol'];
    });
  }

  void _updateEfrisOption(String? option) {
    setState(() {
      _efrisOption = option;
      _showTinField = (option == 'with_efris');
      _showDeviceDetails = (option == 'with_efris');
      if (!_showTinField) _tinController.clear();
      if (!_showDeviceDetails) {
        _deviceNoController.clear();
        _deviceSerialController.clear();
        _branchCodeController.clear();
        _branchNameController.clear();
      }
    });
  }

  Future<void> _register() async {
    if (_registrationType == null) {
      _showMessage("Please select registration method", isError: true);
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    if (!kIsWeb) {
      if (!await Helper().checkConnectivity()) {
        _showMessage("No internet connection", isError: true);
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      Map<String, dynamic> requestData = {};

      if (_registrationType == 'direct') {
        String startDate = _startDateController.text.trim();
        if (startDate.isEmpty) {
          startDate = DateTime.now().toIso8601String().split('T')[0];
        }

        // ========== CORRECT FIELD NAMES FOR BACKEND ==========
        requestData['business_name'] = _nameController.text.trim();
        requestData['username'] = _usernameController.text.trim();
        requestData['country'] = _selectedCountry ?? 'Uganda';

        requestData['currency'] = _selectedCurrencyCode ?? 'UGX';

        requestData['start_date'] = startDate;
        requestData['tax_label_1'] = _taxLabel1Controller.text.trim();

        requestData['country_code'] = _selectedCountryCode ?? '+256';

        requestData['phone'] = _mobileController.text.trim();

        requestData['email'] = _emailController.text.trim();
        requestData['password'] = _passwordController.text;

        requestData['registration_method'] = _registrationType;

        requestData['fy_start_month'] = '1';
        requestData['accounting_method'] = 'fifo';

        requestData['timezone'] = 'Africa/Kampala';

        requestData['surname'] = '';
        requestData['first_name'] = '';
        requestData['city'] = '';
        requestData['state'] = '';
        requestData['zip_code'] = '';
        requestData['landmark'] = '';

        // EFRIS data (only for Uganda)
        if (_selectedCountry == 'Uganda') {
          requestData['efris_enabled'] = _efrisOption ?? 'without_efris';
          if (_efrisOption == 'with_efris') {
            if (_tinController.text.trim().isNotEmpty) {
              requestData['tin'] = _tinController.text.trim();
            }
            if (_deviceNoController.text.trim().isNotEmpty) {
              requestData['device_no'] = _deviceNoController.text.trim();
            }
            if (_deviceSerialController.text.trim().isNotEmpty) {
              requestData['device_serial'] =
                  _deviceSerialController.text.trim();
            }
            if (_branchCodeController.text.trim().isNotEmpty) {
              requestData['branch_code'] = _branchCodeController.text.trim();
            }
            if (_branchNameController.text.trim().isNotEmpty) {
              requestData['branch_name'] = _branchNameController.text.trim();
            }
          }
        } else {
          requestData['efris_enabled'] = 'without_efris';
        }
      } else {
        requestData = {
          'registration_method': 'invitation',
          'email': _invitationEmailController.text.trim(),
          'password': _passwordController.text,
          'password_confirmation': _passwordConfirmationController.text,
        };
      }
      requestData.removeWhere(
          (key, value) => value == null || value.toString().isEmpty);

      print('Sending request: ${jsonEncode(requestData)}');

      final response = await http
          .post(
            Uri.parse('${Config.baseUrl}/api/business/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestData),
          )
          .timeout(Duration(seconds: 30));

      final responseData = jsonDecode(response.body);
      print('Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (responseData['success'] == true) {
          if (responseData['registration_method'] == 'direct') {
            // Check if verification is required
            if (responseData['requires_verification'] == true) {
              // Show verification dialog
              _showVerificationDialog(
                  responseData['email'] ?? _emailController.text);
            } else {
              // Direct login
              SharedPreferences prefs = await SharedPreferences.getInstance();
              if (responseData.containsKey('token')) {
                await prefs.setString('token', responseData['token']);
              }
              if (responseData.containsKey('user') &&
                  responseData['user'].containsKey('id')) {
                await prefs.setInt('userId', responseData['user']['id']);
              }

              await prefs.setString('home_currency', _selectedCurrencyId!);
              await prefs.setString('currency_code', _selectedCurrencyCode!);
              await prefs.setString(
                  'currency_symbol', _selectedCurrencySymbol!);

              _showMessage(
                  responseData['message'] ?? 'Registration successful!',
                  isError: false);

              Future.delayed(Duration(seconds: 1), () {
                Navigator.of(context).pushReplacementNamed('/login');
              });
            }
          } else {
            _showInvitationDialog();
          }
        } else {
          _showMessage(responseData['message'] ?? 'Registration failed',
              isError: true);
        }
      } else {
        String errorMessage = responseData['message'] ?? 'Registration failed';
        if (responseData['errors'] != null) {
          if (responseData['errors'] is Map) {
            errorMessage = (responseData['errors'] as Map)
                .entries
                .map((e) => '${e.key}: ${e.value.join(', ')}')
                .join('\n');
          }
        }
        _showMessage(errorMessage, isError: true);
      }
    } catch (e) {
      print('Registration error: $e');
      _showMessage('Network error: ${e.toString()}', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showInvitationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Icon(Icons.email, size: 50, color: Colors.green),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Invitation Sent!',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff3d63ff))),
              SizedBox(height: 10),
              Text('An invitation email has been sent to:'),
              SizedBox(height: 10),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Color(0xff3d63ff).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10)),
                child: Text(_invitationEmailController.text,
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Color(0xff3d63ff))),
              ),
              SizedBox(height: 10),
              Text('Please check your email to set your password.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushReplacementNamed('/login');
              },
              child: Text('Go to Login',
                  style: TextStyle(
                      color: Color(0xff3d63ff), fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff3d63ff),
      appBar: AppBar(
        title: const Text('Business Registration',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xff3d63ff),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context)),
      ),
      body: Container(
        color: const Color(0xff3d63ff),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildWelcomeCard(),
                SizedBox(height: 20),
                _buildRegistrationMethodCard(),
                SizedBox(height: 20),
                if (_registrationType == 'invitation')
                  _buildEmailInvitationCard(),
                if (_registrationType == 'direct') ...[
                  _buildBusinessInfoCard(),
                  SizedBox(height: 20),
                  _buildAccountInfoCard(),
                ],
                SizedBox(height: 30),
                if (_registrationType != null) _buildSubmitButton(),
                SizedBox(height: 20),
                _buildLoginLink(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.store, size: 60, color: Color(0xff3d63ff)),
            SizedBox(height: 10),
            Text('Create Your Business Account',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff3d63ff))),
            SizedBox(height: 5),
            Text('Choose registration method below',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  Widget _buildRegistrationMethodCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.assignment_ind, color: Color(0xff3d63ff), size: 24),
                SizedBox(width: 10),
                Text('Select Registration Method',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87)),
              ],
            ),
            SizedBox(height: 15),
            Container(
              decoration: BoxDecoration(
                  border: Border.all(color: Color(0xff3d63ff), width: 1.5),
                  borderRadius: BorderRadius.circular(15)),
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                decoration: InputDecoration(
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  border: InputBorder.none,
                  hintText: 'Choose registration method',
                  hintStyle:
                      TextStyle(color: Colors.grey.shade500, fontSize: 14),
                ),
                value: _registrationType,
                items: _registrationMethods.map((method) {
                  return DropdownMenuItem<String>(
                    value: method['value'],
                    child: Row(
                      children: [
                        Icon(method['icon'],
                            color: Color(0xff3d63ff), size: 24),
                        SizedBox(width: 15),
                        Expanded(
                            child: Text(method['label'],
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xff3d63ff),
                                    fontSize: 15))),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _registrationType = value),
                dropdownColor: Colors.white,
                style: TextStyle(
                    color: Color(0xff3d63ff),
                    fontSize: 14,
                    fontWeight: FontWeight.w500),
                icon: Icon(Icons.arrow_drop_down,
                    color: Color(0xff3d63ff), size: 28),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailInvitationCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.email, color: Color(0xff3d63ff), size: 24),
                SizedBox(width: 10),
                Text('Email Invitation',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87)),
              ],
            ),
            SizedBox(height: 15),
            TextFormField(
              controller: _invitationEmailController,
              style: TextStyle(color: Colors.black87),
              decoration: InputDecoration(
                labelText: 'Email Address *',
                labelStyle: TextStyle(color: Colors.grey.shade700),
                hintText: 'user@example.com',
                prefixIcon:
                    Icon(Icons.email_outlined, color: Color(0xff3d63ff)),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Color(0xff3d63ff), width: 2)),
                filled: true,
                fillColor: Colors.grey.shade50,
                helperText: 'A temporary password will be sent to this email',
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty)
                  return 'Please enter email address';
                if (!value.contains('@') || !value.contains('.'))
                  return 'Please enter a valid email address';
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.business_center, color: Color(0xff3d63ff), size: 24),
                SizedBox(width: 10),
                Text('Business Information',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87)),
              ],
            ),
            SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              style: TextStyle(color: Colors.black87),
              decoration:
                  _buildInputDecoration('Business Name *', Icons.business),
              validator: (value) => (value == null || value.isEmpty)
                  ? 'Please enter business name'
                  : null,
            ),
            SizedBox(height: 15),
            TextFormField(
              controller: _usernameController,
              style: TextStyle(color: Colors.black87),
              decoration: _buildInputDecoration('Username *', Icons.person,
                  helperText: 'This will be used to login to the system'),
              validator: (value) =>
                  (value == null || value.isEmpty || value.length < 4)
                      ? 'Username must be at least 4 characters'
                      : null,
            ),
            SizedBox(height: 15),
            Container(
              decoration: BoxDecoration(
                  border: Border.all(color: Color(0xff3d63ff), width: 1.5),
                  borderRadius: BorderRadius.circular(12)),
              child: DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Country *',
                  labelStyle: TextStyle(color: Colors.grey.shade700),
                  prefixIcon: Icon(Icons.public, color: Color(0xff3d63ff)),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                value: _selectedCountry,
                items: _countries.map((country) {
                  return DropdownMenuItem<String>(
                    value: country['value'],
                    child: Row(
                      children: [
                        Text(country['flag']!, style: TextStyle(fontSize: 24)),
                        SizedBox(width: 10),
                        Text(country['label']!,
                            style:
                                TextStyle(color: Colors.black87, fontSize: 16)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: _updateCountry,
                dropdownColor: Colors.white,
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Please select country'
                    : null,
              ),
            ),
            SizedBox(height: 15),
            Container(
              decoration: BoxDecoration(
                  border: Border.all(color: Color(0xff3d63ff), width: 1.5),
                  borderRadius: BorderRadius.circular(12)),
              child: DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Currency *',
                  labelStyle: TextStyle(color: Colors.grey.shade700),
                  prefixIcon:
                      Icon(Icons.currency_exchange, color: Color(0xff3d63ff)),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                value: _selectedCurrencyId,
                items: _currencies.map<DropdownMenuItem<String>>((currency) {
                  return DropdownMenuItem<String>(
                    value: currency['id'].toString(),
                    child: Text(
                      '${currency['code']} - ${currency['name']} (${currency['symbol']})',
                      style: TextStyle(color: Colors.black87, fontSize: 15),
                    ),
                  );
                }).toList(),
                onChanged: _updateCurrency,
                dropdownColor: Colors.white,
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Please select currency'
                    : null,
              ),
            ),
            SizedBox(height: 15),
            if (_showEfrisDropdown) _buildEfrisSection(),
            if (_showEfrisDropdown) SizedBox(height: 15),
            TextFormField(
              controller: _startDateController,
              style: TextStyle(color: Colors.black87),
              decoration:
                  _buildInputDecoration('Start Date *', Icons.calendar_today),
              readOnly: true,
              onTap: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (pickedDate != null) {
                  _startDateController.text =
                      pickedDate.toIso8601String().split('T')[0];
                }
              },
              validator: (value) => (value == null || value.isEmpty)
                  ? 'Please select start date'
                  : null,
            ),
            SizedBox(height: 15),
            TextFormField(
              controller: _taxLabel1Controller,
              style: TextStyle(color: Colors.black87),
              decoration: _buildInputDecoration('Tax Name *', Icons.receipt,
                  helperText: 'e.g., VAT, GST, Sales Tax'),
              validator: (value) => (value == null || value.isEmpty)
                  ? 'Please enter tax name'
                  : null,
            ),
            SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                        border:
                            Border.all(color: Color(0xff3d63ff), width: 1.5),
                        borderRadius: BorderRadius.circular(12)),
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Country Code *',
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      ),
                      value: _selectedCountryCode,
                      items: _countries.map((country) {
                        return DropdownMenuItem<String>(
                          value: country['code'],
                          child: Text(country['code']!,
                              style: TextStyle(color: Colors.black87)),
                        );
                      }).toList(),
                      onChanged: (value) =>
                          setState(() => _selectedCountryCode = value),
                      dropdownColor: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  flex: 5,
                  child: TextFormField(
                    controller: _mobileController,
                    style: TextStyle(color: Colors.black87),
                    decoration: InputDecoration(
                      labelText: 'Business Contact Number *',
                      hintText: '712345678',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: Color(0xff3d63ff), width: 2)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      helperText:
                          'Enter phone number without country code (e.g., 712345678)',
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Please enter phone number'
                        : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_circle, color: Color(0xff3d63ff), size: 24),
                SizedBox(width: 10),
                Text('Account Information',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87)),
              ],
            ),
            SizedBox(height: 20),
            TextFormField(
              controller: _emailController,
              style: TextStyle(color: Colors.black87),
              decoration: _buildInputDecoration(
                  'Email Address *', Icons.email_outlined),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty)
                  return 'Please enter email address';
                if (!value.contains('@') || !value.contains('.'))
                  return 'Please enter a valid email address';
                return null;
              },
            ),
            SizedBox(height: 15),
            TextFormField(
              controller: _passwordController,
              style: TextStyle(color: Colors.black87),
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password *',
                prefixIcon: Icon(Icons.lock_outline, color: Color(0xff3d63ff)),
                suffixIcon: IconButton(
                  icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.grey.shade600),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Color(0xff3d63ff), width: 2)),
                filled: true,
                fillColor: Colors.grey.shade50,
                helperText:
                    'Minimum 8 characters with at least 1 uppercase, 1 lowercase, 1 number',
              ),
              validator: (value) {
                if (value == null || value.isEmpty)
                  return 'Please enter password';
                if (value.length < 8)
                  return 'Password must be at least 8 characters';
                return null;
              },
            ),
            SizedBox(height: 15),
            TextFormField(
              controller: _passwordConfirmationController,
              style: TextStyle(color: Colors.black87),
              obscureText: _obscureConfirmPassword,
              decoration: InputDecoration(
                labelText: 'Confirm Password *',
                prefixIcon: Icon(Icons.lock_outline, color: Color(0xff3d63ff)),
                suffixIcon: IconButton(
                  icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.grey.shade600),
                  onPressed: () => setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword),
                ),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Color(0xff3d63ff), width: 2)),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              validator: (value) {
                if (value == null || value.isEmpty)
                  return 'Please confirm password';
                if (value != _passwordController.text)
                  return 'Passwords do not match';
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEfrisSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
              border: Border.all(color: Colors.orange.shade300, width: 1.5),
              borderRadius: BorderRadius.circular(12)),
          child: DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'EFRIS Integration',
              labelStyle: TextStyle(color: Colors.grey.shade700),
              prefixIcon: Icon(Icons.cloud_upload, color: Colors.orange),
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            value: _efrisOption,
            items: _efrisOptions
                .map((option) => DropdownMenuItem<String>(
                      value: option['value'],
                      child: Text(option['label']!,
                          style: TextStyle(color: Colors.black87)),
                    ))
                .toList(),
            onChanged: _updateEfrisOption,
            dropdownColor: Colors.white,
            validator: (value) => (value == null || value.isEmpty)
                ? 'Please select EFRIS option'
                : null,
          ),
        ),
        if (_showTinField) ...[
          SizedBox(height: 15),
          TextFormField(
            controller: _tinController,
            style: TextStyle(color: Colors.black87),
            decoration: _buildInputDecoration(
                'Tax Identification Number (TIN)', Icons.numbers,
                helperText:
                    'Required for eFRIS integration - 10 digit number from URA'),
            keyboardType: TextInputType.number,
            maxLength: 10,
            validator: (value) {
              if (_efrisOption == 'with_efris') {
                if (value == null || value.isEmpty)
                  return 'Please enter TIN number';
                if (value.length != 10) return 'TIN must be exactly 10 digits';
              }
              return null;
            },
          ),
        ],
        if (_showDeviceDetails) ...[
          SizedBox(height: 15),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('EFRIS Device Details (Optional)',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text('You can add these later in settings',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                SizedBox(height: 10),
                TextFormField(
                    controller: _deviceNoController,
                    decoration:
                        _buildInputDecoration('Device Number', Icons.memory)),
                SizedBox(height: 10),
                TextFormField(
                    controller: _deviceSerialController,
                    decoration: _buildInputDecoration(
                        'Device Serial Number', Icons.qr_code)),
                SizedBox(height: 10),
                TextFormField(
                    controller: _branchCodeController,
                    decoration:
                        _buildInputDecoration('Branch Code', Icons.code)),
                SizedBox(height: 10),
                TextFormField(
                    controller: _branchNameController,
                    decoration: _buildInputDecoration(
                        'Branch Name', Icons.location_city)),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _register,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        minimumSize: Size(double.infinity, 50),
      ),
      child: _isLoading
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xff3d63ff))))
          : Text(
              _registrationType == 'direct'
                  ? 'Register Business'
                  : 'Send Invitation',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff3d63ff)),
            ),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Already have an account?',
            style: TextStyle(color: Colors.white, fontSize: 14)),
        TextButton(
          onPressed: () => Navigator.of(context).pushReplacementNamed('/login'),
          child: Text('Login',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  decoration: TextDecoration.underline)),
        ),
      ],
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon,
      {String? helperText}) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade700),
      prefixIcon: Icon(icon, color: Color(0xff3d63ff)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xff3d63ff), width: 2)),
      filled: true,
      fillColor: Colors.grey.shade50,
      helperText: helperText,
      helperStyle: TextStyle(color: Colors.grey.shade600, fontSize: 12),
    );
  }
}
