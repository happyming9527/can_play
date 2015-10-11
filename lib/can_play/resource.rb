module CanPlay
  class Resource
    include RorHack::ClassLevelInheritableAttributes

    def self.inherited(base)
      base.extend CanPlay::ClassMethods
      base.class_eval do

        # 定义动态类。
        eval "#{base.name.to_s}::OnlyInstance = Class.new(CanPlay::OnlyInstance)"
        singleton_attr_accessor :current_group, :temp_current_group
        inheritable_attributes :module_name
        base.module_name = ''

        clazz_name = base.name.gsub(/Resource$/, '')
        clazz = clazz_name.constantize rescue nil

        if clazz && clazz.is_a?(Module)
          base.group clazz
        end

        def self.before_set(&block)
          self::OnlyInstance.after_initialize_block_array << block
        end
      end
    end

  end
end