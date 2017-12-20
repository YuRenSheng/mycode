1.待办 /已办  get  /approval/list


1.  req   src=todo
    req   src=done&begin_time=xxx&end_time=xxx
    req   src=done&begin_time=xxx&end_time=xxx&form_code=xxx 2017-10-17 08:00:00
     req   src=done&form_code=xxx
    req   src=my&begin_time=xxx&end_time=xxx  我的单

res   {rv = 200,msg= success,data=data}


1.代办 /已办明细申请单明细 get  /approval/list/detail

1.req  src=task&form_id=xxx

res  {rv = 200,msg= success,data=data}

1.申请页面   /approval/request

get

1.单据 /

req   src=type
res   {rv = 200,msg= success,data=data}

2. 费用代码 /

req  src=dept&dept_code=xxx
res   {rv = 200,msg= success,data=data}

3. 申请人 /

req  src=request&emp_no=xxx
res   {rv = 200,msg= success,data=data}

4. 签核人 /

req  src=approval_person&emp_no=xxx
res   {rv = 200,msg= success,data=data}


post

5.uploader uploader

req  file
res  {rv = 200,msg= success,data=data}

6. 暂存 /

req  {act=pre_add,data=xxx}
res   {rv = 200,msg= success,data=data}

7. 提交

req  {act=add,data=xxx}
res   {rv = 200,msg= success,data=data}

{
    "act": "pre_add",
    "data": {
        "id": "",
        "code": "",
        "typeid": "1",
        "dept_code": "中国",
        "dept_name": "中国",
        "applicant_no": "中国",
        "applicant_phone": "中国",
        "applicant_email": "中国",
        "subject": "中国",
        "reason": "中国",
        "approval_flow": [
            {
                "emp_no": "F2828635",
                "dept_name": "系统开发课",
                "order_item": 1,
                "approval_activity_id": 1
            },
            {
                "emp_no": "F2828635",
                "dept_name": "系统开发课",
                "order_item": 1,
                "approval_activity_id": 1
            }
        ],
        "files": [
            {
                "filename": "3.5.1.拍照完成.jpg",
                "disk_filename": "46825293-04b4-40d8-aa2e-44a07eb7dc12.jpg",
                "filesize": 355046,
                "content_type": "jpg"
            },
            {
                "filename": "3.5.1.拍照完成.jpg",
                "disk_filename": "46825293-04b4-40d8-aa2e-44a07eb7dc12.jpg",
                "filesize": 355046,
                "content_type": "jpg"
            }
        ]
    }
}

8  改

req  {act=upd,data=xxx}
res   {rv = 200,msg= success,data=data}

9  删

req  {act=del,data=xxx}
res   {rv = 200,msg= success,data=data}


1. 签核页面   /approval

get

1. req  src=reject&form_id=xxx
   res   {rv = 200,msg= success,data=data}

post

1. req   {src=confirm,data={ret=0,reason(拒绝理由)=xxx,des(退件去向)=xxx}}
   res   {rv = 200,msg= success,data=data}

1.基础资料维护

get

1. req  src=reject&form_id=xxx
   res   {rv = 200,msg= success,data=data}


post  自动建账号
