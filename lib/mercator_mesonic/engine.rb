module MercatorMesonic
  class Engine < ::Rails::Engine

    isolate_namespace MercatorMesonic
    config.erp = "mesonic"
  end
end
