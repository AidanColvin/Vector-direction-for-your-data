from fastapi import FastAPI, UploadFile, File, Form
from typing import List
import os, uuid, shutil

app = FastAPI()

@app.post("/api/run")
async def run_engine(
    mode: str = Form(...),
    models: str = Form(...),
    files: List[UploadFile] = File(...)
):
    job_id = str(uuid.uuid4())[:8]
    save_dir = f"runs/{job_id}"
    os.makedirs(save_dir, exist_ok=True)

    saved_files = []
    for f in files:
        path = os.path.join(save_dir, f.filename)
        with open(path, "wb") as buffer:
            shutil.copyfileobj(f.file, buffer)
        saved_files.append(path)

    return {
        "job_id": job_id,
        "saved_to": save_dir,
        "models": models,
        "files": saved_files
    }
