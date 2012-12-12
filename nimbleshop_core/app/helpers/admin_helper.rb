module AdminHelper

  ROUTE_MAP = {
      admin_products_path:        'admin/products',
      admin_custom_fields_path:   'admin/custom_fields',
      admin_product_groups_path:  'admin/product_groups',
      admin_link_groups_path:     [ 'admin/link_groups', 'admin/navigations' ],
      admin_payment_methods_path: 'admin/payment_methods',
      admin_shipping_zones_path:  [ 'admin/shipping_zones', 'admin/shipping_methods' ],
      edit_admin_shop_path:       'admin/shops',
      admin_orders_path:          'admin/orders'
  }

  def admin_topbar_active?(path, current_controller)
    Array.wrap(ROUTE_MAP[path.to_sym]).include?(current_controller)
  end

  def admin_topbar(label, path, identifier)

    html_options = {}

    if admin_topbar_active?(identifier, params[:controller])
      html_options['class'] = 'active'
    end

    content_tag(:li, link_to(label, path), html_options)
  end

  def display_payment_status(order)
    css_klass = order.payment_status == 'purchased' ? 'label-success' : 'label-info'
    %Q{<span class="label #{css_klass}"> #{order.payment_status.titleize.upcase} </span>}.html_safe
  end

  def display_shipping_status(order)
    css_klass = case order.shipping_status
                when 'shipped'
                  'label-success'
                when 'nothing_to_ship'
                  'label-info'
                when 'shipping_pending'
                  'label-important'
                end
    %Q{<span class="label #{css_klass}"> #{order.shipping_status.titleize.upcase} </span>}.html_safe
  end

  def creditcard_logo_for(creditcard)
    image_tag "#{creditcard.cardtype}.png"
  end

  def shipping_method_condition_in_english(shipping_method)
    if shipping_method.maximum_order_amount
      s = number_to_currency(shipping_method.minimum_order_amount)
      s << " - "
      s << number_to_currency(shipping_method.maximum_order_amount)
    else
      number_to_currency(shipping_method.minimum_order_amount) + ' minimum'
    end
  end

  def gravatar_for(email, options = {})
    email ||= 'user@example.com'
    options = { alt: 'avatar', class: 'avatar', size: 50 }.merge! options
    id = Digest::MD5::hexdigest(email.strip.downcase)

    uri = URI.join(root_url, image_path('default_gravatar.jpg'))
    default_gravatar_url = Rack::Utils.escape uri

    url = 'http://www.gravatar.com/avatar/' + id + '.jpg?d='+default_gravatar_url+'&s=' + options[:size].to_s
    options.delete :size
    image_tag url, options
  end

  def shipment_info(shipment)
    if shipment.tracking_number.present?
      link_to shipment.name + ' #' + shipment.tracking_number, shipment.tracking_url
    else
      shipment.name
    end
  end

  def delete_icon
    %Q{
      <i class='icon-remove icon-black'></i>
    }.html_safe
  end

end
