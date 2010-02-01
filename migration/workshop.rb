#!/usr/bin/env ruby

require 'rubygems'
require 'builder'
require 'hpricot'
require 'yaml'

def parse_title(doc)
  doc.search("title").inner_html.gsub(/[\n ]+/, " ").strip
end

def parse_attributes(doc)
  attrs = {}
  doc.search("meta").each do |meta_tag|
    name = meta_tag["name"]
    next unless name
    case name
    when /^DC\./
      attrs[name] = meta_tag["content"]
    end
  end
  attrs["title"] = parse_title(doc)
  attrs["plone_url"] = doc.search("base")[0]["href"]
  attrs
end

def parse_content(doc)
  doc.search("div.documentContent").inner_html
end

def create_file_index(dir)
  # TODO: could set a class based on whether item is
  # a file or a directory.  For files we could compute size
  # and directories possibly number of items inside.
  adir = File.expand_path(dir)
  xm = Builder::XmlMarkup.new(:indent => 2, :margin => 8)
  content = xm.ul("class" => "file_list") {
    Dir["#{adir}/*"].each do |f|
      xm.li { xm.a(f, "href" => f) }
    end
  }.to_s
  attrs = {
    "title" => "#{File.basename(adir)}",
    "created_at" => Time.now.to_s,
    "autogenerated" => "true"
  }
  { :content => content, :attrs => attrs }
end

##
# import plone workshop index_html into nanoc content
#
# input should be the path to the workshops directory
# as exported from Plone containing the index_html files
#
# content should be the path to the nanoc content directory.
def import_workshop_index_files(input, content)
  indir = File.expand_path(input)
  outdir = File.expand_path(content)
  workshop_out_dir = "#{outdir}/#{File.basename(indir)}"
  Dir.chdir(input) do
    Dir["**/*"].each do |f|
      if File.fnmatch("index[._]html", File.basename(f))
        puts "processing: #{input}/#{f}"
        dest_dir = "#{workshop_out_dir}/#{File.dirname(f)}"
        FileUtils.mkdir_p(dest_dir)
        if !File.size?("#{indir}/#{f}")
          puts "empty file, skipping"
          next
        end
        doc = Hpricot(open("#{indir}/#{f}"))
        print "."
        attrs = parse_attributes(doc)
        print "."
        content = parse_content(doc)
        puts "."
        open("#{dest_dir}/index.html", "w") do |out|
          out.write(content)
        end
        open("#{dest_dir}/index.yaml", "w") do |out|
          out.write(attrs.to_yaml)
        end
      end
    end
  end
end

# infile = ARGV[0]
# puts "processing: #{infile}"

# doc = Hpricot(open(infile))
# attrs = parse_attributes(doc)
# content = parse_content(doc)
# open("test1.html", "w") do |f|
#   f.write(content)
# end
# open("test1.yaml", "w") do |f|
#   f.write(attrs.to_yaml)
# end

import_workshop_index_files("plone-bioconductor.org/workshops", "content")
