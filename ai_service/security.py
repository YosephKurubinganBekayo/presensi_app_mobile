from datetime import datetime, timedelta
from jose import JWTError, jwt
from fastapi import Depends, HTTPException
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

SECRET_KEY = "supersecretkey123"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60

security = HTTPBearer()


def create_access_token(data: dict):
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)


def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security)
):
    token = credentials.credentials

    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        return payload
    except JWTError:
        raise HTTPException(status_code=401, detail="Token tidak valid")


# 🔐 ADMIN ONLY
def admin_required(user: dict = Depends(get_current_user)):
    if user.get("role") != "admin":
        raise HTTPException(status_code=403, detail="Akses khusus admin")
    return user


# 👨‍🏫 GURU ONLY
def guru_required(user: dict = Depends(get_current_user)):
    if user.get("role") != "guru":
        raise HTTPException(status_code=403, detail="Akses khusus guru")
    return user


# 👩‍🏫 WALI ONLY
def wali_required(user: dict = Depends(get_current_user)):
    if user.get("role") != "wali":
        raise HTTPException(status_code=403, detail="Akses khusus wali kelas")
    return user