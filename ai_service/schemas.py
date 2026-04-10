from pydantic import BaseModel, EmailStr
from datetime import datetime
from typing import List, Optional


# =========================================================
# USER
# =========================================================

class RegisterRequest(BaseModel):
    name: str
    email: EmailStr
    password: str
    role: str


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class UserResponse(BaseModel):
    id: int
    name: str
    email: EmailStr
    role: str

    class Config:
        from_attributes = True


# =========================================================
# GURU
# =========================================================

class GuruCreate(BaseModel):
    nip: str
    nama: str
    email: EmailStr
    password: str


class GuruUpdate(BaseModel):
    nama: Optional[str] = None
    email: Optional[EmailStr] = None


class GuruResponse(BaseModel):
    id: int
    nama: str
    email: EmailStr

    class Config:
        from_attributes = True


# =========================================================
# MAPEL
# =========================================================

class MapelCreate(BaseModel):
    nama: str
    guru_id: int


class MapelUpdate(BaseModel):
    nama: Optional[str] = None
    guru_id: Optional[int] = None


class MapelResponse(BaseModel):
    id: int
    nama: str
    guru_id: Optional[int]

    class Config:
        from_attributes = True


# =========================================================
# KELAS
# =========================================================

class KelasCreate(BaseModel):
    nama: str
    wali_id: Optional[int] = None


class KelasUpdate(BaseModel):
    nama: Optional[str] = None
    wali_id: Optional[int] = None


class KelasResponse(BaseModel):
    id: int
    nama: str
    wali_id: Optional[int]

    class Config:
        from_attributes = True


# =========================================================
# SISWA
# =========================================================

class SiswaCreate(BaseModel):
    nama: str
    nis: str
    kelas_id: int


class SiswaUpdate(BaseModel):
    nama: Optional[str] = None
    nis: Optional[str] = None
    kelas_id: Optional[int] = None


class SiswaResponse(BaseModel):
    id: int
    nama: str
    nis: str
    kelas_id: Optional[int]

    class Config:
        from_attributes = True


# =========================================================
# FACE EMBEDDING
# =========================================================

class EmbeddingResponse(BaseModel):
    id: int
    siswa_id: int
    image_path: Optional[str]

    class Config:
        from_attributes = True


# =========================================================
# PRESENSI
# =========================================================

class PresensiCreate(BaseModel):
    siswa_id: int
    mapel_id: int
    guru_id: int
    status: str
class PresensiBulk(BaseModel):
    siswa_ids: List[int]
    status: str

class PresensiResponse(BaseModel):
    id: int
    siswa_id: int
    mapel_id: int
    guru_id: int
    tanggal: datetime
    status: str

    class Config:
        from_attributes = True