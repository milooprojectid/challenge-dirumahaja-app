import 'dart:math';

import 'package:dirumahaja/core/entity/entity_checkin.dart';
import 'package:dirumahaja/core/network/api.dart';
import 'package:dirumahaja/core/network/base_result.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class LocationUpdater {
  static void doCheckIn({
    String source = 'home',
    Function(BaseResult) onResult,
  }) async {
    final location = await Geolocator().getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    // final randHour = Random().nextInt(23) + 1;
    final user = await FirebaseAuth.instance.currentUser();
    // final nextCheckIn = DateTime.now().add(Duration(hours: randHour));

    final checkInResult = await Api().post<CheckIn>(
      path: '/session/checkin',
      dataParser: CheckIn.fromMap,
      headers: {'uid': user.uid},
      body: {
        "coordinate": "${location.latitude}, ${location.longitude}",
        // "next_checkin": nextCheckIn.toString(),
      },
    );

    // print(
    //   "[dirumahaja]: send coordinate = $source: ${location.latitude}, ${location.longitude}",
    // );

    onResult?.call(checkInResult);
  }
}
