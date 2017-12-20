return {
	-- 白名单配置：不需要登录即可访问；除非要二次开发，否则不应更改
	whitelist = {
		"^/m1",
		"^/m2",
		"^/test",
		"^/index$",
		"^/ask$",
		"^/share$",
		"^/category/[0-9]+$",
		"^/topics/all$",
		"^/topic/[0-9]+/view$",
		"^/topic/[0-9]+/query$",

		"^/comments/all$",

		"^/user/[0-9a-zA-Z-_]+/index$",
		"^/user/[0-9a-zA-z-_]+/topics$",
		"^/user/[0-9a-zA-z-_]+/collects$",
		"^/user/[0-9a-zA-z-_]+/comments$",
		"^/user/[0-9a-zA-z-_]+/follows$",
		"^/user/[0-9a-zA-z-_]+/fans$",
		"^/user/[0-9a-zA-z-_]+/hot_topics$",
		"^/user/[0-9a-zA-z-_]+/like_topics$",

		"^/app/v1/auth/token_refresh$",
		"^/app/v1/auth/refresh_token$",
		"^/app/v1/auth/logout$",
		"^/app/v1/auth/login$",

		--"^/approval/list$",
		"^/approval/list/detail$",
		--"^/approval/request$",
		"^/approval/request/upload$",
		"^/approval/uploader$",
		"^/approval/basicinfo$",


		"^/uploadtest$",

		"^/template$",
		"^/template/data_source$",
		"^/resetpw$",
		"^/resetpw/check$",
		"^/resetpw/verify$",
		"^/stat/total_staff$",
		"^/stat/manpower_change$",
		"^/stat/attendance_rate$",
		"^/stat/direct_indirect_manpower$",
		"^/stat/manpower_change_list$",
		"^/stat/dept$",
		"^/stat$",

		"^/organization$",
		"^/layout$",
		"^/layout/place$",
		"^/layout/position$",
		"^/layout/file$",
		"^/auth/check$",
		"^/auth/resetpw$",
		"^/auth/login$", -- login page
		"^/auth/sign_up$", -- sign up page
		"^/auth/logout$", -- logout page
		"^/auth/success$", -- sign up page
		"^/about$", -- about page
		"^/error/$" -- error page
	},

	-- 静态模板配置，保持默认不修改即可
	view_config = {
		engine = "tmpl",
		ext = "html",
		views = "./app/views"
	},

	-- 分页时每页条数配置
	page_config = {
		index_topic_page_size = 10, -- 首页每页文章数
		topic_comment_page_size = 20, -- 文章详情页每页评论数
		notification_page_size = 10, -- 通知每页个数
	},

	-- ########################## 以下配置需要使用者自定义为本地需要的配置 ########################## --

	advanced_filter={
		-- 时间颗粒度
		time_dimension = {
			day = "天",
			week = "周",
			month = "月",
			quarter = "季度",
			year = "年"
		},
		-- 条件范围
		condition_range = {
			eq = "等于",
			en = "不等于",
			ge = "大于等于",
			gt = "大于",
			le = "小于等于",
			lt = "小于"
		},
		-- 逻辑符号
		logical_symbol = {
			land = "与",
			lor = "或",
			lnot = "非",
			lno = "无"
		},
	},
	-- app访问超级token
	app_root_token = "2b5c2d36fc41358c299f9230d8a15e501b45f1b473c0cbacb54afa7bdc03e800",

	-- 邮件推送服务秘钥
	smtp_token = "25df2154fg105p356120wlks12542fv0",

	--重置密碼邮件链接redis有效时间key前缀
	resetpw_config = {
			key_prefix = "resetpw-",
			key_timeout = 900,
	},


	--验证码有效时间key前缀
	key_prefix_code = "change_email-",
	key_timeout_code = 900,

	-- 生成session的secret，请一定要修改此值为一复杂的字符串，用于加密session
	session_secret = "3584827dfed45b40328acb6242bdf13b",

	-- 用于存储密码的盐，请一定要修改此值, 一旦使用不能修改，用户也可自行实现其他密码方案
	pwd_secret = "salt_secret_for_password",

	-- 邮件推送附件使用叠加方式
	mail_attach_send = "concat",

	-- mysql配置
	mysql = {
		timeout = 5000,
		connect_config = {
			host = "10.132.241.214",
	        port = 3306,
	        database = "smartfactory",
	        user = "tom",
	        password = "Xx12`12`1`",
	        max_packet_size = 1024 * 1024
		},
		pool_config = {
			max_idle_timeout = 20000, -- 20s
        	pool_size = 50 -- connection pool size
		}
	},

	smtp_sv = {
		timeout = 5000,
		url = "http://10.132.241.214:6666/mail",
	},

	server_self = {
		url = "http://10.132.241.215:8888",
		--url = "http://10.132.212.236:8888",
	},

	redis = {

		timeout = 1000000,

		connect_config = {
			host = "127.0.0.1",
			port = 6379
		},
		pool_config = {
			max_idle_timeout = 20000, -- 20s
        	pool_size = 50 -- connection pool size
		}
	},

	websocket = {
		timeout = 10000,  -- in milliseconds
    	max_payload_len = 65535
    },

	-- 上传文件配置，如上传的头像、文章中的图片等
	upload_config = {
		dir = "/opt/vssas/app/static/images/layout", -- 文件目录，修改此值时须同时修改nginx配置文件中的$static_files_path值
	--	dir = "/home/miah/dev/vssas/app/static/images/layout",  --miah
		path = "/static/images/layout",
	},

	upload_files = {
		dir = "/opt/vssas/app/static/files", -- 文件目录，修改此值时须同时修改nginx配置文件中的$static_files_path值
	--	dir = "/home/miah/dev/vssas/app/static/images/layout",  --miah
		path = "/static/files",
	},


	attendance_upload_config = {
		dir = "/opt/vssas/app/static/images/attendance", -- 文件目录，修改此值时须同时修改nginx配置文件中的$static_files_path值
	--	dir = "/home/miah/dev/vssas/app/static/images/layout",  --miah
		path = "/static/images/attendance",
	},

	emp_photo_config = {
		dir = "/opt/vssas/app/static/images/emp_photo",  -- 前段上传路径
		path = "/static/images/emp_photo",  --
		default = "/static/images/photo.png",
	},

	local_emp_photo_config = {
		dir = "/opt/vssas/app/static/images/emp",
		path = "/static/images/emp"
	},

	logo_pdf_path = {
		dir = "/opt/vssas/app/static/images/logo.pdf"
	},

	menu = {
		group = {{id = "ssas03",
		           name = "概况" ,
		           icon = "icon-dashboard",
		           page = "welcome"
		         },
		        --[[
				 {id = "ssas01",
		           name = "基础信息",
		           icon = "icon-layout",
		           items ={{id = "ssas01-01",name = "部门分布",page = "org"},
		           		   {id = "ssas01-02",name = "组织架构",page = "dept"}}
		         },
				 {id = "ssas02",
		           name = "数据分析",
		           icon = "icon-dept",
		           items ={{id = "ssas02-01",name = "組織分布",page = "statBydept"},
		                   {id = "ssas02-02",name = "自定義報表"},
		                   {id = "ssas02-03",name = "周報"},
		                   {id = "ssas02-04",name = "月報"}
		                  }
		         },

		         {id = "ssas04",
		           name = "系統設置",
		           icon = "icon-system",
		           items ={{id = "ssas04-01",name = "報表模板管理"},
		                   {id = "ssas04-02",name = "數據查詢"},
		                   {id = "ssas04-03",name = "圖表報表"}}
		         },
				--]]
				 {id = "ssas01",
		           name = "智能考勤",
		           icon = "icon-dept",
		           items ={{id = "ssas01-01",name = "部门分布",page = "org"},
		           		   {id = "ssas01-02",name = "组织架构",page = "dept"},
		           		   {id = "ssas01-03",name = "組織分布",page = "statBydept"}
		           		  }
		         },
		         {id = "ssas02",
		           name = "电子签核",
		           icon = "icon-sign",
		           items ={{id = "ssas02-01",name = "新增申請",page = "req_form"},
		                   {id = "ssas02-02",name = "待辦任務",page = "todo"},
		                   {id = "ssas02-03",name = "已辦任務",page = "finish"},
		                   {id = "ssas02-04",name = "我的單",page = "my"},
		                   {id = "ssas02-05",name = "基礎資料維護",page ="sign_manger_info"}
		                  }

		         },
		         {id = "ssas04",
		           name = "设置",
		           icon = "icon-system",
		           items ={{id = "ssas04-01",name = "账号安全",page = "security"}
							 			,
		           			{id = "ssas04-02",name = "个人资料",page = "about_me"}
		                  }
		     	 }
				},
		project = "智能工廠系统"
			}
}
