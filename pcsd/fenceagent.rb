def getFenceAgents(fence_agent = nil)
  fence_agent_list = {}
  agents = Dir.glob('/usr/sbin/fence_' + '*')
  agents.each { |a|
    fa = FenceAgent.new
    fa.name =  a.sub(/.*\//,"")
    next if fa.name == "fence_ack_manual"

    if fence_agent and a.sub(/.*\//,"") == fence_agent.sub(/.*:/,"")
      required_options, optional_options = getFenceAgentMetadata(fa.name)
      fa.required_options = required_options
      fa.optional_options = optional_options
    end
    fence_agent_list[fa.name] = fa
  }
  fence_agent_list
end

def getFenceAgentMetadata(fenceagentname)
  # There are bugs in stonith_admin & the new fence_agents interaction
  # eventually we'll want to switch back to this, but for now we directly
  # call the agent to get metadata
  #metadata = `stonith_admin --metadata -a #{fenceagentname}`
  metadata = `/usr/sbin/#{fenceagentname} -o metadata`
  doc = REXML::Document.new(metadata)
  options_required = {}
  options_optional = {}
  options_optional["pcmk_host_list"] = ""
  options_optional["pcmk_host_map"] = ""
  options_optional["pcmk_host_check"] = ""
  doc.elements.each('resource-agent/parameters/parameter') { |param|
    temp_array = []
    next if param.attributes["name"] == "action"
    if param.elements["shortdesc"]
      temp_array << param.elements["shortdesc"].text
    else
      temp_array << ""
    end
    if param.elements["longdesc"]
      temp_array << param.elements["longdesc"].text
    else
      temp_array << ""
    end
    if param.attributes["required"] == "1"
      options_required[param.attributes["name"]] = temp_array
    else
      options_optional[param.attributes["name"]] = temp_array
    end
  }
  [options_required, options_optional]
end

class FenceAgent
  attr_accessor :name, :resource_class, :required_options, :optional_options
  def initialize(name=nil, required_options={}, optional_options={}, resource_class=nil)
    @name = name
    @required_options = {}
    @optional_options = {}
    @required_options = required_options
    @optional_options = optional_options
    @resource_class = nil
  end

  def type
    name
  end

  def to_json(options = {})
    JSON.generate({:type => name})
  end
end
