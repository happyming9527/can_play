module CanPlay
  class Power
    include Consul::Power
    attr_accessor :user

    def initialize(user)
      self.user = user
    end

  end
end