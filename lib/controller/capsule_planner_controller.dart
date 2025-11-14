import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../models/capsule_plan.dart';
import '../services/hive_service.dart';
import '../services/preferences_service.dart';

class CapsulePlannerController extends GetxController {
  CapsulePlannerController(this._hiveService, this._preferencesService);

  final HiveService _hiveService;
  final PreferencesService _preferencesService;
  final _uuid = const Uuid();

  final plans = <CapsulePlan>[].obs;
  final accentColorHex = ''.obs;

  @override
  void onInit() {
    super.onInit();
    plans.assignAll(_hiveService.readCapsulePlans());
    final argb = _preferencesService.loadSeedColor(Colors.orange).toARGB32();
    final color = argb.toRadixString(16).padLeft(8, '0').toUpperCase();
    accentColorHex.value = color;
  }

  Future<void> savePlan({
    String? id,
    required String weekLabel,
    required String top,
    required String bottom,
    required String outer,
    required String accessories,
    required String colorHex,
  }) async {
    final plan = CapsulePlan(
      id: id ?? _uuid.v4(),
      weekLabel: weekLabel,
      top: top,
      bottom: bottom,
      outer: outer,
      accessories: accessories,
      colorHex: (colorHex.isNotEmpty ? colorHex : accentColorHex.value)
          .toUpperCase(),
      createdAt: DateTime.now(),
    );
    await _hiveService.saveCapsulePlan(plan);
    plans.assignAll(_hiveService.readCapsulePlans());
    accentColorHex.value = plan.colorHex;
  }

  Future<void> deletePlan(String id) async {
    await _hiveService.deleteCapsulePlan(id);
    plans.assignAll(_hiveService.readCapsulePlans());
  }
}
