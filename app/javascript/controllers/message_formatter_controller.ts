import { Controller } from "@hotwired/stimulus"

export default class extends Controller<HTMLElement> {
  private observer: MutationObserver | null = null
  
  connect(): void {
    this.formatMessages()
    // Add copy buttons after formatting is complete
    setTimeout(() => this.addCopyButtons(), 0)
    
    // Set up observer for dynamically added messages
    this.setupObserver()
  }
  
  disconnect(): void {
    if (this.observer) {
      this.observer.disconnect()
    }
  }
  
  // Set up MutationObserver to handle dynamically added messages
  private setupObserver(): void {
    this.observer = new MutationObserver((mutations) => {
      mutations.forEach((mutation) => {
        mutation.addedNodes.forEach((node) => {
          if (node instanceof HTMLElement) {
            // Check if this is a message or contains messages
            if (node.classList.contains('message-bubble-assistant') || 
                node.classList.contains('message-bubble-user') ||
                node.querySelector('.message-content')) {
              // Format and add buttons to new content
              setTimeout(() => {
                this.formatMessages()
                this.addCopyButtons()
              }, 0)
            }
          }
        })
      })
    })
    
    // Start observing
    this.observer.observe(this.element, {
      childList: true,
      subtree: true
    })
  }

  // Format message content with proper markup
  private formatMessages(): void {
    const messageContents = this.element.querySelectorAll('.message-content')
    
    messageContents.forEach((content: Element) => {
      if (content instanceof HTMLElement) {
        this.formatMessageContent(content)
      }
    })
  }

  // Add copy buttons to code blocks (called after formatting)
  private addCopyButtons(): void {
    // Process each message content area for code blocks
    const messageContents = this.element.querySelectorAll('.message-content')
    
    messageContents.forEach((content: Element) => {
      if (content instanceof HTMLElement) {
        // Find pre elements within this specific message content
        const codeBlocks = content.querySelectorAll('pre')
        
        codeBlocks.forEach((block: Element) => {
          if (block instanceof HTMLElement && !block.parentElement?.classList.contains('code-block-wrapper')) {
            this.wrapCodeBlock(block)
          }
        })
      }
    })
  }

  // Wrap code block and add copy button
  private wrapCodeBlock(codeBlock: HTMLElement): void {
    const wrapper = document.createElement('div')
    wrapper.className = 'code-block-wrapper'
    
    // Create copy button
    const copyBtn = document.createElement('button')
    copyBtn.className = 'copy-code-btn'
    copyBtn.title = 'Копировать код'
    copyBtn.innerHTML = `
      <svg fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" 
              d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z"/>
      </svg>
    `
    
    // Add click handler for copy functionality
    copyBtn.addEventListener('click', () => this.copyCode(copyBtn, codeBlock))
    
    // Wrap the code block
    codeBlock.parentNode?.insertBefore(wrapper, codeBlock)
    wrapper.appendChild(codeBlock)
    wrapper.appendChild(copyBtn)
  }

  // Copy code to clipboard
  private async copyCode(button: HTMLElement, codeBlock: HTMLElement): Promise<void> {
    const code = codeBlock.querySelector('code')?.textContent || codeBlock.textContent || ''
    
    try {
      await navigator.clipboard.writeText(code)
      this.showCopySuccess(button)
    } catch (err) {
      // Fallback for older browsers
      this.fallbackCopyText(code)
      this.showCopySuccess(button)
    }
  }

  // Show copy success feedback
  private showCopySuccess(button: HTMLElement): void {
    const originalHTML = button.innerHTML
    
    // Update button to show success
    button.classList.add('copied')
    button.innerHTML = `
      <svg fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" 
              d="M5 13l4 4L19 7"/>
      </svg>
    `
    
    // Reset after 2 seconds
    setTimeout(() => {
      button.classList.remove('copied')
      button.innerHTML = originalHTML
    }, 2000)
  }

  // Fallback copy method for older browsers
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

  // Enhanced message content formatting
  private formatMessageContent(content: HTMLElement): void {
    let html = content.innerHTML
    
    // Format code blocks (triple backticks)
    html = html.replace(/```([\s\S]*?)```/g, '<pre><code>$1</code></pre>')
    
    // Format inline code (single backticks)
    html = html.replace(/`([^`]+)`/g, '<code>$1</code>')
    
    // Format bold text
    html = html.replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>')
    
    // Format italic text
    html = html.replace(/\*(.*?)\*/g, '<em>$1</em>')
    
    // Format headers
    html = html.replace(/^### (.*$)/gm, '<h3>$1</h3>')
    html = html.replace(/^## (.*$)/gm, '<h2>$1</h2>')
    html = html.replace(/^# (.*$)/gm, '<h1>$1</h1>')
    
    // Format links
    html = html.replace(/\[([^\]]+)\]\(([^)]+)\)/g, '<a href="$2" target="_blank">$1</a>')
    
    // Only update if content changed
    if (html !== content.innerHTML) {
      content.innerHTML = html
    }
  }
}
