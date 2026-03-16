import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "uploadTile"]

  preview() {
    const newFiles = this.inputTarget.files
    if (!newFiles.length) return

    // Scal poprzednio zgromadzone pliki z nowo wybranymi
    const merged = new DataTransfer()
    Array.from(this._accumulated || []).forEach(f => merged.items.add(f))
    Array.from(newFiles).forEach(f => merged.items.add(f))
    this._accumulated = merged.files
    this.inputTarget.files = merged.files

    // Dodaj podglądy tylko dla nowo wybranych
    Array.from(newFiles).forEach(file => {
      const reader = new FileReader()
      reader.onload = (e) => {
        const wrapper = document.createElement("div")
        wrapper.className = "relative group"

        const img = document.createElement("img")
        img.src = e.target.result
        img.className = "w-full aspect-square object-cover rounded-lg border border-base-200"

        const badge = document.createElement("div")
        badge.className = "absolute top-1 left-1 bg-success text-success-content rounded px-1.5 py-0.5 flex items-center gap-1"
        badge.innerHTML = `
          <svg xmlns="http://www.w3.org/2000/svg" width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round">
            <polyline points="20 6 9 17 4 12"/>
          </svg>
          <span style="font-size:10px;font-weight:700;text-transform:uppercase;letter-spacing:0.05em">Nowe</span>
        `

        wrapper.appendChild(img)
        wrapper.appendChild(badge)
        this.uploadTileTarget.before(wrapper)
      }
      reader.readAsDataURL(file)
    })
  }
}
