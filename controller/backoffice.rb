class Backoffice < Controller
  helper :paginate

  before_all do
    #redirect_referrer unless logged_in? and user.admin
  end

  def index
    @subscribers = paginate(User.filter(:admin=>false, :superadmin=>false))
    #@subscribers = paginate(User)
  end
end

