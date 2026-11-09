/// What the device can afford to run. Implemented in the data layer.
abstract interface class DeviceCapability {
  /// Total physical RAM in megabytes, or `null` if unknown.
  Future<int?> totalRamMb();
}
