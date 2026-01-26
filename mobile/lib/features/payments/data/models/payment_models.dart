import 'package:freezed_annotation/freezed_annotation.dart';

part 'payment_models.freezed.dart';
part 'payment_models.g.dart';

/// Trainer's connected Stripe account status
@freezed
class StripeAccountModel with _$StripeAccountModel {
  const StripeAccountModel._();

  const factory StripeAccountModel({
    int? id,
    @JsonKey(name: 'trainer_email') String? trainerEmail,
    @JsonKey(name: 'stripe_account_id') String? stripeAccountId,
    @Default('pending') String status,
    @JsonKey(name: 'charges_enabled') @Default(false) bool chargesEnabled,
    @JsonKey(name: 'payouts_enabled') @Default(false) bool payoutsEnabled,
    @JsonKey(name: 'details_submitted') @Default(false) bool detailsSubmitted,
    @JsonKey(name: 'onboarding_completed') @Default(false) bool onboardingCompleted,
    @JsonKey(name: 'default_currency') @Default('usd') String defaultCurrency,
    @JsonKey(name: 'is_ready_for_payments') @Default(false) bool isReadyForPayments,
    @JsonKey(name: 'created_at') String? createdAt,
    @JsonKey(name: 'updated_at') String? updatedAt,
  }) = _StripeAccountModel;

  factory StripeAccountModel.fromJson(Map<String, dynamic> json) =>
      _$StripeAccountModelFromJson(json);

  bool get isActive => status == 'active';
  bool get isPending => status == 'pending';
  bool get isRestricted => status == 'restricted';
}

/// Response from Stripe Connect onboarding
@freezed
class StripeConnectResponse with _$StripeConnectResponse {
  const factory StripeConnectResponse({
    @JsonKey(name: 'onboarding_url') String? onboardingUrl,
    @JsonKey(name: 'stripe_account_id') String? stripeAccountId,
    @JsonKey(name: 'dashboard_url') String? dashboardUrl,
    String? error,
  }) = _StripeConnectResponse;

  factory StripeConnectResponse.fromJson(Map<String, dynamic> json) =>
      _$StripeConnectResponseFromJson(json);
}

/// Stripe Connect account status response
@freezed
class StripeConnectStatusResponse with _$StripeConnectStatusResponse {
  const factory StripeConnectStatusResponse({
    @Default(false) bool connected,
    String? status,
    String? message,
    int? id,
    @JsonKey(name: 'trainer_email') String? trainerEmail,
    @JsonKey(name: 'stripe_account_id') String? stripeAccountId,
    @JsonKey(name: 'charges_enabled') @Default(false) bool chargesEnabled,
    @JsonKey(name: 'payouts_enabled') @Default(false) bool payoutsEnabled,
    @JsonKey(name: 'details_submitted') @Default(false) bool detailsSubmitted,
    @JsonKey(name: 'onboarding_completed') @Default(false) bool onboardingCompleted,
    @JsonKey(name: 'is_ready_for_payments') @Default(false) bool isReadyForPayments,
  }) = _StripeConnectStatusResponse;

  factory StripeConnectStatusResponse.fromJson(Map<String, dynamic> json) =>
      _$StripeConnectStatusResponseFromJson(json);
}

/// Trainer's pricing configuration
@freezed
class TrainerPricingModel with _$TrainerPricingModel {
  const TrainerPricingModel._();

  const factory TrainerPricingModel({
    int? id,
    @JsonKey(name: 'trainer_email') String? trainerEmail,
    @JsonKey(name: 'monthly_subscription_price') @Default('0.00') String monthlySubscriptionPrice,
    @JsonKey(name: 'monthly_subscription_enabled') @Default(false) bool monthlySubscriptionEnabled,
    @JsonKey(name: 'one_time_consultation_price') @Default('0.00') String oneTimeConsultationPrice,
    @JsonKey(name: 'one_time_consultation_enabled') @Default(false) bool oneTimeConsultationEnabled,
    @JsonKey(name: 'stripe_monthly_price_id') String? stripeMonthlyPriceId,
    @Default('usd') String currency,
    @JsonKey(name: 'created_at') String? createdAt,
    @JsonKey(name: 'updated_at') String? updatedAt,
  }) = _TrainerPricingModel;

  factory TrainerPricingModel.fromJson(Map<String, dynamic> json) =>
      _$TrainerPricingModelFromJson(json);

  double get monthlyPrice => double.tryParse(monthlySubscriptionPrice) ?? 0.0;
  double get oneTimePrice => double.tryParse(oneTimeConsultationPrice) ?? 0.0;

  String get formattedMonthlyPrice => '\$${monthlyPrice.toStringAsFixed(2)}/mo';
  String get formattedOneTimePrice => '\$${oneTimePrice.toStringAsFixed(2)}';
}

