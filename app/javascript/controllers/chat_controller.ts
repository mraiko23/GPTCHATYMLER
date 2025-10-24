import BaseChannelController from "./base_channel_controller"

export default class extends BaseChannelController {
  declare readonly hasMessagesTarget: boolean
  declare readonly hasFormTarget: boolean
  declare readonly hasInputTarget: boolean
  declare readonly hasSendButtonTarget: boolean
  declare readonly hasFileInputTarget: boolean
  declare readonly hasFilePreviewTarget: boolean
  declare readonly hasScrollButtonTarget: boolean
  
  declare readonly messagesTarget: HTMLElement
  declare readonly formTarget: HTMLFormElement
  declare readonly inputTarget: HTMLInputElement
  declare readonly sendButtonTarget: HTMLButtonElement
  declare readonly fileInputTarget: HTMLInputElement
  declare readonly filePreviewTarget: HTMLElement
  declare readonly scrollButtonTarget: HTMLElement
  
  declare readonly chatIdValue: string
  
  private isUserScrolling = false
  private scrollTimeout: number | null = null
  
  static targets = [
    "messages",
    "form", 
    "input",
    "sendButton",
    "fileInput",
    "filePreview",
    "scrollButton"
  ]

  static values = {
    chatId: String
  }

  connect(): void {
    console.log("Chat controller connected")

    this.createSubscription("ChatChannel", {
      chat_id: this.chatIdValue
    })
    
    if (this.hasFormTarget) {
      this.formTarget.addEventListener('submit', this.handleSubmit.bind(this))
    }
    
    window.addEventListener('scroll', this.handleScroll.bind(this))
    this.scrollToBottom()
  }

  disconnect(): void {
    this.destroySubscription()
    window.removeEventListener('scroll', this.handleScroll.bind(this))
    
    if (this.scrollTimeout) {
      clearTimeout(this.scrollTimeout)
    }
  }

  protected channelConnected(): void {
    console.log("Chat WebSocket connected")
  }

  protected channelDisconnected(): void {
    console.log("Chat WebSocket disconnected")
  }

  private handleSubmit(event: Event): void {
    const formData = new FormData(this.formTarget as HTMLFormElement)
    const content = formData.get('content') as string
    const files = this.hasFileInputTarget ? Array.from(this.fileInputTarget.files || []) : []
    
    const hasContent = content && content.trim()
    const hasFiles = files.length > 0 && files.some(f => f.size > 0)
    
    if (!hasContent && !hasFiles) {
      event.preventDefault()
      return
    }
    
    if (hasContent && !hasFiles) {
      event.preventDefault()
      this.perform('send_message', { content: content.trim() })
      
      if (this.hasInputTarget) {
        (this.inputTarget as HTMLInputElement).value = ''
      }
      return
    }
  }
  
  handleFileChange(event: Event): void {
    const input = event.target as HTMLInputElement
    const files = Array.from(input.files || [])
    
    if (files.length === 0) {
      this.clearFilePreview()
      return
    }
    
    this.displayFilePreview(files)
  }
  
  handleFormSubmitEnd(event: any): void {
    if (event.detail.success) {
      this.clearFileInput()
      this.clearFilePreview()
      
      if (this.hasInputTarget) {
        (this.inputTarget as HTMLInputElement).value = ''
      }
    }
  }
  
  private displayFilePreview(files: File[]): void {
    if (!this.hasFilePreviewTarget) return
    
    this.filePreviewTarget.innerHTML = ''
    this.filePreviewTarget.classList.remove('hidden')
    
    files.forEach((file, index) => {
      const preview = document.createElement('div')
      preview.className = 'flex items-center space-x-2 p-2 bg-background rounded-lg border border-border'
      
      const icon = document.createElement('div')
      icon.className = 'flex-shrink-0'
      
      if (file.type.startsWith('image/')) {
        const img = document.createElement('img')
        img.src = URL.createObjectURL(file)
        img.className = 'w-10 h-10 object-cover rounded'
        img.onload = () => URL.revokeObjectURL(img.src)
        icon.appendChild(img)
      } else {
        icon.innerHTML = `
          <div class="w-10 h-10 rounded bg-primary/10 flex items-center justify-center">
            <svg class="w-5 h-5 text-primary" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/>
            </svg>
          </div>
        `
      }
      
      const info = document.createElement('div')
      info.className = 'flex-1 min-w-0'
      info.innerHTML = `
        <p class="text-sm font-medium text-text-primary truncate">${file.name}</p>
        <p class="text-xs text-text-muted">${this.formatFileSize(file.size)}</p>
      `
      
      const removeBtn = document.createElement('button')
      removeBtn.type = 'button'
      removeBtn.className = 'flex-shrink-0 p-1 text-text-muted hover:text-red-500 transition-colors'
      removeBtn.innerHTML = `
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
        </svg>
      `
      removeBtn.addEventListener('click', () => this.removeFile(index))
      
      preview.appendChild(icon)
      preview.appendChild(info)
      preview.appendChild(removeBtn)
      
      this.filePreviewTarget.appendChild(preview)
    })
  }
  
  private clearFilePreview(): void {
    if (!this.hasFilePreviewTarget) return
    
    this.filePreviewTarget.innerHTML = ''
    this.filePreviewTarget.classList.add('hidden')
  }
  
