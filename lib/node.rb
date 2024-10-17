class Node
  attr_accessor :id, :neighbors, :log, :accepted_states, :proposed_state, :leader, :votes

  def initialize(id)
    @id = id
    @neighbors = []
    @log = []
    @accepted_states = []
    @proposed_state = nil
    @leader = false
    @votes = 0
  end

  def add_neighbor(node)
    @neighbors << node
  end

  def become_leader
    @leader = true
    log << "Node #{@id} became leader"
  end

  def propose_state(state)
    if @leader
      @propose_state = state
      log << "Node #{@id} (leader) proposes state: #{state}"
      accepted_states << state
      @votes = 1 
      send_proposal(state)
    else
      log << "Node #{@id} tried to propose state but is not the leader"
    end
  end

  def send_proposal(state)
    neighbors.each do |neighbor|
      neighbor.receive_proposal(state, self)
    end
  end

  def receive_proposal(state, leader)
    log << "Node #{@id} received state: #{state} from Node #{leader.id} (leader)"
    accepted_states << state
    leader.receive_vote(self, state)
  end

  def receive_vote(neighbor, state)
    if state == @proposed_state
      @votes += 1
      log << "Node #{@id} received vote from Node #{neighbor.id} for state #{state}"
      check_consensus
    end
  end

  def check_consensus
    majority = (neighbors.size  + 1)/ 2 
    if @votes >= majority
      log << "Consensus reached on state: #{@proposed_state}"
    else
      log << "Consensus not yet reached on state: #{@proposed_state} (Votes: #{@votes})"
    end
  end

  def retrieve_log
    log
  end
end
