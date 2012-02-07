require 'spec_helper'

describe ShippingMethod do

  describe "making country level shipping method inactive should make children inactive" do
    describe "updating record" do
      it {
        shipping_method = create(:country_shipping_method)
        region = shipping_method.regions.first
        region.active.must_equal true
        shipping_method.update_attributes!(active: false)
        region.reload
        region.active.must_equal false
      }
    end
    describe "creating record" do
      it {
        shipping_method = create(:country_shipping_method, active: false)
        region = shipping_method.regions.first
        region.active.must_equal false
      }
    end
  end

  describe "#enable! #disable!" do
    it {
      shipping = create(:country_shipping_method)

      shipping.enable!
      shipping.must_be(:active)

      shipping.disable!
      shipping.wont_be(:active)
    }
  end

  describe "#update_offset" do
    let(:shipment) { ShippingMethod.new(base_price: 10) }
    describe "of country" do
      it "is not going to update" do
        shipment.shipping_zone = CountryShippingZone.new

        shipment.update_offset(0.20)

        shipment.offset.to_f.must_equal 0.0
      end
    end

    describe "of state" do
      it "is going to increase by 0.20" do
        shipment.shipping_zone = RegionalShippingZone.new

        shipment.update_offset(0.20)

        shipment.offset.to_f.must_equal 0.20
      end

      it "is going to decreate by 0.20" do
        shipment.shipping_zone = RegionalShippingZone.new
        shipment.offset = 0.80

        shipment.update_offset(-0.20)

        shipment.offset.to_f.must_be_within_delta 0.60
      end
    end
  end

  describe "#available_for" do
    describe "with one shipping method" do
      it {
        shipping_method = create(:country_shipping_method, lower_price_limit: 10, upper_price_limit: 51)
        CountryShippingZone.count.must_equal 1
        RegionalShippingZone.count.must_equal 57
        shipping_method.shipping_zone.country_code.must_equal 'US'

        address = create(:shipping_address, state_code: 'FL', country_code: 'US')
        address.state_code.must_equal 'FL'
        RegionalShippingZone.count(conditions: {state_code: 'FL', country_code: 'US'}).must_equal 1

        ShippingMethod.available_for(25, address).size.must_equal 1
        ShippingMethod.available_for(200, address).size.must_equal 0
      }
    end

    describe "with two shipping methods" do
      it {
        create(:country_shipping_method, lower_price_limit: 10, upper_price_limit: 51, name: 'General')
        create(:country_shipping_method, lower_price_limit: 10, upper_price_limit: 51, name: 'Express')
        RegionalShippingZone.count(conditions: {state_code: 'FL', country_code: 'US'}).must_equal 2

        address = create(:shipping_address, state_code: 'FL', country_code: 'US')
        ShippingMethod.available_for(25, address).size.must_equal 2
        ShippingMethod.available_for(200, address).size.must_equal 0
      }
    end
    describe "with two shipping methods and make one active" do
      it {
        s1 = create(:country_shipping_method, lower_price_limit: 1, upper_price_limit: 51, name: 'General')
        s2 = create(:country_shipping_method, lower_price_limit: 1, upper_price_limit: 51, active: false, name: 'Express')
        s1.active.must_equal true
        s1.regions.each { |r| r.active.must_equal true }

        s2.active.must_equal false
        s2.regions.each { |r| r.active.must_equal false }

        address = create(:shipping_address, state_code: 'FL', country_code: 'US')
        ShippingMethod.available_for(25, address).size.must_equal 1
        ShippingMethod.available_for(200, address).size.must_equal 0
      }
    end
  end

  describe "of country type" do
    let(:shipping) { build(:country_shipping_method) }

    it "#validations" do
      shipping.higher_price_limit = 20

      shipping.must have_valid(:name).when("Any name")
      shipping.wont have_valid(:name).when(nil)

      shipping.wont have_valid(:base_price).when(nil)

      shipping.must have_valid(:offset).when(nil)

      shipping.wont have_valid(:lower_price_limit).when(nil)
      shipping.wont have_valid(:lower_price_limit).when(20)
      shipping.wont have_valid(:lower_price_limit).when(40)
      shipping.must have_valid(:lower_price_limit).when(12)
      end

    describe "#shipping_price" do
      it "ignores offset value" do
        shipping.offset = 0.10
        shipping.base_price = 10

        shipping.shipping_price.must_equal 10.0
      end
    end

    describe "on create #callbacks" do
      it "creates all regional shipping zone records" do
        shipping.save
        shipping.regions.count.must_equal 57
      end
    end
  end

  describe "of state type" do
    let(:shipping) { build(:regional_shipping_method) }

    it "#validations" do
      shipping.must have_valid(:name).when("Any name")
      shipping.wont have_valid(:name).when(nil)

      shipping.must have_valid(:base_price).when(nil)

      shipping.must have_valid(:offset).when(nil)

      shipping.must have_valid(:lower_price_limit).when(nil)
      shipping.must have_valid(:higher_price_limit).when(nil)
      end

    describe "#shipping_price" do
      it "ignores base_price value" do
        shipping.parent.base_price = 10
        shipping.offset = 0.10
        shipping.base_price = 20

        shipping.shipping_price.to_f.must_equal 10.10
      end
    end

    describe "on create #callbacks" do
      it "does not create all regional shipping zone records" do
        shipping.save
        shipping.regions.count.must_equal 0
      end
    end
  end
end
