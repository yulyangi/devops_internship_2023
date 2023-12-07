*Please take a look on Dockerfile comments*

**Create an image:**
```
docker build --tag <my-image-name> .
``` 
**Run an container:**
```
docker container run -it --rm -p 8080 <my-image-name>
```
