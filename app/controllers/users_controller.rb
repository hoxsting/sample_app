class UsersController < ApplicationController
  before_filter :authenticate, :only => [:index, :edit, :update, :destroy]
  before_filter :correct_user, :only => [:edit, :update]
  before_filter :admin_user,   :only => :destroy
  before_filter :non_autenticate,   :only => [:new, :create] 

  def new
      @titre = "Inscription"
      @user = User.new
  end

  def index
    @titre = "Tous les utilisateurs"
    @users = User.paginate(:page => params[:page])
  end

  def show
    @user = User.find(params[:id])
    @titre = @user.nom
  end

 def create
    @user = User.new(params[:user])
    if @user.save
      sign_in @user
      flash[:success] = "Bienvenue dans l'Application Exemple !"
      redirect_to @user
    else
      @titre = "Inscription"
      render 'new'
    end
  end

  def edit
    @user = User.find(params[:id])
    @titre = "Edition profil"
  end

  def update
    @user = User.find(params[:id])
    if @user.update_attributes(params[:user])
      flash[:success] = "Profil actualise."
      redirect_to @user
    else
      @titre = "Edition profil"
      render 'edit'
    end
  end

  def destroy
    user = User.find(params[:id])
    if(user != current_user)
      user.destroy
      flash[:success] = "Utilisateur supprime."
      redirect_to users_path
    else
      flash[:error] = "Vous n'avez pas l'autorisation de vous supprimer"
      redirect_to users_path
    end
  end

  private

    def non_autenticate
      deny_access_connecte unless not signed_in?
    end

    def authenticate
      deny_access unless signed_in?
    end

    def correct_user
      @user = User.find(params[:id])
      redirect_to(root_path) unless current_user?(@user)
    end

    def admin_user
      redirect_to(root_path) unless current_user.admin?
    end

  #end private
end
