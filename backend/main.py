"""
Backend mẫu cho app Thử Kính AR.

Mục đích: thay cho việc scrape web (không ổn định), cửa hàng tự upload sản phẩm
kèm ảnh PNG kính ĐÃ TÁCH NỀN, căn thẳng -> app overlay lên mặt rất đẹp.

Chạy:
    pip install -r requirements.txt
    uvicorn main:app --host 0.0.0.0 --port 8000

API:
    GET  /                              health check
    GET  /stores/{store_id}/products    danh sách sản phẩm (JSON)
    POST /stores/{store_id}/products    upload sản phẩm (multipart)
    GET  /stores/{store_id}/upload      form HTML đơn giản để cửa hàng upload
    GET  /media/{filename}              ảnh tĩnh

Lưu trữ: file JSON + thư mục media/ (đủ cho demo; production nên dùng DB + S3).
"""
import json
import os
import uuid
from pathlib import Path

from fastapi import FastAPI, Form, UploadFile, File, HTTPException, Request
from fastapi.responses import HTMLResponse, JSONResponse
from fastapi.staticfiles import StaticFiles

BASE = Path(__file__).parent
MEDIA = BASE / "media"
MEDIA.mkdir(exist_ok=True)
DB_FILE = BASE / "db.json"

app = FastAPI(title="Glasses Store API")
app.mount("/media", StaticFiles(directory=MEDIA), name="media")


def _load() -> dict:
    if DB_FILE.exists():
        return json.loads(DB_FILE.read_text(encoding="utf-8"))
    return {}


def _save(db: dict) -> None:
    DB_FILE.write_text(json.dumps(db, ensure_ascii=False, indent=2), encoding="utf-8")


@app.get("/")
def health():
    return {"status": "ok", "service": "glasses-store-api"}


@app.get("/stores/{store_id}/products")
def list_products(store_id: str, request: Request):
    db = _load()
    products = db.get(store_id, [])
    # Bổ sung URL tuyệt đối cho ảnh để client tải trực tiếp.
    base = str(request.base_url).rstrip("/")
    out = []
    for p in products:
        q = dict(p)
        if q.get("overlay_file"):
            q["overlay_url"] = f"{base}/media/{q['overlay_file']}"
        if q.get("thumbnail_file"):
            q["thumbnail_url"] = f"{base}/media/{q['thumbnail_file']}"
        out.append(q)
    return {"store_id": store_id, "products": out}


@app.post("/stores/{store_id}/products")
async def add_product(
    store_id: str,
    name: str = Form(...),
    price: str = Form(""),
    shape: str = Form("rectangle"),   # rectangle | round | catEye | aviator
    color: str = Form("#222222"),
    overlay: UploadFile | None = File(None),     # PNG kính tách nền
    thumbnail: UploadFile | None = File(None),   # ảnh hiển thị (tuỳ chọn)
):
    if shape not in {"rectangle", "round", "catEye", "aviator"}:
        raise HTTPException(400, "shape không hợp lệ")

    pid = uuid.uuid4().hex[:8]

    def _store(f: UploadFile | None, suffix: str) -> str | None:
        if f is None:
            return None
        ext = os.path.splitext(f.filename or "")[1] or ".png"
        fname = f"{store_id}_{pid}_{suffix}{ext}"
        (MEDIA / fname).write_bytes(f.file.read())
        return fname

    product = {
        "id": pid,
        "name": name,
        "price": price,
        "shape": shape,
        "color": color,
        "overlay_file": _store(overlay, "overlay"),
        "thumbnail_file": _store(thumbnail, "thumb"),
    }

    db = _load()
    db.setdefault(store_id, []).append(product)
    _save(db)
    return JSONResponse({"ok": True, "product": product})


@app.get("/stores/{store_id}/upload", response_class=HTMLResponse)
def upload_form(store_id: str):
    return f"""
    <html><body style="font-family:sans-serif;max-width:480px;margin:40px auto">
    <h2>Upload kính - cửa hàng: {store_id}</h2>
    <form action="/stores/{store_id}/products" method="post" enctype="multipart/form-data">
      <p>Tên: <input name="name" required></p>
      <p>Giá: <input name="price"></p>
      <p>Kiểu:
        <select name="shape">
          <option value="rectangle">Chữ nhật</option>
          <option value="round">Tròn</option>
          <option value="catEye">Mắt mèo</option>
          <option value="aviator">Aviator</option>
        </select>
      </p>
      <p>Màu (hex): <input name="color" value="#222222"></p>
      <p>Ảnh PNG kính (tách nền): <input type="file" name="overlay" accept="image/png"></p>
      <p>Ảnh hiển thị (tuỳ chọn): <input type="file" name="thumbnail" accept="image/*"></p>
      <button type="submit">Lưu sản phẩm</button>
    </form>
    </body></html>
    """
