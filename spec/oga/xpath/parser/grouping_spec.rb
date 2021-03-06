require 'spec_helper'

describe Oga::XPath::Parser do
  describe 'grouping of expressions' do
    it 'parses "A + (B + C)"' do
      parse_xpath('A + (B + C)').should == s(
        :add,
        s(:axis, 'child', s(:test, nil, 'A')),
        s(
          :add,
          s(:axis, 'child', s(:test, nil, 'B')),
          s(:axis, 'child', s(:test, nil, 'C'))
        )
      )
    end

    it 'parses "A or (B or C)"' do
      parse_xpath('A or (B or C)').should == s(
        :or,
        s(:axis, 'child', s(:test, nil, 'A')),
        s(
          :or,
          s(:axis, 'child', s(:test, nil, 'B')),
          s(:axis, 'child', s(:test, nil, 'C'))
        )
      )
    end

    it 'parses "(A or B) and C"' do
      parse_xpath('(A or B) and C').should == s(
        :and,
        s(
          :or,
          s(:axis, 'child', s(:test, nil, 'A')),
          s(:axis, 'child', s(:test, nil, 'B'))
        ),
        s(:axis, 'child', s(:test, nil, 'C'))
      )
    end
  end
end
