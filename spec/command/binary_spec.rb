require File.expand_path('../../spec_helper', __FILE__)

module Pod
  describe Command::Binary do
    describe 'CLAide' do
      it 'registers it self' do
        Command.parse(%w{ binary }).should.be.instance_of Command::Binary
      end
    end
  end
end

