module CanPlay
  module Config
    mattr_accessor :user_class_name, :role_class_name, :role_resources_relation_name, :super_roles, :role_judge_method
    self.user_class_name              = 'User'
    self.role_class_name              = 'Role'
    self.role_resources_relation_name = 'role_resources'
    self.super_roles                  = []
    self.role_judge_method            = 'role_is?'

    def self.setup
      yield self
    end
  end
end