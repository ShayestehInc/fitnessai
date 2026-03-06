"""
Custom throttle classes for rate limiting sensitive endpoints.
"""
from rest_framework.throttling import AnonRateThrottle, UserRateThrottle


class RegistrationThrottle(AnonRateThrottle):
    """
    Strict rate limit for registration to prevent referral code brute-forcing.
    Uses the 'registration' rate from REST_FRAMEWORK['DEFAULT_THROTTLE_RATES'].
    """
    scope = 'registration'


class MediaUploadThrottle(UserRateThrottle):
    """
    Stricter rate limit for media upload endpoints (images, videos).
    Uses the 'media_upload' rate from REST_FRAMEWORK['DEFAULT_THROTTLE_RATES'].
    Prevents abuse of expensive file-upload endpoints.
    """
    scope = 'media_upload'
