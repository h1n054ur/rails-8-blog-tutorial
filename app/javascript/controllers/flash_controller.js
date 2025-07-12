// FLASH MESSAGE CONTROLLER - Handles flash message interactions using Stimulus
//
// STIMULUS CONCEPT: This controller manages flash message behavior including:
// - Close button functionality
// - Auto-hide after timeout
// - Smooth fade-out animations
// - Turbo-compatible event handling
//
// RAILS 8 INTEGRATION: Works seamlessly with Turbo Drive navigation
// ensuring flash messages work correctly across page transitions
//
// WHY STIMULUS: 
// - Turbo-compatible (works with dynamic content)
// - Declarative HTML data attributes
// - Automatic cleanup when elements are removed
// - No jQuery dependency needed

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  // STIMULUS TARGETS: Define DOM elements this controller can reference
  static targets = ["message", "closeButton"]
  
  // STIMULUS VALUES: Configuration options passed from HTML
  static values = { 
    autoDismiss: { type: Boolean, default: true },
    dismissAfter: { type: Number, default: 5000 }
  }
  
  // CONTROLLER INITIALIZATION: Called when controller is added to DOM
  //
  // STIMULUS LIFECYCLE: This runs when:
  // - Page loads with flash messages
  // - New flash messages are added via Turbo
  // - Controller is re-connected after navigation
  connect() {
    console.log("Flash controller connected")
    
    // Set up auto-dismiss if enabled
    if (this.autoDismissValue) {
      this.setupAutoDismiss()
    }
    
    // Ensure the flash message is visible initially
    this.element.style.opacity = '1'
    this.element.style.display = 'flex'
  }
  
  // CLOSE BUTTON ACTION: Manually close flash message
  //
  // STIMULUS ACTION: Called when user clicks close button
  // HTML usage: data-action="click->flash#close"
  close(event) {
    console.log("Flash close button clicked")
    event.preventDefault()
    this.hideMessage()
  }
  
  // AUTO-DISMISS SETUP: Configure automatic message hiding
  //
  // TIMEOUT BEHAVIOR: Starts fade after specified delay
  // ACCESSIBILITY: Provides enough time for users to read message
  setupAutoDismiss() {
    console.log(`Setting up auto-dismiss after ${this.dismissAfterValue}ms`)
    
    this.dismissTimeout = setTimeout(() => {
      this.hideMessage()
    }, this.dismissAfterValue)
  }
  
  // HIDE MESSAGE: Smooth fade-out animation and removal
  //
  // ANIMATION APPROACH: Two-stage process for smooth UX
  // 1. Fade out opacity over 300ms
  // 2. Set display:none after animation completes
  hideMessage() {
    console.log("Hiding flash message")
    
    // Clear any pending auto-dismiss
    if (this.dismissTimeout) {
      clearTimeout(this.dismissTimeout)
      this.dismissTimeout = null
    }
    
    // Start fade-out animation
    this.element.style.transition = 'opacity 0.3s ease-out'
    this.element.style.opacity = '0'
    
    // Hide completely after animation
    setTimeout(() => {
      this.element.style.display = 'none'
      
      // Optional: Remove from DOM entirely
      // this.element.remove()
    }, 300)
  }
  
  // STIMULUS DISCONNECT: Cleanup when controller is removed
  //
  // MEMORY MANAGEMENT: Clear timeouts to prevent memory leaks
  // LIFECYCLE: Called when:
  // - User navigates away
  // - Flash message is removed from DOM
  // - Page is unloaded
  disconnect() {
    console.log("Flash controller disconnected")
    
    if (this.dismissTimeout) {
      clearTimeout(this.dismissTimeout)
      this.dismissTimeout = null
    }
  }
}

// STIMULUS CONTROLLER FEATURES DEMONSTRATED:
//
// 1. TARGETS: Define reusable DOM element references
// 2. VALUES: Accept configuration from HTML data attributes  
// 3. ACTIONS: Handle user interactions declaratively
// 4. LIFECYCLE: Connect/disconnect for setup and cleanup
// 5. TURBO COMPATIBILITY: Works across page transitions
//
// HTML INTEGRATION EXAMPLE:
//
// <div data-controller="flash" 
//      data-flash-auto-dismiss-value="true"
//      data-flash-dismiss-after-value="5000">
//   <div data-flash-target="message">Your message here</div>
//   <button data-action="click->flash#close" 
//           data-flash-target="closeButton">×</button>
// </div>
//
// RAILS INTEGRATION BENEFITS:
//
// - No manual event listener setup required
// - Automatic cleanup prevents memory leaks
// - Works with dynamically added content
// - Plays nicely with Turbo Drive caching
// - Declarative HTML configuration
// - Reusable across different flash message types
//
// FUTURE ENHANCEMENTS:
//
// - Different animations for different message types
// - Configurable animation duration
// - Sound effects for important alerts
// - Integration with notification APIs
// - Undo functionality for destructive actions