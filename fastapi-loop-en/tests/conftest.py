"""Shared test fixtures. Locked by .tests.lock: only humans change this file."""

import os
from collections.abc import Iterator

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker
from sqlalchemy.pool import StaticPool

from app.db import Base, get_session
from app.main import app

TEST_DATABASE_URL = os.environ.get("TEST_DATABASE_URL", "sqlite://")
assert "test" in TEST_DATABASE_URL or TEST_DATABASE_URL == "sqlite://", "tests may only use a test database"


@pytest.fixture
def session() -> Iterator[Session]:
    """A fresh, empty database for every test."""
    sqlite = TEST_DATABASE_URL.startswith("sqlite")
    engine = create_engine(
        TEST_DATABASE_URL,
        connect_args={"check_same_thread": False} if sqlite else {},
        poolclass=StaticPool if sqlite else None,
    )
    Base.metadata.create_all(engine)
    with sessionmaker(bind=engine, expire_on_commit=False)() as s:
        yield s
    Base.metadata.drop_all(engine)
    engine.dispose()


@pytest.fixture
def client(session: Session) -> Iterator[TestClient]:
    """HTTP client against the app, wired to the test database."""
    app.dependency_overrides[get_session] = lambda: session
    with TestClient(app) as c:
        yield c
    app.dependency_overrides.clear()
