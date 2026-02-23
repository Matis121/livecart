import { Controller } from "@hotwired/stimulus"

// Manages the checkout form mode toggle (open package vs ship now)
export default class extends Controller {
  static targets = ["modeRadio", "paymentSection", "paymentRadio", "shippingRadio", "submitButton"]

  toggleMode() {
    const selected = this.modeRadioTargets.find(r => r.checked)
    if (!selected) return

    if (selected.value === "ship_now") {
      this.paymentSectionTarget.classList.remove("hidden")
      // Make shipping and payment required
      this.shippingRadioTargets.forEach((radio, index) => {
        if (index === 0) radio.required = true
      })
      this.paymentRadioTargets.forEach((radio, index) => {
        if (index === 0) radio.required = true
      })
      this.submitButtonTarget.textContent = "Zamów i zapłać"
      this.submitButtonTarget.classList.remove("btn-disabled", "btn-warning")
      this.submitButtonTarget.classList.add("btn-primary")
      this.submitButtonTarget.disabled = false
    } else {
      this.paymentSectionTarget.classList.add("hidden")
      // Remove shipping and payment requirement
      this.shippingRadioTargets.forEach(radio => {
        radio.required = false
        radio.checked = false
      })
      this.paymentRadioTargets.forEach(radio => {
        radio.required = false
        radio.checked = false
      })
      this.submitButtonTarget.textContent = "Otwarta paczka"
      this.submitButtonTarget.classList.remove("btn-disabled", "btn-primary")
      this.submitButtonTarget.classList.add("btn-warning")
      this.submitButtonTarget.disabled = false
    }
  }
}
