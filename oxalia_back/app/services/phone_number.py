"""Normalize clinician phone numbers for WhatsApp matching.

WhatsApp Cloud API sends the sender as digits without ``+`` (e.g. ``21612345678``).
The same form is stored on the user so n8n can look up the owner by ``from``.
"""

from __future__ import annotations

import re

_NON_DIGITS = re.compile(r"\D+")
_MIN_DIGITS = 8
_MAX_DIGITS = 15


def normalize_phone_number(raw: str) -> str:
    """Return country-code digits only. Empty input → empty string."""
    digits = _NON_DIGITS.sub("", raw.strip())
    if digits.startswith("00"):
        digits = digits[2:]
    return digits


def is_valid_phone_number(digits: str) -> bool:
    return digits.isdigit() and _MIN_DIGITS <= len(digits) <= _MAX_DIGITS
