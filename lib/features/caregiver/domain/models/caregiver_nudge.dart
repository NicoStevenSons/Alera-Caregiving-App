enum CaregiverNudgeType {
  drinkWater('DRINK_WATER', 'Drink water 💧'),
  takeMedication('TAKE_MEDICATION', 'Take medication 💊'),
  checkBloodPressure('CHECK_BLOOD_PRESSURE', 'Check blood pressure 🩺');

  final String apiValue;
  final String label;

  const CaregiverNudgeType(this.apiValue, this.label);
}
