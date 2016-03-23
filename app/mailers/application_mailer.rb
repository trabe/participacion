class ApplicationMailer < ActionMailer::Base
  helper :settings
  default from: "participa-noreply@udc.gal"
  layout 'mailer'
end
