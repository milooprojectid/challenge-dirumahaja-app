import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:dirumahaja/core/entity/entity_credit.dart';
import 'package:dirumahaja/core/entity/entity_notif.dart';
import 'package:dirumahaja/core/entity/entity_profile.dart';
import 'package:dirumahaja/core/network/api.dart';
import 'package:dirumahaja/core/res/app_color.dart';
import 'package:dirumahaja/core/res/app_images.dart';
import 'package:dirumahaja/feature/activity/activity_screen.dart';
import 'package:dirumahaja/feature/status/status_board.dart';
import 'package:dirumahaja/feature/information/information_screen.dart';
import 'package:dirumahaja/feature/notification/notification_screen.dart';
import 'package:dirumahaja/feature/rulebook/rule_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_color/flutter_color.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info/package_info.dart';
import 'package:url_launcher/url_launcher.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

/// This "Headless Notif Handler" is run when app is terminated.
Future<dynamic> myBackgroundMessageHandler(Map<String, dynamic> message) {
  print('onBackground : $message');
  if (message.containsKey('data')) {
    // Handle data message
    final dynamic data = message['data'];
  }

  if (message.containsKey('notification')) {
    // Handle notification message
    final dynamic notification = message['notification'];
  }

  // Or do other work.
}

class _DashboardScreenState extends State<DashboardScreen> {
  Gradient skyGradient = AppColor.skyGradient;
  Gradient shadeGradient = AppColor.shadeNoonGradient;
  Color userNameColor = Colors.black;
  Profile profile;
  List<Notif> notifList = [];
  Credit partner;
  String downloadLink = "";

  @override
  void initState() {
    super.initState();
    reload();
  }

  void reload() {
    checkTimeBackground();
    checkVersion();
    loadProfile();
    loadNotification();
    loadCredits();
  }

  void loadCredits() async {
    RemoteConfig remoteConfig = await RemoteConfig.instance;
    final rawCredits = remoteConfig.getString('game_credit');
    final jsonCredits = jsonDecode(rawCredits);
    final credits = Credit.fromJsonList(jsonCredits);
    setState(() {
      partner = credits.where((c) => c.link.contains('prixa.ai')).first;
    });
  }

  void checkVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    RemoteConfig remoteConfig = await RemoteConfig.instance;
    final rawVersions = remoteConfig.getString('versions');
    final jsonVersions = jsonDecode(rawVersions);
    final remoteAppNumber = jsonVersions['app'];

    String localAppNumber = packageInfo.buildNumber;
    bool isUpdateExist = remoteAppNumber.compareTo(localAppNumber) > 0;

    downloadLink = jsonVersions['app_download_link'];

