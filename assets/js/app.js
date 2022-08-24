/*global grecaptcha*/
/*global Image*/
import "bootstrap"
import moment from "moment"
import "moment/locale/it"
import * as Utils from './utils'
import "phoenix_html"
import "./socket"


//import loadImage from 'loadImage'
window.loadImage = module.export = require('../node_modules/blueimp-load-image/js/load-image')
require('../node_modules/blueimp-load-image/js/load-image-scale')
require('../node_modules/blueimp-load-image/js/load-image-meta')
require('../node_modules/blueimp-load-image/js/load-image-fetch')
require('../node_modules/blueimp-load-image/js/load-image-exif')
require('../node_modules/blueimp-load-image/js/load-image-exif-map')
require('../node_modules/blueimp-load-image/js/load-image-orientation')


import Photo from "./photo"
import CurrentUser from "./user"
import User from "./user"

window.loadApple = function (e) {
  e.preventDefault()
  var script = document.createElement('script')
  script.onload = function () {
    Utils.onLoadedAppleID()
  };
  script.src = 'https://appleid.cdn-apple.com/appleauth/static/jsapi/appleid/1/en_US/appleid.auth.js'
  document.head.appendChild(script)
}


Utils.checkBackButton()

const rightBarContent = document.getElementsByClassName("right-bar-content")
if (rightBarContent.length > 0) {
  const rightBar = rightBarContent[0]
  let top = rightBar.offsetHeight - window.innerHeight + 50
  top = top < 0 ? 100 : (top * -1)
  rightBar.style.top = top + 'px'
}



if (!document.getElementById("currentUser")) {
  const uploads = document.getElementsByClassName("check-user")
  Array.from(uploads).forEach((upload) => {
    upload.addEventListener("click", function (e) {
      e.preventDefault();
      document.getElementById("loginBtn").click()
    })
  })
}

var getTimeRemaining = function () {
  var elements = document.getElementsByClassName("time-left");
  var i;
  for (i = 0; i < elements.length; i++) {
    const ele = elements[i]

    var endtime = ele.getAttribute("data-time");
    var t = Date.parse(endtime) - Date.parse(new Date());
    var seconds = Math.floor((t / 1000) % 60);
    var minutes = Math.floor((t / 1000 / 60) % 60);
    var hours = Math.floor((t / (1000 * 60 * 60)) % 24);
    var days = Math.floor((t / (1000 * 60 * 60 * 24)));
    if (t > 0) {
      if (days == 1)
        ele.innerText = Utils.i18n.t("manca 1 giorno")
      else if (days > 1) {
        ele.innerText = Utils.i18n.t("mancano |n| giorni", { "n": days })
      } else {
        ele.innerText = Utils.i18n.t("mancano |ore|", {
          "ore":
            ("0" + hours).slice(-2) + ":" +
            ("0" + minutes).slice(-2) + ":" +
            ("0" + seconds).slice(-2)
        })
      }
    } else {
      if (days == -1) {
        ele.innerText = Utils.i18n.t("terminato 1 giorno fa")
      }
      else
        ele.innerText = Utils.i18n.t("terminato |n| giorni fa", { "n": days * -1 })
    }
  }
}

