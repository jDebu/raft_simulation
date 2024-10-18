require 'debug'
class Node
  attr_accessor :id, :neighbors, :log, :accepted_states, :proposed_state, :leader, :votes, :term, :voted_for, :partitioned_nodes

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
    @partitioned_nodes = []
  end

  def add_neighbor(node)
    @neighbors << node
  end

  def become_leader
    @leader = true
    log << "Node #{@id} became leader in term #{@term}"
  end

  def start_election
    if @leader
      log << "Node #{@id} is already a leader in term #{@term}, no need to start a new election."
      return
    end

    neighbors.each do |neighbor|
      if neighbor.leader
        log << "Node #{@id} canceled its election for term #{@term} because Node #{neighbor.id} is already the leader."
        return
      end
    end

    @term += 1
    @voted_for = self
    @votes = 1
    log << "Node #{@id} started an election for term #{@term} and voted for itself"
    send_vote_request
  end

  def send_vote_request
    neighbors.each do |neighbor|
      unless partitioned_nodes.include?(neighbor)
        neighbor.receive_vote_request(self, @term)
      else
        log << "Node #{@id} could not send vote request to Node #{neighbor.id} due to partition"
      end
    end
  end

  def receive_vote_request(candidate, candidate_term)
    if (candidate_term > @term || candidate_term == @term) && @voted_for.nil?
      @term = candidate_term
      @voted_for = candidate
      log << "Node #{@id} voted for Node #{candidate.id} in term #{candidate_term}"
      candidate.receive_leader_vote(self)
    else
      log << "Node #{@id} rejected vote request from Node #{candidate.id} for term #{candidate_term}"
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
      @proposed_state = state
      log << "Node #{@id} (leader) proposes state: #{state}"
      @votes = 1
      accepted_states << state
      send_proposal(state)
    else
      log << "Node #{@id} tried to propose state #{state} but is not the leader"
    end
  end

  def send_proposal(state)
    neighbors.each do |neighbor|
      unless partitioned_nodes.include?(neighbor)
        neighbor.receive_proposal(state, self)
      else
        log << "Node #{@id} could not send proposal to Node #{neighbor.id} due to partition"
      end
    end
  end

  def receive_proposal(state, leader)
    unless partitioned_nodes.include?(leader)
      log << "Node #{@id} received state: #{state} from Node #{leader.id} (leader)"
      accepted_states << state
      leader.receive_state_vote(self, state)
    else
      log << "Node #{@id} could not receive proposal from Node #{leader.id} due to partition"
    end
  end

  def receive_state_vote(neighbor, state = nil)
    majority = ((neighbors.size + 1) / 2.0).ceil
    if @votes >= majority
      log << "Node #{@id} already reached consensus on state #{@proposed_state} (Votes: #{@votes})"
      return
    end
    if state == @proposed_state
      @votes += 1
      log << "Node #{@id} received vote from Node #{neighbor.id} for state #{state}"
      check_consensus
    end
  end

  def check_consensus
    majority = ((neighbors.size + 1) / 2.0).ceil
    if @votes >= majority
      log << "Consensus reached on state: #{@proposed_state} (Votes: #{@votes})"
    else
      log << "Consensus not yet reached on state: #{@proposed_state} (Votes: #{@votes})"
    end
  end

  def simulate_partition(partitioned_nodes)
    @partitioned_nodes = partitioned_nodes
    log << "Node #{@id} is partitioned from #{partitioned_nodes.map(&:id).join(', ')}"
    partitioned_nodes.each do |node|
      node.partitioned_nodes << self unless node.partitioned_nodes.include?(self)
      node.log << "Node #{node.id} is partitioned from #{@id}"
    end
  end

  def retrieve_log
    log
  end
end
