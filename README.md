# 🚀 Trader Plus - Trading Course & AI Bot Platform

Продакшн-готовая платформа для предзаказа торговых курсов и AI ботов с автоматической отправкой email уведомлений.

## 🏗️ Архитектура

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Nginx Frontend │    │   Go Backend    │    │  PostgreSQL DB  │
│   (TradePlusOnline)│    │   (Strategy)    │    │                 │
│   Port: 80       │───▶│   Port: 8080    │───▶│   Port: 5432    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                 │
                                 ▼
                       ┌─────────────────┐
                       │   Mail.ru SMTP  │
                       │   Port: 465     │
                       └─────────────────┘
```

## 🚀 Быстрый старт

### 1. Склонировать репозиторий
```bash
git clone <repository-url>
cd Strategy
```

### 2. Настроить продакшн конфигурацию
```bash
cp prod.env.example prod.env
# Отредактировать prod.env с реальными значениями
```

### 3. Запустить с Docker
```bash
docker compose -f docker-compose.prod.yml up -d
```

## 📋 API Endpoints

| Endpoint | Method | Описание |
|----------|--------|----------|
| `/insert` | POST | Создание предзаказа |
| `/health` | GET | Проверка здоровья |
| `/records` | GET | Получение всех записей |
| `/api/insert` | POST | API версия создания предзаказа |
| `/api/health` | GET | API версия проверки здоровья |
| `/api/records` | GET | API версия получения записей |

### Пример запроса
```javascript
POST /insert
Content-Type: application/json

{
  "selected_id": "Id1",
  "number": "1234567890",
  "email": "user@example.com",
  "TGNikName": "username"
}
```

## 🔧 GitHub Secrets Setup

### Обязательные секреты:

#### 1. SSH подключение:
```
HOST = 69.62.112.20
USERNAME = root
PORT = 22
SSH_KEY = [ваш SSH ключ]
```

#### 2. Единый конфигурационный секрет:
Создайте секрет `PROD_ENV_FILE` с содержимым:
```
DB_USER=traderplus_user
DB_PASSWORD=ваш_пароль_бд
DB_NAME=traderplus_db
DB_CONNECTION_STRING=postgresql://traderplus_user:ваш_пароль_бд@db:5432/traderplus_db?sslmode=disable
EMAIL_PASSWORD=ваш_пароль_email
EMAIL_ADDRESS=ваш-email@mail.ru
SMTP_HOST=smtp.mail.ru
SMTP_PORT=465
FRONTEND_PORT=80
PORT=8080
```

### Удалить старые секреты:
После создания `PROD_ENV_FILE` можно удалить:
- DB_NAME
- DB_PASSWORD  
- DB_USER
- EMAIL_ADDRESS
- EMAIL_PASSWORD
- ENV_PROD_FILE (старое название)
- SMTP_HOST
- SMTP_PORT

## 📧 Email Configuration

Проект настроен для работы с **Mail.ru SMTP**:
- **Host**: `smtp.mail.ru`
- **Port**: `465` (SSL/TLS)
- **Alternative**: `587` (STARTTLS)

### Получение пароля приложения Mail.ru:
1. Войдите в mail.ru
2. Настройки → Пароль и безопасность
3. Пароли для внешних приложений
4. Создайте пароль для "SMTP"

## 🗄️ База данных

### Структура таблицы `send`:
```sql
CREATE TABLE send (
    Number TEXT NOT NULL,
    Email TEXT NOT NULL,
    TGNikName TEXT NOT NULL,
    Id1 TEXT NOT NULL,
    Id2 TEXT NOT NULL,
    Id3 TEXT NOT NULL
);
```

### Package IDs:
- `Id1` - Trading Course Only
- `Id2` - AI Trading Bot Only  
- `Id3` - Complete Package (Course + Bot)

## 🔒 Безопасность

- ✅ CORS настроен для продакшена
- ✅ Nginx security headers
- ✅ Валидация входящих данных
- ✅ Проверка дубликатов email/телефонов
- ✅ TLS для SMTP соединений
- ✅ Безопасные Docker контейнеры

## 📊 Мониторинг

### Health check:
```bash
curl http://localhost/health
# Ответ: "здоров"
```

### Получение записей:
```bash
curl http://localhost/records
# Возвращает JSON массив всех записей
```

## 🚨 Отладка проблем с email

### Проверка логов:
```bash
docker compose -f docker-compose.prod.yml logs backend
```

### Типичные ошибки:
1. **Неправильный пароль приложения** - создайте новый в Mail.ru
2. **Блокировка SMTP** - проверьте настройки Mail.ru
3. **Файл latter.html не найден** - проверьте что файл скопирован в контейнер

## 📁 Структура проекта

```
Strategy/
├── cmd/main.go              # Entry point
├── config/config.go         # Конфигурация
├── internal/taker/          # Бизнес логика
├── TradePlusOnline/         # Frontend (Nginx)
├── db/db.sql               # SQL схема
├── prod.env.example        # Пример конфигурации
├── docker-compose.prod.yml # Продакшн compose
├── Dockerfile              # Backend image
└── latter.html             # Email шаблон
```

## 🎯 Roadmap

- [ ] Admin панель для управления записями
- [ ] Telegram бот интеграция
- [ ] Продвинутая аналитика
- [ ] A/B тестирование форм
- [ ] Multi-language support

## 📞 Поддержка

При проблемах с развертыванием проверьте:
1. GitHub Secrets настроены правильно
2. SSH ключ имеет доступ к серверу
3. Docker и docker-compose установлены на сервере
4. Порты 80 и 8080 открыты

---

**Made with ❤️ for Trader Plus community** 