module MercatorMesonic
  class Base < ActiveRecord::Base

    establish_connection :mesonic_cwldaten_development
    self.abstract_class = true
  end
end