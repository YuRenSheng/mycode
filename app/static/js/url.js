/**
 * Created by Amanda Tung on 2017/6/13.
 */

var APP= APP || {};
APP.namespace= function (str) {
  var arr = str.split('.'), o = APP;
  for ( var i = (arr[0]=='Global') ? 1 : 0; i<arr.length; i++){
    o[arr[i]] = [arr[i]]||{};
    o = o[arr[i]];
  }
};

APP.namespace('APP.URL');
APP.namespace('APP.URL.application');
APP.namespace('APP.URL.sign');
APP.URL = {
  //root:'http://127.0.0.1:8888',
  root:'http://10.132.241.215:8888',
   // test:'simulation_employee_no=F2828635',
  // root:'http://10.132.212.236:8888',
  // root:'http://10.132.212.114:8888',

  getUrl: function( str ) {
   return APP.URL.root + eval('APP.URL.'+str);
  }
};

APP.namespace('APP.URL.Layout');
APP.namespace('APP.URL.Home');
APP.URL.Layout = {
  building: '/layout?src=building',
  floor: '/layout?src=floor&building=',
  layout: '/layout',
  dept:'/layout?src=dept&no=',
  deptFindRelevantPoint:'/layout/position?src=pos&dept_id=',
  pointFindRelevantDept:'/layout/position?src=dept&pos_id=',
  exchangeData:'/layout/position',
  upload:'/layout/file',
  endUpload:'/layout/place'
};
APP.URL.Home = {
  totalResource:'/stat?src=total_staff&dim=day&begin_time=',
  newResource:'/stat?src=new&dim=day&begin_time=',
  loseResource:'/stat?src=wastage&dim=',
  attendanceRate:'/stat?src=att_rate&dim=day&begin_time=',
  directIndirect:'/stat?src=direct_indirect_manpower&&dim=day&begin_time='
};
APP.URL.application = {
  documentType: '/approval/request?src=type',
  auditorType: '/approval/request?src=approval_activity',
  auditorInformation:'/approval/request?src=approval_person&emp_no=',
  upload:'/approval/request/upload',
  keep:'/approval/request',
  deleteDocument:'/approval/request',
  costCode:'/employee/dept_name?dept_code=',
  applicant:'/employee/'
};

APP.URL.sign = {
  allData:'/approval/list/detail?src=task&form_id=',
  rejectPath:'/approval?src=reject&form_id=',
  approval:'/approval'
};
APP.URL.database = {
  searchUserInformation:'/approval/basicinfo?src=query_info&emp_no=',
  addUserInformation:'/approval/basicinfo'
};
APP.URL.todo = {
    modalRemote:'/approval/',
    tableData:'/approval/list?src=todo',
    typeName:'/approval/list?src=type'
};
APP.URL.finish = {
    tableData:'/approval/list?src=finish'
};
APP.URL.myList = {
    tableData:'/approval/list?src=my'
};
