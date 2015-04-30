class CreateClaims < ActiveRecord::Migration
  def change
    create_table :claims do |t|
      t.text :additional_information
      t.boolean :apply_vat
      t.string :state, index: true
      t.string :case_type, index: true
      t.datetime :submitted_at
      t.string :case_number, index: true
      t.string :advocate_category
      t.string :prosecuting_authority
      t.string :indictment_number

      t.decimal :fees_total, default: 0
      t.decimal :expenses_total, default: 0
      t.decimal :total, default: 0

      t.references :advocate, index: true
      t.references :court, index: true
      t.references :offence, index: true
      t.references :scheme, index: true

      t.timestamps
    end
  end
end
