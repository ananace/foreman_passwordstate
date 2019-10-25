module MyPlugin
  class InfoProvider < HostInfo::Provider # inherit the base class

    # override this method according to principles specified below
    def host_info
      { 'parameters' => host.params }
    end
  end
end
