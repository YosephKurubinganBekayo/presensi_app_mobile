import json
import numpy as np
import cv2
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Query
from sqlalchemy.orm import Session, joinedload
from passlib.context import CryptContext
from database import get_db
from models import Guru, Siswa, FaceEmbedding, Kelas, Presensi, Mapel
from security import admin_required
from schemas import PresensiBulk, SiswaCreate, GuruCreate
from pydantic import BaseModel

router = APIRouter()
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# =========================================================
# DASHBOARD
# =========================================================

@router.get("/dashboard")
def dashboard(
    db: Session = Depends(get_db),
    user=Depends(admin_required),
):
    total_siswa = db.query(Siswa).count()
    total_guru = db.query(Guru).count()

    return {
        "total_siswa": total_siswa,
        "total_guru": total_guru,
        "presensi_hari_ini": 0,
        "persentase_kehadiran": 0,
    }

# =========================================================
# GURU CRUD
# =========================================================

@router.get("/guru")
def list_guru(
    db: Session = Depends(get_db),
    user=Depends(admin_required),
):
    return db.query(Guru).all()


@router.post("/guru")
def tambah_guru(
    data: GuruCreate,
    db: Session = Depends(get_db),
    user=Depends(admin_required),
):
    hashed_password = pwd_context.hash(data.password)
    guru = Guru(
        nip=data.nip,
        nama=data.nama,
        email=data.email,
        password=hashed_password
    )

    db.add(guru)
    db.commit()
    db.refresh(guru)

    return guru


@router.put("/guru/{guru_id}")
def update_guru(
    guru_id: int,
    data: GuruCreate,
    db: Session = Depends(get_db),
    user=Depends(admin_required),
):
    guru = db.query(Guru).filter(Guru.id == guru_id).first()

    if not guru:
        raise HTTPException(status_code=404, detail="Guru tidak ditemukan")

    guru.nama = data.nama
    guru.email = data.email

    db.commit()

    return {"message": "Guru berhasil diupdate"}


@router.delete("/guru/{guru_id}")
def delete_guru(
    guru_id: int,
    db: Session = Depends(get_db),
    user=Depends(admin_required),
):
    guru = db.query(Guru).filter(Guru.id == guru_id).first()

    if not guru:
        raise HTTPException(status_code=404, detail="Guru tidak ditemukan")

    db.delete(guru)
    db.commit()

    return {"message": "Guru berhasil dihapus"}


# =========================================================
# SISWA CRUD
# =========================================================

@router.get("/siswa")
def list_siswa(
    db: Session = Depends(get_db),
    user=Depends(admin_required),
):
    siswa_list = db.query(Siswa).all()

    result = []

    for s in siswa_list:
        result.append({
            "id": s.id,
            "nama": s.nama,
            "nis": s.nis,
            "kelas_id": s.kelas_id,
            "kelas": s.kelas.nama if s.kelas else None,  # 🔥 TAMBAHKAN INI
            "total_embedding": len(s.embeddings),
        })

    return result


@router.post("/siswa")
def tambah_siswa(
    data: SiswaCreate,
    db: Session = Depends(get_db),
    user=Depends(admin_required),
):
    # pastikan kelas ada
    kelas = db.query(Kelas).filter(Kelas.id == data.kelas_id).first()
    if not kelas:
        raise HTTPException(status_code=404, detail="Kelas tidak ditemukan")

    siswa = Siswa(
        nama=data.nama,
        nis=data.nis,
        kelas_id=data.kelas_id,
    )

    db.add(siswa)
    db.commit()
    db.refresh(siswa)

    return {"message": "Siswa berhasil ditambahkan"}


@router.put("/siswa/{siswa_id}")
def update_siswa(
    siswa_id: int,
    data: SiswaCreate,
    db: Session = Depends(get_db),
    user=Depends(admin_required),
):
    siswa = db.query(Siswa).filter(Siswa.id == siswa_id).first()

    if not siswa:
        raise HTTPException(status_code=404, detail="Siswa tidak ditemukan")

    kelas = db.query(Kelas).filter(Kelas.id == data.kelas_id).first()
    if not kelas:
        raise HTTPException(status_code=404, detail="Kelas tidak ditemukan")

    siswa.nama = data.nama
    siswa.nis = data.nis
    siswa.kelas_id = data.kelas_id

    db.commit()

    return {"message": "Siswa berhasil diupdate"}


@router.delete("/siswa/delete-all")
def delete_all_siswa(
    db: Session = Depends(get_db),
    user=Depends(admin_required),
):
    deleted_count = db.query(Siswa).delete()
    db.commit()

    return {
        "message": "Semua siswa berhasil dihapus",
        "total_deleted": deleted_count,
    }


@router.delete("/siswa/{siswa_id}")
def delete_siswa(
    siswa_id: int,
    db: Session = Depends(get_db),
    user=Depends(admin_required),
):
    siswa = db.query(Siswa).filter(Siswa.id == siswa_id).first()

    if not siswa:
        raise HTTPException(status_code=404, detail="Siswa tidak ditemukan")

    db.delete(siswa)
    db.commit()

    return {"message": "Siswa berhasil dihapus"}


# =========================================================
# FACE EMBEDDING
# =========================================================

