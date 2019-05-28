# frozen_string_literal: true

class ScheduleController < ApplicationController
  def save_scheduled_publishing_datetime
    Edition.find_and_lock_current(document: params[:document]) do |edition|
      checker = Requirements::ScheduledDatetimeChecker.new(permitted_params)
      issues = checker.pre_submit_issues

      if issues.any?
        flash["alert_with_items"] = {
          "title" => I18n.t!("requirements.scheduled_datetime.title"),
          "items" => issues.items(
            link_options: {
              scheduled_datetime: { href: "#scheduled_publishing_datetime" },
            },
          ),
        }

        render :scheduling,
               assigns: { edition: edition, issues: issues },
               status: :unprocessable_entity
      else
        set_scheduled_publishing_datetime(edition, checker.parsed_datetime)
        redirect_to document_path(edition.document)
      end
    end
  end

  def clear_scheduled_publishing_datetime
    Edition.find_and_lock_current(document: params[:document]) do |edition|
      set_scheduled_publishing_datetime(edition)

      redirect_to document_path(edition.document)
    end
  end

  def confirmation
    @edition = Edition.find_current(document: params[:document])

    unless @edition.schedulable?
      # FIXME: this shouldn't be an exception but we've not worked out the
      # right response - maybe bad request or a redirect with flash?
      raise "Scheduled publishing date and time must be at least 15 minutes in the future."
    end
  end

  def schedule
    Edition.find_and_lock_current(document: params[:document]) do |edition|
      if params[:review_status].blank?
        issues = Requirements::CheckerIssues.new([
          Requirements::Issue.new(:scheduling, :not_selected),
        ])

        flash.now["alert_with_items"] = {
          "title" => I18n.t!("requirements.scheduled_datetime.title"),
          "items" => issues.items,
        }

        render :confirmation,
               assigns: { review_status_issues: issues.items.first[:text], edition: edition },
               status: :unprocessable_entity
        next
      end

      if edition.scheduled_publishing_datetime.blank?
        # FIXME: this shouldn't be an exception but we've not worked out the
        # right response - maybe bad request or a redirect with flash?
        raise "Cannot schedule an edition to be published without setting a publishing date and time."
      end

      datetime = edition.scheduled_publishing_datetime
      ScheduledPublishingJob.set(wait_until: datetime).perform_later(edition.id)

      reviewed = params[:review_status] == "reviewed"
      ScheduleService.new(edition).schedule(user: current_user, reviewed: reviewed)

      redirect_to scheduled_path(edition.document)
    end
  rescue GdsApi::BaseError => e
    GovukError.notify(e)
    redirect_to document_path(params[:document]), alert_with_description: t("documents.show.flashes.schedule_error")
  end

  def scheduled
    @edition = Edition.find_current(document: params[:document])
  end

  def scheduling
    @edition = Edition.find_current(document: params[:document])
  end

private

  def permitted_params
    params.require(:schedule).permit(:year, :month, :day, :time, :action, :update)
  end

  def set_scheduled_publishing_datetime(edition, datetime = nil)
    updater = Versioning::RevisionUpdater.new(edition.revision, current_user)
    updater.assign(scheduled_publishing_datetime: datetime)

    if updater.changed?
      edition.assign_revision(updater.next_revision, current_user).save!
      create_timeline_entry(edition, datetime)
    end
  end

  def create_timeline_entry(edition, datetime)
    entry_type = if datetime
                   :scheduled_publishing_datetime_set
                 else
                   :scheduled_publishing_datetime_cleared
                 end

    TimelineEntry.create_for_revision(entry_type: entry_type, edition: edition)
  end
end
