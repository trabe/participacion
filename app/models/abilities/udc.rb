module Abilities
  class Udc
    include CanCan::Ability

    def initialize(user)
      self.merge Abilities::Everyone.new(user)

      can :vote, Debate
      can :vote, Comment
      can :vote, Proposal
      can :vote_featured, Proposal

    end
  end
end
