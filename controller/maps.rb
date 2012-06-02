# encoding: UTF-8
#
class Maps < Controller
  def index
    @title = 'Cartes'
    @subtitle = "Tracés de l'épreuve"
    @loadmap = true
  end
end
