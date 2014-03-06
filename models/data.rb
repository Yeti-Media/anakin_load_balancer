module Anakin
  class DataIndex < Ohm::Model
    
    attribute :category
    attribute :user_id
    attribute :index_id
    attribute :amount
    attribute :offset
    index :index_id
    reference :server, 'Anakin::ServerPool'

  end
end
