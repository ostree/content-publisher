# frozen_string_literal: true

class ContactsController < ApplicationController
  def search
    @document = Document.with_current_edition.find_by_param(params[:id])
    @contacts_by_organisation = ContactsService.new.all_by_organisation
  rescue GdsApi::BaseError => e
    GovukError.notify(e)
    render "search_api_down", status: :service_unavailable
  end

  def insert
    Document.transaction do # rubocop:disable Metrics/BlockLength
      document = Document.with_current_edition.lock.find_by_param(params[:id])

      redirect_location = edit_document_path(document) + "#body"

      unless params[:contact_id]
        redirect_to redirect_location
        return
      end

      contact_markdown = "[Contact:#{params[:contact_id]}]\n"
      current_revision = document.current_edition.revision

      body = current_revision.contents.fetch("body", "").chomp
      updated_body = if body.present?
                       "#{body}\n\n#{contact_markdown}"
                     else
                       contact_markdown
                     end

      next_revision = current_revision.build_revision_update(
        { contents: current_revision.contents.merge("body" => updated_body) },
        current_user,
      )

      if next_revision != current_revision
        current_edition = document.current_edition
        current_edition.assign_revision(next_revision, current_user).save!

        TimelineEntry.create_for_revision(entry_type: :updated_content,
                                          edition: current_edition)

        PreviewService.new(current_edition).try_create_preview
      end

      redirect_to redirect_location
    end
  end
end