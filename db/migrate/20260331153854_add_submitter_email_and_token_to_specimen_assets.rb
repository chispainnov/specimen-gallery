class AddSubmitterEmailAndTokenToSpecimenAssets < ActiveRecord::Migration[8.1]
  def change
    add_column :specimen_assets, :submitter_email, :string
    add_column :specimen_assets, :submission_token, :string
    add_index :specimen_assets, :submission_token, unique: true
  end
end
