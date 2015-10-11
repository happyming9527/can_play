module CanPlay

  class OnlyInstance

    singleton_attr_accessor :after_initialize_block_array, :only_you, :instance

    def initialize(opts={})
      opts = opts.with_indifferent_access
      if opts[:user]
        @user = opts[:user]
        @origin = true
      end
      @instance = opts[:instance] if opts[:instance]
      self.class.only_you = self
    end

    def self.new(user)
      o = allocate
      o.instance_eval{ initialize(user) }
      after_initialize_block_array.each do |block|
        o.instance_exec(user, &block)
      end
      o
    end

    def self.only
      if only_you.blank?
        if self == CanPlay::OnlyInstance
          raise 'CanPlay::OnlyInstance not set first instance'
        else
          self.only_you = new(instance: superclass.only)
        end
      else
        only_you
      end
    end

    def self.after_initialize_block_array
      @after_initialize_block_array ||= []
    end

    def method_missing(method, *args, &block)
      if @instance
        return @instance.send(method, *args, &block)
      end
      super(method, *args, &block)
    end
  end

end