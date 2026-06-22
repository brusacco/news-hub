import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["overlay", "image", "caption", "item"]

  connect() {
    this.boundHandleKeydown = this.handleKeydown.bind(this)
    this.currentIndex = 0
  }

  disconnect() {
    this.close()
  }

  open(event) {
    event.preventDefault()

    const trigger = event.currentTarget
    this.currentIndex = Number.parseInt(trigger.dataset.screenshotLightboxIndex || "0", 10)
    this.renderCurrentImage()

    this.overlayTarget.classList.remove("hidden")
    document.body.classList.add("overflow-hidden")
    document.addEventListener("keydown", this.boundHandleKeydown)
  }

  next(event) {
    if (event) {
      event.preventDefault()
      event.stopPropagation()
    }

    this.currentIndex = (this.currentIndex + 1) % this.itemTargets.length
    this.renderCurrentImage()
  }

  previous(event) {
    if (event) {
      event.preventDefault()
      event.stopPropagation()
    }

    this.currentIndex = (this.currentIndex - 1 + this.itemTargets.length) % this.itemTargets.length
    this.renderCurrentImage()
  }

  close() {
    if (!this.hasOverlayTarget || this.overlayTarget.classList.contains("hidden")) {
      return
    }

    this.overlayTarget.classList.add("hidden")
    this.imageTarget.removeAttribute("src")
    this.imageTarget.alt = ""
    this.captionTarget.textContent = ""
    document.body.classList.remove("overflow-hidden")
    document.removeEventListener("keydown", this.boundHandleKeydown)
  }

  closeIfBackdrop(event) {
    if (event.target === this.overlayTarget) {
      this.close()
    }
  }

  handleKeydown(event) {
    if (event.key === "Escape") {
      this.close()
    } else if (event.key === "ArrowRight") {
      this.next()
    } else if (event.key === "ArrowLeft") {
      this.previous()
    }
  }

  renderCurrentImage() {
    const currentItem = this.itemTargets[this.currentIndex]
    if (!currentItem) {
      return
    }

    const imageUrl = currentItem.dataset.screenshotLightboxUrl
    const imageAlt = currentItem.dataset.screenshotLightboxAlt || ""

    this.imageTarget.src = imageUrl
    this.imageTarget.alt = imageAlt
    this.captionTarget.textContent = imageAlt
  }
}
