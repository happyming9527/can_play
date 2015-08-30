class Ability
  include CanCan::Ability
  attr_accessor :user

  def initialize(user)
    self.user = user||CanPlay::Config.user_class_name.constantize.new
    CanPlay::Config.super_roles.each do |role_name|
      can(:manage, :all) if user.role?(role_name)
    end
    CanPlay::Config.role_class_name.constantize.all.each do |role|
      next unless user.role?(role.name)
      role.send(CanPlay::Config.role_resources_relation_name).each do |role_resource|
        resource = CanPlay.find_by_name(role_resource.resource_name)
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