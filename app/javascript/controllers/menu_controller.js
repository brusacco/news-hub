import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["mobileMenu", "openIcon", "closeIcon"];

  connect() {
    this.isOpen = false;
  }

  toggle() {
    this.isOpen = !this.isOpen;
    
    // Toggle mobile menu visibility
    this.mobileMenuTarget.classList.toggle("hidden", !this.isOpen);
    
    // Toggle icons
    this.openIconTarget.classList.toggle("hidden", this.isOpen);
    this.openIconTarget.classList.toggle("block", !this.isOpen);
    this.closeIconTarget.classList.toggle("hidden", !this.isOpen);
    this.closeIconTarget.classList.toggle("block", this.isOpen);
  }
}