# Trader Plus Deployment Guide

## Локальная разработка

### Требования
- Go 1.21+
- Node.js 18+
- Docker & Docker Compose
- PostgreSQL

### Быстрый старт
```bash
# Клонируем репозиторий
git clone <your-repo>
cd Strategy

# Запускаем базу данных
docker-compose up -d

# Настраиваем .env
cp .env.example .env
# Отредактируйте .env с вашими настройками

# Запускаем бэкенд
cd cmd && go run main.go

# Запускаем фронтенд (в новом терминале)
cd TradePlusOnline && npm start
```

## Продакшн деплой

### 1. Подготовка сервера
```bash
# Установка Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Создание директории приложения
sudo mkdir -p /opt/tradeplus
sudo chown $USER:$USER /opt/tradeplus
cd /opt/tradeplus

# Клонирование репозитория
git clone <your-repo> .
```

### 2. Настройка GitHub Secrets
В настройках репозитория GitHub добавьте следующие secrets:

**Сервер подключение:**
- `HOST` - IP адрес сервера
- `USERNAME` - пользователь для SSH
- `SSH_KEY` - приватный SSH ключ
- `PORT` - SSH порт (обычно 22)

**База данных:**
- `DB_USER` - пользователь PostgreSQL
- `DB_PASSWORD` - пароль PostgreSQL  
- `DB_NAME` - имя базы данных

**Email настройки:**
- `EMAIL_ADDRESS` - email адрес отправителя
- `EMAIL_PASSWORD` - пароль от email
- `SMTP_HOST` - SMTP сервер (например: smtp.mail.ru)
- `SMTP_PORT` - SMTP порт (обычно 465)

### 3. Автоматический деплой
CI/CD настроен на автоматический деплой при push в main/master ветку:

1. **Test** - запуск тестов Go
2. **Build** - сборка Docker образов и отправка в GitHub Container Registry
3. **Deploy** - автоматический деплой на сервер

### 4. Ручной деплой
```bash
# На сервере
cd /opt/tradeplus

# Создание .env.prod файла
cat > .env.prod << EOF
DB_USER=your_db_user
DB_PASSWORD=your_secure_password
DB_NAME=tradeplus_prod
EMAIL_PASSWORD=your_email_password
EMAIL_ADDRESS=your@email.com
SMTP_HOST=smtp.mail.ru
SMTP_PORT=465
FRONTEND_PORT=80
EOF

# Запуск продакшн версии
docker compose -f docker-compose.prod.yml --env-file .env.prod up -d
```

## Мониторинг

### Health checks
- **Frontend:** http://your-domain/
- **Backend:** http://your-domain/health
- **Database:** автоматические проверки в Docker

### Логи
```bash
# Логи всех сервисов
docker compose -f docker-compose.prod.yml logs -f

# Логи конкретного сервиса
docker compose -f docker-compose.prod.yml logs -f backend
docker compose -f docker-compose.prod.yml logs -f frontend
docker compose -f docker-compose.prod.yml logs -f db
```

### Бэкапы базы данных
```bash
# Создание бэкапа
docker compose -f docker-compose.prod.yml exec db pg_dump -U user mydb > backup_$(date +%Y%m%d_%H%M%S).sql

# Восстановление из бэкапа
docker compose -f docker-compose.prod.yml exec -T db psql -U user mydb < backup_file.sql
```

## Безопасность

### SSL/TLS
Рекомендуется использовать reverse proxy (nginx/traefik) с Let's Encrypt сертификатами:

```nginx
server {
    listen 443 ssl http2;
    server_name yourdomain.com;
    
    ssl_certificate /etc/letsencrypt/live/yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/yourdomain.com/privkey.pem;
    
    location / {
        proxy_pass http://localhost:80;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### Firewall
```bash
# Основные правила UFW
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```

## Масштабирование

### Горизонтальное масштабирование
Для увеличения нагрузки можно запустить несколько инстансов бэкенда:

```yaml
# В docker-compose.prod.yml
backend:
  # ... existing config
  deploy:
    replicas: 3
```

### Мониторинг производительности
- Используйте Prometheus + Grafana для метрик
- Добавьте APM (Application Performance Monitoring)
- Настройте алерты на критические метрики

## Troubleshooting

### Проблемы с контейнерами
```bash
# Перезапуск всех сервисов
docker compose -f docker-compose.prod.yml restart

# Пересборка образов
docker compose -f docker-compose.prod.yml build --no-cache

# Очистка системы
docker system prune -af
```

### Проблемы с базой данных
```bash
# Подключение к базе
docker compose -f docker-compose.prod.yml exec db psql -U user mydb

# Проверка таблиц
\dt

# Проверка данных
SELECT * FROM send LIMIT 10;
``` 