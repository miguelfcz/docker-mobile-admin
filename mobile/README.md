# Docker Mobile App

Aplicativo Flutter do Docker Mobile Admin.

## Status

Base inicial criada, login validado, listagem de containers e botoes de acao validados ate o Passo 8.

## Comandos validados

```powershell
flutter analyze
flutter test
flutter build web
```

Para testar o login visualmente, deixe o backend rodando em `http://localhost:3000` e execute:

```powershell
flutter run -d chrome
```

Credenciais padrao de desenvolvimento:

```text
usuario: admin
senha: admin
```

Depois do login, o app busca `GET /containers` usando o token JWT e mostra nome, imagem, estado e status dos containers.

A tela tambem exibe botoes Start, Stop e Restart em cada container. Os Passos 7 e 8 foram validados no app com Docker Desktop aberto e porta `2375` habilitada.
