module CommonActions

  def sign_up(email='manuela@madrid.es', password='judgementday')
    visit '/'
    click_link 'Sign up'

    fill_in 'user_username',              with: "Manuela Carmena #{rand(99999)}"
    fill_in 'user_email',                 with: email
    fill_in 'user_password',              with: password
    fill_in 'user_password_confirmation', with: password
    fill_in 'user_captcha',               with: correct_captcha_text
    check 'user_terms_of_service'

    click_button 'Sign up'
  end

  def login_through_form_as(user)
    visit root_path
    click_link 'Log in'

    fill_in 'user_email', with: user.email
    fill_in 'user_password', with: user.password

    click_button 'Log in'
  end

  def login_as_manager
    login, user_key, date = "JJB042", "31415926", Time.now.strftime("%Y%m%d%H%M%S")
    allow_any_instance_of(ManagerAuthenticator).to receive(:auth).and_return({login: login, user_key: user_key, date: date})
    visit management_sign_in_path(login: login, clave_usuario: user_key, fecha_conexion: date)
  end

  def login_managed_user(user)
    allow_any_instance_of(Management::BaseController).to receive(:managed_user).and_return(user)
  end

  def confirm_email
    expect(page).to have_content "A message with a confirmation link has been sent to your email address."

    sent_token = /.*confirmation_token=(.*)".*/.match(ActionMailer::Base.deliveries.last.body.to_s)[1]
    visit user_confirmation_path(confirmation_token: sent_token)

    expect(page).to have_content "Your email address has been successfully confirmed"
  end

  def reset_password
    create(:user, email: 'manuela@madrid.es')

    visit '/'
    click_link 'Log in'
    click_link 'Forgot your password?'

    fill_in 'user_email', with: 'manuela@madrid.es'
    click_button 'Send me reset password'
  end

  def comment_on(commentable, user = nil)
    user ||= create(:user)

    login_as(user)
    commentable_path = commentable.is_a?(Proposal) ? proposal_path(commentable) : debate_path(commentable)
    visit commentable_path

    fill_in "comment-body-#{commentable.class.name.downcase}_#{commentable.id}", with: 'Have you thought about...?'
    click_button 'Publish comment'

    expect(page).to have_content 'Have you thought about...?'
  end

  def reply_to(original_user, manuela = nil)
    manuela ||= create(:user)

    debate  = create(:debate)
    comment = create(:comment, commentable: debate, user: original_user)

    login_as(manuela)
    visit debate_path(debate)

    click_link "Reply"
    within "#js-comment-form-comment_#{comment.id}" do
      fill_in "comment-body-comment_#{comment.id}", with: 'It will be done next week.'
      click_button 'Publish reply'
    end
    expect(page).to have_content 'It will be done next week.'
  end

  def correct_captcha_text
    SimpleCaptcha::SimpleCaptchaData.last.value
  end

  def avatar(name)
    "img.initialjs-avatar[data-name='#{name}']"
  end

  def error_message
    /\d errors? prohibited this (.*) from being saved:/
  end

  def expect_to_be_signed_in
    expect(find('.top-bar')).to have_content 'My account'
  end

  def select_date(values, selector)
    selector = selector[:from]
    day, month, year = values.split("-")
    select day,   from: "#{selector}_3i"
    select month, from: "#{selector}_2i"
    select year,  from: "#{selector}_1i"
  end

  def verify_residence
    select 'Spanish ID', from: 'residence_document_type'
    fill_in 'residence_document_number', with: "12345678Z"
    select_date '31-December-1980', from: 'residence_date_of_birth'
    fill_in 'residence_postal_code', with: '28013'
    check 'residence_terms_of_service'

    click_button 'Verify residence'
    expect(page).to have_content 'Residence verified'
  end

  def confirm_phone
    fill_in 'sms_phone', with: "611111111"
    click_button 'Send'

    expect(page).to have_content 'Phone confirmation'

    user = User.last.reload
    fill_in 'sms_confirmation_code', with: user.sms_confirmation_code
    click_button 'Send'

    expect(page).to have_content 'Correct code'
  end

  def expect_message_you_need_to_sign_in
    expect(page).to have_content 'You need to sign in or sign up before continuing'
    expect(page).to have_selector('.in-favor a', visible: false)
  end

  def expect_message_to_many_anonymous_votes
    expect(page).to have_content 'Too many anonymous votes, verify your account to vote.'
    expect(page).to have_selector('.in-favor a', visible: false)
  end

  def expect_message_only_verified_can_vote_proposals
    expect(page).to have_content 'Proposals can only be voted by verified users, verify your account.'
    expect(page).to have_selector('.in-favor a', visible: false)
  end

  def create_featured_proposals
    [create(:proposal, :with_confidence_score, cached_votes_up: 100),
     create(:proposal, :with_confidence_score, cached_votes_up: 90),
     create(:proposal, :with_confidence_score, cached_votes_up: 80)]
  end

end
