from pydantic import Field, computed_field, PostgresDsn
from pydantic_core import MultiHostUrl
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings, cli_hide_none_type=True):
    
    # General Info
    APP_NAME: str = "Backend"
    PROJECT_NAME: str | None = Field(default=None)
    PROJECT_VERSION: str | None = Field(default=None)
    PROJECT_DESCRIPTION: str | None = Field(default=None)
    API_V1_STR: str | None = Field(default=None)
    
    # OpenAI Constants
    OPENAI_API_KEY: str
    OPENAI_ORG_ID: str | None = Field(default=None)
    OPENAI_PROJ_ID: str | None = Field(default=None)
    OPENAI_MODEL: str | None = Field(default=None)
    OPENAI_MODELS: list | None = Field(default=None)
    
    # Claude Constants
    CLAUDE_API_KEY: str | None = Field(default=None)
    CLAUDE_MODEL: str | None = Field(default=None)
    CLAUDE_MODELS: list | None = Field(default=None)
    
    # Mistral Constants
    MISTRAL_API_KEY: str | None = Field(default=None)
    MISTRAL_MODEL: str | None = Field(default=None)
    MISTRAL_MODELS: list | None = Field(default=None)
    
    # Gemini Constants
    GOOGLE_API_KEY: str | None = Field(default=None)
    GOOGLE_MODEL: str | None = Field(default=None)
    GOOGLE_MODELS: list | None = Field(default=None)
    
    # PostgresSQL
    POSTGRES_SERVER: str = Field(default="localhost")
    POSTGRES_PORT: int = Field(default=5432)
    POSTGRES_USER: str = Field(default="postgres")
    POSTGRES_PASSWORD: str = Field(default="password")
    POSTGRES_DB: str = Field(default="smartlegal-db")
    
    @computed_field  # type: ignore[misc]
    @property
    def SQLALCHEMY_DATABASE_URI(self) -> PostgresDsn:
        return MultiHostUrl.build(
            scheme="postgresql+psycopg",
            username=self.POSTGRES_USER,
            password=self.POSTGRES_PASSWORD,
            host=self.POSTGRES_SERVER,
            port=self.POSTGRES_PORT,
            path=self.POSTGRES_DB,
        )
    
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding='utf-8')
    
settings = Settings()