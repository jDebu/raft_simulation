require 'rspec'
require_relative '../lib/node'

RSpec.describe Node do
  before(:each) do
    @node1 = Node.new(1)
    @node2 = Node.new(2)
    @node3 = Node.new(3)

    @node1.add_neighbor(@node2)
    @node1.add_neighbor(@node3)
    @node2.add_neighbor(@node1)
    @node2.add_neighbor(@node3)
    @node3.add_neighbor(@node1)
    @node3.add_neighbor(@node2)
  end

  it 'elects a leader successfully' do
    @node1.start_election
    expect(@node1.raft_state).to eq(:leader)
    expect(@node1.retrieve_log).to include("Node 1 became leader in term 1")
    puts @node1.retrieve_log
  end

  it 'leader can propose a state' do
    @node1.start_election
    @node1.propose_state(1)
    expect(@node1.proposed_state).to eq(1)
    expect(@node1.retrieve_log).to include("Node 1 (leader) proposes state: 1")
    puts @node1.retrieve_log
  end

  it 'non-leader cannot propose a state' do
    @node1.start_election
    @node2.propose_state(2)
    expect(@node2.proposed_state).to be_nil
    expect(@node2.retrieve_log).to include("Node 2 tried to propose state 2 but is not the leader or has no followers")
    puts @node1.retrieve_log
    puts @node2.retrieve_log
  end

  it 'simulates partition and proposal failure' do
    @node1.start_election
    @node3.simulate_partition([@node1])
    @node1.propose_state(1)
    expect(@node1.retrieve_log).to include("Node 1 (leader) proposes state: 1")
    expect(@node3.retrieve_log).to include("Node 3 is partitioned from 1")
    expect(@node1.retrieve_log).to include("Node 1 could not send proposal to Node 3 due to partition")
    puts @node1.retrieve_log
    puts @node3.retrieve_log
  end


  it 'simulates multiple proposals and reaches consensus with highest state' do
    @node1.start_election
    @node2.start_election

    @node1.propose_state(1)
    @node2.propose_state(2)
    @node3.simulate_partition([@node1])
    @node2.propose_state(3)
    @node1.propose_state(4)

    expect(@node1.retrieve_log).to include("Node 1 (leader) proposes state: 1")
    expect(@node2.retrieve_log).to include("Node 2 tried to propose state 3 but is not the leader or has no followers")
    expect(@node3.retrieve_log).to include("Node 3 is partitioned from 1")

    expect(@node1.retrieve_log).to include("Node 1 could not send proposal to Node 3 due to partition")

    expect(@node1.retrieve_log).to include("Consensus reached on state: 4 (Votes: 2)")
    puts @node1.retrieve_log
    puts @node2.retrieve_log
    puts @node3.retrieve_log
  end

  it 'simulates a partition and new leader election in the partitioned network elapse election timeout' do
    @node1.start_election
    expect(@node1.raft_state).to eq(:leader)
  
    @node1.simulate_partition([@node2, @node3])  
    @node2.start_election
    expect(@node2.raft_state).to eq(:leader)
    expect(@node2.retrieve_log).to include("Node 2 became leader in term 2")
    expect(@node3.retrieve_log).to include("Node 3 voted for Node 2 in term 2")
    @node2.propose_state(5)
    expect(@node2.proposed_state).to eq(5)
    expect(@node2.retrieve_log).to include("Node 2 (leader) proposes state: 5")
    expect(@node3.retrieve_log).to include("Node 3 received state: 5 from Node 2 (leader)")
    @node1.propose_state(10)
    expect(@node1.proposed_state).to be_nil
    expect(@node1.retrieve_log).to include("Node #{@node1.id} tried to propose state 10 but is not the leader or has no followers")
    expect(@node1.retrieve_log).not_to include("Node 1 (leader) proposes state: 10")
    puts @node1.retrieve_log
    puts @node2.retrieve_log
    puts @node3.retrieve_log
  end
end
