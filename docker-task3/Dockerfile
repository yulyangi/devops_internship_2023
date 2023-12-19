FROM python:3.9.18-alpine
WORKDIR /app
ENV FLASK_APP=app.py
ENV FLASK_RUN_HOST=0.0.0.0
RUN apk update && apk add curl && rm -rf /var/cache/apk/*
COPY src/requirements.txt requirements.txt
RUN pip install --no-cache-dir -r requirements.txt
EXPOSE 5000
COPY src/ .
CMD ["flask", "run"]