    if (isUpdateExist) {
      final updateLink = jsonVersions['app_update_link'];
      showUpdateDialog(updateLink);
    }
  }

  void showUpdateDialog(String link) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(14),
          children: <Widget>[
            Text(
              'Terdapat versi terbaru',
              style: GoogleFonts.raleway(
                color: AppColor.titleColor.toHexColor(),
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            Container(height: 12),
            Text(
              'Yuk lakukan udpate aplikasi, agar mendapatkan fitur terbaru',
              style: GoogleFonts.raleway(fontSize: 14),
            ),
            Container(height: 12),
            FlatButton(
              color: AppColor.titleColor.toHexColor(),
              textColor: Colors.white,
              child: Text('Download Update'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: AppColor.titleColor.toHexColor()),
              ),
              onPressed: () => launch(link),
            )
          ],
        ),
      ),
    );
  }

  void checkTimeBackground() {
    setState(() {
      final hour = DateTime.now().hour;
      if (hour >= 6 && hour < 14) {
        skyGradient = AppColor.skyGradient;
      } else if (hour >= 14 && hour < 19) {
        skyGradient = AppColor.skyNoonGradient;
        shadeGradient = AppColor.shadeNoonGradient;
      } else {
        skyGradient = AppColor.skyNightGradient;
        shadeGradient = AppColor.shadeNightGradient;
        userNameColor = Colors.white;
      }
    });
  }

  void loadNotification() async {
    final user = await FirebaseAuth.instance.currentUser();

    final request = await Api().getDio().get<Map<String, dynamic>>(
          '/profile/notification?cache=false',
          options: Options(headers: {'uid': user.uid}),
        );

    final notifs = Notif.fromMapList(request.data['data']);
    setState(() {
      notifList = notifs;
    });
  }

  void loadProfile() async {
    final user = await FirebaseAuth.instance.currentUser();

    final profileResult = await Api().get<Profile>(
      path: '/profile?cache=false',
      dataParser: Profile.fromJson,
      headers: {'uid': user.uid},
    );

    profile = profileResult.data;
    String city = profile.locationName;

    if (city == null || city.isEmpty) {
      List<Placemark> placemark = await Geolocator().placemarkFromCoordinates(
        double.tryParse(profile.coordinate.split(',')[0]),
        double.tryParse(profile.coordinate.split(',')[1]),
      );
      if (placemark.length > 0) {
        city = placemark[0].subAdministrativeArea;
      }
    }

    if (city == null || city.isEmpty) city = "Unknown";

    setState(() {
      this.profile = profile.copyWith(locationName: city);
    });

    setupFCM(profile.username);
  }

  void setupFCM(String username) async {
    final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
    _firebaseMessaging.subscribeToTopic(username);
    _firebaseMessaging.subscribeToTopic('all');
    _firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) async {
        print("onMessage: $message");
        // _showItemDialog(message);
      },
      onBackgroundMessage: myBackgroundMessageHandler,
      onLaunch: (Map<String, dynamic> message) async {
        print("onLaunch: $message");
      },
      onResume: (Map<String, dynamic> message) async {
        print("onResume: $message");
      },
    );
    _firebaseMessaging.requestNotificationPermissions(
      const IosNotificationSettings(sound: true, badge: true, alert: true),
    );
    _firebaseMessaging.onIosSettingsRegistered.listen(
      (IosNotificationSettings settings) {
        print("Settings registered: $settings");
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(gradient: skyGradient),
        child: Stack(
          children: <Widget>[
            ...getBackgrounds(),
            getUserPin(),
            getContent(),
          ],
        ),
      ),
    );
  }

  Column getContent() {
    return Column(
      children: <Widget>[
        Container(height: 32),
        getTopbar(),
        StatusBoard(profile, () => reload(), downloadLink),
        Expanded(child: Container()),
        getMainMenu(),
        Container(height: 10),
        getPartnerButton(),
        Container(height: 16),
      ],
    );
  }

  FlatButton getPartnerButton() {
    final partnerText = ' with ${partner?.creator}';
    final content = 'Periksa Gejala${partner != null ? partnerText : ''}';
    return FlatButton(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.white),
      ),
      child: Text(
        content,
        style: GoogleFonts.muli(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      onPressed: () {
        if (partner != null) launch(partner.link);
      },
    );
  }

  Widget getMainMenu() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 23),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          Expanded(
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              child: InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (ctx) => ActivityScreen()),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: <Widget>[
                      AppImages.productivePng.toPngImage(),
                      Container(height: 16),
                      Text(
                        'Mari Produktif',
                        style: GoogleFonts.muli(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColor.titleColor.toHexColor(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Container(width: 8),
          Expanded(
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              child: InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (ctx) => InformationScreen()),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: <Widget>[
                      AppImages.assestmentSvg.toSvgPicture(),
                      Container(height: 16),
                      Text(
                        'Update Corona',
                        style: GoogleFonts.muli(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColor.titleColor.toHexColor(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget getUserPin() {
    return Column(
      children: <Widget>[
        Expanded(child: Container(), flex: 12),
        Text(
          profile?.username ?? '...',
          style: GoogleFonts.muli(color: userNameColor),
        ),
        Container(height: 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              height: 8,
              width: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: HexColor('8EC13F'),
              ),
            ),
            Container(width: 4),
            Text(
              profile?.locationName ?? 'Unknown',
              style: GoogleFonts.raleway(
                color: userNameColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Container(height: 8),
        Stack(
          alignment: Alignment.center,
          children: <Widget>[
            AppImages.pinSvg.toSvgPicture(width: 52),
            Column(
              children: <Widget>[
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(21),
                  ),
                ),
                Container(height: 16),
              ],
            ),
            Column(
              children: <Widget>[
                CachedNetworkImage(
                  imageUrl: profile?.emblemImgUrl ?? '',
                  width: 42,
                  fit: BoxFit.fitWidth,
                ),
                Container(height: 16),
              ],
            ),
          ],
        ),
        Expanded(child: Container(), flex: 10),
      ],
    );
  }

  Row getTopbar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        getHelpButton(),
        getPageTitle(),
        getNotifButton(),
      ],
    );
  }

  Text getPageTitle() {
    return Text(
      'AYOK #DIRUMAHAJA',
      style: GoogleFonts.raleway(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: userNameColor == Colors.white
            ? userNameColor
            : AppColor.titleColor.toHexColor(),
      ),
    );
  }

  List<Widget> getBackgrounds() {
    return [
      Align(
        alignment: Alignment.bottomCenter,
        child: AppImages.homeBgMediumPng.toPngImage(
          width: double.infinity,
          fit: BoxFit.fitWidth,
        ),
      ),
      Align(
        alignment: Alignment.topCenter,
        child: AppImages.cloudBgPng.toPngImage(
          width: double.infinity,
          fit: BoxFit.fitWidth,
        ),
      ),
      if (skyGradient == AppColor.skyNoonGradient)
        AppImages.noonShadeSvg.toSvgPicture(
          width: double.infinity,
          fit: BoxFit.fill,
        ),
      if (skyGradient == AppColor.skyNightGradient)
        AppImages.nightShadeSvg.toSvgPicture(
          width: double.infinity,
          fit: BoxFit.fill,
        ),
    ];
  }

  Widget getHelpButton() {
    return RaisedButton(
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (ctx) => RuleScreen()),
        );
      },
      color: Colors.white,
      shape: CircleBorder(),
      child: AppImages.helpSvg.toSvgPicture(),
    );
  }

  Widget getNotifButton() {
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        RaisedButton(
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (ctx) => NotificationScreen(
                notifList,
                profile.username,
                profile.emblemImgUrl,
                downloadLink,
              ),
            ));
          },
          color: Colors.white,
          shape: CircleBorder(),
          child: AppImages.bellSvg.toSvgPicture(),
        ),
        if (notifList.isNotEmpty)
          Container(
            height: 12,
            width: 12,
            margin: const EdgeInsets.only(left: 26, bottom: 26),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: HexColor('FF5555'),
            ),
          ),
      ],
    );
  }
}
