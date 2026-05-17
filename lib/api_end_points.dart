abstract final class ApiEndPoints {
  // static String baseUrl = 'http://10.0.2.2/UltimatePOS/public';
  // static String baseUrl = 'https://www.testpos.digifrica.com/public';

  static String apiUrl = '/api';
  static String baseUrl = 'https://tillio.digifrica.com';

  //#region used by http

  ///auth
  static String loginUrl = '$baseUrl$apiUrl/business/login';
  static String getUser = '$baseUrl$apiUrl/user/loggedin';
  static String loginEmailUrl = '$baseUrl$apiUrl/login-with-email';

  ///attendance
  static String checkIn = '$baseUrl$apiUrl/clock-in';
  static String checkOut = '$baseUrl$apiUrl/clock-out';
  static String getAttendance = '$baseUrl$apiUrl/get-attendance/';

  static String forgetPassword = '$baseUrl$apiUrl/forget-password';

  ///contact
  static String contact = '$baseUrl$apiUrl/contactapi';
  static String getContact = '$contact?type=customer&per_page=500';
  static String addContact = '$contact?type=customer';
  //contact payment
  static String customerDue = '$contact/';
  static String addContactPayment = '$contact-payment';
  static String get googleLoginUrl => '$baseUrl/api/auth/google-login';
  //#endregion

  //#region used by Dio

  ///Notifications
  static String allNotifications = '$apiUrl/notifications';

  ///brands
  static String allBrands = '$apiUrl/brand';

  ///Purchases
  static String purchases = '$apiUrl/purchases';
  //#endregion

  ///farmer
  static String farmer = '$baseUrl$apiUrl/farmer';
  static String addFarmer = '$farmer?type=farmer';
  static String updateFarmer = '$farmer';

  static String qrlogin = '$baseUrl$apiUrl/qr-login/authorize';
  static String ggsigin = '$baseUrl$apiUrl/google-sigin/authorize';

  //#region Business Registration
  ///Business
  static String business = '$baseUrl$apiUrl/business';
  static String registerBusiness = '$business/register';
  static String emailRegister = '$business/email-register';
  static String changePassword = '$business/change-password';
  static String getBusinessDetails = '$business/details';
  static String updateBusinessDetails = '$business/update';

  static final String pricingPackages = "$baseUrl/pricing";
  //#endregion
}
