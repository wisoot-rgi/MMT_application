import 'dart:math';

class CalTankThickness {
  static double calculateTankBlockThickness({
    required double tempInside,
    required double tempOutside,
    required double tempAir,
    required double qFlux,
    required double patchThk,
    required double airGap,
    required double kTank,
    required double kPatch,
    required bool isPatching,
  }) {
    // ==========================
    // Non-Patching
    // ==========================
    if (!isPatching) {
      double resistance =
          (tempInside - tempOutside) / qFlux;

      return resistance * kTank * 1000;
    }

    // ==========================
    // With-Patching
    // Rtotal = RAZS + Rgap + Rchrome
    // ==========================

    double meanTemp = (tempOutside + tempAir) / 2;
    double tempK = meanTemp + 273.15;

    // air conductivity
    double kAir = 0.024 + (7e-5 * meanTemp);

    // radiation conductivity in gap
    const sigma = 5.67e-8;
    double kRad = 4 * sigma * pow(tempK, 3) * (airGap / 1000);

    double kGap = kAir + kRad;

    // Resistances
    double rTotal = (tempInside - tempOutside) / qFlux;
    double rGap = (airGap / 1000) / kGap;
    double rChrome = (patchThk / 1000) / kPatch;

    // AZS resistance
    double rAZS = rTotal - rGap - rChrome;

    // AZS thickness
    return rAZS * kTank * 1000;
  }
}

class CalThickness {
  //------------------------------------------------
  // 1) Characteristic Length
  //------------------------------------------------
  static double calculateLCharacteristic({
    required double width,
    required double height,
  }) {
    if (width + height == 0) return 0;

    return (2 * width * height) / (width + height) / 1000;
  }

  //------------------------------------------------
  // Dynamic viscosity (Sutherland)
  //------------------------------------------------
  static double calculateDynamicViscosity({
    required double tempOutside,
    required double tempAir,
  }) {
    double meanTemp = (tempOutside + tempAir) / 2;
    double t = meanTemp + 273.15;

    const mu0 = 1.716e-5;
    const t0 = 273.15;
    const s = 111.0;

    return mu0 *
        pow(t / t0, 1.5) *
        ((t0 + s) / (t + s));
  }

  //------------------------------------------------
  // 2) Reynolds
  //------------------------------------------------
  static double calculateReynolds({
    required double velocity,
    required double tempAir,
    required double tempOutside,
    required double lChar,
  }) {
    double meanTemp = (tempOutside + tempAir) / 2;
    double tempK = meanTemp + 273.15;

    double rho = 101325 / (287.05 * tempK);

    double mu = calculateDynamicViscosity(
      tempOutside: tempOutside,
      tempAir: tempAir,
    );

    return (rho * velocity * lChar) / mu;
  }

  //------------------------------------------------
  // 3) Nusselt
  //------------------------------------------------
  static double calculateNusselt(double reynolds) {
    const pr = 0.70;

    return 0.023 * pow(reynolds, 0.8) * pow(pr, 0.4);
  }

  //------------------------------------------------
  // 4) hConv
  //------------------------------------------------
  static double calculateHConv({
    required double nusselt,
    required double tempOutside,
    required double tempAir,
    required double lChar,
  }) {
    if (lChar == 0) return 0;

    double meanTemp = (tempOutside + tempAir) / 2;
    double kAir = 0.024 + (7e-5 * meanTemp);

    return (nusselt * kAir) / lChar;
  }

  //------------------------------------------------
  // 5) hRad
  //------------------------------------------------
  static double calculateHRad({
    required double tempOutside,
    required double tempAir,
    double emissivity = 0.8,
  }) {
    const sigma = 5.67e-8;

    double ts = tempOutside + 273.15;
    double ta = tempAir + 273.15;

    return emissivity *
        sigma *
        (pow(ts, 2) + pow(ta, 2)) *
        (ts + ta);
  }

  //------------------------------------------------
  // 6) hTotal
  //------------------------------------------------
  static double calculateHTotal({
    required double hConv,
    required double hRad,
  }) {
    return hConv + hRad;
  }

  //------------------------------------------------
  // 7) qFlux
  //------------------------------------------------
  static double calculateQFlux({
    required double hTotal,
    required double tempOutside,
    required double tempAir,
  }) {
    return hTotal * (tempOutside - tempAir);
  }

  //------------------------------------------------
  // 8) Resistance
  //------------------------------------------------
  static double calculateResistance({
    required double tempInside,
    required double tempOutside,
    required double qFlux,
  }) {
    if (qFlux == 0) return 0;

    return (tempInside - tempOutside) / qFlux;
  }

  //------------------------------------------------
  // 9) AZS thickness
  //------------------------------------------------
  static double calculateAZSThickness({
    required double resistance,
    required double kTank,
  }) {
    return resistance * kTank * 1000;
  }
}