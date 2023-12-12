To run containers: ```docker compose up -d```

To destroy containers: ```docker compose down```

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

Remember, due to port forwarding 8080:80 you can reach proxy on ```http://localhost:8080```

To check logs run ```journalctl CONTAINER_NAME=<container_name>```

To check application logs move to ```/fluentd/log/``` directory of fluentd container
