
$(function(){
  APP.indexfirest.init();
});

(function(L){
  var _this = null;
  L.indexfirest = L.indexfirest || {};
  _this = L.indexfirest = {
    init:function(){
      _this.shadow();
      _this.headFont();
      _this.bottomChange();
    },

    //头部文字鼠标移动样式改变
    headFont:function(){
      $('.head-font-box').mousemove(function(event) {
        $(this).addClass('head-box-bl');
        $(this).children().addClass('head-font-bl');
      });
      $('.head-font-box').mouseout(function(event) {
        $(this).removeClass('head-box-bl');
        $(this).children().removeClass('head-font-bl');
      });
    },

    //鼠标移动按鈕样式改变
    bottomChange:function(){
      $('.content-phone-bt').mousemove(function(event) {
        $(this).addClass('content-phone-bt-bl');
      });
      $('.content-phone-bt').mouseout(function(event) {
        $('.content-phone-bt').removeClass('content-phone-bt-bl');
      });
    },
    //鼠标移动阴影添加
    shadow:function(){
      $('.content-product').mousemove(function(event) {
        $(this).addClass('por-shadow');
        $(this).stop().animate({marginTop:"0px"},50);
      });
      $('.content-product').mouseout(function(event) {
        $('.content-product').removeClass('por-shadow');
        $(this).stop().animate({marginTop:"5px"},50);
      });
    }

  }

}(APP));
