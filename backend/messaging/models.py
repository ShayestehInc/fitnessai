"""
Messaging models: Conversation and Message for 1:1 trainer-trainee direct messaging.
"""
from __future__ import annotations

import os
import uuid

from django.db import models


def _message_image_path(instance: object, filename: str) -> str:
    """Generate a UUID-based upload path for message images."""
    ext = os.path.splitext(filename)[1].lower()
    return f"message_images/{uuid.uuid4().hex}{ext}"


class Conversation(models.Model):
    """
    A 1:1 conversation between a trainer and one of their trainees.

    Each (trainer, trainee) pair has at most one conversation.
    Soft-deleted via is_archived when trainee is removed.
    """
    trainer = models.ForeignKey(
        'users.User',
        on_delete=models.CASCADE,
        related_name='trainer_conversations',
        limit_choices_to={'role': 'TRAINER'},
    )
    trainee = models.ForeignKey(
        'users.User',
        on_delete=models.SET_NULL,
        null=True,
        related_name='trainee_conversations',
        limit_choices_to={'role': 'TRAINEE'},
    )
    last_message_at = models.DateTimeField(null=True, blank=True)
    is_archived = models.BooleanField(
        default=False,
        help_text='Set to True when trainee is removed. Messages preserved for audit.',
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'messaging_conversations'
        constraints = [
            models.UniqueConstraint(
                fields=['trainer', 'trainee'],
                name='unique_trainer_trainee_conversation',
            ),
        ]
        indexes = [
            models.Index(fields=['trainer', '-last_message_at']),
            models.Index(fields=['trainee', '-last_message_at']),
            models.Index(fields=['trainer', 'is_archived']),
        ]
        ordering = ['-last_message_at']

    def __str__(self) -> str:
        trainee_email = self.trainee.email if self.trainee else '[removed]'
        return (
            f"Conversation({self.trainer.email} <-> {trainee_email}, "
            f"archived={self.is_archived})"
        )


class Message(models.Model):
    """
    A single message within a conversation.

    Messages are always persisted to the database.
    Read receipts tracked via is_read / read_at.
    """
    conversation = models.ForeignKey(
        Conversation,
        on_delete=models.CASCADE,
        related_name='messages',
    )
    sender = models.ForeignKey(
        'users.User',
        on_delete=models.CASCADE,
        related_name='sent_messages',
    )
    content = models.TextField(max_length=2000, blank=True, default='')
    image = models.ImageField(
        upload_to=_message_image_path,
        null=True,
        blank=True,
        default=None,
        help_text='Optional image attachment (JPEG, PNG, WebP; max 5MB).',
    )
    is_read = models.BooleanField(default=False)
    read_at = models.DateTimeField(null=True, blank=True)
    edited_at = models.DateTimeField(
        null=True,
        blank=True,
        help_text='Set when message content is edited by the sender.',
    )
    is_deleted = models.BooleanField(
        default=False,
        help_text='Soft-delete flag. Content and image cleared when set.',
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'messaging_messages'
        indexes = [
            models.Index(fields=['conversation', 'created_at']),
            models.Index(fields=['conversation', 'is_read']),
            models.Index(fields=['sender']),
        ]
        ordering = ['created_at']

    def __str__(self) -> str:
        if self.content:
            preview = self.content[:50]
        elif self.image:
            preview = '[Photo]'
        else:
            preview = ''
        return f"Message({self.sender.email}: {preview})"
