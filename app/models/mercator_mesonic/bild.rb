module MercatorMesonic
  class Bild < System

    self.table_name = "t022cmp"
    self.primary_key = "c000"

    # --- Class Methods --- #

    def self.import_missing
      Product.where(photo_file_name: nil).each do |product|
        file_name = product.number + ".JPG"
        if bildinstance = self.find_by(c000: file_name)
          data = StringIO.new(bildinstance.MESOBIN)
          product.photo = data

          if product.save
            puts "Speichere Bild: " + file_name
          else
            puts product.errors.first
          end
        else
          puts "No photo " + file_name + " found."
        end
      end
    end

    # --- Instance Methods --- #

    def readonly?  # prevents unintentional changes
      true
    end
  end
end