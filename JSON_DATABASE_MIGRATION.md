# Миграция на JSON Database

## Описание изменений

Приложение было полностью переведено с PostgreSQL на JSON-файловое хранилище данных.
Теперь **все данные хранятся в одном файле `db/db.json`** вместо SQL базы данных.

## Что изменилось

### 1. **Система хранения данных**
- ✅ Удалена зависимость от PostgreSQL
- ✅ Все данные хранятся в `db/db.json`
- ✅ Файлы (картинки, документы) хранятся в `storage/`

### 2. **Новые файлы**

#### `lib/json_database.rb`
Основной класс для работы с JSON базой данных:
- Чтение/запись данных в JSON файл
- Thread-safe операции с блокировкой файла
- CRUD операции (create, read, update, delete)
- Автоинкремент ID
- Автоматические timestamps (created_at, updated_at)

#### `lib/json_model.rb`
Базовый класс модели, заменяющий ActiveRecord:
- Поддержка ActiveModel валидаций
- Поддержка has_many, belongs_to ассоциаций
- Поддержка has_many_attached для файлов
- Callbacks (before_save, after_save, etc.)
- Поддержка scopes
- API совместимый с ActiveRecord

#### `lib/json_active_storage.rb`
Реализация хранения файлов для JSON:
- Загрузка и хранение файлов в `storage/`
- Metadata файлов в JSON
- Serving файлов через HTTP

### 3. **Обновленные модели**
Все модели переписаны для работы с JsonModel:
- ✅ User
- ✅ Session
- ✅ Chat
- ✅ Message
- ✅ Administrator
- ✅ AdminOplog

### 4. **Обновленные контроллеры**
Адаптированы для работы с JsonModel:
- ✅ ApplicationController
- ✅ ChatsController
- ✅ MessagesController
- ✅ Admin::SessionsController
- ✅ Новый BlobsController для файлов

### 5. **Обновленные Jobs**
- ✅ ChatResponseJob адаптирован для JSON storage

### 6. **Конфигурация**
Обновлены файлы конфигурации:
- `config/application.rb` - отключен ActiveRecord, загружается JsonDatabase
- `config/environments/development.rb` - убраны ссылки на ActiveRecord
- `config/environments/production.rb` - убраны ссылки на ActiveRecord  
- `config/environments/test.rb` - убраны ссылки на ActiveRecord
- `config/routes.rb` - добавлен роут для файлов

### 7. **Seeds**
- `db/seeds.rb` - обновлен для инициализации JSON базы данных
- Создает администратора по умолчанию (admin/admin123)

## Структура db.json

```json
{
  "users": [],
  "sessions": [],
  "chats": [],
  "messages": [],
  "administrators": [
    {
      "id": 1,
      "name": "admin",
      "password_digest": "...",
      "role": "super_admin",
      "first_login": true,
      "created_at": "2025-10-25T07:26:02Z",
      "updated_at": "2025-10-25T07:26:02Z"
    }
  ],
  "admin_oplogs": [],
  "active_storage_blobs": [],
  "active_storage_attachments": [],
  "counters": {
    "users": 0,
    "sessions": 0,
    "chats": 0,
    "messages": 0,
    "administrators": 1,
    "admin_oplogs": 0,
    "active_storage_blobs": 0,
    "active_storage_attachments": 0
  }
}
```

## Как использовать

### Инициализация базы данных

```bash
# Создать db.json и добавить администратора по умолчанию
bundle exec rails runner "load 'db/seeds.rb'"
```

### Запуск приложения

```bash
# Скомпилировать JavaScript assets
npm install
npm run build

# Запустить сервер
bundle exec rails s
```

### Доступ к приложению

- **Главная страница**: http://localhost:3000/
- **Админ панель**: http://localhost:3000/admin/login
  - Логин: `admin`
  - Пароль: `admin123`

## API JsonModel

JsonModel поддерживает большинство методов ActiveRecord:

