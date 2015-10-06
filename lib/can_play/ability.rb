class Ability
  include CanCan::Ability
  attr_accessor :user

  def initialize(user)
    clear_aliased_actions
    CanPlay::Config.tap do |i|
      self.user = user||i.user_class_name.constantize.new
      if i.super_roles.is_a?(Array)
        i.super_roles.each do |role_name|
          can(:manage, :all) if user.send(i.role_judge_method, role_name)
        end
      elsif i.super_roles.is_a?(Proc)
        can(:manage, :all) if i.super_roles.call(user)
      end
      i.role_class_name.constantize.all.each do |role|
        next unless user.send(i.role_judge_method, role)
        role.send(i.role_resources_relation_name).each do |role_resource|
          resource = CanPlay.find_by_name_and_code(role_resource.resource_name, CanPlay.override_code)
          next unless resource
          if resource[:type] == 'collection'
            if resource[:behavior]
              block = resource[:behavior]
              can(resource[:verb], resource[:object]) if block.call(user)
            else
              can resource[:verb], resource[:object]
            end
          elsif resource[:type] == 'member'
            if resource[:behavior]
              block = resource[:behavior]
              can resource[:verb], resource[:object] do |object|
                block.call(user, object)
              end
            else
              can resource[:verb], resource[:object]
            end
          end
        end
      end
    end
  end
end