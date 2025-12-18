## Design
```
Gateway (demo-gateway)
 ├── Listener: test-bg.makunaiglobal.ai (TLS)
 │     └── HTTPRoute: /grpc → nginx:50051
 │                    /     → nginx:80
 └── Listener: test-2.makunaiglobal.ai (TLS)
       └── HTTPRoute: / → nginx:80

```

