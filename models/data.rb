class DataIndex < Ohm::Model

  attribute :category
  attribute :user_id
  attribute :trainer_id
  attribute :amount
  attribute :offset
  index :trainer_id
  index :category
  index :user_id
  reference :server_pool, :ServerPool
  unique :trainer_id


  def self.count
    all.to_a.size
  end
end