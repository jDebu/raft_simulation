class Node
  attr_accessor :id, :neighbors, :log, :accepted_states, :proposed_state, :leader, :votes, :term, :voted_for

  def initialize(id)
    @id = id
    @neighbors = []
    @log = []
    @accepted_states = []
    @proposed_state = nil
    @leader = false
    @votes = 0
    @term = 0
    @voted_for = nil
  end

  def add_neighbor(node)
    @neighbors << node
  end

  def become_leader
    @leader = true
    log << "Node #{@id} became leader"
  end

  def start_election
    @term += 1
    @voted_for = self
    @votes = 1
    log << "Node #{@id} started an election for term #{@term} and voted for itself"
    send_vote_request
  end

  def send_vote_request
    neighbors.each do |neighbor|
      neighbor.receive_vote_request(self, @term)
    end
  end

  def receive_vote_request(candidate, candidate_term)
    if candidate_term > @term && @voted_for.nil?
      @term = candidate_term
      @voted_for = candidate
      log << "Node #{@id} voted for Node #{candidate.id} in term #{candidate_term}"
      candidate.receive_leader_vote(self)
    else
      log << "Node #{@id} rejected vote request from Node #{candidate.id}"
    end
  end

  def receive_leader_vote(voter)
    @votes += 1
    log << "Node #{@id} received vote from Node #{voter.id} (Votes: #{@votes})"
    check_election_result
  end

  def check_election_result
    majority = ((neighbors.size + 1) / 2.0).ceil
    if @votes >= majority
      become_leader
    else
      log << "Node #{@id} has #{@votes} votes, consensus not yet reached for leadership"
    end
  end


  def propose_state(state)
    if @leader
      @propose_state = state
      log << "Node #{@id} (leader) proposes state: #{state}"
      accepted_states << state
      @votes = 1
      accepted_states << state
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
    majority = ((neighbors.size + 1) / 2.0).ceil 
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
