"""
Social authentication token verification for Google and Apple Sign-In.
"""
import jwt
import requests
from google.oauth2 import id_token
from google.auth.transport import requests as google_requests
from django.conf import settings


class SocialAuthError(Exception):
    """Custom exception for social auth errors."""
    pass


def verify_google_token(token: str) -> dict:
    """
    Verify Google ID token and return user info.

    Args:
        token: The ID token from Google Sign-In

    Returns:
        dict with email, first_name, last_name, provider_uid

    Raises:
        SocialAuthError: If token verification fails
    """
    try:
        # Verify the token with Google
        idinfo = id_token.verify_oauth2_token(
            token,
            google_requests.Request(),
            settings.GOOGLE_CLIENT_ID
        )

        # Verify the issuer
        if idinfo['iss'] not in ['accounts.google.com', 'https://accounts.google.com']:
            raise SocialAuthError('Invalid token issuer')

        return {
            'email': idinfo['email'],
            'first_name': idinfo.get('given_name', ''),
            'last_name': idinfo.get('family_name', ''),
            'provider_uid': idinfo['sub'],
        }
    except ValueError as e:
        raise SocialAuthError(f'Invalid Google token: {str(e)}')


def get_apple_public_keys() -> dict:
    """Fetch Apple's public keys for JWT verification."""
    response = requests.get('https://appleid.apple.com/auth/keys')
    response.raise_for_status()
    return response.json()


def verify_apple_token(token: str) -> dict:
    """
    Verify Apple ID token and return user info.

    Args:
        token: The identity token from Sign in with Apple

    Returns:
        dict with email, first_name, last_name, provider_uid

    Raises:
        SocialAuthError: If token verification fails
    """
    try:
        # Decode header without verification to get the key id
        header = jwt.get_unverified_header(token)
        kid = header.get('kid')

        if not kid:
            raise SocialAuthError('Missing key ID in token header')

        # Fetch Apple's public keys
        apple_keys = get_apple_public_keys()

        # Find the matching key
        public_key = None
        for key in apple_keys.get('keys', []):
            if key.get('kid') == kid:
                public_key = jwt.algorithms.RSAAlgorithm.from_jwk(key)
                break

        if not public_key:
            raise SocialAuthError('Could not find matching Apple public key')

        # Verify and decode the token
        decoded = jwt.decode(
            token,
            public_key,
            algorithms=['RS256'],
            audience=settings.APPLE_CLIENT_ID,
            issuer='https://appleid.apple.com'
        )

        # Apple may not always return email on subsequent logins
        email = decoded.get('email')
        if not email:
            raise SocialAuthError('Email not provided in Apple token')

        return {
            'email': email,
            'first_name': '',  # Apple doesn't provide name in token
            'last_name': '',   # Name comes from first authorization only
            'provider_uid': decoded['sub'],
        }
    except jwt.ExpiredSignatureError:
        raise SocialAuthError('Apple token has expired')
    except jwt.InvalidTokenError as e:
        raise SocialAuthError(f'Invalid Apple token: {str(e)}')
    except requests.RequestException as e:
        raise SocialAuthError(f'Failed to fetch Apple public keys: {str(e)}')
