# Privacy Policy — TouchifyMouse

**Effective date:** 2026-04-25
**Last updated:** 2026-04-25
**Contact:** aitools.deventiatech@gmail.com

This Privacy Policy describes how the TouchifyMouse mobile app ("the app",
"we", "us") handles information when you use it. The app turns your phone
into a wireless trackpad, keyboard, microphone, and remote speaker for a
desktop computer running the TouchifyMouse desktop companion on the same
local Wi-Fi network.

## 1. Summary

- We do **not** run our own servers and we do **not** collect any personal
  data on servers we control.
- All trackpad input, keystrokes, audio, and pairing data flow **directly**
  between your phone and your own desktop computer over your local Wi-Fi
  network. None of it leaves your network.
- We do **not** sell, share, or transfer your personal information to third
  parties for their independent use.

## 2. Permissions and how we use them

### Camera (`android.permission.CAMERA`)
Used **only** to scan the pairing QR code shown by the desktop companion app.
Camera frames are processed on-device by the Google ML Kit barcode scanner
embedded in the app and are **not stored, recorded, transmitted, or sent
anywhere**. The camera is only active while the QR scan sheet is open.

### Microphone (`android.permission.RECORD_AUDIO`)
Used **only** when you explicitly enable the "Use phone as microphone"
feature. Audio captured from your phone's microphone is streamed in real
time over your local Wi-Fi to the paired desktop computer that you own.
Audio is **not** recorded, persisted, or sent to any third-party server.
The microphone is silent until you toggle the feature on, and stops
immediately when you toggle it off or disconnect.

### Network (`INTERNET`, `ACCESS_WIFI_STATE`, `ACCESS_NETWORK_STATE`,
`CHANGE_WIFI_MULTICAST_STATE`)
Used to discover and connect to the desktop companion on your local Wi-Fi
via mDNS (Bonjour) and to maintain the TCP/UDP connection that carries
trackpad, keyboard, media, and audio data. The internet permission is also
required by Google AdMob and Google Play Billing (see §3).

## 3. Third-party services

### Google AdMob
The app displays advertisements through Google AdMob. AdMob may collect and
process information such as advertising ID, IP address, coarse location
(derived from IP), device type, and basic interaction events for ad
delivery, frequency capping, and fraud prevention. Google's handling of
this data is governed by Google's own privacy policy:
https://policies.google.com/privacy

You can reset your Android Advertising ID, opt out of personalised ads, or
delete it at any time from your Android device settings under
**Settings → Privacy → Ads**.

### Google Play Billing (in-app purchases)
If you make an in-app purchase, the transaction is handled by Google Play.
We receive a confirmation token from Google to unlock the purchased
feature, but we do **not** receive or store your payment-card details.
Google's handling of payment data is governed by Google's privacy policy.

### Google Play Services
The app uses Google Play Services and Google ML Kit (for QR decoding).
These are governed by Google's privacy policy.

## 4. Data we do NOT collect

We do not collect, store, or transmit:
- Your name, email, phone number, or address.
- Account credentials.
- Photos, videos, contacts, calendar, files, or SMS.
- Precise GPS location.
- Health, biometric, or financial information.
- Crash logs, telemetry, or analytics on servers we control.

## 5. Data on your device

The app stores small, non-sensitive preferences locally on your device
using Android's standard `SharedPreferences` (e.g. selected theme, pointer
sensitivity, last connected device). This data never leaves your phone and
is removed when you uninstall the app.

## 6. Children's privacy

The app is not directed to children under 13 (or the equivalent minimum
age in your jurisdiction). We do not knowingly collect personal information
from children. If you believe a child has provided personal information,
contact us and we will take steps to address it.

## 7. Security

Connections to your desktop companion happen over your own local Wi-Fi
network. We recommend you use a trusted, password-protected Wi-Fi network.
We do not use TLS for the local connection because the data never leaves
the LAN; please ensure your home/office Wi-Fi is properly secured.

## 8. Your rights

Because we do not collect personal data on our servers, there is nothing
for us to access, export, or delete on your behalf. To control AdMob and
Google Play data, use your Android device settings and your Google account
controls (https://myaccount.google.com).

To delete all app data on your device, go to **Settings → Apps →
TouchifyMouse → Storage → Clear Data**, or simply uninstall the app.

## 9. Changes to this policy

We may update this policy from time to time. Material changes will be
indicated by a revised "Last updated" date at the top. Continued use of
the app after changes are posted constitutes acceptance of the revised
policy.

## 10. Contact

For questions or concerns about this Privacy Policy or how the app
handles data:

**Email:** aitools.deventiatech@gmail.com
