# frozen_string_literal: true

require "spec_helper"

RSpec.feature "Edit a document" do
  DocumentTypeSchema.all.each do |schema|
    next if schema.managed_elsewhere

    scenario "User edits #{schema.name}" do
      @schema = schema

      given_there_is_a_document
      when_i_go_to_edit_the_document
      and_i_fill_in_the_content_fields
      then_i_see_the_document_is_saved
      and_the_preview_creation_succeeded
    end

    def given_there_is_a_document
      create(:document, document_type: @schema.id)
    end

    def when_i_go_to_edit_the_document
      visit document_path(Document.last)
      click_on "Edit document"
      @lookup_base_path_request = publishing_api_has_lookups(Document.last.title => Document.last.content_id)
      @put_content_request = stub_publishing_api_put_content(Document.last.content_id, {})
    end

    def and_i_fill_in_the_content_fields
      @schema.contents.each do |field|
        if field.type == "govspeak"
          fill_in "document[contents][#{field.id}]", with: "Some govspeak text."
        else
          raise "You'll have to write some code here to fill in a #{field.type} field"
        end
      end

      fill_in "document[summary]", with: "A summary of the release."
      click_on "Save"
    end

    def then_i_see_the_document_is_saved
      expect(page).to have_content "A summary of the release."

      @schema.contents.each do |field|
        if field.type == "govspeak"
          expect(page).to have_content "Some govspeak text."
        else
          raise "You'll have to write some code here to test a #{field.type} field"
        end
      end
    end

    def and_the_preview_creation_succeeded
      expect(@lookup_base_path_request).to have_been_requested
      expect(@put_content_request).to have_been_requested
      expect(page).to have_content "Preview creation successful"

      expect(a_request(:put, /content/).with { |req|
        expect(req.body).to be_valid_against_schema(@schema.publishing_metadata.schema_name)
        expect(JSON.parse(req.body)["description"]).to eq "A summary of the release."
      }).to have_been_requested
    end
  end
end
