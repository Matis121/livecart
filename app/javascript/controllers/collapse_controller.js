import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "icon"]
  static values = {
    storageKey: String,
    defaultOpen: { type: Boolean, default: true }
  }

  connect() {
    // Odczytaj stan z localStorage lub użyj wartości domyślnej
    const savedState = localStorage.getItem(this.storageKeyValue)
    const isOpen = savedState !== null ? savedState === "true" : this.defaultOpenValue
    
    if (!isOpen) {
      this.close(false)
    } else {
      this.open(false)
    }
  }

  toggle() {
    if (this.contentTarget.classList.contains("hidden")) {
      this.open(true)
    } else {
      this.close(true)
    }
  }

  open(animate = true) {
    this.contentTarget.classList.remove("hidden")
    
    if (this.hasIconTarget) {
      this.iconTarget.style.transform = "rotate(0deg)"
    }
    
    if (this.storageKeyValue) {
      localStorage.setItem(this.storageKeyValue, "true")
    }
  }

  close(animate = true) {
    this.contentTarget.classList.add("hidden")
    
    if (this.hasIconTarget) {
      this.iconTarget.style.transform = "rotate(180deg)"
    }
    
    if (this.storageKeyValue) {
      localStorage.setItem(this.storageKeyValue, "false")
    }
  }
}
