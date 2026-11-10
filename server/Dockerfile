FROM python:3.12-slim
WORKDIR /app
RUN mkdir -p /data
COPY requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt
COPY world_server.py /app/world_server.py
ENV ABYSSAL_DATABASE=/data/abyssal.sqlite3
ENV ABYSSAL_BIND=0.0.0.0
ENV PORT=8787
EXPOSE 8787
# Mount /data on persistent storage; put TLS in front in production.
CMD ["python", "/app/world_server.py"]
