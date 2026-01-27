"""
Generate a JWT token for a trainer to use with the MCP server.

Usage:
    python manage.py generate_mcp_token --email trainer@example.com
    python manage.py generate_mcp_token --email trainer@example.com --days 30
"""
from django.core.management.base import BaseCommand, CommandError
from rest_framework_simplejwt.tokens import RefreshToken
from datetime import timedelta

from users.models import User


class Command(BaseCommand):
    help = 'Generate a JWT token for a trainer to use with the MCP server'

    def add_arguments(self, parser):
        parser.add_argument(
            '--email',
            type=str,
            required=True,
            help='Email of the trainer',
        )
        parser.add_argument(
            '--days',
            type=int,
            default=7,
            help='Number of days the token should be valid (default: 7)',
        )

    def handle(self, *args, **options):
        email = options['email']
        days = options['days']

        try:
            user = User.objects.get(email=email)
        except User.DoesNotExist:
            raise CommandError(f'User with email "{email}" does not exist')

        if user.role != 'TRAINER':
            raise CommandError(f'User "{email}" is not a trainer (role: {user.role})')

        if not user.is_active:
            raise CommandError(f'User "{email}" is not active')

        # Generate refresh token with extended lifetime
        refresh = RefreshToken.for_user(user)

        # Add custom claims
        refresh['mcp_server'] = True
        refresh['email'] = user.email
        refresh['role'] = user.role

        # Get access token
        access_token = str(refresh.access_token)

        self.stdout.write(self.style.SUCCESS(f'\n=== MCP Server Token for {email} ===\n'))
        self.stdout.write(self.style.WARNING('Access Token (use this for MCP server):'))
        self.stdout.write(f'\n{access_token}\n')
        self.stdout.write(self.style.WARNING('\nRefresh Token (for refreshing access):'))
        self.stdout.write(f'\n{str(refresh)}\n')
        self.stdout.write(self.style.SUCCESS(f'\nToken generated successfully!'))
        self.stdout.write(f'Valid for the default JWT lifetime (typically 5-60 minutes for access token)')
        self.stdout.write(f'\nTo use with Claude Desktop, add to your config:')
        self.stdout.write(f'  TRAINER_JWT_TOKEN="{access_token}"')
        self.stdout.write(f'\nNote: For long-lived sessions, consider implementing token refresh in the MCP server.')
