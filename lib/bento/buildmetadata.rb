require 'bento/common'

class BuildMetadata
  include Common

  def initialize(template, build_timestamp, override_version)
    @template = template
    @build_timestamp = build_timestamp
    @override_version = override_version
  end

  def read
    {
      name:             name,
      version:          version,
      build_timestamp:  build_timestamp,
      git_revision:     git_revision,
      #git_status:       git_clean? ? "clean" : "dirty"
      box_basename:     box_basename,
      template:         template_vars.fetch("template", UNKNOWN),
      cpus:             cpus.to_s,
      memory:           memory.to_s,
    }
  end

  private

  UNKNOWN = "__unknown__".freeze

  attr_reader :template, :build_timestamp, :override_version

  def box_basename
    "#{name.gsub("/", "__")}-#{version}"
  end

  def git_revision
    sha = %x{git rev-parse HEAD}.strip
  end

  def git_clean?
    %x{git status --porcelain}.strip.empty?
  end

  def merged_vars
    @merged_vars ||= begin
      if File.exist?("#{template}.variables.json")
        template_vars.merge(JSON.load(IO.read("#{template}.variables.json")))
      else
        template_vars
      end
    end
  end

  def name
    merged_vars.fetch("name", template)
  end

  def template_vars
    @template_vars ||= JSON.load(IO.read("#{template}.json")).fetch("variables")
  end

  def version
    if override_version
       override_version
    else
    merged_vars.fetch("version", "#{UNKNOWN}.TIMESTAMP").
      rpartition(".").first.concat(".#{build_timestamp}")
    end
  end
end