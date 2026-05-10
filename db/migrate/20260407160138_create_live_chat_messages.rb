class CreateLiveChatMessages < ActiveRecord::Migration[8.0]
  def change
    create_table :live_chat_messages do |t|
      t.references :transmission, null: false, foreign_key: true
      t.integer :platform,    null: false
      t.string  :sender_id,   null: false
      t.string  :sender_name, null: false
      t.text    :body,        null: false
      t.timestamps
    end

    add_index :live_chat_messages, [:transmission_id, :created_at],
      name: "index_live_chat_messages_on_transmission_id_and_created_at"
  end
end
