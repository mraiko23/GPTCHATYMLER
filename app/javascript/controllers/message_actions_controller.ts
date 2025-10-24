import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  static targets = ["content", "editForm", "editTextarea"]
  static values = {
    messageId: String,
    chatId: String
  }

  declare readonly contentTarget: HTMLElement
  declare readonly editFormTarget: HTMLElement
  declare readonly editTextareaTarget: HTMLTextAreaElement
  declare readonly hasEditFormTarget: boolean
  declare readonly hasEditTextareaTarget: boolean
  declare readonly messageIdValue: string
  declare readonly chatIdValue: string

  private buttonsAdded = false

  connect(): void {
    this.addActionButtons()
  }

  // Add action buttons to the message
  private addActionButtons(): void {
    // Check if buttons already added using flag (avoid querySelector)
    if (this.buttonsAdded) return
    this.buttonsAdded = true

    const actionsDiv = document.createElement('div')
    actionsDiv.className = 'message-actions'
    
    // Copy button (always available)
    const copyBtn = this.createActionButton('copy', 'Копировать', 'copy')
    actionsDiv.appendChild(copyBtn)
    
    // Edit button (only for user messages)
    if (this.element.closest('.message-bubble-user')) {
      const editBtn = this.createActionButton('edit', 'Изменить', 'edit')
      actionsDiv.appendChild(editBtn)
    }
    
    // Regenerate button (only for assistant messages)
    if (this.element.closest('.message-bubble-assistant')) {
      const regenerateBtn = this.createActionButton('regenerate', 'Перегенерировать', 'refresh')
      actionsDiv.appendChild(regenerateBtn)
    }
    
    this.element.appendChild(actionsDiv)
  }

  // Create action button with icon and text
  private createActionButton(action: string, text: string, iconType: string): HTMLButtonElement {
    const button = document.createElement('button')
    button.className = `message-action-btn btn-${action}`
    button.type = 'button'
    button.dataset.action = `message-actions#${action}`
    
    const icon = this.getIcon(iconType)
    button.innerHTML = `${icon}<span>${text}</span>`
    
    return button
  }

  // Get SVG icon for button
  private getIcon(type: string): string {
    const icons: Record<string, string> = {
      copy: `<svg fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" 
              d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z"/>
      </svg>`,
      edit: `<svg fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" 
              d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"/>
      </svg>`,
      refresh: `<svg fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" 
              d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"/>
      </svg>`
    }
    return icons[type] || ''
  }

  // Copy message content to clipboard
  async copy(event: Event): Promise<void> {
    event.preventDefault()
    const button = event.currentTarget as HTMLButtonElement
    const content = this.contentTarget.textContent?.trim() || ''
    
    try {
      await navigator.clipboard.writeText(content)
      this.showCopySuccess(button)
    } catch (err) {
      this.fallbackCopyText(content)
      this.showCopySuccess(button)
    }
  }

  // Edit message content
  edit(event: Event): void {
    event.preventDefault()
    
    if (this.hasEditFormTarget) {
      // Cancel edit mode
      this.cancelEdit()
      return
    }
    
    this.enterEditMode()
  }

  // Regenerate assistant response
  regenerate(event: Event): void {
    
    // Use Turbo to make the request without page reload
    const url = `/chats/${this.chatIdValue}/messages/${this.messageIdValue}/regenerate`
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content') || ''
    
    // Create form element for Turbo submission
    const form = document.createElement('form')
    form.method = 'POST'
    form.action = url
    form.style.display = 'none'
    
    // Add CSRF token
    const csrfInput = document.createElement('input')
    csrfInput.type = 'hidden'
    csrfInput.name = 'authenticity_token'
    csrfInput.value = csrfToken
    form.appendChild(csrfInput)
    
    // Append to body and let Turbo handle submission
    document.body.appendChild(form)
    // @ts-ignore - Turbo is available globally
    if (window.Turbo) {
      // @ts-ignore
      window.Turbo.navigator.submitForm(form)
    } else {
      form.requestSubmit()
    }
    
    // Clean up after a delay
    setTimeout(() => {
      if (form.parentNode) {
        document.body.removeChild(form)
      }
    }, 100)
  }

  // Enter edit mode
  private enterEditMode(): void {
    const currentContent = this.contentTarget.textContent?.trim() || ''
    
    // Create edit form
    const editForm = document.createElement('div')
    editForm.className = 'message-edit-form'
    editForm.dataset.messageActionsTarget = 'editForm'
    
    editForm.innerHTML = `
      <form action="/chats/${this.chatIdValue}/messages/${this.messageIdValue}" method="POST">
        <input type="hidden" name="_method" value="PATCH">
        <input type="hidden" name="authenticity_token" value="${this.getCSRFToken()}">
        <textarea 
          name="message[content]" 
          class="message-edit-textarea" 
          data-message-actions-target="editTextarea"
          placeholder="Измените сообщение...">${currentContent}</textarea>
        <div class="message-edit-actions">
          <button type="button" class="btn-outline btn-sm" data-action="message-actions#cancelEdit">Отменить</button>
          <button type="submit" class="btn-primary btn-sm">Сохранить</button>
        </div>
      </form>
    `
    
    // Hide original content and show edit form
    this.contentTarget.style.display = 'none'
    this.element.appendChild(editForm)
    
    // Focus textarea
    const textarea = editForm.querySelector('textarea') as HTMLTextAreaElement
    textarea?.focus()
    textarea?.select()
  }

  // Cancel edit mode
  cancelEdit(): void {
    if (this.hasEditFormTarget) {
      this.editFormTarget.remove()
      this.contentTarget.style.display = 'block'
    }
  }

  // Get CSRF token
  private getCSRFToken(): string {
    return document.querySelector('meta[name="csrf-token"]')?.getAttribute('content') || ''
  }

  // Show copy success feedback
  private showCopySuccess(button: HTMLElement): void {
    const originalHTML = button.innerHTML
    
    button.classList.add('copied')
    button.innerHTML = `
      <svg fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/>
      </svg>
      <span>Скопировано</span>
    `
    
    setTimeout(() => {
      button.classList.remove('copied')
      button.innerHTML = originalHTML
    }, 2000)
  }

  // Fallback copy method
  private fallbackCopyText(text: string): void {
    const textArea = document.createElement('textarea')
    textArea.value = text
    textArea.style.position = 'fixed'
    textArea.style.left = '-999999px'
    textArea.style.top = '-999999px'
    document.body.appendChild(textArea)
    textArea.focus()
    textArea.select()
    
    try {
      document.execCommand('copy')
    } catch (err) {
      console.error('Fallback copy failed:', err)
    }
    
    document.body.removeChild(textArea)
  }
}
