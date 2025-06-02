# 🔐 GitHub Secrets Setup для Trader Plus

## Обновленная продакшн конфигурация

### 📝 **Создание prod.env файла**

Создай файл `prod.env` в корне проекта с содержимым:

```bash
# Database Configuration
DB_USER=traderplus_user
DB_PASSWORD=0J-zaDcQy9JHH)9WSHbj
DB_NAME=traderplus_db
DB_CONNECTION_STRING=postgresql://traderplus_user:0J-zaDcQy9JHH)9WSHbj@db:5432/traderplus_db?sslmode=disable

# Email Configuration  
EMAIL_PASSWORD=Lp4p1f2vQvdwgxmefjND
EMAIL_ADDRESS=four-x-teams@mail.ru
SMTP_HOST=smtp.mail.ru
SMTP_PORT=465

# Server Configuration
FRONTEND_PORT=80
PORT=8080
```

### 🚀 **GitHub Secrets (обязательные)**

Создай следующие секреты в репозитории:

#### SSH подключение:
```
HOST = 69.62.112.20
USERNAME = root  
PORT = 22
SSH_KEY = [твой SSH ключ]
```

#### Единый секрет конфигурации:
```
PROD_ENV_FILE = 
DB_USER=traderplus_user
DB_PASSWORD=0J-zaDcQy9JHH)9WSHbj
DB_NAME=traderplus_db
DB_CONNECTION_STRING=postgresql://traderplus_user:0J-zaDcQy9JHH)9WSHbj@db:5432/traderplus_db?sslmode=disable
EMAIL_PASSWORD=Lp4p1f2vQvdwgxmefjND
EMAIL_ADDRESS=four-x-teams@mail.ru
SMTP_HOST=smtp.mail.ru
SMTP_PORT=465
FRONTEND_PORT=80
PORT=8080
```

### 🔧 **Изменения в проекте:**

✅ **Упрощена конфигурация** - только prod.env  
✅ **Улучшен email отправка** - детальное логгирование  
✅ **Рефакторинг API** - добавлены /api/ endpoints  
✅ **Улучшен nginx** - оптимизирован для продакшена  
✅ **Валидация конфига** - проверка обязательных параметров

### 📂 **Структура проекта:**
```
/
├── prod.env              # Продакшн конфигурация
├── latter.html           # Email шаблон  
├── cmd/main.go          # Entry point
├── config/config.go     # Конфигурация
├── internal/taker/      # Бизнес логика
└── TradePlusOnline/     # Frontend
```

### 🚨 **Важно:**
- Файл `prod.env` должен быть в `.gitignore`
- Все секреты только в GitHub Secrets
- Email конфигурация проверена для Mail.ru SMTP

## Перейди в настройки репозитория
1. **Репозиторий**: https://github.com/Alias1177/Trade-plus-Online
2. **Settings** → **Secrets and variables** → **Actions**
3. **New repository secret**

---

## 🎯 **ВАРИАНТ 1: Отдельные секреты (текущий способ)**

### 🖥️ **SSH подключение к серверу**
```
HOST = 69.62.112.20
USERNAME = root
PORT = 22
SSH_KEY = 
-----BEGIN OPENSSH PRIVATE KEY-----
[твой приватный SSH ключ из ~/.ssh/traderplus_deploy]
-----END OPENSSH PRIVATE KEY-----
```

### 💾 **База данных**
```
DB_USER = traderplus_user
DB_PASSWORD = 0J-zaDcQy9JHH)9WSHbj
DB_NAME = traderplus_db
```

### 📧 **Email настройки (Mail.ru)**
```
EMAIL_ADDRESS = four-x-teams@mail.ru
EMAIL_PASSWORD = Lp4p1f2vQvdwgxmefjND
SMTP_HOST = smtp.mail.ru
SMTP_PORT = 465
```

### 🌐 **Веб настройки**
```
FRONTEND_PORT = 80
SECRET = Lp4p1f2vQvdwgxmefjND
```

---

## 🚀 **ВАРИАНТ 2: Один секрет .env.prod (рекомендуется)**

Создай **ОДИН секрет** с именем `ENV_PROD_FILE` и содержимым:

```
DB_USER=traderplus_user
DB_PASSWORD=0J-zaDcQy9JHH)9WSHbj
DB_NAME=traderplus_db
EMAIL_PASSWORD=Lp4p1f2vQvdwgxmefjND
EMAIL_ADDRESS=four-x-teams@mail.ru
SMTP_HOST=smtp.mail.ru
SMTP_PORT=465
FRONTEND_PORT=80
PORT=8080
```

И оставь только эти секреты для SSH:
```
HOST = 69.62.112.20
USERNAME = root
PORT = 22
SSH_KEY = [твой приватный ключ]
```

---

## 🔄 **Обновление GitHub Actions workflow**

Для варианта 2 нужно обновить `.github/workflows/deploy.yml`:

```yaml
- name: Create .env.prod file
  run: |
    echo "${{ secrets.ENV_PROD_FILE }}" > .env.prod
```

Вместо создания отдельных переменных.

---

## ✅ **Преимущества варианта 2:**
- Меньше секретов для управления
- Легче обновлять конфигурацию
- Один источник правды для всех переменных
- Проще синхронизировать с локальной разработкой

## 📝 **Создание .env.prod файла**

Создай файл `.env.prod` в корне проекта с содержимым:

```bash
DB_USER=traderplus_user
DB_PASSWORD=0J-zaDcQy9JHH)9WSHbj
DB_NAME=traderplus_db
DB_CONNECTION_STRING=postgresql://traderplus_user:0J-zaDcQy9JHH)9WSHbj@db:5432/traderplus_db?sslmode=disable

EMAIL_PASSWORD=Lp4p1f2vQvdwgxmefjND
EMAIL_ADDRESS=four-x-teams@mail.ru
SMTP_HOST=smtp.mail.ru
SMTP_PORT=465

FRONTEND_PORT=80
PORT=8080
``` 