class ProposalsController < ApplicationController
  include CommentableActions
  include FlagActions

  before_action :parse_search_terms, only: [:index, :suggest]
  before_action :parse_advanced_search_terms, only: :index
  before_action :parse_tag_filter, only: :index
  before_action :set_search_order, only: :index
  before_action :load_categories, only: [:index, :new, :edit, :map, :summary]
  before_action :load_geozones, only: [:edit, :map, :summary]
  before_action :authenticate_user!, except: [:index, :show, :map, :summary]

  has_orders %w{hot_score confidence_score created_at relevance}, only: :index
  has_orders %w{most_voted newest oldest}, only: :show

  load_and_authorize_resource
  helper_method :resource_model, :resource_name
  respond_to :html, :js

  def show
    super
    redirect_to proposal_path(@proposal), status: :moved_permanently if request.path != proposal_path(@proposal)
  end

  def index_customization
    @geozones = most_used_geozones
    @featured_proposals = Proposal.all.sort_by_confidence_score.limit(3) if (!@advanced_search_terms && @search_terms.blank? && @tag_filter.blank?)
    if @featured_proposals.present?
      set_featured_proposal_votes(@featured_proposals)
      @resources = @resources.where('proposals.id NOT IN (?)', @featured_proposals.map(&:id))
    end
  end

  def vote
    @proposal.register_vote(current_user, 'yes')
    set_proposal_votes(@proposal)
  end

  def vote_featured
    @proposal.register_vote(current_user, 'yes')
    set_featured_proposal_votes(@proposal)
  end

  def summary
    @proposals = Proposal.for_summary
    @tag_cloud = tag_cloud
  end

  private

    def proposal_params
      params.require(:proposal).permit(:title, :question, :summary, :description, :external_url, :video_url, :responsible_name, :tag_list, :terms_of_service, :captcha, :captcha_key, :geozone_id)
    end

    def resource_model
      Proposal
    end

    def set_featured_proposal_votes(proposals)
      @featured_proposals_votes = current_user ? current_user.proposal_votes(proposals) : {}
    end

    # NOTE: Quick & dirty "show most used geozones method"
    def most_used_geozones
      ids = Debate.pluck(:geozone_id) + Proposal.pluck(:geozone_id)
      most_used_geozones_ids = ids.each_with_object(Hash.new(0)) { |id,counts| counts[id] += 1 }.sort_by{ |_,v| v }.last(5).map{|id, _| id}
      Geozone.find(most_used_geozones_ids)
    end

end
