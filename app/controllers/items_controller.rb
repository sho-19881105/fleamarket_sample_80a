class ItemsController < ApplicationController
  before_action :move_to_index, except: [:index, :show]
  before_action :set_caegory_for_new_create, only: [:new, :create]

  def index
    @items = Item.all
  end

  def show
    @item = Item.find(params[:id])
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

  def set_caegory_for_new_create
    @category_parent_array = ["選択してください"] + Category.where(ancestry: nil).first(13).pluck(:name)
  end


  def move_to_index
    unless user_signed_in?
      redirect_to action: :index
    end
  end

  def done
  end

  private
  def item_params
    params.require(:item).permit(
      :name, :detail, :price, :category_id, :size_id, :shipping_method_id, :condition_id, :shipping_days_id, :fee_burden_id, :prefecture_id, :brand_id, [item_images_attributes: [:url]]
      ).merge(user_id: current_user.id, seller: current_user.id, order_status: "出品中")
  end
  
end
