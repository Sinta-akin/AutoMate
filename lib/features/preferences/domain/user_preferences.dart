/// A customer's saved vehicle preferences (questionnaire + categories).
class UserPreferences {
  final int? minBudget;
  final int? maxBudget;
  final String? vehicleType;
  final String? primaryUse;
  final Set<String> categoryIds;
  final bool questionnaireCompleted;

  const UserPreferences({
    this.minBudget,
    this.maxBudget,
    this.vehicleType,
    this.primaryUse,
    this.categoryIds = const {},
    this.questionnaireCompleted = false,
  });

  UserPreferences copyWith({
    int? minBudget,
    int? maxBudget,
    String? vehicleType,
    String? primaryUse,
    Set<String>? categoryIds,
    bool? questionnaireCompleted,
  }) {
    return UserPreferences(
      minBudget: minBudget ?? this.minBudget,
      maxBudget: maxBudget ?? this.maxBudget,
      vehicleType: vehicleType ?? this.vehicleType,
      primaryUse: primaryUse ?? this.primaryUse,
      categoryIds: categoryIds ?? this.categoryIds,
      questionnaireCompleted:
      questionnaireCompleted ?? this.questionnaireCompleted,
    );
  }
}