class User < Controller
  layout :main
  helper :blue_form

  def create
    @title = 'Inscription'
    @form_data = {}
    @subtitle = 'S\'inscrire'


  end
end
