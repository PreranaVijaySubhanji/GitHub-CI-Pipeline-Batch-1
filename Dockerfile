FROM python:3.12-slim

WORKDIR /app

COPY app/ ./app/

CMD ["python3", "-c", "from app.calculator import add; print('Calculator container is running'); print('10 + 5 =', add(10, 5))"]
