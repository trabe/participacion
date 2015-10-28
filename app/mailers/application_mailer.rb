class ApplicationMailer < ActionMailer::Base
  helper :settings
  default from: "participacion@udc.es"
  layout 'mailer'
end
