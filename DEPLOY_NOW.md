# 🚀 БЫСТРЫЙ СТАРТ: ДЕПЛОЙ НА RENDER

## ✅ ШАГ 1: Откройте Render Dashboard

👉 https://dashboard.render.com/

## ✅ ШАГ 2: Создайте новый Blueprint

1. Нажмите **"New +"** в правом верхнем углу
2. Выберите **"Blueprint"**
3. Подключите репозиторий: **mraiko23/aichatYMLER**

## ✅ ШАГ 3: Добавьте Environment Variables

В настройках сервиса **"aichat-web"** добавьте эти 3 секретных ключа:

### Variable 1: RAILS_MASTER_KEY
```
678be8eb2fb57237d44c93e381e673d3
```

### Variable 2: SECRET_KEY_BASE
```
c1b3fd3d0d5f38f285154b09e1445dcab54d38b6e05baf4b4f6330436f8944e1b21e2fea73fd5ea86e0b7499773eef92a5cb4a042e80409624c0806d7d64e90a
```

### Variable 3: CLACKY_LLM_API_KEY
```
sk-SJeu29HwKbFU3Bx-ixW9oA
```

### Variable 4: DATABASE_URL
- Выберите **"From Database"**
- Выберите **testaichatbot-db**
- Выберите **Connection String**

## ✅ ШАГ 4: Запустите деплой

1. Нажмите **"Apply"**
2. Дождитесь завершения деплоя (5-10 минут)

## 🎉 ШАГ 5: Откройте ваше приложение!

Render покажет URL вашего приложения:
```
https://aichat-web-XXXX.onrender.com
```

---

## 💡 ВАЖНО!

✅ **Все остальные переменные окружения** (IMAGE_GEN_SIZE, GOOGLE_OAUTH_ENABLED, и т.д.) 
   уже настроены в `render.yaml` и будут установлены **автоматически**!

✅ Вам нужно добавить **ТОЛЬКО 3 секретных ключа** вручную:
   - RAILS_MASTER_KEY
   - SECRET_KEY_BASE
   - CLACKY_LLM_API_KEY

---

## 👤 После деплоя: Создайте администратора

1. Зайдите: **Dashboard → aichat-web → Shell**
2. Выполните команды:

```bash
rails console
```

```ruby
User.create!(username: 'admin', password: 'ваш_надежный_пароль', role: 'admin')
exit
```

3. Войдите на сайте с этими данными

---

## 📚 Полная документация

Смотрите **RENDER_DEPLOYMENT.md** для подробных инструкций.

Смотрите **RENDER_SECRETS.txt** для всех секретных ключей.

---

## 🔒 Безопасность

⚠️ **НИКОГДА** не публикуйте файл RENDER_SECRETS.txt!

⚠️ Он уже добавлен в .gitignore и не будет загружен в Git.

⚠️ Храните ключи в менеджере паролей (1Password, Bitwarden, LastPass).

---

## 🆘 Проблемы?

1. Проверьте логи в Render Dashboard
2. Убедитесь, что все 3 секретных ключа добавлены правильно
3. Проверьте, что DATABASE_URL подключен к базе данных testaichatbot-db

---

✅ **Готово! Ваше приложение работает на Render!** 🎉
