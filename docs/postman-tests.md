# Testes no Postman

Base URL:

```text
http://localhost:3000
```

## 1. Health check

```text
GET /health
```

Resultado esperado:

```json
{"status":"ok","service":"docker-mobile-backend","runtime":"dart"}
```

## 2. Login

```text
POST /auth/login
```

Headers:

```text
Content-Type: application/json
```

Body:

```json
{"username":"admin","password":"admin"}
```

Resultado esperado:

```json
{"accessToken":"...","tokenType":"Bearer"}
```

Copie o valor de `accessToken`.

## 3. Listar containers sem token

```text
GET /containers
```

Resultado esperado:

```text
401 Unauthorized
```

## 4. Listar containers com token invalido

Header:

```text
Authorization: Bearer token-invalido
```

Resultado esperado:

```text
401 Unauthorized
```

## 5. Listar containers com token valido

Header:

```text
Authorization: Bearer <accessToken>
```

Resultado esperado:

```text
200 OK
```

O corpo deve trazer a lista de containers reais do Docker Desktop.

## 6. Parar container

```text
POST /containers/<id-ou-nome>/stop
```

Header:

```text
Authorization: Bearer <accessToken>
```

Resultado esperado:

```json
{"success":true,"message":"Container parado."}
```

## 7. Iniciar container

```text
POST /containers/<id-ou-nome>/start
```

Header:

```text
Authorization: Bearer <accessToken>
```

Resultado esperado:

```json
{"success":true,"message":"Container iniciado."}
```

## 8. Reiniciar container

```text
POST /containers/<id-ou-nome>/restart
```

Header:

```text
Authorization: Bearer <accessToken>
```

Resultado esperado:

```json
{"success":true,"message":"Container reiniciado."}
```

## Container de demonstracao

Se precisar criar um container simples para testar:

```powershell
docker run -d --name docker-mobile-demo nginx:alpine
```

Nesse caso, use `docker-mobile-demo` no lugar de `<id-ou-nome>`.