var utils = {
  handleLogout: (element) => {
    var to = element.getAttribute("data-to"),
      method = utils.buildHiddenInput("_method", element.getAttribute("data-method")),
      csrf = utils.buildHiddenInput("_csrf_token", element.getAttribute("data-csrf")),
      fcm_token = utils.buildHiddenInput("token", window.localStorage.notifyToken),
      form = document.createElement("form"),
      target = element.getAttribute("target");

    form.method = (element.getAttribute("data-method") === "get") ? "get" : "post";
    form.action = to;
    form.style.display = "hidden";

    if (target) form.target = target;

    form.appendChild(csrf);
    form.appendChild(method);
    form.appendChild(fcm_token);
    document.body.appendChild(form);
    form.submit();
  },
  buildHiddenInput: (name, value) => {
    var input = document.createElement("input");
    input.type = "hidden";
    input.name = name;
    input.value = value;
    return input;
  },
  sendToken: async () => {
    const response = await fetch("/api/devices", {
      method: 'POST',
      mode: 'cors',
      cache: 'no-cache',
      credentials: 'same-origin',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${Utils.guardianToken}`
      },
      redirect: 'follow',
      referrerPolicy: 'no-referrer',
      body: JSON.stringify({ device: { platform: "web", token: window.localStorage.notifyToken } })
    });
    if (response.status == 201) {
      response.json().then(body => console.log("api/devices", body))
      window.localStorage.notifyTokenSent = Date.now()
    } else {
      response.json().then(body => console.error("api/devices", body))
    }
  }
}



var init = function () {
  var app = null;
  if (window.firebase) {
    window.firebase.initializeApp({ messagingSenderId: "1023268944637" });
    window.messaging = window.firebase.messaging();
    window.messaging.requestPermission()
      .then(function () {
        if (Utils.guardianToken) {
          const notifyTokenSent = window.localStorage.notifyTokenSent ? +window.localStorage.notifyTokenSent : undefined;
          if (!window.localStorage.notifyToken) {
            window.messaging.getToken()
              .then(function (currentToken) {
                window.localStorage.notifyToken = currentToken;
                utils.sendToken();
              }).catch(function (err) {
                console.log('An error occurred while retrieving token. ', err);
              });
          } else if (!notifyTokenSent ||
            ((Date.now() - notifyTokenSent) / 3600000 > 1))
            utils.sendToken()
        }
      })
      .catch(function (err) {
        console.log('Unable to get permission to notify.', err);
      });
  }

  moment.locale(Utils.lang);

  document.querySelectorAll('form.dropdown-menu')
    .forEach(el => el.addEventListener('click', e => {
      e.stopPropagation();
    }));

  document.querySelectorAll('tr.inner-clickable')
    .forEach(el => el.addEventListener('click', e => {
      e.stopPropagation();
      window.location.href = $("a", el).attr("href");
    }));

  document.addEventListener('scroll', function () {
    const scroll = window.scrollY
    const ele = document.querySelector('tr.inner-clickable')
    if (!ele)
      return
    if (scroll > 0) {
      ele.classList.add('scrolled')
    }
    else {
      ele.classList.remove('scrolled')
    }
  });


  setInterval(getTimeRemaining, 1000);
  setInterval(function () {
    document.querySelectorAll('.created_at')
      .forEach(el =>
        el.innerText = moment(el.getAttribute("data-at")).fromNow()
      )
  }, 60000);

  window.addEventListener('phoenix.link.click', function (e) {
    e.stopPropagation();
    if (e.target.classList.contains("logout_btn")) {
      e.preventDefault()
      utils.handleLogout(e.target);
    }
  }, false);

  window.sharePopup = function (e, site, shareUrl) {
    e.preventDefault()
    let url = "";
    shareUrl = 'https://shuttertop.com' + shareUrl;
    switch (site) {
      case 'facebook':
        url = `https://www.facebook.com/dialog/share?app_id=436011423257505&display=page&href=${shareUrl}&redirect_uri=${shareUrl}`
        break;
      case 'whatsapp':
        url = `https://wa.me/?text=${shareUrl}`
        break;
      case 'twitter':
        url = `https://twitter.com/share?url=${shareUrl}`
        break;
      case 'mail':
        url = `mailto:?subject=shuttertop.com&body=${shareUrl}`
    }
    window.open(url, site + 'window', 'left=20,top=20,width=600,height=700,toolbar=0,resizable=1')
  }

  document.querySelectorAll('.contest-desc.mini')
    .forEach(el => el.addEventListener('click', e => {
      e.stopPropagation()
      e.preventDefault()
      e.target.classList.toggleClass('expanded')
    }))

  document.querySelectorAll('.edit-photo-name')
    .forEach(el => el.addEventListener('click', e => {
      e.target.classList.remove('view')
      e.target.classList.add('edit')
    }))

  document.querySelectorAll('.photo-comment-btn')
    .forEach(el => el.addEventListener('click', e => {
      e.preventDefault()
      document.getElementById('comment_body').focus()
    }))


  /*document.getElementById('modalDialog')?.addEventListener('shown.bs.modal', e => {
    const recaptcha = document.querySelector("#modalDialog .g-recaptcha")
    if (recaptcha) {
      recaptcha.setAttribute("id", "recaptchaModal")
      grecaptcha.render('recaptchaModal', { 'sitekey': '6LctTSwUAAAAAJLenqwb9FdfWWMpd6n4ovjAooqt' })
    }
    document.getElementById("redirectUrl").value = window.location.pathname
  })*/


  window.galleryTranslate = 0;

  document.getElementById('next-page')?.addEventListener('click', e => Photo.getNextPage)
  document.getElementById('prev-page')?.addEventListener('click', e => Photo.getPrevPage)

  User.init(utils, document.getElementById("user"), "#userPage")
  CurrentUser.init(utils, document.getElementById("currentUser"), ".activity")

  if (document.querySelector('.photo-winner:not(.winner-loaded)')) {
    document.querySelector('.photo-winner').classList.add("winner-loaded")
    window.addEventListener("resize", window.updateCanvas)
    var tmpImg = new Image()
    tmpImg.src = document.querySelector('.photo-winner .img-fluid').getAttribute('src')
    tmpImg.onload = window.updateCanvas
  }


  document.querySelectorAll("div.control-group").forEach(el => {
    el.addEventListener('focusout', e => {
      if (!e.target.classList.contains("error")) {
        return e.target.classList.add("success");
      }
    });
  })
  setTimeout(function () {
    //$(".alert-info").alert('close');
  }, 5000);

  if (!window.localStorage.getItem('hideAppBar')) {
    let appLink = null;
    let appStore = null;
    if (/(android)/i.test(navigator.userAgent)) {
      appLink = "https://play.google.com/store/apps/details?id=com.shuttertop.android";
      appStore = "Play Store";
    } else if (/iPad|iPhone|iPod/.test(navigator.userAgent)) {
      appLink = "https://apps.apple.com/it/app/shuttertop/id1409758044";
      appStore = "App Store";
    }
    if (appLink != null) {
      const htmlString = "<div class='get_app_container'><i class='icons close'></i>" +
        `<span class='me-auto'>${Utils.i18n.t("shuttertop_get_it")}${appStore}</span>` +
        `<a href='${appLink}'>${Utils.i18n.t("Scaricala")}</a></div>`
      var div = document.createElement('div');
      div.innerHTML = htmlString.trim();
      document.querySelector(".main-nav").parentNode.appendChild(div);
      document.querySelector(".get_app_container .close").addEventListener("click", e => {
        window.localStorage.setItem('hideAppBar', true);
        e.preventDefault();
        document.querySelector('.get_app_container').remove()
      });
    }
  }
}

init();
