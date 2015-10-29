module Verification
  extend ActiveSupport::Concern

  included do
    scope :level_three_verified, -> { where.not(verified_at: nil) }
    scope :level_two_verified, -> { where("users.level_two_verified_at IS NOT NULL OR (users.confirmed_phone IS NOT NULL AND users.residence_verified_at IS NOT NULL)") }
    scope :level_two_or_three_verified, -> { where("users.verified_at IS NOT NULL OR users.level_two_verified_at IS NOT NULL OR (users.confirmed_phone IS NOT NULL AND users.residence_verified_at IS NOT NULL)") }
    scope :unverified, -> { where("users.verified_at IS NULL AND (users.level_two_verified_at IS NULL AND (users.residence_verified_at IS NULL OR users.confirmed_phone IS NULL))") }
    scope :incomplete_verification, -> { where("(users.residence_verified_at IS NULL AND users.failed_census_calls_count > ?) OR (users.residence_verified_at IS NOT NULL AND (users.unconfirmed_phone IS NULL OR users.confirmed_phone IS NULL))", 0)  }
    scope :udc_registered, ->{ includes(:identities).where(identities: {provider: 'cas'}) }
  end

  def verification_email_sent?
    email_verification_token.present?
  end

  def verification_sms_sent?
    unconfirmed_phone.present? && sms_confirmation_code.present?
  end

  def verification_letter_sent?
    letter_requested_at.present? && letter_verification_code.present?
  end

  def residence_verified?
    residence_verified_at.present?
  end

  def sms_verified?
    confirmed_phone.present?
  end

  def level_two_verified?
    level_two_verified_at.present? || (residence_verified? && sms_verified?)
  end

  def level_three_verified?
    verified_at.present?
  end

  def level_two_or_three_verified?
    level_two_verified? || level_three_verified?
  end

  def udc_registered?
    identities.any?{|i| i.provider == 'cas'}
  end

  def verified?
    level_two_or_three_verified? || udc_registered?
  end

  def unverified?
    !verified?
  end

  def failed_residence_verification?
    !residence_verified? && failed_census_calls.size > 0
  end

  def no_phone_available?
    !verification_sms_sent?
  end

  def sms_code_not_confirmed?
    !sms_verified?
  end
end
