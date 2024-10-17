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

  it 'start election' do
    @node1.start_election
  end

  it 'proposes a state' do
    @node1.propose_state(1)
    @node2.propose_state(2)
    puts @node1.retrieve_log
    puts @node2.retrieve_log
    puts @node3.retrieve_log
  end
end
