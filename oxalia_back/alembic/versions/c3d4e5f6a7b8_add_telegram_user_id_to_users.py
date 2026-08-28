"""add telegram_user_id to users

Revision ID: c3d4e5f6a7b8
Revises: b2c3d4e5f6a7
Create Date: 2026-08-28 11:50:00.000000

"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "c3d4e5f6a7b8"
down_revision: Union[str, Sequence[str], None] = "b2c3d4e5f6a7"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("users", sa.Column("telegram_user_id", sa.String(length=32), nullable=True))
    op.create_index(op.f("ix_users_telegram_user_id"), "users", ["telegram_user_id"], unique=True)


def downgrade() -> None:
    op.drop_index(op.f("ix_users_telegram_user_id"), table_name="users")
    op.drop_column("users", "telegram_user_id")
