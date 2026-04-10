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


# ==========================================================
# MODELS
# ==========================================================

yolo_model = YOLO("yolofacedetect.pt")

facenet_model = InceptionResnetV1(
    pretrained="vggface2"
).eval().to(device)


# ==========================================================
# HELPER
# ==========================================================

def preprocess_facenet(face):

    if face is None or face.size == 0:
        raise HTTPException(400, "Crop wajah gagal")

    face = cv2.resize(face, (160, 160))
    face = cv2.cvtColor(face, cv2.COLOR_BGR2RGB)

    face = torch.from_numpy(face).permute(2, 0, 1).float()
    face = face / 255.0
    face = face.unsqueeze(0).to(device)

    return face


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


# ==========================================================
# RECOGNIZE + PRESENSI
# ==========================================================

@app.post("/api/ai/recognize-presensi")
async def recognize_presensi(file: UploadFile = File(...)):

    db = SessionLocal()

    try:
        contents = await file.read()

        img = cv2.imdecode(
            np.frombuffer(contents, np.uint8),
            cv2.IMREAD_COLOR
        )

        if img is None:
            raise HTTPException(400, "Gambar tidak valid")

        # YOLO DETECT
        results = yolo_model(img)

        boxes = []
        for r in results:
            if r.boxes is None:
                continue
            for box in r.boxes:
                x1, y1, x2, y2 = map(int, box.xyxy[0])
                boxes.append((x1, y1, x2, y2))

        if not boxes:
            return {"recognized": []}

        results_output = []

        for (x1, y1, x2, y2) in boxes:

            face = img[y1:y2, x1:x2]

            if face.size == 0:
                continue

            face_tensor = preprocess_facenet(face)

            with torch.no_grad():
                embedding_tensor = facenet_model(face_tensor)

            new_embedding = embedding_tensor[0].cpu().numpy()

            best_score = 0
            best_siswa = None

            for emb in db.query(FaceEmbedding).all():
                saved = np.array(json.loads(emb.embedding))
                score = cosine_similarity(new_embedding, saved)

                if score > best_score:
                    best_score = score
                    best_siswa = emb.siswa_id

            if best_score > 0.7 and best_siswa:

                # cek sudah absen hari ini
                today = datetime.now().date()

                existing = db.query(Presensi).filter(
                    Presensi.siswa_id == best_siswa,
                    Presensi.tanggal >= today
                ).first()

                if not existing:
                    db.add(Presensi(
                        siswa_id=best_siswa,
                        tanggal=datetime.now(),
                        status="Hadir"
                    ))

                results_output.append({
                    "siswa_id": best_siswa,
                    "similarity": float(best_score)
                })

        db.commit()

        return {
            "total_faces": len(boxes),
            "recognized": results_output
        }

    finally:
        db.close()