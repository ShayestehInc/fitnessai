// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'FitnessAI';

  @override
  String get authLoginTitle => 'Bienvenido de Nuevo';

  @override
  String get authLoginSubtitle => 'Inicia sesión en tu cuenta';

  @override
  String get authEmailLabel => 'Correo Electrónico';

  @override
  String get authEmailHint => 'Ingresa tu correo electrónico';

  @override
  String get authPasswordLabel => 'Contraseña';

  @override
  String get authPasswordHint => 'Ingresa tu contraseña';

  @override
  String get authLoginButton => 'Iniciar Sesión';

  @override
  String get authForgotPassword => '¿Olvidaste tu contraseña?';

  @override
  String get authNoAccount => '¿No tienes una cuenta?';

  @override
  String get authSignUp => 'Regístrate';

  @override
  String get authRegisterTitle => 'Crear Cuenta';

  @override
  String get authRegisterSubtitle => 'Únete a FitnessAI hoy';

  @override
  String get authFirstNameLabel => 'Nombre';

  @override
  String get authLastNameLabel => 'Apellido';

  @override
  String get authConfirmPasswordLabel => 'Confirmar Contraseña';

  @override
  String get authConfirmPasswordHint => 'Reingresa tu contraseña';

  @override
  String get authRegisterButton => 'Crear Cuenta';

  @override
  String get authHaveAccount => '¿Ya tienes una cuenta?';

  @override
  String get authSignIn => 'Iniciar Sesión';

  @override
  String get authForgotTitle => 'Restablecer Contraseña';

  @override
  String get authForgotSubtitle =>
      'Ingresa tu correo para recibir un enlace de restablecimiento';

  @override
  String get authSendResetLink => 'Enviar Enlace';

  @override
  String get authResetSent => 'Enlace de restablecimiento enviado a tu correo';

  @override
  String get authBackToLogin => 'Volver al Inicio de Sesión';

  @override
  String get authOrContinueWith => 'O continuar con';

  @override
  String get authGoogle => 'Google';

  @override
  String get authApple => 'Apple';

  @override
  String get authLoginFailed =>
      'Error al iniciar sesión. Verifica tus credenciales.';

  @override
  String get authRegisterFailed =>
      'Error al registrarse. Por favor intenta de nuevo.';

  @override
  String get authInvalidEmail => 'Por favor ingresa un correo válido';

  @override
  String get authPasswordRequired => 'La contraseña es obligatoria';

  @override
  String get authPasswordTooShort =>
      'La contraseña debe tener al menos 8 caracteres';

  @override
  String get authPasswordsDoNotMatch => 'Las contraseñas no coinciden';

  @override
  String get onboardingAboutYou => 'Sobre Ti';

  @override
  String get onboardingActivityLevel => 'Nivel de Actividad';

  @override
  String get onboardingGoals => 'Tus Objetivos';

  @override
  String get onboardingDiet => 'Preferencias de Dieta';

  @override
  String get onboardingNext => 'Siguiente';

  @override
  String get onboardingBack => 'Atrás';

  @override
  String get onboardingFinish => 'Finalizar Configuración';

  @override
  String get onboardingSexLabel => 'Sexo';

  @override
  String get onboardingSexMale => 'Masculino';

  @override
  String get onboardingSexFemale => 'Femenino';

  @override
  String get onboardingAgeLabel => 'Edad';

  @override
  String get onboardingHeightLabel => 'Altura (cm)';

  @override
  String get onboardingWeightLabel => 'Peso (kg)';

  @override
  String get onboardingSedentary => 'Sedentario';

  @override
  String get onboardingSedentaryDesc => 'Poco o nada de ejercicio';

  @override
  String get onboardingLightlyActive => 'Ligeramente Activo';

  @override
  String get onboardingLightlyActiveDesc => 'Ejercicio ligero 1-3 días/semana';

  @override
  String get onboardingModeratelyActive => 'Moderadamente Activo';

  @override
  String get onboardingModeratelyActiveDesc =>
      'Ejercicio moderado 3-5 días/semana';

  @override
  String get onboardingVeryActive => 'Muy Activo';

  @override
  String get onboardingVeryActiveDesc => 'Ejercicio intenso 6-7 días/semana';

  @override
  String get onboardingExtremelyActive => 'Extremadamente Activo';

  @override
  String get onboardingExtremelyActiveDesc =>
      'Ejercicio muy intenso y trabajo físico';

  @override
  String get onboardingBuildMuscle => 'Ganar Músculo';

  @override
  String get onboardingBuildMuscleDesc => 'Ganar masa muscular magra';

  @override
  String get onboardingFatLoss => 'Perder Grasa';

  @override
  String get onboardingFatLossDesc => 'Reducir porcentaje de grasa corporal';

  @override
  String get onboardingRecomp => 'Recomposición';

  @override
  String get onboardingRecompDesc => 'Ganar músculo mientras pierdes grasa';

  @override
  String get onboardingLowCarb => 'Bajo en Carbohidratos';

  @override
  String get onboardingBalanced => 'Balanceada';

  @override
  String get onboardingHighCarb => 'Alto en Carbohidratos';

  @override
  String get onboardingMealsPerDay => 'Comidas por Día';

  @override
  String onboardingStepOf(int current, int total) {
    return 'Paso $current de $total';
  }

  @override
  String get homeTitle => 'Inicio';

  @override
  String get homeGoodMorning => 'Buenos Días';

  @override
  String get homeGoodAfternoon => 'Buenas Tardes';

  @override
  String get homeGoodEvening => 'Buenas Noches';

  @override
  String get homeTodaysPlan => 'Plan de Hoy';

  @override
  String get homeQuickLog => 'Registro Rápido';

  @override
  String get homeRecentActivity => 'Actividad Reciente';

  @override
  String get homeNoActivity => 'Sin actividad todavía. ¡Comienza a registrar!';

  @override
  String homeStreak(int count) {
    return 'Racha de $count días';
  }

  @override
  String get navHome => 'Inicio';

  @override
  String get navDiet => 'Dieta';

  @override
  String get navLogbook => 'Registro';

  @override
  String get navCommunity => 'Comunidad';

  @override
  String get navMessages => 'Mensajes';

  @override
  String get navDashboard => 'Panel';

  @override
  String get navTrainees => 'Alumnos';

  @override
  String get navPrograms => 'Programas';

  @override
  String get navSettings => 'Ajustes';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsProfile => 'Perfil';

  @override
  String get settingsEditProfile => 'Editar Perfil';

  @override
  String get settingsAppearance => 'Apariencia';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get settingsThemeDark => 'Oscuro';

  @override
  String get settingsThemeLight => 'Claro';

  @override
  String get settingsThemeSystem => 'Sistema';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsLanguageSelect => 'Seleccionar Idioma';

  @override
  String get settingsNotifications => 'Notificaciones';

  @override
  String get settingsSecurity => 'Seguridad';

  @override
  String get settingsChangePassword => 'Cambiar Contraseña';

  @override
  String get settingsBiometric => 'Inicio Biométrico';

  @override
  String get settingsDeleteAccount => 'Eliminar Cuenta';

  @override
  String get settingsDeleteAccountWarning =>
      'Esta acción no se puede deshacer. Todos tus datos serán eliminados permanentemente.';

  @override
  String get settingsLogout => 'Cerrar Sesión';

  @override
  String get settingsLogoutConfirm =>
      '¿Estás seguro de que quieres cerrar sesión?';

  @override
  String settingsVersion(String version) {
    return 'Versión $version';
  }

  @override
  String get settingsFeatureRequests => 'Solicitudes de Funciones';

  @override
  String get settingsCalendar => 'Integración de Calendario';

  @override
  String get settingsBranding => 'Marca';

  @override
  String get settingsExerciseBank => 'Banco de Ejercicios';

  @override
  String get commonSave => 'Guardar';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonDelete => 'Eliminar';

  @override
  String get commonEdit => 'Editar';

  @override
  String get commonDone => 'Listo';

  @override
  String get commonClose => 'Cerrar';

  @override
  String get commonSearch => 'Buscar';

  @override
  String get commonFilter => 'Filtrar';

  @override
  String get commonAll => 'Todos';

  @override
  String get commonNone => 'Ninguno';

  @override
  String get commonYes => 'Sí';

  @override
  String get commonNo => 'No';

  @override
  String get commonOk => 'OK';

  @override
  String get commonRetry => 'Reintentar';

  @override
  String get commonConfirm => 'Confirmar';

  @override
  String get commonLoading => 'Cargando...';

  @override
  String get commonError => 'Algo salió mal';

  @override
  String get commonErrorTryAgain =>
      'Algo salió mal. Por favor intenta de nuevo.';

  @override
  String get commonNoResults => 'No se encontraron resultados';

  @override
  String get commonEmpty => 'Nada aquí todavía';

  @override
  String get commonSuccess => 'Éxito';

  @override
  String get commonSaved => 'Cambios guardados';

  @override
  String get commonDeleted => 'Eliminado exitosamente';

  @override
  String get commonCopied => 'Copiado al portapapeles';

  @override
  String get commonViewAll => 'Ver Todo';

  @override
  String get commonRequired => 'Este campo es obligatorio';

  @override
  String get commonBack => 'Atrás';

  @override
  String get commonNext => 'Siguiente';

  @override
  String get commonSubmit => 'Enviar';

  @override
  String get commonRefresh => 'Actualizar';

  @override
  String get commonMore => 'Más';

  @override
  String get commonLess => 'Menos';

  @override
  String get commonToday => 'Hoy';

  @override
  String get commonYesterday => 'Ayer';

  @override
  String commonDaysAgo(int count) {
    return 'Hace $count días';
  }

  @override
  String get commonNeverActive => 'Nunca activo';

  @override
  String get commonNoData => 'No hay datos disponibles';

  @override
  String get trainerDashboard => 'Panel del Entrenador';

  @override
  String get trainerTrainees => 'Alumnos';

  @override
  String get trainerInviteTrainee => 'Invitar Alumno';

  @override
  String get trainerNoTrainees => 'Sin Alumnos Aún';

  @override
  String get trainerNoTraineesDesc => 'Invita a tu primer alumno para comenzar';

  @override
  String get trainerAtRiskTrainees => 'Alumnos en Riesgo';

  @override
  String get trainerRetentionAnalytics => 'Análisis de Retención';

  @override
  String get trainerAnnouncements => 'Anuncios';

  @override
  String get trainerManageAnnouncements => 'Gestionar Anuncios';

  @override
  String get trainerBroadcastDesc =>
      'Enviar actualizaciones a todos tus alumnos';

  @override
  String get trainerAiAssistant => 'Asistente IA';

  @override
  String get trainerPrograms => 'Programas';

  @override
  String get trainerExercises => 'Ejercicios';

  @override
  String get nutritionCalories => 'Calorías';

  @override
  String get nutritionProtein => 'Proteína';

  @override
  String get nutritionCarbs => 'Carbohidratos';

  @override
  String get nutritionFat => 'Grasa';

  @override
  String get nutritionMacros => 'Macros';

  @override
  String get nutritionGoal => 'Objetivo';

  @override
  String get nutritionRemaining => 'Restante';

  @override
  String get nutritionConsumed => 'Consumido';

  @override
  String get nutritionLogFood => 'Registrar Alimento';

  @override
  String get nutritionWeightCheckIn => 'Registro de Peso';

  @override
  String get workoutStartWorkout => 'Iniciar Entrenamiento';

  @override
  String get workoutCompleteWorkout => 'Completar Entrenamiento';

  @override
  String get workoutSets => 'Series';

  @override
  String get workoutReps => 'Repeticiones';

  @override
  String get workoutWeight => 'Peso';

  @override
  String get workoutRestTimer => 'Temporizador de Descanso';

  @override
  String get workoutHistory => 'Historial de Entrenamientos';

  @override
  String get workoutNoProgram => 'Sin programa asignado';

  @override
  String get workoutNoProgramDesc =>
      'Pide a tu entrenador que te asigne un programa';

  @override
  String get errorNetworkError => 'Error de red. Verifica tu conexión.';

  @override
  String get errorSessionExpired =>
      'Sesión expirada. Por favor inicia sesión de nuevo.';

  @override
  String get errorPermissionDenied => 'Permiso denegado';

  @override
  String get errorNotFound => 'No encontrado';

  @override
  String get errorServerError =>
      'Error del servidor. Por favor intenta más tarde.';

  @override
  String get errorUnknown => 'Ocurrió un error desconocido';

  @override
  String get languageEnglish => 'Inglés';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languagePortuguese => 'Portugués (Brasil)';

  @override
  String get languageChanged => 'Idioma cambiado exitosamente';

  @override
  String get adminActive => 'Active';

  @override
  String get adminAddNotesAboutThisSubscription =>
      'Add notes about this subscription...';

  @override
  String get adminAdmin => 'Admin';

  @override
  String get adminAdminDashboard => 'Panel de Administrador';

  @override
  String get adminAllTrainersTrainees => 'All (Trainers & Trainees)';

  @override
  String get adminAmbassadorDetail => 'Ambassador Detail';

  @override
  String get adminAmbassadorexampleCom => 'ambassador@example.com';

  @override
  String get adminAmbassadors => 'Ambassadors';

  @override
  String get adminAmount => 'Amount';

  @override
  String get adminAppliesTo => 'Applies To';

  @override
  String get adminApprove => 'Approve';

  @override
  String get adminApproveAll => 'Approve All';

  @override
  String get adminApproveAllPending => 'Approve All Pending';

  @override
  String get adminApproveCommission => 'Approve Commission';

  @override
  String get adminAreYouSureYouWantToDeleteEmail =>
      'Are you sure you want to delete \$_email?';

  @override
  String get adminBasicAnalyticsnEmailSupportn =>
      'Basic analytics\\nEmail support\\n...';

  @override
  String get adminBriefDescriptionOfThisTier =>
      'Brief description of this tier';

  @override
  String get adminChangeStatus => 'Change Status';

  @override
  String get adminChangeTier => 'Change Tier';

  @override
  String get adminClear => 'Limpiar';

  @override
  String get adminClearAll => 'Clear All';

  @override
  String get adminClearPastDue => 'Clear Past Due';

  @override
  String get adminCodeCopiedToClipboard => 'Code copied to clipboard';

  @override
  String get adminCommissionApproved => 'Commission approved';

  @override
  String get adminCommissionMarkedAsPaid => 'Commission marked as paid';

  @override
  String get adminContinue => 'Continue';

  @override
  String get adminCopyCode => 'Copy code';

  @override
  String get adminCouponCode => 'Coupon Code';

  @override
  String get adminCouponCreated => 'Coupon created';

  @override
  String get adminCouponDeleted => 'Coupon deleted';

  @override
  String get adminCouponNotFound => 'Coupon not found';

  @override
  String get adminCouponReactivated => 'Coupon reactivated';

  @override
  String get adminCouponRevoked => 'Coupon revoked';

  @override
  String get adminCoupons => 'Coupons';

  @override
  String get adminCreate => 'Create';

  @override
  String get adminCreateAmbassador => 'Crear Embajador';

  @override
  String get adminCreateCoupon => 'Crear Cupón';

  @override
  String get adminCreateDefaultTiers => 'Create Default Tiers';

  @override
  String get adminCreateUser => 'Crear Usuario';

  @override
  String get adminDefaultTiersCreated => 'Default tiers created';

  @override
  String get adminDeleteCoupon => 'Delete Coupon';

  @override
  String get adminDeleteTier => 'Delete Tier';

  @override
  String get adminDeleteUser => 'Delete User';

  @override
  String get adminDescription => 'Description';

  @override
  String get adminDescriptionOptional => 'Description (optional)';

  @override
  String get adminDiscountType => 'Discount Type';

  @override
  String get adminDisplayName => 'Display Name';

  @override
  String get adminEGManualPaymentViaCheck => 'e.g., Manual payment via check';

  @override
  String get adminEGPROSTARTER => 'e.g., PRO, STARTER';

  @override
  String get adminEGProfessional => 'e.g., Professional';

  @override
  String get adminEGSAVE20 => 'e.g., SAVE20';

  @override
  String get adminEarnings => 'Earnings';

  @override
  String get adminEditCommissionRate => 'Edit Commission Rate';

  @override
  String get adminEditNotes => 'Edit Notes';

  @override
  String get adminEditUser => 'Editar Usuario';

  @override
  String get adminExhausted => 'Exhausted';

  @override
  String get adminExpired => 'Expired';

  @override
  String get adminExpiryDateOptional => 'Expiry Date (optional)';

  @override
  String get adminFailedToBulkApproveCommissionsPleaseTryAgain =>
      'Failed to bulk approve commissions. Please try again.';

  @override
  String get adminFailedToBulkPayCommissionsPleaseTryAgain =>
      'Failed to bulk pay commissions. Please try again.';

  @override
  String get adminFailedToactionLabelAmbassadorPleaseTryAgain =>
      'Failed to \$actionLabel ambassador. Please try again.';

  @override
  String get adminFeaturesOnePerLine => 'Features (one per line)';

  @override
  String get adminFilterByStatus => 'Filter by Status';

  @override
  String get adminFixedAmountOff => 'Fixed Amount Off';

  @override
  String get adminFreeTrialDays => 'Free Trial Days';

  @override
  String get adminInactive => 'Inactive';

  @override
  String get adminInactiveTiersCannotBePurchased =>
      'Inactive tiers cannot be purchased';

  @override
  String get adminInternalDescription => 'Internal description';

  @override
  String get adminLeaveBlankToKeepCurrentPassword =>
      'Leave blank to keep current password';

  @override
  String get adminLoginAsTrainer => 'Login as Trainer';

  @override
  String get adminManageUsers => 'Manage Users';

  @override
  String get adminMarkCommissionAsPaid => 'Mark Commission as Paid';

  @override
  String get adminMarkPaid => 'Mark Paid';

  @override
  String get adminMaxUses0Unlimited => 'Max Uses (0 = unlimited)';

  @override
  String get adminNewStatus => 'New Status';

  @override
  String get adminNewTier => 'New Tier';

  @override
  String get adminNotesUpdatedSuccessfully => 'Notes updated successfully';

  @override
  String get adminPastDueAccounts => 'Past Due Accounts';

  @override
  String get adminPastDueClearedSuccessfully => 'Past due cleared successfully';

  @override
  String get adminPayAll => 'Pay All';

  @override
  String get adminPayAllApproved => 'Pay All Approved';

  @override
  String get adminPaymentRecordedSuccessfully =>
      'Payment recorded successfully';

  @override
  String get adminPercentageOff => 'Porcentaje de Descuento';

  @override
  String get adminPleaseFixTheErrorsBeforeContinuing =>
      'Please fix the errors before continuing';

  @override
  String get adminPriceMonth => 'Price (\\\$/month)';

  @override
  String get adminRate => 'Rate';

  @override
  String get adminReactivate => 'Reactivate';

  @override
  String get adminReasonOptional => 'Reason (optional)';

  @override
  String get adminRecord => 'Record';

  @override
  String get adminRecordPayment => 'Record Payment';

  @override
  String get adminReferrals => 'Referrals';

  @override
  String get adminReminderSent => 'Reminder sent';

  @override
  String get adminReturnedToAdminAccount => 'Returned to admin account';

  @override
  String get adminRevoke => 'Revoke';

  @override
  String get adminRevokeCoupon => 'Revoke Coupon';

  @override
  String get adminRevoked => 'Revoked';

  @override
  String get adminSaveChanges => 'Guardar Cambios';

  @override
  String get adminSearchByEmail => 'Search by email...';

  @override
  String get adminSearchByNameOrEmail => 'Search by name or email...';

  @override
  String get adminSeedDefaults => 'Seed Defaults';

  @override
  String get adminSelectRole => 'Select Role';

  @override
  String get adminSendReminder => 'Send Reminder';

  @override
  String get adminSetPassword => 'Set Password';

  @override
  String get adminShareThisWithTheAmbassadorSoTheyCanLogIn =>
      'Share this with the ambassador so they can log in';

  @override
  String get adminStatusUpdatedSuccessfully => 'Status updated successfully';

  @override
  String get adminSubscriptionDetails => 'Detalles de la Suscripción';

  @override
  String get adminSubscriptionNotFound => 'Subscription not found';

  @override
  String get adminSubscriptionTiers => 'Subscription Tiers';

  @override
  String get adminSubscriptions => 'Subscriptions';

  @override
  String get adminTapToReload => 'Tap to reload';

  @override
  String get adminTemporaryPassword => 'Temporary Password';

  @override
  String get adminTierDeleted => 'Tier deleted';

  @override
  String get adminTierNameInternal => 'Tier Name (Internal)';

  @override
  String get adminTierUpdatedSuccessfully => 'Tier updated successfully';

  @override
  String get adminTiers => 'Tiers';

  @override
  String get adminTraineeCoachingOnly => 'Trainee Coaching Only';

  @override
  String get adminTraineeLimit => 'Trainee Limit';

  @override
  String get adminTrainer => 'Trainer';

  @override
  String get adminTrainerSubscriptionsOnly => 'Trainer Subscriptions Only';

  @override
  String get adminTrainers => 'Trainers';

  @override
  String get adminUpcomingPayments => 'Próximos Pagos';

  @override
  String get adminUserDeletedSuccessfully => 'User deleted successfully';

  @override
  String get adminUserDetails => 'Detalles del Usuario';

  @override
  String get adminUserUpdatedSuccessfully => 'User updated successfully';

  @override
  String get adminUsers => 'Users';

  @override
  String get adminViewSubscription => 'View Subscription';

  @override
  String get aiChatAllTrainees => 'All trainees';

  @override
  String get aiChatAreYouSureYouWantToClearTheConversationHistor =>
      'Are you sure you want to clear the conversation history?';

  @override
  String get aiChatClearConversation => 'Clear conversation';

  @override
  String get aiChatClearConversation2 => 'Clear Conversation';

  @override
  String get aiChatSearchTrainees => 'Search trainees...';

  @override
  String get ambassadorAmbassadorDashboard => 'Panel del Embajador';

  @override
  String get ambassadorChangeReferralCode => 'Change Referral Code';

  @override
  String get ambassadorEditReferralCode => 'Edit referral code';

  @override
  String get ambassadorFailedToStartStripeOnboarding =>
      'Failed to start Stripe onboarding';

  @override
  String get ambassadorLogOutOfYourAccount => 'Log out of your account';

  @override
  String get ambassadorMyReferrals => 'My Referrals';

  @override
  String get ambassadorNoEarningsDataYet => 'No earnings data yet';

  @override
  String get ambassadorOpeningStripeOnboardingCompleteSetupInBrowser =>
      'Opening Stripe onboarding... Complete setup in browser.';

  @override
  String get ambassadorPayouts => 'Payouts';

  @override
  String get ambassadorReferralCode => 'Referral Code';

  @override
  String get ambassadorReferralCodeCopied => 'Referral code copied!';

  @override
  String get ambassadorReferralCodeUpdatedTocode =>
      'Referral code updated to \$code';

  @override
  String get ambassadorReferralCodecode => 'Referral Code: \$code';

  @override
  String get ambassadorShareMessageCopiedToClipboard =>
      'Share message copied to clipboard!';

  @override
  String get ambassadorShareReferralCode => 'Share Referral Code';

  @override
  String get authConfirmPassword => 'Confirm password';

  @override
  String get authEmail => 'email';

  @override
  String get authEmailAddress => 'Email address';

  @override
  String get authEmailSentSuccessfully => 'Email sent successfully';

  @override
  String get authHaveAReferralCodeEnterItHere =>
      'Have a referral code? Enter it here.';

  @override
  String get authNewPassword => 'New password';

  @override
  String get authPassword => 'password';

  @override
  String get authPasswordResetIcon => 'Password reset icon';

  @override
  String get authReferralCodeOptional => 'Referral Code (Optional)';

  @override
  String get authRegister => 'Register';

  @override
  String get authResetToDefault => 'Reset to Default';

  @override
  String get authResetToDefaultURL => 'Reset to default URL';

  @override
  String get authRole => 'Role';

  @override
  String get authServerConfiguration => 'Server Configuration';

  @override
  String get authServerSettings => 'Server Settings';

  @override
  String get authServerURL => 'Server URL';

  @override
  String get authServerURLUpdatedTourl => 'Server URL updated to: \$url';

  @override
  String get authSetNewPassword => 'Set New Password';

  @override
  String get authTrainee => 'Trainee';

  @override
  String get barcodeFiber => 'Fiber';

  @override
  String get barcodeFoodAddedToYourLog => 'Food added to your log';

  @override
  String get barcodeScanAnother => 'Scan Another';

  @override
  String get barcodeScanResult => 'Scan Result';

  @override
  String get barcodeSugar => 'Sugar';

  @override
  String get calendarAddAvailabilitySlot => 'Add availability slot';

  @override
  String get calendarAuthorizationCode => 'Authorization Code';

  @override
  String get calendarAvailability => 'Availability';

  @override
  String get calendarBackToCalendarSettings => 'Back to Calendar Settings';

  @override
  String get calendarCalendarEvents => 'Calendar Events';

  @override
  String get calendarCalendarNotConnected => 'Calendar not connected';

  @override
  String get calendarConnect => 'Connect';

  @override
  String get calendarConnectACalendar => 'Connect a Calendar';

  @override
  String get calendarConnecttitle => 'Connect \$title';

  @override
  String get calendarCouldNotGetAuthorizationURL =>
      'Could not get authorization URL';

  @override
  String get calendarCouldNotOpenBrowser => 'Could not open browser';

  @override
  String get calendarDayOfWeek => 'Day of Week';

  @override
  String get calendarDeleteSlot => 'Delete Slot';

  @override
  String get calendarDisconnect => 'Desconectar';

  @override
  String get calendarDisconnectCalendar => 'Disconnect Calendar';

  @override
  String get calendarEditTimeSlot => 'Edit time slot';

  @override
  String get calendarEnd => 'End';

  @override
  String get calendarEndTimeMustBeAfterStartTime =>
      'End time must be after start time';

  @override
  String get calendarFilterBylabel => 'Filter by \$label';

  @override
  String get calendarGoBack => 'Go back';

  @override
  String get calendarGoogleCalendar => 'Google Calendar';

  @override
  String get calendarManageAvailability => 'Manage Availability';

  @override
  String get calendarMicrosoft => 'Microsoft';

  @override
  String get calendarMicrosoftOutlook => 'Microsoft Outlook';

  @override
  String get calendarNoAvailability => 'No availability';

  @override
  String get calendarNoAvailabilitySet => 'No availability set';

  @override
  String get calendarNoAvailabilitySetTapThePlusButtonToAddYourFir =>
      'No availability set. Tap the plus button to add your first time slot.';

  @override
  String get calendarNoEvents => 'Sin eventos';

  @override
  String get calendarNoUpcomingEvents => 'No upcoming events';

  @override
  String get calendarNoUpcomingEventsPullDownToSyncYourCalendar =>
      'No upcoming events. Pull down to sync your calendar.';

  @override
  String get calendarPleaseEnterBothCodeAndState =>
      'Please enter both code and state';

  @override
  String get calendarRemoveThisAvailabilitySlot =>
      'Remove this availability slot?';

  @override
  String get calendarStart => 'Start';

  @override
  String get calendarStateParameter => 'State Parameter';

  @override
  String get calendarSyncNow => 'Sincronizar Ahora';

  @override
  String get checkinsAddField => 'Add Field';

  @override
  String get checkinsAddNotesAboutThisCheckIn =>
      'Add notes about this check-in...';

  @override
  String get checkinsAddOption => 'Add option...';

  @override
  String get checkinsBuildCheckInForm => 'Build Check-In Form';

  @override
  String get checkinsCheckInResponses => 'Check-In Responses';

  @override
  String get checkinsCheckInSubmittedSuccessfully =>
      'Check-in submitted successfully!';

  @override
  String get checkinsDiscard => 'Discard';

  @override
  String get checkinsDiscardCheckIn => 'Discard check-in?';

  @override
  String get checkinsEGHowAreYouFeeling => 'e.g. How are you feeling?';

  @override
  String get checkinsEGWeeklyProgressCheckIn => 'e.g. Weekly Progress Check-In';

  @override
  String get checkinsEnterANumber => 'Enter a number...';

  @override
  String get checkinsEnterYourResponse => 'Enter your response...';

  @override
  String get checkinsFields => 'Fields';

  @override
  String get checkinsFrequency => 'Frequency';

  @override
  String get checkinsLabel => 'Label';

  @override
  String get checkinsPleaseFillInAllRequiredFields =>
      'Please fill in all required fields';

  @override
  String get checkinsPleaseFillInTheTemplateNameAndAllFieldLabels =>
      'Please fill in the template name and all field labels';

  @override
  String get checkinsRequired => 'Obligatorio';

  @override
  String get checkinsSaveNote => 'Save Note';

  @override
  String get checkinsSubmitCheckIn => 'Submit Check-In';

  @override
  String get checkinsTemplateCreated => 'Template created!';

  @override
  String get checkinsTemplateName => 'Template Name';

  @override
  String get checkinsType => 'Type';

  @override
  String get commonActiveCal => 'Active Cal';

  @override
  String get commonApplyFilters => 'Apply Filters';

  @override
  String get commonHeartRate => 'Heart Rate';

  @override
  String get commonLoadingHealthData => 'Loading health data';

  @override
  String get commonOpenHealthSettings => 'Open health settings';

  @override
  String get commonRetryAll => 'Retry All';

  @override
  String get communityAchievements => 'Logros';

  @override
  String get communityAttendees => 'Attendees';

  @override
  String get communityAttendeesJoinViaMeetingLink =>
      'Attendees join via meeting link';

  @override
  String get communityAutoJoinNewMembers => 'Auto-join new members';

  @override
  String get communityCancelEvent => 'Cancel event';

  @override
  String get communityCancelEvent2 => 'Cancel Event?';

  @override
  String get communityCancelEvent3 => 'Cancel Event';

  @override
  String get communityCancelled => 'Cancelled';

  @override
  String get communityChallenge => 'Challenge';

  @override
  String get communityCloseFullscreenVideo => 'Close fullscreen video';

  @override
  String get communityCouldNotOpenMeetingLink => 'Could not open meeting link';

  @override
  String get communityCreateANewEvent => 'Create a new event';

  @override
  String get communityCreateEvent => 'Create event';

  @override
  String get communityCreateEvent2 => 'Crear Evento';

  @override
  String get communityCreateSpace => 'Crear Espacio';

  @override
  String get communityDateTime => 'Date & Time';

  @override
  String get communityDeleteComment => 'Delete Comment';

  @override
  String get communityDeleteEvent => 'Delete event';

  @override
  String get communityDeleteEvent2 => 'Delete Event?';

  @override
  String get communityDeletePost => 'Eliminar Publicación';

  @override
  String get communityDeleteThisComment => 'Delete this comment?';

  @override
  String get communityDeleteThisPostThisCannotBeUndone =>
      'Delete this post? This cannot be undone.';

  @override
  String get communityEGWorkoutTips => 'e.g. Workout Tips';

  @override
  String get communityEventCancelled => 'Event cancelled';

  @override
  String get communityEventDeleted => 'Event deleted';

  @override
  String get communityEventDetails => 'Detalles del Evento';

  @override
  String get communityEventNotFoundOrNoLongerAvailable =>
      'Event not found or no longer available';

  @override
  String get communityEventType => 'Event Type';

  @override
  String get communityEvents => 'Eventos';

  @override
  String get communityFailedToCancelEvent => 'Failed to cancel event';

  @override
  String get communityFailedToCreatePostPleaseTryAgain =>
      'Failed to create post. Please try again.';

  @override
  String get communityFailedToCreateSpace => 'Failed to create space';

  @override
  String get communityFailedToDeleteComment => 'Failed to delete comment';

  @override
  String get communityFailedToDeleteEvent => 'Failed to delete event';

  @override
  String get communityFailedToPostComment => 'Failed to post comment';

  @override
  String get communityFire => 'fire';

  @override
  String get communityGeneralFeed => 'General feed';

  @override
  String get communityGoBack => 'Go Back';

  @override
  String get communityGoing => 'Going';

  @override
  String get communityHeart => 'heart';

  @override
  String get communityInterested => 'Interested';

  @override
  String get communityJoinMeeting => 'Join Meeting';

  @override
  String get communityJoinSpace => 'Join Space';

  @override
  String get communityJoinVirtualMeeting => 'Join virtual meeting';

  @override
  String get communityKeep => 'Keep';

  @override
  String get communityLatest => 'Recientes';

  @override
  String get communityLeaderboard => 'Tabla de Clasificación';

  @override
  String get communityLeaveEmptyForUnlimited => 'Leave empty for unlimited.';

  @override
  String get communityLeaveSpace => 'Leave Space';

  @override
  String get communityLiveSession => 'Live Session';

  @override
  String get communityLoadingAchievements => 'Loading achievements';

  @override
  String get communityLoadingAnnouncements => 'Loading announcements';

  @override
  String get communityLoadingCommunityFeed => 'Loading community feed';

  @override
  String get communityLoadingEvents => 'Loading events';

  @override
  String get communityMarkdown => 'Markdown';

  @override
  String get communityMaxAttendeesOptional => 'Max Attendees (optional)';

  @override
  String get communityMeetingLink => 'Meeting Link';

  @override
  String get communityMetric => 'Metric';

  @override
  String get communityNewPost => 'New post';

  @override
  String get communityOpenFullscreenVideo => 'Open fullscreen video';

  @override
  String get communityOther => 'Other';

  @override
  String get communityPastEvents => 'Past Events';

  @override
  String get communityPeriod => 'Period';

  @override
  String get communityPlayVideo => 'Play video';

  @override
  String get communityPopular => 'Popular';

  @override
  String get communityPost => 'Publicar';

  @override
  String get communityPostTo => 'Post to';

  @override
  String get communityPosted => 'Posted!';

  @override
  String get communityPrivate => 'Private';

  @override
  String get communityPublic => 'Public';

  @override
  String get communityQA => 'Q&A';

  @override
  String get communitySaved => 'Saved';

  @override
  String get communitySavedPosts => 'Saved Posts';

  @override
  String get communitySearchSpaces => 'Search spaces...';

  @override
  String get communitySpaceCreated => 'Space created!';

  @override
  String get communitySpaceName => 'Nombre del Espacio';

  @override
  String get communitySpaces => 'Espacios';

  @override
  String get communityStreak => 'Racha';

  @override
  String get communityThisEventHasBeenCancelled =>
      'This event has been cancelled.';

  @override
  String get communityThisMonth => 'Este Mes';

  @override
  String get communityThisWeek => 'Esta Semana';

  @override
  String get communityTitle => 'Title';

  @override
  String get communityUnmuteVideo => 'Unmute video';

  @override
  String get communityUnsupportedFormatUseMP4MOVOrWebM =>
      'Unsupported format. Use MP4, MOV, or WebM.';

  @override
  String get communityVideoAttachmentTapToPlayLongPressForFullscree =>
      'Video attachment. Tap to play, long press for fullscreen.';

  @override
  String get communityVideoFileIsEmpty => 'Video file is empty.';

  @override
  String get communityVideoMustBeUnder50MB => 'Video must be under 50MB.';

  @override
  String get communityVideoSeekBar => 'Video seek bar';

  @override
  String get communityVirtualEvent => 'Virtual Event';

  @override
  String get communityWhatIsThisSpaceAbout => 'What is this space about?';

  @override
  String get communityWorkouts => 'Workouts';

  @override
  String get communityWorkshop => 'Workshop';

  @override
  String get dashboardAiCommand => 'AI Command';

  @override
  String get dashboardSteps => 'Steps';

  @override
  String get exercisesAddCustomExercise => 'Add Custom Exercise';

  @override
  String get exercisesChangeTheExerciseThumbnail =>
      'Change the exercise thumbnail';

  @override
  String get exercisesClearSelection => 'Clear selection';

  @override
  String get exercisesCouldNotOpenVideo => 'Could not open video';

  @override
  String get exercisesCreateExercise => 'Create Exercise';

  @override
  String get exercisesCustomMuscleGroupOptional =>
      'Custom Muscle Group (optional)';

  @override
  String get exercisesEGForearmsNeckHipFlexors =>
      'e.g., Forearms, Neck, Hip Flexors...';

  @override
  String get exercisesEGInclineDumbbellPress => 'e.g., Incline Dumbbell Press';

  @override
  String get exercisesEditImage => 'Edit Image';

  @override
  String get exercisesEditVideo => 'Edit Video';

  @override
  String get exercisesErrorerror => 'Error: \$error';

  @override
  String get exercisesExerciseLibrary => 'Exercise Library';

  @override
  String get exercisesExerciseName => 'Exercise Name *';

  @override
  String get exercisesExercisenameCreated => 'Exercise \"\$name\" created';

  @override
  String get exercisesHowToPerformThisExercise =>
      'How to perform this exercise...';

  @override
  String get exercisesImageURL => 'Image URL';

  @override
  String get exercisesImageUpdated => 'Image updated';

  @override
  String get exercisesImageUploadedSuccessfully =>
      'Image uploaded successfully';

  @override
  String get exercisesInvalidYouTubeURL => 'Invalid YouTube URL';

  @override
  String get exercisesLeaveEmptyToUseOther => 'Leave empty to use \"Other\"';

  @override
  String get exercisesMuscleGroup => 'Muscle Group *';

  @override
  String get exercisesPleaseEnterAnExerciseName =>
      'Please enter an exercise name';

  @override
  String get exercisesPreview => 'Preview';

  @override
  String get exercisesSaveURL => 'Save URL';

  @override
  String get exercisesSeeFullExerciseInformation =>
      'See full exercise information';

  @override
  String get exercisesVideoURLOptional => 'Video URL (optional)';

  @override
  String get exercisesVideoURLUpdated => 'Video URL updated';

  @override
  String get exercisesVideoUploadedSuccessfully =>
      'Video uploaded successfully';

  @override
  String get exercisesViewDetails => 'View Details';

  @override
  String get exercisesWatchTutorialVideo => 'Watch Tutorial Video';

  @override
  String get exercisesYoutubeURL => 'YouTube URL';

  @override
  String get featureReqAddAComment => 'Add a comment...';

  @override
  String get featureReqApply => 'Aplicar';

  @override
  String get featureReqBriefDescriptionOfYourIdea =>
      'Brief description of your idea';

  @override
  String get featureReqCategory => 'Category';

  @override
  String get featureReqErrorLoadingCommentse => 'Error loading comments: \$e';

  @override
  String get featureReqErrore => 'Error: \$e';

  @override
  String get featureReqExplainYourIdeaInDetailWhatProblemDoesItSolve =>
      'Explain your idea in detail. What problem does it solve? How would it work?';

  @override
  String get featureReqFeatureRequest => 'Feature Request';

  @override
  String get featureReqFeatureRequestNotFound => 'Feature request not found';

  @override
  String get featureReqFeatureRequestSubmittedSuccessfully =>
      'Feature request submitted successfully!';

  @override
  String get featureReqFeatureTitle => 'Feature Title';

  @override
  String get featureReqMostVotes => 'Most Votes';

  @override
  String get featureReqRecent => 'Recent';

  @override
  String get featureReqRequest => 'Request';

  @override
  String get featureReqRequestAFeature => 'Request a Feature';

  @override
  String get featureReqRequestFeature => 'Request Feature';

  @override
  String get featureReqSortBy => 'Ordenar por';

  @override
  String get featureReqStatus => 'Estado';

  @override
  String get featureReqSubmitFeatureRequest => 'Enviar Solicitud de Función';

  @override
  String get habitsBriefDescriptionOfTheHabit =>
      'Brief description of the habit';

  @override
  String get habitsCustom => 'Custom';

  @override
  String get habitsDaily => 'Daily';

  @override
  String get habitsDailyHabits => 'Hábitos Diarios';

  @override
  String get habitsDeleteHabit => 'Delete Habit';

  @override
  String get habitsEGDrink8GlassesOfWater => 'e.g., Drink 8 glasses of water';

  @override
  String get habitsFailedToUpdateHabit => 'Failed to update habit';

  @override
  String get habitsHabitName => 'Nombre del Hábito';

  @override
  String get habitsManageHabits => 'Gestionar Hábitos';

  @override
  String get habitsPickDate => 'Pick date';

  @override
  String get habitsPleaseSelectAtLeastOneDayForCustomFrequency =>
      'Please select at least one day for custom frequency';

  @override
  String get habitsWeekdays => 'Weekdays';

  @override
  String get homeAdvancedGluteBiomechanicsWithTomJoe =>
      'Advanced Glute Biomechanics with Tom & Joe';

  @override
  String get homeLog => 'Registrar';

  @override
  String get homeLogout => 'Cerrar Sesión';

  @override
  String get homeLogoutAnyway => 'Cerrar Sesión de Todas Formas';

  @override
  String get homeOverview => 'Overview';

  @override
  String get homePerfectYourSquatForm => 'Perfect Your Squat Form';

  @override
  String get homeStartYourFirstWorkout => 'Start your first workout!';

  @override
  String get homeThisWorkoutIsWaitingToSync =>
      'This workout is waiting to sync.';

  @override
  String get homeUnsyncedData => 'Datos sin Sincronizar';

  @override
  String get homeUpperBodyStrengthTrainingTips =>
      'Upper Body Strength Training Tips';

  @override
  String get homeViewPrograms => 'View Programs';

  @override
  String get homeWeekCompleteGreatJob => 'Week complete — great job!';

  @override
  String get loggingAiCommandCenter => 'AI Command Center';

  @override
  String get loggingLogSavedSuccessfully => 'Log saved successfully!';

  @override
  String get loggingTypeYourLogHere => 'Type your log here...';

  @override
  String get messagingAttachImage => 'Attach image';

  @override
  String get messagingConversationList => 'Conversation list';

  @override
  String get messagingCopy => 'Copy';

  @override
  String get messagingDeleteMessage => 'Delete message';

  @override
  String get messagingEditYourMessage => 'Edit your message...';

  @override
  String get messagingFullScreenImagePinchToZoom =>
      'Full screen image. Pinch to zoom.';

  @override
  String get messagingGoToTrainees => 'Go to Trainees';

  @override
  String get messagingImage => 'Image';

  @override
  String get messagingImageMustBeUnder5MB => 'Image must be under 5MB';

  @override
  String get messagingMessageCopied => 'Message copied';

  @override
  String get messagingOtherPersonIsTyping => 'Other person is typing';

  @override
  String get messagingSendMessage => 'Send message';

  @override
  String get nutritionAddFirstCheckIn => 'Add First Check-In';

  @override
  String get nutritionAddedFat => 'Added Fat';

  @override
  String get nutritionAddedfoodNameToMealmealNumber =>
      'Added \"\$foodName\" to Meal \$mealNumber';

  @override
  String get nutritionAreYouSureYouWantToDeleteThisFoodEntry =>
      'Are you sure you want to delete this food entry?';

  @override
  String get nutritionAssignNutritionTemplate => 'Assign Nutrition Template';

  @override
  String get nutritionAssignTemplate => 'Asignar Plantilla';

  @override
  String get nutritionBackToResults => 'Back to results';

  @override
  String get nutritionBetween1And10 => 'Between 1 and 10.';

  @override
  String get nutritionBodyFatMustBeBetween1And70 =>
      'Body fat % must be between 1 and 70';

  @override
  String get nutritionBodyFatOptional => 'Body Fat % (optional)';

  @override
  String get nutritionBodyWeightIsRequired => 'Body weight is required';

  @override
  String get nutritionBodyWeightLbs => 'Body Weight (lbs)';

  @override
  String get nutritionBodyWeightMustBeAPositiveNumber =>
      'Body weight must be a positive number';

  @override
  String get nutritionBodyWeightMustBeUnder1000Lbs =>
      'Body weight must be under 1,000 lbs';

  @override
  String get nutritionCarbsG => 'Carbs, g';

  @override
  String get nutritionCarbsG2 => 'Carbs (g)';

  @override
  String get nutritionCheckIn => 'Registrar';

  @override
  String get nutritionClarificationNeeded => 'Clarification needed';

  @override
  String get nutritionClearMeal => 'Clear Meal';

  @override
  String get nutritionCopyMeal => 'Copy Meal';

  @override
  String get nutritionDayTypeSchedule => 'Day-Type Schedule';

  @override
  String get nutritionDeleteEntry => 'Delete Entry';

  @override
  String get nutritionEG150g1Cup => 'e.g., 150g, 1 cup';

  @override
  String get nutritionEG2ChickenBreasts1CupRice1Apple =>
      'e.g., \"2 chicken breasts, 1 cup rice, 1 apple\"';

  @override
  String get nutritionEGChickenBreast => 'e.g., Chicken Breast';

  @override
  String get nutritionEditFoodEntry => 'Edit food entry';

  @override
  String get nutritionFailedToAddFood => 'Failed to add food';

  @override
  String get nutritionFailedToAssignTemplatePleaseTryAgain =>
      'Failed to assign template. Please try again.';

  @override
  String get nutritionFailedToLoadWeekPlan => 'Failed to load week plan';

  @override
  String get nutritionFailedToSaveFoodEntry => 'Failed to save food entry';

  @override
  String get nutritionFailedToSaveFoodEntryPleaseCheckYourConnectio =>
      'Failed to save food entry. Please check your connection and try again.';

  @override
  String get nutritionFatG => 'Fat, g';

  @override
  String get nutritionFatG2 => 'Fat (g)';

  @override
  String get nutritionFatMode => 'Fat Mode';

  @override
  String get nutritionFoodEntryDeleted => 'Food entry deleted';

  @override
  String get nutritionFoodEntryUpdated => 'Food entry updated';

  @override
  String get nutritionFoodLoggedSuccessfully => 'Food logged successfully';

  @override
  String get nutritionFoodName => 'Food name';

  @override
  String get nutritionHowAreYouFeelingToday => 'How are you feeling today?';

  @override
  String get nutritionIfKnownImprovesLeanBodyMassCalculation =>
      'If known, improves lean body mass calculation.';

  @override
  String get nutritionIncludeQuantitiesAndMeasurementsForAccuracy =>
      'Include quantities and measurements for accuracy';

  @override
  String get nutritionLoadingNutritionTemplates =>
      'Loading nutrition templates';

  @override
  String get nutritionMealmealNum => 'Meal \$mealNum';

  @override
  String get nutritionMealsPerDayMustBeBetween1And10 =>
      'Meals per day must be between 1 and 10';

  @override
  String get nutritionNextDay => 'Next day';

  @override
  String get nutritionNextWeek => 'Next week';

  @override
  String get nutritionNoFoodItemsDetectedPleaseDescribeWhatYouAteWi =>
      'No food items detected. Please describe what you ate with quantities.';

  @override
  String get nutritionNoLogFoundForThisDate => 'No log found for this date';

  @override
  String get nutritionNutritionPlan => 'Nutrition Plan';

  @override
  String get nutritionNutritionTemplateAssigned =>
      'Nutrition template assigned';

  @override
  String get nutritionOpenScanner => 'Open Scanner';

  @override
  String get nutritionPendingSync => 'Sincronización pendiente';

  @override
  String get nutritionPleaseLogInToSaveWeightData =>
      'Please log in to save weight data.';

  @override
  String get nutritionPreviousDay => 'Previous day';

  @override
  String get nutritionPreviousWeek => 'Previous week';

  @override
  String get nutritionProteinG => 'Protein, g';

  @override
  String get nutritionProteinG2 => 'Protein (g)';

  @override
  String get nutritionRefreshGoals => 'Actualizar objetivos';

  @override
  String get nutritionRequiredUsedToCalculateMacroTargets =>
      'Required. Used to calculate macro targets.';

  @override
  String get nutritionSaveCheckIn => 'Save Check-In';

  @override
  String get nutritionSelectATemplate => 'Select a template';

  @override
  String get nutritionSelectMealNumber => 'Select meal number';

  @override
  String get nutritionTemplate => 'Template';

  @override
  String get nutritionTotalFat => 'Total Fat';

  @override
  String get nutritionTraineeParameters => 'Trainee Parameters';

  @override
  String get nutritionTrainingBased => 'Training-Based';

  @override
  String get nutritionViewWeek => 'View Week';

  @override
  String get nutritionWeeklyNutrition => 'Weekly Nutrition';

  @override
  String get nutritionWeeklyRotation => 'Weekly Rotation';

  @override
  String get nutritionWeightCheckInSavedSuccessfully =>
      'Weight check-in saved successfully!';

  @override
  String get nutritionWeightTrends => 'Tendencias de Peso';

  @override
  String get onboardingCompleteSetup => 'Complete Setup';

  @override
  String get onboardingEnterHeight => 'Enter height';

  @override
  String get onboardingEnterWeight => 'Enter weight';

  @override
  String get onboardingEnterYourAge => 'Enter your age';

  @override
  String get onboardingEnterYourFirstName => 'Enter your first name';

  @override
  String get onboardingFeet => 'Feet';

  @override
  String get onboardingInches => 'Inches';

  @override
  String get paymentsCancelSubscription => 'Cancelar Suscripción';

  @override
  String get paymentsEGWELCOME10 => 'e.g., WELCOME10';

  @override
  String get paymentsEGWelcomeDiscountForNewTrainees =>
      'e.g., Welcome discount for new trainees';

  @override
  String get paymentsMonthlyCoaching => 'Monthly Coaching';

  @override
  String get paymentsMonthlySubscription => 'Monthly Subscription';

  @override
  String get paymentsMyCoupons => 'My Coupons';

  @override
  String get paymentsNoPayments => 'No Payments';

  @override
  String get paymentsNoPaymentsYet => 'No Payments Yet';

  @override
  String get paymentsNoSubscribersYet => 'No Subscribers Yet';

  @override
  String get paymentsNoSubscriptions => 'No Subscriptions';

  @override
  String get paymentsOneTimeConsultation => 'One-Time Consultation';

  @override
  String get paymentsOpenStripeDashboard => 'Open Stripe Dashboard';

  @override
  String get paymentsRefreshStatus => 'Refresh Status';

  @override
  String get paymentsSetYourPrices => 'Set Your Prices';

  @override
  String get photosAddPhoto => 'Agregar Foto';

  @override
  String get photosAddProgressPhoto => 'Add Progress Photo';

  @override
  String get photosAfter => 'Después';

  @override
  String get photosAnyObservationsAboutYourProgress =>
      'Any observations about your progress...';

  @override
  String get photosArms => 'Arms';

  @override
  String get photosBefore => 'Antes';

  @override
  String get photosChest => 'Chest';

  @override
  String get photosChooseFromGallery => 'Elegir de la Galería';

  @override
  String get photosComparePhotos => 'Compare Photos';

  @override
  String get photosDeletePhoto => 'Delete Photo';

  @override
  String get photosFailedToLoadPhotos => 'Failed to load photos';

  @override
  String get photosFailedToPickImagee => 'Failed to pick image: \$e';

  @override
  String get photosFailedToUploadPhotoPleaseTryAgain =>
      'Failed to upload photo. Please try again.';

  @override
  String get photosFront => 'Front';

  @override
  String get photosHips => 'Hips';

  @override
  String get photosProgressPhotoSaved => 'Progress photo saved!';

  @override
  String get photosProgressPhotos => 'Fotos de Progreso';

  @override
  String get photosSavePhoto => 'Save Photo';

  @override
  String get photosSide => 'Side';

  @override
  String get photosTakePhoto => 'Tomar Foto';

  @override
  String get photosThighs => 'Thighs';

  @override
  String get photosWaist => 'Waist';

  @override
  String get programsAddExercise => 'Agregar Ejercicio';

  @override
  String get programsAddVolume => 'Add Volume';

  @override
  String get programsAdvanced => 'Advanced';

  @override
  String get programsAllWeeks => 'All Weeks';

  @override
  String get programsAppliedProgressiveOverloadAcrossAllWeeks =>
      'Applied progressive overload across all weeks';

  @override
  String get programsApplyWithProgressiveOverload1RepWeek =>
      'Apply with Progressive Overload (+1 rep/week)';

  @override
  String get programsAreYouSureYouWantToRemoveAllExercisesFromThis =>
      'Are you sure you want to remove all exercises from this day?';

  @override
  String get programsAssignToTrainee => 'Assign to Trainee';

  @override
  String get programsAutoCreateAFullProgramBasedOnSplitGoalDifficu =>
      'Auto-create a full program based on split, goal & difficulty';

  @override
  String get programsBeginner => 'Beginner';

  @override
  String get programsBroSplit => 'Bro Split';

  @override
  String get programsBuildACompletelyCustomProgramFromTheGroundUp =>
      'Build a completely custom program from the ground up';

  @override
  String get programsChange => 'Cambiar';

  @override
  String get programsClearAllExercises => 'Clear All Exercises';

  @override
  String get programsConvertToRestDay => 'Convert to Rest Day';

  @override
  String get programsConvertToWorkoutDay => 'Convert to Workout Day';

  @override
  String get programsConvertedToRestDayForAllWeeks =>
      'Converted to rest day for all weeks';

  @override
  String get programsConvertedToRestDayForThisWeek =>
      'Converted to rest day for this week';

  @override
  String get programsConvertedToWorkoutDayForAllWeeks =>
      'Converted to workout day for all weeks';

  @override
  String get programsConvertedToWorkoutDayForThisWeek =>
      'Converted to workout day for this week';

  @override
  String get programsCopiedToAllWeeks => 'Copied to all weeks';

  @override
  String get programsCopyToAll => 'Copy to All';

  @override
  String get programsCopyWeek => 'Copy Week';

  @override
  String get programsCreateProgram => 'Crear Programa';

  @override
  String get programsCreateSuperset => 'Create Superset';

  @override
  String get programsCustomSplit => 'Custom Split';

  @override
  String get programsDayNameEGPushDay => 'Day name (e.g. Push Day)';

  @override
  String get programsDecreaseDuration => 'Decrease duration';

  @override
  String get programsDecreaseTrainingDays => 'Decrease training days';

  @override
  String get programsDeleteDraft => 'Delete Draft?';

  @override
  String get programsDeleteWeek => 'Delete Week';

  @override
  String get programsDeleteWeek2 => 'Delete Week?';

  @override
  String get programsDifficulty => 'Difficulty';

  @override
  String get programsDraftToMyPrograms => 'Draft to My Programs';

  @override
  String get programsDurationdurationWeeksWeeks =>
      'Duration: \$durationWeeks weeks';

  @override
  String get programsEGMyCustomPPL => 'e.g., My Custom PPL';

  @override
  String get programsEditProgramName => 'Edit Program Name';

  @override
  String get programsEditWeek => 'Edit Week';

  @override
  String get programsEndurance => 'Endurance';

  @override
  String get programsErrorLoadingProgramserror =>
      'Error loading programs: \$error';

  @override
  String get programsErrorLoadingTrainees => 'Error loading trainees';

  @override
  String get programsFullBody => 'Full Body';

  @override
  String get programsGeneralFitness => 'General Fitness';

  @override
  String get programsGenerate => 'Generate';

  @override
  String get programsGenerateProgram => 'Generar Programa';

  @override
  String get programsGenerateWithAI => 'Generate with AI';

  @override
  String get programsIncreaseDuration => 'Increase duration';

  @override
  String get programsIncreaseTrainingDays => 'Increase training days';

  @override
  String get programsIntermediate => 'Intermediate';

  @override
  String get programsLoadingExercises => 'Loading exercises...';

  @override
  String get programsMoreOptions => 'Más opciones';

  @override
  String get programsOpenInBuilder => 'Open in Builder';

  @override
  String get programsProgramDurationDurationWeeksWeeks =>
      'Program duration: \$_durationWeeks weeks';

  @override
  String get programsProgramName => 'Nombre del Programa';

  @override
  String get programsProgramSavedAndAssignedSuccessfully =>
      'Program saved and assigned successfully!';

  @override
  String get programsProgramTemplateSavedSuccessfully =>
      'Program template saved successfully!';

  @override
  String get programsProgramUpdatedSuccessfully =>
      'Program updated successfully!';

  @override
  String get programsPushPullLegs => 'Push / Pull / Legs';

  @override
  String get programsQuickPresets => 'Quick Presets:';

  @override
  String get programsRecomp => 'Recomp';

  @override
  String get programsRemove => 'Eliminar';

  @override
  String get programsRemoveExercise => 'Remove exercise';

  @override
  String get programsRemoveExercise2 => 'Remove Exercise';

  @override
  String get programsRemoveFromSuperset => 'Remove from superset';

  @override
  String get programsRename => 'Rename';

  @override
  String get programsRenameDay => 'Rename Day';

  @override
  String get programsRenameProgram => 'Rename Program';

  @override
  String get programsRenamedTonewName => 'Renamed to \"\$newName\"';

  @override
  String get programsReplaceActiveProgram => 'Replace Active Program?';

  @override
  String get programsReplaceExercise => 'Replace exercise';

  @override
  String get programsReplaceProgram => 'Replace Program';

  @override
  String get programsReps => 'Reps:';

  @override
  String get programsRest => 'Rest:';

  @override
  String get programsSearchExercises => 'Buscar ejercicios...';

  @override
  String get programsSelectAtLeast2ExercisesToCreateASuperset =>
      'Select at least 2 exercises to create a superset';

  @override
  String get programsSets => 'Sets:';

  @override
  String get programsStartDate => 'Start Date';

  @override
  String get programsStartFromScratch => 'Start from Scratch';

  @override
  String get programsStartWithAProvenProgramStructureAndCustomizeI =>
      'Start with a proven program structure and customize it';

  @override
  String get programsStrength => 'Strength';

  @override
  String get programsSuperset => 'Superset';

  @override
  String get programsSupersetCreatedForAllWeeks =>
      'Superset created for all weeks!';

  @override
  String get programsSupersetCreatedForThisWeek =>
      'Superset created for this week!';

  @override
  String get programsThisWeekOnly => 'This Week Only';

  @override
  String get programsTrainingDaysPerWeekTrainingDaysPerWeek =>
      'Training days per week: \$_trainingDaysPerWeek';

  @override
  String get programsUpdate => 'Update';

  @override
  String get programsUpdatedForAllWeeks => 'Updated for all weeks';

  @override
  String get programsUpdatedForThisWeek => 'Updated for this week';

  @override
  String get programsUpperLower => 'Upper / Lower';

  @override
  String get programsUseATemplate => 'Use a Template';

  @override
  String get programsWeekDeleted => 'Week deleted';

  @override
  String get progressionAcceptDeload => 'Accept Deload';

  @override
  String get progressionCheckAgain => 'Check Again';

  @override
  String get progressionCurrent => 'Current';

  @override
  String get progressionDeloadAppliedSuccessfully =>
      'Deload applied successfully';

  @override
  String get progressionDeloadDetection => 'Deload Detection';

  @override
  String get progressionDeloadRecommendationDismissed =>
      'Deload recommendation dismissed';

  @override
  String get progressionDismiss => 'Dismiss';

  @override
  String get progressionIntensity => 'Intensity';

  @override
  String get progressionSmartProgression => 'Smart Progression';

  @override
  String get progressionSuggested => 'Suggested';

  @override
  String get progressionSuggestionDismissed => 'Suggestion dismissed';

  @override
  String get progressionVolume => 'Volume';

  @override
  String get quickLogDuration => 'Duración';

  @override
  String get quickLogDurationMustBeGreaterThanZero =>
      'Duration must be greater than zero';

  @override
  String get quickLogNotesOptional => 'Notes (optional)';

  @override
  String get quickLogPleaseSelectAWorkoutTemplate =>
      'Please select a workout template';

  @override
  String get quickLogQuickLogSaved => 'Quick log saved!';

  @override
  String get settingsAccent => 'Accent';

  @override
  String get settingsAccount => 'Account';

  @override
  String get settingsActiveSessions => 'Active Sessions';

  @override
  String get settingsAlwaysUseDarkMode => 'Always use dark mode';

  @override
  String get settingsAlwaysUseLightMode => 'Always use light mode';

  @override
  String get settingsAnalytics => 'Analytics';

  @override
  String get settingsAnnouncementsFromYourTrainer =>
      'Announcements from your trainer';

  @override
  String get settingsAppleWatch => 'Apple Watch';

  @override
  String get settingsAreYouSureYouWantToRemoveYourLogo =>
      'Are you sure you want to remove your logo?';

  @override
  String get settingsAreYouSureYouWantToRemoveYourProfilePicture =>
      '¿Estás seguro de que quieres eliminar tu foto de perfil?';

  @override
  String get settingsBadgesAchievements => 'Badges & Achievements';

  @override
  String get settingsBilling => 'Billing';

  @override
  String get settingsBodyMeasurements => 'Body Measurements';

  @override
  String get settingsBrandingUpdatedSuccessfully =>
      'Branding updated successfully';

  @override
  String get settingsBusinessName => 'Business Name';

  @override
  String get settingsButtonsHeadersAccentElements =>
      'Buttons, headers, accent elements';

  @override
  String get settingsChangeYourActivityLevelAndGoals =>
      'Change your activity level and goals';

  @override
  String get settingsChangelabelTovalue => 'Change \$label to \$value';

  @override
  String get settingsCheckInDays => 'Check-in Days';

  @override
  String get settingsChooseImage => 'Choose Image';

  @override
  String get settingsChurnAlert => 'Churn Alert';

  @override
  String get settingsCommunication => 'Communication';

  @override
  String get settingsCommunityActivity => 'Community Activity';

  @override
  String get settingsCommunityEvents => 'Community Events';

  @override
  String get settingsConfigureCoachingSubscriptionPricing =>
      'Configure coaching subscription pricing';

  @override
  String get settingsConfigureSystemNotifications =>
      'Configure system notifications';

  @override
  String get settingsConfigureWorkoutAndMealReminders =>
      'Configure workout and meal reminders';

  @override
  String get settingsConfirmNewPassword => 'Confirm New Password';

  @override
  String get settingsConfirmationEmailsForPayments =>
      'Confirmation emails for payments';

  @override
  String get settingsConnectGoogleOrMicrosoftCalendar =>
      'Connect Google or Microsoft calendar';

  @override
  String get settingsConnectStripeToReceivePayments =>
      'Connect Stripe to receive payments';

  @override
  String get settingsContactSupportViaEmailAtSupportEmail =>
      'Contact support via email at \$_supportEmail';

  @override
  String get settingsCouldNotOpenEmailAppEmailCopiedToClipboard =>
      'Could not open email app. Email copied to clipboard.';

  @override
  String get settingsCreateDiscountsForYourTrainees =>
      'Create discounts for your trainees';

  @override
  String get settingsCurrentLogo => 'Current logo';

  @override
  String get settingsCurrentPassword => 'Current Password';

  @override
  String get settingsCurrentSession => 'Current session';

  @override
  String get settingsCustomizeYourAppColorsLogoAndName =>
      'Customize your app colors, logo, and name';

  @override
  String get settingsDailyOverviewOfPlatformActivity =>
      'Daily overview of platform activity';

  @override
  String get settingsDailySummary => 'Daily Summary';

  @override
  String get settingsDeleteMyAccount => 'Delete My Account';

  @override
  String get settingsDietPreferencesUpdated => 'Diet preferences updated!';

  @override
  String get settingsEditName => 'Editar Nombre';

  @override
  String get settingsEditNameBusiness => 'Edit Name & Business';

  @override
  String get settingsEmailNotifications => 'Email Notifications';

  @override
  String get settingsEnterYourBusinessName => 'Enter your business name';

  @override
  String get settingsEnterYourLastName => 'Enter your last name';

  @override
  String get settingsError => 'Error';

  @override
  String get settingsFailedToSaveReminderSettings =>
      'Failed to save reminder settings.';

  @override
  String get settingsFailedToUpdatePreferencePleaseTryAgain =>
      'Failed to update preference. Please try again.';

  @override
  String get settingsFitnessGoals => 'Fitness Goals';

  @override
  String get settingsGentleNudgesWhenYouHaveNotLoggedInAWhile =>
      'Gentle nudges when you have not logged in a while';

  @override
  String get settingsGetADailyReminderToCompleteYourWorkout =>
      'Get a daily reminder to complete your workout';

  @override
  String get settingsGetADailyReminderToLogYourMeals =>
      'Get a daily reminder to log your meals';

  @override
  String get settingsGetAWeeklyReminderToLogYourWeight =>
      'Get a weekly reminder to log your weight';

  @override
  String get settingsGetHelpWithUsingThePlatform =>
      'Get help with using the platform';

  @override
  String get settingsGettingStarted => 'Getting Started';

  @override
  String get settingsGoalsUpdatedMacrosRecalculated =>
      'Goals updated! Macros recalculated.';

  @override
  String get settingsHeightWeight => 'Height & Weight';

  @override
  String get settingsHelpSupport => 'Ayuda y Soporte';

  @override
  String get settingsHexColor => 'Hex Color';

  @override
  String get settingsHighlightsBadgesSecondaryActions =>
      'Highlights, badges, secondary actions';

  @override
  String get settingsLogOutFromAllOtherDevices =>
      'Log out from all other devices';

  @override
  String get settingsLoginAttemptsAndSecurityEvents =>
      'Login attempts and security events';

  @override
  String get settingsLogoRemoved => 'Logo removed';

  @override
  String get settingsLogoUploadedSuccessfully => 'Logo uploaded successfully';

  @override
  String get settingsManageCoachingSubscriptions =>
      'Manage coaching subscriptions';

  @override
  String get settingsManageDevicesLoggedIntoYourAccount =>
      'Manage devices logged into your account';

  @override
  String get settingsManageNotificationPreferences =>
      'Manage notification preferences';

  @override
  String get settingsManageYourSubscriptionPlan =>
      'Manage your subscription plan';

  @override
  String get settingsMatchDeviceSettings => 'Match device settings';

  @override
  String get settingsMealLoggingReminder => 'Meal Logging Reminder';

  @override
  String get settingsMySubscriptions => 'My Subscriptions';

  @override
  String get settingsNewEventsUpdatesCancellationsAndReminders =>
      'New events, updates, cancellations, and reminders';

  @override
  String get settingsNewMessage => 'Nuevo Mensaje';

  @override
  String get settingsNewPassword => 'New Password';

  @override
  String get settingsNewTrainerSignups => 'New Trainer Signups';

  @override
  String get settingsNotificationPreferences =>
      'Preferencias de Notificaciones';

  @override
  String get settingsNotificationsDisabled => 'Notifications disabled';

  @override
  String get settingsNutrition => 'Nutrición';

  @override
  String get settingsOpenNotificationSettings => 'Open notification settings';

  @override
  String get settingsPassword2FAAndSessions => 'Password, 2FA, and sessions';

  @override
  String get settingsPasswordChangedSuccessfully =>
      'Password changed successfully';

  @override
  String get settingsPastDueAlerts => 'Past Due Alerts';

  @override
  String get settingsPaymentAlerts => 'Payment Alerts';

  @override
  String get settingsPaymentHistory => 'Historial de Pagos';

  @override
  String get settingsPaymentReceipts => 'Payment Receipts';

  @override
  String get settingsPaymentSetup => 'Payment Setup';

  @override
  String get settingsPermanentlyDeleteYourAccountAndAllData =>
      'Permanently delete your account and all data';

  @override
  String get settingsPostsAndReactionsInTheCommunityFeed =>
      'Posts and reactions in the community feed';

  @override
  String get settingsPreviewOfHowYourTraineesWillSeedisplayName =>
      'Preview of how your trainees will see: \$displayName';

  @override
  String get settingsPrimary => 'Primary';

  @override
  String get settingsPrimaryColor => 'Primary Color';

  @override
  String get settingsPrimaryLight => 'Primary Light';

  @override
  String get settingsProfileUpdated => 'Profile updated!';

  @override
  String get settingsPushNotifications => 'Push Notifications';

  @override
  String get settingsReEngagementReminders => 'Re-engagement Reminders';

  @override
  String get settingsReceiveNotificationsViaEmail =>
      'Receive notifications via email';

  @override
  String get settingsReceivePushNotificationsOnThisDevice =>
      'Receive push notifications on this device';

  @override
  String get settingsRegenerate => 'Regenerate';

  @override
  String get settingsReminders => 'Recordatorios';

  @override
  String get settingsRemoveLogo => 'Remove Logo';

  @override
  String get settingsRemoveLogoImage => 'Remove logo image';

  @override
  String get settingsRemovePhoto => 'Eliminar Foto';

  @override
  String get settingsRemoveProfilePicture => 'Eliminar Foto de Perfil';

  @override
  String get settingsReplace => 'Replace';

  @override
  String get settingsReplaceLogoImage => 'Replace logo image';

  @override
  String get settingsReset => 'Restablecer';

  @override
  String get settingsResetBranding => 'Reset Branding';

  @override
  String get settingsResetToDefault => 'Reset to default';

  @override
  String get settingsResetToDefaults => 'Reset to Defaults';

  @override
  String get settingsResetToDefaults2 => 'Reset to Defaults?';

  @override
  String get settingsSaveBranding => 'Save Branding';

  @override
  String get settingsSaveBrandingChanges => 'Save branding changes';

  @override
  String get settingsSchedule => 'Schedule';

  @override
  String get settingsSecondary => 'Secondary';

  @override
  String get settingsSecondaryColor => 'Secondary Color';

  @override
  String get settingsSecurityAlerts => 'Security Alerts';

  @override
  String get settingsSetYourWeighInSchedule => 'Set your weigh-in schedule';

  @override
  String get settingsSignOutAll => 'Sign Out All';

  @override
  String get settingsSignOutAllDevices => 'Sign Out All Devices';

  @override
  String get settingsSignOutOfAdminAccount => 'Sign out of admin account';

  @override
  String get settingsSignOutOfYourAccount => 'Sign out of your account';

  @override
  String get settingsSignedOutFromAllOtherDevices =>
      'Signed out from all other devices';

  @override
  String get settingsSubscription => 'Subscription';

  @override
  String get settingsSubscriptionChanges => 'Subscription Changes';

  @override
  String get settingsSuccessfulAndFailedPayments =>
      'Successful and failed payments';

  @override
  String get settingsSuggestNewFeaturesOrVoteOnIdeas =>
      'Suggest new features or vote on ideas';

  @override
  String get settingsSyncWorkoutsAndHealthDataWithYourWatch =>
      'Sync workouts and health data with your watch';

  @override
  String get settingsThemeColorsAndDisplay => 'Tema, colores y pantalla';

  @override
  String get settingsThisWillResetAllColorCustomizationsBackToTheD =>
      'This will reset all color customizations back to the default Indigo theme.';

  @override
  String get settingsTime => 'Time';

  @override
  String get settingsTrackYourVisualTransformationOverTime =>
      'Track your visual transformation over time';

  @override
  String get settingsTraineeActivity => 'Trainee Activity';

  @override
  String get settingsTrainerAnnouncements => 'Trainer Announcements';

  @override
  String get settingsUnsavedChanges => 'Cambios sin Guardar';

  @override
  String get settingsUpdateAgeHeightAndWeight =>
      'Update age, height, and weight';

  @override
  String get settingsUpdateDietTypeAndMealSettings =>
      'Update diet type and meal settings';

  @override
  String get settingsUpdateYourAccountPassword =>
      'Update your account password';

  @override
  String get settingsUpdateYourName => 'Actualiza tu nombre';

  @override
  String get settingsUpdateYourNameAndBusinessName =>
      'Update your name and business name';

  @override
  String get settingsUpdates => 'Updates';

  @override
  String get settingsUpgradesDowngradesAndCancellations =>
      'Upgrades, downgrades, and cancellations';

  @override
  String get settingsUploadALogoImage => 'Upload a logo image';

  @override
  String get settingsViewReceivedPaymentsAndSubscribers =>
      'View received payments and subscribers';

  @override
  String get settingsViewTraineeProgressAnalytics =>
      'View trainee progress analytics';

  @override
  String get settingsViewYourEarnedBadges => 'View your earned badges';

  @override
  String get settingsWarning => 'Warning';

  @override
  String get settingsWeeklyReportWithKeyMetrics =>
      'Weekly report with key metrics';

  @override
  String get settingsWeeklySummary => 'Weekly Summary';

  @override
  String get settingsWeightCheckIn => 'Weight Check-in';

  @override
  String get settingsWeightCheckInReminder => 'Weight Check-in Reminder';

  @override
  String get settingsWhenANewTrainerCreatesAnAccount =>
      'When a new trainer creates an account';

  @override
  String get settingsWhenATraineeFinishesAWorkoutSession =>
      'When a trainee finishes a workout session';

  @override
  String get settingsWhenATraineeIsAtRiskOfChurning =>
      'When a trainee is at risk of churning';

  @override
  String get settingsWhenATraineeLogsAWorkout =>
      'When a trainee logs a workout';

  @override
  String get settingsWhenATraineeRecordsTheirWeight =>
      'When a trainee records their weight';

  @override
  String get settingsWhenATraineeStartsAWorkoutSession =>
      'When a trainee starts a workout session';

  @override
  String get settingsWhenAccountsBecomePastDue =>
      'When accounts become past due';

  @override
  String get settingsWhenYouEarnANewAchievement =>
      'When you earn a new achievement';

  @override
  String get settingsWhenYouReceiveANewMessage =>
      'When you receive a new message';

  @override
  String get settingsWorkoutFinished => 'Workout Finished';

  @override
  String get settingsWorkoutLogged => 'Workout Logged';

  @override
  String get settingsWorkoutReminder => 'Workout Reminder';

  @override
  String get settingsWorkoutStarted => 'Workout Started';

  @override
  String get settingsYouHaveUnsavedBrandingChangesDiscardThem =>
      'You have unsaved branding changes. Discard them?';

  @override
  String get settingsYourTraineesWillSeeThisNameInsteadOfFitnessAI =>
      'Your trainees will see this name instead of \"FitnessAI\"';

  @override
  String get sharingFailedToCaptureWorkoutCard =>
      'Failed to capture workout card';

  @override
  String get sharingSaveToGallery => 'Save to Gallery';

  @override
  String get sharingShare => 'Compartir';

  @override
  String get sharingShareWorkout => 'Compartir Entrenamiento';

  @override
  String get trainerActiveToday => 'Active Today';

  @override
  String get trainerAdd => 'Add';

  @override
  String get trainerAddAPersonalMessageToYourInvitation =>
      'Add a personal message to your invitation...';

  @override
  String get trainerAddNewPreset => 'Add New Preset';

  @override
  String get trainerAdherence => 'Adherence';

  @override
  String get trainerAnnouncementTitle => 'Announcement title';

  @override
  String get trainerAreYouSureYouWantToDeleteThisAnnouncement =>
      'Are you sure you want to delete this announcement?';

  @override
  String get trainerAskAIAboutThisTrainee => 'Ask AI about this trainee';

  @override
  String get trainerAssign => 'Assign';

  @override
  String get trainerAssignADifferentProgram => 'Assign a different program';

  @override
  String get trainerAssignAProgramToGetStarted =>
      'Assign a program to get started';

  @override
  String get trainerAssignExistingProgram => 'Assign Existing Program';

  @override
  String get trainerAssignNutritionTemplateToTrainee =>
      'Assign nutrition template to trainee';

  @override
  String get trainerAssignProgram => 'Asignar Programa';

  @override
  String get trainerAtRisk => 'At-Risk';

  @override
  String get trainerAvgDailyIntake => 'Avg Daily Intake';

  @override
  String get trainerAvgEngagement => 'Avg Engagement';

  @override
  String get trainerAvgRate => 'avg rate';

  @override
  String get trainerBody => 'Body';

  @override
  String get trainerBuildACustomProgramFromScratch =>
      'Build a custom program from scratch';

  @override
  String get trainerCalendar => 'Calendario';

  @override
  String get trainerCancelInvitation => 'Cancel Invitation?';

  @override
  String get trainerCancelInvitation2 => 'Cancel Invitation';

  @override
  String get trainerCard => 'Card';

  @override
  String get trainerChangeProgram => 'Change Program';

  @override
  String get trainerClassic => 'Classic';

  @override
  String get trainerClientexampleCom => 'client@example.com';

  @override
  String get trainerCopyAProgramFromAnotherTrainee =>
      'Copy a program from another trainee';

  @override
  String get trainerCopyLink => 'Copy Link';

  @override
  String get trainerCouldNotLoadPrograms => 'Could not load programs';

  @override
  String get trainerCreateNew => 'Create New';

  @override
  String get trainerCreateNewProgram => 'Create New Program';

  @override
  String get trainerCritical => 'Critical';

  @override
  String get trainerDayName => 'Day Name';

  @override
  String get trainerDeleteAnnouncement => 'Delete Announcement';

  @override
  String get trainerDeletePreset => 'Delete Preset?';

  @override
  String get trainerEGPushDayCircuitA => 'e.g., Push Day, Circuit A';

  @override
  String get trainerEGStrengthBuildingPhase1 =>
      'e.g., Strength Building Phase 1';

  @override
  String get trainerEGTrainingDayRestDay => 'e.g., Training Day, Rest Day';

  @override
  String get trainerEditGoals => 'Editar Objetivos';

  @override
  String get trainerEditProgram => 'Editar Programa';

  @override
  String get trainerEmailAddress => 'Email Address';

  @override
  String get trainerEndProgram => 'End Program';

  @override
  String get trainerErrorLoadingPresets => 'Error loading presets';

  @override
  String get trainerFailedToDeleteAnnouncement =>
      'Failed to delete announcement';

  @override
  String get trainerFailedToDeleteNotification =>
      'Failed to delete notification';

  @override
  String get trainerFailedToSavee => 'Failed to save: \$e';

  @override
  String get trainerFrequencyOptional => 'Frequency (optional)';

  @override
  String get trainerGoToTraineeHome => 'Go to Trainee Home';

  @override
  String get trainerGoalsUpdatedSuccessfully => 'Goals updated successfully';

  @override
  String get trainerHittingGoals => 'hitting goals';

  @override
  String get trainerImport => 'Import';

  @override
  String get trainerInvitationCancelled => 'Invitation cancelled';

  @override
  String get trainerInvitationResent => 'Invitation resent';

  @override
  String get trainerInvitationResentSuccessfully =>
      'Invitation resent successfully';

  @override
  String get trainerInvitationSentSuccessfully =>
      'Invitation sent successfully!';

  @override
  String get trainerInvite => 'Invite';

  @override
  String get trainerInviteLinkCopiedToClipboard =>
      'Invite link copied to clipboard';

  @override
  String get trainerKcal => 'kcal';

  @override
  String get trainerLayoutUpdatedTolabel => 'Layout updated to \$label';

  @override
  String get trainerLoadingNutritionTemplateAssignment =>
      'Loading nutrition template assignment';

  @override
  String get trainerLogged => 'Logged';

  @override
  String get trainerLoggedActivity => 'logged activity';

  @override
  String get trainerMarkAllAsRead => 'Mark All as Read';

  @override
  String get trainerMarkAllNotificationsAsRead =>
      'Mark all notifications as read';

  @override
  String get trainerMarkAllNotificationsAsRead2 =>
      'Mark all notifications as read?';

  @override
  String get trainerMarkAllRead => 'Mark All Read';

  @override
  String get trainerMessage => 'Message';

  @override
  String get trainerMinimal => 'Minimal';

  @override
  String get trainerModifyExercisesSetsAndReps =>
      'Modify exercises, sets, and reps';

  @override
  String get trainerMyTrainees => 'My Trainees';

  @override
  String get trainerNeedsAttention => 'Needs attention';

  @override
  String get trainerNewAnnouncement => 'New announcement';

  @override
  String get trainerNoActiveProgram => 'No Active Program';

  @override
  String get trainerNoProgramScheduleFound => 'No program schedule found';

  @override
  String get trainerNotSpecified => 'Not specified';

  @override
  String get trainerNotificationDeleted => 'Notification deleted';

  @override
  String get trainerOnTrack => 'On Track';

  @override
  String get trainerPersonalMessageOptional => 'Personal Message (Optional)';

  @override
  String get trainerPinAnnouncement => 'Pin Announcement';

  @override
  String get trainerPinnedAnnouncementsAppearAtTheTop =>
      'Pinned announcements appear at the top';

  @override
  String get trainerPleaseEnterAPresetName => 'Please enter a preset name';

  @override
  String get trainerPresetDeleted => 'Preset deleted';

  @override
  String get trainerPresetName => 'Preset Name';

  @override
  String get trainerPrimaryGoal => 'Primary Goal';

  @override
  String get trainerProgramEndedSuccessfully => 'Program ended successfully';

  @override
  String get trainerProgramOptions => 'Opciones de Programa';

  @override
  String get trainerProgramUpdatedSuccessfully =>
      'Program updated successfully';

  @override
  String get trainerReassign => 'Reassign';

  @override
  String get trainerReassignTemplate => 'Reassign Template?';

  @override
  String get trainerRecoveryRest => 'Recovery & rest';

  @override
  String get trainerRemoveThisProgramFromTrainee =>
      'Remove this program from trainee';

  @override
  String get trainerRemoveTrainee => 'Eliminar Alumno';

  @override
  String get trainerRenamedTonewNameInAllWeeks =>
      'Renamed to \"\$newName\" in all weeks';

  @override
  String get trainerReplaceExercise => 'Replace Exercise';

  @override
  String get trainerResend => 'Resend';

  @override
  String get trainerRestDay => 'Día de Descanso';

  @override
  String get trainerRetentionRate => 'Tasa de Retención';

  @override
  String get trainerSearch => 'Buscar...';

  @override
  String get trainerSendCheckIn => 'Send Check-In';

  @override
  String get trainerSendMessage => 'Send Message';

  @override
  String get trainerSetAsDefault => 'Set as Default';

  @override
  String get trainerShowAsPrimaryOption => 'Show as primary option';

  @override
  String get trainerStartWithAPreBuiltProgramTemplate =>
      'Start with a pre-built program template';

  @override
  String get trainerTapToManage => 'Tap to manage';

  @override
  String get trainerTotalSets => 'Total Sets';

  @override
  String get trainerTotalTrainees => 'Total de Alumnos';

  @override
  String get trainerTraineeNoLongerAvailable => 'Trainee no longer available';

  @override
  String get trainerTraineeNotFound => 'Trainee not found';

  @override
  String get trainerTraineeRemovedSuccessfully =>
      'Trainee removed successfully';

  @override
  String get trainerUpdatedInAllWeeks => 'Updated in all weeks';

  @override
  String get trainerUseThisTemplate => 'Use This Template';

  @override
  String get trainerViewAsTrainee => 'View as Trainee';

  @override
  String get trainerWeekcurrentWeek => 'Week \$currentWeek';

  @override
  String get trainerWorkout => 'Workout';

  @override
  String get trainerWriteYourAnnouncement => 'Write your announcement...';

  @override
  String get trainerYesCancel => 'Yes, Cancel';

  @override
  String get watchAutoSync => 'Auto Sync';

  @override
  String get watchConnected => 'Conectado';

  @override
  String get watchLogFromYourWrist => 'Log from your wrist';

  @override
  String get watchPaired => 'Paired';

  @override
  String get watchRestTimers => 'Rest timers';

  @override
  String get watchSyncRequested => 'Sync requested';

  @override
  String get workoutAddExercise => 'Add exercise';

  @override
  String get workoutAddSet => 'Agregar Serie';

  @override
  String get workoutAddWorkout => 'Agregar Entrenamiento';

  @override
  String get workoutChangesSavedSuccessfully => 'Changes saved successfully';

  @override
  String get workoutCheckOtherWeeksOrContactYourTrainer =>
      'Revisa otras semanas o contacta a tu entrenador';

  @override
  String get workoutComparedToYourUsualWorkouts =>
      'Compared to your usual workouts';

  @override
  String get workoutComplete => 'Complete';

  @override
  String get workoutEGShoulderFeltTightDuringOverheadPress =>
      'e.g., \"Shoulder felt tight during overhead press\"';

  @override
  String get workoutExit => 'Exit';

  @override
  String get workoutExitWorkout => 'Exit Workout?';

  @override
  String get workoutFailedToSaveRestDaye => 'Failed to save rest day: \$e';

  @override
  String get workoutGoToToday => 'Go to today';

  @override
  String get workoutHowDoYouFeelNow => 'How do you feel now?';

  @override
  String get workoutHowHappyAreYouWithThisSession =>
      'How happy are you with this session';

  @override
  String get workoutHowIntenseWasIt => 'How intense was it?';

  @override
  String get workoutHowWasYourPerformance => 'How was your performance?';

  @override
  String get workoutMarkAsMissed => 'Mark as Missed';

  @override
  String get workoutMyPrograms => 'Mis Programas';

  @override
  String get workoutNoProgramsAssigned => 'Sin programas asignados';

  @override
  String get workoutNoProgramsAvailableToSwitchTo =>
      'No hay programas disponibles para cambiar';

  @override
  String get workoutNoWorkoutsThisWeek => 'Sin entrenamientos esta semana';

  @override
  String get workoutOpenCalendar => 'Abrir calendario';

  @override
  String get workoutOverallSatisfaction => 'Overall satisfaction?';

  @override
  String get workoutPostWorkout => 'Post-Entrenamiento';

  @override
  String get workoutPreWorkout => 'Pre-Entrenamiento';

  @override
  String get workoutRateHowWellYouExecutedYourExercises =>
      'Rate how well you executed your exercises';

  @override
  String get workoutRestDayCompleted => 'Rest day completed!';

  @override
  String get workoutSaveChanges => 'Save changes';

  @override
  String get workoutScheduleNotBuiltYet => 'Horario aún no construido';

  @override
  String get workoutShareWorkout => 'Share workout';

  @override
  String get workoutSkip => 'Skip';

  @override
  String get workoutSkipFinish => 'Skip & Finish';

  @override
  String get workoutSkipStart => 'Skip & Start';

  @override
  String get workoutSkipSurvey => 'Skip Survey?';

  @override
  String get workoutStartAWorkout => 'Start a Workout';

  @override
  String get workoutSwitchProgram => 'Cambiar Programa';

  @override
  String get workoutViewAllPrograms => 'Ver Todos los Programas';

  @override
  String get workoutViewCalendar => 'Ver Calendario';

  @override
  String get workoutYouCanStillStartYourWorkoutWithoutCompletingT =>
      'You can still start your workout without completing the survey.';

  @override
  String get workoutYouOnlyHaveOneProgramAssigned =>
      'You only have one program assigned';

  @override
  String get workoutYourEnergyLevelAfterTheWorkout =>
      'Your energy level after the workout';

  @override
  String get workoutYourProgressWillNotBeSaved =>
      'Your progress will not be saved.';

  @override
  String get workoutYourTrainerWillAssignYouAProgramSoon =>
      'Tu entrenador te asignará un programa pronto';
}
