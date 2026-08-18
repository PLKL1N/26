FROM python:3.14-alpine

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

COPY ./app.py /app/app.py

RUN apk add --no-cache curl && pip install --no-cache-dir boto3 flask && rm -rf /root/.cache/

RUN adduser -D --disabled-password --gecos '' app-user
USER app-user

EXPOSE 8080

CMD ["python", "/app/app.py"]
