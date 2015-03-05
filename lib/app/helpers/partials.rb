module Sinatra::Partials
  def partial(template, *args)
    path = template.to_s.split('/')
    name = path.last.to_sym
    file = "_#{name}"

    template = (path[0..-2] << file).join('/').to_sym
    options  = args.extract_options!.merge(layout: false)

    if collection = options.delete(:collection)
      locals = options[:locals] || {}
      collection.map do |member|
        locals  = {name => member}.merge(locals)
        options = options.merge(locals: locals)
        erb(template, options)
      end.join("\n")
    else
      erb(template, options)
    end
  end
end