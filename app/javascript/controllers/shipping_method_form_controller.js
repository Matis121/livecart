import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["pickupProvider"]

  togglePickupProvider(event) {
    this.pickupProviderTarget.style.display = event.target.checked ? "block" : "none"
  }
}