/// Public trainer pricing info (for trainees)
@freezed
class TrainerPublicPricingModel with _$TrainerPublicPricingModel {
  const TrainerPublicPricingModel._();

  const factory TrainerPublicPricingModel({
    @JsonKey(name: 'trainer_id') required int trainerId,
    @JsonKey(name: 'trainer_name') String? trainerName,
    @JsonKey(name: 'trainer_email') String? trainerEmail,
    @JsonKey(name: 'monthly_subscription_price') @Default('0.00') String monthlySubscriptionPrice,
    @JsonKey(name: 'monthly_subscription_enabled') @Default(false) bool monthlySubscriptionEnabled,
    @JsonKey(name: 'one_time_consultation_price') @Default('0.00') String oneTimeConsultationPrice,
    @JsonKey(name: 'one_time_consultation_enabled') @Default(false) bool oneTimeConsultationEnabled,
    @Default('usd') String currency,
    @JsonKey(name: 'has_stripe_account') @Default(false) bool hasStripeAccount,
  }) = _TrainerPublicPricingModel;

  factory TrainerPublicPricingModel.fromJson(Map<String, dynamic> json) =>
      _$TrainerPublicPricingModelFromJson(json);

  double get monthlyPrice => double.tryParse(monthlySubscriptionPrice) ?? 0.0;
  double get oneTimePrice => double.tryParse(oneTimeConsultationPrice) ?? 0.0;

  bool get canAcceptPayments => hasStripeAccount;
  bool get hasAnyOffering => monthlySubscriptionEnabled || oneTimeConsultationEnabled;
}

/// Trainee payment record
@freezed
class TraineePaymentModel with _$TraineePaymentModel {
  const TraineePaymentModel._();

  const factory TraineePaymentModel({
    required int id,
    @JsonKey(name: 'trainee_email') String? traineeEmail,
    @JsonKey(name: 'trainer_email') String? trainerEmail,
    @JsonKey(name: 'trainer_name') String? trainerName,
    @JsonKey(name: 'payment_type') required String paymentType,
    required String status,
    required String amount,
    @JsonKey(name: 'platform_fee') @Default('0.00') String platformFee,
    @Default('usd') String currency,
    String? description,
    @JsonKey(name: 'created_at') String? createdAt,
    @JsonKey(name: 'paid_at') String? paidAt,
  }) = _TraineePaymentModel;

  factory TraineePaymentModel.fromJson(Map<String, dynamic> json) =>
      _$TraineePaymentModelFromJson(json);

  double get amountValue => double.tryParse(amount) ?? 0.0;
  String get formattedAmount => '\$${amountValue.toStringAsFixed(2)}';

  bool get isSubscription => paymentType == 'subscription';
  bool get isOneTime => paymentType == 'one_time';
  bool get isSucceeded => status == 'succeeded';
  bool get isPending => status == 'pending';
  bool get isFailed => status == 'failed';
}

/// Trainee subscription to a trainer
@freezed
class TraineeSubscriptionModel with _$TraineeSubscriptionModel {
  const TraineeSubscriptionModel._();

  const factory TraineeSubscriptionModel({
    required int id,
    @JsonKey(name: 'trainee_email') String? traineeEmail,
    @JsonKey(name: 'trainer_email') String? trainerEmail,
    @JsonKey(name: 'trainer_name') String? trainerName,
    required String status,
    required String amount,
    @Default('usd') String currency,
    @JsonKey(name: 'current_period_start') String? currentPeriodStart,
    @JsonKey(name: 'current_period_end') String? currentPeriodEnd,
    @JsonKey(name: 'days_until_renewal') int? daysUntilRenewal,
    @JsonKey(name: 'is_active') @Default(false) bool isActive,
    @JsonKey(name: 'canceled_at') String? canceledAt,
    @JsonKey(name: 'created_at') String? createdAt,
    @JsonKey(name: 'updated_at') String? updatedAt,
  }) = _TraineeSubscriptionModel;

  factory TraineeSubscriptionModel.fromJson(Map<String, dynamic> json) =>
      _$TraineeSubscriptionModelFromJson(json);

  double get amountValue => double.tryParse(amount) ?? 0.0;
  String get formattedAmount => '\$${amountValue.toStringAsFixed(2)}/mo';

  bool get isActiveStatus => status == 'active';
  bool get isPastDue => status == 'past_due';
  bool get isCanceled => status == 'canceled';
  bool get isPaused => status == 'paused';
}

/// Response from creating a checkout session
@freezed
class CheckoutSessionResponse with _$CheckoutSessionResponse {
  const factory CheckoutSessionResponse({
    @JsonKey(name: 'checkout_url') String? checkoutUrl,
    @JsonKey(name: 'session_id') String? sessionId,
    String? error,
  }) = _CheckoutSessionResponse;

  factory CheckoutSessionResponse.fromJson(Map<String, dynamic> json) =>
      _$CheckoutSessionResponseFromJson(json);
}
