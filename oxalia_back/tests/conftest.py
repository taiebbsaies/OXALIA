import asyncio

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from sqlalchemy import event
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine

from app.database import Base, get_db
from app.main import app
from app.models import RefreshToken, User  # noqa: F401 — register models on Base.metadata

TEST_DATABASE_URL = "postgresql+asyncpg://postgres:postgres@localhost:5432/oxalia_test"

engine = create_async_engine(TEST_DATABASE_URL, echo=False)


@pytest.fixture(scope="session")
def event_loop():
    loop = asyncio.new_event_loop()
    yield loop
    loop.close()


@pytest_asyncio.fixture(scope="session", autouse=True)
async def setup_db():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
    await engine.dispose()


@pytest_asyncio.fixture
async def db():
    """Provide an AsyncSession isolated per test via outer transaction + savepoints.

    App code can call session.commit(); that only releases a savepoint.
    The outer transaction is rolled back at teardown so tests never leak data.
    """
    async with engine.connect() as connection:
        transaction = await connection.begin()
        session = AsyncSession(bind=connection, expire_on_commit=False)
        await connection.begin_nested()

        @event.listens_for(session.sync_session, "after_transaction_end")
        def restart_savepoint(sess, trans) -> None:
            if connection.closed:
                return
            if not connection.in_nested_transaction():
                connection.sync_connection.begin_nested()

        try:
            yield session
        finally:
            await session.close()
            await transaction.rollback()


@pytest_asyncio.fixture
async def client(db: AsyncSession):
    async def override_get_db():
        yield db

    app.dependency_overrides[get_db] = override_get_db
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://testserver") as c:
        yield c
    app.dependency_overrides.clear()
