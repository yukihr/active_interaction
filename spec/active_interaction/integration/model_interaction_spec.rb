# coding: utf-8

require 'spec_helper'

ModelInteraction = Class.new(TestInteraction) do
  model :object
end

describe ModelInteraction do
  include_context 'interactions'
  it_behaves_like 'an interaction', :model, -> { // }, class: Regexp

  it 'does not raise an error' do
    expect { result }.to_not raise_error
  end
end
