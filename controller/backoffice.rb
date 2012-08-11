class Backoffice < Controller
  helper :paginate
  layout :backoffice

  before_all do
    if !logged_in? or !user.admin
      event(:edge_case, :controller => "Backoffice#before_all", :type => :acces_denied) 
      redirect_referrer
    end
  end

  def index
    @subscribers = paginate(User.filter(:admin=>false, :superadmin=>false))
  end
end

