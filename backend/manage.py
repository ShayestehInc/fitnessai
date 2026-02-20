#!/usr/bin/env python
"""Django's command-line utility for administrative tasks."""
from __future__ import annotations

import os
import sys


def main() -> None:
    """Run administrative tasks."""
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
    try:
        from django.core.management import execute_from_command_line
    except ImportError as exc:
        raise ImportError(
            "Couldn't import Django. Are you sure it's installed and "
            "available on your PYTHONPATH environment variable? Did you "
            "forget to activate a virtual environment?"
        ) from exc

    # If running 'runserver' with no port argument, use DJANGO_PORT env var
    if len(sys.argv) == 2 and sys.argv[1] == 'runserver':
        port = os.environ.get('DJANGO_PORT', '8000')
        sys.argv.append(port)

    execute_from_command_line(sys.argv)


if __name__ == '__main__':
    main()
