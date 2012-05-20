class Users < Controller
  layout :main
  helper :blue_form

  def create
    @title = 'Inscription'
    @form_data = {}
    @subtitle = 'S\'inscrire'

    p request.params

    if request.params['validate'] == 'true'
      # handle form
      @title = "Posted"
    end
  end
end
