# 🔒 HTTPS Setup Guide для Trader Plus

Полная инструкция по настройке HTTPS с автоматическими SSL сертификатами от Let's Encrypt.

## 📋 Предварительные требования

✅ **Домен настроен**: `trader-plus.online` должен указывать на ваш сервер (69.62.112.20)  
✅ **Проект запущен**: Backend и frontend работают  
✅ **Порты открыты**: 80 и 443 доступны  

## 🚀 Быстрая установка

### 1. Подготовка файлов
```bash
# Сделать скрипты исполняемыми
chmod +x init-letsencrypt.sh
chmod +x setup-ssl-renewal.sh
```

### 2. Инициализация SSL
```bash
# На сервере
cd /opt/tradeplus
./init-letsencrypt.sh
```

### 3. Настройка автообновления
```bash
# Настроить cron для автоматического обновления
./setup-ssl-renewal.sh
```

## 🔧 Пошаговая инструкция

### Шаг 1: Проверка DNS
Убедитесь что домен указывает на сервер:
```bash
dig trader-plus.online
nslookup trader-plus.online
```

### Шаг 2: Остановка текущих контейнеров
```bash
cd /opt/tradeplus
docker compose -f docker-compose.prod.yml down
```

### Шаг 3: Обновление конфигурации
```bash
# Подтянуть последние изменения
git pull origin main

# Пересобрать контейнеры с HTTPS поддержкой
docker compose -f docker-compose.prod.yml build --no-cache frontend
```

### Шаг 4: Инициализация SSL
```bash
# Запустить скрипт инициализации
./init-letsencrypt.sh
```

Скрипт выполнит:
1. 📁 Создаст необходимые директории
2. 🔧 Создаст временный сертификат
3. 🚀 Запустит nginx
4. 🔐 Получит настоящий SSL сертификат
5. 🔄 Перезапустит nginx с HTTPS

### Шаг 5: Настройка автообновления
```bash
# Настроить автоматическое обновление сертификатов
./setup-ssl-renewal.sh
```

## 📊 Проверка работы

### Проверка сертификата
```bash
# Проверка статуса
curl -I https://trader-plus.online

# Детальная информация о сертификате
echo | openssl s_client -servername trader-plus.online -connect trader-plus.online:443 2>/dev/null | openssl x509 -noout -text
```

### Проверка редиректов
```bash
# HTTP должен перенаправлять на HTTPS
curl -I http://trader-plus.online
```

### Проверка API через HTTPS
```bash
# Тест API endpoint
curl -X GET https://trader-plus.online/health

# Тест POST запроса
curl -X POST https://trader-plus.online/insert \
  -H "Content-Type: application/json" \
  -d '{"selected_id": "Id1", "number": "1234567890", "email": "test@example.com", "TGNikName": "testuser"}'
```

## 🔄 Автообновление сертификатов

### Как это работает
- **Cron job** запускается 2 раза в день (2:30 и 14:30)
- **Проверяет** необходимость обновления сертификата
- **Обновляет** сертификат если до истечения < 30 дней
- **Перезагружает** nginx автоматически

### Ручное тестирование
```bash
# Тестировать обновление
./test-ssl-renewal.sh

# Просмотр логов
tail -f /opt/tradeplus/ssl-renewal.log

# Ручное обновление
./renew-ssl.sh
```

## 🛠️ Troubleshooting

### Проблема 1: DNS не настроен
**Симптом**: `Failed to obtain SSL certificate`
**Решение**: 
```bash
# Проверить DNS
dig trader-plus.online A
# Должен вернуть 69.62.112.20
```

### Проблема 2: Порты заблокированы
**Симптом**: Connection timeout
**Решение**:
```bash
# Проверить что порты открыты
netstat -tulpn | grep :80
netstat -tulpn | grep :443

# Проверить firewall
ufw status
```

### Проблема 3: Nginx ошибка конфигурации
**Симптом**: Nginx не стартует
**Решение**:
```bash
# Проверить конфигурацию
docker compose -f docker-compose.prod.yml exec frontend nginx -t

# Просмотр логов
docker compose -f docker-compose.prod.yml logs frontend
```

### Проблема 4: Сертификат не обновляется
**Симптом**: Старый сертификат
**Решение**:
```bash
# Проверить cron
crontab -l

# Ручное обновление
./renew-ssl.sh

# Проверить логи
cat /opt/tradeplus/ssl-renewal.log
```

## 📁 Структура файлов SSL

```
/opt/tradeplus/
├── certbot/
│   ├── conf/              # Конфигурация Let's Encrypt
│   │   ├── live/trader-plus.online/
│   │   │   ├── fullchain.pem    # Полная цепочка сертификатов
│   │   │   ├── privkey.pem      # Приватный ключ
│   │   │   └── chain.pem        # Промежуточные сертификаты
│   │   ├── options-ssl-nginx.conf
│   │   └── ssl-dhparams.pem
│   └── www/               # Webroot для проверки домена
├── init-letsencrypt.sh    # Скрипт инициализации SSL
├── setup-ssl-renewal.sh   # Настройка автообновления
├── renew-ssl.sh          # Скрипт обновления (создается автоматически)
└── ssl-renewal.log       # Логи обновления
```

## 🔐 Безопасность

### Настройки безопасности
- **TLS 1.2/1.3** только современные протоколы
- **HSTS** принудительное использование HTTPS
- **Perfect Forward Secrecy** защита от компрометации ключей
- **OCSP Stapling** быстрая проверка отзыва сертификатов

### Тестирование безопасности
```bash
# SSL Labs тест (откройте в браузере)
# https://www.ssllabs.com/ssltest/analyze.html?d=trader-plus.online

# Тест с помощью testssl.sh
docker run --rm -ti drwetter/testssl.sh trader-plus.online
```

## 📈 Мониторинг

### Проверка статуса SSL
```bash
# Создать скрипт мониторинга
cat > /opt/tradeplus/ssl-monitor.sh << 'EOF'
#!/bin/bash
echo "🔍 SSL Certificate Status for trader-plus.online"
echo "================================================"

# Проверка срока действия
EXPIRY=$(echo | openssl s_client -servername trader-plus.online -connect trader-plus.online:443 2>/dev/null | openssl x509 -noout -enddate | cut -d= -f2)
echo "📅 Certificate expires: $EXPIRY"

# Проверка доступности
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" https://trader-plus.online)
echo "🌐 HTTPS Status: $HTTP_CODE"

# Проверка редиректа
HTTP_REDIRECT=$(curl -s -o /dev/null -w "%{http_code}" http://trader-plus.online)
echo "🔄 HTTP Redirect: $HTTP_REDIRECT"
EOF

chmod +x /opt/tradeplus/ssl-monitor.sh
```

## 🎯 Результат

После успешной настройки:

✅ **https://trader-plus.online** - работает с зеленым замком  
✅ **http://trader-plus.online** - автоматически перенаправляется на HTTPS  
✅ **API endpoints** доступны по HTTPS  
✅ **Автообновление** сертификатов каждые 60 дней  
✅ **A+ рейтинг** безопасности SSL

---

**🎉 Поздравляем! Ваш сайт теперь защищен HTTPS!** 🔒 