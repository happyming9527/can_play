&emsp;&emsp;can_plan集成了cancancan和consul这两个gem的功能，使用简单的DSL描述某个角色对单个资源或某类资源的操作权限，可以完整控制用户对资源的访问权限。如要使用它，系统必须有用户模型和角色模型。用户可以有多个角色，然后在角色上设置权限，让用户，根据角色不同获取不同权限，以下示例都会基于用户和角色的模型。

## 安装方式

&emsp;&emsp;在gemfile中加入can_play。

```
gem 'can_play'
```

&emsp;&emsp;运行bundle，安装完成后执行如下命令

```
rails generate can_play:install
```

&emsp;&emsp;执行该命令会在initializer和locales文件夹下生成配置文件。
initializer文件夹下的can_play.rb是can_play的基本配置文件。
locales下的can_play.zh-Cn.yml文件用于描述权限中文名称。
	
	# path_to_config/initializers/can_play.rb
	CanPlay::Config.setup do |config|
	  config.user_class_name = 'User'
	  config.role_class_name = 'Role'
	  config.role_resources_relation_name = 'role_resources'
	  config.super_roles = ['超级管理员']
  	  self.role_judge_method = 'role_is?'
	end

&emsp;&emsp;can_play.rb配置文件中，可以传入用户类名（默认User）、角色类名（默认Role）、以及角色和权限的关联的名称（默认role_resources）,role_resources_relation_name是角色类和操作权限资源之间的关联，以及判断当前用户角色的方法（默认role_is？）。


	# path_to_config/config/locales/can_play.zh-Cn.yml
	---
	zh-CN:
	  can_play:
	    class_name:
	      test: 测试
	      contract: 合同
	    authority_name:
	      common:
	        list: 列表查看
	        create: 新建
	        read: 查看
	        update: 修改
	        delete: 删除
	        crud: 管理
	        menus_roles: 菜单分配
	        role_resources: 权限分配
	        improve: 完善信息
	      contract:
	        terminate: 终止
	        purchaser_confirm: 采购人确认
	        supplier_confirm: 供应商确认

&emsp;&emsp;can_play.zh-CN.yml是中文翻译文件，在这里写下权限的英文和中文名称的对应，在前端就可以获取到权限的中文描述，其中common是一些常用权限名称，特别的权限名称，可以单独写，如contract下的terminate权限是合同独有的权限名称，必须单独写，而class_name也可以写上资源名称，如contract，如果不写，会默认去ActiveRecord的翻译文件下去取中文翻译。


### DSL文件描述权限的方法
&emsp;&emsp;dsl文件写法如下：

	# 类名，或文件名叫什么并不要紧，关键是要'include CanPlay'
	class Resource
	  include CanPlay
	  self.module_name = '核心模块'
	  
	  # 所有limit块、collection块和member块中都注入了user这个变量，指向当前登录用户，可直接使用。

	  group Contract do |klass|

	  	# 描述某个用户可以查看到哪些合同条目。
	    limit do
	      if user.is_admin?
	        klass.all
	      elsif user.role? '供应商'
	        klass.where(supplier: user.supplier)
	      elsif user.role? '采购人'
	        klass.where(purchaser: user.purchaser)
	      else
	        klass.none
	      end
	    end

		# 描述某个用户可以是否而已查看合同列表、创建合同。
	    collection [:list, :create], klass do
	      user.is_admin?
	    end

		# 描述某个用户可以是否可以查看、更新某个合同。
	    member [:read, :update], klass do |obj|
	      if user.is_admin?
	        true
	      elsif user.role? '供应商'
	        obj.supplier.is? user.supplier
	      elsif user.role? '采购人'
	        obj.purchaser.is? user.purchaser
	      else
	        false
	      end
	    end

		# 描述某个用户可以是否可以删除、终止某个合同。
	    member [:delete, :terminate], klass do |obj|
	      user.is_admin?
	    end
	  end

  	end
  	
  	
&emsp;&emsp;`group`是一个用于对资源做分组的宏。group方法可以只接一个类或模型，在其后再接一个代码块，并把刚才传给group的类或模型，传给这个代码块。他是limit、collection、member方法的容器。
  	
&emsp;&emsp;`limit`方法用于控制某个用户可以查看的资源的额列表，如Contract类下的limit限制了管理员可以查看所有合同，供应商和采购人只能查看和自己相关的合同。limit方法会让在controller中生成一个动态方法，`current_power.contracts`，这个方法返回的是是我们再limit中写如的对象，这样就能根据用户的信息返回不同的资源数组。

&emsp;&emsp;`collection`方法，可以控制某个用户对某类资源的控制权限。如list和create权限，在controller中，我们可以用`authorize!(:read, Contract)`来限制用户的访问。

&emsp;&emsp;`member`方法，可以控制用户对某个资源的控制权限，如read权限，在controller中我们可以用authorize!(:read, @contract)来限制用户的访问。

&emsp;&emsp;`self.module_name = '核心模块'`是用来处理在多模块开发的环境下，各个模块可能有自己的resource文件，并可能出现中文的重名，权限最终要集中管理，module_name可以做个简单的分隔，让用户清楚某个权限属于哪个模块。


### 如何使用
&emsp;&emsp;对使用有不清楚的，可以查看https://github.com/happyming9527/can_play/wiki
