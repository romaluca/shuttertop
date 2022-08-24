import * as Utils from './utils'
window.touchstartX = 0;
window.touchstartY = 0;
window.touchendX = 0;
window.touchendY = 0;
window.minSwipe = 100;
let Photo = {
  checkPageButtons() {
    const xs = 575;
    if (window.innerWidth < xs)
      return;
    const gallery = document.getElementById("gallery")
    const prevPage = document.getElementById("prev-page")
    const nextPage = document.getElementById("next-page")
    if (window.galleryTranslate == 0)
      prevPage.classList.remove("visible")
    else
      prevPage.classList.add("visible")
    const ele = document.getElementById(document.getElementById("gallery-content").lastElementChild.id);
    const max = ele.offsetLeft + ele.offsetWidth;
    if ((window.galleryTranslate - gallery.offsetWidth) * -1 >= max)
      nextPage.classList.remove("visible")
    else
      nextPage.classList.add("visible")
  },
  getNextPage() {
    const container = document.getElementById('gallery')
    const content = document.getElementById('gallery-content')
    const ele = document.getElementById(content.lastElementChild.id);
    const max = ele.offsetLeft + ele.offsetWidth;
    if ((window.galleryTranslate - container.offsetWidth) * -1 < max) {
      window.galleryTranslate -= container.offsetWidth;
      content.style.transform = "translateX(" + window.galleryTranslate + "px" + ")";

      const total_entries = content.getAttribute("data-entries")
      if ((window.galleryTranslate - container.offsetWidth) * -1 >= max && total_entries > content.childElementCount && !window.moreGallery) {
        window.moreGallery = true;
        content.lastElementChild.classList.add("loading")
        setTimeout(function () {
          document.getElementById('more-page').click()
        }, 300);
      }
    }
    Photo.checkPageButtons()

  },
  getPrevPage() {
    const gallery = document.getElementById('gallery')
    window.galleryTranslate += gallery.offsetWidth
    if (window.galleryTranslate > 0)
      window.galleryTranslate = 0
    const content = document.getElementById('gallery-content')
    content.style.transform = "translateX(" + window.galleryTranslate + "px" + ")"
    Photo.checkPageButtons()
  },
  mountedSlide() {
    const xs = 575;
    if (window.innerWidth < xs) {
      const gallery = document.getElementById("gallery")
      gallery.onscroll = function () {
        if (gallery.scrollLeft + gallery.offsetWidth >= gallery.scrollWidth - 1) {
          window.moreGallery = true
          document.getElementById('more-page').click()
        }
      }
      Photo.checkSliderNav()
    }
    Photo.updateSlide()
  },
  updateSlide() {
    const gallery = document.getElementById("gallery")
    const content = document.getElementById("gallery-content")
    const photoId = document.getElementsByClassName("photo_page")[0].getAttribute("data-id")
    const photo = document.getElementById("gallery-photo-" + photoId)
    const selected = content.getElementsByClassName("selected")
    if (selected.length > 0)
      selected[0].classList.remove("selected")
    if (photo)
      photo.classList.add("selected")
    content.style.transition = "none"
    content.style.transform = "translateX(" + window.galleryTranslate + "px)"
    setTimeout(function () {
      if (!window.moreGallery && photo) {
        window.galleryTranslate = (photo.offsetLeft - (gallery.offsetWidth / 2) + (photo.offsetWidth / 2)) * -1
        if (window.galleryTranslate > 0) window.galleryTranslate = 0
        content.style.transform = "translateX(" + window.galleryTranslate + "px)"
        content.style.transition = null
        Photo.checkPageButtons()
      } else {
        window.moreGallery = false
        content.style.transition = null
        Photo.checkPageButtons()
      }
    }, 100)
  },
  upload_url(upload, size) {
    switch (size) {
      case 'normal':
        size = "";
        break;
      case 'medium':
        size = "960x960/";
      case 'thumb':
        size = "500s500/";
        break;
      case 'thumb_small':
        size = "260s270/";
        break;
      default:
        size = "";
    }
    return `https://img.shuttertop.com/${size}${upload}`
  },
  checkSliderNav() {
    let slidernav = document.getElementById("slidernav")
    if (slidernav != null) {
      if (window.slidernavListener) return;
      window.slidernavListener = true;
      slidernav.addEventListener('touchstart', function (event) {
        window.touchstartX = event.changedTouches[0].screenX;
        window.touchstartY = event.changedTouches[0].screenY;
      }, false);

      slidernav.addEventListener('touchend', function (event) {
        window.touchendX = event.changedTouches[0].screenX
        window.touchendY = event.changedTouches[0].screenY
        if (window.touchendX + window.minSwipe < window.touchstartX) {
          event.preventDefault()
          slidernav.getElementsByClassName("next")[0].click()
        }
        if (window.touchendX > window.touchstartX + window.minSwipe) {
          event.preventDefault()
          slidernav.getElementsByClassName("prev")[0].click()
        }
      }, false);
    }
  }

};

export default Photo;
