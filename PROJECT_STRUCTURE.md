# Project Structure

## Overview

```
fitnessai/
├── backend/          # Django REST API
├── mobile/           # Flutter mobile app
└── run_localhost.sh  # Start both services
```

## Backend (`backend/`)

Django REST Framework backend with PostgreSQL.

```
backend/
├── config/              # Django project settings
│   ├── settings.py
│   ├── urls.py
│   └── wsgi.py
├── users/               # User management (Admin, Trainer, Trainee)
│   ├── models.py
│   ├── views.py
│   └── admin.py
├── workouts/            # Workout & nutrition logging
│   ├── models.py        # Exercise, Program, DailyLog
│   ├── services/
│   │   └── natural_language_parser.py  # AI parsing service
│   ├── ai_prompts.py   # AI prompts (standards compliant)
│   ├── serializers.py
│   └── views.py
├── subscriptions/       # Subscription tiers
├── core/               # Shared utilities
│   └── permissions.py
├── manage.py
├── requirements.txt
└── example.env
```

## Mobile (`mobile/`)

Flutter mobile app with Clean Architecture.

```
mobile/
├── lib/
│   ├── main.dart
│   ├── core/
│   │   ├── theme/          # Shadcn Zinc Dark Mode
│   │   ├── api/            # Dio client
│   │   ├── router/         # GoRouter
│   │   └── services/      # HealthService
│   └── features/
│       ├── auth/           # Authentication
│       │   ├── data/       # Models, Repositories
│       │   └── presentation/  # Screens, Providers
│       ├── dashboard/      # Trainee dashboard
│       └── logging/         # AI Command Center ⭐
│           ├── data/
│           └── presentation/
├── ios/                   # iOS config (HealthKit)
├── android/               # Android config (Health Connect)
├── pubspec.yaml
└── setup.sh
```

## Running Services

### Both Services (Recommended)

```bash
./run_localhost.sh
```

Starts:
- Django backend on `http://localhost:8000`
- Flutter app on available device/emulator

### Backend Only

```bash
cd backend
source venv/bin/activate
python manage.py runserver
```

### Mobile Only

```bash
cd mobile
flutter run -d ios  # or android
```

## Key Files

### Backend
- `backend/config/settings.py` - Django configuration
- `backend/workouts/services/natural_language_parser.py` - AI parsing
- `backend/workouts/ai_prompts.py` - AI prompts

### Mobile
- `mobile/lib/main.dart` - App entry point
- `mobile/lib/core/theme/app_theme.dart` - Shadcn theme
- `mobile/lib/features/logging/` - AI Command Center

## Environment Files

- `backend/.env` - Backend environment variables (not in git)
- `backend/example.env` - Backend environment template

## Logs

When running `./run_localhost.sh`:
- `backend.log` - Django server output
- `mobile.log` - Flutter app output

View with:
```bash
tail -f backend.log
tail -f mobile.log
```
