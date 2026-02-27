// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'FitnessAI';

  @override
  String get authLoginTitle => 'Bem-vindo de Volta';

  @override
  String get authLoginSubtitle => 'Faça login na sua conta';

  @override
  String get authEmailLabel => 'E-mail';

  @override
  String get authEmailHint => 'Digite seu e-mail';

  @override
  String get authPasswordLabel => 'Senha';

  @override
  String get authPasswordHint => 'Digite sua senha';

  @override
  String get authLoginButton => 'Entrar';

  @override
  String get authForgotPassword => 'Esqueceu a senha?';

  @override
  String get authNoAccount => 'Não tem uma conta?';

  @override
  String get authSignUp => 'Cadastre-se';

  @override
  String get authRegisterTitle => 'Criar Conta';

  @override
  String get authRegisterSubtitle => 'Junte-se ao FitnessAI hoje';

  @override
  String get authFirstNameLabel => 'Nome';

  @override
  String get authLastNameLabel => 'Sobrenome';

  @override
  String get authConfirmPasswordLabel => 'Confirmar Senha';

  @override
  String get authConfirmPasswordHint => 'Digite a senha novamente';

  @override
  String get authRegisterButton => 'Criar Conta';

  @override
  String get authHaveAccount => 'Já tem uma conta?';

  @override
  String get authSignIn => 'Entrar';

  @override
  String get authForgotTitle => 'Redefinir Senha';

  @override
  String get authForgotSubtitle =>
      'Digite seu e-mail para receber um link de redefinição';

  @override
  String get authSendResetLink => 'Enviar Link';

  @override
  String get authResetSent => 'Link de redefinição enviado para seu e-mail';

  @override
  String get authBackToLogin => 'Voltar ao Login';

  @override
  String get authOrContinueWith => 'Ou continue com';

  @override
  String get authGoogle => 'Google';

  @override
  String get authApple => 'Apple';

  @override
  String get authLoginFailed => 'Falha no login. Verifique suas credenciais.';

  @override
  String get authRegisterFailed => 'Falha no cadastro. Tente novamente.';

  @override
  String get authInvalidEmail => 'Digite um e-mail válido';

  @override
  String get authPasswordRequired => 'A senha é obrigatória';

  @override
  String get authPasswordTooShort => 'A senha deve ter pelo menos 8 caracteres';

  @override
  String get authPasswordsDoNotMatch => 'As senhas não coincidem';

  @override
  String get onboardingAboutYou => 'Sobre Você';

  @override
  String get onboardingActivityLevel => 'Nível de Atividade';

  @override
  String get onboardingGoals => 'Seus Objetivos';

  @override
  String get onboardingDiet => 'Preferências de Dieta';

  @override
  String get onboardingNext => 'Próximo';

  @override
  String get onboardingBack => 'Voltar';

  @override
  String get onboardingFinish => 'Finalizar Configuração';

  @override
  String get onboardingSexLabel => 'Sexo';

  @override
  String get onboardingSexMale => 'Masculino';

  @override
  String get onboardingSexFemale => 'Feminino';

  @override
  String get onboardingAgeLabel => 'Idade';

  @override
  String get onboardingHeightLabel => 'Altura (cm)';

  @override
  String get onboardingWeightLabel => 'Peso (kg)';

  @override
  String get onboardingSedentary => 'Sedentário';

  @override
  String get onboardingSedentaryDesc => 'Pouco ou nenhum exercício';

  @override
  String get onboardingLightlyActive => 'Levemente Ativo';

  @override
  String get onboardingLightlyActiveDesc => 'Exercício leve 1-3 dias/semana';

  @override
  String get onboardingModeratelyActive => 'Moderadamente Ativo';

  @override
  String get onboardingModeratelyActiveDesc =>
      'Exercício moderado 3-5 dias/semana';

  @override
  String get onboardingVeryActive => 'Muito Ativo';

  @override
  String get onboardingVeryActiveDesc => 'Exercício intenso 6-7 dias/semana';

  @override
  String get onboardingExtremelyActive => 'Extremamente Ativo';

  @override
  String get onboardingExtremelyActiveDesc =>
      'Exercício muito intenso e trabalho físico';

  @override
  String get onboardingBuildMuscle => 'Ganhar Músculo';

  @override
  String get onboardingBuildMuscleDesc => 'Ganhar massa muscular magra';

  @override
  String get onboardingFatLoss => 'Perder Gordura';

  @override
  String get onboardingFatLossDesc => 'Reduzir percentual de gordura corporal';

  @override
  String get onboardingRecomp => 'Recomposição';

  @override
  String get onboardingRecompDesc => 'Ganhar músculo enquanto perde gordura';

  @override
  String get onboardingLowCarb => 'Baixo Carboidrato';

  @override
  String get onboardingBalanced => 'Balanceada';

  @override
  String get onboardingHighCarb => 'Alto Carboidrato';

  @override
  String get onboardingMealsPerDay => 'Refeições por Dia';

  @override
  String onboardingStepOf(int current, int total) {
    return 'Passo $current de $total';
  }

  @override
  String get homeTitle => 'Início';

  @override
  String get homeGoodMorning => 'Bom Dia';

  @override
  String get homeGoodAfternoon => 'Boa Tarde';

  @override
  String get homeGoodEvening => 'Boa Noite';

  @override
  String get homeTodaysPlan => 'Plano de Hoje';

  @override
  String get homeQuickLog => 'Registro Rápido';

  @override
  String get homeRecentActivity => 'Atividade Recente';

  @override
  String get homeNoActivity => 'Sem atividade ainda. Comece a registrar!';

  @override
  String homeStreak(int count) {
    return 'Sequência de $count dias';
  }

  @override
  String get navHome => 'Início';

  @override
  String get navDiet => 'Dieta';

  @override
  String get navLogbook => 'Registro';

  @override
  String get navCommunity => 'Comunidade';

  @override
  String get navMessages => 'Mensagens';

  @override
  String get navDashboard => 'Painel';

  @override
  String get navTrainees => 'Alunos';

  @override
  String get navPrograms => 'Programas';

  @override
  String get navSettings => 'Configurações';

  @override
  String get settingsTitle => 'Configurações';

  @override
  String get settingsProfile => 'Perfil';

  @override
  String get settingsEditProfile => 'Editar Perfil';

  @override
  String get settingsAppearance => 'Aparência';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get settingsThemeDark => 'Escuro';

  @override
  String get settingsThemeLight => 'Claro';

  @override
  String get settingsThemeSystem => 'Sistema';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsLanguageSelect => 'Selecionar Idioma';

  @override
  String get settingsNotifications => 'Notificações';

  @override
  String get settingsSecurity => 'Segurança';

  @override
  String get settingsChangePassword => 'Alterar Senha';

  @override
  String get settingsBiometric => 'Login Biométrico';

  @override
  String get settingsDeleteAccount => 'Excluir Conta';

  @override
  String get settingsDeleteAccountWarning =>
      'Esta ação não pode ser desfeita. Todos os seus dados serão excluídos permanentemente.';

  @override
  String get settingsLogout => 'Sair';

  @override
  String get settingsLogoutConfirm => 'Tem certeza que deseja sair?';

  @override
  String settingsVersion(String version) {
    return 'Versão $version';
  }

  @override
  String get settingsFeatureRequests => 'Solicitações de Funcionalidades';

  @override
  String get settingsCalendar => 'Integração de Calendário';

  @override
  String get settingsBranding => 'Marca';

  @override
  String get settingsExerciseBank => 'Banco de Exercícios';

  @override
  String get commonSave => 'Salvar';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonDelete => 'Excluir';

  @override
  String get commonEdit => 'Editar';

  @override
  String get commonDone => 'Concluído';

  @override
  String get commonClose => 'Fechar';

  @override
  String get commonSearch => 'Buscar';

  @override
  String get commonFilter => 'Filtrar';

  @override
  String get commonAll => 'Todos';

  @override
  String get commonNone => 'Nenhum';

  @override
  String get commonYes => 'Sim';

  @override
  String get commonNo => 'Não';

  @override
  String get commonOk => 'OK';

  @override
  String get commonRetry => 'Tentar Novamente';

  @override
  String get commonConfirm => 'Confirmar';

  @override
  String get commonLoading => 'Carregando...';

  @override
  String get commonError => 'Algo deu errado';

  @override
  String get commonErrorTryAgain => 'Algo deu errado. Tente novamente.';

  @override
  String get commonNoResults => 'Nenhum resultado encontrado';

  @override
  String get commonEmpty => 'Nada aqui ainda';

  @override
  String get commonSuccess => 'Sucesso';

  @override
  String get commonSaved => 'Alterações salvas';

  @override
  String get commonDeleted => 'Excluído com sucesso';

  @override
  String get commonCopied => 'Copiado para a área de transferência';

  @override
  String get commonViewAll => 'Ver Tudo';

  @override
  String get commonRequired => 'Este campo é obrigatório';

  @override
  String get commonBack => 'Voltar';

  @override
  String get commonNext => 'Próximo';

  @override
  String get commonSubmit => 'Enviar';

  @override
  String get commonRefresh => 'Atualizar';

  @override
  String get commonMore => 'Mais';

  @override
  String get commonLess => 'Menos';

  @override
  String get commonToday => 'Hoje';

  @override
  String get commonYesterday => 'Ontem';

  @override
  String commonDaysAgo(int count) {
    return 'Há $count dias';
  }

  @override
  String get commonNeverActive => 'Nunca ativo';

  @override
  String get commonNoData => 'Nenhum dado disponível';

  @override
  String get trainerDashboard => 'Painel do Treinador';

  @override
  String get trainerTrainees => 'Alunos';

  @override
  String get trainerInviteTrainee => 'Convidar Aluno';

  @override
  String get trainerNoTrainees => 'Sem Alunos Ainda';

  @override
  String get trainerNoTraineesDesc => 'Convide seu primeiro aluno para começar';

  @override
  String get trainerAtRiskTrainees => 'Alunos em Risco';

  @override
  String get trainerRetentionAnalytics => 'Análise de Retenção';

  @override
  String get trainerAnnouncements => 'Comunicados';

  @override
  String get trainerManageAnnouncements => 'Gerenciar Comunicados';

  @override
  String get trainerBroadcastDesc =>
      'Enviar atualizações para todos os seus alunos';

  @override
  String get trainerAiAssistant => 'Assistente IA';

  @override
  String get trainerPrograms => 'Programas';

  @override
  String get trainerExercises => 'Exercícios';

  @override
  String get nutritionCalories => 'Calorias';

  @override
  String get nutritionProtein => 'Proteína';

  @override
  String get nutritionCarbs => 'Carboidratos';

  @override
  String get nutritionFat => 'Gordura';

  @override
  String get nutritionMacros => 'Macros';

  @override
  String get nutritionGoal => 'Meta';

  @override
  String get nutritionRemaining => 'Restante';

  @override
  String get nutritionConsumed => 'Consumido';

  @override
  String get nutritionLogFood => 'Registrar Alimento';

  @override
  String get nutritionWeightCheckIn => 'Registro de Peso';

  @override
  String get workoutStartWorkout => 'Iniciar Treino';

  @override
  String get workoutCompleteWorkout => 'Completar Treino';

  @override
  String get workoutSets => 'Séries';

  @override
  String get workoutReps => 'Repetições';

  @override
  String get workoutWeight => 'Peso';

  @override
  String get workoutRestTimer => 'Temporizador de Descanso';

  @override
  String get workoutHistory => 'Histórico de Treinos';

  @override
  String get workoutNoProgram => 'Sem programa atribuído';

  @override
  String get workoutNoProgramDesc =>
      'Peça ao seu treinador para atribuir um programa';

  @override
  String get errorNetworkError => 'Erro de rede. Verifique sua conexão.';

  @override
  String get errorSessionExpired => 'Sessão expirada. Faça login novamente.';

  @override
  String get errorPermissionDenied => 'Permissão negada';

  @override
  String get errorNotFound => 'Não encontrado';

  @override
  String get errorServerError =>
      'Erro no servidor. Tente novamente mais tarde.';

  @override
  String get errorUnknown => 'Ocorreu um erro desconhecido';

  @override
  String get languageEnglish => 'Inglês';

  @override
  String get languageSpanish => 'Espanhol';

  @override
  String get languagePortuguese => 'Português (Brasil)';

  @override
  String get languageChanged => 'Idioma alterado com sucesso';
}
