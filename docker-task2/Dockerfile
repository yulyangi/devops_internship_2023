FROM debian:bookworm-slim

LABEL architecture="amd64" \
      OS="Debian" \
      maintainer="Yulyan Glonti"

# default version
ARG CHROMIUM_VERSION=120.0.6099.0

# update system and install required tools
RUN apt-get update && apt-get install -y \
    apache2 \
    jq \
    curl \
    unzip \
    php \
    wget \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt

SHELL [ "/bin/bash", "-c" ]

# now we want to get position according to our version
# get commit, parrent commit, position
RUN set -o pipefail \
    &&  COMMIT_URL=$(curl -L \
      -H "Accept: application/vnd.github+json" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      "https://api.github.com/repos/chromium/chromium/git/refs/tags/${CHROMIUM_VERSION}" | jq -r ".object.url") \
    &&  PARENTS_URL=$(curl -L \
      -H "Accept: application/vnd.github+json" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      "${COMMIT_URL}" | jq -r ".parents[0].url") \
    && CHROMIUM_POSITION=$(curl -L \
      -H "Accept: application/vnd.github+json" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      "${PARENTS_URL}" | jq -r ".message" | awk -F '@{#' '/refs\/heads\/m/ {print $2}' | awk -F '}' '{print $1}') \
    && wget -O chromium.zip "https://commondatastorage.googleapis.com/chromium-browser-snapshots/Linux_x64/${CHROMIUM_POSITION}/chrome-linux.zip" \
    && unzip chromium.zip \
    && rm chromium.zip \
    && ln -s /opt/chrome-linux/chrome /usr/local/bin/chromium

# install dependencies
RUN apt-get update && apt-get install -y \
    libasound2 libatk-bridge2.0-0 libatk1.0-0 libatomic1 libatspi2.0-0 \
    libc6 libcairo2 libcups2 libdbus-1-3 libdouble-conversion3 libdrm2 \
    libevent-2.1-7 libexpat1 libflac12 libfontconfig1 libfreetype6 \
    libgbm1 libgcc-s1 libgcc-s1 libglib2.0-0 libgtk-3-0 libjpeg62-turbo \
    libjsoncpp25 liblcms2-2 libminizip1 libnspr4 libnss3 libopenh264-7 \
    libopenjp2-7 libopus0 libpango-1.0-0 libpng16-16 libpulse0 \
    libsnappy1v5 libstdc++6 libwebp7 libwebpdemux2 libwebpmux3 \
    libwoff1 libx11-6 libxcb1 libxcomposite1 libxdamage1 libxext6 \
    libxfixes3 libxkbcommon0 libxml2 libxnvctrl0 libxrandr2 libxslt1.1 \
    libxtst6 libxss1 fonts-liberation libxshmfence1 libglu1 zlib1g \
    && rm -rf /var/lib/apt/lists/*

EXPOSE 80 9222

CMD ["chromium", "--no-sandbox","--headless", "--disable-gpu", \
"--disable-software-rasterizer", "--remote-debugging-address=0.0.0.0", \
"--remote-debugging-port=9222"]
