let User = {
  userId: null,
  currentUserId: null,
  utils: null,
  init(utils, element) {
    if (!element) { return }
    this.userId = element.getAttribute("data-id")
    this.currentUserId = document.getElementById("currentUser").getAttribute("id")
    if (this.userId === this.currentUserId) { return }
    this.utils = utils
  },


  upload_url(upload, size) {
    if (upload == null)
      return "https://img.shuttertop.com/no_image/user.png"
    else {
      switch (size) {
        case 'normal':
          size = "";
          break;
        case 'thumb':
          size = "300s300/";
          break;
        case 'thumb_small':
          size = "70s70/";
          break;
        default:
          size = "";
      }
      return `https://img.shuttertop.com/${size}${upload}`
    }
  }

}

export default User;