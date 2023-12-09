*To create an image with specific version move to the directory with Dockerfile and run*

```
docker build -t <image-name>:<tag(optional)> --build-arg CHROMIUM_VERSION=116.0.5845.187 .
```
*If you do not specify CHROMIUM_VERSION, chromium will be installed with 120.0.6099.71 version*

```
docker build -t <image-name>:<tag(optional)>  .
```
You can check chromium versions here https://chromiumdash.appspot.com/releases?platform=Linux

Available snapshots to download https://commondatastorage.googleapis.com/chromium-browser-snapshots/index.html?prefix=Linux_x64/