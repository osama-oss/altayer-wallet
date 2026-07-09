import 'package:flutter/widgets.dart';

/// Local shim over the `phosphor_flutter` icon font.
///
/// The package's Dart code (`PhosphorIconData extends IconData`) no longer
/// compiles — `IconData` became a `final` class — and 2.1.0 is the latest
/// release. We keep the package as a dependency purely for its bundled
/// `PhosphorBold` font and declare the handful of glyphs we use as plain
/// [IconData]. Codepoints copied from the package's
/// `phosphor_icons_bold.dart`; same class name so call sites only swap the
/// import. Drop this file if the package ships a fixed release.
abstract final class PhosphorIconsBold {
  static const _family = 'PhosphorBold';
  static const _package = 'phosphor_flutter';

  static const airplaneTakeoff =
      IconData(0xe504, fontFamily: _family, fontPackage: _package);
  static const arrowsLeftRight =
      IconData(0xe0a0, fontFamily: _family, fontPackage: _package);
  static const bell =
      IconData(0xe0ce, fontFamily: _family, fontPackage: _package);
  static const chartLineUp =
      IconData(0xe156, fontFamily: _family, fontPackage: _package);
  static const chartPieSlice =
      IconData(0xe15a, fontFamily: _family, fontPackage: _package);
  static const creditCard =
      IconData(0xe1d2, fontFamily: _family, fontPackage: _package);
  static const eye =
      IconData(0xe220, fontFamily: _family, fontPackage: _package);
  static const eyeSlash =
      IconData(0xe224, fontFamily: _family, fontPackage: _package);
  static const fingerprint =
      IconData(0xe23e, fontFamily: _family, fontPackage: _package);
  static const gift =
      IconData(0xe276, fontFamily: _family, fontPackage: _package);
  static const houseSimple =
      IconData(0xe2c6, fontFamily: _family, fontPackage: _package);
  static const magnifyingGlass =
      IconData(0xe30c, fontFamily: _family, fontPackage: _package);
  static const medal =
      IconData(0xe320, fontFamily: _family, fontPackage: _package);
  static const percent =
      IconData(0xe3b6, fontFamily: _family, fontPackage: _package);
  static const receipt =
      IconData(0xe3ec, fontFamily: _family, fontPackage: _package);
  static const slidersHorizontal =
      IconData(0xe434, fontFamily: _family, fontPackage: _package);
  static const vault =
      IconData(0xe76e, fontFamily: _family, fontPackage: _package);
  static const wallet =
      IconData(0xe68a, fontFamily: _family, fontPackage: _package);
}
