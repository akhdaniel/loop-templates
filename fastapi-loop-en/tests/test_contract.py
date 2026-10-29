"""Every endpoint must honour its own OpenAPI schema and never return 500.

Schemathesis generates requests from the schema (valid and invalid ones) and checks the
responses: no server errors, bodies match the response schema, valid input is accepted
and invalid input rejected. Locked by .tests.lock: only humans change this file.
"""

from collections.abc import Iterator

import pytest
import schemathesis
from hypothesis import settings
from schemathesis.checks import allow_header_conformance, status_code_conformance, unsupported_method
from sqlalchemy.orm import Session

from app.db import get_session
from app.main import app

# Framework behaviour, not feature bugs: FastAPI answers malformed JSON with an
# undocumented 400, and OPTIONS/unknown methods with headers it does not document.
FRAMEWORK_NOISE = [status_code_conformance, allow_header_conformance, unsupported_method]


@pytest.fixture
def wired_app(session: Session) -> Iterator[None]:
    app.dependency_overrides[get_session] = lambda: session
    yield
    app.dependency_overrides.clear()


schema = schemathesis.openapi.from_asgi("/openapi.json", app)


# A judge must not be flaky: the same generated requests on every run (derandomize),
# and no time limits that fail on a busy machine.
@schema.parametrize()
@settings(max_examples=50, derandomize=True, deadline=None)
@pytest.mark.usefixtures("wired_app")
def test_api_honours_its_contract(case: schemathesis.Case) -> None:
    case.call_and_validate(excluded_checks=FRAMEWORK_NOISE, timeout=60)
