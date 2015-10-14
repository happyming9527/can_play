class ActionController::Base
  include Consul::Controller
  current_power do
    CanPlay::Power.new
  end
  helper_method :play_resources

  after_action do
    CanPlay::AbstractResource.clear_only_instances.call
  end

  def set_can_play(opts = {}.with_indifferent_access)
    CanPlay.override_code = opts.delete(:override_code)
    raise 'user not set' unless opts[:user]
    can_play_instance = CanPlay::AbstractResource.only_instance_classes[CanPlay::AbstractResource].new(opts)
    CanPlay::AbstractResource.new_opts = opts.tap do |i|
      i.delete(:user)
    end.freeze
  end

  def play_resources
    @play_resource_object ||= CanPlay::PlayResourceObject.new(current_power, CanPlay)
  end

end