@router.post("/siswa/{siswa_id}/upload-face")
async def upload_face(
    siswa_id: int,
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    user=Depends(admin_required),
):
    siswa = db.query(Siswa).filter(Siswa.id == siswa_id).first()

    if not siswa:
        raise HTTPException(status_code=404, detail="Siswa tidak ditemukan")

    contents = await file.read()
    nparr = np.frombuffer(contents, np.uint8)
    img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

    if img is None:
        raise HTTPException(status_code=400, detail="Gagal membaca gambar")

    face_resized = cv2.resize(img, (160, 160))
    embedding = face_resized.flatten().tolist()[:128]

    new_embedding = FaceEmbedding(
        siswa_id=siswa.id,
        embedding=json.dumps(embedding),
    )

    db.add(new_embedding)
    db.commit()

    return {"message": "Embedding berhasil ditambahkan"}


@router.get("/siswa/{siswa_id}/embeddings")
def get_embeddings(
    siswa_id: int,
    db: Session = Depends(get_db),
    user=Depends(admin_required),
):
    embeddings = (
        db.query(FaceEmbedding)
        .filter(FaceEmbedding.siswa_id == siswa_id)
        .all()
    )

    return [
        {
            "id": e.id,
        }
        for e in embeddings
    ]
@router.get("/siswa/embeddings")
def get_all_embeddings(
    db: Session = Depends(get_db),
    user=Depends(admin_required),
):
    data = db.query(FaceEmbedding).all()

    result = []

    for d in data:
        result.append({
            "id": d.siswa_id,
            "embedding": json.loads(d.embedding)
        })

    return result
@router.get("/kelas")
def list_kelas(
    db: Session = Depends(get_db),
    user=Depends(admin_required),
):
    kelas_list = db.query(Kelas).all()

    return [
        {
            "id": k.id,
            "nama": k.nama,
            "wali_id": k.wali_id,
        }
        for k in kelas_list
    ]
    # =========================================================
# LIST PRESENSI + FILTER
# =========================================================

@router.get("/presensi")
def list_presensi(
    kelas_id: int | None = Query(None),
    mapel_id: int | None = Query(None),
    guru_id: int | None = Query(None),
    tanggal: str | None = Query(None),
    db: Session = Depends(get_db),
    user=Depends(admin_required),
):
    query = db.query(Presensi).options(
        joinedload(Presensi.siswa),
        joinedload(Presensi.mapel),
        joinedload(Presensi.guru),
    )

    # 🔥 Filter kelas (via siswa)
    if kelas_id:
        query = query.join(Presensi.siswa).filter(Siswa.kelas_id == kelas_id)

    # 🔥 Filter mapel
    if mapel_id:
        query = query.filter(Presensi.mapel_id == mapel_id)

    # 🔥 Filter guru
    if guru_id:
        query = query.filter(Presensi.guru_id == guru_id)

    # 🔥 Filter tanggal
    if tanggal:
        date_obj = datetime.strptime(tanggal, "%Y-%m-%d")
        query = query.filter(
            Presensi.tanggal >= date_obj,
            Presensi.tanggal < date_obj.replace(hour=23, minute=59, second=59),
        )

    presensi_list = query.order_by(Presensi.tanggal.desc()).all()

    return [
        {
            "id": p.id,
            "nama": p.siswa.nama if p.siswa else None,
            "kelas": p.siswa.kelas.nama if p.siswa and p.siswa.kelas else None,
            "mapel": p.mapel.nama if p.mapel else None,
            "guru": p.guru.nama if p.guru else None,
            "tanggal": p.tanggal,
            "status": p.status,
        }
        for p in presensi_list
    ]
    # =========================================================
# STATISTIK PRESENSI
# =========================================================

@router.get("/presensi/statistik")
def statistik_presensi(
    kelas_id: int | None = None,
    tanggal: str | None = None,
    db: Session = Depends(get_db),
    user=Depends(admin_required),
):
    from models import Presensi, Siswa
    from datetime import datetime

    query = db.query(Presensi)

    if kelas_id:
        query = query.join(Presensi.siswa).filter(
            Siswa.kelas_id == kelas_id
        )

    if tanggal:
        date_obj = datetime.strptime(tanggal, "%Y-%m-%d")
        query = query.filter(
            Presensi.tanggal >= date_obj,
            Presensi.tanggal < date_obj.replace(hour=23, minute=59, second=59),
        )

    total = query.count()
    hadir = query.filter(Presensi.status == "Hadir").count()
    izin = query.filter(Presensi.status == "Izin").count()
    alfa = query.filter(Presensi.status == "Alfa").count()

    return {
        "total": total,
        "hadir": hadir,
        "izin": izin,
        "alfa": alfa,
    }
# =========================
# PRESENSI MANUAL (FIX 404)
# =========================

@router.post("/presensi/local")
def create_presensi_bulk(
    data: PresensiBulk,
    db: Session = Depends(get_db),
    user=Depends(admin_required),
):
    results = []

    for siswa_id in data.siswa_ids:

        # 🔥 Cegah double presensi
        existing = db.query(Presensi).filter(
            Presensi.siswa_id == siswa_id,
            Presensi.tanggal >= datetime.now().date()
        ).first()

        if not existing:
            presensi = Presensi(
                siswa_id=siswa_id,
                status=data.status
            )
            db.add(presensi)
            results.append(siswa_id)

    db.commit()

    return {
        "message": "Presensi berhasil",
        "total": len(results),
        "data": results
    }