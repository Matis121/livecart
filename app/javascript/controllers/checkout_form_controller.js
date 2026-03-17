import { Controller } from "@hotwired/stimulus";

// Manages the checkout form mode toggle (open package vs ship now),
// live shipping cost + total updates, and pickup point widget integration
export default class extends Controller {
  static targets = [
    "modeRadio",
    "paymentSection",
    "paymentRadio",
    "shippingRadio",
    "submitButton",
    "pickupSection",
    "pickupEmptyState",
    "pickupSelectedState",
    "pickupDisplayName",
    "pickupDisplayAddress",
    "pickupDisplayCity",
    "pickupPointId",
    "pickupPointName",
    "pickupPointAddress",
    "pickupPointPostalCode",
    "pickupPointCity",
  ];
  static values = {
    itemsSubtotal: Number,
    discountAmount: Number,
    inpostWidgetToken: String,
    orlenWidgetToken: String,
  };

  #currentPickupProvider = null;

  connect() {
    this.element.addEventListener(
      "submit",
      this.#validatePickupPoint.bind(this),
    );
    const modal = document.getElementById("pickup-point-modal");
    modal?.addEventListener("close", () => {
      const container = document.getElementById("pickup-widget-container");
      if (container) container.innerHTML = "";
    });
    this.updateShipping();
  }

  toggleMode() {
    const selected = this.modeRadioTargets.find((r) => r.checked);
    if (!selected) return;

    if (selected.value === "ship_now") {
      this.paymentSectionTarget.classList.remove("hidden");
      // Make shipping and payment required
      this.shippingRadioTargets.forEach((radio, index) => {
        if (index === 0) radio.required = true;
      });
      this.paymentRadioTargets.forEach((radio, index) => {
        if (index === 0) radio.required = true;
      });
      this.submitButtonTarget.textContent = "Zamów i zapłać";
      this.submitButtonTarget.classList.remove("btn-disabled", "btn-warning");
      this.submitButtonTarget.classList.add("btn-primary");
      this.submitButtonTarget.disabled = false;
    } else {
      this.paymentSectionTarget.classList.add("hidden");
      // Remove shipping and payment requirement
      this.shippingRadioTargets.forEach((radio) => {
        radio.required = false;
        radio.checked = false;
      });
      this.paymentRadioTargets.forEach((radio) => {
        radio.required = false;
        radio.checked = false;
      });
      this.submitButtonTarget.textContent = "Otwarta paczka";
      this.submitButtonTarget.classList.remove("btn-disabled", "btn-primary");
      this.submitButtonTarget.classList.add("btn-warning");
      this.submitButtonTarget.disabled = false;
    }
  }

  updateShipping() {
    const selected = this.shippingRadioTargets.find((r) => r.checked);
    const shippingEl = document.getElementById("summary-shipping-cost");
    const totalEl = document.getElementById("summary-total");

    if (!selected) {
      if (shippingEl)
        shippingEl.innerHTML = `<span class="body-text font-medium text-base-content/40">—</span>`;
      if (totalEl)
        totalEl.textContent = this.#formatCurrency(
          this.itemsSubtotalValue - this.discountAmountValue,
        );
      if (this.hasPickupSectionTarget) {
        this.pickupSectionTarget.classList.add("hidden");
        this.#clearPickupPoint();
      }
      return;
    }

    const price = parseFloat(selected.dataset.price);
    const total = this.itemsSubtotalValue + price - this.discountAmountValue;

    if (shippingEl) {
      if (price === 0) {
        shippingEl.innerHTML = `<span class="body-text font-medium text-success">Darmowa</span>`;
      } else {
        shippingEl.innerHTML = `<span class="body-text font-medium">${this.#formatCurrency(price)}</span>`;
      }
    }

    if (totalEl) totalEl.textContent = this.#formatCurrency(Math.max(0, total));

