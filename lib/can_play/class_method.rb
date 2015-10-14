module CanPlay

  class ResourcePermission < OpenStruct
  end

  class NameImportantGroup < OpenStruct
    def eql?(another)
      self.name == another.name
    end
  end

  module ClassMethods

    def group(*args, &block)
      opts = args.extract_options!.with_indifferent_access
      clazz = args.first
      if clazz.is_a?(Module)
        name  = clazz.to_s.underscore.gsub('/', '_').pluralize
        group = NameImportantGroup.new(name: name, klass: clazz, defined_class_wrapper: self)
      elsif clazz.blank? &&  opts.key?(:name) &&  opts.key?(:klass)
        opts  = opts.with_indifferent_access
        group = NameImportantGroup.new(name: opts.delete(:name).to_s, klass: opts.delete(:klass), defined_class_wrapper: self)
      else
        raise "group klass need set"
      end
      group.opts = OpenStruct.new opts
      CanPlay.groups << group
      CanPlay.groups = CanPlay.groups.uniq(&:name)
      self.temp_current_group = self.current_group
      self.current_group = group
      if block
        block.call(group.klass)
        self.current_group = self.temp_current_group
        self.temp_current_group = nil
      end
    end

    def limit(name=nil, &block)
      clazz = self
      wrap_block = Proc.new do |*args|
        AbstractResource.only_instance_classes[clazz].only.instance_exec(*args, &block)
      end
      name ||= current_group.try(:name)
      raise "Need define group or set limit name first" if name.nil?
      CanPlay::Power.power(name||current_group.name, &wrap_block)
    end

    def collection(verb_or_verbs, opts={}, &block)

      raise "Need define group first" if current_group.nil?
      opts = OpenStruct.new opts
      group    = current_group
      behavior = nil
      clazz = self
      if block
        behavior = Proc.new do
          AbstractResource.only_instance_classes[clazz].only.instance_eval(&block)
        end
      end

      if verb_or_verbs.kind_of?(Array)
        verb_or_verbs.each do |verb|
          add_resource(group, verb, group.klass, 'collection', behavior, opts)
        end
      else
        add_resource(group, verb_or_verbs, group.klass, 'collection', behavior, opts)
      end
    end

    def member(verb_or_verbs, opts={}, &block)
      raise "Need define group first" if current_group.nil?
      opts = OpenStruct.new opts
      group    = current_group
      behavior = nil
      clazz = self
      if block
        behavior = Proc.new do |obj|
          AbstractResource.only_instance_classes[clazz].only.instance_exec(obj, &block)
        end
      end

      if verb_or_verbs.kind_of?(Array)
        verb_or_verbs.each do |verb|
          add_resource(group, verb, group.klass, 'member', behavior, opts)
        end
      else
        add_resource(group, verb_or_verbs, group.klass, 'member', behavior, opts)
      end
    end

    def add_resource(group, verb, object, type, behavior, opts)
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
      CanPlay.resources.keep_if { |i| i.name != name }
      CanPlay.resources << resource
    end
  end
end