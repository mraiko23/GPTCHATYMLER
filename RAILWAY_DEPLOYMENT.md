# 🚂 ДЕПЛОЙ НА RAILWAY.APP

Railway.app - современная платформа для деплоя с бесплатным тарифом $5 в месяц кредитов.

---

## ✅ ПРЕИМУЩЕСТВА RAILWAY

✨ **Проще чем Render:**
- Автоматическое определение Rails приложений
- Встроенная PostgreSQL база данных в один клик
- Автоматический SSL сертификат
- Простой интерфейс
- Быстрый деплой (3-5 минут)

💰 **Бесплатный тариф:**
- $5 кредитов каждый месяц БЕСПЛАТНО
- Этого хватит на небольшое приложение
- Кредитная карта НЕ требуется для старта

🚀 **Автоматика:**
- Автоматический деплой при push в GitHub
- Автоматические миграции базы данных
- Автоматическое обнаружение Rails

---

## 🚀 БЫСТРЫЙ СТАРТ (5 МИНУТ)

### Шаг 1: Регистрация на Railway

1. Откройте: **https://railway.app/**
2. Нажмите **"Start a New Project"** или **"Login with GitHub"**
3. Авторизуйтесь через GitHub (mraiko23)

### Шаг 2: Создание проекта

1. На главной странице нажмите **"New Project"**
2. Выберите **"Deploy from GitHub repo"**
3. Найдите и выберите репозиторий: **mraiko23/aichatYMLER**
4. Railway автоматически определит Rails приложение!

### Шаг 3: Добавление PostgreSQL базы данных

1. В вашем проекте нажмите **"+ New"**
2. Выберите **"Database"** → **"Add PostgreSQL"**
3. Railway автоматически создаст базу данных
4. Railway автоматически установит переменную `DATABASE_URL`!

### Шаг 4: Настройка переменных окружения

В разделе вашего сервиса (web service) перейдите на вкладку **"Variables"**.

Добавьте следующие переменные:

#### 1. RAILS_MASTER_KEY
```
678be8eb2fb57237d44c93e381e673d3
```

#### 2. SECRET_KEY_BASE
```
c1b3fd3d0d5f38f285154b09e1445dcab54d38b6e05baf4b4f6330436f8944e1b21e2fea73fd5ea86e0b7499773eef92a5cb4a042e80409624c0806d7d64e90a
```

#### 3. CLACKY_LLM_API_KEY
```
sk-SJeu29HwKbFU3Bx-ixW9oA
```

#### 4. RAILS_ENV
```
production
```

#### 5. CLACKY_LLM_BASE_URL
```
https://proxy.clacky.ai
```

#### 6. CLACKY_LLM_MODEL
```
gemini-2.5-flash
```

#### 7. CLACKY_IMAGE_GEN_MODEL
```
gemini-2.5-flash
```

#### 8. IMAGE_GEN_SIZE
```
1024x1024
```

#### 9. GOOGLE_OAUTH_ENABLED
```
false
```

#### 10. FACEBOOK_OAUTH_ENABLED
```
false
```

#### 11. TWITTER_OAUTH_ENABLED
```
false
```

#### 12. GITHUB_OAUTH_ENABLED
```
false
```

#### 13. RAILS_LOG_TO_STDOUT
```
enabled
```

#### 14. RAILS_SERVE_STATIC_FILES
```
enabled
```

### Шаг 5: Деплой!

1. После добавления всех переменных Railway автоматически запустит деплой
2. Дождитесь завершения (3-5 минут)
3. Railway покажет URL вашего приложения (например: `your-app.up.railway.app`)

---

## 🎯 ПОСЛЕ ДЕПЛОЯ: Создание администратора

### Через Railway Shell:

1. В Railway Dashboard откройте ваш проект
2. Выберите web service
3. Перейдите на вкладку **"Settings"**
4. Найдите секцию **"Service"** и нажмите **"Deploy Logs"**
5. Справа вверху найдите кнопку с иконкой терминала или три точки
6. Выберите **"Run Command"** или **"Shell"**
7. Выполните команды:

```bash
# Запустить Rails консоль
bundle exec rails console

# Создать администратора
User.create!(username: 'admin', password: 'ваш_надежный_пароль', role: 'admin')

# Выйти
exit
```

Готово! Теперь войдите на сайт с логином `admin` и вашим паролем.

---

## 📋 АВТОМАТИЧЕСКИ НАСТРОЕНО

Railway автоматически:
- ✅ Определяет Rails приложение
- ✅ Устанавливает Ruby версию из `.ruby-version`
- ✅ Запускает `bundle install`
- ✅ Компилирует assets (`rails assets:precompile`)
- ✅ Запускает миграции (`rails db:migrate`)
- ✅ Создает PostgreSQL базу данных
- ✅ Устанавливает `DATABASE_URL` автоматически
- ✅ Привязывает домен с SSL сертификатом
- ✅ Автоматически деплоит при push в GitHub

---

## 🔧 ФАЙЛЫ КОНФИГУРАЦИИ

В репозитории уже созданы:

