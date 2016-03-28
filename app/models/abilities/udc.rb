module Abilities
  class Udc
    include CanCan::Ability

    def initialize(user)
      self.merge Abilities::Common.new(user)

      can :create, Proposal
      can :vote, Proposal
    end
  end
end
