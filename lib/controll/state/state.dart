import 'package:flutter/material.dart';
import 'package:location/location.dart';

class MyProvider extends ChangeNotifier {
  var _isEnableLocation = false;
  var _locationData = LocationData.fromMap(<String, dynamic>{});
  var _isLoading = false;

  bool get isEnableLocation => _isEnableLocation;
  LocationData get locationData => _locationData;
  bool get isLoading => _isLoading;

  set isEnableLocation(bool value) {
    _isEnableLocation = value;
    notifyListeners();
  }

  set locationData(LocationData value) {
    _locationData = value;
    notifyListeners();
  }

  set isLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
