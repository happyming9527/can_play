class ActionController::Base
  include Consul::Controller
  current_power do
    CanPlay::Power.new(current_user)
  end
  helper_method :play_resources
  # 对current_power采用动态方法调用的装饰者。
  class PlayResourceObject < BasicObject
    def initialize(obj, klass)
      @obj = obj
      @klass = klass
    end

    def method_missing(method, *args, &block)
      if @obj.respond_to? "#{method}_evaluate_in_#{@klass.override_code}_scope"
        @obj.send("#{method}_evaluate_in_#{@klass.override_code}_scope", *args, &block)
      elsif @obj.respond_to? method
        @obj.send(method, *args, &block)
      else
        super
      end
    end
  end

  def play_resources
    @play_resource_object ||= PlayResourceObject.new(current_power, CanPlay)
  end

end