import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "rows",
    "template",
    "row",
    "warehouseSection",
    "manualSection",
    "productSelect",
    "manualName",
    "manualPrice",
    "sourceLabel",
    "searchInput",
    "resultsDropdown",
    "productsList",
    "minChars",
    "noResults",
    "selectedProduct",
    "selectedName",
    "selectedSku",
    "selectedEan",
    "selectedQuantity",
    "selectedImage",
    "productIdInput",
  ];

  static values = {
    transmissionId: Number,
  };

  connect() {
    this.toggleSource();
    this.searchTimeout = null;
    this.customerSearchTimeout = null;
    this.boundCloseDropdown = this.closeDropdownOnClickOutside.bind(this);
    document.addEventListener("mousedown", this.boundCloseDropdown);
  }

  disconnect() {
    document.removeEventListener("mousedown", this.boundCloseDropdown);
  }

  toggleSource() {
    const isManual =
      this.element.querySelector('input[name="product_source"]:checked')
        ?.value === "manual";
    if (isManual) {
      this.warehouseSectionTarget?.classList.add("hidden");
      this.manualSectionTarget?.classList.remove("hidden");
      this.manualNameTarget?.setAttribute("required", "required");
      this.manualPriceTarget?.setAttribute("required", "required");
    } else {
      this.warehouseSectionTarget?.classList.remove("hidden");
      this.manualSectionTarget?.classList.add("hidden");
      this.manualNameTarget?.removeAttribute("required");
      this.manualPriceTarget?.removeAttribute("required");
    }
    // Odśwież style przycisków źródła
    this.sourceLabelTargets?.forEach((label, i) => {
      const isActive = (i === 0 && !isManual) || (i === 1 && isManual);
      label.classList.toggle("btn-primary", isActive);
      label.classList.toggle("btn-ghost", !isActive);
    });
  }

  handleFocus() {
    if (this.hasResultsDropdownTarget) {
      this.resultsDropdownTarget.classList.remove("hidden");
    }
  }

  filterProducts(event) {
    const query = event.target.value.trim();

    clearTimeout(this.searchTimeout);

    if (query.length < 2) {
      this.productsListTarget.innerHTML = "";
      this.minCharsTarget.classList.remove("hidden");
      this.noResultsTarget.classList.add("hidden");
      this.resultsDropdownTarget.classList.add("hidden");
      return;
    }

    this.minCharsTarget.classList.add("hidden");
    this.resultsDropdownTarget.classList.remove("hidden");

    this.searchTimeout = setTimeout(() => {
      fetch(
        `/transmissions/${this.transmissionIdValue}/transmission_items/search_products?q=${encodeURIComponent(query)}`,
      )
        .then((response) => response.text())
        .then((html) => {
          this.productsListTarget.innerHTML = html;

          if (!html.trim()) {
            this.noResultsTarget.classList.remove("hidden");
          } else {
            this.noResultsTarget.classList.add("hidden");
          }
        })
        .catch((error) => {
          console.error("Error fetching products:", error);
        });
    }, 300);
  }

  selectProduct(event) {
    console.log("selectProduct called", event.currentTarget.dataset);
    event.stopPropagation();
    event.preventDefault();

    const button = event.currentTarget;
    const productId = button.dataset.productId;
    const productName = button.dataset.productName;
    const productSku = button.dataset.productSku;
    const productEan = button.dataset.productEan;
    const productQuantity = button.dataset.productQuantity;
    const productImage = button.dataset.productImage;

    this.productIdInputTarget.value = productId;
    this.selectedNameTarget.textContent = productName;
    this.selectedSkuTarget.textContent = productSku || "-";
    this.selectedEanTarget.textContent = productEan || "-";
    this.selectedQuantityTarget.textContent = productQuantity || "0";

    if (productImage) {
      this.selectedImageTarget.src = productImage;
      this.selectedImageTarget.style.display = "block";
    } else {
      this.selectedImageTarget.style.display = "none";
    }

    this.selectedProductTarget.classList.remove("hidden");
    this.resultsDropdownTarget.classList.add("hidden");
    this.searchInputTarget.value = "";

    console.log("Product selected:", productName);
  }

  clearProduct() {
    this.productIdInputTarget.value = "";
    this.selectedProductTarget.classList.add("hidden");
    this.searchInputTarget.value = "";
  }

  closeDropdownOnClickOutside(event) {
    if (!this.element.contains(event.target)) {
      if (this.hasResultsDropdownTarget) {
        this.resultsDropdownTarget.classList.add("hidden");
      }
      this.element
        .querySelectorAll(".customer-dropdown")
        .forEach((d) => d.classList.add("hidden"));
    }
  }

  // --- Customer search ---

  filterCustomers(event) {
    const input = event.target;
    const container = input.closest(".relative");
    const dropdown = container.querySelector(".customer-dropdown");
    const rawValue = input.value;
    const query = rawValue.replace(/^@/, "").trim();

    clearTimeout(this.customerSearchTimeout);

    if (query.length === 0) {
      dropdown.classList.add("hidden");
      dropdown.innerHTML = "";
      container.querySelector("input[name='items[][customer_id]']").value = "";
      container.querySelector("input[name='items[][customer_name]']").value = "";
      return;
    }

    dropdown.classList.remove("hidden");
    dropdown.innerHTML =
      '<div class="p-3 text-sm text-base-content/40">Szukam...</div>';

    this.customerSearchTimeout = setTimeout(() => {
      fetch(
        `/transmissions/${this.transmissionIdValue}/transmission_items/search_customers?q=${encodeURIComponent(rawValue)}`,
        { headers: { Accept: "application/json" } },
      )
        .then((r) => r.json())
        .then((customers) =>
          this.renderCustomerResults(container, dropdown, customers, query),
        )
        .catch(() => dropdown.classList.add("hidden"));
    }, 250);
  }

  openCustomerDropdown(event) {
    const input = event.target;
    if (input.value.trim().length > 0) {
      const dropdown = input.closest(".relative").querySelector(".customer-dropdown");
      if (dropdown.innerHTML.trim()) dropdown.classList.remove("hidden");
    }
  }

  renderCustomerResults(container, dropdown, customers, query) {
    let html = customers
      .map((c) => {
        const display = c.username
          ? `@${this.escapeHtml(c.username)}`
          : this.escapeHtml(c.name);
        const sub = c.email
          ? `<div class="text-xs text-base-content/50">${this.escapeHtml(c.email)}</div>`
          : "";
        return `<button type="button"
            class="w-full text-left px-4 py-2.5 hover:bg-base-200 transition-colors"
            data-action="click->transmission-items-form#selectExistingCustomer"
            data-customer-id="${c.id}"
            data-display="${this.escapeHtml(display)}">
          <div class="font-medium text-sm">${display}</div>${sub}
        </button>`;
      })
      .join('<div class="border-t border-base-200"></div>');

    if (customers.length > 0) {
      html += '<div class="border-t border-base-200"></div>';
    }

    html += `<button type="button"
        class="w-full text-left px-4 py-2.5 hover:bg-base-200 transition-colors text-base-content/60"
        data-action="click->transmission-items-form#selectNewCustomer"
        data-name="${this.escapeHtml(query)}">
      <div class="text-sm">Dodaj jako nowego: <strong>${this.escapeHtml(query)}</strong></div>
    </button>`;

    dropdown.innerHTML = html;
    dropdown.classList.remove("hidden");
  }

  selectExistingCustomer(event) {
    const btn = event.currentTarget;
    const container = btn.closest(".relative");
    this._applyCustomerSelection(
      container,
      btn.dataset.customerId,
      "",
      btn.dataset.display,
    );
  }

  selectNewCustomer(event) {
    const btn = event.currentTarget;
    const container = btn.closest(".relative");
    this._applyCustomerSelection(container, "", btn.dataset.name, btn.dataset.name);
  }

  _applyCustomerSelection(container, customerId, customerName, displayText) {
    container.querySelector(".customer-search-input").value = displayText;
    container.querySelector("input[name='items[][customer_id]']").value = customerId;
    container.querySelector("input[name='items[][customer_name]']").value = customerName;
    container.querySelector(".customer-dropdown").classList.add("hidden");
  }

  escapeHtml(str) {
    return String(str || "")
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;");
  }

  addRow() {
    const content = this.templateTarget.content.cloneNode(true);
    this.rowsTarget.appendChild(content);
  }

  removeRow(event) {
    const row = event.currentTarget.closest(
      "[data-transmission-items-form-target='row']",
    );
    if (this.rowTargets.length > 1) row.remove();
  }
}
