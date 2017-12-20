// $(function () {
//     // 模塊初始化；
//     APP.detection.init();
// });
// $(function(){
//   APP.detection.init();
// })
function load()
{
APP.detection.init();
}
(function (L) {
    var _this = null;
    L.detection = L.detection || {};
    _this = L.detection = {

      init: function () {
        //_this.getBrowserInfo();
        _this.showVersion();
        },

        getBrowserInfo:function ()
        {

        var agent = navigator.userAgent.toLowerCase() ;

        var regStr_ie = /msie [\d.]+;/gi ;
        var regStr_ff = /firefox\/[\d.]+/gi
        var regStr_chrome = /chrome\/[\d.]+/gi ;
        var regStr_saf = /safari\/[\d.]+/gi ;
        //IE
        if(agent.indexOf("msie") > 0)
        {
            alert("IE")
        return agent.match(regStr_ie) ;
        }

        //firefox
        if(agent.indexOf("firefox") > 0)
        {
          alert("火狐")

        return agent.match(regStr_ff) ;
        }

        //Safari
        if(agent.indexOf("safari") > 0 && agent.indexOf("chrome") < 0)
        {
        return agent.match(regStr_saf) ;
        }

        //Chrome
        if(agent.indexOf("chrome") > 0)
        {
          // alert("谷歌")
        return agent.match(regStr_chrome) ;

        }

      },
        showVersion:function(){
          //瀏覽器
          var browser = _this.getBrowserInfo() ;
          //alert(browser);
          //版本
          var verinfo = (browser+"").replace(/[^0-9.]/ig,"");
          //alert(verinfo);
        },

        //圖片改變
        changeImage:function(){
          document.getElementById("detection_copy").src="../static/image/detection_selected.png";
        },
        backImage:function(){
          document.getElementById("detection_copy").src="../static/image/detection_normal.png";
        },

        //複製路徑
        copyPath:function(){
          var url = document.URL;
          document.getElementById('123').value = url;
          document.getElementById('123').select();
          document.execCommand("Copy");


          alert("已經複製到粘貼板");
          // txt = "<p>浏览器代码名: " + navigator.appCodeName + "</p>";
          // txt+= "<p>浏览器名称: " + navigator.appName + "</p>";
          // txt+= "<p>浏览器平台和版本: " + navigator.appVersion + "</p>";
          // txt+= "<p>是否开启cookie: " + navigator.cookieEnabled + "</p>";
          // txt+= "<p>操作系统平台: " + navigator.platform + "</p>";
          // txt+= "<p>User-agent头部值: " + navigator.userAgent + "</p>";
          // document.getElementById("example").innerHTML=txt;
        },

        browserDown:function(name){
          //操作系統
          var platformName = navigator.platform;
          var reg = /\s/ig;
          var platformName = platformName.replace(reg,"").toLowerCase();

          switch (name) {
            case "chrome":

            //判斷是不是linux
            if(platformName.indexOf("linux") >= 0)
            {
              // alert("linux");
              if (platformName.indexOf("32") >=0) {
                // alert("32");
                alert("沒找到符合此系統的安裝包文件！")

                //document.getElementById("chrome").setAttribute("href","");
              }else if (platformName.indexOf("64") >=0) {
                // alert("64");
                alert("正在下載安裝包文件！")
                document.getElementById("chrome").setAttribute("href","../static/downloads/browser/chrome/chrome_linux64.deb");
              }
            }

            //判斷是不是window
            if(platformName.indexOf("win") >= 0)
            {
              // alert("win");
              if (platformName.indexOf("32") >=0) {
                // alert("32");
                alert("正在下載安裝包文件！")
                document.getElementById("chrome").setAttribute("href","../static/downloads/browser/chrome/chrome_win32.exe");
              }else if (platformName.indexOf("64") >=0) {
                // alert("64");
                alert("正在下載安裝包文件！")
                document.getElementById("chrome").setAttribute("href","../static/downloads/browser/chrome/chrome_win64.exe");
              }
            }
              break;

            case "firefox":
            if(platformName.indexOf("linux") >= 0)
            {
              // alert("linux");
              if (platformName.indexOf("32") >=0) {
                // alert("32");
                alert("正在下載安裝包文件！")
                document.getElementById("firefox").setAttribute("href","../static/downloads/browser/firefox/firefox_linux32.tar.bz2");
              }else if (platformName.indexOf("64") >=0) {
                // alert("64");
                alert("正在下載安裝包文件！")
                document.getElementById("firefox").setAttribute("href","../static/downloads/browser/firefox/firefox_linux64.tar.bz2");
              }
            }

            if(platformName.indexOf("win") >= 0)
            {
              // alert("win");
              if (platformName.indexOf("32") >=0) {
                // alert("32");
                alert("正在下載安裝包文件！")
                document.getElementById("firefox").setAttribute("href","../static/downloads/browser/firefox/firefox_win32.exe");
              }else if (platformName.indexOf("64") >=0) {
                // alert("64");
                alert("正在下載安裝包文件！")
                document.getElementById("firefox").setAttribute("href","../static/downloads/browser/firefox/firefox_win64.exe");
              }
            }

              break;

            case "ie":
            if(platformName.indexOf("linux") >= 0)
            {
              // alert("linux");
              if (platformName.indexOf("32") >=0) {
                // alert("32");
                alert("沒找到符合此系統的安裝包文件！")
                // document.getElementById("ie").setAttribute("href","../static/downloads/browser/ie/ie_win32.exe");
              }else if (platformName.indexOf("64") >=0) {
                // alert("64");
                alert("沒找到符合此系統的安裝包文件！")
                // document.getElementById("ie").setAttribute("href","../static/downloads/browser/ie/ie_win64.exe");
              }
            }

            if(platformName.indexOf("win") >= 0)
            {
              // alert("win");
              if (platformName.indexOf("32") >=0) {
                // alert("32");
                alert("正在下載安裝包文件！")
                document.getElementById("ie").setAttribute("href","../static/downloads/browser/ie/ie_win32.exe");
              }else if (platformName.indexOf("64") >=0) {
                // alert("64");
                alert("正在下載安裝包文件！")
                  document.getElementById("ie").setAttribute("href","../static/downloads/browser/ie/ie_win64.exe");
              }
            }

                break;
            default:

          }

        },

    }
}(APP));
