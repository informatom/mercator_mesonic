module MercatorMesonic
  class Base < ActiveRecord::Base

    establish_connection :mesonic_cwldaten
    self.abstract_class = true
  end
end