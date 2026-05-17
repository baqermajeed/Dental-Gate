from enum import Enum


class Role(str, Enum):
    """أدوار المستخدمين في تطبيق Dental Gate."""

    DENTIST = "dentist"
