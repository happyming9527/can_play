module CanPlay
  module Override
    as_trait do |code|
      extend ClassMethods
      singleton_attr_accessor(:groups, :current_group, :module_name)
      self.groups        = []
      self.current_group = nil
      self.module_name   = ''

      define_singleton_method(:limit) do |name=nil, &block|
        raise "Need define group first" if current_group.nil?
        method_name = name ? "#{name}_evaluate_in_#{code}_scope" : "#{current_group.name}_evaluate_in_#{code}_scope"
        Power.power(method_name, &block)
      end

      define_singleton_method(:add_resource) do |group, verb, object, type, behavior, opts|
        super(group, verb, object, type, behavior, opts) and return if code.blank?
        CanPlay.override_resources[code] ||= []
        name                             = "#{verb}_#{group.name}"
        resource                         = OpenStruct.new(
          module_name: module_name,
          name:        name,
          group:       group,
          verb:        verb,
          object:      object,
          type:        type,
          behavior:    behavior,
          opts:        opts
        )
        CanPlay.override_resources[code].keep_if { |i| i.name != name }
        CanPlay.override_resources[code] << resource
      end
    end
  end
end