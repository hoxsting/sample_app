require 'spec_helper'

describe "FriendlyForwardings" do

  it "devrait rediriger vers la page voulue apres identification" do
    user = Factory(:user)
    visit edit_user_path(user)
    # Le test suit automatiquement la redirection vers la page d'identification.
    fill_in :session_email,    :with => user.email
    fill_in :session_password, :with => user.password
    click_button
    # Le test suit a nouveau la redirection, cette fois vers users/edit.
    response.should render_template('users/edit')
  end

end
