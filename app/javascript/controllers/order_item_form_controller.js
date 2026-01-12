import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["fromStock", "manual", "searchInput", "dropdown", "dropdownMenu", "productsList", "minChars", "noResults", "cartContainer", "cartItems", "cartCount", "cartData", "name", "sku", "ean", "unitPrice", "quantity", "totalPrice"]
  static values = { minSearchLength: { type: Number, default: 2 } }

  connect() {
    this.showFromStock()
    this.setupClickOutside()
    this.cart = []
    
    // Ustaw focus na pole wyszukiwania
    if (this.hasSearchInputTarget) {
      setTimeout(() => {
        this.searchInputTarget.focus()
      }, 100)
    }
  }

  disconnect() {
    this.cleanupClickOutside()
  }

  setupClickOutside() {
    this.clickOutsideHandler = (event) => {
      if (this.hasDropdownTarget && !this.dropdownTarget.contains(event.target)) {
        this.closeDropdown()
      }
    }
    document.addEventListener('click', this.clickOutsideHandler)
  }

  cleanupClickOutside() {
    if (this.clickOutsideHandler) {
      document.removeEventListener('click', this.clickOutsideHandler)
    }
  }

  showFromStock() {
    this.fromStockTarget.classList.remove("hidden")
    this.manualTarget.classList.add("hidden")
    
    // Ustaw focus na pole wyszukiwania
    if (this.hasSearchInputTarget) {
      setTimeout(() => {
        this.searchInputTarget.focus()
      }, 100)
    }
  }

  showManual() {
    this.fromStockTarget.classList.add("hidden")
    this.manualTarget.classList.remove("hidden")
    this.closeDropdown()
  }

  handleFocus() {
    const searchTerm = this.searchInputTarget.value
    if (searchTerm.length >= this.minSearchLengthValue) {
      this.openDropdown()
    }
  }

  openDropdown() {
    if (this.hasDropdownMenuTarget) {
      this.dropdownMenuTarget.classList.remove('hidden')
    }
  }

  closeDropdown() {
    if (this.hasDropdownMenuTarget) {
      this.dropdownMenuTarget.classList.add('hidden')
    }
  }

  filterProducts(event) {
    const searchTerm = event.target.value.toLowerCase().trim()
    
    if (searchTerm.length < this.minSearchLengthValue) {
      this.closeDropdown()
      return
    }

    this.openDropdown()

    const productItems = this.productsListTarget.querySelectorAll('.product-item')
    let visibleCount = 0

    productItems.forEach(item => {
      const searchText = item.dataset.searchText || ''
      if (searchText.includes(searchTerm)) {
        item.classList.remove('hidden')
        visibleCount++
      } else {
        item.classList.add('hidden')
      }
    })

    if (this.hasMinCharsTarget) {
      this.minCharsTarget.classList.add('hidden')
    }

    if (this.hasNoResultsTarget && this.hasProductsListTarget) {
      if (visibleCount === 0) {
        this.noResultsTarget.classList.remove('hidden')
        this.productsListTarget.parentElement.classList.add('hidden')
      } else {
        this.noResultsTarget.classList.add('hidden')
        this.productsListTarget.parentElement.classList.remove('hidden')
      }
    }
  }

  addToCart(event) {
    const button = event.currentTarget
    const product = {
      id: button.dataset.productId,
      name: button.dataset.productName,
      sku: button.dataset.productSku,
      ean: button.dataset.productEan,
      unit_price: parseFloat(button.dataset.productPrice),
      currency: button.dataset.productCurrency,
      image: button.dataset.productImage,
      quantity: 1
    }

    // Sprawdź czy produkt już jest w koszyku
    const existingIndex = this.cart.findIndex(item => item.id === product.id)
    if (existingIndex >= 0) {
      // Zwiększ ilość jeśli już istnieje
      this.cart[existingIndex].quantity += 1
    } else {
      // Dodaj nowy produkt
      this.cart.push(product)
    }

    this.renderCart()
    this.closeDropdown()
    
    // Wyczyść wyszukiwanie
    if (this.hasSearchInputTarget) {
      this.searchInputTarget.value = ''
    }
  }

  renderCart() {
    if (this.cart.length === 0) {
      this.cartContainerTarget.classList.add('hidden')
      return
    }

    this.cartContainerTarget.classList.remove('hidden')
    this.cartCountTarget.textContent = this.cart.length

    this.cartItemsTarget.innerHTML = this.cart.map((item, index) => `
      <div class="flex gap-3 items-center p-3 bg-base-200 rounded-lg">
        ${item.image ? `
          <div class="avatar">
            <div class="w-12 h-12 rounded">
              <img src="${item.image}" alt="${item.name}" class="object-cover w-full h-full">
            </div>
          </div>
        ` : `
          <div class="w-12 h-12 rounded bg-base-300 flex items-center justify-center flex-shrink-0">
            <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="opacity-30"><rect width="18" height="18" x="3" y="3" rx="2" ry="2"/><circle cx="9" cy="9" r="2"/><path d="m21 15-3.086-3.086a2 2 0 0 0-2.828 0L6 21"/></svg>
          </div>
        `}
        
        <div class="flex-1 min-w-0">
          <div class="font-medium truncate">${item.name}</div>
          <div class="text-xs opacity-60">
            ${item.sku ? `SKU: ${item.sku}` : ''} ${item.ean ? `EAN: ${item.ean}` : ''}
          </div>
        </div>

        <div class="flex items-center gap-2">
          <input 
            type="number" 
            value="${item.quantity}" 
            min="1"
            class="input input-sm input-bordered w-20 text-center"
            data-action="change->order-item-form#updateQuantity keydown.enter->order-item-form#handleEnterKey"
            data-index="${index}">
          <span class="text-sm opacity-60">×</span>
          <span class="font-semibold min-w-[80px] text-right">${(item.unit_price * item.quantity).toFixed(2)} ${item.currency}</span>
        </div>

        <button 
          type="button"
          class="btn btn-ghost btn-sm btn-circle"
          data-action="click->order-item-form#removeFromCart"
          data-index="${index}">
          <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M18 6 6 18"/><path d="m6 6 12 12"/></svg>
        </button>
      </div>
    `).join('')
  }

  updateQuantity(event) {
    const index = parseInt(event.target.dataset.index)
    const newQuantity = parseInt(event.target.value) || 1
    
    if (this.cart[index]) {
      this.cart[index].quantity = Math.max(1, newQuantity)
      this.renderCart()
    }
  }

  handleEnterKey(event) {
    event.preventDefault()
    
    // Najpierw zaktualizuj ilość
    this.updateQuantity(event)
    
    // Znajdź formularz i go wyślij
    const form = this.element.querySelector('form[data-action*="submitCart"]')
    if (form) {
      // Wywołaj submitCart bezpośrednio
      this.submitCart({ 
        target: form, 
        preventDefault: () => {} 
      })
    }
  }

  removeFromCart(event) {
    const index = parseInt(event.currentTarget.dataset.index)
    this.cart.splice(index, 1)
    this.renderCart()
  }

  clearCart() {
    this.cart = []
    this.renderCart()
  }

  async submitCart(event) {
    event.preventDefault()
    
    if (this.cart.length === 0) {
      alert("Koszyk jest pusty")
      return
    }

    const form = event.target
    const formData = new FormData(form)
    
    // Dodaj dane koszyka jako JSON
    formData.set('cart_items', JSON.stringify(this.cart))

    try {
      const response = await fetch(form.action, {
        method: 'POST',
        body: formData,
        headers: {
          'Accept': 'text/vnd.turbo-stream.html'
        }
      })

      if (response.ok) {
        const turboStream = await response.text()
        Turbo.renderStreamMessage(turboStream)
        
        // Wyczyść koszyk po udanym dodaniu
        this.clearCart()
      } else {
        alert("Wystąpił błąd podczas dodawania produktów")
      }
    } catch (error) {
      console.error("Error submitting cart:", error)
      alert("Wystąpił błąd podczas dodawania produktów")
    }
  }

  calculateTotal() {
    if (!this.hasUnitPriceTarget || !this.hasQuantityTarget || !this.hasTotalPriceTarget) return
    
    const unitPrice = parseFloat(this.unitPriceTarget.value) || 0
    const quantity = parseInt(this.quantityTarget.value) || 0
    const total = unitPrice * quantity
    
    this.totalPriceTarget.value = total.toFixed(2)
    this.totalPriceTarget.disabled = false
  }
}
