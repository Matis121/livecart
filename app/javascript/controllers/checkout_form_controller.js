import { Controller } from "@hotwired/stimulus"

// Manages the checkout form mode toggle (open package vs ship now)
// and live shipping cost + total updates in the order summary
export default class extends Controller {
  static targets = ["modeRadio", "paymentSection", "paymentRadio", "shippingRadio", "submitButton"]
  static values = { itemsSubtotal: Number, discountAmount: Number }

  connect() {
    this.updateShipping()
  }

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

  updateShipping() {
    const selected = this.shippingRadioTargets.find(r => r.checked)
    const shippingEl = document.getElementById("summary-shipping-cost")
    const totalEl = document.getElementById("summary-total")
    if (!shippingEl || !totalEl) return

    if (!selected) {
      shippingEl.innerHTML = `<span class="body-text font-medium text-base-content/40">—</span>`
      totalEl.textContent = this.#formatCurrency(this.itemsSubtotalValue - this.discountAmountValue)
      return
    }

    const price = parseFloat(selected.dataset.price)
    const total = this.itemsSubtotalValue + price - this.discountAmountValue

    if (price === 0) {
      shippingEl.innerHTML = `<span class="body-text font-medium text-success">Darmowa</span>`
    } else {
      shippingEl.innerHTML = `<span class="body-text font-medium">${this.#formatCurrency(price)}</span>`
    }

    totalEl.textContent = this.#formatCurrency(Math.max(0, total))
  }

  #formatCurrency(amount) {
    return new Intl.NumberFormat("pl-PL", { style: "currency", currency: "PLN" }).format(amount)
  }
}
