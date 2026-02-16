"""
Django settings for Fitness AI project.
"""
import os
from pathlib import Path
from dotenv import load_dotenv

load_dotenv()

# Build paths inside the project like this: BASE_DIR / 'subdir'.
BASE_DIR = Path(__file__).resolve().parent.parent

# SECURITY WARNING: keep the secret key used in production secret!
SECRET_KEY = os.getenv('SECRET_KEY', 'django-insecure-change-me-in-production')

# SECURITY WARNING: don't run with debug turned on in production!
DEBUG = os.getenv('DEBUG', 'True') == 'True'

# In debug mode, allow all hosts for easier development
if DEBUG:
    ALLOWED_HOSTS = ['*']
else:
    ALLOWED_HOSTS = os.getenv('ALLOWED_HOSTS', 'localhost,127.0.0.1').split(',')

# Application definition
INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'rest_framework',
    'rest_framework_simplejwt',
    'corsheaders',
    'djoser',
    'core',
    'users',
    'workouts',
    'subscriptions',
    'trainer',
    'features',
    'calendars',
    'ambassador',
    'community',
]

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'corsheaders.middleware.CorsMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'config.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'config.wsgi.application'

# Database
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': os.getenv('DB_NAME', 'fitnessai'),
        'USER': os.getenv('DB_USER', 'postgres'),
        'PASSWORD': os.getenv('DB_PASSWORD', 'postgres'),
        'HOST': os.getenv('DB_HOST', 'localhost'),
        'PORT': os.getenv('DB_PORT', '5432'),
    }
}

# Custom User Model
AUTH_USER_MODEL = 'users.User'

# Authentication backends - use email for login
AUTHENTICATION_BACKENDS = [
    'django.contrib.auth.backends.ModelBackend',  # Default backend
]

# Password validation
AUTH_PASSWORD_VALIDATORS = [
    {
        'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator',
    },
]

# Internationalization
LANGUAGE_CODE = 'en-us'
TIME_ZONE = 'UTC'
USE_I18N = True
USE_TZ = True

# Static files (CSS, JavaScript, Images)
STATIC_URL = 'static/'
STATIC_ROOT = BASE_DIR / 'staticfiles'

# Media files
MEDIA_URL = 'media/'
MEDIA_ROOT = BASE_DIR / 'media'

# Default primary key field type
DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

# REST Framework
REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': (
        'rest_framework_simplejwt.authentication.JWTAuthentication',
    ),
    'DEFAULT_PERMISSION_CLASSES': (
        'rest_framework.permissions.IsAuthenticated',
    ),
    'DEFAULT_PAGINATION_CLASS': 'rest_framework.pagination.PageNumberPagination',
    'PAGE_SIZE': 20,
    'DEFAULT_THROTTLE_CLASSES': [
        'rest_framework.throttling.AnonRateThrottle',
        'rest_framework.throttling.UserRateThrottle',
    ],
    'DEFAULT_THROTTLE_RATES': {
        'anon': '30/minute',
        'user': '120/minute',
        'registration': '5/hour',
    },
}

# CORS - Only allow all origins in development; restrict in production
if DEBUG:
    CORS_ALLOW_ALL_ORIGINS = True
else:
    CORS_ALLOW_ALL_ORIGINS = False
    CORS_ALLOWED_ORIGINS = [
        origin.strip()
        for origin in os.getenv('CORS_ALLOWED_ORIGINS', 'http://localhost:3000').split(',')
        if origin.strip()
    ]
CORS_ALLOW_CREDENTIALS = True

# CSRF trusted origins for ngrok
CSRF_TRUSTED_ORIGINS = [
    "https://*.ngrok-free.app",
    "https://*.ngrok.io",
    "http://localhost:8000",
    "http://127.0.0.1:8000",
]

# JWT Settings
from datetime import timedelta

SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(hours=1),
    'REFRESH_TOKEN_LIFETIME': timedelta(days=7),
    'ROTATE_REFRESH_TOKENS': True,
}

# OpenAI
OPENAI_API_KEY = os.getenv('OPENAI_API_KEY', '')

# Stripe
STRIPE_SECRET_KEY = os.getenv('STRIPE_SECRET_KEY', '')
STRIPE_PUBLISHABLE_KEY = os.getenv('STRIPE_PUBLISHABLE_KEY', '')
STRIPE_WEBHOOK_SECRET = os.getenv('STRIPE_WEBHOOK_SECRET', '')

