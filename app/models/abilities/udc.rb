module Abilities
  class Udc
    include CanCan::Ability

    def initialize(user)
      self.merge Abilities::Common.new(user)

      can :create, Proposal
    end
  end
end
