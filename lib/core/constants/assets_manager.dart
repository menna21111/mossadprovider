const String jsonPath = 'assets/json';
const String imagesPath = 'assets/images';
const String iconsPath = 'assets/icons';

class JsonAssets {}

class ImageAssets {
  // ── Logos ──────────────────────────────────────────────────────────────
  static const String logo = '$imagesPath/logo_brand.png';
  static const String logoBrand = logo;
  static const String logoPng = '$imagesPath/logo.png';
  static const String logomin = logo;

  // ── Brand / flags ──────────────────────────────────────────────────────
  static const String saudiFlag = '$imagesPath/saudi_flag.svg';
  static const String riyalIcon = '$imagesPath/riyalicon.svg';

  // ── Backgrounds ────────────────────────────────────────────────────────
  static const String background =
      '$imagesPath/background%202.51.49%E2%80%AFAM.jpeg';
  static const String backgroundauth = background;
  static const String fingerprintSuccess = '$imagesPath/fingerprintscuess.png';

  // ── Bottom navigation ──────────────────────────────────────────────────
  static const String home = '$imagesPath/home.svg';
  static const String orders = '$imagesPath/orders.svg';
  static const String taskIcon = '$imagesPath/taskicon.svg';
  static const String messages = '$imagesPath/messages.svg';
  static const String moreIcon = '$imagesPath/moreIcon.svg';
  static const String moreIco = '$imagesPath/moreico.svg';

  // ── Chat empty states ──────────────────────────────────────────────────
  static const String chatsEmpty = '$imagesPath/image 3453.png';
  static const String chatsSearchEmpty = '$imagesPath/image 3454.png';

  // Legacy aliases
  static const String elements1 = home;
  static const String icon1 = messages;
  static const String icon2 = orders;

  // ── UI icons ───────────────────────────────────────────────────────────
  static const String offers = '$imagesPath/offers.svg';
  static const String activeWorksIcon = '$imagesPath/activeworksicon.svg';
  static const String mail01 = '$imagesPath/mail-01.svg';
  static const String notification = '$imagesPath/notification.svg';
  static const String calendar03 = '$imagesPath/calendar-03.svg';
  static const String location = '$imagesPath/location.svg';
  static const String cameraIcon = '$imagesPath/cameraicon.svg';
  static const String addPhotosButton = '$imagesPath/Add photos button.svg';
  static const String iconContainer = '$imagesPath/icon-container.svg';
  static const String iconMark1 = '$imagesPath/icon_1.svg';
  static const String userAdd01 = '$imagesPath/user-add-01.svg';
  static const String verifyWhite = '$imagesPath/verifywhite.svg';
  static const String chatDocument = '$imagesPath/documantmessage.svg';
  static const String chatMic = '$imagesPath/mic-01.svg';
  static const String chatSend = '$imagesPath/sent.svg';

  // ── Task / request detail ───────────────────────────────────────────────
  static const String orderHash = '$imagesPath/#.svg';
  static const String checkmarkBadge01 = '$imagesPath/checkmark-badge-01.svg';
  static const String checkmarkCircle03 = '$imagesPath/checkmark-circle-03.svg';
  static const String moneyOrderDetails = '$imagesPath/moneyorderdetails.svg';
  static const String note01 = '$imagesPath/note-01.svg';
  static const String time04 = '$imagesPath/time-04.svg';
  static const String timeQuarterPass = '$imagesPath/time-quarter-pass.svg';
  static const String message02 = '$imagesPath/message-02.svg';
  static const String image02 = '$imagesPath/image-02.svg';

  // ── Profile / more tab ─────────────────────────────────────────────────
  static const String userIconProfile = '$imagesPath/usericonprofile.svg';
  static const String locationProfile = '$imagesPath/locationprofile.svg';
  static const String profits = '$imagesPath/profits.svg';
  static const String bankAccount = '$imagesPath/bankaccount.svg';
  static const String profitsOfMansa = '$imagesPath/profitsofmansa.svg';
  static const String settings01 = '$imagesPath/settings-01.svg';
  static const String languageIcon = '$imagesPath/language Icon.svg';
  static const String alertIcon = '$imagesPath/Alert Icon.svg';
  static const String holdAccount = '$imagesPath/holdaccount.png';
  static const String holdIcon = '$imagesPath/holdicon.svg';

  // ── Address form ───────────────────────────────────────────────────────
  static const String chooseCity = '$imagesPath/choosecity.svg';
  static const String chooseArea = '$imagesPath/choosearea.svg';
  static const String chooseStreet = '$imagesPath/choosestreet.svg';
  static const String mapsGlobal02 = '$imagesPath/maps-global-02.svg';
  static const String buildNumber = '$imagesPath/buildnumber.svg';
  static const String houseIcon = '$imagesPath/houseicon.svg';
  static const String buildingOffice =
      '$imagesPath/heroicons_building-office-2-solid.svg';
  static const String descIcon = '$imagesPath/desc.svg';

  // ── Empty / placeholder images ─────────────────────────────────────────
  static const String noOffer = '$imagesPath/nooofer.png';
  static const String noPlaces = '$imagesPath/noplaces.png';
  static const String chooseAddress = '$imagesPath/chooseadress.png';
  static const String serviceToMe = '$imagesPath/servicetome.png';
  static const String card = '$imagesPath/card.png';
  static const String notificationsEmpty = '$imagesPath/noonptification.png';
}

class IconAssets {
  // profile (assets/icons)
  static const String accountdetails = '$iconsPath/profile.png';
  static const String ratingfeedback = '$iconsPath/ratingfeedback.png';
  static const String privicypolicy = '$iconsPath/privacypolicy.png';
  static const String logoutred = '$iconsPath/logout.png';
  static const String logingreen = '$iconsPath/login.png';
}

class SoundAssets {
  /// Relative to `assets/` — used with `AssetSource`.
  static const String notification = 'sound/scuess_order.mp3';
}
