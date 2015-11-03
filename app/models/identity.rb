class Identity < ActiveRecord::Base
  belongs_to :user

  validates :provider, presence: true
  validates :uid, presence: true, uniqueness: { scope: :provider }

  def self.find_for_oauth(auth_data)
    where(uid: auth_data.uid, provider: auth_data.provider).first_or_create
  end

  def update_user(new_user)
    return unless user != new_user

    self.user = new_user
    save!
  end
end
