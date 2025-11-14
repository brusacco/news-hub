import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "results", "dropdown"]
  static values = { url: String }

  connect() {
    this.timeout = null
    this.isOpen = false
    this.hideResults()
  }

  disconnect() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
    document.removeEventListener("click", this.handleClickOutside.bind(this))
  }

  search() {
    const query = this.inputTarget.value.trim()

    // Limpiar timeout anterior
    if (this.timeout) {
      clearTimeout(this.timeout)
    }

    // Si la búsqueda es muy corta, ocultar resultados
    if (query.length < 2) {
      this.hideResults()
      return
    }

    // Debounce: esperar 300ms antes de buscar
    this.timeout = setTimeout(() => {
      this.performSearch(query)
    }, 300)
  }

  async performSearch(query) {
    try {
      const response = await fetch(`${this.urlValue}?q=${encodeURIComponent(query)}`, {
        headers: {
          "Accept": "application/json",
          "X-Requested-With": "XMLHttpRequest"
        }
      })

      if (!response.ok) {
        throw new Error("Search failed")
      }

      const data = await response.json()
      this.displayResults(data, query)
    } catch (error) {
      console.error("Search error:", error)
      this.hideResults()
    }
  }

  displayResults(data, query) {
    const hasResults = (data.tags && data.tags.length > 0) || 
                       (data.entries && data.entries.length > 0)

    if (!hasResults) {
      this.resultsTarget.innerHTML = `
        <div class="p-4 text-center text-sm text-slate-500">
          No results found for "${query}"
        </div>
      `
      this.showResults()
      return
    }

    let html = ""

    // Mostrar tags
    if (data.tags && data.tags.length > 0) {
      html += `
        <div class="px-4 py-2">
          <div class="text-xs font-semibold text-slate-500 uppercase tracking-wide mb-2">Topics</div>
          <div class="space-y-1">
            ${data.tags.map(tag => `
              <a href="${tag.url}" class="flex items-center justify-between rounded-lg px-3 py-2 text-sm text-slate-700 hover:bg-slate-100 transition-colors group">
                <span class="font-medium">${this.highlight(query, tag.name)}</span>
                <span class="text-xs text-slate-400">${tag.count} articles</span>
              </a>
            `).join("")}
          </div>
        </div>
      `
    }

    // Mostrar entradas
    if (data.entries && data.entries.length > 0) {
      if (html) html += '<div class="border-t border-slate-200"></div>'
      html += `
        <div class="px-4 py-2">
          <div class="text-xs font-semibold text-slate-500 uppercase tracking-wide mb-2">Articles</div>
          <div class="space-y-1">
            ${data.entries.map(entry => `
              <a href="${entry.url}" class="flex items-start gap-3 rounded-lg px-3 py-2 text-sm hover:bg-slate-100 transition-colors group">
                ${entry.image_url ? `
                  <img src="${entry.image_url}" alt="${entry.title}" class="h-12 w-12 rounded-md object-cover flex-shrink-0">
                ` : `
                  <div class="h-12 w-12 rounded-md bg-slate-200 flex-shrink-0"></div>
                `}
                <div class="flex-1 min-w-0">
                  <div class="font-medium text-slate-900 line-clamp-2 group-hover:text-indigo-600">${this.highlight(query, entry.title)}</div>
                  ${entry.published_at ? `
                    <div class="text-xs text-slate-500 mt-1">${entry.published_at}</div>
                  ` : ""}
                </div>
              </a>
            `).join("")}
          </div>
        </div>
      `
    }

    // Link para ver todos los resultados
    html += `
      <div class="border-t border-slate-200">
        <a href="/search?keyword=${encodeURIComponent(query)}" class="block px-4 py-3 text-sm font-medium text-indigo-600 hover:bg-indigo-50 transition-colors text-center">
          View all results →
        </a>
      </div>
    `

    this.resultsTarget.innerHTML = html
    this.showResults()
  }

  highlight(query, text) {
    if (!query || !text) return text
    const regex = new RegExp(`(${query})`, "gi")
    return text.replace(regex, '<mark class="bg-indigo-100 text-indigo-900 rounded px-0.5">$1</mark>')
  }

  showResults() {
    this.dropdownTarget.classList.remove("hidden")
    this.isOpen = true
    // Agregar listener para clicks fuera
    setTimeout(() => {
      document.addEventListener("click", this.handleClickOutside.bind(this))
    }, 100)
  }

  hideResults() {
    this.dropdownTarget.classList.add("hidden")
    this.isOpen = false
    document.removeEventListener("click", this.handleClickOutside.bind(this))
  }

  handleClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.hideResults()
    }
  }

  handleKeydown(event) {
    if (event.key === "Escape") {
      this.hideResults()
      this.inputTarget.blur()
    }
  }

  submit(event) {
    if (event.key === "Enter" && this.inputTarget.value.trim().length >= 2) {
      event.preventDefault()
      window.location.href = `/search?keyword=${encodeURIComponent(this.inputTarget.value.trim())}`
    }
  }
}

