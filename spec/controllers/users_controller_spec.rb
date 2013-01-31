require 'spec_helper'

describe UsersController do
  render_views

  describe "DELETE 'destroy'" do

    before(:each) do
      @user = Factory(:user)
    end

    describe "en tant qu'utilisateur non identifie" do
      it "devrait refuser l'acces" do
        delete :destroy, :id => @user
        response.should redirect_to(signin_path)
      end
    end

    describe "en tant qu'utilisateur non administrateur" do
      it "devrait proteger la page" do
        test_sign_in(@user)
        delete :destroy, :id => @user
        response.should redirect_to(root_path)
      end
    end

    describe "en tant qu'administrateur" do

      before(:each) do
        @admin = Factory(:user, :email => "admin@example.com", :admin => true)
        test_sign_in(@admin)
      end

      it "ne devrait pas permettre de s'auto-detruire" do
        lambda do
          delete :destroy, :id => @admin
        end.should change(User, :count).by(0)
      end

      it "devrait detruire l'utilisateur" do
        lambda do
          delete :destroy, :id => @user
        end.should change(User, :count).by(-1)
      end

      it "devrait rediriger vers la page des utilisateurs" do
        delete :destroy, :id => @user
        response.should redirect_to(users_path)
      end
    end
  end

  describe "GET 'index'" do

    describe "pour utilisateur non identifies" do
      it "devrait refuser l'acces" do
        get :index
        response.should redirect_to(signin_path)
        flash[:notice].should =~ /identifier/i
      end
    end

    describe "pour un utilisateur identifie" do

      before(:each) do
        @user = test_sign_in(Factory(:user))
        second = Factory(:user, :email => "another@example.com")
        third  = Factory(:user, :email => "another@example.net")

        @users = [@user, second, third]
        30.times do
          @users << Factory(:user, :email => Factory.next(:email))
        end
      end

      it "devrait reussir" do
        get :index
        response.should be_success
      end

      it "devrait avoir un element pour chaque utilisateur" do
        get :index
        @users[0..2].each do |user|
          response.should have_selector("li", :content => user.nom)
        end
      end

      it "devrait paginer les utilisateurs" do
        get :index
        response.should have_selector("div.pagination")
        response.should have_selector("span.disabled", :content => "Previous")
      end

      it "devrait avoir le bon titre" do
        get :index
        response.should have_selector("title", :content => "Tous les utilisateurs")
      end

      it "devrait avoir un element pour chaque utilisateur" do
        get :index
        @users.each do |user|
          response.should have_selector("li", :content => user.nom)
        end
      end
    end
  end

  describe "GET 'show'" do

    before(:each) do
      @user = Factory(:user)
    end

    it "devrait reussir" do
      get :show, :id => @user
      response.should be_success
    end

    it "devrait trouver le bon utilisateur" do
      get :show, :id => @user
      assigns(:user).should == @user
    end

    it "devrait avoir le bon titre" do
      get :show, :id => @user
      response.should have_selector("title", :content => @user.nom)
    end

    it "devrait inclure le nom de l'utilisateur" do
      get :show, :id => @user
      response.should have_selector("h1", :content => @user.nom)
    end

    it "devrait avoir une image de profil" do
      get :show, :id => @user
      response.should have_selector("h1>img", :class => "gravatar")
    end
  end

  describe "GET 'new'" do

    it "devrait reussir" do
      get 'new'
      response.should be_success
    end

    it "devrait avoir le titre adequat" do
      get 'new'
      response.should have_selector("title", :content => "Inscription")
    end

    it "devrait avoir un champ nom" do
      get 'new'
      response.should have_selector("input[name='user[nom]'][type='text']")
    end

    it "devrait avoir un champ email" do
      get :new
      response.should have_selector("input[name='user[email]'][type='text']")
    end

    it "devrait avoir un champ mot de passe" do
      get :new
      response.should have_selector("input[name='user[password]'][type='password']")
    end

    it "devrait avoir un champ confirmation du mot de passe" do
      get :new
      response.should have_selector("input[name='user[password_confirmation]'][type='password']")
    end
  end

  describe "POST 'create'" do

    describe "succes" do

      before(:each) do
        @attr = { :nom => "New User", :email => "user@example.com",
                  :password => "foobar", :password_confirmation => "foobar" }
      end

      it "devrait creer un utilisateur" do
        lambda do
          post :create, :user => @attr
        end.should change(User, :count).by(1)
      end

      it "devrait rediriger vers la page d'affichage de l'utilisateur" do
        post :create, :user => @attr
        response.should redirect_to(user_path(assigns(:user)))
      end    
    
      it "devrait avoir un message de bienvenue" do
        post :create, :user => @attr
        flash[:success].should =~ /Bienvenue /i
      end

      
      it "devrait identifier l'utilisateur" do
        post :create, :user => @attr
        controller.should be_signed_in
      end
    end

    describe "echec" do

      before(:each) do
        @attr = { :nom => "", :email => "", :password => "",
                  :password_confirmation => "" }
      end

      it "ne devrait pas creer d'utilisateur" do
        lambda do
          post :create, :user => @attr
        end.should_not change(User, :count)
      end

      it "devrait avoir le bon titre" do
        post :create, :user => @attr
        response.should have_selector("title", :content => "Inscription")
      end

      it "devrait rendre la page 'new'" do
        post :create, :user => @attr
        response.should render_template('new')
      end
    end
  end

  describe "GET 'edit'" do

    before(:each) do
      @user = Factory(:user)
      test_sign_in(@user)
    end

    it "devrait reussir" do
      get :edit, :id => @user
      response.should be_success
    end

    it "devrait avoir le bon titre" do
      get :edit, :id => @user
      response.should have_selector("title", :content => "Edition profil")
    end

    it "devrait avoir un lien pour changer l'image Gravatar" do
      get :edit, :id => @user
      gravatar_url = "http://gravatar.com/emails"
      response.should have_selector("a", :href => gravatar_url,
                                         :content => "changer")
    end
  end

  describe "PUT 'update'" do

    before(:each) do
      @user = Factory(:user)
      test_sign_in(@user)
    end

    describe "Echec" do

      before(:each) do
        @attr = { :email => "", :nom => "", :password => "",
                  :password_confirmation => "" }
      end

      it "devrait retourner la page d'edition" do
        put :update, :id => @user, :user => @attr
        response.should render_template('edit')
      end

      it "devrait avoir le bon titre" do
        put :update, :id => @user, :user => @attr
        response.should have_selector("title", :content => "Edition profil")
      end
    end

    describe "succes" do

      before(:each) do
        @attr = { :nom => "New Name", :email => "user@example.org",
                  :password => "barbaz", :password_confirmation => "barbaz" }
      end

      it "devrait modifier les caracteristiques de l'utilisateur" do
        put :update, :id => @user, :user => @attr
        @user.reload
        @user.nom.should  == @attr[:nom]
        @user.email.should == @attr[:email]
      end

      it "devrait rediriger vers la page d'affichage de l'utilisateur" do
        put :update, :id => @user, :user => @attr
        response.should redirect_to(user_path(@user))
      end

      it "devrait afficher un message flash" do
        put :update, :id => @user, :user => @attr
        flash[:success].should =~ /actualise/
      end
    end
  end

  describe "authentification des pages edit et update" do

    before(:each) do
      @user = Factory(:user)
    end

    describe "pour un utilisateur non identifie" do

      it "devrait refuser l'accces a l'action edit" do
        get :edit, :id => @user
        response.should redirect_to(signin_path)
      end

      it "devrait refuser l'acces a l'action update" do
        put :update, :id => @user, :user => {}
        response.should redirect_to(signin_path)
      end
    end

    describe "pour un utilisateur identifie" do

      before(:each) do
        wrong_user = Factory(:user, :email => "user@example.net")
        test_sign_in(wrong_user)
      end

      it "devrait correspondre a l'utilisateur a editer" do
        get :edit, :id => @user
        response.should redirect_to(root_path)
      end

      it "devrait correspondre a l'utilisateur a actualiser" do
        put :update, :id => @user, :user => {}
        response.should redirect_to(root_path)
      end
    end
  end
end
