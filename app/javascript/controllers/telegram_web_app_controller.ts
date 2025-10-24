import { Controller } from "@hotwired/stimulus"

// Extend Window interface to include Telegram WebApp
declare global {
  interface Window {
    Telegram?: {
      WebApp?: {
        initData: string
        initDataUnsafe: any
        MainButton: any
        BackButton: any
        ready(): void
        expand(): void
        close(): void
        showAlert(message: string): void
        showConfirm(message: string, callback: (confirmed: boolean) => void): void
        requestWriteAccess(callback: (granted: boolean) => void): void
        themeParams: {
          bg_color?: string
          text_color?: string
          hint_color?: string
          link_color?: string
          button_color?: string
          button_text_color?: string
        }
      }
    }
  }
}

export default class extends Controller<HTMLElement> {
  static targets = ["authError"]
  static values = { autoAuth: Boolean }

  declare readonly authErrorTarget?: HTMLElement
  declare readonly hasAuthErrorTarget: boolean
  declare readonly autoAuthValue: boolean

  connect(): void {
    console.log("TelegramWebApp controller connected")
    
    if (typeof window.Telegram?.WebApp !== 'undefined') {
      this.initializeTelegramWebApp()
    } else {
      console.warn("Telegram WebApp SDK not loaded")
      this.showError("Это приложение работает только в Telegram")
    }
  }

  private initializeTelegramWebApp(): void {
    const tg = window.Telegram!.WebApp!
    
    // Initialize Telegram WebApp
    tg.ready()
    tg.expand()

    console.log("Telegram WebApp initialized:", tg.initDataUnsafe)

    // Apply Telegram theme
    this.applyTelegramTheme(tg.themeParams)

    // Auto-authenticate if init data is available and auto auth is enabled
    if (this.autoAuthValue && tg.initData) {
      this.authenticateWithTelegram(tg.initData)
    }
  }

  private applyTelegramTheme(themeParams: any): void {
    const root = document.documentElement

    if (themeParams.bg_color) {
      root.style.setProperty('--telegram-bg-color', themeParams.bg_color)
    }
    
    if (themeParams.text_color) {
      root.style.setProperty('--telegram-text-color', themeParams.text_color)
    }
    
    if (themeParams.button_color) {
      root.style.setProperty('--telegram-button-color', themeParams.button_color)
    }

    // Apply dark theme if background is dark
    if (themeParams.bg_color && this.isDarkColor(themeParams.bg_color)) {
      document.body.classList.add('dark')
    }
  }

  private isDarkColor(color: string): boolean {
    // Remove # if present
    const hex = color.replace('#', '')
    
    // Convert to RGB
    const r = parseInt(hex.substr(0, 2), 16)
    const g = parseInt(hex.substr(2, 2), 16)
    const b = parseInt(hex.substr(4, 2), 16)
    
    // Calculate luminance
    const luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255
    
    return luminance < 0.5
  }

  authenticate(): void {
    if (typeof window.Telegram?.WebApp !== 'undefined') {
      const tg = window.Telegram!.WebApp!
      
      if (tg.initData) {
        this.authenticateWithTelegram(tg.initData)
      } else {
        this.showError("Нет данных для аутентификации Telegram")
      }
    } else {
      this.showError("Telegram WebApp не инициализирован")
    }
  }

  private async authenticateWithTelegram(initData: string): Promise<void> {
    try {
      const response = await fetch('/api/telegram_auths', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': this.getCSRFToken()
        },
        body: JSON.stringify({ init_data: initData })
      })

      const data = await response.json()

      if (data.success) {
        console.log("Telegram authentication successful:", data.user)
        
        // Redirect to the specified URL or reload the page
        if (data.redirect_url) {
          window.location.href = data.redirect_url
        } else {
          window.location.reload()
        }
      } else {
        this.showError(data.error || "Ошибка аутентификации")
      }
    } catch (error) {
      console.error("Authentication error:", error)
      this.showError("Ошибка соединения с сервером")
    }
  }

  private getCSRFToken(): string {
    const token = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content')
    return token || ''
  }

  private showError(message: string): void {
    console.error("Telegram WebApp Error:", message)
    
    if (this.hasAuthErrorTarget && this.authErrorTarget) {
      this.authErrorTarget.textContent = message
      this.authErrorTarget.classList.remove('hidden')
    }

    // Also show in Telegram if available
    if (typeof window.Telegram?.WebApp !== 'undefined') {
      window.Telegram!.WebApp!.showAlert(message)
    } else {
      alert(message)
    }
  }

  disconnect(): void {
    console.log("TelegramWebApp controller disconnected")
  }
}