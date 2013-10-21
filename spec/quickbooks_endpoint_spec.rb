require 'spec_helper'

describe QuickbooksEndpoint do

  def auth
    {'HTTP_X_AUGURY_TOKEN' => 'x123'}
  end

  def app
    described_class
  end


  context "windows" do
    context "persist" do
    end
  end

  context "online" do
    context "persist" do
    end
  end

end