  private clearFileInput(): void {
    if (!this.hasFileInputTarget) return
    
    this.fileInputTarget.value = ''
  }
  
  private removeFile(index: number): void {
    if (!this.hasFileInputTarget) return
    
    const dt = new DataTransfer()
    const files = Array.from(this.fileInputTarget.files || [])
    
    files.forEach((file, i) => {
      if (i !== index) {
        dt.items.add(file)
      }
    })
    
    this.fileInputTarget.files = dt.files
    
    if (dt.files.length === 0) {
      this.clearFilePreview()
    } else {
      this.displayFilePreview(Array.from(dt.files))
    }
  }
  
  private formatFileSize(bytes: number): string {
    if (bytes === 0) return '0 Bytes'
    
    const k = 1024
    const sizes = ['Bytes', 'KB', 'MB', 'GB']
    const i = Math.floor(Math.log(bytes) / Math.log(k))
    
    return `${parseFloat((bytes / Math.pow(k, i)).toFixed(2))} ${sizes[i]}`
  }
  
  private handleScroll(): void {
    if (this.scrollTimeout) {
      clearTimeout(this.scrollTimeout)
    }
    
    this.scrollTimeout = window.setTimeout(() => {
      this.checkScrollPosition()
    }, 100) as unknown as number
  }
  
  private checkScrollPosition(): void {
    if (!this.hasScrollButtonTarget) return
    
    const scrollPosition = window.scrollY + window.innerHeight
    const documentHeight = document.documentElement.scrollHeight
    const threshold = 500
    
    if (documentHeight - scrollPosition > threshold) {
      this.scrollButtonTarget.classList.remove('hidden')
      this.isUserScrolling = true
    } else {
      this.scrollButtonTarget.classList.add('hidden')
      this.isUserScrolling = false
    }
  }
  
  scrollToBottom(): void {
    window.scrollTo({
      top: document.documentElement.scrollHeight,
      behavior: 'smooth'
    })
    
    if (this.hasScrollButtonTarget) {
      this.scrollButtonTarget.classList.add('hidden')
    }
    this.isUserScrolling = false
  }
  
  protected handleNewMessage(data: any): void {
    console.log('New message:', data)
    
    if (this.hasMessagesTarget) {
      const messageEl = this.createMessageElement(data)
      this.messagesTarget.appendChild(messageEl)
      
      if (!this.isUserScrolling) {
        this.scrollToBottom()
      }
    }
  }
  
  protected handleChunk(data: any): void {
    const existingMessage = document.getElementById(`message-${data.message_id}`)
    
    if (existingMessage) {
      const contentEl = existingMessage.querySelector('.message-content')
      if (contentEl) {
        contentEl.textContent += data.chunk
      }
    }
    
    if (!this.isUserScrolling) {
      this.scrollToBottom()
    }
  }
  
  protected handleResponseStart(data: any): void {
    if (this.hasMessagesTarget) {
      const messageEl = this.createMessageElement({
        id: data.message_id,
        role: 'assistant',
        content: '',
        created_at: new Date().toISOString()
      })
      this.messagesTarget.appendChild(messageEl)
      
      if (!this.isUserScrolling) {
        this.scrollToBottom()
      }
    }
  }
  
  protected handleComplete(data: any): void {
    console.log('AI response completed:', data)
  }
  
  protected handleError(data: any): void {
    console.error('Chat error:', data)
    
    if (this.hasMessagesTarget) {
      const errorEl = document.createElement('div')
      errorEl.className = 'flex justify-center mb-4'
      errorEl.innerHTML = `
        <div class="max-w-[80%] px-4 py-2 bg-red-50 border border-red-200 rounded-2xl">
          <div class="text-red-700 text-sm">${data.message}</div>
        </div>
      `
      this.messagesTarget.appendChild(errorEl)
      this.scrollToBottom()
    }
  }
  
  protected handleTypingIndicator(data: any): void {
    console.log('Typing indicator:', data)
  }
  
  private createMessageElement(data: any): HTMLElement {
    const messageEl = document.createElement('div')
    messageEl.id = `message-${data.id}`
    messageEl.className = `flex ${data.role === 'user' ? 'justify-end' : 'justify-start'}`
    
    const bubbleEl = document.createElement('div')
    bubbleEl.className = `${
      data.role === 'user' 
        ? 'message-bubble-user' 
        : 'message-bubble-assistant'
    } shadow-sm`
    
    bubbleEl.setAttribute('data-controller', 'message-actions')
    bubbleEl.setAttribute('data-message-actions-message-id-value', data.id)
    bubbleEl.setAttribute('data-message-actions-chat-id-value', data.chat_id || this.chatIdValue)
    
    const contentEl = document.createElement('div')
    contentEl.className = 'message-content'
    contentEl.setAttribute('data-message-actions-target', 'content')
    contentEl.textContent = data.content
    
    const timeEl = document.createElement('div')
    timeEl.className = `text-xs mt-2 ${
      data.role === 'user' ? 'text-white/70' : 'text-text-muted'
    }`
    timeEl.textContent = new Date(data.created_at).toLocaleTimeString('ru-RU', { hour: '2-digit', minute: '2-digit' })
    
    bubbleEl.appendChild(contentEl)
    bubbleEl.appendChild(timeEl)
    messageEl.appendChild(bubbleEl)
    
    return messageEl
  }
}
