*Please take a look on Dockerfile comments*

**Create an image:**
```
docker build --tag <my-image-name> .
``` 
**Run a container:**
```
docker container run -it --rm -p 8080:80 <my-image-name>
```
