class ItemsController < ApplicationController
  require 'payjp'
  before_action :move_to_index, except: [:index, :show]
  before_action :set_item, only: [:show, :destroy, :purchase, :done]
  before_action :set_caegory_for_new_create, only: [:new, :create]

  def index
  end

  def show
    @comment = Comment.new
    @comments = @item.comments.includes(:user)
    @grandchildren = @item.category
    @children = @grandchildren.parent
  end

  def new
    @item = Item.new
    @item.item_images.build
  end

  def get_category_children
    @category_children = Category.find_by(name: "#{params[:parent_name]}", ancestry: nil).children
  end

  def get_category_grandchildren
    @category_grandchildren = Category.find("#{params[:child_id]}").children
  end

  def create
    @item = Item.new(item_params)
    if @item.save
      redirect_to root_path
    else
      redirect_to new_item_path
    end
  end


  def search_child
    respond_to do |format|
      format.html
      format.json do
        @childrens = Category.find(params[:parent_id]).children
      end
    end
  end

  def search_grandchild
    respond_to do |format|
      format.html
      format.json do
        @grandchildrens = Category.find(params[:child_id]).children
      end
    end
  end

  def set_caegory_for_new_create
    @category_parent_array = ["選択してください"] + Category.where(ancestry: nil).first(13).pluck(:name)
  end


  def move_to_index
    unless user_signed_in?
      redirect_to action: :index
    end
  end

  def done
    @user = User.find(current_user.id)
    @address = Address.find(current_user.id)
    @grandchildren = @item.category
    @children = @grandchildren.parent
    card = Card.where(user_id: current_user.id).first
    if card.blank?
      redirect_to new_card_path(current_user.id), alert: 'クレジットカードを登録してください'
    else
      Payjp.api_key = ENV["PAYJP_SECRET_KEY"]
      customer = Payjp::Customer.retrieve(card.customer_id)
      @default_card_information = customer.cards.retrieve(card.card_id)
      @card_brand = @default_card_information.brand      
      case @card_brand
      when "Visa"
        @card_src = "visa.svg"
      when "JCB"
        @card_src = "jcb.svg"
      when "MasterCard"
        @card_src = "master-card.svg"
      when "American Express"
        @card_src = "american_express.svg"
      when "Diners Club"
        @card_src = "dinersclub.svg"
      when "Discover"
        @card_src = "discover.svg"
      end
    end
  end

  def destroy
    if @item.destroy
      redirect_to root_path, notice: '削除しました'
    else
      render :show
    end
  end

  def purchase
    Payjp.api_key = ENV["PAYJP_SECRET_KEY"]
    card = Card.where(user_id: current_user.id).first
    charge = Payjp::Charge.create(
      # @item.price
      amount: @item.price,
      customer: Payjp::Customer.retrieve(card.customer_id),
      currency: 'jpy'
    )
    @item.update( buyer: current_user.id, order_status: "売切れ")
    redirect_to root_path, alert: '購入致しました'
  end


  private
  def item_params
    params.require(:item).permit(
      :name, :detail, :price, :category_id, :size_id, :shipping_method_id, :condition_id, :shipping_days_id, :fee_burden_id, :prefecture_id, [item_images_attributes: [:url]]
      ).merge(user_id: current_user.id, seller: current_user.id, order_status: "出品中")
  end

  def set_item
    @item = Item.find(params[:id])
  end
  
end
