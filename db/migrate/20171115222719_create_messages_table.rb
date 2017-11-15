class CreateMessagesTable < ActiveRecord::Migration[5.1]
  def change
    create_table :messages do |t|
      t.string     :body,      null: false
      t.references :recipient, references: :users
      t.references :author,    references: :users
      t.timestamps null: false
    end

    add_foreign_key :messages, :users, column: :recipient_id, on_delete: :nullify
    add_foreign_key :messages, :users, column: :author_id,    on_delete: :nullify
  end
end
