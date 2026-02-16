import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "fromStock",
    "manual",
    "searchInput",
    "dropdown",
    "dropdownMenu",
    "productsList",
    "minChars",
    "noResults",
    "cartContainer",
    "cartItems",
    "cartCount",
    "cartData",
    "name",
    "sku",
    "ean",
    "unitPrice",
    "quantity",
    "totalPrice",
  ];

  static values = {
    orderNumber: String,
  };

  connect() {
    this.cart = [];
    this.searchTimeout = null;
    document.addEventListener(
      "click",
      this.closeDropdownOnClickOutside.bind(this),
    );
  }

  disconnect() {
    document.removeEventListener(
      "click",
      this.closeDropdownOnClickOutside.bind(this),
    );
  }

  showFromStock(event) {
    event.currentTarget.classList.add("btn-active");
    event.currentTarget.nextElementSibling.classList.remove("btn-active");
    this.fromStockTarget.classList.remove("hidden");
    this.manualTarget.classList.add("hidden");
  }

  showManual(event) {
    event.currentTarget.classList.add("btn-active");
    event.currentTarget.previousElementSibling.classList.remove("btn-active");
    this.manualTarget.classList.remove("hidden");
    this.fromStockTarget.classList.add("hidden");
  }

  handleFocus() {
    this.dropdownMenuTarget.classList.remove("hidden");
  }

  filterProducts(event) {
    const query = event.target.value.trim();

    clearTimeout(this.searchTimeout);

    if (query.length < 2) {
      this.productsListTarget.innerHTML = "";
      this.minCharsTarget.classList.remove("hidden");
      this.noResultsTarget.classList.add("hidden");
      this.dropdownMenuTarget.classList.remove("hidden");
      return;
    }

    this.minCharsTarget.classList.add("hidden");

    this.searchTimeout = setTimeout(() => {
      fetch(
        `/orders/${this.orderNumberValue}/order_items/search_products?q=${encodeURIComponent(query)}`,
      )
        .then((response) => response.text())
        .then((html) => {
          this.productsListTarget.innerHTML = html;

          if (!html.trim()) {
            this.noResultsTarget.classList.remove("hidden");
          } else {
            this.noResultsTarget.classList.add("hidden");
          }

          this.dropdownMenuTarget.classList.remove("hidden");
        })
        .catch((error) => {
          console.error("Error fetching products:", error);
        });
    }, 300);
  }

  closeDropdownOnClickOutside(event) {
    if (!this.dropdownTarget.contains(event.target)) {
      this.dropdownMenuTarget.classList.add("hidden");
    }
  }

  addToCart(event) {
    const button = event.currentTarget;
    const productData = {
      id: button.dataset.productId,
      name: button.dataset.productName,
      sku: button.dataset.productSku,
      ean: button.dataset.productEan,
      unit_price: parseFloat(button.dataset.productPrice),
      currency: button.dataset.productCurrency,
      image: button.dataset.productImage,
      quantity: 1,
    };

    const existingIndex = this.cart.findIndex(
      (item) => item.id === productData.id,
    );

    if (existingIndex !== -1) {
      this.cart[existingIndex].quantity += 1;
    } else {
      this.cart.push(productData);
    }

    this.updateCartUI();
    this.searchInputTarget.value = "";
    this.dropdownMenuTarget.classList.add("hidden");
  }

  updateCartUI() {
    if (this.cart.length === 0) {
      this.cartContainerTarget.classList.add("hidden");
      return;
    }

    this.cartContainerTarget.classList.remove("hidden");
    this.cartCountTarget.textContent = this.cart.length;

    this.cartItemsTarget.innerHTML = this.cart
      .map(
        (item, index) => `
      <div class="flex gap-3 items-center p-3 bg-base-100 rounded-lg">
        ${
          item.image
            ? `
          <div class="avatar flex-shrink-0">
            <div class="w-12 h-12 rounded">
              <img src="${item.image}" alt="${item.name}" class="object-cover">
            </div>
          </div>
        `
            : ""
        }
        <div class="flex-1 min-w-0">
          <div class="font-medium truncate">${item.name}</div>
          <div class="text-xs opacity-60">EAN: ${item.ean || "-"}</div>
          <div class="text-xs opacity-60">SKU: ${item.sku || "-"}</div>
        </div>
        <div class="flex items-center gap-2">
          <label class="text-xs opacity-60">Ilość:</label>
          <input type="number" 
                 min="1" 
                 value="${item.quantity}"
                 class="input input-bordered input-sm w-20 text-center font-mono font-semibold"
                 data-action="change->order-item-form#updateQuantity"
                 data-index="${index}">
        </div>
        <div class="text-right">
          <div class="font-bold">${(item.unit_price * item.quantity).toFixed(2)} ${item.currency}</div>
        </div>
        <button type="button" 
                class="btn btn-ghost btn-sm btn-circle" 
                data-action="click->order-item-form#removeFromCart"
                data-index="${index}">✕</button>
      </div>
    `,
      )
      .join("");

    this.cartDataTarget.value = JSON.stringify(this.cart);
  }

  updateQuantity(event) {
    const index = parseInt(event.currentTarget.dataset.index);
    const newQuantity = parseInt(event.currentTarget.value);

    if (newQuantity > 0) {
      this.cart[index].quantity = newQuantity;
      this.updateCartUI();
    } else {
      event.currentTarget.value = 1;
      this.cart[index].quantity = 1;
      this.updateCartUI();
    }
  }

  removeFromCart(event) {
    const index = parseInt(event.currentTarget.dataset.index);
    this.cart.splice(index, 1);
    this.updateCartUI();
  }

  calculateTotal() {
    if (
      this.hasUnitPriceTarget &&
      this.hasQuantityTarget &&
      this.hasTotalPriceTarget
    ) {
      const unitPrice = parseFloat(this.unitPriceTarget.value) || 0;
      const quantity = parseInt(this.quantityTarget.value) || 0;
      const total = unitPrice * quantity;
      this.totalPriceTarget.value = total.toFixed(2);
    }
  }
}
