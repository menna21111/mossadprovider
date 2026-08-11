class AppConstants {
  /// غيّر الـ base URL حسب الـ API الخاص بك
  static const String baseUrl = 'https://mosaed-production.up.railway.app';

  static const String appVersion = '2.4.1';
  static const String userType = 'provider';

  static const String otpSend = '/api/accounts/otp/send/';
  static const String otpVerify = '/api/accounts/otp/verify/';
  static const String providerRegister = '/api/accounts/provider/register/';
  static const String providerProfile = '/api/accounts/provider/profile/';
  static const String providerAddresses = '/api/accounts/provider/addresses/';
  static String deleteAddress(String id) =>
      '/api/accounts/provider/addresses/$id/';
  static const String logout = 'logout/';
  static const String biometricRegister = '/api/accounts/biometric/register/';
  static const String biometricLogin = '/api/accounts/biometric/login/';
  static const String tokenRefresh = 'auth/tokens/refresh/';

  static const String existedServices = '/api/existedservices/existed/';
  static String existedServiceDetail(String id) =>
      '/api/existedservices/existed/$id/';
  static String serviceProviders(String serviceId) =>
      '/api/existedservices/services/$serviceId/providers/';
  static String servicePreviousWorks(String serviceId) =>
      '/api/existedservices/services/$serviceId/previous-works/';
  static const String providerBookings = '/api/existedservices/provider/bookings/';
  static String providerBookingDetail(String id) =>
      '/api/existedservices/provider/bookings/$id/';
  static const String validateCoupon = '/api/existedservices/coupons/validate/';
  static const String providerCompletionForms =
      '/api/existedservices/provider/completion-forms/';
  static String providerCompletionFormDetail(String bookingId) =>
      '/api/existedservices/provider/completion-forms/$bookingId/';
  static String bookingPreviousWork(String bookingId) =>
      '/api/existedservices/bookings/$bookingId/previous-work/';
  static const String providerCustomRequests =
      '/api/custom_services/provider/custom-requests/';
  static String providerCustomRequestDetail(String id) =>
      '/api/custom_services/provider/custom-requests/$id/';
  static String providerCustomRequestOffers(String requestId) =>
      '/api/custom_services/provider/custom-requests/$requestId/offers/';
  static const String providerCustomCompletionForms =
      '/api/custom_services/provider/custom-requests/completion-forms/';
  static String providerCustomCompletionFormDetail(String requestId) =>
      '/api/custom_services/provider/custom-requests/$requestId/completion/';
  static String customRequestPreviousWork(String requestId) =>
      '/api/custom_services/provider/custom-requests/$requestId/previous-work/';
  static String providerCustomRequestCompletion(String requestId) =>
      '/api/custom_services/provider/custom-requests/$requestId/completion/';
  static const String providerOffers = '/api/custom_services/provider/offers/';
  static String providerOfferDetail(String offerId) =>
      '/api/custom_services/provider/offers/$offerId/';
  static String providerCustomRequestChat(String requestId) =>
      '/api/custom_services/provider/custom-requests/$requestId/chat/';
  static String providerCustomRequestChatRead(String requestId) =>
      '/api/custom_services/provider/custom-requests/$requestId/chat/read/';

  static const String notifications = '/api/custom_services/notifications/';
  static const String notificationsUnreadCount =
      '/api/custom_services/notifications/unread-count/';
  static String notificationRead(String id) =>
      '/api/custom_services/notifications/$id/read/';
  static const String notificationsMarkAllRead =
      '/api/custom_services/notifications/mark-all-read/';
  static const String deviceTokens = '/api/custom_services/device-tokens/';

  // Provider payments
  static const String providerWallet = '/api/payments/provider/wallet/';
  static const String providerDuesStatus = '/api/payments/provider/dues/status/';
  static const String providerDues = '/api/payments/provider/dues/';
  static String paymentConfirmCash(String paymentRequestId) =>
      '/api/payments/payments/$paymentRequestId/confirm-cash/';
  static String paymentByBooking(String bookingId) =>
      '/api/payments/by-booking/$bookingId/';
  static String paymentByCustomRequest(String requestId) =>
      '/api/payments/by-custom-request/$requestId/';

  static String get wsBaseUrl {
    final uri = Uri.parse(baseUrl);
    final scheme = uri.scheme == 'https' ? 'wss' : 'ws';
    final includePort = uri.hasPort &&
        uri.port != 0 &&
        uri.port != 443 &&
        uri.port != 80;
    final port = includePort ? ':${uri.port}' : '';
    return '$scheme://${uri.host}$port';
  }

  static List<String> notificationSocketUrls(String accessToken) => [
        '$wsBaseUrl/ws/notifications/?token=$accessToken',
        '$wsBaseUrl/ws/notifications/?access_token=$accessToken',
      ];

  static List<String> chatSocketUrls(String requestId, String accessToken) => [
        '$wsBaseUrl/ws/provider/chat/$requestId/?token=$accessToken',
        '$wsBaseUrl/ws/provider/chat/$requestId/?access_token=$accessToken',
        '$wsBaseUrl/ws/chat/$requestId/?token=$accessToken',
        '$wsBaseUrl/ws/chat/$requestId/?access_token=$accessToken',
      ];

  static const String specializations = '/api/accounts/specializations/';

  static const String cloudinaryCloudName = 'dftpzis0y';
  static const String cloudinaryUploadPreset = 'mosaed_customer';
  static const String cloudinaryCustomRequestsFolder = 'custom_requests';
  static String get cloudinaryImageUploadUrl =>
      'https://api.cloudinary.com/v1_1/$cloudinaryCloudName/image/upload';

  /// مؤقتًا لحد ما يتظبط Cloudinary upload preset
  static const String customRequestPlaceholderImage =
      'https://res.cloudinary.com/dftpzis0y/image/upload/v1782039707/services/erfger_ktaiib.png';

  static const String cities = '/api/accounts/cities/';
  static const String regions = '/api/accounts/regions';

  static const String googleMapsApiKey =
      'AIzaSyBcqYSQUB84VBJOwAqgyMmHlfGfW3Yl68A';

  static const String defaultAddressIdKey = 'default_address_id';

  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String biometricTokenKey = 'biometric_token';
  static const String deviceIdKey = 'device_id';
  static const String userNameKey = 'user_name';
  static const String phoneNumberKey = 'phone_number';
  static const String biometricEnabledKey = 'biometric_enabled';
  static const String isLoggedInKey = 'is_logged_in';
  static const String locationSetupDoneKey = 'location_setup_done';
  static const String userCityKey = 'user_city';
  static const String userDistrictKey = 'user_district';
  static const String userStreetKey = 'user_street';
  static const String userLocationDetailsKey = 'user_location_details';
}
