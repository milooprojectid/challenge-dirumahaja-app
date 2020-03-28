import 'package:dirumahaja/core/res/app_color.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_color/flutter_color.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      child: Column(
        children: <Widget>[
          Container(height: 64),
          Text(
            'Siapa Kamu?',
            textAlign: TextAlign.center,
            style: GoogleFonts.raleway(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: AppColor.titleColor.toHexColor(),
            ),
          ),
          Container(height: 32),
          getRuleBox(),
        ],
      ),
    );
  }

  Widget getRuleBox() {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 46),
      child: Container(
        // height: 420,
        padding: const EdgeInsets.all(26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Username'),
            TextField(),
            Text('Umur'),
            Row(
              children: <Widget>[
                Container(
                  child: TextField(),
                  width: 56,
                ),
                Text('Tahun'),
              ],
            ),
            Row(
              children: <Widget>[
                MaterialButton(
                  child: Text('Pria'),
                  color: HexColor('0165C0'),
                  onPressed: () {},
                ),
                MaterialButton(
                  child: Text('Wanita'),
                  color: HexColor('0165C0'),
                  onPressed: () {},
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}