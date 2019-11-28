# frozen_string_literal: true

class ResyncService < ApplicationService
  attr_reader :document

  def initialize(document)
    @document = document
  end

  def call
    if document.live_edition.present?
      resync(document.live_edition)
      return if document.current_edition == document.live_edition
    end

    resync(document.current_edition)
  rescue GdsApi::BaseError => e
    GovukError.notify(e)
    raise
  end

private

  def reserve_base_path(edition)
    # Reserves a path for a publishing application, in case it has
    # been imported from Whitehall. There's no harm in calling
    # this even if we already own the path.
    GdsApi.publishing_api_v2.put_path(
      edition.base_path,
      publishing_app: "content-publisher",
      override_existing: true,
    )
  end

  def resync(edition)
    # has to be done for each edition in case base_path differs
    reserve_base_path(edition)

    if edition.withdrawn?
      resync_live_withdrawn(edition)
    elsif edition.published? || edition.published_but_needs_2i?
      resync_live(edition)
    elsif edition.draft? || edition.submitted_for_review?
      resync_draft(edition)
    end
  end

  def resync_live_withdrawn(edition)
    # Present to publishing API and Asset Manager draft stack
    PreviewService.call(edition)

    GdsApi.publishing_api_v2.unpublish(
      edition.content_id,
      type: "withdrawal",
      explanation: GovspeakDocument.new(edition.status.details, edition).payload_html,
      locale: edition.locale,
    )
  end

  def resync_live(edition)
    payload = PreviewService::Payload.new(edition).payload

    # This will create a new draft with an `update_type: "republish"`.
    GdsApi.publishing_api_v2.put_content(
      edition.document.content_id,
      payload.merge(update_type: "republish", bulk_publishing: true),
    )

    # Publish assets to live stack before we publish the document,
    # otherwise we risk referencing assets that aren't visible yet.
    PublishAssetService.call(edition, nil)

    # Finally, publish the doc (promote from draft stack to live)
    GdsApi.publishing_api_v2.publish(
      edition.document.content_id,
      nil, # Sending update_type is deprecated (now in payload)
      locale: edition.document.locale,
    )

    edition.update!(revision_synced: true)
  end

  def resync_draft(edition)
    # Present to publishing API and Asset Manager draft stack
    PreviewService.call(edition)
  end
end
