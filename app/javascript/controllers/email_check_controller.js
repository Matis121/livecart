import { Controller } from "@hotwired/stimulus"

// Live email availability check for anonymous checkout forms.
// Fires on blur of the email input and hits a lightweight JSON endpoint.
// If email is already taken, shows an error and blocks progression.
// Server-side validation remains the authoritative check.
export default class extends Controller {
  static targets = ["input", "error"]
  static values = { url: String }

  async check() {
    const email = this.inputTarget.value.trim()
    if (!email) return

    try {
      const url = new URL(this.urlValue, window.location.origin)
      url.searchParams.set("email", email)
      const response = await fetch(url, { headers: { Accept: "application/json" } })
      const data = await response.json()

      if (data.taken) {
        this.inputTarget.classList.add("input-error")
        this.errorTarget.textContent = "ten adres email jest już zajęty - użyj innego"
        this.errorTarget.classList.remove("hidden")
      } else {
        this.#clearError()
      }
    } catch {
      // sieć niedostępna — walidacja serwerowa jest zabezpieczeniem
    }
  }

  #clearError() {
    this.inputTarget.classList.remove("input-error")
    this.errorTarget.textContent = ""
    this.errorTarget.classList.add("hidden")
  }
}
