"""add phone_number to users for WhatsApp ingest

Revision ID: c3d4e5f6a7b8
Revises: b2c3d4e5f6a7
Create Date: 2026-08-30 15:40:00.000000

"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "c3d4e5f6a7b8"
down_revision: Union[str, Sequence[str], None] = "b2c3d4e5f6a7"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("users", sa.Column("phone_number", sa.String(length=20), nullable=True))
    op.create_index(op.f("ix_users_phone_number"), "users", ["phone_number"], unique=True)


def downgrade() -> None:
    op.drop_index(op.f("ix_users_phone_number"), table_name="users")
    op.drop_column("users", "phone_number")
