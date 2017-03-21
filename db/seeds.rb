# coding: utf-8
# Default admin user (change password after first deploy to a server!)
if Administrator.count == 0 && !Rails.env.test?
  admin = User.create!(username: 'admin', email: 'admin@udcdecide.udc.gal', password: '12345678', password_confirmation: '12345678', confirmed_at: Time.now, terms_of_service: "1")
  admin.create_administrator
end

# Names for the moderation console, as a hint for moderators
# to know better how to assign users with official positions
Setting["official_level_1_name"] = "PAS"
Setting["official_level_2_name"] = "Facultade"
Setting["official_level_3_name"] = "Decano"
Setting["official_level_4_name"] = "Vicereitor"
Setting["official_level_5_name"] = "Reitor"

# Max percentage of allowed anonymous votes on a debate
Setting["max_ratio_anon_votes_on_debates"] = 50

# Max votes where a debate is still editable
Setting["max_votes_for_debate_edit"] = 100

# Max votes where a proposal is still editable
Setting["max_votes_for_proposal_edit"] = 100

# Prefix for the Proposal codes
Setting["proposal_code_prefix"] = 'UDC'

# Number of votes needed for proposal success
Setting["votes_for_proposal_success"] = 100

# Users with this email domain will automatically be marked as level 1 officials
# Emails under the domain's subdomains will also be included
Setting["email_domain_for_officials"] = ''

# Code to be included at the top (header) of every page (useful for tracking)
Setting['per_page_code'] =  ''

# Social settings
Setting["twitter_handle"] = '@UDC_gal'
Setting["facebook_handle"] = 'udc.gal'
Setting["youtube_handle"] = nil
Setting["blog_url"] = nil

# Public-facing URL of the app.
Setting["url"] = "http://udcdecide.udc.gal"

# Consul installation's organization name
Setting["org_name"] = "UDC Decide"

# Consul installation place name (City, Country...)
Setting["place_name"] = "A Coruña"

# Feature flags
Setting['feature.debates'] = true
Setting['feature.spending_proposals'] = false
Setting['feature.twitter_login'] = false
Setting['feature.facebook_login'] = false
Setting['feature.google_login'] = false
Setting['feature.cas_login'] = true
Setting['feature.public_stats'] = false

# Max length for comments
Setting['comments_body_max_length'] = 1000
