import 'package:flutter/material.dart';

class RedeemPopup extends StatelessWidget {
  final String userName;
  final int redeemPoints;
  final String dateTime;

  RedeemPopup({
    required this.userName,
    required this.redeemPoints,
    required this.dateTime,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 50, color: Colors.black),
            SizedBox(height: 8),
            Text(
              "Tanda Terima Penukaran",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Divider(thickness: 1, color: Colors.black26),
            SizedBox(height: 12),
            _infoRow("username", "$userName"),
            SizedBox(height: 8),
            _infoRow("Penukaran Point", "$redeemPoints POIN", icon: Icons.stars),
            SizedBox(height: 8),
            _infoRow("Tanggal & waktu", dateTime, icon: Icons.calendar_today),
            SizedBox(height: 20),
            Divider(thickness: 1, color: Colors.black26),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _popupButton(context, "Close", Colors.green, Icons.close, () => Navigator.pop(context)),
                _popupButton(context, "Save", Colors.green, Icons.save, () {}),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String title, String value, {IconData? icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) Icon(icon, size: 20, color: Colors.black),
            if (icon != null) SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _popupButton(BuildContext context, String text, Color color, IconData icon, VoidCallback onPressed) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      icon: Icon(icon, size: 18, color: color),
      label: Text(text, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
    );
  }
}
