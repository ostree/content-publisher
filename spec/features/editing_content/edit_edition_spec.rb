# frozen_string_literal: true

RSpec.feature "Edit an edition" do
  scenario do
    given_there_is_an_edition
    when_i_go_to_edit_the_edition
    and_i_fill_in_the_content_fields
    then_i_see_the_edition_is_saved
    and_the_preview_creation_succeeded
    and_i_see_i_was_the_last_user_to_edit_the_edition
    and_i_see_the_timeline_entry
  end

  def given_there_is_an_edition
    body_field = DocumentType::BodyField.new
    document_type = build(:document_type, contents: [body_field])
    contents = { body: "Existing body" }
    @edition = create(:edition, document_type_id: document_type.id, contents: contents)
  end

  def when_i_go_to_edit_the_edition
    visit document_path(@edition.document)
    expect(page).to have_content("Existing body")
    click_on "Change Content"
  end

  def and_i_fill_in_the_content_fields
    fill_in "revision[contents][body]", with: "Edited body."
    stub_publishing_api_put_content(@edition.content_id, {})
    click_on "Save"
  end

  def then_i_see_the_edition_is_saved
    expect(page).to have_content("Edited body.")
  end

  def and_the_preview_creation_succeeded
    expect(page).to have_content(I18n.t!("user_facing_states.draft.name"))

    expect(a_request(:put, /content/).with { |req|
      expect(JSON.parse(req.body)["details"]["body"]).to eq("<p>Edited body.</p>\n")
    }).to have_been_requested
  end

  def and_i_see_i_was_the_last_user_to_edit_the_edition
    editor = current_user.name
    last_edited = I18n.t!("documents.show.metadata.last_edited_by") + ": #{editor}"
    expect(page).to have_content(last_edited)
  end

  def and_i_see_the_timeline_entry
    click_on "Document history"
    within first(".app-timeline-entry") do
      expect(page).to have_content I18n.t!("documents.history.entry_types.updated_content")
    end
  end
end
