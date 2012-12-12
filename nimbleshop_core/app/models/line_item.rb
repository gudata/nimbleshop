class LineItem < ActiveRecord::Base

  # this is used only to pull the picture of the line_item. If after an order is created a product
  # is deleted then that product and all the pictures are gone. In that case line item should
  # display image not available. Besides image line_item should not pull any data from product and
  # instead used the attributes copied from product to line_item
  belongs_to :product

  store :metadata, accessors: [ :picture_tiny,      :picture_small,      :picture_medium,      :picture_large,
                                :picture_tiny_plus, :picture_small_plus, :picture_medium_plus, :picture_large_plus,
                                :product_permalink ]

  belongs_to :order

  validates_presence_of :order_id
  validates_presence_of :product_id
  validates_numericality_of :quantity, minimum: 1

  before_create :copy_product_attributes

  alias_attribute :name, :product_name
  alias_attribute :description, :product_description

  def price
    product_price * quantity
  end

  # updates quantity count. If count is zero then deletes the line_item .
  def update_quantity(count)
    count = count.to_i
    (count > 0) ? update_attributes(quantity: count) : destroy
  end

  private

  def copy_product_attributes
    self.product_name        = product.name
    self.product_description = product.description
    self.product_price       = product.price
    self.product_permalink   = product.permalink
    self.digital             = product.digital

    if product.picture
      %w(tiny tiny_plus small small_plus medium medium_plus large large_plus).each do |size|
        send("picture_#{size}=", product.picture.picture_url(size.intern))
      end
    end
  end
end
