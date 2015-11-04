class User < ActiveRecord::Base
  OMNIAUTH_EMAIL_PREFIX = 'omniauth@participacion'
  OMNIAUTH_EMAIL_REGEX  = /\A#{OMNIAUTH_EMAIL_PREFIX}/

  include Verification

  apply_simple_captcha
  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :trackable, :validatable, :omniauthable, :async

  acts_as_voter
  acts_as_paranoid column: :hidden_at
  include ActsAsParanoidAliases

  has_one :administrator
  has_one :moderator
  has_one :organization
  has_one :lock
  has_many :flags
  has_many :identities, dependent: :destroy
  has_many :debates, -> { with_hidden }, foreign_key: :author_id
  has_many :proposals, -> { with_hidden }, foreign_key: :author_id
  has_many :comments, -> { with_hidden }
  has_many :failed_census_calls

  validates :username, presence: true, if: :username_required?
  validates :username, uniqueness: true, if: :username_required?
  validates :document_number, uniqueness: { scope: :document_type }, allow_nil: true

  validate :validate_username_length

  validates :official_level, inclusion: {in: 0..5}
  validates_format_of :email, without: OMNIAUTH_EMAIL_REGEX, on: :update
  validates :terms_of_service, acceptance: { allow_nil: false }, on: :create

  validates_associated :organization, message: false

  accepts_nested_attributes_for :organization, update_only: true

  attr_accessor :skip_password_validation

  scope :administrators, -> { joins(:administrators) }
  scope :moderators,     -> { joins(:moderator) }
  scope :organizations,  -> { joins(:organization) }
  scope :officials,      -> { where("official_level > 0") }
  scope :for_render,     -> { includes(:organization) }
  scope :by_document,    -> (document_type, document_number) { where(document_type: document_type, document_number: document_number) }

  before_validation :clean_document_number

  def self.find_for_oauth(auth, signed_in_resource = nil)
    # Get the identity and user if they exist
    identity = Identity.find_for_oauth(auth)

    # If a signed_in_resource is provided it always overrides the existing user
    # to prevent the identity being locked with accidentally created accounts.
    # Note that this may leave zombie accounts (with no associated identity) which
    # can be cleaned up at a later date.
    user = signed_in_resource ? signed_in_resource : identity.user
    user ||= first_or_create_for_oauth(auth)

    # Associate the identity with the user if needed
    identity.update_user(user)
    user
  end

  # Get the existing user by email if the provider gives us a verified email.
  # If no verified email was provided we assign a temporary email and ask the
  # user to verify it on the next step via RegistrationsController.finish_signup
  def self.first_or_create_for_oauth(auth)
    email = auth.info.email if auth.info.verified || auth.info.verified_email
    email = auth.extra.mail if auth.extra.mail # Just for our cas :S

    name = auth.extra.firstName || auth.info.nickname || auth.extra.raw_info.name.parameterize('-') || auth.uid

    document_number = auth.extra.documentNumber

    user  = User.where(email: email).first if email

    # Create the user if it's a new registration
    if user.nil?
      user = User.new(
        username: name,
        email: email ? email : "#{OMNIAUTH_EMAIL_PREFIX}-#{auth.uid}-#{auth.provider}.com",
        document_number: document_number,
        document_type: 1, # TODO: Save the correct type, see: UserHelper
        password: Devise.friendly_token[0,20],
        terms_of_service: '1'
      )
      user.skip_confirmation!
      user.save!
    end

    user.update_document_number(document_number) unless user.document_number.present? # Can be if the user was registered first as non-udc with an udc email

    user
  end

  def name
    organization? ? organization.name : username
  end

  def debate_votes(debates)
    voted = votes.for_debates(debates)
    voted.each_with_object({}) { |v, h| h[v.votable_id] = v.value }
  end

  def proposal_votes(proposals)
    voted = votes.for_proposals(proposals)
    voted.each_with_object({}) { |v, h| h[v.votable_id] = v.value }
  end

  def comment_flags(comments)
    comment_flags = flags.for_comments(comments)
    comment_flags.each_with_object({}){ |f, h| h[f.flaggable_id] = true }
  end

  def administrator?
    administrator.present?
  end

  def moderator?
    moderator.present?
  end

  def organization?
    organization.present?
  end

  def verified_organization?
    organization && organization.verified?
  end

  def official?
    official_level && official_level > 0
  end

  def add_official_position!(position, level)
    return if position.blank? || level.blank?
    update official_position: position, official_level: level.to_i
  end

  def remove_official_position!
    update official_position: nil, official_level: 0
  end

  def block
    debates_ids = Debate.where(author_id: id).pluck(:id)
    comments_ids = Comment.where(user_id: id).pluck(:id)
    proposal_ids = Proposal.where(author_id: id).pluck(:id)

    self.hide

    Debate.hide_all debates_ids
    Comment.hide_all comments_ids
    Proposal.hide_all proposal_ids
  end

  def erase(erase_reason = nil)
    self.update(
      erased_at: Time.now,
      erase_reason: erase_reason,
      username: nil,
      email: nil,
      unconfirmed_email: nil,
      document_number: nil,
      phone_number: nil,
      encrypted_password: "",
      confirmation_token: nil,
      reset_password_token: nil,
      email_verification_token: nil
    )
    self.identities.destroy_all
  end

  def erased?
    erased_at.present?
  end

  def email_provided?
    !!(email && email !~ OMNIAUTH_EMAIL_REGEX) ||
      !!(unconfirmed_email && unconfirmed_email !~ OMNIAUTH_EMAIL_REGEX)
  end

  def locked?
    Lock.find_or_create_by(user: self).locked?
  end

  def self.search(term)
    term.present? ? where("email = ? OR username ILIKE ?", term, "%#{term}%") : none
  end

  def self.username_max_length
    @@username_max_length ||= self.columns.find { |c| c.name == 'username' }.limit || 60
  end

  def show_welcome_screen?
    sign_in_count == 1 && unverified? && !organization && !administrator?
  end

  def password_required?
    return false if skip_password_validation
    super
  end

  def username_required?
    !organization? && !erased?
  end

  def email_required?
    !erased?
  end

  def update_document_number(document_number)
    self.update_attributes(document_number: document_number, document_type: 1) # TODO: Save the correct type, see: UserHelper
  end

  private
    def clean_document_number
      self.document_number = self.document_number.gsub(/[^a-z0-9]+/i, "").upcase unless self.document_number.blank?
    end

    def validate_username_length
      validator = ActiveModel::Validations::LengthValidator.new(
        attributes: :username,
        maximum: User.username_max_length)
      validator.validate(self)
    end

end
