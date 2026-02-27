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
}
