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
    this.boundCloseDropdown = this.closeDropdownOnClickOutside.bind(this);
    document.addEventListener(
      "mousedown",
      this.boundCloseDropdown,
    );
  }

  disconnect() {
    document.removeEventListener(
      "mousedown",
      this.boundCloseDropdown,
    );
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
    console.log('selectProduct called', event.currentTarget.dataset);
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
      this.selectedImageTarget.style.display = 'block';
    } else {
      this.selectedImageTarget.style.display = 'none';
    }

    this.selectedProductTarget.classList.remove("hidden");
    this.resultsDropdownTarget.classList.add("hidden");
    this.searchInputTarget.value = "";
    
    console.log('Product selected:', productName);
  }

  clearProduct() {
    this.productIdInputTarget.value = "";
    this.selectedProductTarget.classList.add("hidden");
    this.searchInputTarget.value = "";
  }

  closeDropdownOnClickOutside(event) {
    if (
      this.hasResultsDropdownTarget &&
      !this.element.contains(event.target)
    ) {
      this.resultsDropdownTarget.classList.add("hidden");
    }
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
