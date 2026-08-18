"""Helpers that turn a free-text patient name into a safe stored name + filename."""

from __future__ import annotations

import re

_MAX_NAME_LEN = 120
_FILENAME_STEM_LEN = 80
_SAFE_STEM = re.compile(r"[^\w\-]+", re.UNICODE)


def normalize_patient_name(raw: str) -> str:
    """Trim, collapse whitespace, and cap length. Empty after trim → ''."""
    cleaned = " ".join(raw.strip().split())
    return cleaned[:_MAX_NAME_LEN]


def filename_from_patient_name(patient_name: str) -> str:
    """Build a JPEG filename from the patient name (e.g. 'Jane Doe' → 'Jane_Doe.jpg')."""
    stem = _SAFE_STEM.sub("_", patient_name).strip("_")
    if not stem:
        stem = "patient"
    return f"{stem[:_FILENAME_STEM_LEN]}.jpg"