    // Handle pickup point section
    if (this.hasPickupSectionTarget) {
      const isPickupPoint = selected.dataset.isPickupPoint === "true";
      if (isPickupPoint) {
        const newProvider = selected.dataset.pickupPointProvider;
        if (newProvider !== this.#currentPickupProvider) {
          this.#clearPickupPoint();
          const container = document.getElementById("pickup-widget-container");
          if (container) container.innerHTML = "";
        }
        this.pickupSectionTarget.classList.remove("hidden");
        this.#currentPickupProvider = newProvider;
      } else {
        this.pickupSectionTarget.classList.add("hidden");
        this.#clearPickupPoint();
      }
    }
  }

  openPickupWidget() {
    const modal = document.getElementById("pickup-point-modal");
    const container = document.getElementById("pickup-widget-container");
    if (!modal || !container) return;

    if (this.#currentPickupProvider === "inpost") {
      this.#initInpostWidget(container);
    } else if (this.#currentPickupProvider === "orlen") {
      this.#initOrlenWidget(container);
    }

    modal.showModal();
  }

  // --- Private methods ---

  #initInpostWidget(container) {
    this.#loadInpostAssets();
    container.innerHTML = `<inpost-geowidget
      id="inpost-widget"
      token="${this.inpostWidgetTokenValue}"
      language="pl"
      config="parcelCollect"
      onpoint="checkoutPickupPointCallback"
      style="height:100%;width:100%;"
    ></inpost-geowidget>`;

    window.checkoutPickupPointCallback = (point) => {
      this.#onPointSelected({
        point_id: point.name,
        name: point.name,
        address_line1: point.address?.line1 || "",
        postal_code: point.address_details?.post_code || "",
        city: point.address_details?.city || "",
      });
      document.getElementById("pickup-point-modal").close();
    };
  }

  #initOrlenWidget(container) {
    this.#loadOrlenAssets();
    container.innerHTML = `<orlen-geowidget
      id="orlen-widget"
      token="${this.orlenWidgetTokenValue}"
      language="pl"
      onpoint="checkoutPickupPointCallback"
      style="height:100%;width:100%;"
    ></orlen-geowidget>`;

    window.checkoutPickupPointCallback = (point) => {
      this.#onPointSelected({
        point_id: point.id,
        name: point.name,
        address_line1: point.address?.line1 || "",
        postal_code: point.address_details?.post_code || "",
        city: point.address_details?.city || "",
      });
      document.getElementById("pickup-point-modal").close();
    };
  }

  #loadInpostAssets() {
    if (!document.getElementById("inpost-geowidget-css")) {
      const link = document.createElement("link");
      link.id = "inpost-geowidget-css";
      link.rel = "stylesheet";
      link.href = "https://geowidget.inpost.pl/inpost-geowidget.css";
      document.head.appendChild(link);
    }
    if (!document.getElementById("inpost-geowidget-js")) {
      const script = document.createElement("script");
      script.id = "inpost-geowidget-js";
      script.src = "https://geowidget.inpost.pl/inpost-geowidget.js";
      document.head.appendChild(script);
    }
  }

  #loadOrlenAssets() {
    if (!document.getElementById("orlen-geowidget-css")) {
      const link = document.createElement("link");
      link.id = "orlen-geowidget-css";
      link.rel = "stylesheet";
      link.href = "https://geowidget.orlen.pl/orlen-geowidget.css";
      document.head.appendChild(link);
    }
    if (!document.getElementById("orlen-geowidget-js")) {
      const script = document.createElement("script");
      script.id = "orlen-geowidget-js";
      script.src = "https://geowidget.orlen.pl/orlen-geowidget.js";
      document.head.appendChild(script);
    }
  }

  #onPointSelected(point) {
    this.pickupPointIdTarget.value = point.point_id;
    this.pickupPointNameTarget.value = point.name;
    this.pickupPointAddressTarget.value = point.address_line1;
    this.pickupPointPostalCodeTarget.value = point.postal_code;
    this.pickupPointCityTarget.value = point.city;

    this.pickupDisplayNameTarget.textContent = point.name;
    this.pickupDisplayAddressTarget.textContent = point.address_line1;
    this.pickupDisplayCityTarget.textContent = `${point.postal_code} ${point.city}`;

    this.pickupEmptyStateTarget.classList.add("hidden");
    this.pickupSelectedStateTarget.classList.remove("hidden");
  }

  #clearPickupPoint() {
    if (!this.hasPickupPointIdTarget) return;
    this.pickupPointIdTarget.value = "";
    this.pickupPointNameTarget.value = "";
    this.pickupPointAddressTarget.value = "";
    this.pickupPointPostalCodeTarget.value = "";
    this.pickupPointCityTarget.value = "";

    this.pickupEmptyStateTarget.classList.remove("hidden");
    this.pickupSelectedStateTarget.classList.add("hidden");
  }

  #validatePickupPoint(e) {
    if (!this.hasPickupSectionTarget) return;
    if (this.pickupSectionTarget.classList.contains("hidden")) return;
    if (this.pickupPointIdTarget.value) return;

    e.preventDefault();
    alert("Proszę wybrać punkt odbioru przed złożeniem zamówienia.");
    this.pickupSectionTarget.scrollIntoView({ behavior: "smooth" });
  }

  #formatCurrency(amount) {
    return new Intl.NumberFormat("pl-PL", {
      style: "currency",
      currency: "PLN",
    }).format(amount);
  }
}
