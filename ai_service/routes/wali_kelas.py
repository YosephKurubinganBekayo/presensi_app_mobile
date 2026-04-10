from fastapi import APIRouter, Depends
from security import wali_required

router = APIRouter()

@router.get("/dashboard")
def wali_dashboard(user=Depends(wali_required)):
    return {"message": "Selamat datang wali kelas"}