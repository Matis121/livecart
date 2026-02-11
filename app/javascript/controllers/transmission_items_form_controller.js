import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["rows", "template", "row", "warehouseSection", "manualSection", "productSelect", "manualName", "manualPrice", "sourceLabel"]

  connect() {
    this.toggleSource()
  }

  toggleSource() {
    const isManual = this.element.querySelector('input[name="product_source"]:checked')?.value === "manual"
    if (isManual) {
      this.warehouseSectionTarget?.classList.add("hidden")
      this.manualSectionTarget?.classList.remove("hidden")
      this.productSelectTarget?.removeAttribute("required")
      this.manualNameTarget?.setAttribute("required", "required")
      this.manualPriceTarget?.setAttribute("required", "required")
    } else {
      this.warehouseSectionTarget?.classList.remove("hidden")
      this.manualSectionTarget?.classList.add("hidden")
      this.productSelectTarget?.setAttribute("required", "required")
      this.manualNameTarget?.removeAttribute("required")
      this.manualPriceTarget?.removeAttribute("required")
    }
    // Odśwież style przycisków źródła
    this.sourceLabelTargets?.forEach((label, i) => {
      const isActive = (i === 0 && !isManual) || (i === 1 && isManual)
      label.classList.toggle("btn-primary", isActive)
      label.classList.toggle("btn-ghost", !isActive)
    })
  }

  addRow() {
    const content = this.templateTarget.content.cloneNode(true)
    this.rowsTarget.appendChild(content)
  }

  removeRow(event) {
    const row = event.currentTarget.closest("[data-transmission-items-form-target='row']")
    if (this.rowTargets.length > 1) row.remove()
  }
}