# Stripe Connect (for trainer payments)
STRIPE_PLATFORM_FEE_PERCENT = float(os.getenv('STRIPE_PLATFORM_FEE_PERCENT', '10'))

# Frontend URLs for Stripe redirects
FRONTEND_URL = os.getenv('FRONTEND_URL', 'http://localhost:3000')
STRIPE_CONNECT_RETURN_URL = os.getenv('STRIPE_CONNECT_RETURN_URL', f'{FRONTEND_URL}/trainer/stripe-connect/return')
STRIPE_CONNECT_REFRESH_URL = os.getenv('STRIPE_CONNECT_REFRESH_URL', f'{FRONTEND_URL}/trainer/stripe-connect/refresh')
STRIPE_CHECKOUT_SUCCESS_URL = os.getenv('STRIPE_CHECKOUT_SUCCESS_URL', f'{FRONTEND_URL}/payment/success')
STRIPE_CHECKOUT_CANCEL_URL = os.getenv('STRIPE_CHECKOUT_CANCEL_URL', f'{FRONTEND_URL}/payment/cancel')

# Google Calendar Integration
GOOGLE_CALENDAR_CLIENT_ID = os.getenv('GOOGLE_CALENDAR_CLIENT_ID', '')
GOOGLE_CALENDAR_CLIENT_SECRET = os.getenv('GOOGLE_CALENDAR_CLIENT_SECRET', '')
GOOGLE_CALENDAR_REDIRECT_URI = os.getenv('GOOGLE_CALENDAR_REDIRECT_URI', f'{FRONTEND_URL}/calendar/google/callback')

# Microsoft Calendar Integration
MICROSOFT_CALENDAR_CLIENT_ID = os.getenv('MICROSOFT_CALENDAR_CLIENT_ID', '')
MICROSOFT_CALENDAR_CLIENT_SECRET = os.getenv('MICROSOFT_CALENDAR_CLIENT_SECRET', '')
MICROSOFT_CALENDAR_REDIRECT_URI = os.getenv('MICROSOFT_CALENDAR_REDIRECT_URI', f'{FRONTEND_URL}/calendar/microsoft/callback')

# Calendar encryption key (for storing tokens securely)
CALENDAR_ENCRYPTION_KEY = os.getenv('CALENDAR_ENCRYPTION_KEY', '')

# Social Authentication (Google & Apple Sign-In)
GOOGLE_CLIENT_ID = os.getenv('GOOGLE_CLIENT_ID', '')
APPLE_CLIENT_ID = os.getenv('APPLE_CLIENT_ID', '')  # Bundle ID (e.g., com.yourapp.bundleid)
APPLE_TEAM_ID = os.getenv('APPLE_TEAM_ID', '')

# Email Configuration
# Dev: console backend prints emails to stdout
# Prod: SMTP via env vars
EMAIL_BACKEND = os.getenv(
    'EMAIL_BACKEND',
    'django.core.mail.backends.console.EmailBackend',
)
EMAIL_HOST = os.getenv('EMAIL_HOST', 'localhost')
EMAIL_PORT = int(os.getenv('EMAIL_PORT', '587'))
EMAIL_HOST_USER = os.getenv('EMAIL_HOST_USER', '')
EMAIL_HOST_PASSWORD = os.getenv('EMAIL_HOST_PASSWORD', '')
EMAIL_USE_TLS = os.getenv('EMAIL_USE_TLS', 'True') == 'True'
DEFAULT_FROM_EMAIL = os.getenv('DEFAULT_FROM_EMAIL', 'noreply@fitnessai.com')

# Djoser Configuration - Use email for authentication
DJOSER = {
    'LOGIN_FIELD': 'email',  # Use email instead of username
    'USER_CREATE_PASSWORD_RETYPE': False,
    'PASSWORD_RESET_CONFIRM_URL': 'reset-password/{uid}/{token}',
    'DOMAIN': os.getenv('DJOSER_DOMAIN', 'localhost:3000'),
    'SITE_NAME': os.getenv('DJOSER_SITE_NAME', 'FitnessAI'),
    'SERIALIZERS': {
        'user_create': 'users.serializers.UserCreateSerializer',
        'user': 'users.serializers.UserSerializer',
        'current_user': 'users.serializers.UserSerializer',
    },
    'PERMISSIONS': {
        'user': ['rest_framework.permissions.IsAuthenticated'],
        'user_list': ['rest_framework.permissions.IsAuthenticated'],
    },
}
