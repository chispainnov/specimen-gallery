import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "canvas", "previewArea", "controls",
    "zoomSlider", "zoomValue",
    "loader", "errorMsg", "usedFlag"
  ]

  static values = {
    url: String
  }

  previewImage = null
  zoom = 100
  trimBounds = null
  active = false

  connect() {
    this.boundHandleSubmit = this.handleSubmit.bind(this)
    this.element.addEventListener("submit", this.boundHandleSubmit)
  }

  disconnect() {
    this.element.removeEventListener("submit", this.boundHandleSubmit)
  }

  async requestPreview() {
    const fileInput = this.element.querySelector('[data-image-upload-target="fileInput"]')
    const bgCheckbox = this.element.querySelector('[data-image-upload-target="removeBackground"]')

    if (!fileInput?.files[0] || !bgCheckbox?.checked) {
      this.hidePreview()
      return
    }

    this.showLoader()

    const formData = new FormData()
    formData.append("image", fileInput.files[0])

    try {
      const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
      const response = await fetch(this.urlValue, {
        method: "POST",
        body: formData,
        headers: csrfToken ? { "X-CSRF-Token": csrfToken } : {}
      })

      const data = await response.json()

      if (!response.ok) {
        this.showError(data.error || "Preview failed")
        return
      }

      await this.loadPreviewImage(data.preview_url)
      this.showPreview()
    } catch (err) {
      this.showError("Could not generate preview. You can still submit — background removal will run on submit.")
    } finally {
      this.hideLoader()
    }
  }

  loadPreviewImage(url) {
    return new Promise((resolve, reject) => {
      const img = new Image()
      img.crossOrigin = "anonymous"
      img.onload = () => {
        this.previewImage = img
        this.zoom = 100
        this.trimBounds = null
        this.resetSliders()
        this.redrawCanvas()
        resolve()
      }
      img.onerror = () => reject(new Error("Failed to load preview image"))
      img.src = url
    })
  }

  redrawCanvas() {
    if (!this.previewImage || !this.hasCanvasTarget) return

    const canvas = this.canvasTarget
    const ctx = canvas.getContext("2d")
    const img = this.previewImage

    const bounds = this.trimBounds || { x: 0, y: 0, w: img.width, h: img.height }

    // Fixed square canvas based on the longest edge of the source image
    const frameSize = Math.max(img.width, img.height)
    canvas.width = frameSize
    canvas.height = frameSize

    // Scale the specimen within the fixed frame
    const scale = this.zoom / 100
    const drawW = Math.round(bounds.w * scale)
    const drawH = Math.round(bounds.h * scale)
    const drawX = Math.round((frameSize - drawW) / 2)
    const drawY = Math.round((frameSize - drawH) / 2)

    ctx.clearRect(0, 0, frameSize, frameSize)
    ctx.drawImage(img, bounds.x, bounds.y, bounds.w, bounds.h, drawX, drawY, drawW, drawH)

    this.active = true
    this.element.dataset.bgPreviewActive = "true"
    if (this.hasUsedFlagTarget) this.usedFlagTarget.value = "1"
  }

  adjustZoom(event) {
    this.zoom = parseInt(event.target.value, 10)
    if (this.hasZoomValueTarget) this.zoomValueTarget.textContent = `${this.zoom}%`
    this.redrawCanvas()
  }

  autoTrim() {
    if (!this.previewImage) return

    const offscreen = document.createElement("canvas")
    offscreen.width = this.previewImage.width
    offscreen.height = this.previewImage.height
    const ctx = offscreen.getContext("2d")
    ctx.drawImage(this.previewImage, 0, 0)

    const imageData = ctx.getImageData(0, 0, offscreen.width, offscreen.height)
    const { data, width, height } = imageData

    let minX = width, minY = height, maxX = 0, maxY = 0

    for (let y = 0; y < height; y++) {
      for (let x = 0; x < width; x++) {
        const alpha = data[(y * width + x) * 4 + 3]
        if (alpha > 10) {
          if (x < minX) minX = x
          if (x > maxX) maxX = x
          if (y < minY) minY = y
          if (y > maxY) maxY = y
        }
      }
    }

    if (maxX >= minX && maxY >= minY) {
      const pad = Math.max(8, Math.round(Math.max(maxX - minX, maxY - minY) * 0.03))
      this.trimBounds = {
        x: Math.max(0, minX - pad),
        y: Math.max(0, minY - pad),
        w: Math.min(this.previewImage.width, (maxX - minX) + pad * 2),
        h: Math.min(this.previewImage.height, (maxY - minY) + pad * 2)
      }
      this.redrawCanvas()
    }
  }

  resetEdits() {
    this.zoom = 100
    this.trimBounds = null
    this.resetSliders()
    this.redrawCanvas()
  }

  resetSliders() {
    if (this.hasZoomSliderTarget) this.zoomSliderTarget.value = 100
    if (this.hasZoomValueTarget) this.zoomValueTarget.textContent = "100%"
  }

  hidePreview() {
    this.active = false
    this.previewImage = null
    this.element.dataset.bgPreviewActive = "false"
    if (this.hasUsedFlagTarget) this.usedFlagTarget.value = "0"
    if (this.hasPreviewAreaTarget) this.previewAreaTarget.classList.add("hidden")
  }

  showPreview() {
    if (this.hasPreviewAreaTarget) this.previewAreaTarget.classList.remove("hidden")
    if (this.hasErrorMsgTarget) this.errorMsgTarget.classList.add("hidden")
  }

  showLoader() {
    if (this.hasLoaderTarget) this.loaderTarget.classList.remove("hidden")
    if (this.hasPreviewAreaTarget) this.previewAreaTarget.classList.add("hidden")
    if (this.hasErrorMsgTarget) this.errorMsgTarget.classList.add("hidden")
  }

  hideLoader() {
    if (this.hasLoaderTarget) this.loaderTarget.classList.add("hidden")
  }

  showError(message) {
    if (this.hasErrorMsgTarget) {
      this.errorMsgTarget.textContent = message
      this.errorMsgTarget.classList.remove("hidden")
    }
    this.hideLoader()
    if (this.hasPreviewAreaTarget) this.previewAreaTarget.classList.add("hidden")
  }

  handleSubmit(_event) {
    if (!this.active || !this.hasCanvasTarget) return

    const dataUrl = this.canvasTarget.toDataURL("image/png")
    const blob = this.dataUrlToBlob(dataUrl)
    const file = new File([blob], "specimen_cutout.png", { type: "image/png", lastModified: Date.now() })

    const dt = new DataTransfer()
    dt.items.add(file)

    const fileInput = this.element.querySelector('[data-image-upload-target="fileInput"]')
    if (fileInput) fileInput.files = dt.files
  }

  dataUrlToBlob(dataUrl) {
    const parts = dataUrl.split(",")
    const mime = parts[0].match(/:(.*?);/)[1]
    const bstr = atob(parts[1])
    const arr = new Uint8Array(bstr.length)
    for (let i = 0; i < bstr.length; i++) arr[i] = bstr.charCodeAt(i)
    return new Blob([arr], { type: mime })
  }
}
