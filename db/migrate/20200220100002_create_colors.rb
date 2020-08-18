class CreateColors < ActiveRecord::Migration[4.2]
  def change
    create_table :colors do |t|
      t.string :name
      t.string :value
    end
  end
end
