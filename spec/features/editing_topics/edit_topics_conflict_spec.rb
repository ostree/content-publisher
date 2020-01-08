# frozen_string_literal: true

RSpec.feature "Edit topics when there is a conflict" do
  include TopicsHelper

  scenario do
    given_there_is_an_edition
    when_i_visit_the_topics_page
    given_the_remote_has_changed
    when_i_click_save
    then_i_see_an_error_message
  end

  def given_there_is_an_edition
    @edition = create :edition
  end

  def when_i_visit_the_topics_page
    stub_publishing_api_has_links(
      "content_id" => @edition.content_id,
      "links" => {
        "taxons" => [],
      },
      "version" => 3,
    )

    stub_publishing_api_has_taxonomy
    visit topics_path(@edition.document)
  end

  def given_the_remote_has_changed
    stub_publishing_api_patch_links_conflict(
      @edition.content_id,
      "links" => {
        "taxons" => [],
        "topics" => [],
      },
      "previous_version" => 3,
    )
  end

  def when_i_click_save
    click_on "Save"
  end

  def then_i_see_an_error_message
    expect(page).to have_content(I18n.t!("topics.edit.flashes.topic_update_conflict.title"))
    expect(current_path).to eq(topics_path(@edition.document))
  end
end