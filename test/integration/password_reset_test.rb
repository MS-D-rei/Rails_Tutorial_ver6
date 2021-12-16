require 'test_helper'

class PasswordResetsTest < ActionDispatch::IntegrationTest
  def setup
    ActionMailer::Base.deliveries.clear
    @user = users(:michael)
  end

  test 'password resets' do
    get new_password_reset_url
    assert_template 'password_resets/new'
    assert_select 'input[name=?]', 'password_reset[email]'
    # invalid email
    post password_resets_path, params: { password_reset: { email: '' } }
    assert_template 'password_resets/new'
    # valid email
    post password_resets_path, params: { password_reset: { email: @user.email } }
    assert_not_equal @user.reset_digest, @user.reload.reset_digest
    assert_equal 1, ActionMailer::Base.deliveries.size
    assert_not flash.empty?
    assert_redirected_to root_url
    # reset email with invalid addresss
    user = assigns(:user)
    get edit_password_reset_url(user.reset_token, email: '')
    assert_redirected_to root_url
    # invalid user
    user.toggle!(:activated)
    get edit_password_reset_url(user.reset_token, email: user.email)
    assert_redirected_to root_url
    user.toggle!(:activated)
    # valid mail address but invalid token
    get edit_password_reset_url('wrong token', email: user.email)
    assert_redirected_to root_url
    # valid email and token
    get edit_password_reset_url(user.reset_token, email: user.email)
    assert_template 'password_resets/edit'
    assert_select 'input[name=email][type=hidden][value=?]', user.email
    # invalid password
    patch password_reset_url(user.reset_token), params: {
      email: user.email,
      user: {
        password: 'foobaz',
        password_confirmation: 'barquux'
      }
    }
    assert_select 'div#error_explanation'
    # blank password
    patch password_reset_url(user.reset_token), params: {
      email: user.email,
      user: {
        password: '',
        password_confirmation: ''
      }
    }
    assert_select 'div#error_explanation'
    # valid password
    patch password_reset_url(user.reset_token), params: {
      email: user.email,
      user: {
        password: 'foobaz',
        password_confirmation: 'foobaz'
      }
    }
    assert is_logged_in?
    assert_nil user.reload.reset_digest
    assert_not flash.empty?
    assert_redirected_to user
  end

  test 'expired token' do
    get new_password_reset_path
    post password_resets_path, params: { password_reset: { email: @user.email } }
    @user = assigns(:user)
    @user.update_attribute(:reset_sent_at, 3.hours.ago)
    patch password_reset_path(@user.reset_token), params: {
      email: @user.email,
      user: {
        password: 'foobar',
        password_confirmation: 'foobar'
      }
    }
    assert_response :redirect
    follow_redirect!
    assert_match /expired/i, response.body
  end
end
