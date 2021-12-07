require 'test_helper'

class UsersLoginTest < ActionDispatch::IntegrationTest
  def setup
    # take the data from fixtures/users.yml
    @user = users(:michael)
  end

  test 'login with invalid information' do
    # 1. get login path
    get login_path
    # 2. show properly session form
    assert_template 'sessions/new'
    # 3. post invalid info to login path
    post login_path, params: { session: { email: '', password: '' } }
    # 4. show new session page properly
    assert_template 'sessions/new'
    # 5. confirm flash message
    assert_not flash.empty?
    # 6. move to another page for now
    get root_path
    # 7. confirm no flash message in the page.
    assert flash.empty?
  end

  test 'login with valid email/invalid password' do
    get login_path
    assert_template 'sessions/new'
    post login_path, params: { session: {
      email: @user.email,
      password: 'invalid'
    } }
    assert_template 'sessions/new'
    assert_not flash.empty?
    get root_path
    assert flash.empty?
  end

  test 'login with valid information' do
    get login_path
    post login_path, params: { session: {
      email: @user.email,
      password: 'password'
      } }
    # check redirect destination is @user or not
    assert_redirected_to @user
    # move to the redirect destination
    follow_redirect!
    # show users/show properly or not
    assert_template 'users/show'
    # check the page doesn't show login_path
    assert_select 'a[href=?]', login_path, count: 0
    # check the page shows logout and profile
    assert_select 'a[href=?]', logout_path
    assert_select 'a[href=?]', user_path(@user)
  end
end
