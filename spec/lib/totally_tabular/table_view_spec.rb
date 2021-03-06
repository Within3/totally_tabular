require File.join(File.dirname(__FILE__), '..', '..', 'spec_helper')

require 'ostruct'
require 'nokogiri'

include TotallyTabular

describe TableView do

  def selector(string, selector)
    Nokogiri(string).css(selector)
  end

  before do
    @table_view = TableView.new([]) do
      define_column("col") do |o|
      end
    end
  end

  it "should be instantiated" do
    @table_view.should_not be_nil
  end

  it "should take a collection when initialized" do
    lambda { TableView.new }.should raise_error(ArgumentError)
  end

  it "should take a hash of options" do
    lambda { TableView.new(mock, {}) }.should_not raise_error
  end

  it "should render an empty table" do
    @table_view.render.should == "<table><thead></thead><tbody></tbody><tfoot></tfoot></table>"
  end

  it "should render with a class" do
    table_class = "CLASS"

    t = TableView.new([], :class => table_class) do |table|
      table.define_column("col") do |o|
      end
    end

    selector(t.render, "table.#{table_class}").should_not be_empty
  end

  it "should render with cellpadding, cellspacing" do
    t = TableView.new([], :cellpadding => 0, :cellspacing => 0) do |table|
      table.define_column("col") do |o|
      end
    end

    selector(t.render, "table[cellpadding='0']").should_not be_empty
    selector(t.render, "table[cellspacing='0']").should_not be_empty
  end

  context "displaying multiple objects in rows" do

    before do
      o = OpenStruct.new(:name => "Joe", :coolness => "Really cool!", :age => 28)
      o2 = OpenStruct.new(:name => "Jonathan", :coolness => "Kinda cool.", :age => 33)
      o3 = OpenStruct.new(:name => "Gary", :coolness => "Eh.", :age => 26)
      o4 = OpenStruct.new(:name => "Josh", :coolness => "Lame.", :age => 26)
      @table_view = TableView.new([o, o2, o3, o4]) do |t|
        t.define_column("Name") do |o|
          template! do
            "%s is %s" % [o.name, o.coolness]
          end
        end
        t.define_column("Age") do |o|
          template! do
            o.age
          end
        end
      end
      @result = @table_view.render
    end

    it "should display 4 rows" do
      selector(@result, "table tbody tr").length.should == 4
    end

    it "should have 2 column headers" do
      selector(@result, "table thead th").length.should == 2
    end

    it "should have 2 columns" do
      selector(@result, "table tr:first-child td").length.should == 2
    end
  end

  context "defining columns" do

    it "allows defining class on header" do
      t = TableView.new([1]) do
        define_column("Blah") do |o|
          header_attributes!(:class => 'blahdiddy')
          template! do
          end
        end
      end

      selector(t.render, "table th.blahdiddy").length.should == 1
    end

    it "allows defining a class on row" do
      t = TableView.new([1]) do
        define_column("Blah") do |o|
          row_attributes!(:class => 'diddy')
          template! do
          end
        end
      end

      selector(t.render, "table tr.diddy").length.should == 1
    end

    it "allows defining a class from an object attribute" do
      obj = OpenStruct.new(:status => 'unread')
      t = TableView.new([obj]) do
        define_column("Blah") do |o|
          row_attributes!(:class => o.status)
          template! do
          end
        end
      end

      selector(t.render, "table tr.unread").length.should == 1
    end

    it "allows defining a class on the cell" do
      t = TableView.new([1]) do
        define_column("Blah") do |o|
          cell_attributes!(:class => 'diddy')
          template! {}
        end
      end

      selector(t.render, "table td.diddy").length.should == 1
    end

    it "should take a block and give a table class" do
      table = TableView::Table.new
      TableView::Table.stub!(:new).and_return(table)

      column_definition = Proc.new {  }
      table_view = TableView.new([], {}, &column_definition)

      table.should_receive(:instance_eval)

      table_view.render
    end

    it "should allow me to define a column" do
      column_definition = Proc.new do
        define_column("Joe") do
          template! do
          end
        end
      end

      t = TableView.new([], {}, &column_definition)
      lambda { t.render }.should_not raise_error
    end

    it "should allow defining the column body when defining the column" do
      t = TableView.new(["Judge"]) do
        define_column("Name") do |item|
          template! do
            "My name is %s." % item
          end
        end
      end

      selector(t.render, "table tr td").inner_html.should == "My name is Judge."
    end

  end

  it "should allow me to call other methods in the same class" do
    class TableHelper
      def embolden_text(text)
        "<strong>%s</strong>" % text
      end
      def render_table
        TableView.new(["Teamicil"], :self => self) do
          define_column("Drugs") do |item|
            template! do
              embolden_text(item)
            end
          end
        end.render
      end
    end
    t = ""
    lambda { t = TableHelper.new.render_table }.should_not raise_error
    selector(t, "table tr td strong").inner_html.should == "Teamicil"
  end
end
