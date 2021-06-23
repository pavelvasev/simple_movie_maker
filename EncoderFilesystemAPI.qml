// https://web.dev/file-system-access/
Column {
    id: enc
    //    anchors.fill: parent
    //    color: "grey"
    spacing: 5
    
    Button {
      text: "Select target dir"
      width: 200
      onClicked: setdir()
    }
    
    Text {
      text: realdhandle ? "Dir selected" : "Dir not selected"
    }
    
    Text {
      text: "current_i="+current_i
    }
    
    property var dhandle
    property var realdhandle    
    
    onDhandleChanged: {
      console.log("dh changed",dhandle );
      realdhandle = null
      if (dhandle)
      dhandle.then( function(arg) {
        console.log("rdh resolved",arg);
        realdhandle=arg;
      });
    }
    

    
    function setdir() {
      dhandle = window.showDirectoryPicker();
      dhandle.then( function(arg) {
        verifyPermission( arg, true );
      });
    }
    
    // https://developer.mozilla.org/en-US/docs/Web/API/FileSystemHandle/requestPermission
    function verifyPermission(fileHandle, withWrite) {
      const opts = {};
      if (withWrite) {
        opts.mode = 'readwrite';
      }
      
      fileHandle.requestPermission(opts).then( function(resp) {
        console.log("reqPerm resp=",resp );
      });
/*      
    

      // Check if we already have permission, if so, return true.
      if (await fileHandle.queryPermission(opts) === 'granted') {
        return true;
      }

  // Request permission to the file, if the user grants permission, return true.
  if (await fileHandle.requestPermission(opts) === 'granted') {
    return true;
  }

  // The user did not grant permission, return false.
  return false;
*/  
      }

    function getImagePngBlob(img,cb) {
        if (img.naturalWidth == 0) {
          console.error("warning, img nat width = 0!");
          debugger;
        }
        // Create an empty canvas element
        var canvas = document.createElement("canvas");
        canvas.width = img.naturalWidth;
        canvas.height = img.naturalHeight;

        // Copy the image contents to the canvas
        var ctx = canvas.getContext("2d");
        ctx.drawImage(img, 0, 0);

        // Get the data-URL formatted image
        // Firefox supports PNG and JPEG. You could check img.src to
        // guess the original format, but be aware the using "image/jpg"
        // will re-encode the image.
        dataURL = canvas.toBlob(cb); //"image/png");
    }

    function pad(num, size) {
        var s = num+"";
        while (s.length < size) s = "0" + s;
        return s;
    }

    function generate(start_i) {
        //console.
        
        if (!dhandle) return; //setdir();
        
        dhandle.then( function(realdhandle) {
          var images=[];
          var total = imagesCount;
          for (var i=0;i<total; i++) {
              var img = getImageObject( i );
              images.push(img);
          }
          imagesCount = 0;
          saverec( start_i || 0, images, realdhandle );
        });
      

    } // generate func
    
    function saverec( i, images, realdhandle ) {
      if (images.length == 0) return;
      
      var img = images[0];
      var padding = 5;
      var fname = "image-"+pad(i,padding)+".png";
      getImagePngBlob( img, function(blob) {
          console.log("writing file",fname,"with blob",blob );
          writefile( realdhandle, fname, blob, function() {
            saverec( i+1,images.slice(1), realdhandle );
          } );
      });
    }
    
    function writefile( realdhandle, fname, blob,cb ) {
            var fh = realdhandle.getFileHandle( fname, { create: true });
            fh.then( function(realfh) {
                const writable = realfh.createWritable();
                
                writable.then( function(realwritable) { 
                  // Write the contents of the file to the stream.
                  realwritable.write(blob);
                  
                  
                  // bug: https://bugs.chromium.org/p/chromium/issues/detail?id=1132506
//                  realwritable.closed.catch(function(){});
//                  realwritable.releaseLock();
                  
                  // Close the file and write the contents to disk.
                  realwritable.close();
                  cb();
                }); // writeable
            }); // fh
    }
    
    //// котовасия на тему сохранения по мере поступления
    property var current_i: 0
    //property var ic: imagesCount
    //property var rtime: resetTime
    //onIcChanged: generate( current_i )
    //onRtimeChanged: restart()
    
    function imageAdded(img) {
      if (!realdhandle) return;
      saverec( current_i, [img], realdhandle );
      current_i = current_i + 1;
      imagesCount =0;
    }
    
    function restart() {
      current_i = 0;
      dhandle = null;
    }

}