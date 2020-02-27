FROM python:3

WORKDIR /usr/src/app

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

ENV AWS_ACCESS_KEY_ID='MOCK_KEY_ID'
ENV AWS_SECRET_ACCESS_KEY='MOCK_ACCESS_KEY'

ENTRYPOINT [ "python", "./random-streamer.py" ]
