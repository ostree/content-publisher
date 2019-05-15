# frozen_string_literal: true

RSpec.feature "Preview file attachment when unavailable" do
  scenario do
    given_there_is_an_edition_with_attachments
    when_i_preview_the_attachment
    then_i_should_see_a_pending_page
    and_the_preview_creation_was_successful
  end

  def given_there_is_an_edition_with_attachments
    body_field = build(:field, id: "body", type: "govspeak")
    document_type = build(:document_type, contents: [body_field])
    @attachment_revision = create(:file_attachment_revision, assets: [])
    @asset = @attachment_revision.asset("file")

    @edition = create(:edition,
                      document_type_id: document_type.id,
                      file_attachment_revisions: [@attachment_revision])
  end

  def when_i_preview_the_attachment
    @request = stub_asset_manager_receives_an_asset(filename: /.*/)
    visit edit_document_path(@edition.document)
    find("markdown-toolbar details").click
    click_on "Attachment"
    click_on "Preview"
  end

  def then_i_should_see_a_pending_page
    expect(page).to have_content I18n.t!("file_attachments.preview_pending.title")
  end

  def and_the_preview_creation_was_successful
    expect(@request).to have_been_requested
  end
end