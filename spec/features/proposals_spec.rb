# coding: utf-8
require 'rails_helper'

feature 'Proposals' do

  scenario 'Index' do
    featured_proposals = create_featured_proposals
    proposals = [create(:proposal), create(:proposal), create(:proposal)]

    visit proposals_path

    expect(page).to have_selector('#proposals .proposal-featured', count: 3)
    featured_proposals.each do |featured_proposal|
      within('#featured-proposals') do
        expect(page).to have_content featured_proposal.title
        expect(page).to have_css("a[href='#{proposal_path(featured_proposal)}']")
      end
    end

    expect(page).to have_selector('#proposals .proposal', count: 3)
    proposals.each do |proposal|
      within('#proposals') do
        expect(page).to have_content proposal.title
        expect(page).to have_css("a[href='#{proposal_path(proposal)}']", text: proposal.title)
        expect(page).to have_css("a[href='#{proposal_path(proposal)}']", text: proposal.summary)
      end
    end
  end

  scenario 'Paginated Index' do
    per_page = Kaminari.config.default_per_page
    (per_page + 5).times { create(:proposal) }

    visit proposals_path

    expect(page).to have_selector('#proposals .proposal', count: per_page)

    within("ul.pagination") do
      expect(page).to have_content("1")
      expect(page).to have_content("2")
      expect(page).to_not have_content("3")
      click_link "Next", exact: false
    end

    expect(page).to have_selector('#proposals .proposal', count: 2)
  end

  scenario 'Show' do
    proposal = create(:proposal)

    visit proposal_path(proposal)

    expect(page).to have_content proposal.title
    expect(page).to have_content proposal.code
    expect(page).to have_content "Proposal question"
    expect(page).to have_content "Proposal description"
    expect(page).to have_content "http://external_documention.es"
    expect(page).to have_content proposal.author.name
    expect(page).to have_content I18n.l(proposal.created_at.to_date)
    expect(page).to have_selector(avatar(proposal.author.name))
    expect(page.html).to include "<title>#{proposal.title}</title>"

    within('.social-share-button') do
      expect(page.all('a').count).to be(3) # Twitter, Facebook, Google+
    end
  end

  scenario 'Social Media Cards' do
    proposal = create(:proposal)

    visit proposal_path(proposal)
    expect(page.html).to include "<meta name=\"twitter:title\" content=\"#{proposal.title}\" />"
    expect(page.html).to include "<meta id=\"ogtitle\" property=\"og:title\" content=\"#{proposal.title}\"/>"
  end

  scenario 'Create' do
    author = create(:user)
    login_as(author)

    visit new_proposal_path
    fill_in 'proposal_title', with: 'Help refugees'
    fill_in 'proposal_question', with: '¿Would you like to give assistance to war refugees?'
    fill_in 'proposal_summary', with: 'In summary, what we want is...'
    fill_in 'proposal_description', with: 'This is very important because...'
    fill_in 'proposal_external_url', with: 'http://rescue.org/refugees'
    fill_in 'proposal_video_url', with: 'http://youtube.com'
    fill_in 'proposal_responsible_name', with: 'Isabel Garcia'
    fill_in 'proposal_captcha', with: correct_captcha_text
    check 'proposal_terms_of_service'

    click_button 'Create proposal'

    expect(page).to have_content 'Proposal created successfully.'
    expect(page).to have_content 'Help refugees'
    expect(page).to have_content '¿Would you like to give assistance to war refugees?'
    expect(page).to have_content 'In summary, what we want is...'
    expect(page).to have_content 'This is very important because...'
    expect(page).to have_content 'http://rescue.org/refugees'
    expect(page).to have_content 'http://youtube.com'
    expect(page).to have_content author.name
    expect(page).to have_content I18n.l(Proposal.last.created_at.to_date)
  end

  scenario 'Responsible name is stored for anonymous users' do
    author = create(:user)
    login_as(author)

    visit new_proposal_path
    fill_in 'proposal_title', with: 'Help refugees'
    fill_in 'proposal_question', with: '¿Would you like to give assistance to war refugees?'
    fill_in 'proposal_summary', with: 'In summary, what we want is...'
    fill_in 'proposal_description', with: 'This is very important because...'
    fill_in 'proposal_external_url', with: 'http://rescue.org/refugees'
    fill_in 'proposal_responsible_name', with: 'Isabel Garcia'
    fill_in 'proposal_captcha', with: correct_captcha_text
    fill_in 'proposal_responsible_name', with: 'Isabel Garcia'
    check 'proposal_terms_of_service'

    click_button 'Create proposal'

    expect(page).to have_content 'Proposal created successfully.'
    expect(Proposal.last.responsible_name).to eq('Isabel Garcia')
  end

  scenario 'Responsible name field is not shown for verified users' do
    author = create(:user, :level_two)
    login_as(author)

    visit new_proposal_path
    expect(page).to_not have_selector('#proposal_responsible_name')

    fill_in 'proposal_title', with: 'Help refugees'
    fill_in 'proposal_question', with: '¿Would you like to give assistance to war refugees?'
    fill_in 'proposal_summary', with: 'In summary, what we want is...'
    fill_in 'proposal_description', with: 'This is very important because...'
    fill_in 'proposal_external_url', with: 'http://rescue.org/refugees'
    fill_in 'proposal_captcha', with: correct_captcha_text
    check 'proposal_terms_of_service'

    click_button 'Create proposal'

    expect(page).to have_content 'Proposal created successfully.'
  end

  scenario 'Captcha is required for proposal creation' do
    login_as(create(:user))

    visit new_proposal_path
    fill_in 'proposal_title', with: "Great title"
    fill_in 'proposal_question', with: '¿Would you like to give assistance to war refugees?'
    fill_in 'proposal_summary', with: 'In summary, what we want is...'
    fill_in 'proposal_description', with: 'Very important issue...'
    fill_in 'proposal_external_url', with: 'http://rescue.org/refugees'
    fill_in 'proposal_responsible_name', with: 'Isabel Garcia'
    fill_in 'proposal_captcha', with: "wrongText!"
    check 'proposal_terms_of_service'

    click_button "Create proposal"

    expect(page).to_not have_content "Proposal created successfully."
    expect(page).to have_content "1 error"

    fill_in 'proposal_captcha', with: correct_captcha_text
    click_button "Create proposal"

    expect(page).to have_content "Proposal created successfully."
  end

  scenario 'Errors on create' do
    author = create(:user)
    login_as(author)

    visit new_proposal_path
    click_button 'Create proposal'
    expect(page).to have_content error_message
  end

  scenario 'JS injection is prevented but safe html is respected' do
    author = create(:user)
    login_as(author)

    visit new_proposal_path
    fill_in 'proposal_title', with: 'Testing an attack'
    fill_in 'proposal_question', with: '¿Would you like to give assistance to war refugees?'
    fill_in 'proposal_summary', with: 'In summary, what we want is...'
    fill_in 'proposal_description', with: '<p>This is <script>alert("an attack");</script></p>'
    fill_in 'proposal_external_url', with: 'http://rescue.org/refugees'
    fill_in 'proposal_responsible_name', with: 'Isabel Garcia'
    fill_in 'proposal_captcha', with: correct_captcha_text
    check 'proposal_terms_of_service'

    click_button 'Create proposal'

    expect(page).to have_content 'Proposal created successfully.'
    expect(page).to have_content 'Testing an attack'
    expect(page.html).to include '<p>This is alert("an attack");</p>'
    expect(page.html).to_not include '<script>alert("an attack");</script>'
    expect(page.html).to_not include '&lt;p&gt;This is'
  end

  scenario 'Autolinking is applied to description' do
    author = create(:user)
    login_as(author)

    visit new_proposal_path
    fill_in 'proposal_title', with: 'Testing auto link'
    fill_in 'proposal_question', with: 'Should I stay or should I go?'
    fill_in 'proposal_summary', with: 'In summary, what we want is...'
    fill_in 'proposal_description', with: '<p>This is a link www.example.org</p>'
    fill_in 'proposal_responsible_name', with: 'Isabel Garcia'
    fill_in 'proposal_captcha', with: correct_captcha_text
    check 'proposal_terms_of_service'

    click_button 'Create proposal'

    expect(page).to have_content 'Proposal created successfully.'
    expect(page).to have_content 'Testing auto link'
    expect(page).to have_link('www.example.org', href: 'http://www.example.org')
  end

  scenario 'JS injection is prevented but autolinking is respected' do
    author = create(:user)
    login_as(author)

    visit new_proposal_path
    fill_in 'proposal_title', with: 'Testing auto link'
    fill_in 'proposal_question', with: 'Should I stay or should I go?'
    fill_in 'proposal_summary', with: 'In summary, what we want is...'
    fill_in 'proposal_description', with: "<script>alert('hey')</script> <a href=\"javascript:alert('surprise!')\">click me<a/> http://example.org"
    fill_in 'proposal_responsible_name', with: 'Isabel Garcia'
    fill_in 'proposal_captcha', with: correct_captcha_text
    check 'proposal_terms_of_service'

    click_button 'Create proposal'

    expect(page).to have_content 'Proposal created successfully.'
    expect(page).to have_content 'Testing auto link'
    expect(page).to have_link('http://example.org', href: 'http://example.org')
    expect(page).not_to have_link('click me')
    expect(page.html).to_not include "<script>alert('hey')</script>"

    click_link 'Edit'

    expect(current_path).to eq edit_proposal_path(Proposal.last)
    expect(page).not_to have_link('click me')
    expect(page.html).to_not include "<script>alert('hey')</script>"
  end

  context 'Tagging' do
    let(:author) { create(:user) }

    background do
      login_as(author)
    end

    scenario 'Category tags', :js do
      education = create(:tag, name: 'Education', kind: 'category')
      health    = create(:tag, name: 'Health',    kind: 'category')

      visit new_proposal_path

      fill_in 'proposal_title', with: 'Help refugees'
      fill_in 'proposal_question', with: '¿Would you like to give assistance to war refugees?'
      fill_in 'proposal_summary', with: 'In summary, what we want is...'
      fill_in 'proposal_external_url', with: 'http://rescue.org/refugees'
      fill_in 'proposal_video_url', with: 'http://youtube.com'
      fill_in 'proposal_responsible_name', with: 'Isabel Garcia'
      fill_in 'proposal_captcha', with: correct_captcha_text
      check 'proposal_terms_of_service'

      find('.js-add-tag-link', text: 'Education').click
      click_button 'Create proposal'

      expect(page).to have_content 'Proposal created successfully.'

      within "#tags" do
        expect(page).to have_content 'Education'
        expect(page).to_not have_content 'Health'
      end
    end

    scenario 'Custom tags' do
      visit new_proposal_path

      fill_in 'proposal_title', with: 'Help refugees'
      fill_in 'proposal_question', with: '¿Would you like to give assistance to war refugees?'
      fill_in 'proposal_summary', with: 'In summary, what we want is...'
      fill_in 'proposal_description', with: 'This is very important because...'
      fill_in 'proposal_external_url', with: 'http://rescue.org/refugees'
      fill_in 'proposal_video_url', with: 'http://youtube.com'
      fill_in 'proposal_responsible_name', with: 'Isabel Garcia'
      fill_in 'proposal_captcha', with: correct_captcha_text
      check 'proposal_terms_of_service'

      fill_in 'proposal_tag_list', with: 'Refugees, Solidarity'
      click_button 'Create proposal'

      expect(page).to have_content 'Proposal created successfully.'
      within "#tags" do
        expect(page).to have_content 'Refugees'
        expect(page).to have_content 'Solidarity'
      end
    end

    scenario 'using dangerous strings' do
      author = create(:user)
      login_as(author)

      visit new_proposal_path

      fill_in 'proposal_title', with: 'A test of dangerous strings'
      fill_in 'proposal_question', with: '¿Would you like to give assistance to war refugees?'
      fill_in 'proposal_summary', with: 'In summary, what we want is...'
      fill_in 'proposal_description', with: 'A description suitable for this test'
      fill_in 'proposal_external_url', with: 'http://rescue.org/refugees'
      fill_in 'proposal_responsible_name', with: 'Isabel Garcia'
      fill_in 'proposal_captcha', with: correct_captcha_text
      check 'proposal_terms_of_service'

      fill_in 'proposal_tag_list', with: 'user_id=1, &a=3, <script>alert("hey");</script>'

      click_button 'Create proposal'

      expect(page).to have_content 'Proposal created successfully.'
      expect(page).to have_content 'user_id1'
      expect(page).to have_content 'a3'
      expect(page).to have_content 'scriptalert("hey");script'
      expect(page.html).to_not include 'user_id=1, &a=3, <script>alert("hey");</script>'
    end
  end

  context "Geozones" do

    scenario "Default whole city" do
      author = create(:user)
      login_as(author)

      visit new_proposal_path

      fill_in 'proposal_title', with: 'Help refugees'
      fill_in 'proposal_question', with: '¿Would you like to give assistance to war refugees?'
      fill_in 'proposal_summary', with: 'In summary, what we want is...'
      fill_in 'proposal_description', with: 'This is very important because...'
      fill_in 'proposal_external_url', with: 'http://rescue.org/refugees'
      fill_in 'proposal_video_url', with: 'http://youtube.com'
      fill_in 'proposal_responsible_name', with: 'Isabel Garcia'
      fill_in 'proposal_captcha', with: correct_captcha_text
      check 'proposal_terms_of_service'

      click_button 'Create proposal'

      expect(page).to have_content 'Proposal created successfully.'
      within "#geozone" do
        expect(page).to have_content 'All city'
      end
    end

    scenario "Specific geozone" do
      geozone = create(:geozone, name: 'California')
      geozone = create(:geozone, name: 'New York')
      author = create(:user)
      login_as(author)

      visit new_proposal_path

      fill_in 'proposal_title', with: 'Help refugees'
      fill_in 'proposal_question', with: '¿Would you like to give assistance to war refugees?'
      fill_in 'proposal_summary', with: 'In summary, what we want is...'
      fill_in 'proposal_description', with: 'This is very important because...'
      fill_in 'proposal_external_url', with: 'http://rescue.org/refugees'
      fill_in 'proposal_video_url', with: 'http://youtube.com'
      fill_in 'proposal_responsible_name', with: 'Isabel Garcia'
      fill_in 'proposal_captcha', with: correct_captcha_text
      check 'proposal_terms_of_service'

      select('California', from: 'proposal_geozone_id')
      click_button 'Create proposal'

      expect(page).to have_content 'Proposal created successfully.'
      within "#geozone" do
        expect(page).to have_content 'California'
      end
    end

  end

  scenario 'Update should not be posible if logged user is not the author' do
    proposal = create(:proposal)
    expect(proposal).to be_editable
    login_as(create(:user))

    visit edit_proposal_path(proposal)
    expect(current_path).not_to eq(edit_proposal_path(proposal))
    expect(current_path).to eq(proposals_path)
    expect(page).to have_content 'You do not have permission'
  end

  scenario 'Update should not be posible if proposal is not editable' do
    proposal = create(:proposal)
    Setting["max_votes_for_proposal_edit"] = 10
    11.times { create(:vote, votable: proposal) }

    expect(proposal).to_not be_editable

    login_as(proposal.author)
    visit edit_proposal_path(proposal)

    expect(current_path).not_to eq(edit_proposal_path(proposal))
    expect(current_path).to eq(proposals_path)
    expect(page).to have_content 'You do not have permission'
  end

  scenario 'Update should be posible for the author of an editable proposal' do
    proposal = create(:proposal)
    login_as(proposal.author)

    visit edit_proposal_path(proposal)
    expect(current_path).to eq(edit_proposal_path(proposal))

    fill_in 'proposal_title', with: "End child poverty"
    fill_in 'proposal_question', with: '¿Would you like to give assistance to war refugees?'
    fill_in 'proposal_summary', with: 'Basically...'
    fill_in 'proposal_description', with: "Let's do something to end child poverty"
    fill_in 'proposal_external_url', with: 'http://rescue.org/refugees'
    fill_in 'proposal_responsible_name', with: 'Isabel Garcia'
    fill_in 'proposal_captcha', with: correct_captcha_text

    click_button "Save changes"

    expect(page).to have_content "Proposal updated successfully."
    expect(page).to have_content "Basically..."
    expect(page).to have_content "End child poverty"
    expect(page).to have_content "Let's do something to end child poverty"
  end

  scenario 'Errors on update' do
    proposal = create(:proposal)
    login_as(proposal.author)

    visit edit_proposal_path(proposal)
    fill_in 'proposal_title', with: ""
    click_button "Save changes"

    expect(page).to have_content error_message
  end

  scenario 'Captcha is required to update a proposal' do
    proposal = create(:proposal)
    login_as(proposal.author)

    visit edit_proposal_path(proposal)
    expect(current_path).to eq(edit_proposal_path(proposal))

    fill_in 'proposal_title', with: "New cool title"
    fill_in 'proposal_captcha', with: "wrong!"
    click_button "Save changes"

    expect(page).to_not have_content "Proposal updated successfully."
    expect(page).to have_content "error"

    fill_in 'proposal_captcha', with: correct_captcha_text
    click_button "Save changes"

    expect(page).to have_content "Proposal updated successfully."
  end

  describe 'Limiting tags shown' do
    scenario 'Index page shows up to 5 tags per proposal' do
      create_featured_proposals
      tag_list = ["Hacienda", "Economía", "Medio Ambiente", "Corrupción", "Fiestas populares", "Prensa"]
      create :proposal, tag_list: tag_list

      visit proposals_path

      within('.proposal .tags') do
        expect(page).to have_content '1+'
      end
    end

    scenario 'Index page shows 3 tags with no plus link' do
      create_featured_proposals
      tag_list = ["Medio Ambiente", "Corrupción", "Fiestas populares"]
      create :proposal, tag_list: tag_list

      visit proposals_path

      within('.proposal .tags') do
        tag_list.each do |tag|
          expect(page).to have_content tag
        end
        expect(page).not_to have_content '+'
      end
    end
  end

  feature 'Proposal index order filters' do

    scenario 'Default order is hot_score', :js do
      create_featured_proposals

      create(:proposal, title: 'Best proposal').update_column(:hot_score, 10)
      create(:proposal, title: 'Worst proposal').update_column(:hot_score, 2)
      create(:proposal, title: 'Medium proposal').update_column(:hot_score, 5)

      visit proposals_path

      expect('Best proposal').to appear_before('Medium proposal')
      expect('Medium proposal').to appear_before('Worst proposal')
    end

    scenario 'Proposals are ordered by confidence_score', :js do
      create_featured_proposals

      create(:proposal, title: 'Best proposal').update_column(:confidence_score, 10)
      create(:proposal, title: 'Worst proposal').update_column(:confidence_score, 2)
      create(:proposal, title: 'Medium proposal').update_column(:confidence_score, 5)

      visit proposals_path
      click_link 'highest rated'
      expect(page).to have_selector('a.active', text: 'highest rated')

      within '#proposals' do
        expect('Best proposal').to appear_before('Medium proposal')
        expect('Medium proposal').to appear_before('Worst proposal')
      end

      expect(current_url).to include('order=confidence_score')
      expect(current_url).to include('page=1')
    end

    scenario 'Proposals are ordered by newest', :js do
      create_featured_proposals

      create(:proposal, title: 'Best proposal',   created_at: Time.now)
      create(:proposal, title: 'Medium proposal', created_at: Time.now - 1.hour)
      create(:proposal, title: 'Worst proposal',  created_at: Time.now - 1.day)

      visit proposals_path
      click_link 'newest'
      expect(page).to have_selector('a.active', text: 'newest')

      within '#proposals' do
        expect('Best proposal').to appear_before('Medium proposal')
        expect('Medium proposal').to appear_before('Worst proposal')
      end

      expect(current_url).to include('order=created_at')
      expect(current_url).to include('page=1')
    end
  end

  context "Search" do

    context "Basic search" do

      scenario 'Search by text' do
        proposal1 = create(:proposal, title: "Get Schwifty")
        proposal2 = create(:proposal, title: "Schwifty Hello")
        proposal3 = create(:proposal, title: "Do not show me")

        visit proposals_path

        within "#search_form" do
          fill_in "search", with: "Schwifty"
          click_button "Search"
        end

        within("#proposals") do
          expect(page).to have_css('.proposal', count: 2)

          expect(page).to have_content(proposal1.title)
          expect(page).to have_content(proposal2.title)
          expect(page).to_not have_content(proposal3.title)
        end
      end

      scenario 'Search by proposal code' do
        proposal1 = create(:proposal, title: "Get Schwifty")
        proposal2 = create(:proposal, title: "Schwifty Hello")

        visit proposals_path

        within "#search_form" do
          fill_in "search", with: proposal1.code
          click_button "Search"
        end

        within("#proposals") do
          expect(page).to have_css('.proposal', count: 1)

          expect(page).to have_content(proposal1.title)
          expect(page).to_not have_content(proposal2.title)
        end
      end

      scenario "Maintain search criteria" do
        visit proposals_path

        within "#search_form" do
          fill_in "search", with: "Schwifty"
          click_button "Search"
        end

        expect(page).to have_selector("input[name='search'][value='Schwifty']")
      end

    end

    context "Advanced search" do

      scenario "Search by text", :js do
        proposal1 = create(:proposal, title: "Get Schwifty")
        proposal2 = create(:proposal, title: "Schwifty Hello")
        proposal3 = create(:proposal, title: "Do not show me")

        visit proposals_path

        click_link "Advanced search"
        fill_in "Write the text", with: "Schwifty"
        click_button "Filter"

        expect(page).to have_content("There are 2 citizen proposals")

        within("#proposals") do

          expect(page).to have_content(proposal1.title)
          expect(page).to have_content(proposal2.title)
          expect(page).to_not have_content(proposal3.title)
        end
      end

      context "Search by author type" do

        scenario "Public employee", :js do
          ana = create :user, official_level: 1
          john = create :user, official_level: 2

          proposal1 = create(:proposal, author: ana)
          proposal2 = create(:proposal, author: ana)
          proposal3 = create(:proposal, author: john)

          visit proposals_path

          click_link "Advanced search"
          select "Public employee", from: "advanced_search_official_level"
          click_button "Filter"

          expect(page).to have_content("There are 2 citizen proposals")

          within("#proposals") do
            expect(page).to have_content(proposal1.title)
            expect(page).to have_content(proposal2.title)
            expect(page).to_not have_content(proposal3.title)
          end
        end

        scenario "Municipal Organization", :js do
          ana = create :user, official_level: 2
          john = create :user, official_level: 3

          proposal1 = create(:proposal, author: ana)
          proposal2 = create(:proposal, author: ana)
          proposal3 = create(:proposal, author: john)

          visit proposals_path

          click_link "Advanced search"
          select "Municipal Organization", from: "advanced_search_official_level"
          click_button "Filter"

          expect(page).to have_content("There are 2 citizen proposals")

          within("#proposals") do
            expect(page).to have_content(proposal1.title)
            expect(page).to have_content(proposal2.title)
            expect(page).to_not have_content(proposal3.title)
          end
        end

        scenario "General director", :js do
          ana = create :user, official_level: 3
          john = create :user, official_level: 4

          proposal1 = create(:proposal, author: ana)
          proposal2 = create(:proposal, author: ana)
          proposal3 = create(:proposal, author: john)

          visit proposals_path

          click_link "Advanced search"
          select "General director", from: "advanced_search_official_level"
          click_button "Filter"

          expect(page).to have_content("There are 2 citizen proposals")

          within("#proposals") do
            expect(page).to have_content(proposal1.title)
            expect(page).to have_content(proposal2.title)
            expect(page).to_not have_content(proposal3.title)
          end
        end

        scenario "City councillor", :js do
          ana = create :user, official_level: 4
          john = create :user, official_level: 5

          proposal1 = create(:proposal, author: ana)
          proposal2 = create(:proposal, author: ana)
          proposal3 = create(:proposal, author: john)

          visit proposals_path

          click_link "Advanced search"
          select "City councillor", from: "advanced_search_official_level"
          click_button "Filter"

          expect(page).to have_content("There are 2 citizen proposals")

          within("#proposals") do
            expect(page).to have_content(proposal1.title)
            expect(page).to have_content(proposal2.title)
            expect(page).to_not have_content(proposal3.title)
          end
        end

        scenario "Mayoress", :js do
          ana = create :user, official_level: 5
          john = create :user, official_level: 4

          proposal1 = create(:proposal, author: ana)
          proposal2 = create(:proposal, author: ana)
          proposal3 = create(:proposal, author: john)

          visit proposals_path

          click_link "Advanced search"
          select "Mayoress", from: "advanced_search_official_level"
          click_button "Filter"

          expect(page).to have_content("There are 2 citizen proposals")

          within("#proposals") do
            expect(page).to have_content(proposal1.title)
            expect(page).to have_content(proposal2.title)
            expect(page).to_not have_content(proposal3.title)
          end
        end

      end

      context "Search by date" do

        context "Predefined date ranges" do

          scenario "Last day", :js do
            proposal1 = create(:proposal, created_at: 1.minute.ago)
            proposal2 = create(:proposal, created_at: 1.hour.ago)
            proposal3 = create(:proposal, created_at: 2.days.ago)

            visit proposals_path

            click_link "Advanced search"
            select "Last 24 hours", from: "js-advanced-search-date-min"
            click_button "Filter"

            expect(page).to have_content("There are 2 citizen proposals")

            within("#proposals") do
              expect(page).to have_content(proposal1.title)
              expect(page).to have_content(proposal2.title)
              expect(page).to_not have_content(proposal3.title)
            end
          end

          scenario "Last week", :js do
            proposal1 = create(:proposal, created_at: 1.day.ago)
            proposal2 = create(:proposal, created_at: 5.days.ago)
            proposal3 = create(:proposal, created_at: 8.days.ago)

            visit proposals_path

            click_link "Advanced search"
            select "Last week", from: "js-advanced-search-date-min"
            click_button "Filter"

            expect(page).to have_content("There are 2 citizen proposals")

            within("#proposals") do
              expect(page).to have_content(proposal1.title)
              expect(page).to have_content(proposal2.title)
              expect(page).to_not have_content(proposal3.title)
            end
          end

          scenario "Last month", :js do
            proposal1 = create(:proposal, created_at: 10.days.ago)
            proposal2 = create(:proposal, created_at: 20.days.ago)
            proposal3 = create(:proposal, created_at: 33.days.ago)

            visit proposals_path

            click_link "Advanced search"
            select "Last month", from: "js-advanced-search-date-min"
            click_button "Filter"

            expect(page).to have_content("There are 2 citizen proposals")

            within("#proposals") do
              expect(page).to have_content(proposal1.title)
              expect(page).to have_content(proposal2.title)
              expect(page).to_not have_content(proposal3.title)
            end
          end

          scenario "Last year", :js do
            proposal1 = create(:proposal, created_at: 300.days.ago)
            proposal2 = create(:proposal, created_at: 350.days.ago)
            proposal3 = create(:proposal, created_at: 370.days.ago)

            visit proposals_path

            click_link "Advanced search"
            select "Last year", from: "js-advanced-search-date-min"
            click_button "Filter"

            expect(page).to have_content("There are 2 citizen proposals")

            within("#proposals") do
              expect(page).to have_content(proposal1.title)
              expect(page).to have_content(proposal2.title)
              expect(page).to_not have_content(proposal3.title)
            end
          end

        end

        scenario "Search by custom date range", :js do
          proposal1 = create(:proposal, created_at: 2.days.ago)
          proposal2 = create(:proposal, created_at: 3.days.ago)
          proposal3 = create(:proposal, created_at: 9.days.ago)

          visit proposals_path

          click_link "Advanced search"
          select "Customized", from: "js-advanced-search-date-min"
          fill_in "advanced_search_date_min", with: 7.days.ago
          fill_in "advanced_search_date_max", with: 1.days.ago
          click_button "Filter"

          expect(page).to have_content("There are 2 citizen proposals")

          within("#proposals") do
            expect(page).to have_content(proposal1.title)
            expect(page).to have_content(proposal2.title)
            expect(page).to_not have_content(proposal3.title)
          end
        end

        scenario "Search by multiple filters", :js do
          ana  = create :user, official_level: 1
          john = create :user, official_level: 1

          proposal1 = create(:proposal, title: "Get Schwifty",   author: ana,  created_at: 1.minute.ago)
          proposal2 = create(:proposal, title: "Hello Schwifty", author: john, created_at: 2.days.ago)
          proposal3 = create(:proposal, title: "Save the forest")

          visit proposals_path

          click_link "Advanced search"
          fill_in "Write the text", with: "Schwifty"
          select "Public employee", from: "advanced_search_official_level"
          select "Last 24 hours",   from: "js-advanced-search-date-min"

          click_button "Filter"

          expect(page).to have_content("There is 1 citizen proposal")

          within("#proposals") do
            expect(page).to have_content(proposal1.title)
          end
        end

        scenario "Maintain advanced search criteria", :js do
          visit proposals_path
          click_link "Advanced search"

          fill_in "Write the text", with: "Schwifty"
          select "Public employee", from: "advanced_search_official_level"
          select "Last 24 hours", from: "js-advanced-search-date-min"

          click_button "Filter"

          expect(page).to have_content("citizen proposals cannot be found")

          within "#js-advanced-search" do
            expect(page).to have_selector("input[name='search'][value='Schwifty']")
            expect(page).to have_select('advanced_search[official_level]', selected: 'Public employee')
            expect(page).to have_select('advanced_search[date_min]', selected: 'Last 24 hours')
          end
        end

        scenario "Maintain custom date search criteria", :js do
          visit proposals_path
          click_link "Advanced search"

          select "Customized", from: "js-advanced-search-date-min"
          fill_in "advanced_search_date_min", with: 7.days.ago.to_date
          fill_in "advanced_search_date_max", with: 1.days.ago.to_date
          click_button "Filter"

          expect(page).to have_content("citizen proposals cannot be found")

          within "#js-advanced-search" do
            expect(page).to have_select('advanced_search[date_min]', selected: 'Customized')
            expect(page).to have_selector("input[name='advanced_search[date_min]'][value*='#{7.days.ago.strftime('%Y-%m-%d')}']")
            expect(page).to have_selector("input[name='advanced_search[date_max]'][value*='#{1.day.ago.strftime('%Y-%m-%d')}']")
          end
        end

      end
    end

    scenario "Order by relevance by default", :js do
      proposal1 = create(:proposal, title: "Show you got",      cached_votes_up: 10)
      proposal2 = create(:proposal, title: "Show what you got", cached_votes_up: 1)
      proposal3 = create(:proposal, title: "Show you got",      cached_votes_up: 100)

      visit proposals_path
      fill_in "search", with: "Show what you got"
      click_button "Search"

      expect(page).to have_selector("a.active", text: "relevance")

      within("#proposals") do
        expect(all(".proposal")[0].text).to match "Show what you got"
        expect(all(".proposal")[1].text).to match "Show you got"
        expect(all(".proposal")[2].text).to match "Show you got"
      end
    end

    scenario "Reorder results maintaing search", :js do
      proposal1 = create(:proposal, title: "Show you got",      cached_votes_up: 10,  created_at: 1.week.ago)
      proposal2 = create(:proposal, title: "Show what you got", cached_votes_up: 1,   created_at: 1.month.ago)
      proposal3 = create(:proposal, title: "Show you got",      cached_votes_up: 100, created_at: Time.now)
      proposal4 = create(:proposal, title: "Do not display",    cached_votes_up: 1,   created_at: 1.week.ago)

      visit proposals_path
      fill_in "search", with: "Show what you got"
      click_button "Search"
      click_link 'newest'
      expect(page).to have_selector("a.active", text: "newest")

      within("#proposals") do
        expect(all(".proposal")[0].text).to match "Show you got"
        expect(all(".proposal")[1].text).to match "Show you got"
        expect(all(".proposal")[2].text).to match "Show what you got"
        expect(page).to_not have_content "Do not display"
      end
    end

    scenario 'After a search do not show featured proposals' do
      featured_proposals = create_featured_proposals
      proposal = create(:proposal, title: "Abcdefghi")

      visit proposals_path
      within "#search_form" do
        fill_in "search", with: proposal.title
        click_button "Search"
      end

      expect(page).to_not have_selector('#proposals .proposal-featured')
      expect(page).to_not have_selector('#featured-proposals')
    end

  end

  scenario 'Index tag does not show featured proposals' do
    featured_proposals = create_featured_proposals
    proposal = create(:proposal, tag_list: "123")

    visit proposals_path(tag: "123")

    expect(page).to_not have_selector('#proposals .proposal-featured')
    expect(page).to_not have_selector('#featured-proposals')
  end

  scenario 'Conflictive' do
    good_proposal = create(:proposal)
    conflictive_proposal = create(:proposal, :conflictive)

    visit proposal_path(conflictive_proposal)
    expect(page).to have_content "This proposal has been flagged as inappropriate by several users."

    visit proposal_path(good_proposal)
    expect(page).to_not have_content "This proposal has been flagged as inappropriate by several users."
  end

  scenario "Flagging", :js do
    user = create(:user)
    proposal = create(:proposal)

    login_as(user)
    visit proposal_path(proposal)

    within "#proposal_#{proposal.id}" do
      page.find("#flag-expand-proposal-#{proposal.id}").click
      page.find("#flag-proposal-#{proposal.id}").click

      expect(page).to have_css("#unflag-expand-proposal-#{proposal.id}")
    end

    expect(Flag.flagged?(user, proposal)).to be
  end

  scenario "Unflagging", :js do
    user = create(:user)
    proposal = create(:proposal)
    Flag.flag(user, proposal)

    login_as(user)
    visit proposal_path(proposal)

    within "#proposal_#{proposal.id}" do
      page.find("#unflag-expand-proposal-#{proposal.id}").click
      page.find("#unflag-proposal-#{proposal.id}").click

      expect(page).to have_css("#flag-expand-proposal-#{proposal.id}")
    end

    expect(Flag.flagged?(user, proposal)).to_not be
  end

  scenario 'Erased author' do
    user = create(:user)
    proposal = create(:proposal, author: user)
    user.erase

    visit proposals_path
    expect(page).to have_content('User deleted')

    visit proposal_path(proposal)
    expect(page).to have_content('User deleted')

    create_featured_proposals

    visit proposals_path
    expect(page).to have_content('User deleted')
  end

  context "Filter" do

    scenario "By category" do
      education = create(:tag, name: 'Education', kind: 'category')
      health    = create(:tag, name: 'Health',    kind: 'category')

      proposal1 = create(:proposal, tag_list: education.name)
      proposal2 = create(:proposal, tag_list: health.name)

      visit proposals_path

      within "#categories" do
        click_link "Education"
      end

      within("#proposals") do
        expect(page).to have_css('.proposal', count: 1)
        expect(page).to have_content(proposal1.title)
      end
    end

    context "By geozone" do

      background do
        @california = Geozone.create(name: "California")
        @new_york   = Geozone.create(name: "New York")

        @proposal1 = create(:proposal, geozone: @california)
        @proposal2 = create(:proposal, geozone: @california)
        @proposal3 = create(:proposal, geozone: @new_york)
      end

      scenario "From map" do
        visit proposals_path

        click_link "map"
        within("#html_map") do
          url = find("area[title='California']")[:href]
          visit url
        end

        within("#proposals") do
          expect(page).to have_css('.proposal', count: 2)
          expect(page).to have_content(@proposal1.title)
          expect(page).to have_content(@proposal2.title)
          expect(page).to_not have_content(@proposal3.title)
        end
      end

      scenario "From geozone list" do
        visit proposals_path

        click_link "map"
        within("#geozones") do
          click_link "California"
        end
        within("#proposals") do
          expect(page).to have_css('.proposal', count: 2)
          expect(page).to have_content(@proposal1.title)
          expect(page).to have_content(@proposal2.title)
          expect(page).to_not have_content(@proposal3.title)
        end
      end

      scenario "From proposal" do
        visit proposal_path(@proposal1)

        within("#geozone") do
          click_link "California"
        end

        within("#proposals") do
          expect(page).to have_css('.proposal', count: 2)
          expect(page).to have_content(@proposal1.title)
          expect(page).to have_content(@proposal2.title)
          expect(page).to_not have_content(@proposal3.title)
        end
      end

    end
  end

  context 'Suggesting proposals' do
    scenario 'Show up to 5 suggestions', :js do
      author = create(:user)
      login_as(author)

      create(:proposal, title: 'First proposal, has search term')
      create(:proposal, title: 'Second title')
      create(:proposal, title: 'Third proposal, has search term')
      create(:proposal, title: 'Fourth proposal, has search term')
      create(:proposal, title: 'Fifth proposal, has search term')
      create(:proposal, title: 'Sixth proposal, has search term')
      create(:proposal, title: 'Seventh proposal, has search term')

      visit new_proposal_path
      fill_in 'proposal_title', with: 'search'
      check "proposal_terms_of_service"

      within('div#js-suggest') do
        expect(page).to have_content ("You are seeing 5 of 6 proposals containing the term 'search'")
      end
    end

    scenario 'No found suggestions', :js do
      author = create(:user)
      login_as(author)

      create(:proposal, title: 'First proposal').update_column(:confidence_score, 10)
      create(:proposal, title: 'Second proposal').update_column(:confidence_score, 8)

      visit new_proposal_path
      fill_in 'proposal_title', with: 'debate'
      check "proposal_terms_of_service"

      within('div#js-suggest') do
        expect(page).to_not have_content ('You are seeing')
      end
    end
  end

  context "Summary" do

    scenario "Displays proposals grouped by category" do
      create(:tag, kind: 'category', name: 'Culture')
      create(:tag, kind: 'category', name: 'Social Services')

      3.times { create(:proposal, tag_list: 'Culture') }
      3.times { create(:proposal, tag_list: 'Social Services') }

      create(:proposal, tag_list: 'Random')

      visit proposals_path
      click_link "The most supported proposals by category"

      within("#culture") do
        expect(page).to have_content("Culture")
        expect(page).to have_css(".proposal", count: 3)
      end

      within("#social-services") do
        expect(page).to have_content("Social Services")
        expect(page).to have_css(".proposal", count: 3)
      end
    end

    scenario "Displays proposals grouped by district" do
      california = create(:geozone, name: 'California')
      new_york   = create(:geozone, name: 'New York')

      3.times { create(:proposal, geozone: california) }
      3.times { create(:proposal, geozone: new_york) }

      visit proposals_path
      click_link "The most supported proposals by category"

      within("#california") do
        expect(page).to have_content("California")
        expect(page).to have_css(".proposal", count: 3)
      end

      within("#new-york") do
        expect(page).to have_content("New York")
        expect(page).to have_css(".proposal", count: 3)
      end
    end

    scenario "Displays a maximum of 3 proposals per category" do
      create(:tag, kind: 'category', name: 'culture')
      4.times { create(:proposal, tag_list: 'culture') }

      visit summary_proposals_path

      expect(page).to have_css(".proposal", count: 3)
    end

    scenario "Orders proposals by votes" do
      create(:tag, kind: 'category', name: 'culture')
      create(:proposal, title: 'Best',   tag_list: 'culture').update_column(:confidence_score, 10)
      create(:proposal, title: 'Worst',  tag_list: 'culture').update_column(:confidence_score, 2)
      create(:proposal, title: 'Medium', tag_list: 'culture').update_column(:confidence_score, 5)

      visit summary_proposals_path

      expect('Best').to appear_before('Medium')
      expect('Medium').to appear_before('Worst')
    end

    scenario "Displays proposals from last week" do
      create(:tag, kind: 'category', name: 'culture')
      proposal1 = create(:proposal, tag_list: 'culture', created_at: 1.day.ago)
      proposal2 = create(:proposal, tag_list: 'culture', created_at: 5.days.ago)
      proposal3 = create(:proposal, tag_list: 'culture', created_at: 8.days.ago)

      visit summary_proposals_path

      within("#proposals") do
        expect(page).to have_css('.proposal', count: 2)

        expect(page).to have_content(proposal1.title)
        expect(page).to have_content(proposal2.title)
        expect(page).to_not have_content(proposal3.title)
      end
    end

  end

end
