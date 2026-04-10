from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Text
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from database import Base


# =========================
# USER (Login System)
# =========================
class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False)
    email = Column(String(100), unique=True, nullable=False)
    password = Column(String(255), nullable=False)
    role = Column(String(20), nullable=False)


# =========================
# GURU
# =========================
class Guru(Base):
    __tablename__ = "guru"

    nip = Column(String(20), primary_key=True, index=True)  # 🔥 jadi PK
    nama = Column(String(100), nullable=False)
    email = Column(String(100), unique=True, nullable=False)
    password = Column(String(255), nullable=False)
    # 1 Guru hanya mengajar 1 Mapel
    mapel = relationship("Mapel", back_populates="guru", uselist=False)

    # 1 Guru hanya menjadi wali 1 Kelas
    kelas_wali = relationship("Kelas", back_populates="wali", uselist=False)

    # Relasi presensi
    presensi = relationship("Presensi", back_populates="guru")
# =========================
# MAPEL
# =========================
class Mapel(Base):
    __tablename__ = "mapel"

    id = Column(Integer, primary_key=True, index=True)
    nama = Column(String(100), nullable=False)

    # 1 Guru hanya boleh punya 1 Mapel
    guru_id = Column(String(20), ForeignKey("guru.nip"), unique=True)
    guru = relationship("Guru", back_populates="mapel")

    # Relasi presensi
    presensi = relationship("Presensi", back_populates="mapel")


# =========================
# KELAS
# =========================
class Kelas(Base):
    __tablename__ = "kelas"

    id = Column(Integer, primary_key=True, index=True)
    nama = Column(String(50), nullable=False)

    # 1 Guru hanya boleh jadi wali 1 kelas
    wali_id = Column(String(20), ForeignKey("guru.nip"), unique=True)
    wali = relationship("Guru", back_populates="kelas_wali")

    # 1 Kelas memiliki banyak siswa
    siswa = relationship("Siswa", back_populates="kelas")


# =========================
# SISWA
# =========================
class Siswa(Base):
    __tablename__ = "siswa"

    id = Column(Integer, primary_key=True, index=True)
    nama = Column(String(100), nullable=False)
    nis = Column(String(50), unique=True, nullable=False)

    # 1 Siswa hanya memiliki 1 Kelas
    kelas_id = Column(Integer, ForeignKey("kelas.id"))
    kelas = relationship("Kelas", back_populates="siswa")

    # Face Embedding (AI Recognition)
    embeddings = relationship("FaceEmbedding", back_populates="siswa")

    # Relasi presensi
    presensi = relationship("Presensi", back_populates="siswa")


# =========================
# FACE EMBEDDING (AI)
# =========================
class FaceEmbedding(Base):
    __tablename__ = "face_embeddings"

    id = Column(Integer, primary_key=True, index=True)
    siswa_id = Column(Integer, ForeignKey("siswa.id"))
    image_path = Column(String(255), nullable=True)  # <-- FIX
    embedding = Column(Text)

    siswa = relationship("Siswa", back_populates="embeddings")

# =========================
# PRESENSI
# =========================
class Presensi(Base):
    __tablename__ = "presensi"

    id = Column(Integer, primary_key=True, index=True)

    siswa_id = Column(Integer, ForeignKey("siswa.id"))
    mapel_id = Column(Integer, ForeignKey("mapel.id"))
    guru_id = Column(String(20), ForeignKey("guru.nip"))

    tanggal = Column(DateTime(timezone=True), server_default=func.now())
    status = Column(String(20), nullable=False)

    siswa = relationship("Siswa", back_populates="presensi")
    mapel = relationship("Mapel", back_populates="presensi")
    guru = relationship("Guru", back_populates="presensi")