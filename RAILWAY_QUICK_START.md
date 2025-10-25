# 🚂 RAILWAY.APP - БЫСТРЫЙ СТАРТ (5 МИНУТ!)

## 🎯 ШАГ 1: Регистрация

1. Откройте: **https://railway.app/**
2. Нажмите **"Login with GitHub"**
3. Авторизуйтесь (mraiko23)

---

## 🚀 ШАГ 2: Создание проекта

1. Нажмите **"New Project"**
2. Выберите **"Deploy from GitHub repo"**
3. Выберите: **mraiko23/aichatYMLER**
4. Railway автоматически начнет деплой!

---

## 🗄️ ШАГ 3: Добавить базу данных

1. В проекте нажмите **"+ New"**
2. **"Database"** → **"Add PostgreSQL"**
3. Готово! `DATABASE_URL` установится автоматически

---

## ⚙️ ШАГ 4: Environment Variables

Нажмите на ваш web service → вкладка **"Variables"**

⚠️ **ВАЖНО: Добавьте ВСЕ эти переменные!**

### Variable 1: RAILS_MASTER_KEY
```
678be8eb2fb57237d44c93e381e673d3
```

### Variable 2: SECRET_KEY_BASE
```
c1b3fd3d0d5f38f285154b09e1445dcab54d38b6e05baf4b4f6330436f8944e1b21e2fea73fd5ea86e0b7499773eef92a5cb4a042e80409624c0806d7d64e90a
```

### Variable 3: CLACKY_LLM_API_KEY (или LLM_API_KEY)
```
sk-SJeu29HwKbFU3Bx-ixW9oA
```

### Variable 4: RAILS_ENV
```
production
```

### Variable 5: CLACKY_LLM_BASE_URL (или LLM_BASE_URL)
```
https://proxy.clacky.ai
```

### Variable 6: CLACKY_LLM_MODEL (или LLM_MODEL)
```
gemini-2.5-flash
```

### Variable 7: CLACKY_IMAGE_GEN_MODEL (или IMAGE_GEN_MODEL)
```
gemini-2.5-flash
```

### Variable 8: IMAGE_GEN_SIZE
```
1024x1024
```

### Variable 9: GOOGLE_OAUTH_ENABLED
```
false
```

### Variable 10: FACEBOOK_OAUTH_ENABLED
```
false
```

### Variable 11: TWITTER_OAUTH_ENABLED
```
false
```

### Variable 12: GITHUB_OAUTH_ENABLED
```
false
```

### Variable 13: RAILS_LOG_TO_STDOUT
```
enabled
```

### Variable 14: RAILS_SERVE_STATIC_FILES
```
enabled
```

---

## ✅ ШАГ 5: Дождитесь деплоя

Railway автоматически перезапустит деплой после добавления переменных.

Время деплоя: **3-5 минут**

---

## 👤 ШАГ 6: Создать администратора

1. Web service → **Settings** → найдите кнопку терминала или "Shell"
2. Запустите:

```bash
bundle exec rails console
```

3. Выполните:

```ruby
User.create!(username: 'admin', password: 'ваш_надежный_пароль', role: 'admin')
exit
```

---

## 🎉 ГОТОВО!

Ваше приложение доступно по адресу:
```
https://your-app-name.up.railway.app
```

Войдите как **admin** с вашим паролем!

---

## 💰 СТОИМОСТЬ

Railway дает **$5 бесплатных кредитов каждый месяц**.

Ваше приложение будет стоить **~$3-5/месяц** (покрывается бесплатными кредитами!)

---

## 📚 Подробная документация

Смотрите **RAILWAY_DEPLOYMENT.md** для полной информации.

---

## 🆘 Проблемы?

### Ошибка: "Config error, missing these env keys"
**Решение:** Убедитесь что все 14 переменных добавлены правильно

### Ошибка: "PG::ConnectionBad"
**Решение:** Проверьте что PostgreSQL база данных добавлена и DATABASE_URL установлена автоматически

### Ошибка: "Puma starting in single mode"
**Решение:** Это нормально! Приложение работает корректно

---

## 💡 СОВЕТ

Вы можете использовать ЛИБО `CLACKY_*` переменные, ЛИБО обычные (без префикса).

Примеры:
- `CLACKY_LLM_API_KEY` или `LLM_API_KEY` - оба работают!
- `CLACKY_LLM_BASE_URL` или `LLM_BASE_URL` - оба работают!

Выберите один вариант и используйте его последовательно.

---

✅ **Railway.app - проще чем Render!** 🚂🚀
