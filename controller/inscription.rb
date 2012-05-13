class InscriptionController < Controller
  layout :main
  helper :blue_form

  def new
    @title = 'Nouvelle inscription'
  end
end
