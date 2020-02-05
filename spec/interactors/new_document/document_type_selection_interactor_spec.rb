# frozen_string_literal: true

RSpec.describe NewDocument::DocumentTypeSelectionInteractor do
  describe ".call" do

    it "succeeds with default paramaters" do
      result = NewDocument::DocumentTypeSelectionInteractor.call(params: { document_type_selection_id: "root" })
      expect(result).to be_success
    end

    it "fails if the document_type_selection_id isn't passed in" do
      result = NewDocument::DocumentTypeSelectionInteractor.call(params: { document_type_selection_id: "" })
      expect(result).to_not be_success
    end
  end
end
