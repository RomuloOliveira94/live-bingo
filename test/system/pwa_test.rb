require "application_system_test_case"

class PwaSystemTest < ApplicationSystemTestCase
  test "home has pwa manifest link" do
    visit root_path
    assert_selector 'link[rel="manifest"][href="/manifest.json"]', visible: false
  end

  test "home has theme color meta" do
    visit root_path
    assert_selector 'meta[name="theme-color"][content="#141414"]', visible: false
  end

  test "home has favicon ico link" do
    visit root_path
    assert_selector 'link[rel="icon"][href="/favicon.ico"]', visible: false
  end

  test "home has apple touch icon link" do
    visit root_path
    assert_selector 'link[rel="apple-touch-icon"][href="/apple-touch-icon.png"]', visible: false
  end
end
