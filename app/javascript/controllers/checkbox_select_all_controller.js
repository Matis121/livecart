import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="checkbox-select-all"
export default class extends Controller {
  static targets = ["parent", "child", "counter"]
  
  connect() {
    console.log("checkbox-select-all connected")
    this.updateCounter()
  }

  toggleChildren(event) {
    const shouldCheck = event.currentTarget.dataset.value === "true"
    
    this.childTargets.forEach(checkbox => {
      checkbox.checked = shouldCheck
    })
    
    // Zaktualizuj też parent checkbox
    this.parentTarget.checked = shouldCheck
    
    this.updateCounter()
  }

  toggleParent() {
    if(this.childTargets.every(x => x.checked)) {
      this.parentTarget.checked = true
    } else {
      this.parentTarget.checked = false
    }
    this.updateCounter()
  }

  updateCounter() {
    console.log("updateCounter")
    console.log(this.counterTarget)
    if (this.hasCounterTarget) {
      const selected = this.childTargets.filter(x => x.checked).length
      const total = this.childTargets.length
      
      // Ukryj/pokaż w zależności od liczby zaznaczonych
      if (selected > 0) {
        this.counterTarget.classList.remove('hidden')
        this.counterTarget.textContent = `${selected} / ${total}`
      } else {
        this.counterTarget.classList.add('hidden')
      }
    }
  }
}