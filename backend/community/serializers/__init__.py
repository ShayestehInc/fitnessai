"""
Community serializers package.
Re-exports from sub-modules for backward compatibility.
"""
from .core_serializers import (
    AnnouncementCreateSerializer,
    AnnouncementSerializer,
    CommentReplySerializer,
    CommentSerializer,
    CreateCommentSerializer,
    CreatePostSerializer,
    LeaderboardSettingsSerializer,
    NewAchievementSerializer,
    ReactionToggleSerializer,
)
from .bookmark_serializers import (
    BookmarkCollectionCreateSerializer,
    BookmarkCollectionSerializer,
    BookmarkSerializer,
    BookmarkToggleSerializer,
)
from .space_serializers import (
    SpaceCreateSerializer,
    SpaceMembershipSerializer,
    SpaceSerializer,
)
from .classroom_serializers import (
    CourseCreateSerializer,
    CourseDetailSerializer,
    CourseEnrollmentSerializer,
    CourseLessonCreateSerializer,
    CourseLessonSerializer,
    CourseSerializer,
    LessonProgressSerializer,
    LessonProgressUpdateSerializer,
)
from .event_serializers import (
    CommunityEventCreateSerializer,
    CommunityEventSerializer,
    EventRSVPCreateSerializer,
    EventRSVPSerializer,
)
from .moderation_serializers import (
    AutoModRuleCreateSerializer,
    AutoModRuleSerializer,
    ContentReportCreateSerializer,
    ContentReportSerializer,
    ModerationActionSerializer,
    ReportReviewSerializer,
    UserBanCreateSerializer,
    UserBanSerializer,
)
from .config_serializers import (
    CommunityConfigSerializer,
)

__all__ = [
    # Core
    'AnnouncementCreateSerializer',
    'AnnouncementSerializer',
    'CommentReplySerializer',
    'CommentSerializer',
    'CreateCommentSerializer',
    'CreatePostSerializer',
    'LeaderboardSettingsSerializer',
    'NewAchievementSerializer',
    'ReactionToggleSerializer',
    # Bookmarks
    'BookmarkCollectionCreateSerializer',
    'BookmarkCollectionSerializer',
    'BookmarkSerializer',
    'BookmarkToggleSerializer',
    # Spaces
    'SpaceCreateSerializer',
    'SpaceMembershipSerializer',
    'SpaceSerializer',
    # Classroom
    'CourseCreateSerializer',
    'CourseDetailSerializer',
    'CourseEnrollmentSerializer',
    'CourseLessonCreateSerializer',
    'CourseLessonSerializer',
    'CourseSerializer',
    'LessonProgressSerializer',
    'LessonProgressUpdateSerializer',
    # Events
    'CommunityEventCreateSerializer',
    'CommunityEventSerializer',
    'EventRSVPCreateSerializer',
    'EventRSVPSerializer',
    # Moderation
    'AutoModRuleCreateSerializer',
    'AutoModRuleSerializer',
    'ContentReportCreateSerializer',
    'ContentReportSerializer',
    'ModerationActionSerializer',
    'ReportReviewSerializer',
    'UserBanCreateSerializer',
    'UserBanSerializer',
    # Config
    'CommunityConfigSerializer',
]
