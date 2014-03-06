module Anakin
  class Category < Ohm::Model
    attribute :name
    collection :servers, 'Anakin::ServerPool'
  end
end
