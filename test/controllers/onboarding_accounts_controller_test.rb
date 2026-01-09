require "test_helper"

class OnboardingAccountsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get onboarding_accounts_new_url
    assert_response :success
  end

  test "should get create" do
    get onboarding_accounts_create_url
    assert_response :success
  end
end
