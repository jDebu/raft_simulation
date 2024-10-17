class Node
  attr_accessor :id, :neighbors

  def initialize(id)
    @id = id
    @neighbors = []
  end

  def add_neighbor(node)
    @neighbors << node
  end
end
