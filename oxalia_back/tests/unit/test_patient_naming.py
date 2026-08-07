import pytest

from app.services.patient_naming import filename_from_patient_name, normalize_patient_name


@pytest.mark.parametrize(
    ("raw", "expected"),
    [
        ("  Jane   Doe  ", "Jane Doe"),
        ("", ""),
        ("   ", ""),
        ("A" * 200, "A" * 120),
    ],
)
def test_normalize_patient_name(raw, expected):
    assert normalize_patient_name(raw) == expected


@pytest.mark.parametrize(
    ("name", "expected"),
    [
        ("Jane Doe", "Jane_Doe.jpg"),
        ("Jean-Pierre", "Jean-Pierre.jpg"),
        ("", "patient.jpg"),
        ("@@@", "patient.jpg"),
    ],
)
def test_filename_from_patient_name(name, expected):
    assert filename_from_patient_name(name) == expected
