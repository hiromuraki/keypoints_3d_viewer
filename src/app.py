# 安装依赖: pip install fastapi uvicorn python-multipart numpy
from fastapi import FastAPI, UploadFile, File
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles  # 导入静态文件托管组件
import numpy as np
import io
import os

app = FastAPI()

# --- 核心：静态文件托管 ---
# 将 /static 目录映射到网页根路径，这样访问 http://localhost:8000/ 就能看到 index.html
if not os.path.exists("static"):
    os.makedirs("static")

BONES = [
    [0, 1], [1, 2], [2, 3], [0, 4], [4, 5], [5, 6],
    [0, 7], [7, 8], [8, 9], [9, 10], [8, 11], [11, 12],
    [12, 13], [8, 14], [14, 15], [15, 16]
]


@app.post("/api/upload_npz")
async def process_npz(file: UploadFile = File(...)):
    try:
        content = await file.read()
        npz_data = np.load(io.BytesIO(content), allow_pickle=True)
        key = 'reconstruction' if 'reconstruction' in npz_data else npz_data.files[0]
        data = npz_data[key]

        if len(data.shape) == 4:
            data = data[0]

        return JSONResponse(content={
            "status": "success",
            "num_frames": data.shape[0],
            "bones_topology": BONES,
            "frames": data.tolist()
        })
    except Exception as e:
        return JSONResponse(content={"status": "error", "message": str(e)}, status_code=400)

app.mount("/", StaticFiles(directory="static", html=True), name="static")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
