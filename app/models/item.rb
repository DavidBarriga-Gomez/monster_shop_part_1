class Item <ApplicationRecord
  belongs_to :merchant
  has_many :reviews, dependent: :destroy
  has_many :item_orders
  has_many :orders, through: :item_orders

  validates_presence_of :name,
                        :description,
                        :price,
                        :image,
                        :inventory
  validates_inclusion_of :active?, :in => [true, false]
  validates_numericality_of :price, greater_than: 0


  def average_review
    reviews.average(:rating)
  end

  def sorted_reviews(limit, order)
    reviews.order(rating: order).limit(limit)
  end

  def no_orders?
    item_orders.empty?
  end

  def self.find_active_items
    where(active?: true)
  end

  def self.top_five_items
    Item.select("items.*, sum(quantity)").where(active?: true).joins(:item_orders).group(:id).order("sum desc").limit(5)
  end

  def self.bottom_five_items
    Item.select("items.*, sum(quantity)").where(active?: true).joins(:item_orders).group(:id).order("sum").limit(5)
  end

  def self.decrease_item_inventory(item_id, quantity)
    current_inventory = Item.find(item_id).inventory.to_i
    Item.where(id: item_id).update(inventory: (current_inventory - quantity.to_i))
  end

  def self.increase_item_inventory(order)
    order.item_orders.each do |item_order|
      current_inventory = Item.select(:inventory).where(id: item_order.item_id).pluck(:inventory).first
      Item.where(id: item_order.item_id).update(inventory: (current_inventory + item_order.quantity))
    end
  end

  def self.deactivate_all_items
    update(active?: false)
  end

  def self.activate_all_items
    update(active?: true)
  end
end
