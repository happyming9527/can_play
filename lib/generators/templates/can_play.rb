# 在此可设置重要配置信息。

CanPlay::Config.setup do |config|

  # role_class_name表示用户表表名。
  config.user_class_name = 'User'

  # role_class_name表示角色表表名
  config.role_class_name = 'Role'

  # super_role_resources_relation_name表示角色和权限中间表在model中的关联名称。
  config.role_resources_relation_name = 'role_resources'

  # super_roles表示无需分配权限既可拥有所有权限的角色。
  config.super_roles = ['超级管理员']

  # 也可以传入代码块，若使代码块，则会传入形参user，指代当前用户，代码块返回的结果为true，则当前登录用户的当前角色则有无限权限。。
  #config.super_roles = ->(role) { 1 == user.current_role.try(:id) }

  # 判断角色是否符合的方法。
  config.role_judge_method = 'role_is?'
end