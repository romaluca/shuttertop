
export var UploadUtils = {
  resize: function (file, options, callback) {
    options.maxWidth = options.width;
    options.maxHeight = options.height;
    options.crop = options.cropSquare;
    options.canvas = true;

    var fileData = {
      name: file.name,
      size: file.size,
      type: file.type,
      data: null
    };

    // Get image metadata.
    loadImage.parseMetaData(file, function (data) {
      var orientation = 1;
      if (data.exif) {
        orientation = data.exif.get('Orientation');
        if (orientation) {
          options.orientation = orientation;
        }
      }

      loadImage(file, function (canvas) {
        var resize_dataUrl = canvas.toDataURL(fileData.type);

        var binaryImg = atob(resize_dataUrl.slice(resize_dataUrl.indexOf('base64') + 7, resize_dataUrl.length));
        var length = binaryImg.length;
        var ab = new ArrayBuffer(length);
        var ua = new Uint8Array(ab);
        for (var i = 0; i < length; i++) {
          ua[i] = binaryImg.charCodeAt(i);
        }

        fileData.data = new Blob([ua], { type: file.type, name: file.name });

        //fileData.data.type = file.type;

        fileData.size = ua.length;

        const fileResized =  Object.assign(fileData.data,
          { name: fileData.name, width: canvas.width, height: canvas.height },
          data.exif ? data.exif.getAll() : {}
        )
        callback(null, fileResized);
      }, options);

    }, { maxMetaDataSize: 262144, disableImageHead: false });
  },
  S3: function (entries, onViewError) {
    entries.forEach(entry => {
      UploadUtils.resize(entry.file, {
        width: 1600,
        height: 1200,
        //cropSquare: size.crop
      }, function (err, fileResized) {
        if (err) {
          console.log("resize error :( ", err);
        } else {

          const formId = entry.fileEl.form.id;
          console.log("resized :)", formId);
          const exif = {
            width: fileResized.width || null,
            height: fileResized.height || null,
            meta: {
              model: fileResized.Model || null,
              make: fileResized.Make || null,
              f_number: fileResized.Exif.FNumber || null,
              photographic_sensitivity: fileResized.Exif.PhotographicSensitivity || null,
              exposure_time: fileResized.Exif.ExposureTime || null,
              focal_length: fileResized.Exif.FocalLength || null,
              lat: fileResized.GPSLatitude || null,
              lng: fileResized.GPSLongitude || null
            }
          }
          const metaField = document.getElementById(formId + "_meta")
          if (metaField) {
            entry.meta.exif = JSON.stringify(exif)
            console.log('metafieldsss', entry.meta)

            metaField.value = JSON.stringify(exif)
            metaField.dispatchEvent(new Event("input", {bubbles: true}))
          }
         UploadUtils.upload(entry, fileResized, onViewError)
        }
      })
    })
  },
  upload: function (entry, fileResized, onViewError) {
    let formData = new FormData()
    let { url, fields } = entry.meta
    Object.entries(fields).forEach(([key, val]) => formData.append(key, val))
    formData.append("file", fileResized)
    let xhr = new XMLHttpRequest()
    onViewError(() => xhr.abort())
    xhr.onload = () => {
      if (xhr.status === 204) {
        entry.progress(100)
        const formId = entry.fileEl.form.id
        const form = document.getElementById(formId)
        form.dispatchEvent(new Event("submit", {bubbles: true}))
      }
      else entry.error()
    }
    xhr.onerror = () => entry.error()
    xhr.upload.addEventListener("progress", (event) => {
      if (event.lengthComputable) {
        let percent = Math.round((event.loaded / event.total) * 100)
        if (percent < 100) { entry.progress(percent) }
      }
    })
    xhr.open("POST", url, true)
    xhr.send(formData)
  }
}
