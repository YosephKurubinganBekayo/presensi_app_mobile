from fastapi import APIRouter, Depends
from security import guru_required

router = APIRouter()

@router.get("/dashboard")
def guru_dashboard(user=Depends(guru_required)):
    return {"message": "Selamat datang guru"}