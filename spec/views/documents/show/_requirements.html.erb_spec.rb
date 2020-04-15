RSpec.describe "documents/show/_requirements" do
  let(:image) { build :image_revision }
  let(:edition) { create :edition, revision_synced: false, image_revisions: [image] }

  before do
    issues = Requirements::CheckerIssues.new

    issues.create(:image_alt_text,
                  :blank,
                  image_revision: image,
                  filename: "file")

    checker = instance_double(Requirements::EditionChecker,
                              pre_preview_issues: issues,
                              pre_publish_issues: issues)

    allow(Requirements::EditionChecker).to receive(:new).and_return(checker)
    assign(:edition, edition)
  end

  describe "with preview issues" do
    it "shows issues that are preventing preview" do
      render template: described_template

      expect(rendered).to have_content(
        I18n.t!("documents.show.flashes.pre_preview_issues.warning"),
      )
    end

    it "alerts about issues when trying to preview" do
      render template: described_template,
             locals: { flash: { tried_to_preview: true } }

      expect(rendered).to have_content(
        I18n.t!("documents.show.flashes.pre_preview_issues.error"),
      )
    end

    it "shows nothing when the edition is previewable" do
      assign(:edition, build(:edition))

      render template: described_template

      expect(rendered).not_to have_content(
        I18n.t!("documents.show.flashes.pre_preview_issues.warning"),
      )
    end
  end

  context "with publish issues" do
    it "shows issues that are preventing publish" do
      render template: described_template

      expect(rendered).to have_content(
        I18n.t!("documents.show.flashes.pre_publish_issues.warning"),
      )
    end

    it "alerts about issues when trying to publish" do
      render template: described_template,
             locals: { flash: { tried_to_publish: true } }

      expect(rendered).to have_content(
        I18n.t!("documents.show.flashes.pre_publish_issues.error"),
      )
    end

    it "shows nothing if the edition isn't editable" do
      assign(:edition, build(:edition, :published))
      render template: described_template

      expect(rendered).not_to have_content(
        I18n.t!("documents.show.flashes.pre_publish_issues.warning"),
      )
    end
  end

  it "provides links to fix deeply nested issues" do
    render template: described_template

    expect(rendered).to have_link(
      I18n.t!("requirements.image_alt_text.blank.summary_message", filename: "file"),
      href: edit_image_path(edition.document, image.image_id, anchor: "alt-text"),
    )
  end
end
