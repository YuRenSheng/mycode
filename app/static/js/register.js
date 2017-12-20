/**
 * Created by gyq on 2017/6/9.
 */
 jQuery(function(){
  APP.Regiser.init();
});
(function (L) {
    var _this = null;
    L.Regiser = L.Regiser || {};
    _this = L.Regiser = {
        // data: {flag:{ isUserRulePass:false,//用戶檢查是否通過
        //               isExistUserName:false,
        //               isPwdRulePass:false,
        //               isPwdDoubleCheckPass: false,
        //               isExistEmpNo:false,
        //               isExistUserByEmpNo:false,
        //               isEmailRulePass:false,
        //             },
        //        pwdLevel:0,
        //        username:null,
        //        password:null,
        //        empNo:null,
        //        email:null,
        //        re:{
        //             //userRule: /[\w\u4e00-\u9fa5]{3,20}/i,
        //             userRule: /[a-z0-9A-Z_]{3,20}/i,
        //              pwdRule: /^[a-zA-Z]+[a-z0-9A-Z\W]{5,49}.*$/,
        //             emailRule:/^([a-z0-9_\.-]+\@[\da-z\.-]+\.[a-z\.]{2,6})$/,
        //        },
        //        msg:{userRule:"支持字母、數字、_的組合，3-20個字符",
        //             userRule1:"該用戶名不符合規則",
        //             userExists:"用戶名已存在，請重新輸入",
        //             pwdRule1:"密碼必須輸入6-50個以字母開頭任意字串",
        //             pwdRule2:"密碼輸入不一致，請重新輸入",
        //            emailRule:"郵箱格式不正確，請重新輸入",
        //            },
        //        delay_exec:null,
        //       },
        init:function(){
            _this.initEvents();
        },
        initEvents:function() {
            _this.initUserNameEvent();
            _this.initPwdEvent();
            _this.initEmpNoEvent();
            _this.initEmailEvent();
            _this.initLoginEvent();
        },
        initUserNameEvent:function() {
            var inputUser=$("#input_user");
            inputUser.keyup(function(){
                //1.根據輸入的文本長度，動態生成或取消清除文本的按鈕
                _this.showCleanButton("input_user",true);
                //2.檢查用戶名是否符合規則
                if(_this.checkUserRule(inputUser))
                {
                    clearTimeout(_this.data.delay_exec);
                    _this.data.delay_exec = setTimeout(function(){_this.isExistsUser('input_user');},500);
                }
                _this.checkAllRule();
            });

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
                }else {inputRePwd.attr("disabled","disable");
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
        initEmpNoEvent:function() {
            var inputEmpNo=$("#input_employ");
            inputEmpNo.keyup(function(){
                //1.檢查工號是否存在，并檢查工號是否有綁定用戶
                //_this.isExistsEmpNo("input_employ");
                clearTimeout(_this.data.delay_exec);
                _this.data.delay_exec = setTimeout(function(){_this.isExistsEmpNo('input_employ')},500);
                //2.根據檢查結果改變提示信息的狀態和文本內容及顏色
                //3.根據輸入的文本長度，動態生成或取消清除文本的按鈕
                //console.log(_this.data.employ);
                _this.showCleanButton("input_employ",true);
                _this.checkAllRule();
            });
        },
        initEmailEvent:function() {
            var inputEmail=$("#input_email");
            inputEmail.keyup(function(){
                _this.checkEmailRule(inputEmail);
                _this.checkAllRule();
            })
        },
        initLoginEvent:function() {
            //console.log(_this.data.username,_this.data.password,_this.data.employ,_this.data.email);
            var loginBtn=$('#sign');
            loginBtn.bind("click",null,function(){
                _this.execRegister(_this.data.username,_this.data.password,_this.data.employ,_this.data.email);
            })

        },
        checkAllRule: function() {
            var flag = _this.data.flag;
            var loginBtn=$('#sign');
            if (   flag.isUserRulePass
                && flag.isExistUserName
                && flag.isPwdRulePass
                && flag.isPwdDoubleCheckPass
                && flag.isExistEmpNo
                && flag.isEmailRulePass
            ) {
                loginBtn[0].removeAttribute("disabled");
                loginBtn.css({"background-color":"#2875ff"});
            }
            else {
                loginBtn.attr("disabled","disabled");
                loginBtn.css({"background-color":"#999999"});
            };
        },
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

        //檢查密碼格式
        checkPwdRule: function(s) {
            var s=s[0].value;
            console.log(s);
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

        checkRePwd:function(old_pwd,new_pwd) {
            var isSame=old_pwd==new_pwd;
            _this.data.flag.isPwdDoubleCheckPass=isSame;
            _this.setMessageText('check_pwd',isSame,isSame?_this.data.msg.pwdRule2:'');
            _this.showMessage('check_pwd',true);
            return isSame;
        },

        checkUserRule: function(s) {
            var s= s[0].value;
            var isMatch=_this.data.re.userRule.test(s);
            //根據檢查結果改變提示信息的狀態和文本內容及顏色
            if (isMatch)  {
              _this.data.flag.isUserRulePass=true;
              _this.data.username= s;
              _this.setMessageText('input_user',true,'');
            }
            else  {
              _this.data.flag.isUserRulePass=false;
              _this.setMessageText('input_user',false,_this.data.msg.userRule)
            };
            if (s=="") {_this.showMessage('input_user',false)}
            else {_this.showMessage('input_user',true)}
            return isMatch;
        },
        checkEmailRule:function(s){
            var s= s[0].value;
            var isEmailMatch=_this.data.re.emailRule.test(s);
            _this.data.flag.isEmailRulePass=isEmailMatch;

            if (isEmailMatch) {
                _this.setMessageText('input_email',true,'');
                _this.data.email=s;
            } else
            {
                _this.setMessageText('input_email',false,_this.data.msg.emailRule);
                _this.data.email=null;
            }
            if (s=="") {_this.showMessage('input_email',false)}
            else {_this.showMessage('input_email',true)};
        },
        //通過ajax方法
        isExistsUser: function (s) {
            var s=$("#"+s)[0].value;
            //console.log(s);
            $.ajax({
                type:'GET',
                url:'/auth/check',
                data:{src:"username",no:s},
                success:function(json){
                    var data_msg=json.msg;
                    var data_rv=json.rv;
                    //console.log(data_msg,data_rv);
                    _this.data.flag.isExistUserName = (data_rv == 200);
                    _this.setMessageText("input_user", _this.data.flag.isExistUserName, data_msg);
                },
            })
        },
        //通過ajax方法
        isExistsEmpNo:function (s) {
            var s=$("#"+s)[0].value;
            $.ajax({
                type:'GET',
                url:'/auth/check',
                data:{src:"employ",no:s},
                success:function(json){
                    var data_msg=json.msg;
                    var data_rv=json.rv;
                    //console.log(data_msg,data_rv);
                    _this.data.flag.isExistEmpNo =(data_rv==200);
                    _this.data.employ=_this.data.flag.isExistEmpNo?s:null;

                    _this.setMessageText("input_employ", _this.data.flag.isExistEmpNo, data_msg);
                    _this.showMessage("input_employ",_this.data.flag.isExistEmpNo);
                    _this.setEmployMessageText("input_employ",_this.data.flag.isExistEmpNo,data_msg);
                    _this.checkAllRule();
                },
            })
        },
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

        //秀出消息
        showMessage: function(position,isDisplay){
            var input = $("#"+position);
            var msg_id=position+"_msg";
            var msg=$("#"+msg_id);
            var visibility = isDisplay?"visible":"hidden";
            msg.css({"visibility":visibility});
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
                var msgoffsetTop = input[0].offsetTop+12;
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
                msg[0].innerHTML="<i class='okTip'></i>";
            }
            else
            {
                msg[0].innerHTML="<i class='errorTip'></i>"+text+"";
            };
        },
        makeEmployMessage: function(position) {
            var employ_input =$('#'+position);
            var employ_msg_id=position+"_employ_msg";
            var employ_msg=$('#'+employ_msg_id);
            if($("#"+employ_msg_id).length ==0)
            {
                $("<div id='"+employ_msg_id+"' class='employ_msg'></div>").insertAfter(employ_input);
                var employmsgoffsetTop=employ_input[0].offsetTop+46;
                employ_msg = $("#"+employ_msg_id);
                employ_msg.css( { "top":employmsgoffsetTop+"px",
                    "visibility":"visible"});
            }
        },
        setEmployMessageText:function(position,status,text) {
            var input=$("#"+position);
            var msg_id=position+"_employ_msg";
            var msg=$("#"+msg_id);
            var isExist = ($("#"+msg_id).length > 0);
            if (!isExist)
            {
                msg = _this.makeEmployMessage(position);
            }
            if (status) {
                msg.css({"color":"#999999"});
                //_this.data.employ=input[0].value;

                console.log(_this.data.employ);
                } else {
                msg.css({"color":"#f03838"})
            }
            msg[0].innerHTML=""+text+"";

        },

          showCleanButton:function(position,isDisplay) {
              var input = $("#"+position);
              var clsbtn_id = position+"_clear_btn";
              var clsbtn = $("#"+clsbtn_id);
              var visibility = isDisplay?"visible":"hidden";
              clsbtn.css({"visibility":visibility});
          },

        keyRegisterIn:function(event) {
            var event=event || window.event;
            var e=document.getElementById("sign");
            if (event.keyCode==13) {
                e.click();
            }
        },

        delayJump:function(url) {
            var delay = document.getElementById("time").innerHTML;//取到id="time"的对象，.innerHTML取到对象的值
            if(delay > 0) {
                delay--;
                console.log(document.getElementById("time"));
                document.getElementById("time").innerHTML = delay;
            } else {
                window.location.href = url;//跳转到URL
            }
            setTimeout("delayJump('" + url + "')", 3000);    //delayJump() 就是每间隔1000毫秒 调用delayJump(url);
        },
        execRegister: function(username,pwd,emp_no,email){
            $.ajax({
                type:'POST',
                url:'/auth/sign_up',
                data:{username:username,password:pwd,employ:emp_no,email:email},
                success:function(json){
                    var signFlag=(json.rv=200);
                    if (signFlag) {
                        //document.getElementById("sign-container").innerhtml="<h1>恭喜您，註冊成功！</h1><h1>页面<span id='time'>5</span>秒后，將自动跳转至登錄界面..</h1>"
                        window.location.href="/auth/success";
                        _this.delayJump('/');
                    } else {
                        setTimeout(alert("註冊失敗，請重新註冊"),1000);
                        window.location.href="register.html";
                    }
                },
            })},
    }
})(APP);
