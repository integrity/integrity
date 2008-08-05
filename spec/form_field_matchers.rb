module FormFieldHpricotMatchers
  # TODO: Add support for selects
  class HaveField
    include RspecHpricotMatchers
    
    def initialize(id, type, tagname)
      @tagname = tagname
      @type = type
      @id = id
      @tag_matcher = have_tag("#{@tagname}##{@id}", @tagname == "textarea" ? @value : nil)
      @label_set = true # always check for a label, unless explicitly told not to
    end
    
    def named(name)
      @name_set = true
      @name = name
      self
    end
    
    def with_label(label)
      @label = label
      self
    end
    
    def without_label
      @label_set = false
      self
    end
    
    def with_value(value)
      @value_set = true
      @value = value
      self
    end
    
    def checked
      @checked = "checked"
      self
    end
    
    def unchecked
      @checked = ""
      self
    end
    
    def matches?(actual)
      (@label_set ? have_tag("label[@for=#{@id}]", @label).matches?(actual) : true) &&
      @tag_matcher.matches?(actual) do |field|
        field["type"].should == @type if @type
        field["name"].should == @name if @name_set
        field["value"].should == @value if @value_set && @tagname == "input"
        field["checked"].should == @checked if @checked
      end
    end
    
    def failure_message
      attrs = [
        "id ##{@id}",
        @name  && "name '#{@name}'",
        @type  && "type '#{@type}'",
        @label && "labelled '#{@label}'",
        @value && "value '#{@value}'"
      ].compact.join(", ")
      "You expected a #{@tagname}#{@type ? " (#{@type})" : ""} with #{attrs} but found none.\n\n#{@tag_matcher.failure_message}"
    end
  end
  
  def have_field(id, type="text", tagname="input")
    HaveField.new(id, type, tagname)
  end
  
  def have_textfield(id)
    have_field(id)
  end
  
  def have_password(id)
    have_field(id, "password")
  end
  
  def have_checkbox(id)
    have_field(id, "checkbox")
  end

  def have_radio(id)
    have_field(id, "radio")
  end

  def have_textarea(id)
    have_field(id, nil, "textarea")
  end
end
