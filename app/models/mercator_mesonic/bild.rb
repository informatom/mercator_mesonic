module MercatorMesonic
  class Bild < System

    self.table_name = "t022cmp"
    self.primary_key = "c000"

    # --- Class Methods --- #

    def self.import(missing: true)
      if missing == "true"
        products = Product.where(photo_file_name: nil)
      else
        products = Product.all
      end

      products.each do |product|
        file_name = product.number + ".JPG"
        bildinstance = self.find_by(C000: file_name)
        unless bildinstance
          file_name = product.number.split("-")[0] + ".JPG"
          bildinstance = self.find_by(C000: file_name)
        end

        # Let's try some more filenames ...
        unless bildinstance and product.number[0] == 0
          file_name = product.number[1..99] + ".JPG"
          bildinstance = self.find_by(C000: file_name)
        end

        unless bildinstance
          file_name = product.number.gsub(",","") + ".JPG"
          bildinstance = self.find_by(C000: file_name)
        end

        unless bildinstance
          file_name =  "10194SW.JPG" if product.number == "10194"
          file_name =  "19-08411.JPG" if product.number == "19-08411PAKO"
          file_name =  "25477B.JPG" if product.number == "25477"
          file_name =  "27145-0.JPG" if product.number == "27145-2"
          file_name =  "51-217.JPG" if product.number == "51-217-"
          file_name =  "51-218.JPG" if product.number == "51-218-"
          file_name =  "51-028.JPG" if product.number == "51-28"
          file_name =  "51-029.JPG" if product.number == "51-29"
          file_name =  "51-362-1.JPG" if product.number == "51-362/1"
          file_name =  "51-362-2.JPG" if product.number == "51-362/2"
          file_name =  "51-362-3.JPG" if product.number == "51-362/3"
          file_name =  "51-616.JPG" if product.number == "51-616."
          file_name =  "51-617.JPG" if product.number == "51-617."
          file_name =  "84-6430.JPG" if product.number == "84-6430P"
          file_name =  "88-526.JPG" if product.number == "88-526-104"
          file_name =  "88-20055.JPG" if product.number == "88-20055,00"
          file_name =  "88-20057.JPG" if product.number == "88-20057,00"
          file_name =  "88-20058.JPG" if product.number == "88-20058,00"
          file_name =  "88-23268.JPG" if product.number == "88-23068,00"
          file_name =  "88-23280.JPG" if product.number == "88-23280,00"
          file_name =  "88-40325.JPG" if product.number == "88-40325,00"
          file_name =  "88-40326.JPG" if product.number == "88-40326,00"
          file_name =  "88-40327.JPG" if product.number == "88-40327,00"
          file_name =  "88-40328.JPG" if product.number == "88-40328,00"
          file_name =  "88-40329.JPG" if product.number == "88-40329,00"
          file_name =  "88-40330.JPG" if product.number == "88-40330,00"
          file_name =  "88-40331.JPG" if product.number == "88-40331,00"
          file_name =  "88-40345.JPG" if product.number == "88-40345,00"
          file_name =  "88-40347.JPG" if product.number == "88-40347,00"
          file_name =  "88-40348.JPG" if product.number == "88-40348,00"
          file_name =  "88-40349.JPG" if product.number == "88-40349,00"
          bildinstance = self.find_by(C000: file_name)
        end

        if bildinstance
          data = StringIO.new(bildinstance.MESOBIN)
          product.photo = data
          product.photo.instance_write(:file_name, file_name) # fixes filename
          product.save
        end
      end
    end

    # --- Instance Methods --- #

    def readonly?  # prevents unintentional changes
      true
    end
  end
end