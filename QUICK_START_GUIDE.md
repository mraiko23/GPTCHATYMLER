# 🚀 Quick Start Guide

## Immediate Access

**Your application is running at:**
```
https://3000-322582f0a0ce-web.clackypaas.com
```

---

## 🎯 Quick Actions

### Access Admin Panel
1. Go to: https://3000-322582f0a0ce-web.clackypaas.com/admin/login
2. Username: `admin`
3. Password: `admin`
4. Click "Login"

### Test File Upload
1. Open the app URL
2. Create a new chat (or use existing)
3. Click the paperclip icon (📎)
4. Select a file (image or text)
5. Type a message
6. Click send

### View Logs
```bash
# In Clacky terminal
get_run_project_output
```

---

## 💻 Common Commands

### Database
```bash
# Create migration
bin/rails generate migration AddFieldToModel field:type

# Run migrations
bin/rails db:migrate

# Reset database (CAUTION)
bin/rails db:reset

# Open console
bin/rails console
```

### Testing
```bash
# Run all tests
bundle exec rspec

# Run specific test
bundle exec rspec spec/models/message_spec.rb

# Run with coverage
COVERAGE=true bundle exec rspec
```

### Linting
```bash
# Run all linters
npm run lint

# Fix JavaScript issues
npm run lint:fix

# Check TypeScript types
npm run type-check

# Run Rubocop
bundle exec rubocop
```

### Assets
```bash
# Build assets
npm run build

# Build CSS only
npm run build:css

# Build JavaScript only
npm run build:js
```

---

## 🔧 Development Tips

### File Upload Testing
**Test with these file types:**
- 📷 Image: `.jpg`, `.png`, `.gif` (AI will describe it)
- 📄 Text: `.txt`, `.json` (AI will read content)
- 📁 Document: `.pdf`, `.doc`, `.csv` (download only)

### Database Console
```bash
bin/rails console

# Try these commands:
User.count
Chat.last
Message.where(role: 'user').count
Administrator.first
```

### Check Background Jobs
1. Login to admin panel
2. Go to: `/admin/good_job`
3. View job status and failures

---

## 📝 File Locations

### Key Files
```
app/controllers/messages_controller.rb  ← File upload logic
app/models/message.rb                   ← has_many_attached :files
app/jobs/chat_response_job.rb          ← AI processing
app/views/chats/show.html.erb          ← Upload form
app/views/messages/_message.html.erb   ← File display
config/application.yml                  ← Environment vars
config/database.yml                     ← Database config
```

### Configuration
```
config/application.yml        ← App settings
config/routes.rb              ← URL routes
config/database.yml           ← Database
Procfile.dev                  ← Development servers
package.json                  ← NPM scripts
Gemfile                       ← Ruby gems
```

---

## 🎨 Customization

### Change AI Model
Edit `config/application.yml`:
```yaml
LLM_MODEL: 'gemini-2.0-flash-exp'  # or 'gpt-4', etc.
```

### Update Styles
Edit `app/assets/stylesheets/application.css`:
```css
/* Your custom CSS here */
```

### Modify AI Prompts
Edit `app/jobs/chat_response_job.rb`:
```ruby
system_prompt = <<~PROMPT
  Your custom prompt here...
PROMPT
```

---

## 🐛 Troubleshooting

### Server Not Responding
```bash
# Check if running
ps aux | grep rails

# Restart
stop_project
run_project
```

### Database Connection Error
```bash
# Check PostgreSQL
psql -U postgres -h 127.0.0.1 -c "SELECT 1;"

# Verify config
cat config/database.yml
```

### Assets Not Loading
```bash
# Rebuild
npm run build

# Check for errors
npm run lint
```

### File Upload Fails
Check:
1. Form has `multipart: true`
2. Controller params include `files: []`
3. Model has `has_many_attached :files`
4. ActiveStorage tables exist: `bin/rails db:migrate`

---

## 📦 Tech Stack Quick Reference

| Component | Technology | Version |
|-----------|-----------|---------|
| Backend | Ruby on Rails | 7.2.2 |
| Frontend | Stimulus + Turbo | Latest |
| Styling | Tailwind CSS | 3.x |
| Database | PostgreSQL | 15.0 |
| JS/TS | TypeScript | 5.x |
| Build | esbuild | Latest |
| Jobs | GoodJob | 4.x |
| WebSocket | ActionCable | Built-in |

---

## 🔐 Security Notes

### Development Mode
- Admin password is `admin` (change in production!)
- SECRET_KEY_BASE is for development only
- CORS is disabled (enable for APIs)

### Production Checklist
- [ ] Change admin password
- [ ] Generate new SECRET_KEY_BASE
- [ ] Set up SSL/TLS
- [ ] Configure S3 for file storage
- [ ] Enable database backups
- [ ] Set up monitoring
- [ ] Configure environment variables
- [ ] Enable rate limiting

---

## 📚 Learn More

### Documentation
- `START_HERE.md` - Project overview
- `CHANGES_SUMMARY.md` - Recent changes
- `FILE_UPLOAD_INSTRUCTIONS.md` - Upload details
- `DEPLOY_GUIDE.md` - Production deployment
- `CLACKY_SETUP_COMPLETE.md` - Full setup info

### External Resources
- [Rails Guides](https://guides.rubyonrails.org)
- [Tailwind CSS](https://tailwindcss.com)
- [Stimulus](https://stimulus.hotwired.dev)
- [Turbo](https://turbo.hotwired.dev)

---

## ✅ Quick Health Check

Run this to verify everything works:
```bash
# Test server
curl http://localhost:3000/ -I

# Test database
bin/rails runner "puts User.count"

# Test assets
ls -la app/assets/builds/

# Check background jobs
bin/rails runner "puts GoodJob::Job.count"
```

---

## 💡 Pro Tips

1. **Use the Rails console** for quick debugging
   ```bash
   bin/rails console
   ```

2. **Watch logs in real-time**
   ```bash
   tail -f log/development.log
   ```

3. **Generate code quickly**
   ```bash
   bin/rails generate model Post title:string
   bin/rails generate controller Posts index show
   ```

4. **Database seeds for testing**
   ```bash
   # Edit db/seeds.rb
   bin/rails db:seed
   ```

5. **Interactive debugging**
   Add `debugger` in your code and interact in console

---

## 🎉 You're Ready!

Everything is set up and working. Start building your features!

**Happy Coding! 🚀**

---

*For detailed information, see: CLACKY_SETUP_COMPLETE.md*
