# Roteiro de demonstracao

Este roteiro serve para apresentar o MVP do Docker Mobile Admin.

## 1. Preparar o Docker Desktop

Abra o Docker Desktop e confirme se a API local esta habilitada:

```text
Settings > General > Expose daemon on tcp://localhost:2375 without TLS
```

Depois teste no PowerShell:

```powershell
Test-NetConnection -ComputerName 127.0.0.1 -Port 2375
docker ps
```

Resultado esperado:

```text
TcpTestSucceeded : True
```

Se nao houver containers para demonstrar, crie um container simples:

```powershell
docker run -d --name docker-mobile-demo nginx:alpine
```

## 2. Rodar o backend

Em um terminal:

```powershell
cd "C:\Users\Miguel\Desktop\PROGRAMACAO\Docker Mobile\backend"
dart pub get
dart analyze
dart run bin/server.dart
```

Validar o backend:

```powershell
Invoke-RestMethod http://localhost:3000/health
```

Resultado esperado:

```json
{"status":"ok","service":"docker-mobile-backend","runtime":"dart"}
```

## 3. Rodar o app Flutter

Em outro terminal:

```powershell
cd "C:\Users\Miguel\Desktop\PROGRAMACAO\Docker Mobile\mobile"
flutter pub get
flutter analyze
flutter test
flutter run -d chrome
```

## 4. Fazer login

Na tela do app:

```text
URL do backend: http://localhost:3000
Usuario: admin
Senha: admin
```

Resultado esperado:

- o login entra no painel;
- a lista de containers aparece;
- cada container mostra nome, imagem, estado, status e ID curto.

## 5. Demonstrar acoes

Na tela de containers:

1. Clique em Stop em um container rodando.
2. Aguarde o feedback de sucesso.
3. Confirme que a lista atualizou.
4. Clique em Start para iniciar novamente.
5. Clique em Restart para reiniciar.

As acoes tambem podem ser conferidas no terminal:

```powershell
docker ps -a
```

## 6. Testar pelo Postman

Use a base URL:

```text
http://localhost:3000
```

Fluxo sugerido:

1. `GET /health`
2. `POST /auth/login`
3. copiar o `accessToken`
4. `GET /containers` com `Authorization: Bearer <accessToken>`
5. `POST /containers/:id/stop`
6. `POST /containers/:id/start`
7. `POST /containers/:id/restart`

## 7. Checklist final

- Backend inicia sem erro.
- `GET /health` retorna `status: ok`.
- Login valido retorna token JWT.
- Login invalido mostra erro.
- App Flutter abre no Chrome.
- Login no app entra no painel.
- Containers reais aparecem no app.
- Botoes Start, Stop e Restart alteram o estado no Docker Desktop.
- README e documentacao explicam como rodar o projeto.

## 8. Limpeza opcional

Se voce criou o container de demonstracao, pode remover no final:

```powershell
docker rm -f docker-mobile-demo
```
