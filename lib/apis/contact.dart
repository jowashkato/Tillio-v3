import 'dart:convert';

import 'package:http/http.dart' as http;

import '../api_end_points.dart';
import '../models/contact_model.dart';
import '../models/system.dart';
import 'api.dart';

class CustomerApi extends Api {
  var customers;

  get() async {
    String? url = ApiEndPoints.getContact;
    var token = await System().getToken();
    do {
      try {
        var response =
            await http.get(Uri.parse(url!), headers: this.getHeader('$token'));
        url = jsonDecode(response.body)['links']['next'];
        jsonDecode(response.body)['data'].forEach((element) {
          Contact().insertContact(Contact().contactModel(element));
        });
      } catch (e) {
        return null;
      }
    } while (url != null);
  }

  Future<dynamic> add(Map customer) async {
    try {
      String url = ApiEndPoints.addContact;
      var body = json.encode(customer);
      var token = await System().getToken();
      var response = await http.post(Uri.parse(url),
          headers: this.getHeader('$token'), body: body);
      var result = await jsonDecode(response.body);
      return result;
    } catch (e) {
      return null;
    }
  }

  Future<dynamic> addFarmer(Map customer) async {
    try {
      String url = ApiEndPoints.addFarmer;
      var body = json.encode(customer);
      var token = await System().getToken();
      var response = await http.post(Uri.parse(url),
          headers: this.getHeader('$token'), body: body);
      var result = await jsonDecode(response.body);
      return result;
    } catch (e) {
      return null;
    }
  }

  Future<dynamic> updateFarmer(Map customer) async {
    try {
      // Extract the ID from the customer data
      final id = customer['id'];

      if (id == null) {
        throw Exception('fARMER ID is missing');
      }

      // Build the URL dynamically using the ID
      final String url = '${ApiEndPoints.updateFarmer}/$id';

      var body = json.encode(customer);
      var token = await System().getToken();
      var response = await http.put(Uri.parse(url),
          headers: this.getAjaxHeader('$token'), body: body);print(response.body);
      var result = await jsonDecode(response.body);
      return result;
    } catch (e) {
      return null;
    }
  }
  Future<dynamic> forgotPassword(Map data) async {
    try {
      String url = ApiEndPoints.forgetPassword;
      var body = json.encode(data);
      var token = await System().getToken();
      var response = await http.post(Uri.parse(url),
          headers: this.getHeader(token), body: body);
      var result = await jsonDecode(response.body);
      return result;
    } catch (e) {
      return null;
    }
  }


  Future<dynamic> loginWithEmail(Map data) async {
    try {
      String url = ApiEndPoints.loginEmailUrl;
      var body = json.encode(data);
      var token = await System().getToken();
      var response = await http.post(Uri.parse(url), body: body);
      /*print(body);
      */print(token);
      print(response.body);
      var result = await jsonDecode(response.body);
      return result;
    } catch (e) {
      return null;
    }
  }
  // Future<dynamic> qrlogin(String data) async {
  //   try {
  //     String url = ApiEndPoints.qrlogin;
  //     var body = json.encode(data);
  //     var token = await System().getToken();
  //     var response = await http.post(Uri.parse(url), body: body);
  //     /*print(body);
  //     */print(token);
  //     print(response.body);
  //     var result = await jsonDecode(response.body);
  //     return result;
  //   } catch (e) {
  //     return null;
  //   }
  // }////////////
  Future<Map?> validateWithServer(String? idToken) async {
    //try {
      String url = ApiEndPoints.ggsigin;
      var body = json.encode({'id_token':idToken});
      var token = await System().getToken();
      final response = await http.post(Uri.parse(url),
          headers: this.getHeader(token), body: body);

        final data = jsonDecode(response.body);
       // print(data);
      if (response.statusCode == 200) {
      return {'success': true, 'access_token': data['access_token']};
      } else if (response.statusCode == 401) {
      //Invalid credentials
      return {'success': false, 'error': data['error']};
      }
      else if (response.statusCode == 400) {
        //Invalid credentials
        return {'success': false, 'error': data['error_description']};
      }
      else {
        return {'success': false, 'error': data['error_description']};
      }
    // } catch (e) {
    //   print('Token validation failed: $e');
    //   return null;
    // }
  }
}
