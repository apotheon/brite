require 'chocolates'
require 'brite/part'

module Brite

  # Page class
  class Page

    attr :file

    # Template type (rhtml or liquid)
    attr :stencil

    # Layout name (relative filename less extension)
    attr :layout

    # Author
    attr :author

    # Title of page/post
    attr :title

    # Publish date
    attr :date

    # Tags (labels)
    attr :tags

    # Category ("a glorified tag")
    attr :category

    # Rendering of each part.
    attr :renders

    # Rendered output.
    attr :content

    # output extension (defualt is 'html')
    attr :extension

    #
    def initialize(site, file)
      @site    = site
      @file    = file
      @parts   = []
      @renders = []
      parse
    end

    def name
      @name ||= file.chomp(File.extname(file))
    end

    #
    def url
      @url ||= File.join(site.url, name + extension)
    end

    #
    def path
      @path ||= '/' + name + extension
    end

    #
    def extension
      @extension ||= '.html'
    end

    # DEPRECATE: Get rid of this and use rack to test page instead of files.
    def root
      '../' * file.count('/')
    end

    #
    def work
      '/' + File.dirname(file)
    end

    # TODO
    #def next
    #  self
    #end

    # TODO
    #def previous
    #  self
    #end

    #
    def to_h
      {
        'url'      => url,
        'path'     => path,
        'author'   => author,
        'title'    => title,
        'date'     => date,
        'tags'     => tags,
        'category' => category,
        'summary'  => summary
        #'yield'    => content
      }
    end

    #
    def save(output=nil)
      output ||= Dir.pwd  # TODO
      text  = render
      fname = file.chomp(File.extname(file)) + extension
      if dryrun
        puts "[DRYRUN] write #{fname}"
      else
        puts "write #{fname}"
        File.open(fname, 'w'){ |f| f << text }
      end
    end

    def to_contextual_attributes
      { 'site'=>site.to_h, 'page'=>to_h, 'root'=>root, 'work'=>work }
    end

    #
    def to_liquid
      to_contextual_attributes
    end

    # Summary is the rendering of the first part.
    def summary
      @summary #||= @renders.first
    end

  protected

    #--
    # TODO: Should validate front matter before any processing.
    #
    # TODO: Improve this code in general, what's up with output vs. content?
    #++
    def render(inherit={})
      attributes = to_contextual_attributes
      attributes = attributes.merge(inherit)

      render = @document.render(attributes)
      output = render.to_s

      @summary = render.summary

      #attributes['content'] = content if content
      #@renders = parts.map{ |part| part.render(stencil, attributes) }
      #output = @renders.join("\n")
      #@content = output

      #attributes = attributes.merge('content'=>output)

      if layout
        renout = site.lookup_layout(layout)
        raise "No such layout -- #{layout}" unless renout
        output = renout.render(attributes){ output }
      end

      output.strip
    end

  private

    #
    def site
      @site
    end

    #
    def parts
      @parts
    end

    #
    def dryrun
      site.dryrun
    end

    #
    def parse
      @document = Chocolates::Document.new(file)
      @template = @document.template

      header = @template.header

      @stencil    = header['stencil'] || site.defaults.stencil

      @author     = header['author']  || 'Anonymous'
      @title      = header['title']
      @date       = header['date']
      @category   = header['category']
      @extension  = header['extension']
      @summary    = header['summary']

      self.tags   = header['tags']
      self.layout = header['layout']
    end

=begin
    #
    def parse
      hold = []
      text = File.read(file)
      sect = text.split(/^\-\-\-/)

      if sect.size == 1
        @prop = {}
        @parts << Part.new(sect[0], site.defaults.format)
      else
        void = sect.shift
        head = sect.shift
        head = YAML::load(head)

        parse_header(head)

        sect.each do |body|
          index   = body.index("\n")
          format  = body[0...index].strip
          format  = site.defaults.format if format.empty?
          text    = body[index+1..-1]
          @parts << Part.new(text, format)
        end
      end

    end
=end

    #
    def parse_header(head)
      @stencil    = head['stencil'] || site.defaults.stencil
      @author     = head['author']  || 'Anonymous'
      @title      = head['title']
      @date       = head['date']
      @category   = head['category']
      @extension  = head['extension']
      @summary    = head['summary']

      self.tags   = head['tags']
      self.layout = head['layout']
    end

    def layout=(layout)
      if FalseClass === layout
        @layout = nil
      else
        @layout = layout || default_layout
      end
    end

    #
    def tags=(entry)
      return entry unless entry
      case entry
      when String, Symbol
        entry = entry.to_s.strip
        if entry.index(/[,;]/)
          entry = entry.split(/[,;]/)
        else
          entry = entry.split(/\s+/)
        end
      else
        entry = entry.to_a.flatten
      end
      @tags = entry.map{ |e| e.strip }
    end

    # Default layout is different for pages vs. posts, so we
    # use this method to differntiation them.
    def default_layout
      site.defaults.pagelayout
    end

  public

    def to_s
      file
    end

    def inspect
      "<#{self.class}: #{file}>"
    end

  end

end

