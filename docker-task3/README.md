To run containers: ```docker compose up -d```

To destroy containers: ```docker compose down```

Get proxy ip address:

```
docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' proxy
```

App endpoints:

```
http://proxy-ip-address/
http://proxy-ip-address/items
http://proxy-ip-address/items/item_id
```

To create an item in database:

```curl -X POST -H "Content-Type: application/json" -d '{"title": "my-title"}' http://proxy-ip-address/items```

To get an item from cache or database:

```curl -X GET http://proxy-ip-address/items/<item_id>```

To change an item:

```curl -X PUT -H "Content-Type: application/json" -d '{"title": "new-title"}' http://proxy-ip-address/items/<item_id>```

To delete an item:

```curl -X DELETE -H http://proxy-ip-address/items/<item_id>```

To check redis, db, proxy, fluentd logs run ```journalctl CONTAINER_NAME=<container_name>```

To check app logs run ```docker exec -it fluentd tail -f /fluentd/log/data.log```

For production run:
First create an images for app and proxy:

```docker build -t registry.example.com/group/project/image .```

```docker build -t registry.example.com/group/project/image -f DockerfileProxy .```

And push them:

```docker push registry.example.com/group/project/image```

Run in prod:

```docker compose -f compose.yml -f production.yml up -d```
