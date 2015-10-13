module CanPlay
  class AbstractResource

    include RorHack::ClassLevelInheritableAttributes
    extend CanPlay::ClassMethods
    inheritable_attributes :my_module_name
    self.my_module_name = 'other'

    def self.set_module_name(str)
      self.my_module_name = str
    end

    def self.set_method(name, &block)
      self::OnlyInstance.after_initialize_block_array << Proc.new do
        define_singleton_method name, &block
      end
    end

    def self.inherited(base)
      super
      base.class_eval do
        # 定义动态类。
        base.const_set "OnlyInstance", Class.new(self::OnlyInstance)
      end
    end

    class OnlyInstance

      singleton_attr_accessor :after_initialize_block_array, :only_you, :instance

      def initialize(opts)
        @user               = opts[:user] if opts[:user]
        @instance           = opts[:instance] if opts[:instance]
        self.class.only_you = self
      end

      def self.new(opts = {}.with_indifferent_access)
        o = allocate
        o.instance_eval { initialize(opts) }
        after_initialize_block_array.each do |block|
          o.instance_exec(opts[:user], &block)
        end
        o
      end

      def self.only
        if only_you.blank?
          if self == CanPlay::AbstractResource::OnlyInstance
            raise 'CanPlay::Resource::OnlyInstance not set first instance'
          else
            self.only_you = new(instance: superclass.only)
          end
        else
          only_you
        end
      end

      def self.only=(obj)
        self.only_you = obj
      end

      def self.after_initialize_block_array
        @after_initialize_block_array ||= []
      end

      def klass
        @klass ||= begin
          clazz_string = self.class.parent.name
          raise 'class name error' unless clazz_string.end_with?('Resource') || clazz_string.end_with?('ResourceOverride')
          clazz_name = self.class.parent.name.gsub(/Resource$/, '').gsub(/ResourceOverride$/, '')
          klass = clazz_name.constantize rescue nil
          klass
        end
      end

      def method_missing(method, *args, &block)
        if @instance
          return @instance.send(method, *args, &block)
        end
        super(method, *args, &block)
      end

      self.after_initialize_block_array << Proc.new do |user|

        define_singleton_method :user do
          user
        end

      end

      alias_method :set_method, :define_singleton_method
    end

  end

  class Resource < AbstractResource

    def self.inherited(base)
      super
      base.class_eval do
        raise 'class name set error' unless base.name.end_with?('Resource')
        clazz_name = base.name.gsub(/Resource$/, '')
        clazz = clazz_name.constantize rescue nil
        singleton_attr_accessor :current_group, :temp_current_group
        if clazz && clazz.is_a?(Module)
          base.group clazz
        end
      end
    end
  end

  class ResourceOverride < AbstractResource
    inheritable_attributes :uniq_override_code

    def self.set_override_code(str)
      self.uniq_override_code = str
    end

    set_override_code('')

    def self.inherited(base)
      super
      base.class_eval do
        raise 'class name set error' unless base.name.end_with?('ResourceOverride')
        clazz_name = base.name.gsub(/ResourceOverride$/, '')
        clazz = clazz_name.constantize rescue nil
        singleton_attr_accessor :current_group, :temp_current_group
        if clazz && clazz.is_a?(Module)
          base.group clazz
        end
      end
    end

    def self.add_resource(group, verb, object, type, behavior, opts)
      code = self.uniq_override_code
      super(group, verb, object, type, behavior, opts) and return if code.blank?
      name     = "#{verb}_#{group.name}"
      resource = ResourcePermission.new(
        my_module_name: my_module_name,
        name:        name,
        group:       group,
        verb:        verb,
        object:      object,
        type:        type,
        behavior:    behavior,
        opts:        opts
      )
      CanPlay.override_resources[code] ||= []
      CanPlay.override_resources[code].keep_if { |i| i.name != name }
      CanPlay.override_resources[code] << resource
    end

    def self.limit(name=nil, &block)
      clazz = self
      wrap_block = Proc.new do |*args|
        clazz::OnlyInstance.only.instance_exec(*args, &block)
      end
      method_name = name ? "#{name}_evaluate_in_#{code}_scope" : "#{current_group.name}_evaluate_in_#{self.uniq_override_code}_scope"

      CanPlay::Power.power(method_name, &wrap_block)
    end

  end
end