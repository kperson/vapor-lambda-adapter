#!/bin/bash

docker run --rm -it -v $(pwd):/src --workdir /src swift:5.0.1 /bin/bash -c "apt-get -y update && apt-get install -y zlib1g-dev libssl-dev && /bin/bash"
