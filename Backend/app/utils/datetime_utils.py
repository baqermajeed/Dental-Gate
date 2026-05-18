from datetime import datetime, timezone


def ensure_utc(dt: datetime | None) -> datetime | None:
    """Normalize datetimes from MongoDB (often naive) for safe UTC comparison."""
    if dt is None:
        return None
    if dt.tzinfo is None:
        return dt.replace(tzinfo=timezone.utc)
    return dt.astimezone(timezone.utc)