```ruby
# Create
user = User.create(name: 'John', email: 'john@example.com')
user = User.create!(name: 'Jane', email: 'jane@example.com')

# Read
user = User.find(1)
user = User.find_by(email: 'john@example.com')
users = User.where(verified: true)
users = User.all

# Update
user.update(name: 'John Doe')
user.update!(verified: true)

# Delete
user.destroy
User.destroy_all

# Associations
user.chats  # has_many
chat.user   # belongs_to
message.files  # has_many_attached

# Scopes (определяются в модели)
Chat.recent  # возвращает отсортированные чаты

# Validations
user.valid?
user.errors.full_messages
```

## Особенности и ограничения

### ✅ Поддерживается:
- CRUD операции
- Валидации (включая кастомные)
- Ассоциации (has_many, belongs_to)
- Загрузка файлов (has_many_attached)
- Callbacks (before_save, after_create, etc.)
- Scopes
- Timestamps
- Thread-safe операции

### ⚠️ Не поддерживается:
- SQL запросы
- Сложные JOIN'ы
- Транзакции (кроме file-level locking)
- Миграции (схема статична)
- Индексы
- Eager loading (.includes)
- Query building chains (.where.or.where)

### 🔄 Различия с ActiveRecord:
- `uniqueness: true` validation заменен на кастомные методы
- `.first`, `.last` заменены на `.all.first`, `.all.last`
- `.pluck` не поддерживается, используйте `.map(&:attribute)`
- `.order` не поддерживается, используйте `.sort_by`
- `.count` работает без аргументов
- Нет eager loading, каждая ассоциация загружается отдельно

## Преимущества JSON-хранилища

1. **Простота**: Не нужна база данных PostgreSQL
2. **Портативность**: Весь проект в одном файле
3. **Читаемость**: Легко просмотреть данные в текстовом редакторе
4. **Backup**: Просто скопировать db.json файл
5. **Debugging**: Легко понять структуру данных
6. **Деплой**: Не нужно настраивать базу данных на сервере

## Недостатки JSON-хранилища

1. **Производительность**: Медленнее чем SQL при больших объемах
2. **Масштабируемость**: Не подходит для больших данных (>100MB)
3. **Конкурентность**: File-level locking может быть узким местом
4. **Сложные запросы**: Отсутствуют JOIN'ы и SQL функции
5. **Размер**: Весь файл загружается в память при операциях

## Рекомендации

- ✅ Подходит для: прототипов, демо, небольших приложений
- ✅ Хорошо для: локальной разработки, тестирования
- ⚠️ Не рекомендуется для: production с большой нагрузкой
- ⚠️ Ограничение: до 1000-5000 записей на таблицу

## Миграция обратно на PostgreSQL

Если понадобится вернуться на PostgreSQL:

1. Восстановите старые модели из git истории
2. Восстановите `config/application.rb` (require "rails/all")
3. Создайте миграции: `rails g migration ...`
4. Запустите миграции: `rails db:migrate`
5. Импортируйте данные из db.json вручную или через скрипт

## Backup данных

```bash
# Создать backup
cp db/db.json db/db.json.backup

# Восстановить backup
cp db/db.json.backup db/db.json

# Backup с датой
cp db/db.json db/db.json.$(date +%Y%m%d_%H%M%S)
```

## Мониторинг размера базы

```bash
# Проверить размер db.json
du -h db/db.json

# Проверить количество записей
cat db/db.json | jq '.counters'

# Красиво отформатировать
cat db/db.json | jq '.'
```

## Troubleshooting

### Проблема: db.json поврежден
```bash
# Восстановить из backup
cp db/db.json.backup db/db.json

# Или пересоздать
rm db/db.json
bundle exec rails runner "load 'db/seeds.rb'"
```

### Проблема: Файлы не загружаются
```bash
# Проверить папку storage
ls -la storage/

# Создать папку если отсутствует
mkdir -p storage
```

### Проблема: Ошибка при сохранении
```ruby
# В rails console
user = User.new(email: 'test@example.com')
user.valid?  # Проверить валидность
user.errors.full_messages  # Посмотреть ошибки
user.save  # Попробовать сохранить
```

## Заключение

Приложение успешно мигрировано на JSON-based storage.
Все функции работают: авторизация, чаты, сообщения, файлы, админка.

База данных расположена в: **`db/db.json`**
Файлы хранятся в: **`storage/`**

Приятной работы! 🎉
