$(function () {
    // 模塊初始化；
    APP.personal.init();
});

(function (L) {
    var _this = null;

    L.personal = L.personal || {};
    _this = L.personal = {

      data:{
        flag:{
          phoneNum:false, //手机
          lockNum:false,  //座机
          // checkSex:false, //性别
             },

          re:{
            phone:/^1\d{10}$/,
            lockphone:/^\d{5}$/,
          },

          msg:{
            phoneErr:"請輸入正確的手機號碼",
            lockNumErr:"請輸入正確格式的座机號碼",
            checkSexErr:"请选择性别",
          },
      },

      init: function () {
        _this.updatePhone();
        _this.clickSave();
        },

        //点击保存
        clickSave:function(){
          $('#preser').click(function(event) {
            _this.checkSave();
          });
          $(":radio").click(function(event) {
            _this.checkSex();
          });
        },

        //修改性別
        checkSexf:function(){
          //获取性别
          var val=$('input:radio[name="sex"]:checked').val();
          if(val!=null){
            // _this.data.flag.checkSex=true;
            $("#preser").addClass('per-sub-chg');
            $("#preser").removeAttr('disabled');
            console.log("lockNum");
          }
        },

      //检查保存条件
      checkSave:function(){


          var flag = _this.data.flag;

          // console.log("checkSex"+flag.checkSex);
          console.log("lockNum"+flag.lockNum);
          console.log("phoneNum"+flag.phoneNum);

          if(
              // flag.checkSex
            flag.lockNum
            &&flag.phoneNum
          ){
            //提交表单
            console.log("提交保单");
          }

        console.log("保存成功");
      },

      //更改資料保存按鈕啓動
      updatePhone:function(){
        //手机
        $('#userPhone').keyup(function(event) {

          $("#preser").addClass('per-sub-chg');
          $("#preser").removeAttr('disabled');
          _this.checkPhone("userPhone","hand_phone",_this.data.re.phone);

        });

        //座机
        $('#userLockPhone').keyup(function(event) {

          $("#preser").addClass('per-sub-chg');
          $("#preser").removeAttr('disabled');
          _this.checkLockPhone("userLockPhone","lock_phone",_this.data.re.lockphone,_this.data.flag.lockNum);

        });


      },

      //驗證座机號碼
      checkLockPhone:function(phoneId,phone,regular){
        var uphone = $('#'+phoneId)[0].value;

        _this.data.flag.lockNum = regular.test(uphone);
        console.log(_this.data.flag.lockNum)
        if(_this.data.flag.lockNum){
          $('#'+phone).removeClass('icon-no');
          $('#'+phone).addClass('icon-greenyes');
        }else{
          $('#'+phone).removeClass('icon-greenyes');
          $('#'+phone).addClass('icon-no');
        }
      },

      //驗證手机號碼
      checkPhone:function(phoneId,phone,regular){
        var uphone = $('#'+phoneId)[0].value;

        _this.data.flag.phoneNum = regular.test(uphone);
        console.log(_this.data.flag.phoneNum)
        if(_this.data.flag.phoneNum){
          $('#'+phone).removeClass('icon-no');
          $('#'+phone).addClass('icon-greenyes');
        }else{
          $('#'+phone).removeClass('icon-greenyes');
          $('#'+phone).addClass('icon-no');
        }
      },


      }
  }(APP));
