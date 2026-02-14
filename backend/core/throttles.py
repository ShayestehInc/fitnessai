"""
Custom throttle classes for rate limiting sensitive endpoints.
"""
from rest_framework.throttling import AnonRateThrottle


class RegistrationThrottle(AnonRateThrottle):
    """
    Strict rate limit for registration to prevent referral code brute-forcing.
    Uses the 'registration' rate from REST_FRAMEWORK['DEFAULT_THROTTLE_RATES'].
    """
    scope = 'registration'
