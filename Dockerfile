FROM python:3.12-slim

LABEL org.opencontainers.image.title="MovieBox API Pro"
LABEL org.opencontainers.image.authors="Faisal <https://github.com/faisaljs>"
LABEL org.opencontainers.image.licenses="MIT"

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PORT=8000 \
    CATALOG_DB=/app/data/catalog.db

RUN apt-get update && \
    apt-get install -y --no-install-recommends curl && \
    rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# ✅ COPY EKSPLISIT folder routes/ dan static/ — ini yang hilang di versi lama
COPY routes/ ./routes/
COPY static/ ./static/
COPY *.py ./

# ✅ Verifikasi build — gagal cepat kalau routes/ hilang
RUN test -d /app/routes || (echo "FATAL: folder routes/ tidak ter-copy" && exit 1)
RUN test -f /app/routes/__init__.py || (echo "FATAL: routes/__init__.py tidak ada" && exit 1)
RUN python -c "import routes, main; print('IMPORT OK - routes dan main berhasil di-load')"

RUN mkdir -p /app/data

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
    CMD curl -fsS http://localhost:8000/health || exit 1

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--timeout-keep-alive", "75"]
