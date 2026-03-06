"""
Service layer for Content Moderation:
reports, bans, auto-mod rules, content filtering.
"""
from __future__ import annotations

import logging
import re
from dataclasses import dataclass
from typing import Optional

from django.db.models import QuerySet
from django.utils import timezone

from users.models import User
from ..models import (
    AutoModRule,
    Comment,
    CommunityPost,
    ContentReport,
    ModerationAction,
    SpaceMembership,
    UserBan,
)

logger = logging.getLogger(__name__)


@dataclass(frozen=True)
class AutoModResult:
    """Result of running auto-mod rules against content."""
    passed: bool
    triggered_rule_id: Optional[int]
    action: Optional[str]
    reason: str


class ModerationService:
    """Handles content reports, bans, and auto-moderation."""

    # ---- Reports ----

    @staticmethod
    def create_report(
        reporter: User,
        trainer: User,
        content_type: str,
        reason: str,
        details: str = '',
        post: Optional[CommunityPost] = None,
        comment: Optional[Comment] = None,
    ) -> ContentReport:
        """Create a content report."""
        report = ContentReport.objects.create(
            reporter=reporter,
            trainer=trainer,
            content_type=content_type,
            reason=reason,
            details=details,
            post=post,
            comment=comment,
        )
        logger.info("Report %s created by %s for %s", report.id, reporter.email, reason)
        return report

    @staticmethod
    def review_report(
        report: ContentReport,
        reviewer: User,
        action_type: str,
        reason: str = '',
    ) -> ModerationAction:
        """Review a report and take action."""
        now = timezone.now()
        report.status = ContentReport.ReportStatus.ACTION_TAKEN
        report.reviewed_at = now
        report.reviewed_by = reviewer
        report.save(update_fields=['status', 'reviewed_at', 'reviewed_by'])

        action = ModerationAction.objects.create(
            report=report,
            moderator=reviewer,
            action_type=action_type,
            reason=reason,
        )

        # Execute the action
        if action_type == ModerationAction.ActionType.REMOVE_CONTENT:
            ModerationService._remove_content(report)
        elif action_type == ModerationAction.ActionType.BAN:
            if report.post:
                ModerationService.ban_user(
                    user=report.post.author,
                    trainer=report.trainer,
                    banned_by=reviewer,
                    reason=reason,
                    is_permanent=False,
                )
            elif report.comment:
                ModerationService.ban_user(
                    user=report.comment.author,
                    trainer=report.trainer,
                    banned_by=reviewer,
                    reason=reason,
                    is_permanent=False,
                )
        elif action_type == ModerationAction.ActionType.MUTE:
            target_user = None
            if report.post:
                target_user = report.post.author
            elif report.comment:
                target_user = report.comment.author
            if target_user:
                ModerationService._mute_user(target_user, report.trainer)

        logger.info(
            "Report %s reviewed by %s: %s",
            report.id, reviewer.email, action_type,
        )
        return action

    @staticmethod
    def dismiss_report(report: ContentReport, reviewer: User) -> ContentReport:
        """Dismiss a report without taking action."""
        report.status = ContentReport.ReportStatus.DISMISSED
        report.reviewed_at = timezone.now()
        report.reviewed_by = reviewer
        report.save(update_fields=['status', 'reviewed_at', 'reviewed_by'])
        return report

    @staticmethod
    def _remove_content(report: ContentReport) -> None:
        """Delete the reported content."""
        if report.post:
            report.post.delete()
        elif report.comment:
            report.comment.delete()

    @staticmethod
    def _mute_user(user: User, trainer: User) -> None:
        """Mute a user across all spaces in a trainer's community."""
        SpaceMembership.objects.filter(
            user=user,
            space__trainer=trainer,
        ).update(is_muted=True)

    # ---- Bans ----

    @staticmethod
    def ban_user(
        user: User,
        trainer: User,
        banned_by: User,
        reason: str,
        is_permanent: bool = False,
        duration_days: Optional[int] = None,
    ) -> UserBan:
        """Ban a user from a trainer's community."""
        expires_at = None
        if not is_permanent and duration_days:
            expires_at = timezone.now() + timezone.timedelta(days=duration_days)

        # Deactivate existing bans first
        UserBan.objects.filter(
            user=user, trainer=trainer, is_active=True,
        ).update(is_active=False)

        ban = UserBan.objects.create(
            user=user,
            trainer=trainer,
            banned_by=banned_by,
            reason=reason,
            is_permanent=is_permanent,
            expires_at=expires_at,
            is_active=True,
        )
        logger.info("User %s banned from %s by %s", user.email, trainer.email, banned_by.email)
        return ban

    @staticmethod
    def unban_user(user: User, trainer: User) -> int:
        """Remove active bans for a user in a trainer's community."""
        updated = UserBan.objects.filter(
            user=user, trainer=trainer, is_active=True,
        ).update(is_active=False)
        if updated:
            logger.info("User %s unbanned from %s", user.email, trainer.email)
        return updated

    @staticmethod
    def is_user_banned(user: User, trainer: User) -> bool:
        """Check if a user has an active, non-expired ban in a trainer's community."""
        now = timezone.now()
        return UserBan.objects.filter(
            user=user,
            trainer=trainer,
            is_active=True,
        ).exclude(
            is_permanent=False,
            expires_at__lt=now,
        ).exists()

    # ---- Auto-Mod ----

    @staticmethod
    def check_content(trainer: User, content: str) -> AutoModResult:
        """Run all enabled auto-mod rules for a trainer against content."""
        rules = AutoModRule.objects.filter(
            trainer=trainer,
            is_enabled=True,
        )
        for rule in rules:
            result = ModerationService._check_rule(rule, content)
            if not result.passed:
                return result

        return AutoModResult(passed=True, triggered_rule_id=None, action=None, reason='')

    @staticmethod
    def _check_rule(rule: AutoModRule, content: str) -> AutoModResult:
        """Check content against a single auto-mod rule."""
        content_lower = content.lower()

        if rule.rule_type == AutoModRule.RuleType.WORD_FILTER:
            words = rule.config.get('words', [])
            for word in words:
                if word.lower() in content_lower:
                    return AutoModResult(
                        passed=False,
                        triggered_rule_id=rule.id,
                        action=rule.action,
                        reason=f"Contains filtered word: {word}",
                    )

        elif rule.rule_type == AutoModRule.RuleType.LINK_FILTER:
            max_links = rule.config.get('max_links', 0)
            url_pattern = r'https?://\S+'
            links_found = len(re.findall(url_pattern, content))
            if links_found > max_links:
                return AutoModResult(
                    passed=False,
                    triggered_rule_id=rule.id,
                    action=rule.action,
                    reason=f"Too many links ({links_found} > {max_links})",
                )

        elif rule.rule_type == AutoModRule.RuleType.SPAM_DETECTION:
            # Basic spam heuristics
            if len(content) > 0:
                caps_ratio = sum(1 for c in content if c.isupper()) / len(content)
                if caps_ratio > 0.7 and len(content) > 20:
                    return AutoModResult(
                        passed=False,
                        triggered_rule_id=rule.id,
                        action=rule.action,
                        reason="Excessive caps detected",
                    )

        return AutoModResult(passed=True, triggered_rule_id=None, action=None, reason='')
