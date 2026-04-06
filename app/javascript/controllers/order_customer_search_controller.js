import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["searchInput", "dropdown", "customerIdInput"];

  connect() {
    this.searchTimeout = null;
    this.boundCloseDropdown = this.closeDropdownOnClickOutside.bind(this);
    document.addEventListener("mousedown", this.boundCloseDropdown);
  }

  disconnect() {
    document.removeEventListener("mousedown", this.boundCloseDropdown);
  }

  filter(event) {
    const rawValue = event.target.value;
    const query = rawValue.replace(/^@/, "").trim();

    clearTimeout(this.searchTimeout);

    if (query.length < 2) {
      this.dropdownTarget.classList.add("hidden");
      this.dropdownTarget.innerHTML = "";
      this.customerIdInputTarget.value = "";
      return;
    }

    this.dropdownTarget.classList.remove("hidden");
    this.dropdownTarget.innerHTML =
      '<div class="p-3 text-sm text-base-content/40">Szukam...</div>';

    this.searchTimeout = setTimeout(() => {
      fetch(
        `/orders/search_customers?q=${encodeURIComponent(rawValue)}`,
        { headers: { Accept: "application/json" } }
      )
        .then((r) => r.json())
        .then((customers) => this.renderResults(customers, query))
        .catch(() => this.dropdownTarget.classList.add("hidden"));
    }, 250);
  }

  openDropdown(event) {
    const query = event.target.value.replace(/^@/, "").trim();
    if (query.length >= 2 && this.dropdownTarget.innerHTML.trim()) {
      this.dropdownTarget.classList.remove("hidden");
    }
  }

  renderResults(customers, query) {
    if (customers.length === 0) {
      this.dropdownTarget.innerHTML =
        '<div class="p-3 text-sm text-base-content/40">Nie znaleziono klientów</div>';
      return;
    }

    const html = customers
      .map((c) => {
        const display = c.username
          ? `@${this.escapeHtml(c.username)}`
          : this.escapeHtml(c.name);
        const sub = c.email
          ? `<div class="text-xs text-base-content/50">${this.escapeHtml(c.email)}</div>`
          : "";
        return `<button type="button"
            class="w-full text-left px-4 py-2.5 hover:bg-base-200 transition-colors"
            data-action="click->order-customer-search#selectCustomer"
            data-customer-id="${c.id}"
            data-customer-name="${this.escapeHtml(c.name)}"
            data-display="${this.escapeHtml(display)}">
          <div class="font-medium text-sm">${display}</div>${sub}
        </button>`;
      })
      .join('<div class="border-t border-base-200"></div>');

    this.dropdownTarget.innerHTML = html;
    this.dropdownTarget.classList.remove("hidden");
  }

  selectCustomer(event) {
    const btn = event.currentTarget;
    this.customerIdInputTarget.value = btn.dataset.customerId;
    this.searchInputTarget.value = btn.dataset.customerName;
    this.dropdownTarget.classList.add("hidden");
  }

  closeDropdownOnClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.dropdownTarget.classList.add("hidden");
    }
  }

  escapeHtml(str) {
    return String(str || "")
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;");
  }
}
