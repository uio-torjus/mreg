FROM python:3.8

RUN apt-get update \
    && apt-get install -y sqlite3 build-essential libsasl2-dev \
       libldap2-dev libssl-dev postgresql-client \
    && apt-get clean
WORKDIR /app
COPY requirements.txt /app/requirements.txt
RUN pip install -r requirements.txt
COPY . /app

CMD ["/app/docker-entrypoint.sh"]
