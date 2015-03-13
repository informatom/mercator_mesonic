module MercatorMesonic
  class System < ActiveRecord::Base

    establish_connection :mesonic_cwlsystem
    self.abstract_class = true
  end
end