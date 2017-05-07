class CreateTwitterAccounts < ActiveRecord::Migration[5.0]
  def change
    create_table :twitter_accounts do |t|
      t.belongs_to :account, foreign_key: true
      t.string :name
      t.string :access_token
      t.string :access_token_secret
      t.datetime :last_updated_at, null: false, default: -> { 'NOW()' }

      t.timestamps
    end
  end
end
