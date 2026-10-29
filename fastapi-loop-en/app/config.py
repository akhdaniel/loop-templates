from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    database_url: str = "sqlite:///./dev.db"
    # Web frontends (Vue, Expo web) need their origin here; native apps do not use CORS.
    cors_origins: list[str] = ["http://localhost:5173", "http://localhost:8081"]


settings = Settings()
