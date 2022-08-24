// NOTE: The contents of this file will only be executed if
// you uncomment its entry in "web/static/js/app.js".

// To use Phoenix channels, the first step is to import Socket
// and connect at the socket path in "lib/my_app/endpoint.ex":
import autosize from "autosize"
import { Socket } from "phoenix"
import { LiveSocket } from "phoenix_live_view"
import * as Utils from './utils'
import Photo from "./photo"
import { UploadUtils } from "./uploadutils"
import Comment from "./comment"
import topbar from "topbar"

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")

let Hooks = {}
Hooks.Lazyload = {
  mounted() {
  },
  updated() {
  }
}
Hooks.CommentUpdate = {
  mounted() {
    Comment.mountedComment()
  },
  updated() {
    Comment.updateComment()
  }
}
Hooks.SlideUpdate = {
  mounted() {
    Photo.mountedSlide()
  },
  updated(hook) {
    Photo.updateSlide()
  }
}

Hooks.TopicsUpdate = {
  mounted() {
    if (!document.getElementById("commentsContainer"))
      this.pushEvent("show_topic", { "small_screen": window.innerWidth < Utils.ScreenSize.lg })
    Comment.mountedTopics()
  },
  updated(hook) {
    Comment.updateTopics()
  }
}
Hooks.GooglereCAPTCHA = {
  mounted() {
    console.log("GooglereCAPTCHA mount")
  },
  updated(hook) {
    console.log("GooglereCAPTCHA update")
    grecaptcha.reset()
  }
}
Hooks.PreventDefault = {
  mounted() {
    this.el.addEventListener("click", e => {
      e.preventDefault();
    })
  },
}
Hooks.VoteBtn = {
  mounted() {
    this.el.addEventListener("click", e => {
      e.preventDefault();
    })
  },
  updated() {
    let votes = this.el.getAttribute("data-votes")
    let position = this.el.getAttribute("data-position")
    let id = this.el.getAttribute("id")
    if (votes)
      document.querySelectorAll(`.votes.${id}`).forEach(i => i.innerText = votes)
    if (position)
      document.querySelectorAll(`.position.${id}`).forEach(i => i.innerText = position)
    let msg = this.el.getAttribute("error-msg")
    this.el.removeAttribute("error-msg")
    if (msg)
      Utils.renderAlert(msg, true);
  }
}
Hooks.PhotoForm = {
  updated() {
    document.getElementById("photo_name_label").innerText = document.getElementById("photo_name").value
    document.getElementsByClassName("photo-name")[0].classList.remove("edit")
  }
}


const liveSocket = new LiveSocket("/live", Socket, {
  uploaders: UploadUtils,
  params: { _csrf_token: csrfToken },
  hooks: Hooks
})

// Show progress bar on live navigation and form submits
topbar.config({
  barColors: {
    '0': "#4fcf70",
    '.25': '#fad648',
    '.50': '#a767e5',
    '.75': '#12bcfe',
    '1.0': '#44ce7b'
  }, shadowColor: "rgba(0, 0, 0, .3)"
})
window.addEventListener("phx:page-loading-start", info => topbar.show())
window.addEventListener("phx:page-loading-stop", info => {
  topbar.hide()
  autosize(document.querySelector('textarea'), ({ append: false }));
})


liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
//liveSocket.enableDebug()
//liveSocket.enableLatencySim(1000)
window.liveSocket = liveSocket
