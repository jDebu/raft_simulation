class Node
  attr_accessor :id, :neighbors, :log, :accepted_states, :proposed_state

  def initialize(id)
    @id = id
    @neighbors = []
    @log = []
    @accepted_states = []
    @proposed_state = nil
  end

  def add_neighbor(node)
    @neighbors << node
  end

  def propose_state(state)
    @propose_state = state
    log << "Node #{@id} proposes state: #{state}"
    accepted_states << state
    send_proposal(state)
  end

  def send_proposal(state)
    neighbors.each do |neighbor|
      neighbor.receive_proposal(state, self)
    end
  end

  def receive_proposal(state, node)
    log << "Node #{@id} received state: #{state} from Node #{node.id}"
    accepted_states << state
  end

  def retrieve_log
    log
  end
end
