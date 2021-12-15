FROM python:3-alpine

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

COPY ./docker/ /app/

RUN chmod +x data_initialization.py

RUN pip install -r requirements.txt

CMD [ "python3", "data_initialization.py" ]
