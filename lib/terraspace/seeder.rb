require "hcl_parser"

module Terraspace
  class Seeder
    extend Memoist

    def initialize(mod, options={})
      @mod, @options = mod, options
    end

    def seed
      parsed = parse # make @parsed available for rest of processing
      content = Content.new(parsed).build
      write(content)
    end

    def parse
      if exist?("variables.tf")
        load_hcl_variables
      elsif exist?("variables.tf.json")
        JSON.load(read("variables.tf.json"))
      else
        puts "WARN: no variables.tf or variables.tf.json found in: #{@mod.cache_build_dir}"
        ENV['TS_TEST'] ? raise : exit
      end
    end
    memoize :parse

    def load_hcl_variables
      HclParser.load(read("variables.tf"))
    rescue Racc::ParseError => e
      puts "ERROR: Unable to parse the #{Util.pretty_path(@mod.cache_build_dir)}/variables.tf file".color(:red)
      puts "and generate the starter tfvars file. This is probably due to a complex variable type."
      puts "#{e.class}: #{e.message}"
      puts
      puts "You will have to create the tfvars file manually at: #{Util.pretty_path(dest_path)}"
      exit 1
    end

    def write(content)
      actions.create_file(dest_path, content)
    end

    def dest_path
      Where.new(@mod, @options).dest_path
    end
    memoize :dest_path

    def exist?(file)
      path = "#{@mod.cache_build_dir}/#{file}"
      File.exist?(path)
    end

    def read(file)
      path = "#{@mod.cache_build_dir}/#{file}"
      puts "Reading: #{Util.pretty_path(path)}"
      IO.read(path)
    end

    def actions
      Actions.new(@options)
    end
    memoize :actions
  end
end