import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="checkbox-select-all"
export default class extends Controller {
  static targets = ["parent", "child"]
  
  connect() {
    console.log("checkbox-select-all connected")
  }

  toggleChildren() {
    if(this.parentTarget.checked) {
      this.childTargets.map(x => x.checked = true)
    } else {
      this.childTargets.map(x => x.checked = false)
    }
  }
  toggleParent() {
    if(this.childTargets.every(x => x.checked)) {
      this.parentTarget.checked = true
    } else {
      this.parentTarget.checked = false
    }
  }
}