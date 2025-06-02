# 🔧 Диагностика проблемы с API

## 🚨 Проблема: 
Фронтенд получает HTML вместо JSON ответа при отправке POST запроса к `/insert`

## 🕵️ Диагностика:

### 1. Проверить статус контейнеров:
```bash
ssh root@69.62.112.20
cd /opt/tradeplus
docker compose -f docker-compose.prod.yml ps
```

### 2. Проверить логи backend:
```bash
docker compose -f docker-compose.prod.yml logs backend
```

### 3. Проверить логи nginx:
```bash
docker compose -f docker-compose.prod.yml logs frontend
```

### 4. Проверить что prod.env создан:
```bash
ls -la prod.env
cat prod.env
```

### 5. Проверить доступность API напрямую:
```bash
# Тест внутри сети Docker
docker compose -f docker-compose.prod.yml exec frontend curl -X GET http://backend:8080/health

# Тест с хоста
curl -X GET http://localhost:8080/health
```

### 6. Проверить nginx конфигурацию:
```bash
docker compose -f docker-compose.prod.yml exec frontend nginx -t
```

## 🔧 Возможные исправления:

### Исправление 1: Перезапустить backend
```bash
docker compose -f docker-compose.prod.yml restart backend
```

### Исправление 2: Полный перезапуск
```bash
docker compose -f docker-compose.prod.yml down
docker compose -f docker-compose.prod.yml up -d
```

### Исправление 3: Проверить переменные окружения
```bash
docker compose -f docker-compose.prod.yml exec backend env | grep -E "(EMAIL|DB|SMTP)"
```

## 📋 Быстрый тест API:
```bash
curl -X POST http://trader-plus.online/insert \
  -H "Content-Type: application/json" \
  -d '{
    "selected_id": "Id1",
    "number": "1234567890", 
    "email": "test@example.com",
    "TGNikName": "testuser"
  }'
```

Должен вернуть: `Data saved` (не HTML!) 