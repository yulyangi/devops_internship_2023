## Create an image
To create an image with specific version of chromium move to the directory with Dockerfile and run

```
docker build -t <image-name>:<tag(optional)> --build-arg CHROMIUM_VERSION=116.0.5845.187 .
```
If you do not specify CHROMIUM_VERSION, chromium will be installed with 120.0.6099.71 version

```
docker build -t <image-name>:<tag(optional)>  .
```
Remember! Not all version are available for installation

Available snapshots for installation https://commondatastorage.googleapis.com/chromium-browser-snapshots/index.html?prefix=Linux_x64/

You can check chromium versions here https://chromiumdash.appspot.com/releases?platform=Linux

## Run a container
If you want to run a container as apache2 server execute
```
docker run -it --rm -d -p 8080:80 <your-image> apache2ctl -D FOREGROUND
```
You can check apache2 on http://localhost:8080

If you want to run a container as a chromium execute
```
docker run -it --rm -d -p 9222:9222 <your-image>
```
You can check chromium devtools on http://localhost:9222