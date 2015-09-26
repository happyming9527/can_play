can_plan集成了cancancan和consul的功能，使用简单的DSL描述用户对单个资源或某类资源的操作权限，可以完整控制用户对任何资源的访问权限。如要使用它，系统必须有用户模型，推荐使用角色模型，用户可以有多个角色，然后在角色上设置权限，让单个用户，根据角色不同获取不同权限，以下示例都会基于用户和角色的模型。

![](http://7xn1q4.com1.z0.glb.clouddn.com/gem_can_play_role.png)

其中角色表在通过RoleResources这样的中间表和资源管理的权限进行关联。
![](http://7xn1q4.com1.z0.glb.clouddn.com/gem_can_play_role_resources.png)

使用Resource表做权限，字段可以有action、resource这样的字段，action表示行为，例如'create'，resouce表示资源，可以是Order这样的类名。这样做当然够简单，但是主要问题是，你没法对权限做更详细的限制，例如你对供应商都赋予查看合同的权限，但是不同的供应商只能查看自己的合同，这在数据库层面是难以表示的。当然，你也可以在controller里面加入限制，但这就是将权限控制的逻辑分散开了，其实完全可以将他们集中写到一个文件中。将Resources变成一张伪表，将具体的权限限制写入一个叫resources.rb的文件，并将资源名称和具体权限名称释放出来。

![](http://7xn1q4.com1.z0.glb.clouddn.com/gem_can_play_role_real.png)


## 安装方式


can_play在内部集成了cancancan和consul两个gem，所以没必要再安装这两个gem。
### can_play安装
在gemfile中加入can_play。

```
gem 'can_play'
```

运行bundle，安装完成后执行如下命令

```
rails generate can_play:install
```

执行该命令会在initializer和locales文件夹下生成配置文件。
initializer文件夹下的can_play.rb是can_play的基本配置文件。
locales下的can_play.zh-Cn.yml文件用于描述权限名称。
	
	# path_to_config/initializers/can_play.rb
	CanPlay::Config.setup do |config|
	  config.user_class_name = 'User'
	  config.role_class_name = 'Role'
	  config.role_resources_relation_name = 'role_resources'
	  config.super_roles = ['超级管理员']
	end

can_play.rb配置文件中，可以传入用户类名（默认User）、角色类名（默认Role）、以及角色和权限的关联的名称（默认role_resources）,role_resources_relation_name是角色类和操作权限资源之间的关联。

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

can_play.zh-CN.yml是中文翻译文件，在这里写下权限的英文和中文名称的对应，在前端就可以获取到权限的中文描述，其中common是一些常用权限名称，特别的权限名称，可以单独写，如contract下的terminate权限是合同独有的权限名称，必须单独写，而class_name也可以写上资源名称，如contract，如果不写，会默认去ActiveRecord的翻译文件下去取中文翻译。


### DSL文件描述权限的方法
dsl文件写法如下：

	#用哪个类用来描写权限，可在intializer下的can_play.rb文件下描写。
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
  	
`limit`方法用于控制某个用户可以查看的资源的额列表，如Contract类下的limit限制了管理员可以查看所有合同，供应商和采购人只能查看和自己相关的合同。limit方法会让在controller中生成一个动态方法，`current_power.contracts`，这个方法返回的是是我们再limit中写如的对象，这样就能根据用户的信息返回不同的资源数组。

`collection`方法，可以控制某个用户对某类资源的控制权限。如list和create权限，在controller中，我们可以用`authorize!(:read, Contract)`来限制用户的访问。

`member`方法，可以控制用户对某个资源的控制权限，如read权限，在controller中我们可以用authorize!(:read, @contract)来限制用户的访问。

`self.module_name = '核心模块'`是用来处理在多模块开发的环境下，各个模块可能有自己的resource文件，并可能出现中文的重名，权限最终要集中管理，module_name可以做个简单的分隔，让用户清楚某个权限属于哪个模块。

这些在controller中需要使用的current_power方法和authorize！方法分别是consul和cancancan中既有的方法。

### 和角色类之间建立关联

此处的resouce文件相当于在数据库中的resouces表，以动态的语言记录了所有的权限。我们需要通过role_resources这样的中间表，建立角色和权限之间的关联。可以在数据库建立中间表role_resources。

在controller或view中只要调用 CanPlay.splat_grouped_resources_with_chinese_desc就能返回所有的权限hash，并按资源进行了分组。如果调用CanPlay.grouped_resources_with_chinese_desc则返回按module_name分组后，再按资源名称分组的权限hash。我们用这个hash在表单中呈现，让用户勾选，然后在controller中保存角色和资源权限的关联。


其中roles_resources的表结构，至少要有role_id、resource_name字段，其中role_id关联角色，而 resource_name用于关联resource类（伪关联，实际不用加belongs_to这类关联）。

有了这个关联，加载页面，就可以自动执行权限的限制了，当然前提是你在controller的每个action加入了cancancan的权限限制语句authorize！。
