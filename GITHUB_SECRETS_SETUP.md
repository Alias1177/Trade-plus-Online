# 🔐 GitHub Secrets Setup для Trader Plus

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