from pydantic import BaseModel, EmailStr, Field


class LoginRequest(BaseModel):
    email: EmailStr = Field(examples=["clinician@oxalia.health"])
    password: str = Field(examples=["StrongPassw0rd!"])


class TokenPair(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class RefreshRequest(BaseModel):
    refresh_token: str = Field(examples=["Ns5ODM646oyfP43WFc16..."])
