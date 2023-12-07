FROM debian:stable-slim

LABEL author="Yulyan Glonti"

# ARG PHP_VERSION=8.2

RUN apt-get update && apt-get install -y \
    php\
    apache2 \
    chromium \
    && rm -rf /var/lib/apt/lists/*

EXPOSE 80

# RUN ["/usr/sbin/apache2ctl", "-D", "FOREGROUND"]
# RUN ["/usr/sbin/apache2ctl"]

# # Add chromium user
# RUN groupadd -r chromium && useradd -r -g chromium -G audio,video chromium \
#     && mkdir -p /home/chromium/Downloads && chown -R chromium:chromium /home/chromium

# # Run as non privileged user
# USER chromium
ENTRYPOINT ["/usr/bin/chromium", "--no-sandbox", "--headless", "--disable-gpu","--user-data-dir=/usr/src/app/chromium-data", "http://localhost"]
CMD ["/usr/sbin/apache2ctl", "-D", "FOREGROUND"]