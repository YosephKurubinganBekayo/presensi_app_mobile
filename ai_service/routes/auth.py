from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database import SessionLocal
from models import User
from schemas import RegisterRequest, LoginRequest, UserResponse
from passlib.context import CryptContext
from security import create_access_token
router = APIRouter()

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


# 🔐 REGISTER
@router.post("/register", response_model=UserResponse)
def register(data: RegisterRequest, db: Session = Depends(get_db)):

    # Cek email sudah ada atau belum
    existing_user = db.query(User).filter(User.email == data.email).first()
    if existing_user:
        raise HTTPException(status_code=400, detail="Email sudah terdaftar")

    # Hash password
    hashed_password = pwd_context.hash(data.password)

    new_user = User(
        name=data.name,
        email=data.email,
        password=hashed_password,
        role=data.role
    )

    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    return new_user


# 🔐 LOGIN
@router.post("/login")
def login(data: LoginRequest, db: Session = Depends(get_db)):

    email = data.email.strip().lower()
    password = data.password.strip()

    # 🔍 Cek di tabel User
    user = db.query(User).filter(User.email.ilike(email)).first()
    role = None

    if user:
        role = user.role

    else:
        # 🔍 Kalau tidak ada, cek di tabel Guru
        from models import Guru

        user = db.query(Guru).filter(Guru.email.ilike(email)).first()

        if user:
            role = "guru"

    # ❌ Tidak ditemukan di kedua tabel
    if not user:
        raise HTTPException(status_code=401, detail="Email atau password salah")

    # 🔐 Verifikasi password
    if not pwd_context.verify(password, user.password):
        raise HTTPException(status_code=401, detail="Email atau password salah")

    # ✅ Token
    token = create_access_token({
        "user_id": getattr(user, "id", getattr(user, "nip", None)),
        "email": user.email,
        "role": role
    })

    return {
        "access_token": token,
        "token_type": "bearer",
        "user": {
            "id": getattr(user, "id", getattr(user, "nip", None)),
            "name": getattr(user, "name", getattr(user, "nama", "")),
            "email": user.email,
            "role": role
        }
    }