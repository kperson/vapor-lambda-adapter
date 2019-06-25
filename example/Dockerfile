FROM swift:5.0.1

ADD . /code
WORKDIR /code

RUN apt-get -y update 
RUN apt-get install -y zlib1g-dev libssl-dev
RUN swift build -c release
