from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings

# Feature routers: import each one here, e.g.
# from app.features.orders import router as orders_router

app = FastAPI(title="API", version="0.1.0")
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health", operation_id="health")
def health() -> dict[str, str]:
    return {"status": "ok"}


# ...and include it here, e.g.
# app.include_router(orders_router)
