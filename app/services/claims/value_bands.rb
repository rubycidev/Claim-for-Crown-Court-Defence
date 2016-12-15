module Claims
  class ValueBands

    Struct.new('ValueBandDefinition', :id, :name, :min, :max)

    VALUE_BANDS = {
      10 => Struct::ValueBandDefinition.new(10, 'less than £25,000', 0.0, 25_000.0),
      20 => Struct::ValueBandDefinition.new(20, '£25,000 - £100,000', 25_000.01, 100_000.0),
      30 => Struct::ValueBandDefinition.new(30, '£100,000 - £150,000', 100_000.01, 150_000.0),
      40 => Struct::ValueBandDefinition.new(40, 'more than £150,000', 150_000.01, 99_999_999.99),
    }

    def self.band_id_for_claim(claim)
      VALUE_BANDS.each do |band_id, band|
        next if  claim.total + claim.vat_amount > band.max
        return band_id
      end
      raise 'Maximum band value exceeded'
    end

    def self.band_by_id(band_id)
      VALUE_BANDS[band_id]
    end

    def self.bands
      VALUE_BANDS.values
    end

  end
end