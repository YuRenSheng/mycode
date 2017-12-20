/**
 * Created by gyq on 2017/6/20.
 */
var APP =APP||{};

(function (L) {
    var _this = null;
    L.Utils = L.Utils || {};
    _this = L.Utils = {
        data: {},
        init: function () {
        },
        //自動居中元素（el=element）
        autoCenterAlign: function (el){
            el.style.visibility="visible";
            var bodyW=document.documentElement.clientWidth;
            var bodyH=document.documentElement.clientHeight;
            var elW=el.offsetWidth;
            var elH=el.offsetHeight;
            el.style.left=(bodyW-elW)/2+"px";
            el.style.top=(bodyH-elH) / 2+"px";
        },
        getElement: function (id){
            return document.getElementById(id)
        },
        makeCleanButton: function(position,func) {

            var input = $("#"+position);
            var clsbtn_id = position+"_clear_btn";
            var clsbtn = $("#"+clsbtn_id);

            if($("#"+clsbtn_id).length ==0)
            {
                $("<span id='"+clsbtn_id+"' class='clear_btn'></span>").insertAfter(input);
                var clearbtnoffsetTop=input[0].offsetTop+12;
                //console.log(clearbtnoffsetTop);
                clsbtn = $("#"+clsbtn_id);
                clsbtn.css( { "top":clearbtnoffsetTop+"px",
                    "visibility":"hidden"});
            }

            clsbtn.bind("click",null,function() {

                input.focus().select();
                input[0].value="";
                input.keyup();
                clsbtn.css({"visibility":"hidden"});
                //_this.showMessage(position,false);
                func();
            });
        },
        showCleanButton:function(position,isDisplay) {
            var input = $("#"+position);
            var clsbtn_id = position+"_clear_btn";
            var clsbtn = $("#"+clsbtn_id);
            var visibility = isDisplay?"visible":"hidden";
            clsbtn.css({"visibility":visibility});
        },

    }
})(APP);
