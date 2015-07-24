MercatorMesonic::Engine.routes.draw do
  get 'import' => "application#import"
  get 'update_business_year' => "application#update_business_year"
end
