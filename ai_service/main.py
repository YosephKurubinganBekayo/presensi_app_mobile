from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from sqlalchemy.orm import Session

import numpy as np
import cv2
import json
import os
from uuid import uuid4
from datetime import datetime

import torch
from facenet_pytorch import InceptionResnetV1
from ultralytics import YOLO

from database import Base, engine, SessionLocal
from models import Siswa, FaceEmbedding, Presensi
from routes import auth, admin, guru, wali_kelas as wali


# ==========================================================
# APP INIT
# ==========================================================

app = FastAPI()

STATIC_DIR = "static"
UPLOAD_DIR = os.path.join(STATIC_DIR, "faces")

os.makedirs(UPLOAD_DIR, exist_ok=True)

app.mount("/static", StaticFiles(directory=STATIC_DIR), name="static")

Base.metadata.create_all(bind=engine)


# ==========================================================
# DEVICE
# ==========================================================

device = "cuda" if torch.cuda.is_available() else "cpu"
print("Device:", device)





def cosine_similarity(a, b):
    a = np.array(a)
    b = np.array(b)
    return np.dot(a, b) / (np.linalg.norm(a) * np.linalg.norm(b))


# ==========================================================
# CORS
# ==========================================================

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router, prefix="/api")
app.include_router(admin.router, prefix="/api/admin")
app.include_router(guru.router, prefix="/api/guru")
app.include_router(wali.router, prefix="/api/wali")


# ==========================================================
# UPLOAD FACE (TRAINING)
# ==========================================================
@app.post("/api/ai/save-embedding")
def save_embedding(data: dict):
    db = SessionLocal()

    try:
        siswa_id = data.get("siswa_id")
        embedding = data.get("embedding")

        # 🔥 VALIDASI
        if not siswa_id:
            raise HTTPException(400, "siswa_id wajib")

        if not embedding or not isinstance(embedding, list):
            raise HTTPException(400, "embedding tidak valid")

        # 🔥 NORMALISASI (BIAR KONSISTEN)
        emb = np.array(embedding, dtype=np.float32)
        norm = np.linalg.norm(emb)

        if norm == 0:
            raise HTTPException(400, "embedding kosong")

        emb = emb / norm

        # 🔥 BATASI MAX DATA (OPTIONAL)
        existing = db.query(FaceEmbedding).filter(
            FaceEmbedding.siswa_id == siswa_id
        ).count()

        if existing >= 5:
            raise HTTPException(400, "Maksimal 5 wajah per siswa")

        # 🔥 SIMPAN
        db.add(FaceEmbedding(
            siswa_id=siswa_id,
            embedding=json.dumps(emb.tolist()),
        ))

        db.commit()

        return {
            "message": "Embedding disimpan",
            "total_face": existing + 1
        }

    finally:
        db.close()
# load wajah siswa
@app.get("/api/ai/faces/{siswa_id}")
def get_faces(siswa_id: int):
    db = SessionLocal()

    try:
        faces = db.query(FaceEmbedding).filter(
            FaceEmbedding.siswa_id == siswa_id
        ).all()

        return [
            {
                "id": f.id,
                "image_url": f.image_path
            }
            for f in faces
        ]

    finally:
        db.close()
# hapus wajah siswa
@app.delete("/api/ai/faces/{face_id}")
def delete_face(face_id: int):
    db = SessionLocal()

    try:
        face = db.query(FaceEmbedding).filter(
            FaceEmbedding.id == face_id
        ).first()

        if not face:
            raise HTTPException(404, "Data tidak ditemukan")

        # 🔥 HAPUS FILE GAMBAR
        if face.image_path:
            file_path = face.image_path.lstrip("/")

            if os.path.exists(file_path):
                os.remove(file_path)

        # 🔥 HAPUS DB
        db.delete(face)
        db.commit()

        return {"message": "Berhasil dihapus"}

    finally:
        db.close() 
# upload wajah siswa
@app.post("/api/ai/upload/{siswa_id}")
async def upload_face(siswa_id: int, file: UploadFile = File(...)):

    db: Session = SessionLocal()

    try:
        siswa = db.query(Siswa).filter(Siswa.id == siswa_id).first()

        if not siswa:
            raise HTTPException(404, "Siswa tidak ditemukan")

        contents = await file.read()

        img = cv2.imdecode(
            np.frombuffer(contents, np.uint8),
            cv2.IMREAD_COLOR
        )

        if img is None:
            raise HTTPException(400, "Gambar tidak valid")

        # YOLO detect
        results = yolo_model(img)

        boxes = []
        for r in results:
            if r.boxes is None:
                continue
            for box in r.boxes:
                x1, y1, x2, y2 = map(int, box.xyxy[0])
                boxes.append((x1, y1, x2, y2))

        if not boxes:
            raise HTTPException(400, "Wajah tidak ditemukan")

        x1, y1, x2, y2 = boxes[0]
        face = img[y1:y2, x1:x2]

        face_tensor = preprocess_facenet(face)

        with torch.no_grad():
            embedding_tensor = facenet_model(face_tensor)

        embedding = embedding_tensor[0].cpu().numpy().tolist()

        filename = f"{uuid4().hex}.jpg"
        file_path = os.path.join(UPLOAD_DIR, filename)

        with open(file_path, "wb") as f:
            f.write(contents)

        db.add(FaceEmbedding(
            siswa_id=siswa_id,
            embedding=json.dumps(embedding),
            image_path=f"/static/faces/{filename}",
        ))

        db.commit()

        return {
            "message": "Embedding berhasil disimpan",
            "image_url": f"/static/faces/{filename}",
        }

    finally:
        db.close()


