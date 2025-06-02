# 🚀 Trader Plus - Trading Course & AI Bot Platform

Продакшн-готовая платформа для предзаказа торговых курсов и AI ботов с автоматической отправкой email уведомлений и полной HTTPS поддержкой.

## 🏗️ Архитектура

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Nginx Frontend │    │   Go Backend    │    │  PostgreSQL DB  │
│   (TradePlusOnline)│    │   (Strategy)    │    │                 │
│   HTTP: 80       │───▶│   Port: 8080    │───▶│   Port: 5432    │
│   HTTPS: 443     │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                        │
         ▼                        ▼
┌─────────────────┐    ┌─────────────────┐
│   Let's Encrypt │    │   Mail.ru SMTP  │
│   SSL Certs     │    │   Port: 465     │
└─────────────────┘    └─────────────────┘
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

### 4. 🔒 Настроить HTTPS (рекомендуется)
```bash
# Инициализация SSL сертификатов
./init-letsencrypt.sh

# Настройка автообновления
./setup-ssl-renewal.sh
```

## 📋 API Endpoints

| Endpoint | Method | Описание | HTTP | HTTPS |
|----------|--------|----------|------|-------|
| `/insert` | POST | Создание предзаказа | ✅ | ✅ |
| `/health` | GET | Проверка здоровья | ✅ | ✅ |
| `/records` | GET | Получение всех записей | ✅ | ✅ |
| `/api/insert` | POST | API версия создания предзаказа | ✅ | ✅ |
| `/api/health` | GET | API версия проверки здоровья | ✅ | ✅ |
| `/api/records` | GET | API версия получения записей | ✅ | ✅ |

### Пример запроса
```javascript
POST https://trader-plus.online/insert
Content-Type: application/json

{
  "selected_id": "Id1",
  "number": "1234567890",
  "email": "user@example.com",
  "TGNikName": "username"
}
```

## 🔒 HTTPS Configuration

### Автоматические SSL сертификаты
- **Let's Encrypt** - бесплатные SSL сертификаты
- **Автообновление** каждые 60 дней
- **HTTP → HTTPS** автоматический редирект
- **A+ Security Rating** современные протоколы TLS 1.2/1.3

### Быстрая настройка HTTPS
```bash
# 1. Инициализация SSL
./init-letsencrypt.sh

# 2. Настройка автообновления
./setup-ssl-renewal.sh

# 3. Проверка работы
curl -I https://trader-plus.online
```

### Структура SSL файлов
```
/opt/tradeplus/
├── certbot/
│   ├── conf/live/trader-plus.online/
│   │   ├── fullchain.pem
│   │   ├── privkey.pem
│   │   └── chain.pem
│   └── www/
├── init-letsencrypt.sh
├── setup-ssl-renewal.sh
└── ssl-renewal.log
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

- ✅ **HTTPS Everywhere** - принудительное HTTPS
- ✅ **TLS 1.2/1.3** - современные протоколы шифрования
- ✅ **HSTS** - строгая безопасность транспорта
- ✅ **CORS** настроен для продакшена
- ✅ **Security Headers** - защитные заголовки
- ✅ **Валидация данных** - проверка входящих данных
- ✅ **Проверка дубликатов** email/телефонов
- ✅ **TLS для SMTP** - шифрованная отправка email
- ✅ **Безопасные Docker контейнеры**

## 📊 Мониторинг

### Health check:
```bash
curl https://trader-plus.online/health
# Ответ: "здоров"
```

### Получение записей:
```bash
curl https://trader-plus.online/records
# Возвращает JSON массив всех записей
```

### SSL мониторинг:
```bash
# Проверка SSL сертификата
./ssl-monitor.sh

# Логи автообновления
tail -f ssl-renewal.log
```

## 🚨 Отладка проблем

### Проблемы с HTTPS
```bash
# Проверка SSL сертификата
openssl s_client -connect trader-plus.online:443

# Проверка nginx конфигурации
docker compose -f docker-compose.prod.yml exec frontend nginx -t

# Логи nginx
docker compose -f docker-compose.prod.yml logs frontend
```

### Отладка проблем с email
```bash
docker compose -f docker-compose.prod.yml logs backend
```

### Типичные ошибки:
1. **DNS не настроен** - проверьте что домен указывает на сервер
2. **Порты закрыты** - откройте 80 и 443 порты
3. **Неправильный пароль приложения** - создайте новый в Mail.ru
4. **Файл latter.html не найден** - проверьте WORKDIR в Dockerfile

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
├── latter.html             # Email шаблон
├── init-letsencrypt.sh     # Инициализация SSL
├── setup-ssl-renewal.sh    # Настройка автообновления
└── HTTPS_SETUP.md          # Подробная инструкция HTTPS
```

## 🎯 Roadmap

- [x] HTTPS поддержка с Let's Encrypt
- [x] Автообновление SSL сертификатов
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
4. Порты 80, 443 и 8080 открыты
5. DNS домена указывает на сервер

### HTTPS Troubleshooting
Подробная инструкция по настройке и решению проблем с HTTPS: [HTTPS_SETUP.md](HTTPS_SETUP.md)

---

**Made with ❤️ and 🔒 for Trader Plus community** 