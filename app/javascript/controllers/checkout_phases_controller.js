import { Controller } from "@hotwired/stimulus"

// Two-phase checkout flow controller.
// Phase 1: contact info + address forms (new/anonymous customers)
// Phase 2: order review with address summaries + shipping + payment
//
// Transitions:
// - "Kontynuuj" button in Phase 1 → validate → update summaries → show Phase 2
// - "Zmień" buttons in Phase 2 → show Phase 1 (for editing)
// - initialPhaseValue set server-side: 2 if customer has saved address, else 1
export default class extends Controller {
  static targets = [
    "phase1", "phase2",

    // Phase 1 — shipping address inputs
    "shippingFirstName", "shippingLastName",
    "shippingAddress1", "shippingAddress2",
    "shippingCity", "shippingPostalCode",

    // Phase 1 — billing inputs
    "needsInvoice", "invoiceFields",
    "billingCompany", "billingNip",
    "billingFirstName", "billingLastName",
    "billingAddress1",
    "billingCity", "billingPostalCode",

    // Phase 2 — shipping summary
    "summaryShippingName", "summaryShippingAddress1",
    "summaryShippingAddress2", "summaryShippingPostalCity",

    // Phase 2 — billing summary
    "phase2BillingBox",
    "summaryBillingCompany", "summaryBillingNip",
    "summaryBillingName", "summaryBillingAddress1", "summaryBillingPostalCity",
  ]

  static values = { initialPhase: Number }

  connect() {
    if (this.initialPhaseValue === 2) this.#showPhase2()
  }

  // "Kontynuuj" button in Phase 1
  continue(event) {
    event.preventDefault()
    if (!this.#validatePhase1()) return
    if (this.#emailHasError()) return
    this.#updateSummary()
    this.#showPhase2()
  }

  // "Zmień" for shipping address in Phase 2
  editShipping() {
    this.#showPhase1()
    this.shippingFirstNameTarget.focus()
  }

  // "Zmień" for billing data in Phase 2
  editBilling() {
    this.#showPhase1()
    this.needsInvoiceTarget.scrollIntoView({ behavior: "smooth" })
  }

  // Toggle invoice fields visibility in Phase 1
  toggleInvoice() {
    this.invoiceFieldsTarget.classList.toggle("hidden", !this.needsInvoiceTarget.checked)
  }

  // --- private ---

  #validatePhase1() {
    const fields = Array.from(this.phase1Target.querySelectorAll("[required]"))
    const first = fields.find(f => !f.checkValidity())
    if (first) { first.reportValidity(); return false }
    return true
  }

  #emailHasError() {
    // Block progression if email-check found the email is already taken
    const errorEl = this.phase1Target.querySelector("[data-email-check-target='error']")
    return errorEl && !errorEl.classList.contains("hidden") && errorEl.textContent.trim() !== ""
  }

  #updateSummary() {
    // Shipping summary
    const fn = this.shippingFirstNameTarget.value
    const ln = this.shippingLastNameTarget.value
    this.summaryShippingNameTarget.textContent = [fn, ln].filter(Boolean).join(" ")
    this.summaryShippingAddress1Target.textContent = this.shippingAddress1Target.value
    const addr2 = this.shippingAddress2Target.value
    this.summaryShippingAddress2Target.textContent = addr2
    this.summaryShippingAddress2Target.classList.toggle("hidden", !addr2)
    this.summaryShippingPostalCityTarget.textContent =
      [this.shippingPostalCodeTarget.value, this.shippingCityTarget.value].filter(Boolean).join(" ")

    // Billing summary
    const hasBilling = this.needsInvoiceTarget.checked
    this.phase2BillingBoxTarget.classList.toggle("hidden", !hasBilling)
    if (hasBilling) {
      const co = this.billingCompanyTarget.value
      this.summaryBillingCompanyTarget.textContent = co
      this.summaryBillingCompanyTarget.classList.toggle("hidden", !co)
      const nip = this.billingNipTarget.value
      this.summaryBillingNipTarget.textContent = nip ? `NIP: ${nip}` : ""
      this.summaryBillingNipTarget.classList.toggle("hidden", !nip)
      this.summaryBillingNameTarget.textContent =
        [this.billingFirstNameTarget.value, this.billingLastNameTarget.value].filter(Boolean).join(" ")
      this.summaryBillingAddress1Target.textContent = this.billingAddress1Target.value
      this.summaryBillingPostalCityTarget.textContent =
        [this.billingPostalCodeTarget.value, this.billingCityTarget.value].filter(Boolean).join(" ")
    }
  }

  #showPhase1() {
    this.phase1Target.classList.remove("hidden")
    this.phase2Target.classList.add("hidden")
  }

  #showPhase2() {
    this.phase1Target.classList.add("hidden")
    this.phase2Target.classList.remove("hidden")
  }
}
