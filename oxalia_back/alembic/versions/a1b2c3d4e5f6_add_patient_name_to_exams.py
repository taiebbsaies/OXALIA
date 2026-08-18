"""add patient_name to exams

Revision ID: a1b2c3d4e5f6
Revises: 2829d74606be
Create Date: 2026-08-07 09:35:00.000000

"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "a1b2c3d4e5f6"
down_revision: Union[str, Sequence[str], None] = "2829d74606be"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "exams",
        sa.Column(
            "patient_name",
            sa.String(length=255),
            nullable=False,
            server_default="Unknown",
        ),
    )
    op.alter_column("exams", "patient_name", server_default=None)


def downgrade() -> None:
    op.drop_column("exams", "patient_name")
