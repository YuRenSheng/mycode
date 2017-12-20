$(function () {
    // 模塊初始化；
    APP.safe.init();
});

(function (L) {
    var _this = null;

    L.safe = L.safe || {};
    _this = L.safe = {

      data: {flag:{ //isUserRulePass:false,//用戶檢查是否通過
                      //isExistUserName:false,//是否存在用戶名
                      isPwdRulePass:false,//是否符合密碼規則
                      isPwdDoubleCheckPass: false,//檢查重複密碼
                      //isExistEmpNo:false,//檢查是否存在部門
                      //isExistUserByEmpNo:false,//檢查用戶所屬部門
                      //isEmailRulePass:false,//檢查郵箱規則是否通過
                      //新密碼是否符合規則
                      //重複輸入是否正確
                    },
               pwdLevel:0,
               username:null,
               password:null,
               empNo:null,
               email:null,
               re:{
                    //userRule: /[\w\u4e00-\u9fa5]{3,20}/i,
                    userRule: /[a-z0-9A-Z_]{3,20}/i,
                     pwdRule: /^[a-zA-Z]+[a-z0-9A-Z\W]{5,49}.*$/,
                    emailRule:/^([a-z0-9_\.-]+\@[\da-z\.-]+\.[a-z\.]{2,6})$/,
               },
               msg:{userRule:"支持字母、數字、_的組合，3-20個字符",
                    userRule1:"該用戶名不符合規則",
                    userExists:"用戶名已存在，請重新輸入",
                    pwdRule1:"密碼必須輸入6-50個以字母開頭任意字串",
                    pwdRule2:"密碼輸入不一致，請重新輸入",
                   emailRule:"郵箱格式不正確，請重新輸入",
                   },
               delay_exec:null,
             },

      init: function () {
        _this.buttomChange();
        //修改密碼
        _this.openModel('update_code','model-dialog');
        _this.closeModel('safe-model-close','model-dialog');
        _this.closeModel('safe-cancel','model-dialog');
        //修改郵箱
        _this.openModel('update_mail','model-dialog-mail');
        _this.closeModel('safe-model-close','model-dialog-mail');
        _this.closeModel('safe-cancel','model-dialog-mail');
        _this.initPwdEvent();
        _this.sure();
        _this.enterDown();
        },

        //圖片鼠標移動樣式
        buttomChange:function(){
          $('.safe-bottom').mousemove(function(event) {
            $(this).addClass('safe-bottom-c');
          });
          $('.safe-bottom').mouseout(function(event) {
            $('.safe-bottom').removeClass('safe-bottom-c');
          });
        },
        // 打开模态框
        openModel:function(updateId,dialog){
          $('#'+updateId).click(function(){
            _this.modelBody(dialog);
            _this.modelShadow();

          });

        },

        //模態框身體(無高度,需要的話可以自己加)
        modelBody:function(dialog){
          $('.safe-sure').attr("disabled","disabled");
          $('.safe-sure').css({"background-color":"#dddddd"});
          var oldWidth = $('body').outerWidth();
          var marginLeft = (document.documentElement.clientWidth - $("."+dialog).outerWidth())/2-160;
          var marginHeight = (document.documentElement.clientHeight - $("."+dialog).outerHeight())/2-60;
          $('.'+dialog).css('margin-left',marginLeft);
          $('.'+dialog).css('margin-top',marginHeight);
          $('body').css('overflow','hidden');
          var newWidth = $('body').outerWidth();
          var scrollbarWidth = newWidth-oldWidth;
          $('body').css('padding-right',scrollbarWidth+'px');
          $('.'+dialog).removeClass('hide');
        },

        //模態透明背景
        modelShadow:function(){
          $('.model').removeClass('hide');
        },


        //点击蒙版关闭模态框
        closeModel:function(classid,dialog){
          $('.'+classid).click(function(){
            $('body').css('overflow','auto');
            $('body').css('padding-right','0px');
            $('.model').addClass('hide');
            $('.'+dialog).addClass('hide');
            $("input[type=reset]").trigger("click");
            $('.msg').css('visibility','hidden');
            $('.strength').css('visibility','hidden');
          });
        },

        //設置彈出消息
        makeMessageText: function(position) {
            var input = $("#"+position);
            var msg_id=position+"_msg";
            var msg=$("#"+msg_id);

            var isExist = ($("#"+msg_id).length > 0);

            if (!isExist)
            {
                $("<span id='"+msg_id+"' class='msg'><i class='infoTip'></i>"+_this.data.msg.userRule+"</span>").insertAfter(input);
                var msgoffsetTop = input[0].offsetTop+10;
                msg = $("#"+msg_id);
                msg.css( { "top":msgoffsetTop+"px",
                    "visibility":"hidden"});
            }

            return msg;
        },

        //設置消息文字
        setMessageText: function(position,status,text) {
            var input = $("#"+position);
            var msg_id=position+"_msg";
            var msg=$("#"+msg_id);
            var isExist = ($("#"+msg_id).length > 0);
            if (!isExist)
            {
                msg = _this.makeMessageText(position);
            }

            if(status)
            {
                msg[0].innerHTML="<i class='okTip' style='margin-left:10px'></i>";
            }
            else
            {
                msg[0].innerHTML="<i class='errorTip' style='margin-left:10px'></i>"+text+"";
            };
        },

        //秀出消息
        showMessage: function(position,isDisplay){
            var input = $("#"+position);
            var msg_id=position+"_msg";
            var msg=$("#"+msg_id);
            var visibility = isDisplay?"visible":"hidden";
            msg.css({"visibility":visibility});
        },

              //檢查密碼格式
              checkPwdRule: function(s) {
                  var s=s[0].value;

                  var isPwdMatch=_this.data.re.pwdRule.test(s);//正則表達式檢查
                           if (isPwdMatch) {
                               _this.data.flag.isPwdRulePass=true;
                               _this.data.password= s;
                               _this.setMessageText('input_pwd',true,'');
                           }
                           else  {
                               _this.data.flag.isPwdRulePass=false;
                               _this.setMessageText('input_pwd',false,_this.data.msg.pwdRule1)
                           };
                  if (s=="") {_this.showMessage('input_pwd',false)}
                  else {_this.showMessage('input_pwd',true)}
                  console.log(isPwdMatch);
                  return isPwdMatch;
              },

              //秀出密碼等級顏色
              showPwdLevel: function(level) {
                  var pwd=$("#input_pwd")[0].value;
                  var pwdLevel=new Array();
                  pwdLevel[0]=document.getElementById("enough-one");
                  pwdLevel[1]=document.getElementById("enough-two");
                  pwdLevel[2]=document.getElementById("enough-three");
                  pwdLevel[3]=document.getElementById("middle-one");
                  pwdLevel[4]=document.getElementById("middle-two");
                  pwdLevel[5]=document.getElementById("middle-three");
                  pwdLevel[6]=document.getElementById("strong-one");
                  pwdLevel[7]=document.getElementById("strong-two");
                  pwdLevel[8]=document.getElementById("strong-three");
                  var strength=document.getElementsByClassName("strength")[0];
                  var enough_clr = "#f4533b";
                  var middle_clr = "#f7b422";
                  var strong_clr = "#56bd5b";
                  var tran_clr = "#fff";
                  var curr_clr;
                  if (level> 0 && level<=3) curr_clr = enough_clr;
                  if (level> 3 && level<=6) curr_clr = middle_clr;
                  if (level> 6 && level<=9) curr_clr = strong_clr;
                  if (pwd=="") {strength.style.visibility ="hidden";}
                  for(var idx=0;idx<level;idx++)
                  {
                      strength.style.visibility ="visible";
                      pwdLevel[idx].style.backgroundColor = curr_clr;
                  };
                  for(var idx=level;idx<9;idx++)
                  {
                      pwdLevel[idx].style.backgroundColor = tran_clr;
                  }
              },

              showCleanButton:function(position,isDisplay) {
                  var input = $("#"+position);
                  var clsbtn_id = position+"_clear_btn";
                  var clsbtn = $("#"+clsbtn_id);
                  var visibility = isDisplay?"visible":"hidden";
                  clsbtn.css({"visibility":visibility});
              },

              //檢查所有消息
              checkAllRule: function() {
                var inputPwd=$("#input_pwd");
                var inputRePwd=$("#check_pwd");
                  var flag = _this.data.flag;
                  var loginBtn=$('#code_sure');
                  if (   //flag.isUserRulePass
                      //&& flag.isExistUserName
                      flag.isPwdRulePass
                      && flag.isPwdDoubleCheckPass
                      && inputRePwd[0].value!=""
                      && inputPwd[0].value!=""
                      // && flag.isExistEmpNo
                      // && flag.isEmailRulePass
                  ) {
                      loginBtn[0].removeAttribute("disabled");
                      loginBtn.css({"background-color":"#1d82d2"});
                  }
                  else {
                      loginBtn.attr("disabled","disabled");
                      loginBtn.css({"background-color":"#dddddd"});
                  };
              },

              //密碼等級判定
              checkPwdLevel: function(s) {
                  var s= s[0].value;
                  if(s.length < 6){return 0;}
                  var ls = 0;
                  if(s.match(/([a-z])+/)){
                              ls++;
                          }
                  if(s.match(/([0-9])+/)){
                              ls++;
                          }
                  if(s.match(/([A-Z])+/)){
                              ls++;
                          }
                  if(s.match(/[^a-zA-Z0-9]+/)){
                              ls++;
                          }
                  if(s.match(/[^a-zA-Z0-9]+.*/)){
                      ls++;
                  }
                  if (s.length > 10) {
                              ls++;
                          }
                  if (s.length > 15) {
                      ls++;
                  }
                  if (s.length > 24) {
                              ls++;
                          }
                  if (s.length > 40) {
                      ls++;
                  }
                  return ls;
                      },

                      //密碼處理
                      initPwdEvent:function() {
                          var inputPwd=$("#input_pwd");
                          var inputRePwd=$("#check_pwd");
                          inputPwd.keyup(function(){
                              //1.檢查密碼是否符合規則
                              console.log(inputPwd);
                              if(_this.checkPwdRule(inputPwd))
                              {
                                  _this.showPwdLevel(_this.checkPwdLevel(inputPwd));
                                  inputRePwd[0].removeAttribute("disabled");

                                  var newpwd=inputRePwd[0].value;
                                  var oldpwd=inputPwd[0].value;
                                  if(newpwd.length>0) {
                                      _this.checkRePwd(oldpwd, newpwd);
                                  }
                              }else {
                                inputRePwd.attr("disabled","disable");
                                  _this.showPwdLevel(0);
                              }
                              //2.根據檢查結果改變提示信息的狀態和文本內容及顏色
                              //3.根據輸入的文本長度，動態生成或取消清除文本的按鈕
                              _this.showCleanButton("input_pwd",true);
                              //4.根據密碼等級，顯示密碼等級提示
                              _this.checkAllRule();
                          });

                          var inputChkPwd=$("#check_pwd");
                          inputChkPwd.keyup(function(){
                              //1.檢查當前輸入的與第一次輸入的密碼是否一致
                              var oldpwd=inputPwd[0].value;
                              var newpwd=inputRePwd[0].value;
                              _this.checkRePwd(oldpwd,newpwd);
                              _this.checkAllRule();


                          });

                        },
                          checkRePwd:function(old_pwd,new_pwd) {
                              var isSame=old_pwd==new_pwd;
                              _this.data.flag.isPwdDoubleCheckPass=isSame;
                              _this.setMessageText('check_pwd',isSame,isSame?_this.data.msg.pwdRule2:'');
                              _this.showMessage('check_pwd',true);
                              console.log(_this.data.flag.isPwdDoubleCheckPass);
                              return isSame;
                          },

            //確定按鈕然後提交表單
            formSubmit:function(){
              var inputOldPwd=$("#old_pwd");
              var inputPwd=$("#input_pwd");

              var old_paswd=inputOldPwd[0].value; //舊密碼
              var new_pwd=inputPwd[0].value;      //新密碼

              var jsonData = {
                "action":"change_psw",
                "data":{
                    "old_psw":old_paswd,
                    "new_psw":new_pwd
                      }
          }
          console.log(jsonData.data.old_psw)
          console.log(jsonData.data.new_psw)

          jsonData = JSON.stringify(jsonData);
          $.ajax({
            url: 'http://10.132.241.214:8888/setup/security',
            type: 'POST',
            contentType:'application/json',
            dataType: 'json',
            data: jsonData,
            success:function(data){
              if(data.rv==200){
                // alert('修改成功');
                window.location.href = "http://10.132.241.214:8888/auth/logout";//  退出系統
              }else{
                  alert('修改失敗');
                    }
            }
          })
            },

            //回車事件
            enterDown:function(event){
              var event=event || window.event;
              var e=document.getElementById("code_sure");
              if (event.keyCode==13) {
                  e.click();
              }
            },

            //確認修改密碼
            sure:function(){
              $("#code_sure").click(function(event) {

                // $('#code_sure').removeAttr('disabled');
                _this.formSubmit();
                _this.closeModel('safe-model-close','model-dialog');
                _this.closeModel('safe-cancel','model-dialog');

              });
            },
      }
  }(APP));
