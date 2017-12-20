/**
 * Created by Amanda Tung on 2017/5/11.
 */

var client = function(){
//呈现引擎
  var engine = {
    ie     : 0,
    gecko  : 0,
    webkit : 0,
    khtml  : 0,
    opera  : 0,
    //完整的版本号
    ver    : null
  };

//浏览器
  var browser = {
//主要浏览器
    ie	    : 0,
    firefox : 0,
    konq    : 0,
    opera   : 0,
    chrome  : 0,
    safari  : 0,

    //具体的版本号
    ver     : null
  };

//平台、设备和操作系统
  var system ={
    win : false,
    mac : false,
    xll : false,

    //移动设备
    iphone    : false,
    ipod      : false,
    nokiaN    : false,
    winMobile : false,
    macMobile : false,

    //游戏设备
    wii : false,
    ps  : false
  };
//检测呈现引擎和浏览器
  var	ua = navigator.userAgent;
  if (window.opera){
    engine.ver = browser.ver = window.opera.version();
    engine.opera = browser.opera = parseFloat(engine.ver);
  } else if (/AppleWebKit\/(\S+)/.test(ua)){
    engine.ver = RegExp["$1"];
    engine.webkit = parseFloat(engine.ver);

    //确定是Chrome还是Safari
    if (/Chrome\/(\S+)/.test(ua)){
      browser.ver = RegExp["$1"];
      browser.chrome = parseFloat(browser.ver);
    } else if (/Version\/(\S+)/.test(ua)){
      browser.ver = RegExp["$1"];
      browser.safari = parseFloat(browser.ver);
    } else {
      //近似地确定版本号
      var safariVersion = 1;
      if(engine.webkit < 100){
        safariVersion = 1;
      } else if (engine.webkit < 312){
        safariVersion = 1.2;
      } else if (engine.webkit < 412){
        safariVersion = 1.3;
      } else {
        safariVersion = 2;
      }
      browser.safari = browser.ver = safariVersion;
    }
  } else if (/KHTML\/(\S+)/.test(ua) || /Konquersor\/([^;]+)/.test(ua)){
    engine.ver = browser.ver = RegExp["$1"];
    engine.khtml = browser.kong = paresFloat(engine.ver);
  } else if (/rv:([^\)]+)\) Gecko\/\d{8}/.test(ua)){
    engine.ver = RegExp["$1"]
    engine.gecko = parseFloat(engine.ver);
    //确定是不是Firefox
    if (/Firefox\/(\S+)/.test(ua)){
      browser.ver = RegExp["$1"];
      browser.firefox = pareseFloat(browser.ver);
    }
  } else if(/MSIE([^;]+)/.test(ua)){
    browser.ver = RegExp["$1"];
    browser.firefox = parseFloat(browser.ver);
  }
//检测浏览器
  browser.ie = engine.ie;
  browser.opera = engine.opera;
//检测平台
  var p = navigator.platform;
  system.win = p.indexOf("Win") == 0;
  system.mac = p.indexOf("Mac") == 0;
  system.x11 = (p == "X11") || (p.indexOf("Linux") == 0);
//检测Windows操作系统
  if (system.win){
    if (/Win(?:doms)?([^do]{2})\s?(\d+\.\d+)?/.test(ua)){
      if (RegExp["$1"] == "NT"){
        switch(RegExp["$2"]){
          case "5.0":
            system.win = "2000";
            break;
          case "5.1":
            system.win = "XP";
            break;
          case "6.0":
            system.win = "Vista";
            break;
          default   :
            system.win = "NT";
            break;
        }
      } else if (RegExp["$1"]){
        system.win = "ME";
      } else {
        system.win = RegExp["$1"];
      }
    }
  }
//移动设备
  system.iphone	 = ua.indexOf("iPhone") > -1;
  system.ipod	     = ua.indexOf("iPod") > -1;
  system.nokiaN	 = ua.indexOf("NokiaN") > -1;
  system.winMobile = (system.win == "CE");
  system.macMobile = (system.iphone || system.ipod);
//游戏系统
  system.wii = ua.indexOf("Wii") > -1;
  system.ps  = /playstation/i.test(ua);
//返回这些对象
  return {
    engine:  engine,
    browser:  browser,
    system:  system
  };
}();


// getOS = function() {
// //获取用户代理
//   var ua = navigator.userAgent;
//   if (ua.indexOf("Windows NT 5.1") != -1) return "Windows XP";
//   if (ua.indexOf("Windows NT 6.0") != -1) return "Windows Vista";
//   if (ua.indexOf("Windows NT 6.1") != -1) return "Windows 7";
//   if (ua.indexOf("iPhone") != -1) return "iPhone";
//   if (ua.indexOf("iPad") != -1) return "iPad";
//   if (ua.indexOf("Linux") != -1) {
//     var index = ua.indexOf("Android");
//     if (index != -1) {
// //os以及版本
//       var os = ua.slice(index, index+13);
//
// //手机型号
//       var index2 = ua.indexOf("Build");
//       var type = ua.slice(index1+1, index2);
//       return type + os;
//     } else {
//       return "Linux";
//     }
//   }
//
//   return "未知操作系统";
// }
//
// alert('Your OS: '+ getOS());
//
//
// function getCPU()
//
// {
//
//   var agent=navigator.userAgent.toLowerCase();
//
//   if(agent.indexOf("win64")>=0||agent.indexOf("wow64")>=0) return "x64";
//
//   return navigator.cpuClass;
//
// }
// console.log(getCPU());
