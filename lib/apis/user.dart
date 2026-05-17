import 'dart:convert';

import 'package:http/http.dart' as http;

import '../api_end_points.dart';
import 'api.dart';

class User extends Api {
  Future<Map> get(var token) async {
    String url = ApiEndPoints.getUser;
    var response =
        await http.get(Uri.parse(url), headers: this.getHeader(token));
    var userDetails = jsonDecode(response.body);
    // print("userDetails => $userDetails");
    Map userDetailsMap = userDetails['data'];
    // Map userDetailsMap = userDetails;
    return userDetailsMap;
  }
}
