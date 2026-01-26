from django.core.management.base import BaseCommand
from users.models import User


class Command(BaseCommand):
    help = 'Creates a default admin user for testing'

    def handle(self, *args, **options):
        admin_email = 'admin@fitnessai.com'
        admin_password = 'AdminFitness123!'

        if User.objects.filter(email=admin_email).exists():
            self.stdout.write(self.style.WARNING(f'Admin user "{admin_email}" already exists.'))
            user = User.objects.get(email=admin_email)
            # Update role to admin if not already
            if user.role != User.Role.ADMIN:
                user.role = User.Role.ADMIN
                user.is_staff = True
                user.is_superuser = True
                user.save()
                self.stdout.write(self.style.SUCCESS(f'Updated user role to ADMIN'))

            # Print credentials
            self.stdout.write(self.style.SUCCESS(
                f'\nAdmin credentials:\n'
                f'  Email: {admin_email}\n'
                f'  Password: {admin_password}'
            ))
            return

        user = User.objects.create_superuser(
            email=admin_email,
            password=admin_password,
            first_name='Admin',
            last_name='User',
        )

        self.stdout.write(self.style.SUCCESS(
            f'\nSuccessfully created admin user:\n'
            f'  Email: {admin_email}\n'
            f'  Password: {admin_password}\n'
            f'  Role: {user.role}'
        ))