### 1. `railway.json`
Конфигурация Railway для билда и деплоя:
```json
{
  "build": {
    "builder": "NIXPACKS",
    "buildCommand": "bundle install && bundle exec rails assets:precompile && bundle exec rails assets:clean"
  },
  "deploy": {
    "startCommand": "bundle exec rails db:migrate && bundle exec puma -C config/puma.rb",
    "restartPolicyType": "ON_FAILURE",
    "restartPolicyMaxRetries": 10
  }
}
```

### 2. `Procfile`
Процессы для запуска:
```
web: bundle exec puma -C config/puma.rb
release: bundle exec rails db:migrate
```

### 3. `config/puma.rb`
Настроен Puma web server для production.

---

## 🌐 CUSTOM DOMAIN (Опционально)

Если хотите использовать свой домен:

1. В Railway Dashboard откройте ваш проект
2. Выберите web service
3. Перейдите на вкладку **"Settings"**
4. Найдите секцию **"Domains"**
5. Нажмите **"Custom Domain"**
6. Введите ваш домен (например: `myapp.com`)
7. Railway покажет CNAME запись
8. Добавьте эту CNAME запись в настройки вашего домена
9. Готово! SSL сертификат установится автоматически

---

## 📊 МОНИТОРИНГ И ЛОГИ

### Просмотр логов:
1. Откройте ваш проект в Railway
2. Выберите web service
3. Вкладка **"Deployments"** → выберите активный деплой
4. Увидите логи в реальном времени

### Метрики:
1. Вкладка **"Metrics"**
2. Показывает: CPU, Memory, Network usage

---

## 🆘 РЕШЕНИЕ ПРОБЛЕМ

### Проблема: Деплой падает с ошибкой миграции

**Решение:**
1. Откройте Railway Shell
2. Запустите вручную:
```bash
bundle exec rails db:migrate
```

### Проблема: Приложение не запускается

**Решение:**
1. Проверьте логи (Deployments → активный деплой)
2. Убедитесь что все environment variables установлены
3. Проверьте что `DATABASE_URL` установлена автоматически

### Проблема: 502 Bad Gateway

**Решение:**
1. Проверьте что Puma слушает на правильном порту
2. Railway автоматически устанавливает `PORT` переменную
3. Наш `config/puma.rb` уже настроен правильно

### Проблема: Assets не загружаются

**Решение:**
Убедитесь что установлены переменные:
```
RAILS_LOG_TO_STDOUT=enabled
RAILS_SERVE_STATIC_FILES=enabled
```

---

## 💰 СТОИМОСТЬ

Railway дает **$5 кредитов каждый месяц БЕСПЛАТНО**.

Примерная стоимость небольшого Rails приложения:
- Web service (512MB RAM): ~$2-3/месяц
- PostgreSQL база (256MB): ~$1-2/месяц
- **ИТОГО: ~$3-5/месяц** (покрывается бесплатными кредитами!)

Если приложение не активно (мало трафика), стоимость будет еще меньше.

---

## 🔄 АВТОМАТИЧЕСКИЙ ДЕПЛОЙ

Railway автоматически деплоит при каждом push в GitHub:

1. Вы делаете `git push origin main`
2. Railway получает вебхук от GitHub
3. Автоматически запускается новый деплой
4. Через 3-5 минут новая версия live!

Чтобы отключить автодеплой:
1. Settings → GitHub Repo
2. Отключите "Auto Deploy"

---

## 📚 ПОЛЕЗНЫЕ ССЫЛКИ

- **Railway Dashboard:** https://railway.app/dashboard
- **Railway Docs:** https://docs.railway.app/
- **Ваш проект:** https://railway.app/project/YOUR_PROJECT_ID
- **GitHub репозиторий:** https://github.com/mraiko23/aichatYMLER

---

## ✅ ЧЕКЛИСТ ПЕРЕД ДЕПЛОЕМ

- [ ] Зарегистрирован на Railway.app
- [ ] Создан новый проект из GitHub репозитория
- [ ] Добавлена PostgreSQL база данных
- [ ] Добавлены все Environment Variables (14 штук)
- [ ] Дождался завершения первого деплоя
- [ ] Создал администратора через Shell
- [ ] Проверил что сайт открывается

---

## 🎉 ГОТОВО!

Ваше приложение работает на Railway! 🚂

URL вашего приложения:
```
https://your-app-name.up.railway.app
```

Войдите как администратор и наслаждайтесь!

---

## 🔒 БЕЗОПАСНОСТЬ

⚠️ **НЕ КОММИТЬТЕ СЕКРЕТНЫЕ КЛЮЧИ В GIT!**

Все секретные ключи хранятся в:
- `RENDER_SECRETS.txt` (уже в .gitignore)
- Railway Environment Variables (зашифровано)

Храните резервную копию ключей в менеджере паролей:
- 1Password
- Bitwarden  
- LastPass

---

## 💡 СОВЕТЫ

1. **Включите автодеплой** для удобства разработки
2. **Настройте custom domain** для профессионального вида
3. **Мониторьте метрики** чтобы оптимизировать стоимость
4. **Используйте Railway CLI** для управления из терминала
5. **Настройте health checks** для автоматического перезапуска

---

🎯 **Railway.app - самый простой способ задеплоить Rails приложение!**

Удачи! 🚀
